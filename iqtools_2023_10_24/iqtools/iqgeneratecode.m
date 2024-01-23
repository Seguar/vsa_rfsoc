% generate MATLAB code for IQTools functions
function iqgeneratecode(~, code)
h = iqcodeview('text', sprintf('%%\n%% automatically generated code by IQTools\n%%\n%s\n', code));

