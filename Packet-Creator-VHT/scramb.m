function Data_after_csr = scramb(Data_befor_csr, registerInit)
Data_after_csr = [];

for(i = 1:length(Data_befor_csr))
    registerInit = [registerInit  xor(registerInit(end-6),registerInit(end-3))];
    Data_after_csr = [Data_after_csr xor(Data_befor_csr(i),registerInit(end))];
end

end
