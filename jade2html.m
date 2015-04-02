function success = jade2html(file)

% jade2html
%
% Render the input Jade file to HTML.
%
% This requires Jade to be installed on the system path. To install Jade,
% you can use the Node Package Manager:
%
%   npm install jade -g
%
% The default template also uses Stylus, so you may wish to add Stylus too:
%
%   npm install stylus -g
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
    
    % Look for Jade.
    [status, ~] = system('jade --version');
    if ~status
        
        % If we found, run it. Status is 0 if there were no errors.
        [status, out] = system(sprintf('jade %s', file));
        success = ~status;
        if ~success
            warning(out);
        end
        
    else
        warning(['jade is not on the system path. enjaden could '...
                 'not render the Jade file to HTML.']);
    end
    
end
