%
% MOHAWK Calibration
%
function iqmohawk(visaAddr)

  mohawk = iqopen(visaAddr);
  if (isempty(mohawk))
      disp('RCAL VISA address must be specified');
      return;
  end
    
% iqmohawk.m
%   Measures VSA Receiver Amp,Delay and Phase flatness using Mohawk BPSK
%   Generator as a reference source. For use with IQTools program.

% iqmohawk.m Rev.08 2020.02.26 Ed Barich
%   Changed Harmonic Interference Test from:
%   "Test for BPSK tones falling on modulation odd harmonics" to
%   "Test for BPSK tones falling on ALL modulation harmonics"

% iqmohawk.m Rev.07 2020.02.19 Ed Barich
%   1. Changed Ref unlock and Low SNR error messages and
%   added return to initial VSA state when these errors occur.
%   2. Now limiting MeasPts to be a finite range (50,64,100,128,200).
%   3. Set parameter VsaPtsExp = 14.

% iqmohawk.m Rev.06 2019.08.01 Ed Barich
%   Fixed bug in line 226: "if rem(100,Tones) == 0" is changed to:
%   "if rem(Tones,100) == 0"
%   Also commented out lines 219-222 to keep Scope sample rate from using
%   User Sample rate.

% iqmohawk.m Rev.05 2019.07.08 Ed Barich
%   Modified to get ABS and S21 cal data from RCAL internal EEPROM

% iqmohawk.m Rev.04 2019.06.12 Ed Barich
%   Modified to allow MeasPtsDesired to be 2^N where N = positive integer

% iqmohawk.m Rev.03 2019.06.11 Ed Barich
%   Modified Mohawk absolute power cal data interpolation by removing the
%   'spline' option from the interp1 function because it was causing
%   large interpolation errors at the Mohawk band edges due to 1Hz
%   separation of cal points.

% iqmohawk.m Rev.02 2019.05.02 Ed Barich
%   Modified SincCorr calculation to include the mag rolloff of the BPSK
%   modulation for wide bandwidths up to 5GHz.

% iqmohawk.m Rev.01 2019.03.29 Ed Barich
%   Derived from VsaRxCalUsingMohawkRev12.m, for use with IQTools

% VsaRxCalUsingMohawkRev12.m 2019.01.23 Ed Barich
%   Modified to use FX3 SCIPI Mohawk commands

% VsaRxCalUsingMohawkAsRef11.m 2018.11.14 Ed Barich
%   Redesigned to start from existing VSA state, do Mohawk cal, then return
%   to original VSA state with user RF cal applied
%   This has been reduced to a single center frequency measurement

% VsaRxCalUsingMohawkAsRef10.m 2018.11.07 Ed Barich
%   Uses VsaRfCalData.s2p files instead of VsaIfCalData.cal files

% VsaRxCalUsingMohawkAsRef09.m 2018.10.25 Ed Barich
%   Features & fixes from UxaRxCalUsingMohawkRef04.m
%   Replaced ConcatCal with Mohawk StepCal corrections

% VsaRxCalUsingMohawkAsRef08.m 2018.10.15 Ed Barich
%   Updated Mohawk FX3 Controller code
%   Added Ext IF Output command to UXA setup to route IF to Ext Digitizer.
%   Mohawk Center Frequency will be adjusted to avoid image interference
%   when using 5GHz IF and External Digitizer.

% VsaRxCalUsingMohawkAsRef07.m 2018.05.17 Ed Barich
%   MODIFIED FOR FX3 CONTROLLER

% VsaRxCalUsingMohawkAsRef06.m 2018.04.30 Ed Barich
%   Added routine to check freqFund to see if Mohawk sub/harmonics will
%   alias into receiver IF; if so, turn ImageShiftOn.

% VsaRxCalUsingMohawkAsRef05.m 2018.04.30 Ed Barich
%   Added control of Spectrum Analyzer if it is being used with an external
%   digitizer.

% VsaRxCalUsingMohawkAsRef04.m 2018.04.24 Ed Barich
%   Replaced ExternalMix parameter with ExternalDigitizer
%   Added UxaIsConverter parameter to allow the UXA use an external digitizer

% VsaRxCalUsingMohawkAsRef04.m 2018.04.24 Ed Barich
%   Deleted MeasMagOnly parameter and associated functionality.
%   Switched ImageShiftOn to be applied to Mohawk CF instead of Receiver.

% VsaRxCalUsingMohawkAsRef03.m 2018.04.03 Ed Barich
%   Derived from VsaRxCalUsingMohawkAsRef01.m
%   Using measurement engine from UxaConcatCal13.m

