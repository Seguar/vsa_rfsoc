function [iqdata, data, channelMapping]= iqofdm(varargin)
% Generate OFDM waveform
% Parameters are passed as property/value pairs. Properties are:
% 'correction' - decide if amplitude corretion is used
% 'fftlength' - FFT Length each OFDM Symbol 
% 'oversampling' - Oversampling factor
% 'resourcemap' - Resource map array for OFDM signal
% 'resourcemodulation' - Resource modulation array for OFDM signal
% 'quamidentifier' - Quam identifier array for OFDM signal generation
% 'quamlevels' - Quam level array for OFDM signal generation
% 'pilotdefinitions' - Array with defined pilot values (real, imag, ...)
% 'preambleiqvalues' - Array with defined preamble values (real, imag, ...)
% 'numguardlowersubcarriers' - Number of lower subcarriers, N=0,1,2,....
% 'numguardhighersubcarriers' -  Number of upper subcarriers, N=0,1,2,....
% 'resourcerepeatindex' - Loop back to symbol defined by index, N=0,1,...,('numsymbols'-1)
% 'prefix' - Guard interval, value must be 1/N, N=1,2,3,.... 
% 'ofdmsamplefrequency' - Sample frequency for OFDM signal in Hz
% 'fshift' - Center frequency in Hz OFDM signal uses only one channel if >0
% 'burstinterval' - Length of the pause in s, after N='numsymbols, if 0 two channel OFDM Signal is created otherwise one channel' 
% 'numsymbols' - Number of Symbols to be created in one package
% 'isranddata' - Decision if randomdata is created or user defined data is used (0=user data, 1=randomdata)
% 'data' - user defined data if 'isranddata' is not selected
% 'numpackages' - Number of OFDM packages with 'numsymbols' 
% 'NumWindow' - Number of Samples for wich a windowing is used
% 'FilterTyp' - Filter function used for windowing
% If called without arguments, opens a graphical user interface to specify
% parameters
%
% Marius Lippke, Keysight Technologies 2020
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

if (nargin == 0)
    iqofdm_gui;
    return;
end

    correction = 0;
    FFTLength=8;
    oversampling=4;
    oversampling = 4;
    ResourceMap = [0, 1, 0, 4, 0, 1, 0];    %Resource Map needs to be coded in Format: -4,-3,-2,-1,0,1,2,3 for FFT Lenght of 8 
    ResourceModulation = [3, 3, 3, 1, 3, 3, 1];
    QuamIdentifier = [0, 1, 2, 3, 4, 5];
    QuamLevels = [0, 1, 2, 4, 6, 8]; 
    PilotDefinitions = [1, -1/3,1/3,- 1];   
    PreambleIQValues = [0.95,0.95,1.41,1.41];     
    numGuardLowerSubcarriers = 1;            
    numGuardHigherSubcarriers = 0;
    ResourceRepeatIndex=0; 
    prefix=0.0;
    OFDMSystemFrequency=2e9;
    fshift=2e9;
    BurstInterval=0;
    IsRandata=1;
    NumSymbols=143;
    NumPackages=1;
    NumWindow=0; 
    FilterTyp='blackman';
    
    iqdatapack=[];     %OFDM signal returned by function
    datapack=[];       %Binary data returned by function
    data = [];         %Array containing the binary data for one pack
    datalenght=0;      %Length of data array (for testing)
    FFTData = [];      %FFT Data for one symbol (without subcarrier)
    IFFTData = [];     %Time Signal for one symbol 
    iqdata=[];         %Array containing iq data for one package
    channelMapping = [1 0; 0 1];
 

    
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'correction';                correction = varargin{i+1};
            case 'fftlength';                 FFTLength = varargin{i+1};
            case 'oversampling';              oversampling = varargin{i+1};
            case 'resourcemap';               ResourceMap = varargin{i+1};
            case 'resourcemodulation';        ResourceModulation = varargin{i+1};
            case 'quamidentifier';            QuamIdentifier = varargin{i+1};
            case 'quamlevels';                QuamLevels = varargin{i+1};
            case 'pilotdefinitions';          PilotDefinitions = varargin{i+1};
            case 'preambleiqvalues';          PreambleIQValues = varargin{i+1};
            case 'numguardlowersubcarriers';  numGuardLowerSubcarriers = varargin{i+1};
            case 'numguardhighersubcarriers'; numGuardHigherSubcarriers = varargin{i+1};
            case 'resourcerepeatindex';       ResourceRepeatIndex = varargin{i+1};
            case 'prefix';                    prefix = varargin{i+1};
            case 'ofdmsamplefrequency';       OFDMSystemFrequency=varargin{i+1};
            case 'fshift';                    fshift=varargin{i+1};
            case 'burstinterval';             BurstInterval=varargin{i+1};
            case 'numsymbols';                NumSymbols=varargin{i+1};
            case 'isranddata';                IsRandata=varargin{i+1};
            case 'data';                      data=varargin{i+1};
            case 'numpackages';               NumPackages=varargin{i+1};
            case 'numwindow';                 NumWindow=varargin{i+1};
            case 'channelmapping';            channelMapping = varargin{i+1};
            otherwise error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end

if (round(oversampling) ~= oversampling)
    errordlg('only integer oversampling ratios are supported');
    return;
end

%If Signal is bursted, control if the Burstlength is a multiplier of AWG
%Sample Rate (necessary, because a natural number of zeros need to be
%filled into the signal as burst period)
if(BurstInterval>0)
   if( BurstInterval*(OFDMSystemFrequency*oversampling)~=round(BurstInterval*(OFDMSystemFrequency*oversampling)))
      N=BurstInterval*(OFDMSystemFrequency*oversampling);
      N=ceil(N);
      BurstInterval=N/(OFDMSystemFrequency*oversampling);
   end
elseif(BurstInterval<0)
      BurstInterval=0;
end

%If it is selected not to create random data and the data pattern to be looped is empty,
%then create random data
if(IsRandata==0)
   if(isempty(data)) 
      IsRandata=1;
      msgbox('Data pattern to be looped is empty, random data will be created','Message');
   end
end

