function wavaform = VHT_Creator(MCS, BW_channel, LENGTH,Sample_Rate, isDataRand,SaveAsPath);
%% Inputs

% SaveAsPath = 'U:\dzooyev\MATLAB\Create WFM\ESG_OFDM_sig_BPSK_VHT20MHz.csv';
% %VHT inputs
% BW_channel = 160;        % HT channel BW 20/40
% LENGTH = 5000;           % Number of octets (8 bits)
% N_tx = 1;               % The number of transmit chains.
% Sample_Rate = 200;      % Multiple value of BW_channel   
% MCS = 9;

MCSParams = VHT_MCSTable(MCS, BW_channel);

gamma = Gamma(BW_channel);

%Legacy inputs as a constants in HT Signals
Rate = 6;                         % Legacy Rate 
RateParams = RateTable(Rate);     % Legacy Parameters
N_cbps = RateParams.N_cbps;       % Number of bits in a single OFDM symbol
N_bpsc = RateParams.N_bpsc;       % Number of coded bits per subcarrier
R = RateParams.CodeRate;          % Code rate


resample_flag = 0;
switch BW_channel
    case 20
        points_FFT = 64;
        if (mod(Sample_Rate,BW_channel) == 0 && (Sample_Rate <= BW_channel*3))
            Pad_Rate = Sample_Rate/BW_channel-1;% Padding required for FFT Siganal to create signal in multiple Sample Rates of 20
        else
            Pad_Rate = (BW_channel*3)/BW_channel-1;% Padding required for FFT Siganal to create signal in multiple Sample Rates of 20
            p = Sample_Rate;
            q = BW_channel*3;
            if mod(Sample_Rate,1) ~= 0
                [a,b] = rat(Sample_Rate)
                p = a;
                q = q*b;
            end;
            resample_flag = 1;
        end
        pointsFilter8us = 159;
        pointsFilter4us = 79;
    case 40
        points_FFT = 128;
        if (mod(Sample_Rate,BW_channel) == 0 && (Sample_Rate <= BW_channel*3))
            Pad_Rate = Sample_Rate/BW_channel-1;% Padding required for FFT Siganal to create signal in multiple Sample Rates of 20
        else
            Pad_Rate = (BW_channel*3)/BW_channel-1;% Padding required for FFT Siganal to create signal in multiple Sample Rates of 20
            p = Sample_Rate;
            q = BW_channel*3;
            if mod(Sample_Rate,1) ~= 0
                [a,b] = rat(Sample_Rate);
                p = a;
                q = q*b;
            end;
            resample_flag = 1;
        end
        pointsFilter8us = 319;
        pointsFilter4us = 159;
    case 80
        points_FFT = 256;
        if (mod(Sample_Rate,BW_channel) == 0 && (Sample_Rate <= BW_channel*3))
            Pad_Rate = Sample_Rate/BW_channel-1;% Padding required for FFT Siganal to create signal in multiple Sample Rates of 20
        else
            Pad_Rate = (BW_channel*3)/BW_channel-1;% Padding required for FFT Siganal to create signal in multiple Sample Rates of 20
            p = Sample_Rate;
            q = BW_channel*3;
            if mod(Sample_Rate,1) ~= 0
                [a,b] = rat(Sample_Rate);
                p = a;
                q = q*b;
            end;
            resample_flag = 1;
        end
        pointsFilter8us = 639;
        pointsFilter4us = 319;
    case 160
        points_FFT = 512;
        if (mod(Sample_Rate,BW_channel) == 0 && (Sample_Rate <= BW_channel*3))
            Pad_Rate = Sample_Rate/BW_channel-1;% Padding required for FFT Siganal to create signal in multiple Sample Rates of 20
        else
            Pad_Rate = (BW_channel*3)/BW_channel-1;% Padding required for FFT Siganal to create signal in multiple Sample Rates of 20
            p = Sample_Rate;
            q = BW_channel*3;
            if mod(Sample_Rate,1) ~= 0
                [a,b] = rat(Sample_Rate);
                p = a;
                q = q*b;
            end;
            resample_flag = 1;
        end
        pointsFilter8us = 1279;
        pointsFilter4us = 639;
end

% Windows for 8us and 4us sigments
W_t_8us = [winEdge(Pad_Rate) ones(1,pointsFilter8us*(Pad_Rate+1)) fliplr(winEdge(Pad_Rate))]; % Pulse Shaping Filter for 8us
W_t_4us = [winEdge(Pad_Rate) ones(1,pointsFilter4us*(Pad_Rate+1)) fliplr(winEdge(Pad_Rate))];  % Pulse Shaping Filter for 4us

%% L-STF

