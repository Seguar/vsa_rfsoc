function Y_k_l = Segment_Parsing_160MHz( X_j, Nes, Ncbps, Nbpsc )

s = max([1 Nbpsc/2]);

k1 = 0:floor(Ncbps/(2*s*Nes))*s*Nes-1;
k2 = floor(Ncbps/(2*s*Nes))*s*Nes:Ncbps/2-1 ;

j_l1 = zeros(1,length([k1 k2]));
j_l2 = zeros(1,length([k1 k2]));

if( mod(Ncbps, 2*s*Nes) == 0)
    j_l1 = [ 2*s*Nes.*floor(k1./(s*Nes)) + 0*s*Nes + mod(k1, s*Nes) ...
             2*s*Nes.*floor(k2./(s*Nes)) + 0*s + mod(k2, s) ];
    j_l2 = [ 2*s*Nes.*floor(k1./(s*Nes)) + 1*s*Nes + mod(k1, s*Nes) ...
             2*s*Nes.*floor(k2./(s*Nes)) + 1*s + mod(k2, s) ];
else
    j_l1 = [ 2*s*Nes.*floor(k1./(s*Nes)) + 0*s*Nes + mod(k1, s*Nes) ...
             2*s*Nes.*floor(k2./(s*Nes)) + 0*s + mod(k2, s) + 2*s.*floor(mod(k,s*Nes)/s) ];
    j_l2 = [ 2*s*Nes.*floor(k1./(s*Nes)) + 1*s*Nes + mod(k1, s*Nes) ...
             2*s*Nes.*floor(k2./(s*Nes)) + 1*s + mod(k2, s) + 2*s.*floor(mod(k,s*Nes)/s) ];
end
Y_k_l = zeros(2,length([k1 k2]));
Y_k_l(1,[k1 k2]+1) = X_j(j_l1+1);
Y_k_l(2,[k1 k2]+1) = X_j(j_l2+1);

end