%Calculate the number of Symbols which are coded via one resource map entry
%CalculatedValues (must be n=1,2,3,... or Resource Map must be changed)
%value is return value used to control if NumSymbolsperMap is N=1,2,3,...
[value NumSymbolsperMap]=calculateN(FFTLength,ResourceMap,numGuardHigherSubcarriers,numGuardLowerSubcarriers); 
%If more than one Symbol is used, the created binary data and the FFT
%data are repeated from the Index Repeat on in the Resource Map Array 
Repeatat=ResourceRepeatIndex*(FFTLength-numGuardLowerSubcarriers-numGuardHigherSubcarriers)+1;

 
%Generate modem objects (to be faster defined at the beginning)
%Set array type
%hmod = 2; 
%hmodem=[@(x) pskmod(x, hmod.m)];
%Demodulation Objects
%hdemodem=[];

 for i=1:length(QuamLevels)
   
   if(isscalar(QuamLevels(i))&& QuamLevels(i)>=0)
       
       switch QuamLevels(i)
           case 0
           hmodem(i).m = 2; 
           hmodem(i).modulate = @(x) pskmod(x, hmodem(i).m);
           %hmodem(i)= modem.pskmod(2); 
           %hdemodem(i)=modem.pskdemod(hmodem(i));
           case 1 
           %BPSK Modulation    
           hmodem(i).m = 2; 
           hmodem(i).modulate = @(x) pskmod(x, hmodem(i).m);
           case 2   
           %4 Quam Modulation
           hmodem(i).m = 4; hmodem(i).modulate = @(x) pskmod(x, hmodem(i).m, pi/4, 'Gray');
           %hmodem(i)= modem.qammod('M',2^QuamLevels(i),'SymbolOrder','Gray');
           %hdemodem(i)=modem.qamdemod(hmodem(i));
           %4PSK Modulation (alternatively)
           %hmodem(i)= modem.pskmod(4); 
           %hdemodem(i)=modem.pskdemod(hmodem(i));  
           case 3
           %8PSK Modulation
           hmodem(i).m = 8; 
           hmodem(i).modulate = @(x) pskmod(x, hmodem(i).m, pi/8);
           %8Quam Modulation (alternatively)
           %hmodem(i)= modem.qammod('M',2^QuamLevels(i),'SymbolOrder','Gray');
           %hdemodem(i)=modem.qamdemod(hmodem(i));  
           case 4 
           %Quam 16 modulation
           hmodem(i).m = 16;
           hmodem(i).modulate = @(x) genqammod(x, [-3+3i;-3+1i;-3-1i;-3-3i;-1+3i;-1+1i;-1-1i;-1-3i;1+3i;1+1i;1-1i;1-3i;3+3i;3+1i;3-1i;3-3i]);
           %hmodem(i).SymbolMapping=[0 1 3 2 4 5 7 6 12 13 15 14 8 9 11 10]
           %hdemodem(i)=modem.qamdemod(hmodem(i));
           %hdemodem(i).SymbolMapping=[14 6 2 10 12 4 0 8 13 5 1 9 15 7 3 11];
           %hdemodem(i).SymbolMapping=[0 1 3 2 4 5 7 6 12 13 15 14 8 9 11 10]
           case 5 
           %Quam 32 modulation
           hmodem(i).m = 32;
           hmodem(i).modulate = @(x) genqammod(x, [-3+5i;-1+5i;-1-5i;-3-5i;-5+3i;-5+1i;-5-1i;-5-3i;-3+3i;-3+1i;-3-1i;-3-3i;-1+3i;-1+1i;-1-1i;-1-3i;1+3i;1+1i;1-1i;1-3i;3+3i;3+1i;3-1i;3-3i;5+3i;5+1i;5-1i;5-3i;3+5i;1+5i;1-5i;3-5i]);
           
           case 6
           %Quam 64 modulation
           hmodem(i).m = 64;
           hmodem(i).modulate = @(x) genqammod(x, [-7+7i;-7+5i;-7+3i;-7+1i;-7-1i;-7-3i;-7-5i;-7-7i;-5+7i;-5+5i;-5+3i;-5+1i;-5-1i;-5-3i;-5-5i;-5-7i;-3+7i;-3+5i;-3+3i;-3+1i;-3-1i;-3-3i;-3-5i;-3-7i;-1+7i;-1+5i;-1+3i;-1+1i;-1-1i;-1-3i;-1-5i;-1-7i;1+7i;1+5i;1+3i;1+1i;1-1i;1-3i;1-5i;1-7i;3+7i;3+5i;3+3i;3+1i;3-1i;3-3i;3-5i;3-7i;5+7i;5+5i;5+3i;5+1i;5-1i;5-3i;5-5i;5-7i;7+7i;7+5i;7+3i;7+1i;7-1i;7-3i;7-5i;7-7i]);
           
           case 7
           %Quam 128 modulation 
           hmodem(i).m = 128;
           hmodem(i).modulate = @(x) genqammod(x, [-7+9i;-7+11i;-1+11i;-1+9i;-1-9i;-1-11i;-7-11i;-7-9i;-5+9i;-5+11i;-3+11i;-3+9i;-3-9i;-3-11i;-5-11i;-5-9i;-11+7i;-11+5i;-11+3i;-11+1i;-11-1i;-11-3i;-11-5i;-11-7i;-9+7i;-9+5i;-9+3i;-9+1i;-9-1i;-9-3i;-9-5i;-9-7i;-7+7i;-7+5i;-7+3i;-7+1i;-7-1i;-7-3i;-7-5i;-7-7i;-5+7i;-5+5i;-5+3i;-5+1i;-5-1i;-5-3i;-5-5i;-5-7i;-3+7i;-3+5i;-3+3i;-3+1i;-3-1i;-3-3i;-3-5i;-3-7i;-1+7i;-1+5i;-1+3i;-1+1i;-1-1i;-1-3i;-1-5i;-1-7i;1+7i;1+5i;1+3i;1+1i;1-1i;1-3i;1-5i;1-7i;3+7i;3+5i;3+3i;3+1i;3-1i;3-3i;3-5i;3-7i;5+7i;5+5i;5+3i;5+1i;5-1i;5-3i;5-5i;5-7i;7+7i;7+5i;7+3i;7+1i;7-1i;7-3i;7-5i;7-7i;9+7i;9+5i;9+3i;9+1i;9-1i;9-3i;9-5i;9-7i;11+7i;11+5i;11+3i;11+1i;11-1i;11-3i;11-5i;11-7i;5+9i;5+11i;3+11i;3+9i;3-9i;3-11i;5-11i;5-9i;7+9i;7+11i;1+11i;1+9i;1-9i;1-11i;7-11i;7-9i]);
           
           case 8
           %Quam 256 modulation
           hmodem(i).m = 256;
           hmodem(i).modulate =@(x) genqammod(x, ...
            [-15+15i;-15+13i;-15+11i;-15+9i;-15+7i;-15+5i;-15+3i;-15+1i;-15-1i;-15-3i;-15-5i;-15-7i;-15-9i;-15-11i;-15-13i;-15-15i;-13+15i;-13+13i;-13+11i;-13+9i;-13+7i;-13+5i;-13+3i;-13+1i;-13-1i;-13-3i;-13-5i;-13-7i;-13-9i;-13-11i;-13-13i;-13-15i;-11+15i;-11+13i;-11+11i;-11+9i;-11+7i;-11+5i;-11+3i;-11+1i;-11-1i;-11-3i;-11-5i;-11-7i;-11-9i;-11-11i;-11-13i;-11-15i;-9+15i;-9+13i;-9+11i;-9+9i;-9+7i;-9+5i;-9+3i;-9+1i;-9-1i;-9-3i;-9-5i;-9-7i;-9-9i;-9-11i;-9-13i;-9-15i;-7+15i;-7+13i;-7+11i;-7+9i;-7+7i;-7+5i;-7+3i;-7+1i;-7-1i;-7-3i;-7-5i;-7-7i;-7-9i;-7-11i;-7-13i;-7-15i;-5+15i;-5+13i;-5+11i;-5+9i;-5+7i;-5+5i;-5+3i;-5+1i;-5-1i;-5-3i;-5-5i;-5-7i;-5-9i;-5-11i;-5-13i;-5-15i;-3+15i;-3+13i;-3+11i;-3+9i;-3+7i;-3+5i;-3+3i;-3+1i;-3-1i;-3-3i;-3-5i;-3-7i;-3-9i;-3-11i;-3-13i;-3-15i;-1+15i;-1+13i;-1+11i;-1+9i;-1+7i;-1+5i;-1+3i;-1+1i;-1-1i;-1-3i;-1-5i;-1-7i;-1-9i;-1-11i;-1-13i;-1-15i;1+15i;1+13i;1+11i;1+9i;1+7i;1+5i;1+3i;1+1i;1-1i;1-3i;1-5i;1-7i;1-9i;1-11i;1-13i;1-15i;3+15i; ...
            3+13i;3+11i;3+9i;3+7i;3+5i;3+3i;3+1i;3-1i;3-3i;3-5i;3-7i;3-9i;3-11i;3-13i;3-15i;5+15i;5+13i;5+11i;5+9i;5+7i;5+5i;5+3i;5+1i;5-1i;5-3i;5-5i;5-7i;5-9i;5-11i;5-13i;5-15i;7+15i;7+13i;7+11i;7+9i;7+7i;7+5i;7+3i;7+1i;7-1i;7-3i;7-5i;7-7i;7-9i;7-11i;7-13i;7-15i;9+15i;9+13i;9+11i;9+9i;9+7i;9+5i;9+3i;9+1i;9-1i;9-3i;9-5i;9-7i;9-9i;9-11i;9-13i;9-15i;11+15i;11+13i;11+11i;11+9i;11+7i;11+5i;11+3i;11+1i;11-1i;11-3i;11-5i;11-7i;11-9i;11-11i;11-13i;11-15i;13+15i;13+13i;13+11i;13+9i;13+7i;13+5i;13+3i;13+1i;13-1i;13-3i;13-5i;13-7i;13-9i;13-11i;13-13i;13-15i;15+15i;15+13i;15+11i;15+9i;15+7i;15+5i;15+3i;15+1i;15-1i;15-3i;15-5i;15-7i;15-9i;15-11i;15-13i;15-15i]);
        
           case 9
           %Quam 512 modulation
           hmodem(i).m = 512;
           hmodem(i).modulate = @(x) genqammod(x, ...
           [-15+17i;-15+19i;-15+21i;-15+23i;-1+23i;-1+21i;-1+19i;-1+17i;-1-17i;-1-19i;-1-21i;-1-23i;-15-23i;-15-21i;-15-19i;-15-17i;-13+17i;-13+19i;-13+21i;-13+23i;-3+23i;-3+21i;-3+19i;-3+17i;-3-17i;-3-19i;-3-21i;-3-23i;-13-23i;-13-21i;-13-19i;-13-17i;-11+17i;-11+19i;-11+21i;-11+23i;-5+23i;-5+21i;-5+19i;-5+17i;-5-17i;-5-19i;-5-21i;-5-23i;-11-23i;-11-21i;-11-19i;-11-17i;-9+17i;-9+19i;-9+21i;-9+23i;-7+23i;-7+21i;-7+19i;-7+17i;-7-17i;-7-19i;-7-21i;-7-23i;-9-23i;-9-21i;-9-19i;-9-17i;-23+15i;-23+13i;-23+11i;-23+9i;-23+7i;-23+5i;-23+3i;-23+1i;-23-1i;-23-3i;-23-5i;-23-7i;-23-9i;-23-11i;-23-13i;-23-15i;-21+15i;-21+13i;-21+11i;-21+9i;-21+7i;-21+5i;-21+3i;-21+1i;-21-1i;-21-3i;-21-5i;-21-7i;-21-9i;-21-11i;-21-13i;-21-15i;-19+15i;-19+13i;-19+11i;-19+9i;-19+7i;-19+5i;-19+3i; ...
            -19+1i;-19-1i;-19-3i;-19-5i;-19-7i;-19-9i;-19-11i;-19-13i;-19-15i;-17+15i;-17+13i;-17+11i;-17+9i;-17+7i;-17+5i;-17+3i;-17+1i;-17-1i;-17-3i;-17-5i;-17-7i;-17-9i;-17-11i;-17-13i;-17-15i;-15+15i;-15+13i;-15+11i;-15+9i;-15+7i;-15+5i;-15+3i;-15+1i;-15-1i;-15-3i;-15-5i;-15-7i;-15-9i;-15-11i;-15-13i;-15-15i;-13+15i;-13+13i;-13+11i;-13+9i;-13+7i;-13+5i;-13+3i;-13+1i;-13-1i;-13-3i;-13-5i;-13-7i;-13-9i;-13-11i;-13-13i;-13-15i;-11+15i;-11+13i;-11+11i;-11+9i;-11+7i;-11+5i;-11+3i;-11+1i;-11-1i;-11-3i;-11-5i;-11-7i;-11-9i;-11-11i;-11-13i;-11-15i;-9+15i;-9+13i;-9+11i;-9+9i;-9+7i;-9+5i;-9+3i;-9+1i;-9-1i;-9-3i;-9-5i;-9-7i;-9-9i;-9-11i;-9-13i;-9-15i;-7+15i;-7+13i;-7+11i;-7+9i;-7+7i;-7+5i;-7+3i;-7+1i;-7-1i;-7-3i;-7-5i;-7-7i;-7-9i;-7-11i;-7-13i;-7-15i;-5+15i;-5+13i;-5+11i;-5+9i;-5+7i;-5+5i;-5+3i;-5+1i;-5-1i;-5-3i;-5-5i;-5-7i;-5-9i;-5-11i;-5-13i;-5-15i;-3+15i;-3+13i;-3+11i;-3+9i;-3+7i;-3+5i;-3+3i;-3+1i;-3-1i;-3-3i;-3-5i;-3-7i;-3-9i;-3-11i;-3-13i;-3-15i;-1+15i;-1+13i;-1+11i;-1+9i;-1+7i;-1+5i;-1+3i;-1+1i;-1-1i; ...
            -1-3i;-1-5i;-1-7i;-1-9i;-1-11i;-1-13i;-1-15i;1+15i;1+13i;1+11i;1+9i;1+7i;1+5i;1+3i;1+1i;1-1i;1-3i;1-5i;1-7i;1-9i;1-11i;1-13i;1-15i;3+15i;3+13i;3+11i;3+9i;3+7i;3+5i;3+3i;3+1i;3-1i;3-3i;3-5i;3-7i;3-9i;3-11i;3-13i;3-15i;5+15i;5+13i;5+11i;5+9i;5+7i;5+5i;5+3i;5+1i;5-1i;5-3i;5-5i;5-7i;5-9i;5-11i;5-13i;5-15i;7+15i;7+13i;7+11i;7+9i;7+7i;7+5i;7+3i;7+1i;7-1i;7-3i;7-5i;7-7i;7-9i;7-11i;7-13i;7-15i;9+15i;9+13i;9+11i;9+9i;9+7i;9+5i;9+3i;9+1i;9-1i;9-3i;9-5i;9-7i;9-9i;9-11i;9-13i;9-15i;11+15i;11+13i;11+11i;11+9i;11+7i;11+5i;11+3i;11+1i;11-1i;11-3i;11-5i;11-7i;11-9i;11-11i;11-13i;11-15i;13+15i;13+13i;13+11i;13+9i;13+7i;13+5i;13+3i;13+1i;13-1i;13-3i;13-5i;13-7i;13-9i;13-11i;13-13i;13-15i;15+15i;15+13i;15+11i;15+9i;15+7i;15+5i;15+3i;15+1i;15-1i;15-3i;15-5i;15-7i;15-9i;15-11i;15-13i;15-15i;17+15i;17+13i;17+11i;17+9i;17+7i;17+5i;17+3i;17+1i;17-1i;17-3i;17-5i;17-7i;17-9i;17-11i;17-13i;17-15i;19+15i;19+13i;19+11i;19+9i;19+7i;19+5i;19+3i;19+1i;19-1i;19-3i;19-5i;19-7i;19-9i;19-11i;19-13i;19-15i;21+15i;21+13i;21+11i; ...
            21+9i;21+7i;21+5i;21+3i;21+1i;21-1i;21-3i;21-5i;21-7i;21-9i;21-11i;21-13i;21-15i;23+15i;23+13i;23+11i;23+9i;23+7i;23+5i;23+3i;23+1i;23-1i;23-3i;23-5i;23-7i;23-9i;23-11i;23-13i;23-15i;9+17i;9+19i;9+21i;9+23i;7+23i;7+21i;7+19i;7+17i;7-17i;7-19i;7-21i;7-23i;9-23i;9-21i;9-19i;9-17i;11+17i;11+19i;11+21i;11+23i;5+23i;5+21i;5+19i;5+17i;5-17i;5-19i;5-21i;5-23i;11-23i;11-21i;11-19i;11-17i;13+17i;13+19i;13+21i;13+23i;3+23i;3+21i;3+19i;3+17i;3-17i;3-19i;3-21i;3-23i;13-23i;13-21i;13-19i;13-17i;15+17i;15+19i;15+21i;15+23i;1+23i;1+21i;1+19i;1+17i;1-17i;1-19i;1-21i;1-23i;15-23i;15-21i;15-19i;15-17i]);
            
           case 10
           %Quam 1024 modulation
           hmodem(i).m = 1024;   
           hmodem(i).modulate = @(x) genqammod(x, ...
            [-31+31i;-31+29i;-31+27i;-31+25i;-31+23i;-31+21i;-31+19i;-31+17i;-31+15i;-31+13i;-31+11i;-31+9i;-31+7i;-31+5i;-31+3i;-31+1i;-31-1i;-31-3i;-31-5i;-31-7i;-31-9i;-31-11i;-31-13i;-31-15i;-31-17i;-31-19i;-31-21i;-31-23i;-31-25i;-31-27i;-31-29i;-31-31i;-29+31i;-29+29i;-29+27i;-29+25i;-29+23i;-29+21i;-29+19i;-29+17i;-29+15i;-29+13i;-29+11i;-29+9i;-29+7i;-29+5i;-29+3i;-29+1i;-29-1i;-29-3i;-29-5i;-29-7i;-29-9i;-29-11i;-29-13i;-29-15i;-29-17i;-29-19i;-29-21i;-29-23i;-29-25i;-29-27i;-29-29i;-29-31i;-27+31i;-27+29i;-27+27i;-27+25i;-27+23i;-27+21i;-27+19i;-27+17i;-27+15i;-27+13i;-27+11i;-27+9i;-27+7i;-27+5i;-27+3i;-27+1i;-27-1i;-27-3i;-27-5i;-27-7i;-27-9i;-27-11i;-27-13i;-27-15i;-27-17i;-27-19i;-27-21i;-27-23i;-27-25i;-27-27i;-27-29i;-27-31i;-25+31i;-25+29i;-25+27i;-25+25i;-25+23i;-25+21i;-25+19i;-25+17i;-25+15i;-25+13i;-25+11i;-25+9i;-25+7i;-25+5i;-25+3i;-25+1i;-25-1i;-25-3i;-25-5i;-25-7i;-25-9i;-25-11i;-25-13i;-25-15i;-25-17i;-25-19i;-25-21i;-25-23i; ...
            -25-25i;-25-27i;-25-29i;-25-31i;-23+31i;-23+29i;-23+27i;-23+25i;-23+23i;-23+21i;-23+19i;-23+17i;-23+15i;-23+13i;-23+11i;-23+9i;-23+7i;-23+5i;-23+3i;-23+1i;-23-1i;-23-3i;-23-5i;-23-7i;-23-9i;-23-11i;-23-13i;-23-15i;-23-17i;-23-19i;-23-21i;-23-23i;-23-25i;-23-27i;-23-29i;-23-31i;-21+31i;-21+29i;-21+27i;-21+25i;-21+23i;-21+21i;-21+19i;-21+17i;-21+15i;-21+13i;-21+11i;-21+9i;-21+7i;-21+5i;-21+3i;-21+1i;-21-1i;-21-3i;-21-5i;-21-7i;-21-9i;-21-11i;-21-13i;-21-15i;-21-17i;-21-19i;-21-21i;-21-23i;-21-25i;-21-27i;-21-29i;-21-31i;-19+31i;-19+29i;-19+27i;-19+25i;-19+23i;-19+21i;-19+19i;-19+17i;-19+15i;-19+13i;-19+11i;-19+9i;-19+7i;-19+5i;-19+3i;-19+1i;-19-1i;-19-3i;-19-5i;-19-7i;-19-9i;-19-11i;-19-13i;-19-15i;-19-17i;-19-19i;-19-21i;-19-23i;-19-25i;-19-27i;-19-29i;-19-31i;-17+31i;-17+29i;-17+27i;-17+25i;-17+23i;-17+21i;-17+19i;-17+17i;-17+15i;-17+13i;-17+11i;-17+9i;-17+7i;-17+5i;-17+3i;-17+1i;-17-1i;-17-3i;-17-5i;-17-7i;-17-9i;-17-11i;-17-13i;-17-15i;-17-17i;-17-19i;-17-21i;-17-23i;-17-25i;-17-27i; ...
            -17-29i;-17-31i;-15+31i;-15+29i;-15+27i;-15+25i;-15+23i;-15+21i;-15+19i;-15+17i;-15+15i;-15+13i;-15+11i;-15+9i;-15+7i;-15+5i;-15+3i;-15+1i;-15-1i;-15-3i;-15-5i;-15-7i;-15-9i;-15-11i;-15-13i;-15-15i;-15-17i;-15-19i;-15-21i;-15-23i;-15-25i;-15-27i;-15-29i;-15-31i;-13+31i;-13+29i;-13+27i;-13+25i;-13+23i;-13+21i;-13+19i;-13+17i;-13+15i;-13+13i;-13+11i;-13+9i;-13+7i;-13+5i;-13+3i;-13+1i;-13-1i;-13-3i;-13-5i;-13-7i;-13-9i;-13-11i;-13-13i;-13-15i;-13-17i;-13-19i;-13-21i;-13-23i;-13-25i;-13-27i;-13-29i;-13-31i;-11+31i;-11+29i;-11+27i;-11+25i;-11+23i;-11+21i;-11+19i;-11+17i;-11+15i;-11+13i;-11+11i;-11+9i;-11+7i;-11+5i;-11+3i;-11+1i;-11-1i;-11-3i;-11-5i;-11-7i;-11-9i;-11-11i;-11-13i;-11-15i;-11-17i;-11-19i;-11-21i;-11-23i;-11-25i;-11-27i;-11-29i;-11-31i;-9+31i;-9+29i;-9+27i;-9+25i;-9+23i;-9+21i;-9+19i;-9+17i;-9+15i;-9+13i;-9+11i;-9+9i;-9+7i;-9+5i;-9+3i;-9+1i;-9-1i;-9-3i;-9-5i;-9-7i;-9-9i;-9-11i;-9-13i;-9-15i;-9-17i;-9-19i;-9-21i;-9-23i;-9-25i;-9-27i;-9-29i;-9-31i;-7+31i;-7+29i;-7+27i;-7+25i;-7+23i; ...
            -7+21i;-7+19i;-7+17i;-7+15i;-7+13i;-7+11i;-7+9i;-7+7i;-7+5i;-7+3i;-7+1i;-7-1i;-7-3i;-7-5i;-7-7i;-7-9i;-7-11i;-7-13i;-7-15i;-7-17i;-7-19i;-7-21i;-7-23i;-7-25i;-7-27i;-7-29i;-7-31i;-5+31i;-5+29i;-5+27i;-5+25i;-5+23i;-5+21i;-5+19i;-5+17i;-5+15i;-5+13i;-5+11i;-5+9i;-5+7i;-5+5i;-5+3i;-5+1i;-5-1i;-5-3i;-5-5i;-5-7i;-5-9i;-5-11i;-5-13i;-5-15i;-5-17i;-5-19i;-5-21i;-5-23i;-5-25i;-5-27i;-5-29i;-5-31i;-3+31i;-3+29i;-3+27i;-3+25i;-3+23i;-3+21i;-3+19i;-3+17i;-3+15i;-3+13i;-3+11i;-3+9i;-3+7i;-3+5i;-3+3i;-3+1i;-3-1i;-3-3i;-3-5i;-3-7i;-3-9i;-3-11i;-3-13i;-3-15i;-3-17i;-3-19i;-3-21i;-3-23i;-3-25i;-3-27i;-3-29i;-3-31i;-1+31i;-1+29i;-1+27i;-1+25i;-1+23i;-1+21i;-1+19i;-1+17i;-1+15i;-1+13i;-1+11i;-1+9i;-1+7i;-1+5i;-1+3i;-1+1i;-1-1i;-1-3i;-1-5i;-1-7i;-1-9i;-1-11i;-1-13i;-1-15i;-1-17i;-1-19i;-1-21i;-1-23i;-1-25i;-1-27i;-1-29i;-1-31i;1+31i;1+29i;1+27i;1+25i;1+23i;1+21i;1+19i;1+17i;1+15i;1+13i;1+11i;1+9i;1+7i;1+5i;1+3i;1+1i;1-1i;1-3i;1-5i;1-7i;1-9i;1-11i;1-13i;1-15i;1-17i;1-19i;1-21i;1-23i;1-25i;1-27i;1-29i;1-31i; ...
            3+31i;3+29i;3+27i;3+25i;3+23i;3+21i;3+19i;3+17i;3+15i;3+13i;3+11i;3+9i;3+7i;3+5i;3+3i;3+1i;3-1i;3-3i;3-5i;3-7i;3-9i;3-11i;3-13i;3-15i;3-17i;3-19i;3-21i;3-23i;3-25i;3-27i;3-29i;3-31i;5+31i;5+29i;5+27i;5+25i;5+23i;5+21i;5+19i;5+17i;5+15i;5+13i;5+11i;5+9i;5+7i;5+5i;5+3i;5+1i;5-1i;5-3i;5-5i;5-7i;5-9i;5-11i;5-13i;5-15i;5-17i;5-19i;5-21i;5-23i;5-25i;5-27i;5-29i;5-31i;7+31i;7+29i;7+27i;7+25i;7+23i;7+21i;7+19i;7+17i;7+15i;7+13i;7+11i;7+9i;7+7i;7+5i;7+3i;7+1i;7-1i;7-3i;7-5i;7-7i;7-9i;7-11i;7-13i;7-15i;7-17i;7-19i;7-21i;7-23i;7-25i;7-27i;7-29i;7-31i;9+31i;9+29i;9+27i;9+25i;9+23i;9+21i;9+19i;9+17i;9+15i;9+13i;9+11i;9+9i;9+7i;9+5i;9+3i;9+1i;9-1i;9-3i;9-5i;9-7i;9-9i;9-11i;9-13i;9-15i;9-17i;9-19i;9-21i;9-23i;9-25i;9-27i;9-29i;9-31i;11+31i;11+29i;11+27i;11+25i;11+23i;11+21i;11+19i;11+17i;11+15i;11+13i;11+11i;11+9i;11+7i;11+5i;11+3i;11+1i;11-1i;11-3i;11-5i;11-7i;11-9i;11-11i;11-13i;11-15i;11-17i;11-19i;11-21i;11-23i;11-25i;11-27i;11-29i;11-31i;13+31i;13+29i;13+27i;13+25i;13+23i;13+21i;13+19i;13+17i;13+15i; ...
            13+13i;13+11i;13+9i;13+7i;13+5i;13+3i;13+1i;13-1i;13-3i;13-5i;13-7i;13-9i;13-11i;13-13i;13-15i;13-17i;13-19i;13-21i;13-23i;13-25i;13-27i;13-29i;13-31i;15+31i;15+29i;15+27i;15+25i;15+23i;15+21i;15+19i;15+17i;15+15i;15+13i;15+11i;15+9i;15+7i;15+5i;15+3i;15+1i;15-1i;15-3i;15-5i;15-7i;15-9i;15-11i;15-13i;15-15i;15-17i;15-19i;15-21i;15-23i;15-25i;15-27i;15-29i;15-31i;17+31i;17+29i;17+27i;17+25i;17+23i;17+21i;17+19i;17+17i;17+15i;17+13i;17+11i;17+9i;17+7i;17+5i;17+3i;17+1i;17-1i;17-3i;17-5i;17-7i;17-9i;17-11i;17-13i;17-15i;17-17i;17-19i;17-21i;17-23i;17-25i;17-27i;17-29i;17-31i;19+31i;19+29i;19+27i;19+25i;19+23i;19+21i;19+19i;19+17i;19+15i;19+13i;19+11i;19+9i;19+7i;19+5i;19+3i;19+1i;19-1i;19-3i;19-5i;19-7i;19-9i;19-11i;19-13i;19-15i;19-17i;19-19i;19-21i;19-23i;19-25i;19-27i;19-29i;19-31i;21+31i;21+29i;21+27i;21+25i;21+23i;21+21i;21+19i;21+17i;21+15i;21+13i;21+11i;21+9i;21+7i;21+5i;21+3i;21+1i;21-1i;21-3i;21-5i;21-7i;21-9i;21-11i;21-13i;21-15i;21-17i;21-19i;21-21i;21-23i;21-25i;21-27i;21-29i; ...
            21-31i;23+31i;23+29i;23+27i;23+25i;23+23i;23+21i;23+19i;23+17i;23+15i;23+13i;23+11i;23+9i;23+7i;23+5i;23+3i;23+1i;23-1i;23-3i;23-5i;23-7i;23-9i;23-11i;23-13i;23-15i;23-17i;23-19i;23-21i;23-23i;23-25i;23-27i;23-29i;23-31i;25+31i;25+29i;25+27i;25+25i;25+23i;25+21i;25+19i;25+17i;25+15i;25+13i;25+11i;25+9i;25+7i;25+5i;25+3i;25+1i;25-1i;25-3i;25-5i;25-7i;25-9i;25-11i;25-13i;25-15i;25-17i;25-19i;25-21i;25-23i;25-25i;25-27i;25-29i;25-31i;27+31i;27+29i;27+27i;27+25i;27+23i;27+21i;27+19i;27+17i;27+15i;27+13i;27+11i;27+9i;27+7i;27+5i;27+3i;27+1i;27-1i;27-3i;27-5i;27-7i;27-9i;27-11i;27-13i;27-15i;27-17i;27-19i;27-21i;27-23i;27-25i;27-27i;27-29i;27-31i;29+31i;29+29i;29+27i;29+25i;29+23i;29+21i;29+19i;29+17i;29+15i;29+13i;29+11i;29+9i;29+7i;29+5i;29+3i;29+1i;29-1i;29-3i;29-5i;29-7i;29-9i;29-11i;29-13i;29-15i;29-17i;29-19i;29-21i;29-23i;29-25i;29-27i;29-29i;29-31i;31+31i;31+29i;31+27i;31+25i;31+23i;31+21i;31+19i;31+17i;31+15i;31+13i;31+11i;31+9i;31+7i;31+5i;31+3i;31+1i;31-1i;31-3i;31-5i;31-7i;31-9i;31-11i; ...
            31-13i;31-15i;31-17i;31-19i;31-21i;31-23i;31-25i;31-27i;31-29i;31-31i]);
            
       end
   end
 end
       