S_26 = sqrt(1/2)*[0,0, 1+1i, 0,0,0, -1-1i, 0,0,0, 1+1i, 0,0,0, -1-1i, 0,0,0, -1-1i, 0,0,0, 1+1i, 0,0,0,...
           0,0,0,0,   -1-1i, 0,0,0, -1-1i, 0,0,0, 1+1i, 0,0,0,  1+1i, 0,0,0,  1+1i, 0,0,0, 1+1i, 0,0];
       
switch BW_channel
    case 20
        S = S_26.*gamma;
    case 40
        S_58 = [ S_26 zeros(1,11) S_26];
        S = S_58.*gamma;
    case 80
        S_58 = [ S_26 zeros(1,11) S_26];
        S_122 = [ S_58 zeros(1,11) S_58];
        S = S_122.*gamma;      
    case 160
        S_58 = [ S_26 zeros(1, 11) S_26];
        S_122 = [S_58 zeros(1, 11) S_58];
        S_250 = [S_122 zeros(1, 11) S_122];
        S = S_250.*gamma;              
end;

STF_nonHT_FFT = [zeros(1, (points_FFT/2)*Pad_Rate)  zeros(1, 6) S zeros(1,5) zeros(1, (points_FFT/2)*Pad_Rate)]; % 20/40MHz
STF_nonHT_FFT = ifftshift(STF_nonHT_FFT,2);

STF_nonHT_time = ifft(STF_nonHT_FFT);
STF_nonHT_time_out = [STF_nonHT_time STF_nonHT_time STF_nonHT_time(1:length(STF_nonHT_time)/2+1+Pad_Rate)];

N_tone_field_LSTF =  toneFieldTable('L-STF', BW_channel);
STF_nonHT_time_out = sqrt(1/N_tone_field_LSTF).*STF_nonHT_time_out.*W_t_8us;

%% L-LTF
L_26 = [1, 1,-1,-1, 1, 1,-1, 1,-1, 1, 1, 1, 1, 1, 1,-1,-1, 1, 1,-1, 1,-1, 1, 1, 1, 1, 0, ...
         1,-1,-1, 1, 1,-1, 1,-1, 1,-1,-1,-1,-1,-1, 1, 1,-1,-1, 1,-1, 1,-1, 1, 1, 1, 1];
        
switch BW_channel
    case 20
        L = L_26.*gamma;
    case 40
        L_58 = [ L_26 zeros(1,11) L_26];
        L = L_58.*gamma;
    case 80
        L_58 = [L_26 zeros(1,11) L_26];
        L_122 = [ L_58 zeros(1,11) L_58];
        L = L_122.*gamma;      
    case 160
        L_58 = [ L_26 zeros(1, 11) L_26];
        L_122 = [L_58 zeros(1, 11) L_58];
        L_250 = [L_122 zeros(1, 11) L_122];
        L = L_250.*gamma;              
end;

LTF_nonHT_FFT = [zeros(1, (points_FFT/2)*Pad_Rate) zeros(1, 6) L zeros(1,5) zeros(1, (points_FFT/2)*Pad_Rate)]; % 40MHz
LTF_nonHT_FFT = ifftshift(LTF_nonHT_FFT,2);

LTF_nonHT_time = ifft(LTF_nonHT_FFT);
LTF_nonHT_time_out = [LTF_nonHT_time(length(LTF_nonHT_time)/2+1:end ) LTF_nonHT_time LTF_nonHT_time LTF_nonHT_time(1:Pad_Rate+1)];

N_tone_field_LLTF =  toneFieldTable('L-LTF', BW_channel);
LTF_nonHT_time_out = sqrt(1/N_tone_field_LLTF)*LTF_nonHT_time_out.*W_t_8us;

%% L-SIG
RATE_bits = RateParams.RateBits; % to do

%------ VHT LENGTH computation
N_es = ceil((MCSParams.N_dbps/3.6)/600); 
N_sym = ceil((8*LENGTH+16+6*N_es)/MCSParams.N_dbps);

T_L_STF = 8; T_L_LTF = 8; T_L_SIG = 4; T_VHT_SIG_A = 8; T_VHT_STF = 4; N_VHT_LTF = 1; T_VHT_LTF = 4; 
T_VHT_SIG_B = 4; T_Data = N_sym*4;

TX_Time = T_L_STF + T_L_LTF + T_L_SIG + T_VHT_SIG_A + T_VHT_STF + N_VHT_LTF*T_VHT_LTF + T_VHT_SIG_B + T_Data;

LEN_wo_L = ceil((TX_Time - 20)/4);
LENGTH_VHT = LEN_wo_L*3-3;
%-------------------------------

LENGTH_bits = de2bi(LENGTH_VHT,12);

RATE_LNGTH_bits = [RATE_bits 0 LENGTH_bits];
Parity_Check_bit = mod(sum(RATE_LNGTH_bits),2);

L_SIG_bits = [RATE_LNGTH_bits Parity_Check_bit zeros(1, 6)];

% Encoder
R_SIG = 1/2;
SIG_coded_bits = convEncoder(L_SIG_bits,R_SIG);

