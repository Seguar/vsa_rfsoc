function MCSParams = VHT_MCSTable(MCS, BW_channel)

if BW_channel == 20
    switch MCS
        case 0
          MCSParams.N_bpsc = 1;
          MCSParams.N_cbps = 52;
          MCSParams.N_dbps = 26;
          MCSParams.CodeRate = 1/2;
        case 1
          MCSParams.N_bpsc = 2;
          MCSParams.N_cbps = 104;
          MCSParams.N_dbps = 52;
          MCSParams.CodeRate = 1/2;
        case 2
          MCSParams.N_bpsc = 2;
          MCSParams.N_cbps = 104;
          MCSParams.N_dbps = 78;
          MCSParams.CodeRate = 3/4;
        case 3
          MCSParams.N_bpsc = 4;
          MCSParams.N_cbps = 208;
          MCSParams.N_dbps = 104;
          MCSParams.CodeRate = 1/2;
        case 4
          MCSParams.N_bpsc = 4;
          MCSParams.N_cbps = 208;
          MCSParams.N_dbps = 156;
          MCSParams.CodeRate = 3/4;
        case 5
          MCSParams.N_bpsc = 6;
          MCSParams.N_cbps = 312;
          MCSParams.N_dbps = 208;
          MCSParams.CodeRate = 2/3;
        case 6
          MCSParams.N_bpsc = 6;
          MCSParams.N_cbps = 312;
          MCSParams.N_dbps = 234;
          MCSParams.CodeRate = 3/4;
        case 7
          MCSParams.N_bpsc = 6;
          MCSParams.N_cbps = 312;
          MCSParams.N_dbps = 260;
          MCSParams.CodeRate = 5/6;
        case 8
          MCSParams.N_bpsc = 8;
          MCSParams.N_cbps = 416;
          MCSParams.N_dbps = 312;
          MCSParams.CodeRate = 3/4;
        case 9
          disp('MSC9 is not Valid for 20MHz signal!!!');
    end
