function success = enjaden(file_in_name, out_dir, template_name, evaluate, render)

% enjaden
% 
% Publishes a MATLAB script to Jade, similar to MATLAB's built-in 'publish'
% function.
%
% This tool will use MathJax to format the equations, and the default
% template 
%
% Inputs
% ------
%
% file_in_name   Name of .m file to convert
% out_dir        Output directory for .jade file and images; for my_file.m
%                with an out_dir of 'here/there/public', the generated
%                content will be:
%
%                  here/there/public/my_file.jade
%                  here/there/public/imgs/
%                  here/there/public/imgs/my_file_01.png
%                  here/there/public/imgs/my_file_02.png ...
%
%                The .jade file references images relatively. E.g., the
%                images will show up in the .jade as:
% 
%                  figure: img(src="img/my_file_01.png")
% 
% template_name  Name of template file *or* text to use for the template;
%                if empty, a default template will be used.
% evaluate       True to evaluate the MATLAB code sections and include
%                their results (true by default)
%
% Outputs
% -------
%
% success        True iff everything completed correctly.
%
% Template
% --------
%
% The template file should contain at least one section marked with:
%
%   <ml2jade=page_content>
%
% This will be used to determine the amount of indentation needed and will
% be replaced with the content from the publish .m file.
%
% Further, the file can contain <ml2jade=page_title>, which will be
% replaced with the title (the first %% block).
%
% For example, a simple template is:
%
%  html
%    head
%      title <ml2jade=page_title>
%    body
%      <ml2jade=page_content>
%
% Any inline or display equations ($x$ or $$x = f(x)$$) will use MathJax
% for rendering, and so the template should include a MathJax parser as
% well. The default template (_template.jade) include this. To create a
% custom template, it's recommended to start with _template.jade.
%
% Either the raw text for this can be passed in, or this can be saved in a
% file (e.g., _my_template.jade), and the file name can be passed in.

    % Set a default file, just as an example.
    if nargin < 1
        file_in_name = 'enjaden_example.m';
        out_dir      = 'jade';
    end
    
    % Drop the path from the input file name and the .m.
    [file_in_dir, base_name] = fileparts(which(file_in_name));
    
    % By default (and unless we're just running the example file), use the 
    % input directory as the output directory.
    if nargin < 2 && nargin ~= 0
        out_dir = file_in_dir;
    end

    % Set a default template.
    if nargin < 3 || isempty(template_name)
        template_name = fileread('_template.jade');
    end
    
    % By default, evaluate.
    if nargin < 4 || isempty(evaluate)
        evaluate = true;
    end
    
    % Be default, don't render.
    if nargin < 5 || isempty(render)
        render = false;
    end
    
    % If the template_name looks like a file name, load the file.
    % Otherwise, assume the template is text.
    if ~any(template_name == sprintf('\n')) && exist(template_name, 'file')
        template = fileread(template_name);
    else
        template = template_name;
    end
    
    % Create a name for the out file.
    out_file = [base_name '.jade'];
    if evaluate
        out_file = ['_' out_file];
    end
    
    % Where to put the final .jade file
    jade_out_dir = out_dir;
    
    % If evaluating, put the intermediate file in the working directory.
    if evaluate
        out_dir = pwd;
    end
    
    % Make sure the directoroy exists.
    if ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end
    
    % Create a function to tidy up the files for us.
    foid = [];
    function clean_up()
        if ~isempty(foid), fclose(foid); foid = []; end
    end
    
    % Try everythinig so we can catch and clean up before the error is
    % rethrown.
    success = false;
    try

        % Load the file all at once.
        original_text = fileread(file_in_name);
        foid = fopen([out_dir filesep out_file], 'w');

        % Normalize line endings for posix.
        text = [regexprep(original_text, '\r', '') sprintf('\n%%%%\n')];

        % Look for the title.
        title = regexp(text, '^[\n\r]*%%\ *(.*?)[\n\r]', 'tokens');
        if ~isempty(title)
            title = replace_inline(title{1}{1});
        end

        % Extract header and footer.
        page_header = template(1:strfind(template, ...
                                              '<ml2jade=page_content>')-1);
        page_footer = template(strfind(template, ...
                                         '<ml2jade=page_content>')+22:end);

        % Replace the title.
        page_header = regexprep(page_header, '<ml2jade=page_title>', title);

        % Get the nominal spacing.
        page_spaces  = regexp(template, ...
                            '(\ *)<ml2jade=page_content>[\n|$]', 'tokens');
        page_spaces  = page_spaces{1}{1};
        block_spaces = [page_spaces, '  '];

        % Get started.
        fprintf(foid, '%s', page_header);

        % Look for section breaks.
        [starts, stops, cells] = regexp(text, ...
                                 '(?<=(^|[\n\r]))%%[\t\ ]*(.*?)[\n\r]', ...
                                 'start', 'end', 'tokens');
        for k = 1:length(cells)-1

            fprintf(foid, '\n');

            % Pull the header and make it an h2.
            header = replace_inline(cells{k}{1});
            if ~isempty(header)
                if k == 1
                    fprintf(foid, '%sh1 %s\n', page_spaces, header);
                else
                    fprintf(foid, '%sh2 %s\n', page_spaces, header);
                end
            else
                fprintf(foid, '%s// cell %d\n', page_spaces, k);
            end

            % Pull out this section.
            section = text(stops(k)+1:starts(k+1)-1);

            % Look for a blurb and bit of code.
            results = regexp(section, '^(%.*?)\n([^%].*)', 'tokens');
            if ~isempty(results)

                % Extract the parts.
                blurb = results{1}{1};
                code = results{1}{2};

                % Drop the '% 's.
                blurb = regexprep(blurb, '(?<=(\n|^))%\ ?', '');

                % Pick the paragraphs.
                paragraphs = regexp(blurb, '(.*?)(\n\s*\n|$)', 'tokens');

                % For each paragraph...
                for p = 1:length(paragraphs)

                    % Trim the newlines off of the paragraph.
                    paragraph = regexprep(paragraphs{p}{1}, ...
                                                        '(^\n+|\n*$)', '');
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Paragraph Replacements %
                    %%%%%%%%%%%%%%%%%%%%%%%%%%
                             
                    do_replacements = true;
                    
                    % Code
                    if length(paragraph) > 2 && all(paragraph(1:2) == ' ')
                        
                        fprintf(foid, '%spre: code.\n', page_spaces);
                        do_replacements = false;
                        type = 'code';
                        
                    % Pre
                    elseif length(paragraph) > 1 && paragraph(1) == ' '
                        
                        fprintf(foid, '%spre.\n', page_spaces);
                        do_replacements = false;
                        type = 'pre';
                        
                    % Bullets
                    elseif length(paragraph) > 1 && paragraph(1) == '*'
                        
                        fprintf(foid, '%sul\n', page_spaces);
                        type = 'ul';
                        
                    % Numbered lists
                    elseif length(paragraph) > 1 && paragraph(1) == '#'
                        
                        fprintf(foid, '%sol\n', page_spaces);
                        type = 'ol';
                        
                    % Otherwise, it's a normal paragraph.
                    else
                        
                        fprintf(foid, '%sp.\n', page_spaces);
                        type = 'p';
                        
                    end

                    %%%%%%%%%%%%%%%%%%%%%%%%
                    % Inline Replacemenets %
                    %%%%%%%%%%%%%%%%%%%%%%%%
                    
                    % Replace things inside the paragraph (unless it's pre
                    % or code).
                    if do_replacements
                        paragraph = replace_inline(paragraph, type);
                    end
                    
                    % Adding spaceing and stuff like 'ul '.
                    paragraph = add_prefix(type, paragraph, block_spaces);
                                           
                    % Place into the Jade.
                    fprintf(foid, '%s\n', paragraph);

                end

            % Otherwise, the code is the whole section.
            else
                code = section;
            end

            % See if there's code.
            if ~isempty(code) && any(regexp(code, '\S'))
                code = strtrim(code);
                code = [block_spaces regexprep(code, ...
                                               '\n', ['\n' block_spaces])];
                fprintf(foid, '%spre.eval: code.\n', page_spaces);
                fprintf(foid, '%s\n', code);
            end

        end

        % Put the actual code into the file too.
        fprintf(foid, '%s//\n', page_spaces);
        text = original_text;
        
        % This is how 'publish' escapes the quotes, so we'll do the same.
        text = regexprep(text, '(?<=<!)--', 'REPLACE_WITH_DASH_DASH');
        text = regexprep(text, '--(?=>)', 'REPLACE_WITH_DASH_DASH');
        
        % Surround the original code with big flags.
        text = sprintf( ...
             '##### SOURCE BEGIN #####\n%s\n##### SOURCE END #####', text);
         
        % Add in the spaces and print it out.
        text = [block_spaces '| ' regexprep(text, '\n', ['\n' block_spaces '| '])];
        fprintf(foid, '%s\n', text);
        
        % Tack on the footer.
        fprintf(foid, '%s', page_footer);

        % Done!
        clean_up();
       
        % To this point, we've only converted the text of the file to Jade.
        % If we actually need to evaluate the code, do so now. Remove the
        % temporary jade file.
        if evaluate
            success = ml2jade(out_file, jade_out_dir, render);
            pause(0.01);
            delete(out_file);
        end
        
    % If there was an error...
    catch err
        clean_up();
        rethrow(err);
    end

end % enjaden

% Replace inline expressions.
function paragraph = replace_inline(paragraph, type)

    if nargin < 2, type = ''; end;

    % Replace inline equations. Note that display equations need
    % not be replaced! This is one of the ugliest regexps I've ever
    % written. We want (beginning of string or something that's not
    % a $), followed by $, followed by anything that isn't a $,
    % followed by (end of string or anything that's not a $). We
    % can to replace abc$xyz$def with abc\(xyz\)def.
    paragraph = regexprep(paragraph, ...
                          '(?<=(^|[^\$]))\$([^\$]+?)\$(?=([^\$]|$))', ...
                          '\\\($1\\\)');

    % Links.
    paragraph = regexprep(paragraph, ...
                                 '(^|[^<])<([^<\ ]+?)\ (.*?)>([^>]|$)', ...
                                 '$1<a href="$2">$3</a>$4');

    % Embolden.
    if strcmp(type, 'ul');
        paragraph = regexprep(paragraph, ...
                                '[^\n]\*(.+?)\*', '<strong>$1</strong>');
    else
        paragraph = regexprep(paragraph, ...
                                     '\*(.+?)\*', '<strong>$1</strong>');
    end

    % Italic.
    paragraph = regexprep(paragraph, '_(.+?)_', '<em>$1</em>');

    % Code.
    paragraph = regexprep(paragraph, '\|(.+?)\|', '<code>$1</code>');

    % Image.
    paragraph = regexprep(paragraph, '<<(.*?)>>', '<img src="$1">');

end % replace_inline

% Add spacing and stuff like 'ul  '.
function paragraph = add_prefix(type, paragraph, block_spaces)

    % Add the spaces for the block.
    switch type

        case 'code'
            
            % Remove unnecessary spaces.
            paragraph = regexprep(paragraph, '(^|\n)\ \ ', '$1');
                     
        case 'pre'
            
            % Remove unnecessary space.
            paragraph = regexprep(paragraph, '(^|\n)\ ', '$1');
                     
        case 'ol'
            
            % Add li.
            paragraph = regexprep(paragraph, '(^|\n)\#\ ', '$1li.\n\ \ ');
                     
        case 'ul'
            
            % Add li.
            paragraph = regexprep(paragraph, '(^|\n)\*\ ', '$1li.\n\ \ ');
                     

    end
            
    % Prefix the spaces.
    paragraph = [block_spaces ...
                 regexprep(paragraph, '\n', ['\n' block_spaces])];
                    
end % add_prefix