% Interleaver
N_cbps_SIG = 48;
N_bpsc_SIG  = 1;
SIG_coded_inv_bits = legacy_interleaver(SIG_coded_bits, N_cbps_SIG, N_bpsc_SIG); % Output of Interleaver

% Subcarrier modulation
SIG_modulated = subModMap( SIG_coded_inv_bits );
P_26 = [0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,... 
        0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0];
SIG_modulated_sym = zeros(1, length(P_26));

for k = 0:length(SIG_modulated)-1
    M = M_k(k)+27;
    SIG_modulated_sym(M) =  SIG_modulated(k+1);
end

SIG_20M_FFT = [ zeros(1, 6) (SIG_modulated_sym+P_26) zeros(1,5) ]; % 20MHz
switch BW_channel
    case 20
        L_SIG_FFT = SIG_20M_FFT;    % 20MHz
    case 40
        L_SIG_FFT = [SIG_20M_FFT SIG_20M_FFT].*[zeros(1, 6) gamma zeros(1,5)];  % 40MHz
    case 80
        L_SIG_FFT = [SIG_20M_FFT SIG_20M_FFT SIG_20M_FFT SIG_20M_FFT].*[zeros(1, 6) gamma zeros(1,5)];  % 80MHz
    case 160
        L_SIG_FFT = [SIG_20M_FFT SIG_20M_FFT SIG_20M_FFT SIG_20M_FFT...
                     SIG_20M_FFT SIG_20M_FFT SIG_20M_FFT SIG_20M_FFT].*[zeros(1, 6) gamma zeros(1,5)];  % 160MHz
end;

L_SIG_FFT = [ zeros(1,(points_FFT/2)*Pad_Rate) L_SIG_FFT zeros(1,(points_FFT/2)*Pad_Rate) ];
     
L_SIG_FFT = ifftshift(L_SIG_FFT,2);
 
L_SIG_time = ifft(L_SIG_FFT);
L_SIG_time_out = [L_SIG_time(length(L_SIG_time)*3/4+1:end) L_SIG_time L_SIG_time(1:Pad_Rate+1)];

N_tone_field_LSIG =  toneFieldTable('L-SIG', BW_channel);
L_SIG_time_out = sqrt(1/N_tone_field_LSIG)*L_SIG_time_out.*W_t_4us;

%% VHT-SIG-A

BW = de2bi(log2(BW_channel/20),2);
Reserved_1 = 1;
STBC = 0; % Only SU
Group_ID = [0 0 0 0 0 0];
NSTS = [0 0 0];
Partial_AID = de2bi(128, 9);
TXOP_PS_NOT_ALLOWED = 1;
Reserved_2 = 1;
Short_GI = 0;
Short_GI_NSYM_Disambiguati_on = 0;
SU_Coding = 0;
LDPC_Extra_OFDM_Symbol = 0;
SU_VHT_MCS = de2bi(MCS,4);
Beamformed = 0;
Reserved_3 = 1;
VHT_SIG_A = [BW Reserved_1 STBC Group_ID NSTS Partial_AID...
   TXOP_PS_NOT_ALLOWED  Reserved_2 Short_GI Short_GI_NSYM_Disambiguati_on ...
   SU_Coding LDPC_Extra_OFDM_Symbol SU_VHT_MCS Beamformed Reserved_3];
CRC = CRC_decoding(VHT_SIG_A);
Tail = [0 0 0 0 0 0];
VHT_SIG_A = [VHT_SIG_A CRC Tail];

% BCC encoder
R_VHT_SIG_A = 1/2;
VHT_SIG_A_coded_bits = convEncoder( VHT_SIG_A,  R_VHT_SIG_A ); % HT-SIG codind with rate 1/2

% Split to VHT-SIG-A1 and VHT-SIG-A2
VHT_SIG_A1_bits = VHT_SIG_A_coded_bits(1:length(VHT_SIG_A_coded_bits)/2); % VHT-SIG-A1
VHT_SIG_A2_bits = VHT_SIG_A_coded_bits(length(VHT_SIG_A_coded_bits)/2+1:end); % VHT-SIG-A2

% Each sympol is interleaved
N_cbps_SIG = 48;
N_bpsc_SIG  = 1;
VHT_SIG_A1_coded_inv_bits = legacy_interleaver(VHT_SIG_A1_bits, N_cbps_SIG, N_bpsc_SIG); % Output of Interleaver
VHT_SIG_A2_coded_inv_bits = legacy_interleaver(VHT_SIG_A2_bits, N_cbps_SIG, N_bpsc_SIG); % Output of Interleaver


VHT_SIG_A1_modulated = subModMap( VHT_SIG_A1_coded_inv_bits );
VHT_SIG_A2_modulated = subModMap( VHT_SIG_A2_coded_inv_bits );
 