% VsaRxCalUsingMohawkAsRef01.m 2017.08.01 Ed Barich
%   Derived from MohawkFlatnessMeas02.m, with methods from UxaConcatCal09.m

% MohawkFlatnessMeas.m
%   Measures IF Amplitude, Delay and Phase Response of the Mohawk Proto 1,
%   BPSK-modulated RF signal generator.
%   Measurement is made at a fixed RF frequency with a wideband stimulus and
%   using Vector Signal Analyzer as the receiver.
%   Multiple center frequencies can be measured, and correction files from
%   the BpskFreqConverterCal.m program can be used to verify cal accuracy.

% MohawkFlatnessMeas.m Rev.02 2017.01.24 Ed Barich
%   Added Magnitude-only measurement using spectrum analyzer

% MohawkFlatnessMeas.m Rev.01 2017.01.12 Ed Barich
%   Derived from BpskFreqConverterCal12C.m

% BpskFreqConverterCal12C.m - Rev.12C 2017.01.10 Ed Barich (Happy Birthday!)
%   Using .dll driver for Mohawk internal VCO/Synthesizers instead of
%   external signal sources. To prevent FreqRfCenter from being an integer
%   multiple of the FreqMod, added a 2-bin offset to FreqRfCenter if this
%   occurs.

persistent CalDataSerialNum FreqsAbsPowerCal PwrOutCorr  FreqStepCal StepCalResponseMagLog StepCalResponsePhaseDeg;
tic;    % Start timer

% Measurement Parameters that need to be adjusted:
MeasPtsDesired = 50;    % Desired number of measurement frequencies in Span (must be N*50 or 2^N where N = positive integer)

% Measurement Parameters that seldom need to be changed:
UseAbsPowerCalData = 1;   % =0,Do not use cal data; =1,Use Mohawk Abs Power Cal data
UseS21CalData = 1;  % =0,Do not use StepCal data,=1,Use Mohawk Step Cal Data from file
DisplayStepCalCorrections = 0;  % =0,Do not display; =1,Display Step Cal Corrections
MeasPtsOutsideSpan = 0;     % =0,No points measured outside SA span; =1,Two Points measured outside SA span 
VsaPtsExp = 14;             % Averaging Exponent (integer) for VSA measurement points , 1=51 points, 2=101, 3=401,...
SnrRequired = 50;           % Required measurement signal to noise ratio for averaging (positive dBm)
AveMin = 1;                 % Minimum averaging number to be used
AveMax = 25;                % Maximum averaging number to be used
ImageShiftDiv = 16;         % Divisor for Image Shift (positive integer, power of 2)
PointOffset = 4;            % Offset in PointPerTone to dodge Mohawk harmonics (small integer)
WindowEnabled = 0;          % =0,Windowing disabled, =1,Windowing enabled
MohawkExtRef = 1;           % =0,Mohawk uses Internal Reference, =1,Mohawk uses External Reference
InChanVsa = 0;              % =0,Scope CH1 is input,=1,Scope CH3 is input
NormalizeDelayToMidPt = 0;  % =0,Normalize Delay to mean value; =1,Normalize Delay to mid point

% File Paths used in this program:
FilePathCompCorr = [ pwd '\S_parameters' ];  % Path to ComplexCorrection data files

% Read RCAL Serial number:
xfprintf(mohawk,'SERVICE:CONF:SN?');    % Read RCAL serial number
[RcalSerialNum] = fscanf(mohawk);    % Read Serial Number data string
RcalSerialNum = RcalSerialNum(1:10);  % Delete trailing character

% Get Mohawk Abs Power Cal data from module EEPROM:
if UseAbsPowerCalData    
    if  size(PwrOutCorr) == 0   % No Cal Data present:
        [FreqsAbsPowerCal,PwrOutCorr,~,CalDataSerialNum] = readRcalData(mohawk,'ABS');  % Call function to read RCAL data    
    elseif ~strcmp(RcalSerialNum,CalDataSerialNum)  % RCAL serial number does not match Cal Data serial number:
        [FreqsAbsPowerCal,PwrOutCorr,~,CalDataSerialNum] = readRcalData(mohawk,'ABS');  % Call function to read RCAL data    
    end
end

% Get Mohawk Step Cal data from module EEPROM:
if UseS21CalData
    if  size(StepCalResponseMagLog) == 0   % No Cal Data present:
        [FreqStepCal,StepCalResponseMagLog,StepCalResponsePhaseDeg,CalDataSerialNum] = readRcalData(mohawk,'S21');  % Call function to read RCAL data    
    elseif ~strcmp(RcalSerialNum,CalDataSerialNum)  % RCAL serial number does not match Cal Data serial number:
        [FreqStepCal,StepCalResponseMagLog,StepCalResponsePhaseDeg,CalDataSerialNum] = readRcalData(mohawk,'S21');  % Call function to read RCAL data    
    end