%create the windowing filter if NumWindow is grater than zero
if(NumWindow>0)
    
    switch FilterTyp
        case 'blackman'
        Windowfiltall=transpose(blackman(2*NumWindow));
        otherwise %use blackman if undefined
         Windowfiltall=transpose(blackman(2*NumWindow));    
    end
    
    
    Winfiltleft=Windowfiltall(1:NumWindow);
    Winfiltright=Windowfiltall((NumWindow+1):2*NumWindow);
end

%store the data vector in datas, necessary if user defined data is used
datas=data;

for a=1:NumPackages 

  data=[];

  if(IsRandata==1)
     
      %Start to create the 1th symbol
       nextSymbol=1;

       for i=1:NumSymbols
          symboldata= createdataforonesymbol (nextSymbol,hmodem,FFTLength,numGuardLowerSubcarriers, numGuardHigherSubcarriers,ResourceMap,QuamLevels,QuamIdentifier,ResourceModulation); 
    
          if(i>=NumSymbolsperMap)
          %Loop the Symbols from the Symbol given via ResourceRepeatIndex (create the first 1th Symbol for Resource Repeat Index 0) 
          nextSymbol=ResourceRepeatIndex+1;
          else
          nextSymbol=nextSymbol+1;       
          end
      
       data=cat(2,data,symboldata);
    
       end

  else
    
      nextSymbol=1;
      lengthdata=0;
    
      for i=1:NumSymbols
      symboldatalength= calculatebindatapersymbol (nextSymbol,hmodem,FFTLength,numGuardLowerSubcarriers, numGuardHigherSubcarriers,ResourceMap,QuamLevels,QuamIdentifier,ResourceModulation); 
    
        if(i>=NumSymbolsperMap)
          %Loop the Symbols from the Symbol given via ResourceRepeatIndex (create the first 1th Symbol for Resource Repeat Index 0) 
          nextSymbol=ResourceRepeatIndex+1;
        else
          nextSymbol=nextSymbol+1;       
        end
      lengthdata=lengthdata+symboldatalength;
    
      end
    
      N=floor(lengthdata/length(datas));
      s=repmat(datas,1,1);
      dataN=repmat(datas,1,N);
      restdatabits=lengthdata-N*length(datas);
      dataN=cat(2,dataN,datas(1:restdatabits));
      data=dataN;
    
  end
   
  datalenght=length(data);

  iqdata=[];
  %next Pilot to be read when repeat is started at resource repeat index 
  PilotStart=searchpilotpreamindex(ResourceMap,Repeatat,1);
  %next Preamble to be read when repeat is started at resource repeat index
  PreambleStart=searchpilotpreamindex(ResourceMap,Repeatat,3);
  %Start to create the 1th symbol
  nextSymbol=1;
  %next Pilot to be read (next map entry in Pilots)
  PilotCarrierIndex=1;
  %next Preamble to be read (next map entry in Preamble)
  PreambleCarrierIndex=1; 
  %start to read data bits at position in data arry
  bitposition=1;

  for i=1:NumSymbols
       [SignalTime_Oversampled,PilotCarrierIndex,PreambleCarrierIndex, bitposition]= createonesymbol (nextSymbol,hmodem,data,FFTLength,numGuardLowerSubcarriers, numGuardHigherSubcarriers, PilotDefinitions, PreambleIQValues,ResourceMap,QuamLevels,QuamIdentifier,ResourceModulation,bitposition,PilotCarrierIndex,PreambleCarrierIndex,oversampling,prefix); 
       if(nextSymbol>=NumSymbolsperMap)
          %Loop the Symbols from the Symbol given via ResourceRepeatIndex (create the first 1th Symbol for Resource Repeat Index 0) 
           nextSymbol=ResourceRepeatIndex+1;
           PilotCarrierIndex=PilotStart;
           PreambleCarrierIndex=PreambleStart;
       else
          nextSymbol=nextSymbol+1;       
       end
       %use window if window parameter is > 0
            if(NumWindow>0)
              SignalTime_Oversampled(1:NumWindow)=SignalTime_Oversampled(1:NumWindow).*Winfiltleft(1:NumWindow); 
              len=length(SignalTime_Oversampled);
              SignalTime_Oversampled(len-NumWindow+1:len)=SignalTime_Oversampled(len-NumWindow+1:len).*Winfiltright(1:NumWindow); 
              SignalTime_Window=SignalTime_Oversampled;
            else
                SignalTime_Window=SignalTime_Oversampled;
            end
       iqdata=cat(2,iqdata,SignalTime_Window);
   end

    if(fshift>0)
     %if the signal is s(t)=s1(t)+j*s2(t), then the real signal
     %s(t)=s1(t)*cos(2*pi*fshift*t)-s2(t)*sin(2*pi*fshift*t)is created
     len = length(iqdata);
     cy = round(len * fshift / (OFDMSystemFrequency*oversampling)); 
     shiftSig = exp(j * 2 * pi * cy * (linspace(0, 1 - 1/len, len)));
     iqdata=iqdata.*shiftSig;
    end

    if(BurstInterval>0)
      %Fill the time signal with N zeros
      arbConfig = loadArbConfig();
      N = round(BurstInterval*(OFDMSystemFrequency*oversampling) / arbConfig.segmentGranularity) * arbConfig.segmentGranularity;
      try
        zerotime=zeros(1,N);
        iqdata=cat(2,iqdata,zerotime);
      catch ex 
        msgbox('Can not add burst interval, burst interval too long','Message')    
      end
    end

    % make column vectors
    iqdata = iqdata.';
    data = data.';
    
   iqdatapack=cat(1,iqdatapack,iqdata);
   datapack=cat(1,datapack,data);

