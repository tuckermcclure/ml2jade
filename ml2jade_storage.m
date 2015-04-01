function varargout = ml2jade_storage(cmd, line)

% ml2jade_storage
% 
% This function holds on to lines of code with:
%
%     ml2jade_storage('add', line);
%
% until they are requested from the base workspace with:
%
%     lines = ml2jade_storage();
%
% after which the storage is reset with:
%
%    ml2jade_storage('reset');
%
% This enables a call to evalc to return all of the variables, such as:
%
%    output = evalin('base', 'evalc(''ml2jade_storage()'')');

    persistent lines;
    
    if nargout == 1, varargout{1} = lines; end;
    if nargin  == 0, return;               end;
    
    switch cmd
        
        case 'reset'
            lines = [];
            
        case 'add'
            lines = [lines sprintf('\n') line];
        
    end

end
