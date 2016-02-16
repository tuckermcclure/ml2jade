function success = enjaden(file_in_name, out_dir, template_name, evaluate, render)

% enjaden
% 
% Publishes a MATLAB script to Jade, similar to MATLAB's built-in 'publish'
% function.
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
% replaced with the title (the first %% block), and a table of contents,
% containing all of the headers with links, can be placed with
% <ml2jade=page_toc>. See enjaden_example.m.
%
% For example, a simple template is:
%
%  html
%    head
%      title <ml2jade=page_title>
%    body
%      h1 <ml2jade=page_title>
%      <ml2jade=page_content>
%
% Any inline or display equations ($x$ or $$x = f(x)$$) will use MathJax
% for rendering, and so the template should include a MathJax parser as
% well. The default template (_template.jade) include this. To create a
% custom template, it's recommended to start with _template.jade.
%
% Either the raw text for this can be passed in, or this can be saved in a
% file (e.g., _my_template.jade), and the file name can be passed in.
%
% Other
% -----
% 
% To evaluate code without including the code or results in the generated
% Jade file, use a section whose header is #%enjaden:hide, such as:
%
%   %% %#enjaden:hide
%   set(h, 'Color', 'w'); % Make figure background white, but don't show it
%
% To evaluate code without including the code, but including figure output;
%
%   %% %#enjaden:capture
%   set(h, 'Color', [[1 0.5 0.5]); % Make background pink and show it.
% 
% These will appear in the generated Jade as a comment, but the comment
% *will* be evaluated when "evaluating" the jade with ml2jade.
%
% To tell jade to evaluate something that's actually a comment in the code:
% 
%   %#enjaden:disp('You''ll only see this when rendering!');

    % Set a default file, just as an example.
    if nargin < 1
        enjaden('enjaden_example.m', 'jade', [], true, true);
        return;
    end
    
    % Drop the path from the input file name and the .m.
    [file_in_dir, base_name] = fileparts(which(file_in_name));
    
    % By default (and unless we're just running the example file), use the 
    % input directory as the output directory.
    if (nargin < 2 || isempty(out_dir)) && nargin ~= 0
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
    
    % If the out_dir is actually a file, extract the path and file
    % separately.
    if ~isempty(regexp(out_dir, '\.jade$', 'once'))
        
        % Use the output name.
        [out_dir, out_file, out_ext] = fileparts(out_dir);
        out_file = [out_file out_ext];
        
    else
        
        % Create a name for the out file.
        out_file = [base_name '.jade'];
        if evaluate
            out_file = ['_' out_file];
        end

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
    
    % Try everything so we can catch and clean up before the error is
    % rethrown.
    success = false;
    try

        % Load the file all at once.
        original_text = fileread(file_in_name);
        foid = fopen([out_dir filesep out_file], 'w');

        % Normalize line endings for posix and tack on %% at the end (which
        % we'll ignore).
        text = [regexprep(original_text, '\r', '') ...
                sprintf('\n\n%%%%\n')];

        % See if it's a function. All we do for functions is put the title
        % up top. The rest will be treated as a block of code.
%         run_function = false;
        if regexp(text, '^\s*function')
            [~, title] = fileparts(file_in_name);
            text = sprintf('%%%% %s\n\n%s', title, text);
%             run_function = true;
        end
            
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
        page_header = regexpreplit(page_header, ...
                                   '<ml2jade=page_title>', ...
                                   title);

        % Get the nominal spacing.
        page_spaces  = regexp(template, ...
                           '(\ *)<ml2jade=page_content>[\n\r$]', 'tokens');
        page_spaces  = page_spaces{1}{1};
        block_spaces = [page_spaces, '  '];

        % Get the spaces for the table of contents (if it's there at all).
        toc_spaces = regexp(template, ...
                           '(\ *)<ml2jade=page_toc>[\n\r$]', 'tokens');
        use_toc = false;
        if ~isempty(toc_spaces)
            use_toc = true;
            toc_spaces = toc_spaces{1}{1};
        end
        
        % Look for section breaks.
        [starts, stops, cells] = regexp(text, ...
                                 '(?<=(^|[\n\r]))%%[\t\ ]*(.*?)[\n\r]', ...
                                 'start', 'end', 'tokens');
        
        % Build the TOC.
        if use_toc
            
            % Look for non-empty headers.
            toc = {};
            for k = 2:length(cells)-1
                header = replace_inline(cells{k}{1});
                if    length(header) > 10 ...
                   && strcmp(header(1:10), '%#enjaden:')
                    % ...
                elseif regexp(header, '\S')
                    toc{end+1} = header; %#ok<AGROW>
                end
            end

            % Add the TOC to the header/footer.
            if ~isempty(toc)
                for k = 1:length(toc)
                    toc{k} = sprintf([toc_spaces ...
                                      '  li: a(href="#%d") %s'], ...
                                     k, toc{k}); %#ok<AGROW>
                end
                toc_text = [sprintf('ol\n'), sprintf('%s\n', toc{:})];
                toc_text(end) = []; % Remove the last newline.
                page_header = regexpreplit(page_header, ...
                                           '<ml2jade=page_toc>', toc_text);
                page_footer = regexpreplit(page_footer, ...
                                           '<ml2jade=page_toc>', toc_text);
            end
                
        end % use_toc

        % Add in the page header.
        fprintf(foid, '%s', page_header);
                             
        % Now do the code bits.
        toc_count = 0;
        for k = 1:length(cells)-1

            fprintf(foid, '\n');

            % Pull the header and make it an h2.
            header = replace_inline(cells{k}{1});
            cell_is_hidden = false;
            if ~isempty(header)
                if k == 1
                    % Let the template handle the title.
                    %fprintf(foid, '%sh1 %s\n', page_spaces, header);
                else
                    if    length(header) > 10 ...
                       && strcmp(header(1:10), '%#enjaden:')
                        fprintf(foid, '%s//- %s\n', page_spaces, header);
                        cell_is_hidden = true;
                    else
                        if use_toc
                            toc_count = toc_count + 1;
                            fprintf(foid, '%sh2(id="%d") %s\n', ...
                                    page_spaces, toc_count, header);
                        else
                            fprintf(foid, '%sh2 %s\n', ...
                                    page_spaces, header);
                        end
                    end
                end
            else
                fprintf(foid, '%s// cell %d\n', page_spaces, k);
            end

            % Pull out this section.
            section = text(stops(k)+1:starts(k+1)-1);

            % Look for a blurb and bit of code.
            % results = regexp(section, '^(%.*?)\n([^%].*)', 'tokens');
            blurb = regexp(section, '^(%.*?)(\n[^%]|$)', 'tokens');
            code  = regexp(section, '(^|\n)([^%].*)', 'tokens');
            if ~isempty(blurb)

                % Extract the parts.
                blurb = blurb{1}{1};

                % Drop the '% 's.
                blurb = regexprep(blurb, '(?<=(\n|^))%\ ?', '');
                
                % Now handle each paragraph of the blurb.
                handle_blurb(foid, page_spaces, block_spaces, blurb);

            end
            
            % See if there's code.
            if ~isempty(code) && any(regexp(code{1}{2}, '\S'))
                code = code{1}{2};
                code = strtrim(code);
                if ~cell_is_hidden
                    code = [block_spaces '| ' regexprep(code, ...
                                          '\n', ['\n' block_spaces '| '])];
                    fprintf(foid, '%spre.eval: code\n', page_spaces);
                    fprintf(foid, '%s\n', code);
                else
                    code = [block_spaces '| ' regexprep(code, ...
                                          '\n', ['\n' block_spaces '| '])];
                    fprintf(foid, '%s//-\n', page_spaces);
                    fprintf(foid, '%s\n', code);
                end
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
        text = [block_spaces '| ' ...
                regexprep(text, '\n', ['\n' block_spaces '| '])];
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
            for tries = 1:50
                clear(out_file);
                pause(0.001);
                if exist(out_file, 'file')
                    delete(out_file);
                    break;
                end
                pause(0.01);
            end
        end
        
    % If there was an error...
    catch err
        clean_up();
        rethrow(err);
    end

end % enjaden

%%%%%%%%%%%%%%%%
% handle_blurb %
%%%%%%%%%%%%%%%%

function handle_blurb(foid, page_spaces, block_spaces, blurb)


    % Pick the paragraphs.
    paragraphs = regexp(blurb, '(.*?)(\n\s*\n|$)', 'tokens');

    % For each paragraph...
    for p = 1:length(paragraphs)
        handle_paragraph(foid, ...
                         page_spaces, ...
                         block_spaces, ...
                         paragraphs{p}{1});
    end
                
end % handle_blurb

%%%%%%%%%%%%%%%%%%%%
% handle_paragraph %
%%%%%%%%%%%%%%%%%%%%

function handle_paragraph(foid, page_spaces, block_spaces, paragraph)

    % Trim the newlines off of the paragraph.
    paragraph = regexprep(paragraph, '(^\n+|\n*$)', '');

    % True if we should replace things like *this* in the text.
    do_replacements = true;

    % Code
    if length(paragraph) > 2 && all(paragraph(1:2) == ' ')

        fprintf(foid, '%spre: code\n', page_spaces);
        do_replacements = false;
        type = 'code';

    % Pre
    elseif length(paragraph) > 1 && paragraph(1) == ' '

        fprintf(foid, '%spre\n', page_spaces);
        do_replacements = false;
        type = 'pre';

    % Block equations
    elseif    length(paragraph) > 2 ...
           && all(paragraph(1:2) == '$$')

        do_replacements = false;
        type = '';

    % Bullets
    elseif length(paragraph) > 1 && paragraph(1) == '*'

        fprintf(foid, '%sul\n', page_spaces);
        type = 'ul';

    % Numbered lists
    elseif length(paragraph) > 1 && paragraph(1) == '#'

        fprintf(foid, '%sol\n', page_spaces);
        type = 'ol';

    % Table
    elseif    length(paragraph) > 2 ...
           && all(paragraph(1:2) == '+-')

        % type = 'table';

        % Parse the first line and start the table.
        first_line = paragraph(1:find(paragraph == sprintf('\n'), ...
                                      1, 'first') - 1);
        if any(first_line == '(')
            attr_start = find(first_line == '(', 1);
            attr_stop  = find(first_line == ')', 1, 'last');
            attributes = first_line(attr_start:attr_stop);
            fprintf(foid, '%stable%s\n', page_spaces, attributes);
        else
            fprintf(foid, '%stable\n', page_spaces);
        end

        % Use the line breaks to turn the text into cells.
        matches = regexp(paragraph, '[^\n]*?(?=(\n|$))', 'match');
        padded = char(matches{:});
        rows = find(padded(:, 1) == '+');
        cols = find(padded(1, :) == '+');
        cols(end) = size(padded, 2)+2;
        
        % Process each cell of the table.
        for r = 1:length(rows)-1
            
            fprintf(foid, '%str\n', [page_spaces '  ']);
            for c = 1:length(cols)-1
                
                % If it's a header, output a th; otherwise, td.
                if    any(padded(rows(r):rows(r+1)-1, 1) == 'h') ...
                   || any(padded(1, cols(c):cols(c+1)-2) == 'h')
                    fprintf(foid, '%sth\n', [page_spaces '    ']);
                else
                    fprintf(foid, '%std\n', [page_spaces '    ']);
                end
                
                % Go from the padded string back to a single string.
                cell = padded(rows(r)+1:rows(r+1)-1, ...
                              cols(c)+2:cols(c+1)-2);
                cell = [cell, repmat(sprintf('\n'), size(cell, 1), 1)]; %#ok<AGROW>
                cell = cell.';
                cell = cell(:).';
                
                % Remove all the extra spaces at the beginning and end.
                cell = regexprep(cell, '^\s+\n', '');
                cell = regexprep(cell, '\s+$', '');
                
                % Now handle this cell as its own paragraph.
                handle_blurb(foid, ...
                             [page_spaces '      '], ...
                             [block_spaces '      '], ...
                             cell);
                
            end % columns
            
        end % rows
        
        % There's nothing left for this paragraph.
        return;

    % Otherwise, it's a normal paragraph.
    else

        fprintf(foid, '%sp\n', page_spaces);
        type = 'p';

    end

    % Replace things inside the paragraph (unless it's pre or code).
    if do_replacements
        paragraph = replace_inline(paragraph, type);
    end

    % Adding spacing and stuff like 'ul '.
    paragraph = add_prefix(type, paragraph, block_spaces);

    % Place into the Jade.
    fprintf(foid, '%s\n', paragraph);

end % handle_paragraph

%%%%%%%%%%%%%%%%%%
% replace_inline %
%%%%%%%%%%%%%%%%%%

% Replace inline expressions.
function paragraph = replace_inline(paragraph, type)

    if nargin < 2, type = ''; end;

    % Replace %#ok<whatever, else>.
    paragraph = regexprep(paragraph, ...
                          '(%#ok)<(.*?)>', '$1&lt;$2&gt;');
    
    % Replace inline equations. Note that display equations need
    % not be replaced! This is one of the ugliest regexps I've ever
    % written. We want (beginning of string or something that's not
    % a $), followed by $, followed by anything that isn't a $,
    % followed by (end of string or anything that's not a $). We
    % can to replace abc$xyz$def with abc\(xyz\)def.
    paragraph = regexprep(paragraph, ...
                          '(?<=(^|[^\$]))\$([^\$]+?)\$(?=([^\$]|$))', ...
                          '\\\($1\\\)');

    % Links (first as <link> and then <link text>).
    paragraph = regexprep(paragraph, ...
                         '(?<=(^|[^<]))<(\S+)>(?=([^>]|$))', ...
                         '<$1 $1>');
    paragraph = regexprep(paragraph, ...
                         '(?<=(^|[^<]))<(\S+)\ ?(.*?)>(?=([^>]|$))', ...
                         '<a href="$1">$2</a>');

    % Embolden.
    if strcmp(type, 'ul');
        paragraph = regexprep(paragraph, ...
                 '([^\n])\*(.+?[^\n])\*(\W|$)', '$1<strong>$2</strong>$3');
    else
        paragraph = regexprep(paragraph, ...
                         '\*(\S[^\*]+?)\*(\W|$)', '<strong>$1</strong>$2');
    end

    % Italic.
    paragraph = regexprep(paragraph, '_(\w.+?)_(\W|$)', '<em>$1</em>$2');

    % Code.
    paragraph = regexprep(paragraph, ...
                          '(?<=(^|[^\\]))\|(.+?)\|', ...
                          '<code>$1</code>');

    % Image.
    paragraph = regexprep(paragraph, '<<(.*?)>>', '<img src="$1">');

end % replace_inline

%%%%%%%%%%%%%%
% add_prefix %
%%%%%%%%%%%%%%

% Add spacing and stuff like 'li'.
function paragraph = add_prefix(type, paragraph, block_spaces)

    % True if we should add the bar when adding spaces.
    add_bar = true;

    % Add the spaces for the block.
    switch type

        case 'code'
            
            % Remove unnecessary spaces.
            paragraph = regexprep(paragraph, '(^|\n)\ \ ', '$1');
            paragraph = regexprep(paragraph, '<', '&lt;');
            paragraph = regexprep(paragraph, '>', '&gt;');
                     
        case 'pre'
            
            % Remove unnecessary space.
            paragraph = regexprep(paragraph, '(^|\n)\ ', '$1');
                     
        case 'ol'
            
            % Add li.
            paragraph = regexprep(paragraph, '(^|\n)\#\ ', '$1li\n\ \ ');
            paragraph = regexprep(paragraph, '\n\ \ ', '\n\ \ |\ ');
            add_bar = false;
                     
        case 'ul'
            
            % Add li.
            paragraph = regexprep(paragraph, '(^|\n)\*\ ', '$1li\n\ \ ');
            paragraph = regexprep(paragraph, '\n\ \ ', '\n\ \ |\ ');
            add_bar = false;

    end
            
    % Prefix the spaces.
    if add_bar
        paragraph = [block_spaces '| ' ...
                     regexprep(paragraph, '\n', ['\n' block_spaces '| '])];
    else
        paragraph = [block_spaces ...
                     regexprep(paragraph, '\n', ['\n' block_spaces])];
    end
                    
end % add_prefix

%%%%%%%%%%%%%%%%
% regexpreplit %
%%%%%%%%%%%%%%%%

% Replace matches with a literal string.
function s = regexpreplit(s, p, r)
    s = regexprep(s, p, regexptranslate('escape', r));
end % regexpreplit
