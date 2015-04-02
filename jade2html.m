function success = jade2html(file)

% jade2html
%
% Render the input Jade file to HTML.
%
% This requires Jade to be installed on the system path. To install Jade,
% you can use the Node Package Manager*:
%
%   npm install jade -g
%
% The default template also uses Stylus, so you may wish to add Stylus too:
%
%   npm install stylus -g
%
% You may need to use 'sudo' before each of those commands on OS X or
% Linux.
%
% * Node (and the Node Package Manager, npm) can be installed from
%   www.nodejs.org.
%
% Inputs:
%
% file     Name of file (relative or absolute)
%
% Outputs:
%
% success  True iff Jade returns "ok" (presumably, file is rendered)
%

    success = false;
    
    % Look for Jade on the path.
    found_jade = false;
    if exist('jade', 'file')
        
        [status, ~] = system('jade --version');
        found_jade = ~status;
        
    % Look for Jade where it typically gets installed.
    elseif ~ispc && exist('/usr/local/bin/jade', 'file')
        
        % We found it, but it's not on the path. Add the path to this
        % shell's PATH variable.
        original_path = getenv('PATH');
        setenv('PATH', [original_path ':/usr/local/bin/']);
        
        % Now make sure it works.
        [status, ~] = system('jade --version');
        found_jade = ~status;
        
    end
    
    if found_jade
        
        % If we found, run it. Status is 0 if there were no errors.
        [status, out] = system(sprintf('jade %s', file));
        success = ~status;
        if ~success
            warning(out);
        end
        
    else
        warning(['jade is not on the system path; enjaden could '...
                 'not render the Jade file to HTML.']);
    end
    
end
