function lineHandle = guiXline(lineHandle, handles, type, value)

if isempty(lineHandle) || ~isvalid(lineHandle)
    % Create line: 1st input is axis handle
    lineHandle = xline(handles, 0, type.line, {type.txt}); 
end
lineHandle.Value = 0;
% Update line position
if ~isnan(value)
    lineHandle.Value = value; 
end