P_n = scramb(zeros(1,128+1), [1 1 1 1 1 1 1]);
P_n(P_n == 1) = -1;
P_n(P_n == 0) = 1;

VHT_SIG_A1_modulated_sym = zeros(1, length(P_26));
VHT_SIG_A2_modulated_sym = zeros(1, length(P_26));

for k = 0:length(SIG_modulated)-1
    M = M_k(k)+27;
    VHT_SIG_A1_modulated_sym(M) =  VHT_SIG_A1_modulated(k+1);
    VHT_SIG_A2_modulated_sym(M) =  VHT_SIG_A2_modulated(k+1);    
 end

VHT_SIG_A1_20M_FFT = [ zeros(1, 6) (VHT_SIG_A1_modulated_sym+P_26.*P_n(2)) zeros(1,5) ]; % 20MHz 
VHT_SIG_A2_20M_FFT = [ zeros(1, 6) (VHT_SIG_A2_modulated_sym.*1i+P_26.*P_n(3)) zeros(1,5) ]; % 20MHz

switch BW_channel
    case 20
        VHT_SIG_A1_FFT = VHT_SIG_A1_20M_FFT;    % 20MHz
        VHT_SIG_A2_FFT = VHT_SIG_A2_20M_FFT;    % 20MHz
    case 40
        VHT_SIG_A1_FFT = [VHT_SIG_A1_20M_FFT VHT_SIG_A1_20M_FFT].*[zeros(1, 6) gamma zeros(1,5)];  % 40MHz
        VHT_SIG_A2_FFT = [VHT_SIG_A2_20M_FFT VHT_SIG_A2_20M_FFT].*[zeros(1, 6) gamma zeros(1,5)];  % 40MHz
    case 80
        VHT_SIG_A1_FFT = [VHT_SIG_A1_20M_FFT VHT_SIG_A1_20M_FFT VHT_SIG_A1_20M_FFT VHT_SIG_A1_20M_FFT].*[zeros(1, 6) gamma zeros(1,5)];  % 80MHz
        VHT_SIG_A2_FFT = [VHT_SIG_A2_20M_FFT VHT_SIG_A2_20M_FFT VHT_SIG_A2_20M_FFT VHT_SIG_A2_20M_FFT].*[zeros(1, 6) gamma zeros(1,5)];  % 80MHz
    case 160
        VHT_SIG_A1_FFT = [VHT_SIG_A1_20M_FFT VHT_SIG_A1_20M_FFT VHT_SIG_A1_20M_FFT VHT_SIG_A1_20M_FFT...
                          VHT_SIG_A1_20M_FFT VHT_SIG_A1_20M_FFT VHT_SIG_A1_20M_FFT VHT_SIG_A1_20M_FFT].*[zeros(1, 6) gamma zeros(1,5)];  % 160MHz
        VHT_SIG_A2_FFT = [VHT_SIG_A2_20M_FFT VHT_SIG_A2_20M_FFT VHT_SIG_A2_20M_FFT VHT_SIG_A2_20M_FFT...
                          VHT_SIG_A2_20M_FFT VHT_SIG_A2_20M_FFT VHT_SIG_A2_20M_FFT VHT_SIG_A2_20M_FFT].*[zeros(1, 6) gamma zeros(1,5)];  % 160MHz                                    
end;

VHT_SIG_A1_FFT = [ zeros(1,(points_FFT/2)*Pad_Rate) VHT_SIG_A1_FFT zeros(1,(points_FFT/2)*Pad_Rate) ];
VHT_SIG_A2_FFT = [ zeros(1,(points_FFT/2)*Pad_Rate) VHT_SIG_A2_FFT zeros(1,(points_FFT/2)*Pad_Rate) ];


VHT_SIG_A1_FFT = ifftshift(VHT_SIG_A1_FFT,2);
VHT_SIG_A2_FFT = ifftshift(VHT_SIG_A2_FFT,2);

VHT_SIG_A1_time = ifft(VHT_SIG_A1_FFT);
VHT_SIG_A2_time = ifft(VHT_SIG_A2_FFT);

VHT_SIG_A1_time_out = [VHT_SIG_A1_time(length(VHT_SIG_A1_time)*3/4+1:end) VHT_SIG_A1_time VHT_SIG_A1_time(1:Pad_Rate+1)];
VHT_SIG_A2_time_out = [VHT_SIG_A2_time(length(VHT_SIG_A2_time)*3/4+1:end) VHT_SIG_A2_time VHT_SIG_A2_time(1:Pad_Rate+1)];

N_tone_field_VHTSIGA =  toneFieldTable('VHT-SIG-A', BW_channel);
VHT_SIG_A1_time_out = sqrt(1/N_tone_field_VHTSIGA)*VHT_SIG_A1_time_out.*W_t_4us;
VHT_SIG_A2_time_out = sqrt(1/N_tone_field_VHTSIGA)*VHT_SIG_A2_time_out.*W_t_4us;

