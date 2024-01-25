function gamma = Gamma(BW_channel)
switch BW_channel
    case 20
        gamma = ones(1, 26*2 +1);
    case 40
        gamma = [ones(1, 58) 1i 1i.*ones(1, 58)];
    case 80
        gamma = [ones(1, 58) -ones( 1, 245-58)];
    case 160
        gamma = [ones(1, 58) -ones(1, 192) ones(1,64) -ones(1, 250-63)];
end;