end

iqdata = iqdatapack;

%% apply amplitude correction if necessary
if (correction)
    [iqdata, channelMapping] = iqcorrection(iqdata, OFDMSystemFrequency*oversampling, 'chMap', channelMapping);
end

%% normalize the output
scale = max(max(max(abs(real(iqdata))), max(abs(imag(iqdata)))));
iqdata = iqdata / scale;

assignin('base', 'iqdata', iqdatapack);



function [value N]=calculateN(FFTLength,ResourceMap,uppercarrier,lowercarrier)
       
        if(FFTLength-uppercarrier-lowercarrier>0)
          N=length(ResourceMap)/(FFTLength-uppercarrier-lowercarrier); 
        else
          N=0;
        end
        
        if(round(N)==N&& N>=1)
          value=1; %Value is ok., Resource Map+Carriers longer than FFTLenght
          return;
        end
          value=0; %Value false
      
        
function value=searchpilotpreamindex(ResourceMap,Repeatat,a)
        
        value=0;
        %count number of pilots till repeatat
        if(Repeatat>1)
             
           for i=1:Repeatat-1 
              if(ResourceMap(i)==a)
                 value=value+1;
              end
           end
           if(value==0)
             value=1;
             return
           end
             value=2*value+1;
           else
             value=1;
        end
 