%% VHT-STF
VHTS_26 = sqrt(1/2)*[0,0, 1+1i, 0,0,0, -1-1i, 0,0,0, 1+1i, 0,0,0, -1-1i, 0,0,0, -1-1i, 0,0,0, 1+1i, 0,0,0,...
           0,0,0,0,   -1-1i, 0,0,0, -1-1i, 0,0,0, 1+1i, 0,0,0,  1+1i, 0,0,0,  1+1i, 0,0,0, 1+1i, 0,0];
       
VHTS_58 = sqrt(1/2)*[0,0, 1+1i, 0,0,0, -1-1i, 0,0,0, 1+1i, 0,0,0, -1-1i, 0,0,0, -1-1i, 0,0,0, 1+1i, 0,0,0,...
               0,0,0,0, -1-1i, 0,0,0, -1-1i, 0,0,0, 1+1i, 0,0,0,  1+1i, 0,0,0,  1+1i, 0,0,0, 1+1i, 0,0,0,0,0 ...
    0,0,0,0,0,0,0,0,0,0, 1+1i, 0,0,0, -1-1i, 0,0,0, 1+1i, 0,0,0, -1-1i, 0,0,0, -1-1i, 0,0,0, 1+1i, ...
         0,0,0,0,0,0,0, -1-1i, 0,0,0, -1-1i, 0,0,0, 1+1i, 0,0,0,  1+1i, 0,0,0,  1+1i, 0,0,0, 1+1i, 0,0];

     
switch BW_channel
    case 20
        VHTS = VHTS_26.*gamma;
    case 40
        VHTS = VHTS_58.*gamma;
    case 80
        VHTS_122 = [ S_58 zeros(1,11) S_58];
        VHTS = VHTS_122.*gamma;      
    case 160
        VHTS_122 = [VHTS_58 zeros(1, 11) VHTS_58];
        VHTS_250 = [VHTS_122 zeros(1, 11) VHTS_122];
        VHTS = VHTS_250.*gamma;              
end;

STF_VHT_FFT = [zeros(1, (points_FFT/2)*Pad_Rate)  zeros(1, 6) VHTS zeros(1,5) zeros(1, (points_FFT/2)*Pad_Rate)]; % 20/40MHz
STF_VHT_FFT = ifftshift(STF_VHT_FFT,2);

STF_VHT_time = ifft(STF_VHT_FFT);
STF_VHT_time_out = [STF_VHT_time STF_VHT_time(1:length(STF_VHT_time)/4+1+Pad_Rate)];

N_tone_field_VHTSTF =  toneFieldTable('VHT-STF', BW_channel);
STF_VHT_time_out = sqrt(1/N_tone_field_VHTSTF)*STF_VHT_time_out.*W_t_4us;

%% VHT-LTF
LFT_left = L_26(1:26);
LFT_right = L_26(28:end);

switch BW_channel
    case 20
        gamma = [ 1 1 gamma 1 1 ];
        VHTL_28 = [1 1 LFT_left 0 LFT_right -1 -1];
        VHTL = VHTL_28.*gamma;
        zero_pad = (points_FFT-length(VHTL)+1)/2;
    case 40
        VHTL_58 = [LFT_left 1 LFT_right -1 -1 -1 1 0 0 0 -1 1 1 -1 LFT_left 1 LFT_right];
        VHTL = VHTL_58.*gamma;
        zero_pad = (points_FFT-length(VHTL)+1)/2;
    case 80
        VHTL_122 = [LFT_left 1 LFT_right -1 -1 -1 1 1 -1 1 -1 1 1 -1 LFT_left 1 LFT_right ...
                    1 -1 1 -1 0 0 0 1 -1 -1 1 ...
                    LFT_left 1 LFT_right -1 -1 -1 1 1 -1 1 -1 1 1 -1 LFT_left 1 LFT_right];
        VHTL = VHTL_122.*gamma;
        zero_pad = (points_FFT-length(VHTL)+1)/2;
    case 160
        VHTL_122 = [LFT_left 1 LFT_right -1 -1 -1 1 1 -1 1 -1 1 1 -1 LFT_left 1 LFT_right ...
                    1 -1 1 -1 0 0 0 1 -1 -1 1 ...
                    LFT_left 1 LFT_right -1 -1 -1 1 1 -1 1 -1 1 1 -1 LFT_left 1 LFT_right];
        VHTL_250 = [VHTL_122 zeros(1, 11) VHTL_122];
        VHTL = VHTL_250.*gamma;
        zero_pad = (points_FFT-length(VHTL)+1)/2;
end;

LTF_VHT_FFT = [zeros(1, (points_FFT/2)*Pad_Rate) zeros(1, zero_pad) VHTL zeros(1,zero_pad-1) zeros(1, (points_FFT/2)*Pad_Rate)]; % 40MHz
LTF_VHT_FFT = ifftshift(LTF_VHT_FFT,2);

