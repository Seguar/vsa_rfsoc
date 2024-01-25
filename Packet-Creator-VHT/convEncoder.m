function coded_bits = convEncoder(bits,R)

t = poly2trellis(7,[133 171]); % Define trellis.
coded_bits = convenc(bits,t);  % Encoder

ind = 1:length(coded_bits);

switch R
    case (1/2)
        return;
    case (3/4)
        ind([4:6:length(ind) 5:6:length(ind)]) = [];
        coded_bits = coded_bits(ind);
    case (2/3)
        ind(3:4:length(ind)) = [];
        coded_bits = coded_bits(ind);
    case (5/6)
        ind_resedue = mod(length(ind),10);
        ind_Tail = ind(end-ind_resedue+1:end);
        ind_wo_Tail = ind(1:end-ind_resedue);
        indMatrix = reshape(ind_wo_Tail,10,[]);
        indMatrix([4:4:size(indMatrix,1) 5:4:size(indMatrix,1)],:) = [];
        ind_Tail([4:4:length(ind_Tail) 5:4:length(ind_Tail)]) = [];
        ind = [reshape(indMatrix,1,[])  ind_Tail];
        coded_bits = coded_bits(ind);
end