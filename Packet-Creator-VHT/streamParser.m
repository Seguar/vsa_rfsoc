function decodedData = streamParser(streamBCC1, streamBCC2, N_cbps, N_bpsc, Nes)
if size(streamBCC1,1) > 1
    streamBCC1 = streamBCC1';
end
if size(streamBCC2,1) > 1
    streamBCC2 = streamBCC2';
end

matrix = [streamBCC1; streamBCC2];

s = max(N_bpsc/2,1);
decodedData = zeros(1,N_cbps);

for k = 0:N_cbps-1;
    j = mod(floor(k/s),Nes);
    i = floor(k/(Nes*s))+mod(k,s);
    decodedData(k+1) = matrix(j+1, i+1);
end
end