LTF_VHT_time = ifft(LTF_VHT_FFT);
LTF_VHT_time_out = [LTF_VHT_time(length(LTF_VHT_time)*3/4+1:end ) LTF_VHT_time  LTF_VHT_time(1:Pad_Rate+1)];

N_tone_field_VHTLTF =  toneFieldTable('VHT-LTF', BW_channel);
LTF_VHT_time_out = sqrt(1/N_tone_field_VHTLTF)*LTF_VHT_time_out.*W_t_4us;

%% VHT-SIG-B

VHT_SIG_B_LENGTH = ceil(LENGTH/4);

switch BW_channel
    case 20
        VHT_SIG_B_LENGTH_bits = de2bi(VHT_SIG_B_LENGTH,17);
        VHT_SIG_B_Reserved = [1 1 1];
        VHT_SIG_B_Tail = zeros(1,6);
        VHT_SIG_B_bits = [VHT_SIG_B_LENGTH_bits VHT_SIG_B_Reserved VHT_SIG_B_Tail];
    case 40
        VHT_SIG_B_LENGTH_bits = de2bi(VHT_SIG_B_LENGTH,19);
        VHT_SIG_B_Reserved = [1 1 ];
        VHT_SIG_B_Tail = zeros(1,6);
        VHT_SIG_B_bits_40 = [VHT_SIG_B_LENGTH_bits VHT_SIG_B_Reserved VHT_SIG_B_Tail];
        VHT_SIG_B_bits = [VHT_SIG_B_bits_40 VHT_SIG_B_bits_40];
    case 80
        VHT_SIG_B_LENGTH_bits = de2bi(VHT_SIG_B_LENGTH,21);
        VHT_SIG_B_Reserved = [1 1 ];
        VHT_SIG_B_Tail = zeros(1,6);
        Pad_Bit = 0;
        VHT_SIG_B_bits_80 = [VHT_SIG_B_LENGTH_bits VHT_SIG_B_Reserved VHT_SIG_B_Tail];
        VHT_SIG_B_bits = [VHT_SIG_B_bits_80 VHT_SIG_B_bits_80 VHT_SIG_B_bits_80 VHT_SIG_B_bits_80 Pad_Bit];        
    case 160
        VHT_SIG_B_LENGTH_bits = de2bi(VHT_SIG_B_LENGTH,21);
        VHT_SIG_B_Reserved = [1 1 ];
        VHT_SIG_B_Tail = zeros(1,6);
        Pad_Bit = 0;
        VHT_SIG_B_bits_80 = [VHT_SIG_B_LENGTH_bits VHT_SIG_B_Reserved VHT_SIG_B_Tail];
        VHT_SIG_B_bits = [VHT_SIG_B_bits_80 VHT_SIG_B_bits_80 VHT_SIG_B_bits_80 VHT_SIG_B_bits_80 Pad_Bit ...
                          VHT_SIG_B_bits_80 VHT_SIG_B_bits_80 VHT_SIG_B_bits_80 VHT_SIG_B_bits_80 Pad_Bit]; 
end;

R_VHT_SIG_B = 1/2;
VHT_SIG_B_coded_bits = convEncoder(VHT_SIG_B_bits,R_VHT_SIG_B);

MCSParams_VHT_SIG_B = VHT_MCSTable(0, BW_channel);

if BW_channel == 160
    VHT_SIG_B_coded_bits_parsed = Segment_Parsing_160MHz( VHT_SIG_B_coded_bits, 1, MCSParams_VHT_SIG_B.N_cbps, MCSParams_VHT_SIG_B.N_bpsc );
    VHT_SIG_B_coded_inv_bits1 = VHT_interleaver(VHT_SIG_B_coded_bits_parsed(1,:), MCSParams_VHT_SIG_B.N_cbps, MCSParams_VHT_SIG_B.N_bpsc, BW_channel);
    VHT_SIG_B_coded_inv_bits2 = VHT_interleaver(VHT_SIG_B_coded_bits_parsed(2,:), MCSParams_VHT_SIG_B.N_cbps, MCSParams_VHT_SIG_B.N_bpsc, BW_channel);
    VHT_SIG_B_modulated1 = VHT_subModMap( VHT_SIG_B_coded_inv_bits1 );
    VHT_SIG_B_modulated2 = VHT_subModMap( VHT_SIG_B_coded_inv_bits2 );
    VHT_SIG_B_modulated = [VHT_SIG_B_modulated1 VHT_SIG_B_modulated2];
else
    VHT_SIG_B_coded_inv_bits = VHT_interleaver(VHT_SIG_B_coded_bits(1,:), MCSParams_VHT_SIG_B.N_cbps, MCSParams_VHT_SIG_B.N_bpsc, BW_channel);
    VHT_SIG_B_modulated = VHT_subModMap( VHT_SIG_B_coded_inv_bits );