end

% Connect to VSA:
asmPath = [ pwd '\Interfaces' ];  % Path to VSA interface dlls
asm = NET.addAssembly(strcat(asmPath,'\','Agilent.SA.Vsa.Interfaces.dll')); % Standard VSA interfaces
asmExt = NET.addAssembly(strcat(asmPath,'\','Agilent.SA.Vsa.HardwareExtensions.Core.Interfaces.dll')); % Hardware Extensions VSA interfaces
import Agilent.SA.Vsa.*;
% Attach to a running instance of VSA. If there no running instance, create one:
vsaApp = ApplicationFactory.Create();
if (isempty(vsaApp))
    wasVsaRunning = false;
    disp('Initializing VSA software, which will take a REALLY long time...');
    vsaApp = ApplicationFactory.Create(true, '', '', -1);       % Uses available port
else
    wasVsaRunning = true;
end
vsaApp.IsVisible = true;    % Make VSA visible
% Interfaces to major items:
vsaMeas = vsaApp.Measurements.SelectedItem;
vsaDisp = vsaApp.Display;

vsaApp.SaveSetup([ pwd '\InitialVsaSetupFile.setx' ]);  % Save initial VSA setup to a file

% Get VSA Initial States:
vsaMeas.IsContinuous = false;               % Set Continuous measurement OFF
vsaMeas.Average.Style = AverageStyle.Off;   % Set Averaging Style to OFF
FreqRfCenter = vsaMeas.Frequency.Center;    % Get RF Center Frequency
FreqSpan = vsaMeas.Frequency.Span;          % Get Frequency Span
InitVsaRangeInVpk = vsaMeas.Input.Analog.Range;    % Get initial input Range in Volts Peak
InitVsaRangeInDbm = 20*log10(InitVsaRangeInVpk)+10;    % Calc initial input Range in dBm

% Get Receiver states:    
try    % Receiver is an XSA:
    InitUwPath = vsaMeas.Input.Extensions.Item(0).GetParameter(Agilent.SA.Vsa.InstrumentType.Adc, 'uWPathControl'); % This gets the enum
    switch InitUwPath
        case 0
            CharUwPath = 'STD';
        case 1
            CharUwPath = 'LoNo';
        case 2
            CharUwPath = 'MBP';
        case 3
            CharUwPath = 'FBP';
        otherwise
            CharUwPath = 'Unk';
    end       
    InitRfInPort = vsaMeas.Input.Extensions.Item(0).GetParameter(Agilent.SA.Vsa.InstrumentType.Adc, 'SignalInput');     % This gets the enum
    switch InitRfInPort
        case 4
            CharRfInPort = 'RFIn';
        case 11
            CharRfInPort = 'RFIn2';
        otherwise
            CharRfInPort = 'Unk';
    end
    % Determine receiver first IF frequency:
    if FreqSpan <= 40e6
        FreqIfCenter = 250e6;
    elseif FreqSpan <= 160e6
        FreqIfCenter = 300e6;
    else
        FreqIfCenter = 750e6;
    end
    RxIsXsa = 1;                % =1,Receiver is xSA
catch    % Receiver is not an XSA,probably a scope:
    RxIsXsa = 0;                % =0,Receiver is NOT xSA
    FreqIfCenter = vsaMeas.Corrections.Item(0).ExternalConverterIFCenter; % Get Receiver first IF center frequency 
%     FreqIfSpan = vsaMeas.Corrections.Item(0).ExternalConverterIFBandwidth; % Get Receiver first IF bandwidth 
%     vsaMeas.Input.Extensions.Item(0).SetParameter(Agilent.SA.Vsa.InstrumentType.Adc, 'SampleMode', Agilent.SA.Vsa.HardwareExtensions.Infiniium.SampleMode.UserRate);    % Set SampleMode to UserRate
%     DigitizerSampleRate = 4*(FreqIfCenter+FreqIfSpan/2);   % Calculate needed digitizer sample rate
%     vsaMeas.Input.Extensions.Item(0).SetParameter(Agilent.SA.Vsa.InstrumentType.Adc, 'UserSampleRate', num2str(DigitizerSampleRate));    % Set UserSampleRate
end

% Calculate other measurement parameters:
MeasPtsAllowed = [ 50 64 100 128 200 ]; % Measurement points that are valid to use
Delta = MeasPtsAllowed - MeasPtsDesired;    % Difference between desired and allowed
[~,indClosest] = min(abs(Delta));   % Index of allowed points closest to desired points
MeasPtsBest = MeasPtsAllowed(indClosest);   % Use closest number of points for measurement
Tones = 2*MeasPtsBest;   % Number of modulation tones in the VSA span (odd and even harmonics)   
MeasPts = (Tones/2)+2*MeasPtsOutsideSpan;   % Number of measurement points in the VSA span (odd harmonics only)
VsaPts = 1+50*(2^VsaPtsExp);            % VSA measurement points in span
TimePts = 1.28*(VsaPts-1);              % Number of points in VSA time record
PtsPerTone = (VsaPts-1)/Tones;          % VSA frequency points per modulation tone
FreqMod = PtsPerTone*FreqSpan/(VsaPts-1);    % BSPK modulation rate (Hz)

% Set Mohawk initial states:
if MohawkExtRef
    [ statusRef ] = setReferenceState( 1,mohawk );  % Set Mohawk External Reference ON
else
    [ statusRef ] = setReferenceState( 0,mohawk );  % Set Mohawk External Reference OFF
end
stateMohawkMod = 0;         % Mohawk Modulation State: =0,Mod OFF; =1, ON
[ statusMod ] = setModulationState( stateMohawkMod,mohawk );  % Set Modulation State
[ statusModFreq ] = setModulationFrequency( FreqMod,mohawk );  % Set Modulation Frequency
[ statusCentFreq,freqFund ] = setCenterFrequency(FreqRfCenter,mohawk);  % Set Center Frequency

% State of Complex Corrections:
if RxIsXsa
    CompCorrState = [  'CF' num2str(FreqRfCenter/1e9) 'GHz_SP' num2str(FreqSpan/1e6) 'MHz_Pts' num2str(MeasPts) '_' CharRfInPort '_Rng' num2str(InitVsaRangeInDbm) 'dBm_' CharUwPath ];
else
    CompCorrState = [  'CF' num2str(FreqRfCenter/1e9) 'GHz_SP' num2str(FreqSpan/1e6) 'MHz_Pts' num2str(MeasPts) '_Rng' num2str(InitVsaRangeInDbm) 'dBm' ];
end
FileNameVsaRfCal =  [ 'CompCorr_' CompCorrState '.s2p'];       % File name for VSA RF Cal data

% Check to see if RF Corrections are being applied:
InitRfCorrApplied = vsaMeas.InputCorrections.Item(InChanVsa).IsRFExternalCorrectionEnabled; % Are RF Corrections turned ON?
InitCorrectionFile = vsaMeas.InputCorrections.Item(InChanVsa).RFExternalCalibrationFile;    % Get Path&Name of RF Corrections
FileAndPathVsaRfCal = [ FilePathCompCorr, '\', FileNameVsaRfCal ];      % This is the Path&Name of the RF Corrections that should be used
if InitRfCorrApplied && (InitCorrectionFile == FileAndPathVsaRfCal )
    UseVsaRfCorrections = 1;    % If corrections are present and valid, use them
else
    UseVsaRfCorrections = 0;    % If corrections are not valid, do not use them
    vsaMeas.InputCorrections.Item(InChanVsa).RFExternalCalibrationFile = '';    % Assign VSA RF Cal file to a null
    vsaMeas.InputCorrections.Item(InChanVsa).IsRFExternalCorrectionEnabled = false; % Turn RF Filter correction OFF
end

% VSA SETUP SECTION:

% Set to Vector Measurement Mode:
vecType = Agilent.SA.Vsa.VectorMeasurement.ExtensionType();
measExt = vsaMeas.SetMeasurementExtension(vecType);
vecHandle = Agilent.SA.Vsa.VectorMeasurement.CastToExtensionType(measExt);

if InChanVsa       % 2-Channel, Scope CH3 is used
    logicalChTypes = NET.createArray('Agilent.SA.Vsa.LogicalChannelType', 2);
    logicalChTypes(1) = Agilent.SA.Vsa.LogicalChannelType.Baseband;
    logicalChTypes(2) = Agilent.SA.Vsa.LogicalChannelType.Baseband;    
    vsaMeas.Input.ChangeLogicalChannels(logicalChTypes);
end

% Set up VSA spectral displays and markers:
vsaDisp.Traces.ArrangeWindows((ArrangeWindowHints.HideExtra), 3, 1);  % Set up 3 stacked display windows
vsaTraceA = vsaDisp.Traces.Item(0); % Display A
vsaTraceA.DataName = ['Spectrum' num2str(InChanVsa+1)];     % Set display to Spectrum
vsaTraceA.Format = TraceFormatType.LogMagnitude;     % Set display to Log Magnitude
vsaTraceB = vsaDisp.Traces.Item(1); % Display B
vsaTraceB.DataName = ['Main Time' num2str(InChanVsa+1)];     % Set display to Main Time
vsaTraceB.Format = TraceFormatType.Real;     % Set display to Real
vsaTraceC = vsaDisp.Traces.Item(2); % Display C
vsaTraceC.DataName = ['Main Time' num2str(InChanVsa+1)];     % Set display to Main Time
vsaTraceC.Format = TraceFormatType.Imaginary;     % Set display to Imaginary

% Set VSA settings for measurement:
vsaMeas.Frequency.Points = VsaPts;     % Set VSA frequency points
vsaMeas.Frequency.IsResBWArbitrary = true;    % Set Resolution BW to arbitrary
vsaMeas.Frequency.Window = WindowType.Uniform;  % Set windowing to rectangular

% Set VSA User RF Corrections settings:
if UseVsaRfCorrections        
    vsaMeas.InputCorrections.Item(InChanVsa).RFExternalCalibrationFile = '';    % Assign VSA RF Cal file to a null
    vsaMeas.InputCorrections.Item(InChanVsa).RFExternalCalibrationFile = [ FilePathCompCorr, '\', FileNameVsaRfCal ];    % READ VSA RF Cal file
    vsaMeas.InputCorrections.Item(InChanVsa).IsRFExternalCorrectionEnabled = true; % Turn RF Filter correction ON
else
    vsaMeas.InputCorrections.Item(InChanVsa).IsRFExternalCorrectionEnabled = false; % Turn RF Filter correction OFF
end

% Measure Power of CW signal from Mohawk to get Center Frequency Gain:
vsaMeas.Restart;    % Take a VSA measurement
vsaMeas.WaitForMeasurementDone; % Wait for VSA measurement complete
vsaTraceA.YScaleAuto;   % Autoscale Y-axis
vsaTraceA.Markers.SelectedIndex = 0;   % Marker 1 index
vsaTraceA.Markers.SelectedItem.IsVisible = true;   % Turn marker ON
vsaTraceA.Markers.SelectedItem.MoveTo(MarkerMoveType.Peak);   % Move marker to Peak
MkrFreqAtCenterFreq = vsaTraceA.Markers.Item(0).XAxis;    % Marker frequency at CW signal
CenterFreqError = MkrFreqAtCenterFreq-FreqRfCenter;     % Freqency error of signal
if abs(CenterFreqError) > (FreqSpan/(VsaPts-1))
    disp(['WARNING: Signal is off by ',num2str(CenterFreqError/1e6),'MHz; Check 10MHz Reference from receiver to RCAL module and RF path from RCAL Out to receiver Input']);
    vsaApp.RecallSetup([ pwd '\InitialVsaSetupFile.setx' ], false, false);  % Recall initial VSA setup
    return;
end
MkrPwrAtCenterFreq = vsaTraceA.Markers.Item(0).Y;    % Marker power at CW signal
if UseAbsPowerCalData
    MohawkPwrAtCenterFreq = interp1(FreqsAbsPowerCal,PwrOutCorr,FreqRfCenter);   % Calculate interpolated value for Mohawk Abs Power Cal
    GainAtCenterFreq = MkrPwrAtCenterFreq - MohawkPwrAtCenterFreq;  % Path gain at center frequency
else
    GainAtCenterFreq = 0;  % Path gain at center frequency
end
[ statusMod ] = setModulationState( 1,mohawk );  % Set Mohawk Modulation back ON for vector calibration

% Model of BPSK magnitude shape vs. bandwidth:
NullFreq = 50e9;        % Frequency of sinc null for Mohawk hardware
indPts = [ (MeasPts-1):-2:1 1:2:(MeasPts-1) ];  % Odd harmonics on either side of carrier
HarmShape = 1 ./ indPts;  % 1/N linear rolloff of harmonics for BPSK odd tones
CosShape = cos(FreqSpan*(pi/2)*indPts/(NullFreq*MeasPts));   % Cosine shape of BPSK rolloff across span
SincCorr = HarmShape .* CosShape;  % Total Sin(x)/x rolloff of BPSK tones

%%%%%%%%%%% MEASUREMENT LOOP: %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Test for Image or Harmonic interference and dodge if necessary:
FreqRfCenterMohawk = FreqRfCenter;  % Mohawk centered at SA center frequency
[ statusCentFreq,freqFund ] = setCenterFrequency(FreqRfCenterMohawk,mohawk);  % Set Mohawk Center Frequency
% Test for Images and Shift Rx center frequency if necessary:
if abs(rem(2*FreqIfCenter,freqFund)) < FreqSpan/(VsaPts-1)  % Test for images due to Mohawk multiplier subharmonics
    % [NOTE: This happens at FreqRfCenter=90GHz if FreqIfCenter=5GHz with external digitzer]
    ImageShiftOn = 1;       % Use ImageShift
    disp('Mohawk Center Frequency will be adjusted to avoid image interference'); 
    FreqRfCenterMohawk = FreqRfCenterMohawk-FreqMod/ImageShiftDiv;      % Offset Mohawk Center Frequency
    [ statusCentFreq,freqFund ] = setCenterFrequency( FreqRfCenterMohawk,mohawk );      % Offset Mohawk Center Frequency
else
    ImageShiftOn = 0;       % No ImageShift
end
% Test for harmonic interference and adjust modulation frequency if necessary:
if abs(rem(2*FreqIfCenter,FreqMod)) < FreqSpan/(VsaPts-1)  % Image Test for 2*IF frequency is multiple of modulation frequency
    disp('Mohawk Modulation Frequency will be adjusted to avoid image interference');  
    PtsPerTone = ((VsaPts-1)/Tones)+PointOffset;          % Adjust by PointOffset to avoid harmonic interference
    FreqMod = PtsPerTone*FreqSpan/(VsaPts-1);    % BSPK modulation rate (Hz)
end
% if abs(rem(FreqRfCenterMohawk,2*FreqMod)) < FreqSpan/(VsaPts-1)  % Test for BPSK tones falling on modulation odd harmonics
if abs(FreqRfCenterMohawk-(FreqMod*round(FreqRfCenterMohawk/FreqMod))) < FreqSpan/(VsaPts-1)  % "Test for BPSK tones falling on ALL modulation harmonics"
    disp('Mohawk Modulation Frequency will be adjusted to avoid harmonic interference');  
    PtsPerTone = ((VsaPts-1)/Tones)+(PointOffset+1);          % Adjust PointOffset+1 to avoid harmonic interference
    FreqMod = PtsPerTone*FreqSpan/(VsaPts-1);    % BSPK modulation rate (Hz)
end
[ statusModFreq ] = setModulationFrequency( FreqMod,mohawk );  % Set Modulation Frequency
FreqOffset = FreqMod*(1-MeasPts:2:-(1-MeasPts));    % Calculate center frequency offsets array for plotting and mag-only measurements
FreqOffsetDelay = FreqMod*((2-MeasPts):2:-(2-MeasPts));    % Calculate center frequency offsets array for plotting delay

% Get Mohawk Step Cal correction data:
if UseS21CalData
    InterpFreq = FreqRfCenterMohawk+FreqOffset;    % Frequencies of interpolated output vector
    StepCalInterpMag = interp1(FreqStepCal,StepCalResponseMagLog,InterpFreq,'spline');   % Calculate interpolated values
    StepCalInterpMag = StepCalInterpMag - mean(StepCalInterpMag(MeasPts/2:1+MeasPts/2));    % Mag Normalized to 2 center points
    StepCalInterpPhase = interp1(FreqStepCal,StepCalResponsePhaseDeg,InterpFreq,'spline');   % Calculate interpolated values
    StepCalInterpPhase = StepCalInterpPhase - mean(StepCalInterpPhase(MeasPts/2:1+MeasPts/2));    % Phase Normalized to 2 center points
    StepCalInterpDelay = -diff(unwrap(StepCalInterpPhase))/(360*(2*FreqMod));  % Calculate Delay as derivative of Phase (negative sign matches VNA convention)
    StepCalInterpDelay = StepCalInterpDelay - StepCalInterpDelay(MeasPts/2);   % Delay normalized to mid point
    if DisplayStepCalCorrections
        figure()    % Plot Step Cal Mag,Delay,Phase vs. Freq:
        subplot(3,1,1),plot(FreqOffset/1e6,StepCalInterpMag);
        title([ 'Step Cal: ' CompCorrState ] ,'Interpreter','none');
        ylabel('Mag (dB)');
        subplot(3,1,2),plot(FreqOffsetDelay/1e6,StepCalInterpDelay/1e-9);
        ylabel('Delay (nSec)');
        subplot(3,1,3),plot(FreqOffset/1e6,StepCalInterpPhase);
        xlabel('Offset Frequency (MHz)');
        ylabel('Phase (degrees)');
    end
else
    StepCalInterpMag = zeros(1,MeasPts);    % Null Step cal data
    StepCalInterpDelay = zeros(1,MeasPts-1);    % Null Step cal data
end

% Time-averaged Measurement Loop:
ResponseMagAccum = zeros(1,MeasPts);        % Initialize accumulator
ResponseDelayAccum = zeros(1,(MeasPts)-1);  % Initialize accumulator
Ave = 1;        % Initialize averging index
TimeAves = 1;   % Initialize number of Time Averages
while Ave <= TimeAves    % Start Time Averaging Loop
    % Take VSA measurement:
    vsaMeas.Frequency.Center = FreqRfCenter;        % Set VSA center frequency to RF measurement center frequency
    vsaMeas.Restart;    % Take a VSA measurement
    vsaMeas.WaitForMeasurementDone; % Wait for VSA measurement complete
    SysDoubReal = vsaTraceB.DoubleData(TraceDataSelect.Y, false); % Get Y-axis Real data
    DataReal = SysDoubReal.double;  % Copy to array
    SysDoubImag = vsaTraceC.DoubleData(TraceDataSelect.Y, false); % Get Y-axis Imaginary data
    DataImag = SysDoubImag.double;  % Copy to array
    DataComplex = DataReal + 1i*DataImag;
    if ImageShiftOn
        Rotator = exp(1i*2*pi*((1:TimePts))/(TimePts*ImageShiftDiv/PtsPerTone));  % Calc rotator to shift spectrum frequency by FreqMod/ImageShiftDiv
        DataComplex = DataComplex .* Rotator;       % Apply frequency offset for image rejection
    end

    % Rotate Time Waveform to Align Rising Edge at T=0:         
    ResponseImpulseComplex = [ 0 diff(DataComplex)]; % Impulse is derivative of Step Response; add first zero point
    [MaxVal,ImpulsePeakPt] = max(abs(ResponseImpulseComplex));   % Find peak mag point of real impulse
    DataComplexShifted = circshift(DataComplex,[ 0 1-ImpulsePeakPt]);    % Shift impulse point to left;

    % Take FFT of Time Waveform and calculate Frequency Response:
    if WindowEnabled
        Window = flattopwin(TimePts)';      % Window for FFT
        %Window = blackman(TimePts)';
        %Window = gausswin(TimePts,3.58)';
        DataComplexShifted = DataComplexShifted .* Window;    % Convolve time data with window
    end
    Spectrum = fft(DataComplexShifted)/TimePts;               % Take FFT of time record
    Spectrum = circshift(Spectrum,(TimePts/2)-1,2);    % Shift DC to center of array
    Spectrum = Spectrum((TimePts/2)+1-((MeasPts))*PtsPerTone : (TimePts/2)+((MeasPts))*PtsPerTone ); % Keep center Points
    SpectrumTones = Spectrum(PtsPerTone*(1:2:(2*MeasPts-1)));     % Keep measurement points only
    ResponseFreqTonesAbs = abs(SpectrumTones)./SincCorr;    % Apply Sin(x)/x magnitude correction for BPSK amplitude rolloff
    ResponseFreqTonesAng = angle(SpectrumTones) + (pi/2)*sign((1:MeasPts)-((MeasPts+1)/2));   % Remove BPSK pi radians phase shift at origin
    [ResponseFreqTonesReal,ResponseFreqTonesImag] = pol2cart(ResponseFreqTonesAng,ResponseFreqTonesAbs);    % Get real and imaginary parts
    ResponseFreqTones = ResponseFreqTonesReal + 1i*ResponseFreqTonesImag;   % Reassemble complex frequency response
    ResponseMag = abs(ResponseFreqTones);   % Magnitude of Response
    ResponseMagAccum = ResponseMagAccum + ResponseMag;  % Accumulate for averaging
    ResponsePhaseRadians = -angle(ResponseFreqTones);     % Phase in Radians; (negative sign matches Network Analyzer convention)
    ResponseDelay = diff(unwrap(ResponsePhaseRadians))/(2*pi*(2*FreqMod));  % Calculate Delay as derivative of Phase
    ResponseDelayAccum = ResponseDelayAccum + ResponseDelay;  % Accumulate for averaging

    % Calculate TimeAves for specified measurement SNR:
    if Ave == 1 
        [MinVal,ResponseMinPt] = min(abs(SpectrumTones((1+MeasPtsOutsideSpan):(MeasPts-MeasPtsOutsideSpan))));   % Find min mag point of real impulse
        ResponseMagDbmMin = 10*log10(((abs(SpectrumTones(ResponseMinPt+MeasPtsOutsideSpan))/sqrt(2)).^2)/50)+30;     % Magnitude (dBm) of lowest SNR tone
        MagNoise = mean(10*log10(((abs(Spectrum)/sqrt(2)).^2)/50)+30);     % Noise magnitude (dBm) is mean of spectrum trace
        SnrMeas = ResponseMagDbmMin - MagNoise;         % Calculated measured spectrum signal to noise ratio in dBm
        if SnrMeas < 0
            disp('WARNING: Signal to Noise Ratio is negative dB; Check RF path from RCAL Out to receiver Input');
            vsaApp.RecallSetup([ pwd '\InitialVsaSetupFile.setx' ], false, false);  % Recall initial VSA setup
            return;
        end
        TimeAves = ceil(10^((SnrRequired-SnrMeas)/10));     % Calculate required number of TimeAves
        if TimeAves < AveMin
            TimeAves = AveMin;  % Limit averaging to specified minimum value
        end
        if TimeAves > AveMax
            TimeAves = AveMax;  % Limit averaging to specified maximum value
        end
        disp([ 'TimeAves= ' num2str(TimeAves) ]);
%             figure; plot(10*log10(((abs(Spectrum)/sqrt(2)).^2)/50)+30); % Plot spectrum for troubleshooting purposes
    end

    Ave = Ave+1;        % Increment averaging index
end     % End Time Averaging Loop

% Calculate Averages:
ResponseMagAve = ResponseMagAccum/TimeAves;             % Average of Mag values
ResponseDelayAve = ResponseDelayAccum/TimeAves;            % Average of Delay values
ResponseDelayAve = ResponseDelayAve - StepCalInterpDelay;         % Apply Mohawk Step Cal Correction

% Convert Mag to dBm:
ResponseMagWatts = ((ResponseMagAve/sqrt(2)).^2)/50; % Convert VoltsPeak to Watts in 50 ohm
ResponseMagDbm = 10*log10(ResponseMagWatts)+30;            % Mag converted to dBm
ResponseMagDbm = ResponseMagDbm - StepCalInterpMag;         % Apply Mohawk Step Cal Correction

% Normalize traces; Calculate Phase from Delay:    
ResponseMagDbmNorm = ResponseMagDbm - mean(ResponseMagDbm(MeasPts/2:1+MeasPts/2)); % MagDbm normalized to mean value of middle 2 points
ResponseMagDbmNorm = ResponseMagDbmNorm + GainAtCenterFreq; % Add center frequency gain to normalized response
if NormalizeDelayToMidPt
    ResponseDelayNorm = ResponseDelayAve - ResponseDelayAve(MeasPts/2);   % Delay normalized to mid point
else
    ResponseDelayNorm = ResponseDelayAve - mean(ResponseDelayAve);   % Delay normalized to mean value of all points
end
ResponsePhaseDegrees = [ 0 (-cumsum(ResponseDelayNorm)) ]*360*(2*FreqMod);  % Integrate to get phase and convert radians to degrees; (negative sign matches VNA convention)
ResponsePhaseDegreesNorm = ResponsePhaseDegrees - mean(ResponsePhaseDegrees(MeasPts/2:1+MeasPts/2)); % Phase normalized to mean value of middle 2 points

% Save results to VSA RF Cal file:
if ~UseVsaRfCorrections
   SaveUxaRfCalFile([ FilePathCompCorr '\' FileNameVsaRfCal],FreqRfCenter+FreqOffset,ResponseMagDbmNorm,ResponsePhaseDegreesNorm); % Function that saves results to VSA RF Cal file
%    SaveUxaRfCalFile([ FilePathCompCorr '\Inverted_', FileNameVsaRfCal],FreqRfCenter+FreqOffset,fliplr(ResponseMagDbmNorm),-fliplr(ResponsePhaseDegreesNorm)); % Invert frequency points for Ext Mix
end

figure()    % Plot Mag,Delay,Phase vs. Freq:
subplot(3,1,1),plot(FreqOffset/1e6,ResponseMagDbmNorm);
if UseVsaRfCorrections
    CompCorrChar = 'CompCorrON';
else
    CompCorrChar = 'CompCorrOFF';
end
title([ CompCorrState ',' CompCorrChar  ] ,'Interpreter','none');
ylabel('Mag (dB)');
subplot(3,1,2),plot(FreqOffsetDelay/1e6,ResponseDelayNorm/1e-9);
ylabel('Delay (nSec)');
subplot(3,1,3),plot(FreqOffset/1e6,ResponsePhaseDegreesNorm);
xlabel('Offset Frequency (MHz)');
ylabel('Phase (degrees)');

% Return VSA to original state:
vsaApp.RecallSetup([ pwd '\InitialVsaSetupFile.setx' ], false, false);  % Recall initial VSA setup

% Set VSA User Correction RF Filter settings:
if ~UseVsaRfCorrections        
    vsaMeas.InputCorrections.Item(InChanVsa).RFExternalCalibrationFile = '';    % Assign VSA RF Cal file to a null
    vsaMeas.InputCorrections.Item(InChanVsa).RFExternalCalibrationFile = [ FilePathCompCorr, '\', FileNameVsaRfCal ];    % READ VSA RF Cal file
    vsaMeas.InputCorrections.Item(InChanVsa).IsRFExternalCorrectionEnabled = true; % Turn RF Filter correction ON
end

ElapsedTime = toc;    % End timer
  
% Close the Mohawk session
 iqclose(mohawk);
 
end
