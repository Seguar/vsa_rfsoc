function modSymbol = VHT_subModMap( symBitStream )
switch length(symBitStream)
    case {52, 108, 234} %BPSK
        K_mod = 1;
        I = symBitStream-(symBitStream == 0);
        Q = zeros(1,length(I));
    case {52*2, 108*2, 234*2} %QPSK
        K_mod = 1/power(2,0.5);
        b0_b1_matrix = reshape(symBitStream,2,[]);
        I = b0_b1_matrix(1,:)-(b0_b1_matrix(1,:)== 0);
        Q = b0_b1_matrix(2,:)-(b0_b1_matrix(2,:)== 0);
    case {52*4, 108*4, 234*4} %16 - QAM
        K_mod = 1/power(10,0.5);
        b0_b1_b2_b3_matrix = reshape(symBitStream,4,[]);
        I = ones(1, length(symBitStream)/4);
        Q = ones(1, length(symBitStream)/4);
        I ((b0_b1_b2_b3_matrix(1,:)+b0_b1_b2_b3_matrix(2,:)) == 0) = -3;
        I ((b0_b1_b2_b3_matrix(1,:)-b0_b1_b2_b3_matrix(2,:)) == 1) = 3;
        I ((b0_b1_b2_b3_matrix(1,:)-b0_b1_b2_b3_matrix(2,:)) == -1) = -1;
        Q ((b0_b1_b2_b3_matrix(3,:)+b0_b1_b2_b3_matrix(4,:)) == 0) = -3;
        Q ((b0_b1_b2_b3_matrix(3,:)-b0_b1_b2_b3_matrix(4,:)) == 1) = 3;
        Q ((b0_b1_b2_b3_matrix(3,:)-b0_b1_b2_b3_matrix(4,:)) == -1) = -1;
    case {52*6, 108*6, 234*6} %64 - QAM
        K_mod = 1/power(42, 0.5);
        b0_to_b5_matrix = reshape(symBitStream,6,[]);
        I = ones(1, length(symBitStream)/6);
        Q = ones(1, length(symBitStream)/6);
        I ((b0_to_b5_matrix(1,:) == 0) + (b0_to_b5_matrix(2,:) == 0) + (b0_to_b5_matrix(3,:)==0) == 3) = -7;
        I ((b0_to_b5_matrix(1,:) == 0) + (b0_to_b5_matrix(2,:) == 0) + (b0_to_b5_matrix(3,:) == 1) == 3) = -5;
        I ((b0_to_b5_matrix(1,:) == 0) + (b0_to_b5_matrix(2,:) == 1) + (b0_to_b5_matrix(3,:) == 1) == 3) = -3;
        I ((b0_to_b5_matrix(1,:) == 0) + (b0_to_b5_matrix(2,:) == 1) + (b0_to_b5_matrix(3,:) == 0) == 3) = -1;
        I ((b0_to_b5_matrix(1,:) == 1) + (b0_to_b5_matrix(2,:) == 1) + (b0_to_b5_matrix(3,:) == 1) == 3) = 3;
        I ((b0_to_b5_matrix(1,:) == 1) + (b0_to_b5_matrix(2,:) == 0) + (b0_to_b5_matrix(3,:) == 1) == 3) = 5;
        I ((b0_to_b5_matrix(1,:) == 1) + (b0_to_b5_matrix(2,:) == 0) + (b0_to_b5_matrix(3,:) == 0) == 3) = 7;
        Q ((b0_to_b5_matrix(4,:) == 0) + (b0_to_b5_matrix(5,:) == 0) + (b0_to_b5_matrix(6,:)==0) == 3) = -7;
        Q ((b0_to_b5_matrix(4,:) == 0) + (b0_to_b5_matrix(5,:) == 0) + (b0_to_b5_matrix(6,:) == 1) == 3) = -5;
        Q ((b0_to_b5_matrix(4,:) == 0) + (b0_to_b5_matrix(5,:) == 1) + (b0_to_b5_matrix(6,:) == 1) == 3) = -3;
        Q ((b0_to_b5_matrix(4,:) == 0) + (b0_to_b5_matrix(5,:) == 1) + (b0_to_b5_matrix(6,:) == 0) == 3) = -1;
        Q ((b0_to_b5_matrix(4,:) == 1) + (b0_to_b5_matrix(5,:) == 1) + (b0_to_b5_matrix(6,:) == 1) == 3) = 3;
        Q ((b0_to_b5_matrix(4,:) == 1) + (b0_to_b5_matrix(5,:) == 0) + (b0_to_b5_matrix(6,:) == 1) == 3) = 5;
        Q ((b0_to_b5_matrix(4,:) == 1) + (b0_to_b5_matrix(5,:) == 0) + (b0_to_b5_matrix(6,:) == 0) == 3) = 7;
    case {108*8, 234*8, 234*8} %256 - QAM
        K_mod = 1/power(170, 0.5);
        IQ_Values = -15:2:15;
        symBitStream = round(rand(234*8,1));
        b0_to_b7_matrix = reshape(symBitStream,8,[]);        
        b0_to_b7_dec = bi2de(b0_to_b7_matrix','left-msb');
        I = ones(1, length(symBitStream)/8);
        Q = ones(1, length(symBitStream)/8);
        x = (0:255);
        [y,map] = bin2gray(x','qam',256);
        GrayMatrix = reshape(map,[],16);

        for i = 1:length(symBitStream)/8
            [row,col]=find(b0_to_b7_dec(i) == GrayMatrix);
            I(i) = IQ_Values(col);
            Q(i) = IQ_Values(row);
        end        
end

modSymbol = (I + 1i.*Q).*K_mod;

end