elseif BW_channel == 40
    switch MCS
        case 0
          MCSParams.N_bpsc = 1;
          MCSParams.N_cbps = 108;
          MCSParams.N_dbps = 54;
          MCSParams.CodeRate = 1/2;
        case 1
          MCSParams.N_bpsc = 2;
          MCSParams.N_cbps = 216;
          MCSParams.N_dbps = 108;
          MCSParams.CodeRate = 1/2;
        case 2
          MCSParams.N_bpsc = 2;
          MCSParams.N_cbps = 216;
          MCSParams.N_dbps = 162;
          MCSParams.CodeRate = 3/4;
        case 3
          MCSParams.N_bpsc = 4;
          MCSParams.N_cbps = 432;
          MCSParams.N_dbps = 216;
          MCSParams.CodeRate = 1/2;
        case 4
          MCSParams.N_bpsc = 4;
          MCSParams.N_cbps = 432;
          MCSParams.N_dbps = 324;
          MCSParams.CodeRate = 3/4;
        case 5
          MCSParams.N_bpsc = 6;
          MCSParams.N_cbps = 648;
          MCSParams.N_dbps = 432;
          MCSParams.CodeRate = 2/3;
        case 6
          MCSParams.N_bpsc = 6;
          MCSParams.N_cbps = 648;
          MCSParams.N_dbps = 486;
          MCSParams.CodeRate = 3/4;
        case 7
          MCSParams.N_bpsc = 6;
          MCSParams.N_cbps = 648;
          MCSParams.N_dbps = 540;
          MCSParams.CodeRate = 5/6;
        case 8
          MCSParams.N_bpsc = 8;
          MCSParams.N_cbps = 864;
          MCSParams.N_dbps = 648;
          MCSParams.CodeRate = 3/4;
        case 9
          MCSParams.N_bpsc = 8;
          MCSParams.N_cbps = 864;
          MCSParams.N_dbps = 720;
          MCSParams.CodeRate = 5/6;
    end
    elseif BW_channel == 80
    switch MCS
        case 0
          MCSParams.N_bpsc = 1;
          MCSParams.N_cbps = 234;
          MCSParams.N_dbps = 117;
          MCSParams.CodeRate = 1/2;
        case 1
          MCSParams.N_bpsc = 2;
          MCSParams.N_cbps = 468;
          MCSParams.N_dbps = 234;
          MCSParams.CodeRate = 1/2;
        case 2
          MCSParams.N_bpsc = 2;
          MCSParams.N_cbps = 468;
          MCSParams.N_dbps = 351;
          MCSParams.CodeRate = 3/4;
        case 3
          MCSParams.N_bpsc = 4;
          MCSParams.N_cbps = 936;
          MCSParams.N_dbps = 468;
          MCSParams.CodeRate = 1/2;
        case 4
          MCSParams.N_bpsc = 4;
          MCSParams.N_cbps = 936;
          MCSParams.N_dbps = 702;
          MCSParams.CodeRate = 3/4;
        case 5
          MCSParams.N_bpsc = 6;
          MCSParams.N_cbps = 1404;
          MCSParams.N_dbps = 936;
          MCSParams.CodeRate = 2/3;
        case 6
          MCSParams.N_bpsc = 6;
          MCSParams.N_cbps = 1404;
          MCSParams.N_dbps = 1053;
          MCSParams.CodeRate = 3/4;
        case 7
          MCSParams.N_bpsc = 6;
          MCSParams.N_cbps = 1404;
          MCSParams.N_dbps = 1170;
          MCSParams.CodeRate = 5/6;
        case 8
          MCSParams.N_bpsc = 8;
          MCSParams.N_cbps = 1872;
          MCSParams.N_dbps = 1404;
          MCSParams.CodeRate = 3/4;
        case 9
          MCSParams.N_bpsc = 8;
          MCSParams.N_cbps = 1872;
          MCSParams.N_dbps = 1560;
          MCSParams.CodeRate = 5/6;
    end
    elseif BW_channel == 160
    switch MCS
        case 0
          MCSParams.N_bpsc = 1;
          MCSParams.N_cbps = 468;
          MCSParams.N_dbps = 234;
          MCSParams.CodeRate = 1/2;
        case 1
          MCSParams.N_bpsc = 2;
          MCSParams.N_cbps = 936;
          MCSParams.N_dbps = 468;
          MCSParams.CodeRate = 1/2;
        case 2
          MCSParams.N_bpsc = 2;
          MCSParams.N_cbps = 936;
          MCSParams.N_dbps = 702;
          MCSParams.CodeRate = 3/4;
        case 3
          MCSParams.N_bpsc = 4;
          MCSParams.N_cbps = 1872;
          MCSParams.N_dbps = 936;
          MCSParams.CodeRate = 1/2;
        case 4
          MCSParams.N_bpsc = 4;
          MCSParams.N_cbps = 1872;
          MCSParams.N_dbps = 1404;
          MCSParams.CodeRate = 3/4;
        case 5
          MCSParams.N_bpsc = 6;
          MCSParams.N_cbps = 2808;
          MCSParams.N_dbps = 1872;
          MCSParams.CodeRate = 2/3;
        case 6
          MCSParams.N_bpsc = 6;
          MCSParams.N_cbps = 2808;
          MCSParams.N_dbps = 2106;
          MCSParams.CodeRate = 3/4;
        case 7
          MCSParams.N_bpsc = 6;
          MCSParams.N_cbps = 2808;
          MCSParams.N_dbps = 2340;
          MCSParams.CodeRate = 5/6;
        case 8
          MCSParams.N_bpsc = 8;
          MCSParams.N_cbps = 3744;
          MCSParams.N_dbps = 2808;
          MCSParams.CodeRate = 3/4;
        case 9
          MCSParams.N_bpsc = 8;
          MCSParams.N_cbps = 3744;
          MCSParams.N_dbps = 3120;
          MCSParams.CodeRate = 5/6;
    end
else
    disp('VHT have only 20, 40, 80 and 160 MHz BW!!!');
end;

end