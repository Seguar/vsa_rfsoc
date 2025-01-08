function lineHandle = guiXline(lineHandle, handles, type, value, position)

if isempty(lineHandle) || ~isvalid(lineHandle)
    % Create line: 1st input is axis handle
    lineHandle = xline(handles, 0, type.line, {type.txt}); 
end
lineHandle.Value = 0;
lineHandle.LineWidth = 2;
lineHandle.FontSize = 16;
lineHandle.LabelVerticalAlignment = 'middle';
lineHandle.LabelHorizontalAlignment = position;
% Update line position
if ~isnan(value)
    lineHandle.Value = value; 
end