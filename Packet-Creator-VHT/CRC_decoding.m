function CRC_out = CRC_decoding(HT_SIG_bits)

%HT_SIG_bits = [1 1 1 1 0 0 0 1 0 0 1 0 0 1 1 0 0 0 0 0 0 0 0 0 1 1 1 0 0 0 0 0 0 0];% Test Vector result must be CRC_out = 10101000

D = [1,1,1,1,1,1,1,1];
D_nextStep = zeros(1,length(D));
for i = 1:length(HT_SIG_bits)
    feedback = mod(D(1)+HT_SIG_bits(i),2);
    D_nextStep(1:end-1) = D(2:end);
    D_nextStep(end) = feedback;
    D_nextStep(end - 1) = mod(feedback+D(end-0),2);
    D_nextStep(end - 2) = mod(feedback+D(end-1),2);
    D = D_nextStep;
end
CRC_out = mod(D+1,2);% Result (see check vector), encoder output

end