function symboldata= createdataforonesymbol (numnextsymbol,hmodem,FFTLength,numGuardLowerSubcarriers, numGuardHigherSubcarriers,ResourceMap,QuamLevels,QuamIdentifier,ResourceModulation);          
      
      symboldata=[];
      carrierstobecoded=FFTLength-numGuardLowerSubcarriers-numGuardHigherSubcarriers;
      Startcodinginresourcemapindex=(numnextsymbol-1)*carrierstobecoded;
      
       for i=1:carrierstobecoded
         %If Data Case    
         if(ResourceMap(i+Startcodinginresourcemapindex)==0)
           %If Modulation for data Carrier is defined
           if(QuamLevels(QuamIdentifier( ResourceModulation(i+Startcodinginresourcemapindex)+1)+1)~=0) 
             a=randi([0,1],1,QuamLevels(QuamIdentifier( ResourceModulation(i+Startcodinginresourcemapindex)+1)+1) );
             %If Modulation for data carrier is not defined use default (BPSK)
           else
             a=randi([0,1],1,1);  
           end
           symboldata=cat(2,symboldata,a);
         end  
       end
       
%Calculate how many data bits are coded with one symbol (nextSymbol)       
function symboldatalength= calculatebindatapersymbol (numnextsymbol,hmodem,FFTLength,numGuardLowerSubcarriers, numGuardHigherSubcarriers,ResourceMap,QuamLevels,QuamIdentifier,ResourceModulation);    
          
          symboldatalength=0;
          carrierstobecoded=FFTLength-numGuardLowerSubcarriers-numGuardHigherSubcarriers;
          Startcodinginresourcemapindex=(numnextsymbol-1)*carrierstobecoded;
          for i=1:carrierstobecoded
           %If Data Case    
            if(ResourceMap(i+Startcodinginresourcemapindex)==0)
           
               %If Modulation for data Carrier is defined
               if(QuamLevels(QuamIdentifier( ResourceModulation(i+Startcodinginresourcemapindex)+1)+1)~=0)
                 a=QuamLevels(QuamIdentifier( ResourceModulation(i+Startcodinginresourcemapindex)+1)+1);
               %If Modulation for data carrier is not defined use default (BPSK)
               else
                 a=1
               end
               symboldatalength=symboldatalength+a;
            end  
         end
          
          
