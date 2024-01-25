function RateParams = RateTable(Rate)

switch Rate
    case 6
      RateParams.N_bpsc = 1;
      RateParams.N_cbps = 48;
      RateParams.CodeRate = 1/2;
      RateParams.RateBits = [1 1 0 1];
    case 9
      RateParams.N_bpsc = 1;
      RateParams.N_cbps = 48;
      RateParams.CodeRate = 3/4;
      RateParams.RateBits = [1 1 1 1];
    case 12
      RateParams.N_bpsc = 2;
      RateParams.N_cbps = 48*2;
      RateParams.CodeRate = 1/2;
      RateParams.RateBits = [0 1 0 1];
    case 18
      RateParams.N_bpsc = 2;
      RateParams.N_cbps = 48*2;
      RateParams.CodeRate = 3/4; 
      RateParams.RateBits = [0 1 1 1];
    case 24
      RateParams.N_bpsc = 4;
      RateParams.N_cbps = 48*4;
      RateParams.CodeRate = 1/2; 
      RateParams.RateBits = [1 0 0 1];
    case 36
      RateParams.N_bpsc = 4;
      RateParams.N_cbps = 48*4;
      RateParams.CodeRate = 3/4;
      RateParams.RateBits = [1 0 1 1];
    case 48
      RateParams.N_bpsc = 6;
      RateParams.N_cbps = 48*6;
      RateParams.CodeRate = 1/2; 
      RateParams.RateBits = [0 0 0 1];
    case 54
      RateParams.N_bpsc = 6;
      RateParams.N_cbps = 48*6;
      RateParams.CodeRate = 3/4; 
      RateParams.RateBits = [0 0 1 1];
end

end