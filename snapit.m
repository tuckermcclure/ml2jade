function snapit(varargin)

% snapit
% 
% Like MATLAB's built-in 'snapnow', but works with ml2jade. It can also
% snap a section of a figure instead of a whole figure.
%
%   snapit(); % A drop-in replacement for snapnow().
%   snapit(h, xywh); % Record a section, xywh, of a figure, h.

    if nargin == 0
        
        % Use this instead of snapnow to prevent weirdness.
        evalin('base', 'evalc(''snapnow'');');
        
    elseif nargin >= 2

        % Get the coordinates from the indicated figure.
        h     = varargin{1};
        xywh  = varargin{2};
        frame = getframe(h, xywh);
        
        % Show them elsewhere.
        h_temp = figure();
        imshow(frame.cdata);
        snapit();
        if nargin < 3 || ~varargin{3}
            close(h_temp);
        end
        
    end

end % snapit

