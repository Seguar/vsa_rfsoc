%
% test if the communication to the Rcal module works
% returns IDN string if successful, otherwise an empty result
%
function id = testRcalConnection(visaAddr)
id = [];
f = iqopen(visaAddr);
if (~isempty(f))
    id = strtrim(query(f, '*IDN?'));
    % t.b.d.: check, if the IDN string contains the expected value
    fclose(f);
end

