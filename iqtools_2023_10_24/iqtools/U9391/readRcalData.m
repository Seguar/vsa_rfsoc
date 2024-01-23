function [Freq,Mag,Phase,SerNum] =  readRcalData(RcalObj,CalParm)
    % Function for reading Calibration data from RCAL module memory
    
    % readRcalData.m  Version03  2020.01.09 Ed Barich
    %   Modified to read 18 or 20 character numbers using split command
    
    % readRcalData.m  Version02 2020.01.03 Ed Barich
    %   FOR RCAL FIRMWARE A.00.05 or later (USING LICENSING)
    %   Increased number of decimal digits in readRcalData function
    
    % readRcalData.m  Version01 (First Version, Pre-Licensing) Ed Barich
    
    % INPUTS:
        % RcalObj= Object to connect to RCAL module
        % CalParm= Calibration parameter to be addressed ('ABS','S21,or 'S22')
    % OUTPUTS:
        % Frequency= Cal frequencies (Hz)
        % Mag= Calibrated absolute[Calparm=ABS, in dBm] or relative [CalParm=S21 or S22, in dB] magnitude of RCAL
        % Phase= Calibrated relative phase of RCAL [CalParm=S21 or S22, in degrees]
        % SerNum= Serial number of RCAL unit
    
    fprintf(RcalObj,['SERVice:CAL:',CalParm,':COUNt?']);  % Query number of cal points
    [PointsString] = fscanf(RcalObj);    % Read Cal data string
    Points = str2double(PointsString);  % Convert string to double
    Freq = zeros(1,Points); % Assign array
    Mag = zeros(1,Points); % Assign array
    Phase = zeros(1,Points); % Assign array
    disp(['Reading RCAL ',CalParm,' Data from EEPROM...']);
    for Ind = 1:Points
        switch CalParm
            case 'ABS'    
               % Read Absolute Power Cal Data:
               fprintf(RcalObj,['SERVice:CAL:',CalParm,'? ',num2str(Ind-1),',1']);  % Query cal point data
               [CalDataString] = fscanf(RcalObj);    % Read Cal data string
                CalDataArray = split(CalDataString,',');    % Split into separate strings
                Freq(Ind) = str2double(CalDataArray(1));  % Convert string to double
                Mag(Ind) = str2double(CalDataArray(2));  % Convert string to double
           case {'S21','S22'}
                % Read Relative Mag and Phase Cal Data:
                fprintf(RcalObj,['SERVice:CAL:',CalParm,'? ',num2str(Ind-1),',1']);  % Query cal point data
                [CalDataString] = fscanf(RcalObj);    % Read Cal data string
                CalDataArray = split(CalDataString,',');    % Split into separate strings
                Freq(Ind) = str2double(CalDataArray(1));  % Convert string to double
                Mag(Ind) = str2double(CalDataArray(2));  % Convert string to double
                Phase(Ind) = str2double(CalDataArray(3));  % Convert string to double
            otherwise
                error('CalParm not specified correctly');
        end
    end
    fprintf(RcalObj,'SERVICE:CONF:SN?');    % Read RCAL serial number
    [SerNum] = fscanf(RcalObj);    % Read Serial Number data string
    SerNum = SerNum(1:10);  % Delete trailing character
    disp(['Reading RCAL ',CalParm,' Data from EEPROM FINISHED']);
end
