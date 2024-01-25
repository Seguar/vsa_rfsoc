function [BCCstream1, BCCstream2] = encoderParcer(bitStream, Nes, Nsym, Ndbps)

matrix = zeros(Nes, Nsym*Ndbps/Nes);
for j = 0:Nes-1
    for i = 0:Nsym*Ndbps/Nes-6-1
        matrix(j+1, i+1) = bitStream(Nes*i+j+1);
    end
end

BCCstream1 = matrix(1, :);
BCCstream2 = matrix(2, :);

end