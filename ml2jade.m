function success = ml2jade(file_in_name, out_dir, render)

% ml2jade
%
% This function will take in a .jade file with MATLAB code, evaluate the
% code in the base workspace, and return the command window outputs and
% images of the figures. Anything in a "pre.eval: code." block is treated 
% as MATLAB code.
%
%   ml2jade()                               % Run an example.
%   ml2jade(file_in_name)                   % Given file name to convert.
%   ml2jade(file_in_name, out_dir)          % Specify output directory.
%   ml2jade(file_in_name, out_dir, render)  % Render Jade to HTML.
%   success = ml2jade(...)                  % Report success of operation.
%
% Example for _my_file.jade file:
%
% html
%   body
%     h1 A Title
%     p A paragraph.
%     pre.eval: code.
%       x = 1
%       plot(randn(10), '.');
%
% The output will be <out_dir>/my_file.jade: (Note the lack of underscore.)
%
% html
%   body
%     h1 A Title
%     p A paragraph.
%     pre.eval: code.
%       x = 1
%       plot(randn(10), '.');
%     pre.output: code.
%       x = 
%            1;
%     figure: img(src="<out_dir>/img/input_01.png")
%
% Caution: This uses undocumented functionality for 'snapnow'. It may fail
% with newer or older versions. It was tested in 14b.

    % Set a default file, just as an example.
    if nargin == 0
        clc;
        this_dir     = fileparts(mfilename('fullpath'));
        file_in_name = fullfile(this_dir, 'ml2jade_example.jade');
        out_dir      = fullfile(this_dir, 'jade');
    end
    
    % By default, use the working directory as output.
    if nargin < 2 && nargin ~= 0
        out_dir = [pwd filesep];
    end
    
    % By default, don't render to HTML.
    if nargin < 3
        render = false;
    end
    
    % We're pessimists.
    success = false; %#ok<NASGU>

    % Open the file.
    fiid = fopen(file_in_name);

    % Drop the path from the input file name and the .jade.
    [file_in_dir, base_name] = fileparts(file_in_name);
    
    %  If there's no output specified, use the same.
    if nargin == 1
        out_dir = file_in_dir;
    end
    
    % Make sure it ends in / (or \).
    if out_dir(end) ~= filesep
        out_dir = [out_dir filesep];
    end
    
    if ismac() && out_dir(1) ~= filesep
        out_dir = [pwd filesep out_dir];
    end
    
    % Drop the '_'. This allows us to keep, e.g., _index.jade in the same
    % place as all the other output .jade files, but it will only be used
    % as an input for ml2jade.
    if base_name(1) == '_'
        base_name = base_name(2:end);
    end

    % Create the output directory/clear out previous files for this base
    % name.
    img_dir = fullfile(out_dir, 'img');
    if ~isempty(out_dir) && ~exist(out_dir, 'dir'), 
        mkdir(out_dir);
    end
    if exist(img_dir, 'dir')
        old_files = dir(fullfile(img_dir, [base_name '*.png']));
        for k = 1:length(old_files)
            if regexp(old_files(k).name, [base_name '_\d+\.png'])
                delete(fullfile(img_dir, old_files(k).name));
            end
        end
    else
        mkdir(img_dir);
    end
    
    % Open the output file.
    jade_file_out = fullfile(out_dir, [base_name '.jade']);
    foid = fopen(jade_file_out, 'w');

    % Define a function to snap for us. It will suppress the weird
    % identifier messages in the output but running the snapnow command
    % entirely within an evalc. A bit odd. Works fine.
    cell_count = 0;
    function hidden_snap(cmd)
        base_cmd = sprintf('evalc(''snapnow(''''%s'''', %d)'');', ...
                           cmd, cell_count);
        evalin('base', base_cmd);
    end

    % Close the files.
    function clean_up()
        fclose(fiid);
        fclose(foid);
    end

    % Do everything as a 'try' so we can close files if we need to.
    try

        % State
        in_code    = false;
        first_line = false;
        ml2jade_storage('reset');

        % Set up the snapnow stuff to capture images.
        data                          = [];
        data.options.figureSnapMethod = 'entireGUIWindow';
        data.options.imageFormat      = 'png';
        data.options.maxHeight        = [];
        data.options.maxWidth         = [];
        data.marker                   = 'ml2jade';
        data.baseImageName            = fullfile(img_dir, base_name);
        if ismac
            % snapnow sometimes removes the first character of the path??
            %  data.baseImageName = [filesep data.baseImageName];
        elseif ispc
            % For Jade, we *always* use / for a filesep.
            data.baseImageName = regexprep(data.baseImageName, '\\', '/');
        end
        snapnow('set', data);

        % Loop over the lines of the file.
        while true

            % Read in the line and bail if done.
            line = fgetl(fiid);
            if ~ischar(line), break; end

            % If we're not in code, look for code.
            if ~in_code

                % Look for the line that signals incoming code.
                n_spaces_top = regexp(line, '^\s*(?=pre.eval: code\.)', 'end');

                % If code was found...
                if ~isempty(n_spaces_top)
                    in_code = true;
                    first_line = true;
                end

            % Otherwise, we're in a code segment.
            else

                % Look for a first line with content.
                if first_line
                    n_spaces = regexp(line, '^\s*(?=\S)', 'end');
                    if ~isempty(n_spaces)
                        first_line = false;
                    end
                end

                % Only do something if the content has started.
                if ~first_line

                    % See if this line is still part of the code segment.
                    if isempty(line)
                    elseif    length(line) >= n_spaces ...
                           && all(line(1:n_spaces) == ' ')

                        % Evaluate it.
                        ml2jade_storage('add', line);

                    % Otherwise, we are done with the code block. Capture
                    % any output text or images and move along.
                    else

                        % Begin a new cell.
                        cell_count = cell_count + 1;
                        hidden_snap('beginCell');
                        
                        % Evaluate this whole block of code. We use the
                        % storage to hold on to the lines as they come in
                        % and retrieve them in the base workspace, where we
                        % evaluate everything.
                        try
                            
                            fprintf('Evaluating:\n\n%s\n\n', ml2jade_storage());
                            output = evalin('base', 'evalc(ml2jade_storage());');

                            % End the cell.
                            hidden_snap('endCell');

                            % Set the indentation for the output pre:.
                            spaces_top = repmat(' ', 1, n_spaces_top);

                            % Use only the non-empty outputs.
                            if ~isempty(output)

                                % We'll use this to indent properly for Jade.
                                spaces = repmat(' ', 1, n_spaces);

                                % Print this as an "output" pre.
                                fprintf(foid, '%spre.output: code.\n', ...
                                        spaces_top);

                                % Replace all \n (except for the last) with \n
                                % followed by the appropriate number of spaces.
                                out_lines = regexprep(output, '\n(?!$)', ...
                                                      ['\n' spaces]);
                                fprintf(foid, '%s%s', spaces, out_lines);

                            end

                            % Get the snapnow results.
                            data = snapnow('get');

                            % See which images belong in the current cell (it
                            % will be the ones at the end).
                            img_cells   = data.placeList(1:2:end);
                            img_indices = find(img_cells == cell_count);

                            % For each image, output a 'figure' for it.
                            for k = img_indices(:).'

                                % Make the path relative.
                                img = data.pictureList{k};
                                img = img(length(out_dir)+1:end);
                                fprintf(foid, '%sfigure: img(src="%s")\n', ...
                                        spaces_top, img);

                            end

                        catch err %#ok<NASGU>
                            % Some cells aren't meant to evaluate. That's
                            % ok. Move along.
                        end

                        % Reset everything.
                        ml2jade_storage('reset');
                        in_code    = false;
                        first_line = false;

                    end

                end

            end % in/out of code

            % Add the line no matter what. We never *remove* from the jade.
            fprintf(foid, '%s\n', line);

        end % for each line

        % Done!
        clean_up();
        
        % See if we should go on to HTML.
        if render
            success = jade2html(jade_file_out);
        else
            success = true;
        end

	% If something bad happened, close the files and send the error 
    % upstream.
    catch err
        clean_up();
        rethrow(err)
    end

end % ml2jade