end
P_0_VHT = pilotCreationHT_VHT(0, BW_channel);

VHT_SIG_B_modulated_sym = zeros(1, length(P_0_VHT));
for k = 0:length(VHT_SIG_B_modulated)-1
    M = M_k_VHT(k,BW_channel);
    VHT_SIG_B_modulated_sym(M) =  VHT_SIG_B_modulated(k+1);
end
if BW_channel == 20
    VHT_SIG_B_FFT = [ zeros(1, 4) (VHT_SIG_B_modulated_sym+P_0_VHT.*P_n(3)).*gamma zeros(1,3) ];
else
    VHT_SIG_B_FFT = [ zeros(1, 6) (VHT_SIG_B_modulated_sym+P_0_VHT.*P_n(3)).*gamma zeros(1,5) ];
end
VHT_SIG_B_FFT = [ zeros(1,(points_FFT/2)*Pad_Rate) VHT_SIG_B_FFT zeros(1,(points_FFT/2)*Pad_Rate) ];

VHT_SIG_B_FFT = ifftshift(VHT_SIG_B_FFT,2);

VHT_SIG_B_time = ifft(VHT_SIG_B_FFT);

VHT_SIG_B_time_out = [VHT_SIG_B_time(length(VHT_SIG_B_time)*3/4+1:end) VHT_SIG_B_time VHT_SIG_B_time(1:Pad_Rate+1)];


N_tone_field_VHTSIGB =  toneFieldTable('VHT-SIG-B', BW_channel);
VHT_SIG_B_time_out = sqrt(1/N_tone_field_VHTSIGB)*VHT_SIG_B_time_out.*W_t_4us;

%% Data
ScramblerInitForService = [0 0 0 0 0 0 0];
ReservedForService = 0;
CRCForService = CRC_decoding([VHT_SIG_B_LENGTH_bits VHT_SIG_B_Reserved]);

if ~isDataRand
    Data_vec_oct = LENGTH.*rand(1,LENGTH);
else
    Data_vec_oct = floor(LENGTH*rand(LENGTH,1));
end
Data_vec_oct_bits = dec2bin(Data_vec_oct,8);
Data_vec_bits = [str2num(Data_vec_oct_bits(:,end-7)) str2num(Data_vec_oct_bits(:,end-6)) ...
                 str2num(Data_vec_oct_bits(:,end-5)) str2num(Data_vec_oct_bits(:,end-4))...
                 str2num(Data_vec_oct_bits(:,end-3)) str2num(Data_vec_oct_bits(:,end-2)) ...
                 str2num(Data_vec_oct_bits(:,end-1)) str2num(Data_vec_oct_bits(:,end-0))];
             
N_pad = N_sym*MCSParams.N_dbps - 8*LENGTH - 16 - 6*N_es;