function [SignalTime_Oversampled,PilotCarrierIndex,PreambleCarrierIndex, bitposition]= createonesymbol (numnextsymbol,hmodem,data,FFTLength,numGuardLowerSubcarriers, numGuardHigherSubcarriers, PilotDefinitions, PreambleIQValues,ResourceMap,QuamLevels,QuamIdentifier,ResourceModulation,bitposition,PilotCarrierIndex,PreambleCarrierIndex,oversampling,prefix) 
   
     carrierstobecoded=FFTLength-numGuardLowerSubcarriers-numGuardHigherSubcarriers;
     %Create Subcarrier Vectors
     Subcarrierlow=zeros(1,numGuardLowerSubcarriers);
     Subcarrierhigh=zeros(1,numGuardHigherSubcarriers);
     %Create FFT Data Vector without subcarriers
     FFTinnerdata=zeros(1, carrierstobecoded);
     
     Startcodinginresourcemapindex=(numnextsymbol-1)*carrierstobecoded;
     
       k=1;
       for i=1:carrierstobecoded
         
           switch ResourceMap(i+Startcodinginresourcemapindex)
           %Case coding of binary data    
           case 0
             %get Quam Identifier
             Index=QuamIdentifier(ResourceModulation(i+Startcodinginresourcemapindex)+1)+1;
             %mod is number of bits to be coded
             mod=QuamLevels(Index);
             %if no modulation decided, use BPSK (default)
             if(mod==0)
               mod=1;
             end
             hmod=hmodem(Index);
             %get the bits to be coded
             subdata=transpose(data(bitposition:(mod+bitposition-1)));
             %calculate the I+jQ values
             bins = (subdata).';
             str_x = num2str(bins);
             str_x(isspace(str_x)) = '';
             dec = bin2dec(str_x);
             
             remoddata=hmod.modulate(dec);
             %normalize the modulation (the same scale factor for all modulations)
             
             %---------scaling------------------------------------------
             s = hmod.modulate(0:(hmod.m-1));
             scaleFactor=sqrt(sum(abs(s).^2)/hmod.m);     
             remoddata=remoddata/ scaleFactor;
             
             %------------------------------------------------------------
             test = remoddata;
             FFTinnerdata(k)= remoddata(1);
             %FFTinnerdata(i)=1 for testing
             bitposition=bitposition+mod;
          case 1
             %Pilot to be decoded
             y=PilotDefinitions(PilotCarrierIndex)+j*PilotDefinitions(PilotCarrierIndex+1);
             PilotCarrierIndex=PilotCarrierIndex+2;
             FFTinnerdata(k)=y;
             %Unknown Pilot (set to default value)
          case 2   
             FFTinnerdata(k)=1+j*0;
             %Preamble Value
          case 3
             y=PreambleIQValues(PreambleCarrierIndex )+j*PreambleIQValues(PreambleCarrierIndex+1);
             PreambleCarrierIndex=PreambleCarrierIndex+2;
             FFTinnerdata(k)=y;
             %Null Carrier
          case 4      
             FFTinnerdata(k)=0;
          case 5
             FFTinnerdata(k)=0;
          end
       k=k+1; 
     end
  
%note ft/2 is not used -ft/2 is used     
FFTData=cat(2,Subcarrierlow,FFTinnerdata,Subcarrierhigh);
%fprintf(sprintf('nextSym: %d, PilotIdx: %d, Pilot: %g\n', numnextsymbol, PilotCarrierIndex, FFTinnerdata(5)));
fill = zeros(1, length(FFTData)/2 * (oversampling - 1));
SignalTime_Oversampled = ifft(fftshift([fill FFTData fill]));

if (prefix~=0)
  SignalTime_Oversampled=cat(2,SignalTime_Oversampled(round(length(SignalTime_Oversampled)*(1-prefix)+1):length(SignalTime_Oversampled)),SignalTime_Oversampled);   
end
 


  