Data_befor_csr = [ScramblerInitForService, ReservedForService, CRCForService, reshape(Data_vec_bits',1,[]), zeros(1,6),zeros(1,N_pad)];
Data_after_csr = scramb(Data_befor_csr, [1 1 1 1 1 1 1]);
Data_after_csr(16+8*LENGTH+1:16+8*LENGTH+6*N_es) = 0;

P_n = scramb(zeros(1,N_sym+4), [1 1 1 1 1 1 1]);
P_n(P_n == 1) = -1;
P_n(P_n == 0) = 1;

DATA_encoded_mat = zeros(MCSParams.N_cbps, N_sym);
if (N_es >1)
    [BCCstream1, BCCstream2] = encoderParcer(Data_after_csr(1,:), N_es, N_sym, MCSParams.N_dbps);
    DATA_encoded1 = convEncoder(BCCstream1,MCSParams.CodeRate);
    DATA_encoded2 = convEncoder(BCCstream2,MCSParams.CodeRate);
    DATA_encoded_mat1 = reshape(DATA_encoded1, MCSParams.N_cbps/2, [])';
    DATA_encoded_mat2 = reshape(DATA_encoded2', MCSParams.N_cbps/2, [])';
    for i  = 1:N_sym
         DATA_encoded_mat(:,i) = streamParser(DATA_encoded_mat1(i,:), DATA_encoded_mat2(i,:),MCSParams.N_cbps, MCSParams.N_bpsc, N_es);
    end
    %DATA_encoded = streamParser(DATA_encoded1, DATA_encoded2, MCSParams.N_cbps, MCSParams.N_bpsc, N_es);
else
    DATA_encoded = convEncoder(Data_after_csr(1,:),MCSParams.CodeRate);
    DATA_encoded_mat = reshape(DATA_encoded,MCSParams.N_cbps,[]);
end


DATA_field = [];

N_tone_field_VHTData =  toneFieldTable('Data', BW_channel);
for i  = 1:N_sym
     P_i_VHT = pilotCreationHT_VHT(i-1, BW_channel);   
     
    if BW_channel == 160
        DATA_encoded_mat_parsed = Segment_Parsing_160MHz( DATA_encoded_mat(:,i), 1, MCSParams.N_cbps, MCSParams.N_bpsc );
        DATA_encoded_inv_frame1 = VHT_interleaver(DATA_encoded_mat_parsed(1,:), MCSParams.N_cbps, MCSParams.N_bpsc, BW_channel);
        DATA_encoded_inv_frame2 = VHT_interleaver(DATA_encoded_mat_parsed(2,:), MCSParams.N_cbps, MCSParams.N_bpsc, BW_channel);
        DATA_modulated1 = VHT_subModMap( DATA_encoded_inv_frame1 );
        DATA_modulated2 = VHT_subModMap( DATA_encoded_inv_frame2 );
        DATA_modulated = [DATA_modulated1 DATA_modulated2];
    else     
         DATA_encoded_inv_frame = VHT_interleaver(DATA_encoded_mat(:,i), MCSParams.N_cbps, MCSParams.N_bpsc,BW_channel); % Output of Interleaver
         DATA_modulated = VHT_subModMap( DATA_encoded_inv_frame );
     end
     DATA_modulated_sym = zeros(1, length(P_i_VHT));
     for k = 0:length(DATA_modulated)-1
        M = M_k_VHT(k,BW_channel);
        DATA_modulated_sym(M) =  DATA_modulated(k+1);
     end
     
     DATA_FFT = [ zeros(1, (points_FFT/2)*Pad_Rate) zeros(1, zero_pad) (DATA_modulated_sym+P_i_VHT.*P_n(i+3)).*gamma zeros(1,zero_pad-1) zeros(1, (points_FFT/2)*Pad_Rate)]; 

     DATA_FFT = ifftshift(DATA_FFT,2);
 
     DATA_time = ifft(DATA_FFT);
     DATA_time = [DATA_time(length(DATA_time)*3/4+1:end) DATA_time DATA_time(1:Pad_Rate+1)];
     

     DATA_time = sqrt(1/N_tone_field_VHTData)*DATA_time.*W_t_4us;
     if i == 1
         DATA_field = DATA_time;
     else
         DATA_field = [DATA_field(1:end-1-Pad_Rate) DATA_field(end - Pad_Rate:end)+DATA_time(1:Pad_Rate+1) DATA_time(2+Pad_Rate:end)];
     end
end

 Packet = [STF_nonHT_time_out(1:end-1-Pad_Rate)           STF_nonHT_time_out(end - Pad_Rate:end)+LTF_nonHT_time_out(1:Pad_Rate+1)...
           LTF_nonHT_time_out(2+Pad_Rate:end-1-Pad_Rate)  LTF_nonHT_time_out(end - Pad_Rate:end)+L_SIG_time_out(1:Pad_Rate+1)...
           L_SIG_time_out(2+Pad_Rate:end-1-Pad_Rate)      L_SIG_time_out(end - Pad_Rate:end)+VHT_SIG_A1_time_out(1:Pad_Rate+1)...
           VHT_SIG_A1_time_out(2+Pad_Rate:end-1-Pad_Rate) VHT_SIG_A1_time_out(end - Pad_Rate:end)+VHT_SIG_A2_time_out(1:Pad_Rate+1)...
           VHT_SIG_A2_time_out(2+Pad_Rate:end-1-Pad_Rate) VHT_SIG_A2_time_out(end - Pad_Rate:end)+STF_VHT_time_out(1:Pad_Rate+1)...
           STF_VHT_time_out(2+Pad_Rate:end-1-Pad_Rate)    STF_VHT_time_out(end - Pad_Rate:end)+LTF_VHT_time_out(1:Pad_Rate+1)...
           LTF_VHT_time_out(2+Pad_Rate:end-1-Pad_Rate)    LTF_VHT_time_out(end - Pad_Rate:end)+VHT_SIG_B_time_out(1:Pad_Rate+1)...
           VHT_SIG_B_time_out(2+Pad_Rate:end-1-Pad_Rate)  VHT_SIG_B_time_out(end - Pad_Rate:end)+DATA_field(1:Pad_Rate+1) DATA_field(2+Pad_Rate:end-1-Pad_Rate)];
 
       

 if (resample_flag == 1)
    Packet = resample(Packet,p,q);
 end
  
I_ESG = zeros(length(Packet),1);
Q_ESG = zeros(length(Packet),1);
I_ESG(1:length(Packet)) = real(Packet);
Q_ESG(1:length(Packet)) = imag(Packet);

M_ESG = [I_ESG, Q_ESG];
if ( ~isempty(SaveAsPath))
csvwrite(SaveAsPath,M_ESG);
end
wavaform=M_ESG;
end




