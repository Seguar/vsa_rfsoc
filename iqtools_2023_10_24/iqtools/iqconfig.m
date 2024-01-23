function varargout = iqconfig(varargin)
% IQCONFIG M-file for iqconfig.fig
%      IQCONFIG, by itself, creates a new IQCONFIG or raises the existing
%      singleton*.
%
%      H = IQCONFIG returns the handle to a new IQCONFIG or the handle to
%      the existing singleton*.
%
%      IQCONFIG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQCONFIG.M with the given input arguments.
%
%      IQCONFIG('Property','Value',...) creates a new IQCONFIG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqconfig_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqconfig_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqconfig

% Last Modified by GUIDE v2.5 26-Oct-2022 09:50:17

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqconfig_OpeningFcn, ...
                   'gui_OutputFcn',  @iqconfig_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before iqconfig is made visible.
function iqconfig_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqconfig (see VARARGIN)

% Choose default command line output for iqconfig
handles.output = hObject;

modelInfo = { ...
% tag              mode description (empty if no modes)   ptr to     list of
%                                                        arbModel    GUI features
'M8199B',          'interleaved',                           0, {'amplitude','offset','moduleID','multiModule','skew','peaking','ampType','sampleMarker'}; ...
'M8199B_NONILV',   'non-interleaved',                       0, {'amplitude','offset','moduleID','multiModule','skew','peaking','ampType','sampleMarker'}; ...
'M8199A',          'non-interleaved',                       0, {'amplitude','offset','moduleID','multiModule','skew','peaking','ampType','sampleMarker','psg'}; ...
'M8199A_ILV',      'interleaved',                           0, {'amplitude','offset','moduleID','multiModule','skew','peaking','ampType','sampleMarker','psg'}; ...
% 'M8198A',          [],                                      0, {'amplitude', 'moduleID'}; ...
'M8196A',          [],                                      0, {'amplitude','offset','trigger','clkSource','peaking','multiModule','sw_skew'}; ...
'M8195A_1ch',      '1 ch, deep mem, 64 GSa/s, with markers' 0, {'amplitude','offset','trigger','clkSource','multiModule','sw_skew'}; ...
'M8195A_2ch',      '2 ch, deep mem, 32 GSa/s',              0, {'amplitude','offset','trigger','clkSource','multiModule','sw_skew'}; ...
'M8195A_2ch_mrk',  '2 ch, deep mem, 32 GSa/s, with markers' 0, {'amplitude','offset','trigger','clkSource','multiModule','sw_skew'}; ...
'M8195A_2ch_dupl', '2 ch, deep mem, 32 GSa/s, duplicate'    0, {'amplitude','offset','trigger','clkSource','multiModule','sw_skew'}; ...
'M8195A_2ch_256k', '2 ch, 256k mem, 64 GSa/s',              0, {'amplitude','offset','trigger','clkSource','multiModule','sw_skew'}; ...
'M8195A_4ch',      '4 ch, deep mem, 16 GSa/s',              0, {'amplitude','offset','trigger','clkSource','multiModule','sw_skew'}; ...
'M8195A_4ch_256k', '4 ch, 256k mem, 64 GSa/s',              0, {'amplitude','offset','trigger','clkSource','multiModule','sw_skew'}; ...
'M8195A_Rev1',     'Revision 1 (no longer supported)',      0, {'amplitude','offset'}; ...
'M8194A',          [],                                      0, {'amplitude','offset','trigger','clkSource','ilv','peaking','multiModule','sw_skew'}; ...
'M8190A_12bit',    '12 bit, up to 12 GSa/s',                0, {'amplitude','offset','trigger','clkSource','ilv','ampType','multiModule','skew'}; ...
'M8190A_14bit',    '14 bit, up to 8 GSa/s',                 0, {'amplitude','offset','trigger','clkSource','ilv','ampType','multiModule','skew'}; ...
'M8190A_DUC_x3',   'DUC with x3 interpolation',             0, {'amplitude','offset','trigger','clkSource','ilv','ampType','multiModule','skew','DUC'}; ...
'M8190A_DUC_x12',  'DUC with x12 interpolation',            0, {'amplitude','offset','trigger','clkSource','ilv','ampType','multiModule','skew','DUC'}; ...
'M8190A_DUC_x24',  'DUC with x24 interpolation',            0, {'amplitude','offset','trigger','clkSource','ilv','ampType','multiModule','skew','DUC'}; ...
'M8190A_DUC_x48',  'DUC with x48 interpolation',            0, {'amplitude','offset','trigger','clkSource','ilv','ampType','multiModule','skew','DUC'}; ...
'M8135A',           [],                                     0, {'amplitude'}; ...
'M8121A_12bit',    '12 bit, up to 12 GSa/s',                0, {'amplitude','offset','trigger','clkSource','ilv','ampType','multiModule','skew'}; ...
'M8121A_14bit',    '14 bit, up to 8 GSa/s',                 0, {'amplitude','offset','trigger','clkSource','ilv','ampType','multiModule','skew'}; ...
'M8121A_DUC_x3',   'DUC with x3 interpolation',             0, {'amplitude','offset','trigger','clkSource','ilv','ampType','multiModule','skew','DUC'}; ...
'M8121A_DUC_x12',  'DUC with x12 interpolation',            0, {'amplitude','offset','trigger','clkSource','ilv','ampType','multiModule','skew','DUC'}; ...
'M8121A_DUC_x24',  'DUC with x24 interpolation',            0, {'amplitude','offset','trigger','clkSource','ilv','ampType','multiModule','skew','DUC'}; ...
'M8121A_DUC_x48',  'DUC with x48 interpolation',            0, {'amplitude','offset','trigger','clkSource','ilv','ampType','multiModule','skew','DUC'}; ...
'81180A',          [],                                      0, {'amplitude','offset','trigger','clkSource','ampType','skew'}; ...
'81180B',          [],                                      0, {'amplitude','offset','trigger','clkSource','ampType','skew'}; ...
'81150A',          [],                                      0, {'amplitude','offset'}; ...
'81160A',          [],                                      0, {'amplitude','offset'}; ...
'M9330A/M9331A',   [],                                      0, {'amplitude','offset'}; ...
'M9336A',          [],                                      0, {'amplitude','offset'}; ...
'M3201A_CLF',      'fixed sample rate (CLF)',               0, {'amplitude','offset'}; ...
'M3201A_CLV',      'variable sample rate (CLV)',            0, {'amplitude','offset'}; ...
'M3202A_CLF',      'fixed sample rate (CLF)',               0, {'amplitude','offset'}; ...
'M3202A_CLV',      'variable sample rate (CLV)',            0, {'amplitude','offset'}; ...
'M5300x_baseband', 'Baseband',                              0, {'trigger','clkSource'}; ...
'M5300x_modulated','Modulated',                             0, {'trigger','clkSource','DUC'}; ...
'M5300x_std',      'Std',                                   0, {'trigger','clkSource','DUC'}; ...
% 'M5301x',          [],                                      0, {'trigger','clkSource'}; ...
'N824xA',          [],                                      0, {'amplitude','offset','trigger','clkSource','ampType'}; ...
'N5182A',          [],                                      0, {}; ...
'N5182B',          [],                                      0, {}; ...
'N5172B',          [],                                      0, {}; ...
'N5166B',          [],                                      0, {}; ...
'E4438C',          [],                                      0, {}; ...
'E8267D',          [],                                      0, {}; ...
'M938xA',          'M9381A',                                0, {}; ...
'M9383A',          'M9383A',                                0, {}; ...
'M9383B',          'M9383B',                                0, {}; ...
'M9384B_1Ch',      '1 Channel',                             0, {}; ...
'M9384B_2Ch_IND',  '2 Channel Independent',              	0, {}; ...
'M9384B_2Ch_COH',  '2 Channel Coherent',                    0, {}; ...
'M9484C_1Ch',      '1 Channel',                             0, {}; ...
'M9484C_2Ch_IND',  '2 Channel Independent',              	0, {}; ...
'M9484C_2Ch_COH',  '2 Channel Coherent',                    0, {}; ...
'S93072B_PNA',     'PNA DDS source file creation',          0, {}; ...
'S91xxA_RfOutput',  'RF Output',                            0, {}; ...
'S91xxA_RRH1_RFHD1','Head 1 RFHD1',                         0, {}; ...
'S91xxA_RRH1_RFHD2','Head 1 RFHD2',                         0, {}; ...
'M9410A',          'M9410A',                                0, {}; ...
'M9415A',          'M9415A',                                0, {}; ...
'3351x',           [],                                      0, {'amplitude','offset'}; ...
'3352x',           [],                                      0, {'amplitude','offset'}; ...
'3361x',           [],                                      0, {'amplitude','offset'}; ...
'3362x',           '1Msample',                              0, {'amplitude','offset'}; ...
'3362x_64MS',      '64Msample',                             0, {'amplitude','offset'}; ...
'DSO90000',        [],                                      0, {}; ...
};
% add additional rows
if (exist('iqdownload_AWG7xxx.m', 'file'))
    modelInfo(end+1, :) = {'AWG7xxx', [], 0};
end
if (exist('iqdownload_AWG7xxxx.m', 'file'))
    modelInfo(end+1, :) = {'AWG7xxxx', [], 0};
end
% temporary hack for MUXDAC experiments
% if (exist('muxdac_setup.mat', 'file'))
%     modelInfo(end+1, :) = {'MUXDAC', [], 0};
% end
% search unique instrument models (= tag name up to the first underscore)
[arbModels, ia, ic] = unique(regexp(modelInfo(:,1), '[^_]*', 'match', 'once'), 'stable');
% update the model selection popup menu
set(handles.popupmenuModel, 'String', arbModels);
set(handles.popupmenuModel, 'UserData', 'saveString');
% pointers from modelInfoCell to arbModels
modelInfo(:, 3) = num2cell(ic);
% pointers from arbModel to modelInfoCell
arbModelPtrs = cell(size(arbModels));
for i=1:length(ia)
    arbModelPtrs{i} = find(ic == i);
end

handles.arbModelPtrs = arbModelPtrs;
handles.modelInfo = modelInfo;
% Update handles structure
guidata(hObject, handles);

% select default connection type
set(handles.popupmenuConnectionType, 'Value', 2);

try
    arbCfgFile = iqarbConfigFilename();
catch
    arbCfgFile = 'arbConfig.mat';
end
try
    load(arbCfgFile);
catch e
end
% adjust position of PCIAddr edit control
pos = get(handles.editRecorderAddr, 'Position');
set(handles.editRecorderPCIAddr, 'Position', pos);
% set the multi-module pane to a default state
popupmenuAWGCount_Callback(hObject, eventdata, handles);

% adjust position of PSG panel
pos = get(handles.uipanelRecorder, 'Position');
set(handles.uipanelPSG, 'Position', pos);

%try
    % if no arb model has been selected or it is invalid mark the field red
    % so that the user is aware that he needs to select an AWG model first
    if (~exist('arbConfig', 'var'))
        arbConfig = struct();
        arbConfig.model = 'M8199A';
    end
    if (isfield(arbConfig, 'model'))
        if (strcmp(arbConfig.model, 'M8190A'))  % legacy: treat M8190A as M8190A_14bit
            arbConfig.model = 'M8190A_14bit';
        end
        if (strcmp(arbConfig.model, 'M3201A'))  % legacy: treat M3201A as fixed amplitude
            arbConfig.model = 'M3201A_CLF';
        end
        if (strcmp(arbConfig.model, 'M3202A'))  % legacy: treat M3202A as fixed amplitude
            arbConfig.model = 'M3202A_CLF';
        end
        idx = find(strcmp(modelInfo(:,1), arbConfig.model), 1);
        if (idx > 0)
            set(handles.popupmenuModel, 'Background', 'white');
            arbModels = modelInfo(:,3);
            arbModelIdx = arbModels{idx};
            set(handles.popupmenuModel, 'Value', arbModelIdx);
            modes = handles.modelInfo(handles.arbModelPtrs{arbModelIdx}, 2);
        
            set(handles.popupmenuMode, 'Value', 1);
            set(handles.popupmenuMode, 'String', modes);
            set(handles.popupmenuMode, 'UserData', 'saveList');  % hint to iqsavesettings to store the list of strings
            val = find(idx == handles.arbModelPtrs{arbModelIdx});
            if (~isempty(val))
                set(handles.popupmenuMode, 'Value', val);
            end
            if (isempty(modes{1}) || strcmp(arbConfig.model, 'M8199B'))
                set(handles.popupmenuMode, 'Enable', 'off');
            else
                set(handles.popupmenuMode, 'Enable', 'on');
            end
        else
            set(handles.popupmenuModel, 'Background', 'red');
        end
    end
    if (isfield(arbConfig, 'connectionType'))
        connTypes = get(handles.popupmenuConnectionType, 'String');
        idx = find(strcmp(connTypes, arbConfig.connectionType));
        if (idx > 0)
            set(handles.popupmenuConnectionType, 'Value', idx);
        end
        popupmenuConnectionType_Callback([], [], handles);
    end
    if (isfield(arbConfig, 'visaAddr'))
        set(handles.editVisaAddr, 'String', arbConfig.visaAddr);
    end
    if (isfield(arbConfig, 'ip_address'))
        set(handles.editIPAddress, 'String', arbConfig.ip_address);
    end
    if (isfield(arbConfig, 'port'))
        set(handles.editPort, 'String', num2str(arbConfig.port));
    end
    if (isfield(arbConfig, 'LOIPAddr'))
        set(handles.editLOIPAddr, 'String', arbConfig.LOIPAddr);
    end
    if (isfield(arbConfig, 'SD1ModuleIndex'))
        set(handles.editSD1ModuleIndex, 'String', num2str(arbConfig.SD1ModuleIndex));
    end
    if (isfield(arbConfig, 'M8070ModuleID'))
        set(handles.editM8070ModuleID, 'String', arbConfig.M8070ModuleID);
    end
    if (isfield(arbConfig, 'M8070ModuleID2'))
        set(handles.editM8070ModuleID2, 'String', arbConfig.M8070ModuleID2);
    end
    if (isfield(arbConfig, 'M8070ModuleID3'))
        set(handles.editM8070ModuleID3, 'String', arbConfig.M8070ModuleID3);
    end
    if (isfield(arbConfig, 'M8070ModuleID4'))
        set(handles.editM8070ModuleID4, 'String', arbConfig.M8070ModuleID4);
    end
    % call the modelChange_Callback after setting the VISA address, but
    % before setting the trigger mode and clock modes
    modelChange_Callback(hObject, 'init', handles);
    if (isfield(arbConfig, 'skew'))
        set(handles.editSkew, 'String', iqengprintf(arbConfig.skew));
        set(handles.editSkew, 'Enable', 'on');
        set(handles.checkboxSetSkew, 'Value', 1);
    else
        set(handles.editSkew, 'Enable', 'off');
        set(handles.checkboxSetSkew, 'Value', 0);
    end
    if (isfield(arbConfig, 'gainCorrection'))
        set(handles.editGainCorr, 'String', iqengprintf(arbConfig.gainCorrection));
        set(handles.editGainCorr, 'Enable', 'on');
        set(handles.checkboxSetGainCorr, 'Value', 1);
    else
        set(handles.editGainCorr, 'Enable', 'off');
        set(handles.checkboxSetGainCorr, 'Value', 0);
    end
    if (isfield(arbConfig, 'userSamplerate'))
        set(handles.editUserSampleRate, 'String', iqengprintf(arbConfig.userSamplerate));
        set(handles.editUserSampleRate, 'Enable', 'on');
        set(handles.checkboxUserSampleRate, 'Value', 1);
    else
        set(handles.editUserSampleRate, 'Enable', 'off');
        set(handles.checkboxUserSampleRate, 'Value', 0);
    end
    s = 1;  % use continuous as default
    if (isfield(arbConfig, 'triggerMode'))
        s = find(strcmp(get(handles.popupmenuTrigger, 'String'), arbConfig.triggerMode));
        if (isempty(s))
            s = 1;  % use continuous as default
        end
    end
    set(handles.popupmenuTrigger, 'Value', s);
    if (isfield(arbConfig, 'amplitude'))
        set(handles.editAmpl, 'String', iqengprintf(arbConfig.amplitude));
        set(handles.editAmpl, 'Enable', 'on');
        set(handles.checkboxSetAmpl, 'Value', 1);
        checkScalarOrVector(handles.editAmpl, 1, 16);
    else
        set(handles.checkboxSetAmpl, 'Value', 0);
    end
    if (isfield(arbConfig, 'offset'))
        set(handles.editOffs, 'String', iqengprintf(arbConfig.offset));
        set(handles.editOffs, 'Enable', 'on');
        set(handles.checkboxSetOffs, 'Value', 1);
        checkScalarOrVector(handles.editOffs, 1, 16);
    else
        set(handles.checkboxSetOffs, 'Value', 0);
    end
    if (isfield(arbConfig, 'ampType'))
        ampTypes = get(handles.popupmenuAmpType, 'String');
        idx = find(strcmp(ampTypes, arbConfig.ampType));
        if (idx > 0)
            set(handles.popupmenuAmpType, 'Value', idx);
        end
        set(handles.checkboxSetAmpType, 'Value', 1);
    else
        set(handles.checkboxSetAmpType, 'Value', 0);
    end
    if (isfield(arbConfig, 'outputType'))
        outputTypes = get(handles.popupmenuOutputType, 'String');
        idx = find(strcmp(outputTypes, arbConfig.outputType));
        if (idx > 0)
            set(handles.popupmenuOutputType, 'Value', idx);
        end
    end
    if (isfield(arbConfig, 'clockSource'))
        clkSourceList = {'Unchanged', 'IntRef', 'AxieRef', 'ExtRef', 'ExtClk'};
        idx = find(strcmpi(clkSourceList, arbConfig.clockSource));
        if (idx >= 1 && idx <= length(get(handles.popupmenuClockSource, 'String')))
            set(handles.popupmenuClockSource, 'Value', idx);
        end
        popupmenuClockSource_Callback([], [], handles);
    elseif (isfield(arbConfig, 'extClk') && arbConfig.extClk) % legacy: extClk used to be a separate field
        set(handles.popupmenuClockSource, 'Value', 4);
        popupmenuClockSource_Callback([], [], handles);
    end
    if (isfield(arbConfig, 'clockFreq'))
        set(handles.editClockFreq, 'String', iqengprintf(arbConfig.clockFreq));
    end
    set(handles.checkboxRST, 'Value', (isfield(arbConfig, 'do_rst') && arbConfig.do_rst));
    set(handles.checkboxInterleaving, 'Value', (isfield(arbConfig, 'interleaving') && arbConfig.interleaving));
    if (isfield(arbConfig, 'defaultFc'))
        set(handles.editDefaultFc, 'String', iqengprintf(arbConfig.defaultFc));
    end
    tooltips = 1;
    if (isfield(arbConfig, 'tooltips') && arbConfig.tooltips == 0)
        tooltips = 0;
    end
    set(handles.checkboxTooltips, 'Value', tooltips);
    if (isfield(arbConfig, 'amplScale'))
        set(handles.editAmplScale, 'String', iqengprintf(arbConfig.amplScale));
    end
    if (isfield(arbConfig, 'amplScaleMode'))
        amplScaleModes = get(handles.popupmenuAmplScale, 'String');
        idx = find(strcmp(amplScaleModes, arbConfig.amplScaleMode));
        if (idx > 0)
            set(handles.popupmenuAmplScale, 'Value', idx);
        end
        popupmenuAmplScale_Callback([], [], handles);
    end
    if (isfield(arbConfig, 'filterSettings'))
        filterSettings = get(handles.popupmenuFilterSettings, 'String');
        idx = find(strcmp(filterSettings, arbConfig.filterSettings));
        if (idx > 0)
            set(handles.popupmenuFilterSettings, 'Value', idx);
        end
    end
    if (isfield(arbConfig, 'DACRange'))
        set(handles.editDACRange, 'String', iqengprintf(round(1000 * arbConfig.DACRange)/10));
    end
    if (isfield(arbConfig, 'carrierFrequency'))
        set(handles.editCarrierFreq, 'String', iqengprintf(arbConfig.carrierFrequency));
        set(handles.editCarrierFreq, 'Enable', 'on');
        set(handles.checkboxSetCarrierFreq, 'Value', 1);
    else
        set(handles.textCarrierFreq, 'Enable', 'off');
        set(handles.editCarrierFreq, 'Enable', 'off');
        set(handles.checkboxSetCarrierFreq, 'Value', 0);
    end
    if (isfield(arbConfig, 'peaking'))
        set(handles.editPeaking, 'String', iqengprintf(arbConfig.peaking));
        editPeaking_Callback([], [], handles);
    end
    if (isfield(arbConfig, 'M8195Acorrection'))
        set(handles.checkboxM8195Acorr, 'Value', arbConfig.M8195Acorrection)
    end
    if (isfield(arbConfig, 'sampleMarker'))
        opts = get(handles.popupmenuSampleMarker, 'String');
        idx = find(strcmp(opts, arbConfig.sampleMarker));
        if (idx > 0)
            set(handles.popupmenuSampleMarker, 'Value', idx);
        end
    end
    if (isfield(arbConfig, 'visaAddr2'))
        set(handles.popupmenuAWGCount, 'Value', 2);
        set(handles.editVisaAddr2, 'String', arbConfig.visaAddr2);
    end
    if (isfield(arbConfig, 'visaAddr3'))
        set(handles.popupmenuAWGCount, 'Value', 3);
        set(handles.editVisaAddr3, 'String', arbConfig.visaAddr3);
    end
    if (isfield(arbConfig, 'visaAddr4'))
        set(handles.popupmenuAWGCount, 'Value', 4);
        set(handles.editVisaAddr4, 'String', arbConfig.visaAddr4);
    end

    %--- Sync Module
    if (isfield(arbConfig, 'visaAddrM8192A'))
        set(handles.editVisaAddrM8192A, 'String', arbConfig.visaAddrM8192A);
        if (isfield(arbConfig, 'useM8192A') && (arbConfig.useM8192A ~= 0))
            set(handles.checkboxVisaAddrM8192A, 'Value', 1);
            set(handles.editVisaAddrM8192A, 'Enable', 'on');
            set(handles.pushbuttonTestM8192A, 'Enable', 'on');
        else
            set(handles.checkboxVisaAddrM8192A, 'Value', 0);
            set(handles.editVisaAddrM8192A, 'Enable', 'off');
            set(handles.pushbuttonTestM8192A, 'Enable', 'off');
        end
    end
    popupmenuAWGCount_Callback([], [], handles);
    %--- Scope
    if (isfield(arbConfig, 'visaAddrScope'))
        set(handles.editVisaAddrScope, 'String', arbConfig.visaAddrScope);
        if (~isfield(arbConfig, 'isScopeConnected') || (isfield(arbConfig, 'isScopeConnected') && arbConfig.isScopeConnected ~= 0))
            set(handles.checkboxVisaAddrScope, 'Value', 1);
            set(handles.editVisaAddrScope, 'Enable', 'on');
            set(handles.pushbuttonTestScope, 'Enable', 'on');
        else
            set(handles.checkboxVisaAddrScope, 'Value', 0);
            set(handles.editVisaAddrScope, 'Enable', 'off');
            set(handles.pushbuttonTestScope, 'Enable', 'off');
        end
    end
    %--- VSA
    if (isfield(arbConfig, 'visaAddrVSA'))
        set(handles.editVisaAddrVSA, 'String', arbConfig.visaAddrVSA);
        if (~isfield(arbConfig, 'isVSAConnected') || (isfield(arbConfig, 'isVSAConnected') && arbConfig.isVSAConnected ~= 0))
            set(handles.checkboxRemoteVSA, 'Value', 1);
            set(handles.editVisaAddrVSA, 'Enable', 'on');
            set(handles.pushbuttonTestVSA, 'Enable', 'on');
        else
            set(handles.checkboxRemoteVSA, 'Value', 0);
            set(handles.editVisaAddrVSA, 'Enable', 'off');
            set(handles.pushbuttonTestVSA, 'Enable', 'off');
        end
    end
    %--- DCA
    if (isfield(arbConfig, 'visaAddrDCA'))
        set(handles.editVisaAddrDCA, 'String', arbConfig.visaAddrDCA);
        if (~isfield(arbConfig, 'isDCAConnected') || (isfield(arbConfig, 'isDCAConnected') && arbConfig.isDCAConnected ~= 0))
            set(handles.checkboxDCA, 'Value', 1);
        else
            set(handles.checkboxDCA, 'Value', 0);
        end
        checkboxDCA_update(handles);
    end
    %--- PSG
    if (isfield(arbConfig, 'visaAddrPSG'))
        set(handles.editVisaAddrPSG, 'String', arbConfig.visaAddrPSG);
        if (~isfield(arbConfig, 'isPSGConnected') || (isfield(arbConfig, 'isPSGConnected') && arbConfig.isPSGConnected ~= 0))
            set(handles.checkboxPSG, 'Value', 1);
        else
            set(handles.checkboxPSG, 'Value', 0);
        end
        checkboxPSG_update(handles);
    end
    %--- Power Sensor
    if (isfield(arbConfig, 'visaAddrPowerSensor'))
        set(handles.editVisaAddrPowerSensor, 'String', arbConfig.visaAddrPowerSensor);
    end
    if (isfield(arbConfig, 'powerSensorAverages'))
        set(handles.editPowerSensorAverages, 'String', arbConfig.powerSensorAverages);
    end
    if (isfield(arbConfig, 'isPowerSensorConnected'))
        set(handles.checkboxPowerSensor, 'Value', arbConfig.isPowerSensorConnected);
    end
    checkboxPowerSensor_Callback([], [], handles);
    %--- Recorder
    if (isfield(arbConfig, 'recorderAddr'))
        set(handles.editRecorderAddr, 'String', arbConfig.recorderAddr);
    end
    if (isfield(arbConfig, 'recorderPorts'))
        set(handles.editRecorderPorts, 'String', strtrim(sprintf('%d ', arbConfig.recorderPorts)));
    end
    if (isfield(arbConfig, 'recorderPCIAddr'))
        set(handles.editRecorderPCIAddr, 'String', arbConfig.recorderPCIAddr);
    end
    if (isfield(arbConfig, 'recorderConnectionType') && strcmpi(arbConfig.recorderConnectionType, 'PCIe'))
        set(handles.popupmenuRecorderConnectionType, 'Value', 2);
    else
        set(handles.popupmenuRecorderConnectionType, 'Value', 1);
    end
    if (isfield(arbConfig, 'isRecorderConnected'))
        set(handles.checkboxRecorderConnected, 'Value', arbConfig.isRecorderConnected);
        popupmenuRecorderConnectionType_Callback([], [], handles);
        checkboxRecorderConnected_Callback([], [], handles);
    end
    if (isfield(arbConfig, 'timeout'))
        set(handles.editTimeout, 'String', iqengprintf(arbConfig.timeout));
    end

    % spectrum analyzer
    if (exist('saConfig', 'var'))
        if (isfield(saConfig, 'connected'))
            set(handles.checkboxSAattached, 'Value', saConfig.connected);
        end
        checkboxSAattached_Callback([], [], handles);
        if (isfield(saConfig, 'visaAddr'))
            set(handles.editVisaAddrSA, 'String', saConfig.visaAddr);
        end
    end
%catch e
%    errordlg(e.message);
%end

if (~exist('arbConfig', 'var') || ~isfield(arbConfig, 'tooltips') || arbConfig.tooltips == 1)
set(handles.popupmenuModel, 'TooltipString', sprintf([ ...
    'Select the instrument model. For some models, you also have to select in which\n', ...
    'mode you want the AWG or SigGen to operate']));
set(handles.popupmenuConnectionType, 'TooltipString', sprintf([ ...
    'Use ''visa'' for connections through the VISA library.\n'...
    'Use ''tcpip'' for direct socket connections.\n' ...
    'For the 81180A ''tcpip'' is recommended. For all other instruments \n' ...
    'a ''visa'' connection using the hislip protocol is recommended']));
set(handles.editVisaAddr, 'TooltipString', sprintf([ ...
    'Enter the VISA address as given in the Keysight Connection Expert.\n' ...
    'Examples:  TCPIP0::134.40.175.228::inst0::INSTR\n' ...
    '           TCPIP0::localhost::hislip0::INSTR\n' ...
    '           GPIB0::18::INSTR\n' ...
    'Note, that AXIe-based AWG modules can ONLY be connected through TCPIP.\n' ...
    'Do NOT attempt to connect via the PXIxx:x:x address.']));
set(handles.editIPAddress, 'TooltipString', sprintf([ ...
    'Enter the numeric IP address or hostname. For connection to the same\n' ...
    'PC, use ''localhost'' or 127.0.0.1']));
set(handles.editPort, 'TooltipString', sprintf([ ...
    'Specify the IP Port number for tcpip connection. Usually this is 5025.']));
set(handles.editM8070ModuleID, 'TooltipString', sprintf([ ...
    'Enter the Module ID of the AWG module. The module ID can be found in the M8070B software']));
set(handles.editM8070ModuleID2, 'TooltipString', sprintf([ ...
    'Enter the Module ID of the AWG module. The module ID can be found in the M8070B software']));
set(handles.editM8070ModuleID3, 'TooltipString', sprintf([ ...
    'Enter the Module ID of the AWG module. The module ID can be found in the M8070B software']));
set(handles.editM8070ModuleID4, 'TooltipString', sprintf([ ...
    'Enter the Module ID of the AWG module. The module ID can be found in the M8070B software']));
set(handles.checkboxSetSkew, 'TooltipString', sprintf([ ...
    'Check this box if you want the script to set the skew between I and Q\n' ...
    '(i.e. channel 1 and channel 2). If unchecked, the skew will remain unchanged.\n' ...
    'In case of the M8195A, the skew is used to delay the I waveform mathematically.']));
set(handles.editSkew, 'TooltipString', sprintf([ ...
    'Enter the delay for each channel in units of seconds, separated by spaces.\n' ...
    'These values are used to adjust the hardware delay in the instrument.\n' ...
    'Changes in the hardware will be made upon the next download of a waveform.']));
set(handles.checkboxSetGainCorr, 'TooltipString', sprintf([ ...
    'Check this box if you want the script to apply gain correction between I and Q.\n' ...
    'If unchecked, the waveforms will be downloaded unchanged. In case of the M8195A,\n' ...
    'the gain correction is used to modify the I waveform mathematically.']));
set(handles.editGainCorr, 'TooltipString', sprintf([ ...
    'Enter the gain correction between I and Q in units of dB.\n' ...
    'Positive values will boost I vs. Q, negative values do the opposite.\n' ...
    'Changes in the hardware will be made upon the next download of a waveform.']));
set(handles.checkboxSetAmpl, 'TooltipString', sprintf([ ...
    'Check this box if you want the script to set the amplitude.\n' ...
    'If unchecked, the previously configured amplitude will remain unchanged']));
set(handles.editAmpl, 'TooltipString', sprintf([ ...
    'Enter the single ended amplitude Volts. If you enter a single value, that value will' ...
    'be used for all channels. If you enter multiple values separated by space, comma' ...
    'or semicolon, the first value will be used for ch1, the second for ch2 and so on.' ...
    'Changes in the hardware will be made upon the next download of a waveform.']));
set(handles.checkboxSetOffs, 'TooltipString', sprintf([ ...
    'Check this box if you want the script to set the common mode offset.\n' ...
    'If unchecked, the previously configured offset will remain unchanged']));
set(handles.editOffs, 'TooltipString', sprintf([ ...
    'Enter the common mode offset. If you enter a single value, that value will be' ...
    'used for all channels. If you enter multiple values separated by space, comma' ...
    'or semicolon, the first value will be used for ch1, the second for ch2 and so on.' ...
    'Changes in the hardware will be made upon the next download of a waveform.']));
set(handles.checkboxSetAmpType, 'TooltipString', sprintf([ ...
    'Check this box if you want the script to set the amplifier type.' ...
    'If unchecked, the previously configured amplifier type will remain unchanged.']));
set(handles.popupmenuAmpType, 'TooltipString', sprintf([ ...
    'Select the type of output amplifier you want to use. ''DAC'' is the direct output\n'...
    'from the DAC, which typically has the best signal performance, but limited\n' ...
    'amplitude/offset range. Note, that only some AWGs have switchable amplifiers:\n' ...
    '81180A/B, M8190A and M8121A']));
set(handles.popupmenuClockSource, 'TooltipString', sprintf([ ...
    'Select the sample clock resp. reference clock source for the AWG.\n' ...
    'When you select external sample clock or external reference clock, you must\n' ...
    'also specify the frequency of the input signal. Make sure that you have connected \n' ...
    'a clock signal to the external input before turning this function on. Also, when \n' ...
    'using external sample clock, make sure that you specify the external clock\n' ...
    'frequency in the "sample rate" field of the waveform generation utilities.\n' ...
    'Changes in the hardware will be made upon the next download of a waveform.']));
set(handles.checkboxRST, 'TooltipString', sprintf([ ...
    'Check this box if you want to reset the AWG prior to downloading a new waveform.\n' ...
    'Do not check this checkbox if you plan to use multiple segments or sequence mode.']));
set(handles.checkboxSAattached, 'TooltipString', sprintf([ ...
    'Check this box if you have a spectrum analyzer (PSA, MXA, PXA) connected\n' ...
    'and would like to use it for amplitude flatness correction']));
set(handles.editVisaAddrSA, 'TooltipString', sprintf([ ...
    'Enter the VISA address of the SA as given in the Keysight Connection Expert.\n' ...
    'Examples:  TCPIP0::134.40.175.228::inst0::INSTR\n' ...
    '           GPIB0::18::INSTR']));
set(handles.checkboxTooltips, 'TooltipString', sprintf([ ...
    'Enable/disable tooltips throughout the ''iqtools''.']));
set(handles.editDefaultFc, 'TooltipString', sprintf([ ...
    'If you are using the AWG with external upconversion, enter the\n' ...
    'LO frequency here. This value will be used in the multi-tone and\n' ...
    'digital modulation scripts to set the default center frequency.']));
set(handles.editDACRange, 'TooltipString', sprintf([ ...
    'Set this to 100 to use the DAC to full range. Values less than 100\n' ...
    'cause the waveform to be scaled to the given ratio and use less\n' ...
    'than the full scale DAC. Values greater than 100 cause samples to be clipped.']));
set(handles.editAmplScale, 'TooltipString', sprintf([ ...
    'In M8190A/M8121A DUC mode, this parameter determines the amplitude scaling\n' ...
    'after interpolation and up-conversion. Valid range is from 1 to 2.83.\n' ...
    'Ideally, select the largest value you can without getting distortions.\n' ...
    '(See M8190A/M8121A user guide for more information)']));
set(handles.checkboxInterleaving, 'TooltipString', sprintf([ ...
    'Check this checkbox to distribute even and odd samples to both\n' ...
    'channels. This can be used to virtually double the sample rate\n' ...
    'of the AWG. You have to manually adjust the delay of channel 2\n' ...
    'to one half of a sample period.']));
set(handles.checkboxM8195Acorr, 'TooltipString', sprintf([ ...
    'Check this checkbox to apply the M8195A built-in frequency and\n' ...
    'phase response correction to each channel when downloading waveforms.\n' ...
    'You will probably have to reduce the "DAC range" to avoid clipping\n' ...
    'of DAC values. If clipping occurs, an error message will tell you\n' ...
    'to which value the "DAC range" has to be set']));
set(handles.editPeaking, 'TooltipString', sprintf([ ...
    'The amount of peaking for the M8196A/94A amplifier can be adjusted.\n' ...
    'Positive values increase the peaking (i.e. higher gain at high frequencies)\n' ...
    'The values are unit-less. An increments of 1000 corresponds to approx. 1 dB\n' ...
    'gain at 30 GHz. Try a value of 2000 or 3000 for a noticable effect.' ...
    'You can enter a single value or one value per channel separated by spaces.']));
end

% UIWAIT makes iqconfig wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = iqconfig_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function editIPAddress_Callback(hObject, eventdata, handles)
% hObject    handle to editIPAddress (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editIPAddress as text
%        str2double(get(hObject,'String')) returns contents of editIPAddress as a double


% --- Executes during object creation, after setting all properties.
function editIPAddress_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editIPAddress (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editPort_Callback(hObject, eventdata, handles)
% hObject    handle to editPort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPort as text
%        str2double(get(hObject,'String')) returns contents of editPort as a double
checkScalarOrVector(hObject, 1, 1);


% --- Executes during object creation, after setting all properties.
function editPort_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSkew_Callback(hObject, eventdata, handles)
% hObject    handle to editSkew (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSkew as text
%        str2double(get(hObject,'String')) returns contents of editSkew as a double
paramChangedNote(handles);
checkScalarOrVector(hObject, 1, 16);


% --- Executes during object creation, after setting all properties.
function editSkew_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSkew (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editAmpl_Callback(hObject, eventdata, handles)
% hObject    handle to editAmpl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editAmpl as text
%        str2double(get(hObject,'String')) returns contents of editAmpl as a double
paramChangedNote(handles);
checkScalarOrVector(hObject, 1, 16);


% --- Executes during object creation, after setting all properties.
function editAmpl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAmpl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function editOffs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editOffs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuConnectionType.
function popupmenuConnectionType_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuConnectionType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuConnectionType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuConnectionType
connTypes = cellstr(get(handles.popupmenuConnectionType, 'String'));
connType = connTypes{get(handles.popupmenuConnectionType, 'Value')};
set(handles.pushbuttonTestAWG1, 'Background', [.9 .9 .9]);
switch (connType)
    case 'tcpip'
        set(handles.editVisaAddr, 'Visible', 'off');
        set(handles.editIPAddress, 'Visible', 'on');
        set(handles.editPort, 'Visible', 'on');
        set(handles.textVisaAddr, 'String', 'IP Address / Port');
    case 'visa'
        set(handles.editVisaAddr, 'Visible', 'on');
        set(handles.editIPAddress, 'Visible', 'off');
        set(handles.editPort, 'Visible', 'off');
        set(handles.textVisaAddr, 'String', 'VISA Address');
end


% --- Executes during object creation, after setting all properties.
function popupmenuConnectionType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuConnectionType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxSetSkew.
function checkboxSetSkew_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSetSkew (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxSetSkew
val = get(hObject,'Value');
onoff = {'off' 'on'};
set(handles.editSkew, 'Enable', onoff{val+1});
paramChangedNote(handles);


% --- Executes on button press in checkboxSetAmpl.
function checkboxSetAmpl_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSetAmpl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxSetAmpl
set(handles.checkboxSetAmpl, 'Background', get(0,'defaultUicontrolBackgroundColor'));
val = get(handles.checkboxSetAmpl,'Value');
onoff = {'off' 'on'};
set(handles.editAmpl, 'Enable', onoff{val+1});
paramChangedNote(handles);


% --- Executes on button press in checkboxSetAmpType.
function checkboxSetAmpType_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSetAmpType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxSetAmpType
val = get(hObject,'Value');
onoff = {'off' 'on'};
set(handles.popupmenuAmpType, 'Enable', onoff{val+1});
paramChangedNote(handles);


% --- Executes on button press in pushbuttonOK.
function pushbuttonOK_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonOK (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
checkVisaAddr(handles, [], 1);
[arbConfig saConfig] = makeArbConfig(handles);
try
    arbCfgFile = iqarbConfigFilename();
catch
    arbCfgFile = 'arbConfig.mat';
end
try
    save(arbCfgFile, 'arbConfig', 'saConfig');
    notifyIQToolWindows(handles);
    close(handles.output);
catch
    msgbox(sprintf('Can''t write "%s". Please make sure the file is writeable.', arbCfgFile));
end


% --- Executes on selection change in popupmenuAmpType.
function popupmenuAmpType_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuAmpType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuAmpType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuAmpType
ampTypes = cellstr(get(handles.popupmenuAmpType, 'String'));
ampType = ampTypes{get(handles.popupmenuAmpType, 'Value')};
arbModels = cellstr(get(handles.popupmenuModel, 'String'));
arbModel = arbModels(get(handles.popupmenuModel, 'Value'));
if (contains(arbModel, 'M8199') && contains(ampType, 'DAC'))
    set(handles.popupmenuAmpType, 'Value', 2);
end
paramChangedNote(handles);


% --- Executes during object creation, after setting all properties.
function popupmenuAmpType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuAmpType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function [arbConfig, saConfig] = makeArbConfig(handles)
% retrieve all the field values
clear arbConfig;
arbIdx = get(handles.popupmenuModel, 'Value');
arbModelIdx = handles.arbModelPtrs{arbIdx};
arbModeIdx = get(handles.popupmenuMode, 'Value');
arbModels = handles.modelInfo(:,1);
arbModel = arbModels{arbModelIdx(arbModeIdx)};
arbConfig.model = arbModel;
connTypes = cellstr(get(handles.popupmenuConnectionType, 'String'));
connType = connTypes{get(handles.popupmenuConnectionType, 'Value')};
arbConfig.connectionType = connType;
arbConfig.visaAddr = strtrim(get(handles.editVisaAddr, 'String'));
arbConfig.ip_address = get(handles.editIPAddress, 'String');
arbConfig.port = iqparse(get(handles.editPort, 'String'), 'scalar');
arbConfig.LOIPAddr = strtrim(get(handles.editLOIPAddr, 'String'));
arbConfig.SD1ModuleIndex = iqparse(get(handles.editSD1ModuleIndex, 'String'), 'scalar');
arbConfig.M8070ModuleID = strtrim(get(handles.editM8070ModuleID, 'String'));
arbConfig.defaultFc = iqparse(get(handles.editDefaultFc, 'String'), 'scalar');
arbConfig.tooltips = get(handles.checkboxTooltips, 'Value');
arbConfig.DACRange = iqparse(get(handles.editDACRange, 'String'), 'scalar') / 100;
arbConfig.amplScale = iqparse(get(handles.editAmplScale, 'String'), 'scalar');
amplScaleList = cellstr(get(handles.popupmenuAmplScale, 'String'));
amplScaleMode = amplScaleList{get(handles.popupmenuAmplScale, 'Value')};
arbConfig.amplScaleMode = amplScaleMode;
filterSettingsList = cellstr(get(handles.popupmenuFilterSettings, 'String'));
filterSettings = filterSettingsList{get(handles.popupmenuFilterSettings, 'Value')};
arbConfig.filterSettings = filterSettings;
if (get(handles.checkboxSetCarrierFreq, 'Value'))
    arbConfig.carrierFrequency = iqparse(get(handles.editCarrierFreq, 'String'), 'scalar');
end
if (get(handles.checkboxSetSkew, 'Value'))
    try
        arbConfig.skew = iqparse(get(handles.editSkew, 'String'), 'vector');
    catch
    end
end
if (get(handles.checkboxUserSampleRate, 'Value'))
    try
        arbConfig.userSamplerate = iqparse(get(handles.editUserSampleRate, 'String'), 'scalar');
    catch
    end
end
if (get(handles.checkboxSetGainCorr, 'Value'))
    arbConfig.gainCorrection = iqparse(get(handles.editGainCorr, 'String'), 'scalar');
end
trigList = get(handles.popupmenuTrigger, 'String');
trigVal = trigList{get(handles.popupmenuTrigger, 'Value')};
arbConfig.triggerMode = trigVal;
if (get(handles.checkboxSetAmpl, 'Value'))
    try
        arbConfig.amplitude = iqparse(get(handles.editAmpl, 'String'), 'vector');
    catch
    end
end
if (get(handles.checkboxSetOffs, 'Value'))
    try
        arbConfig.offset = iqparse(get(handles.editOffs, 'String'), 'vector');
    catch
    end
end
if (get(handles.checkboxSetAmpType, 'Value'))
    ampTypes = cellstr(get(handles.popupmenuAmpType, 'String'));
    ampType = ampTypes{get(handles.popupmenuAmpType, 'Value')};
    arbConfig.ampType = ampType;
end
outputTypes = cellstr(get(handles.popupmenuOutputType, 'String'));
arbConfig.outputType = outputTypes{get(handles.popupmenuOutputType, 'Value')};
if (get(handles.checkboxRST, 'Value'))
    arbConfig.do_rst = true;
end
clkSourceList = {'Unchanged', 'IntRef', 'AxieRef', 'ExtRef', 'ExtClk'};
clkSourceIdx = get(handles.popupmenuClockSource, 'Value');
arbConfig.clockSource = clkSourceList{clkSourceIdx};
arbConfig.clockFreq = iqparse(get(handles.editClockFreq, 'String'), 'scalar');
arbConfig.peaking = iqparse(get(handles.editPeaking, 'String'), 'vector');
arbConfig.interleaving = get(handles.checkboxInterleaving, 'Value');
opts = cellstr(get(handles.popupmenuSampleMarker, 'String'));
arbConfig.sampleMarker = opts{get(handles.popupmenuSampleMarker, 'Value')};
switch (get(handles.popupmenuAWGCount, 'Value'))
    case 2
        arbConfig.visaAddr2 = strtrim(get(handles.editVisaAddr2, 'String'));
        arbConfig.M8070ModuleID2 = strtrim(get(handles.editM8070ModuleID2, 'String'));
    case 3
        arbConfig.visaAddr2 = strtrim(get(handles.editVisaAddr2, 'String'));
        arbConfig.visaAddr3 = strtrim(get(handles.editVisaAddr3, 'String'));
        arbConfig.M8070ModuleID2 = strtrim(get(handles.editM8070ModuleID2, 'String'));
        arbConfig.M8070ModuleID3 = strtrim(get(handles.editM8070ModuleID3, 'String'));
    case 4
        arbConfig.visaAddr2 = strtrim(get(handles.editVisaAddr2, 'String'));
        arbConfig.visaAddr3 = strtrim(get(handles.editVisaAddr3, 'String'));
        arbConfig.visaAddr4 = strtrim(get(handles.editVisaAddr4, 'String'));
        arbConfig.M8070ModuleID2 = strtrim(get(handles.editM8070ModuleID2, 'String'));
        arbConfig.M8070ModuleID3 = strtrim(get(handles.editM8070ModuleID3, 'String'));
        arbConfig.M8070ModuleID4 = strtrim(get(handles.editM8070ModuleID4, 'String'));
end
arbConfig.useM8192A = get(handles.checkboxVisaAddrM8192A, 'Value');
arbConfig.visaAddrM8192A = strtrim(get(handles.editVisaAddrM8192A, 'String'));
arbConfig.isScopeConnected = get(handles.checkboxVisaAddrScope, 'Value');
arbConfig.visaAddrScope = strtrim(get(handles.editVisaAddrScope, 'String'));
arbConfig.isVSAConnected = get(handles.checkboxRemoteVSA, 'Value');
arbConfig.visaAddrVSA = strtrim(get(handles.editVisaAddrVSA, 'String'));
arbConfig.isDCAConnected = get(handles.checkboxDCA, 'Value');
arbConfig.visaAddrDCA = strtrim(get(handles.editVisaAddrDCA, 'String'));
arbConfig.isPSGConnected = get(handles.checkboxPSG, 'Value');
arbConfig.visaAddrPSG = strtrim(get(handles.editVisaAddrPSG, 'String'));
arbConfig.visaAddrPowerSensor = strtrim(get(handles.editVisaAddrPowerSensor, 'String'));
arbConfig.powerSensorAverages = strtrim(get(handles.editPowerSensorAverages, 'String'));
arbConfig.isPowerSensorConnected = get(handles.checkboxPowerSensor, 'Value');
arbConfig.isRecorderConnected = get(handles.checkboxRecorderConnected, 'Value');
arbConfig.recorderAddr = strtrim(get(handles.editRecorderAddr, 'String'));
arbConfig.recorderPCIAddr = strtrim(get(handles.editRecorderPCIAddr, 'String'));
arbConfig.recorderPorts = iqparse(get(handles.editRecorderPorts, 'String'), 'vector');
recorderConnectionTypeList = get(handles.popupmenuRecorderConnectionType, 'String');
arbConfig.recorderConnectionType = recorderConnectionTypeList{get(handles.popupmenuRecorderConnectionType, 'Value')};
arbConfig.timeout = iqparse(get(handles.editTimeout, 'String'), 'vector');
% spectrum analyzer connections
clear saConfig;
saConfig.connected = get(handles.checkboxSAattached, 'Value');
saConfig.connectionType = 'visa';
saConfig.visaAddr = get(handles.editVisaAddrSA, 'String');


function notifyIQToolWindows(handles)
% Notify all open iqtool utilities that arbConfig has changed 
% Figure windows are recognized by their "iqtool" tag
try
    TempHide = get(0, 'ShowHiddenHandles');
    set(0, 'ShowHiddenHandles', 'on');
    figs = findobj(0, 'Type', 'figure', 'Tag', 'iqtool');
    set(0, 'ShowHiddenHandles', TempHide);
    for i = 1:length(figs)
        fig = figs(i);
        [path file ext] = fileparts(get(fig, 'Filename'));
        handles = guihandles(fig);
        feval(file, 'checkfields', fig, 'red', handles);
    end
catch ex
    errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
end


function editVisaAddr_Callback(hObject, eventdata, handles)
% hObject    handle to editVisaAddr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVisaAddr as text
%        str2double(get(hObject,'String')) returns contents of editVisaAddr as a double
checkVisaAddr(handles, hObject, 1);


% --- Executes during object creation, after setting all properties.
function editVisaAddr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVisaAddr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in checkboxSAattached.
function checkboxSAattached_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSAattached (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkboxSAattached
saConnected = get(handles.checkboxSAattached, 'Value');
if (~saConnected)
    set(handles.editVisaAddrSA, 'Enable', 'off');
    set(handles.pushbuttonTestSA, 'Enable', 'off');
    set(handles.pushbuttonTestSA, 'Background', [.9 .9 .9]);
else
    set(handles.editVisaAddrSA, 'Enable', 'on');
    set(handles.pushbuttonTestSA, 'Enable', 'on');
end


function editVisaAddrSA_Callback(hObject, eventdata, handles)
% hObject    handle to editVisaAddrSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVisaAddrSA as text
%        str2double(get(hObject,'String')) returns contents of editVisaAddrSA as a double
checkVisaAddr(handles, hObject, 0);


% --- Executes during object creation, after setting all properties.
function editVisaAddrSA_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVisaAddrSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuModel.
function popupmenuModel_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuModel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuModel contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuModel
set(handles.popupmenuModel, 'Background', 'white');
arbModelIdx = get(handles.popupmenuModel, 'Value');
arbModelNames = get(handles.popupmenuModel, 'String');
arbModelName = arbModelNames{arbModelIdx};
modes = handles.modelInfo(handles.arbModelPtrs{arbModelIdx}, 2);
set(handles.popupmenuMode, 'Value', 1);
set(handles.popupmenuMode, 'String', modes);
if (isempty(modes{1})|| strcmp(arbModelName, 'M8199B'))
    set(handles.popupmenuMode, 'Enable', 'off');
else
    set(handles.popupmenuMode, 'Enable', 'on');
end
modelChange_Callback(hObject, 'popup', handles);

function modelChange_Callback(hObject, reason, handles)
global driverHandle;
arbIdx = get(handles.popupmenuModel, 'Value');
arbModelIdxList = handles.arbModelPtrs{arbIdx};      % index list of all modes for a given model
arbModeIdx = get(handles.popupmenuMode, 'Value');
arbModels = handles.modelInfo(:,1);                  % list of all models
arbModel = arbModels{arbModelIdxList(arbModeIdx)};   % the selected model
guiFlagList = handles.modelInfo(:,4);                % list of all GUI flags
guiFlags = guiFlagList{arbModelIdxList(arbModeIdx)}; % GUI flags for the selected model
onoff = {'off' 'on'};
% we don't use global frequency/phase correction any more
%set(handles.checkboxM8195Acorr, 'Visible', 'off');
%set(handles.checkboxM8195Acorr, 'Value', 0);

% deal with M9336A "specialties"
isM9336A = (~isempty(strfind(arbModel, 'M9336A')));
isN8241A = (~isempty(strfind(arbModel, 'N824')));
pos = get(handles.textAmpType, 'Position');
set(handles.textOutputType, 'Position', pos);
pos = get(handles.popupmenuAmpType, 'Position');
set(handles.popupmenuOutputType, 'Position', pos);
set(handles.textAmpType, 'Visible', onoff{2 - (isM9336A || isN8241A)});
set(handles.popupmenuAmpType, 'Visible', onoff{2 - (isM9336A || isN8241A)});
set(handles.checkboxSetAmpType, 'Visible', onoff{2 - (isM9336A || isN8241A)});
set(handles.textOutputType, 'Visible', onoff{1 + (isM9336A || isN8241A)});
set(handles.popupmenuOutputType, 'Visible', onoff{1 + (isM9336A || isN8241A)});
if (isM9336A)
    set(handles.checkboxSetAmpl, 'Value', 1);
    set(handles.checkboxSetOffs, 'Value', 1);
end
% show filter settings for N8241A
set(handles.textFilterSettings, 'Visible', onoff{1 + isN8241A});
set(handles.popupmenuFilterSettings, 'Visible', onoff{1 + isN8241A});
% show editLOIPAddr 
if (~isempty(find(strcmp(guiFlags, 'LOIPaddr'), 1)))
    set(handles.textLOIPAddr, 'Visible', 'on');
    set(handles.editLOIPAddr, 'Visible', 'on');
else
    set(handles.textLOIPAddr, 'Visible', 'off');
    set(handles.editLOIPAddr, 'Visible', 'off');
end
editLOIPAddr_Callback([], [], handles);
% show peaking only for M8196A/94A
if (~isempty(find(strcmp(guiFlags, 'peaking'),1)))
    set(handles.textPeaking, 'Visible', 'on');
    set(handles.editPeaking, 'Visible', 'on');
else
    set(handles.textPeaking, 'Visible', 'off');
    set(handles.editPeaking, 'Visible', 'off');
end
% show M8190A DUC controls only when they are relevant
showDUC = ~isempty(find(strcmp(guiFlags, 'DUC'),1));
set(handles.textAmplScale, 'Visible', onoff{1 + showDUC});
set(handles.popupmenuAmplScale, 'Visible', onoff{1 + showDUC});
set(handles.editAmplScale, 'Visible', onoff{1 + showDUC});
set(handles.textCarrierFreq, 'Visible', onoff{1 + showDUC});
set(handles.editCarrierFreq, 'Visible', onoff{1 + showDUC});
set(handles.checkboxSetCarrierFreq, 'Visible', onoff{1 + showDUC});
% fields that are only available for M8190A DUC mode
if (showDUC)
    set(handles.textCarrierFreq, 'Enable', 'on');
    set(handles.checkboxSetCarrierFreq, 'Enable', 'on');
    checkboxSetCarrierFreq_Callback(hObject, 0, handles);
else
    set(handles.textCarrierFreq, 'Enable', 'off');
    set(handles.editCarrierFreq, 'Enable', 'off');
    set(handles.checkboxSetCarrierFreq, 'Enable', 'off');
end
if (~isempty(strfind(arbModel, 'M320')))
    set(handles.editVisaAddr, 'Enable', 'off');
    set(handles.editIPAddress, 'Enable', 'off');
    set(handles.editPort, 'Enable', 'off');
    set(handles.popupmenuConnectionType, 'Enable', 'off');
    set(handles.editSD1ModuleIndex, 'Visible', 'on');
    set(handles.textSD1ModuleIndex, 'Visible', 'on');
    if (~get(handles.checkboxSetAmpl, 'Value'))
        if (~strcmp(reason, 'init'))
            warndlg('When you select the M32xx AWG, you must check the "Set Amplitude" checkbox and set an amplitude value. Otherwise no signal will be generated.');
        end
        set(handles.checkboxSetAmpl, 'Background', 'red');
    end
else
    set(handles.editVisaAddr, 'Enable', 'on');
    set(handles.editIPAddress, 'Enable', 'on');
    set(handles.editPort, 'Enable', 'on');
    set(handles.editSD1ModuleIndex, 'Visible', 'off');
    set(handles.textSD1ModuleIndex, 'Visible', 'off');
    set(handles.popupmenuConnectionType, 'Enable', 'on');
    popupmenuConnectionType_Callback(hObject, 0, handles);
end
if (~isempty(find(strcmp(guiFlags, 'moduleID'),1)))
    set(handles.textM8070ModuleID, 'Visible', 'on');
    set(handles.editM8070ModuleID, 'Visible', 'on');
    set(handles.textM8070ModuleID2, 'Visible', 'on');
    set(handles.editM8070ModuleID2, 'Visible', 'on');
    set(handles.textM8070ModuleID3, 'Visible', 'on');
    set(handles.editM8070ModuleID3, 'Visible', 'on');
    set(handles.textM8070ModuleID4, 'Visible', 'on');
    set(handles.editM8070ModuleID4, 'Visible', 'on');
    set(handles.textVisaAddr2, 'Visible', 'off');
    set(handles.editVisaAddr2, 'Visible', 'off');
    set(handles.textVisaAddr3, 'Visible', 'off');
    set(handles.editVisaAddr3, 'Visible', 'off');
    set(handles.textVisaAddr4, 'Visible', 'off');
    set(handles.editVisaAddr4, 'Visible', 'off');
else
    set(handles.textM8070ModuleID, 'Visible', 'off');
    set(handles.editM8070ModuleID, 'Visible', 'off');
    set(handles.textM8070ModuleID2, 'Visible', 'off');
    set(handles.editM8070ModuleID2, 'Visible', 'off');
    set(handles.textM8070ModuleID3, 'Visible', 'off');
    set(handles.editM8070ModuleID3, 'Visible', 'off');
    set(handles.textM8070ModuleID4, 'Visible', 'off');
    set(handles.editM8070ModuleID4, 'Visible', 'off');
    set(handles.textVisaAddr2, 'Visible', 'on');
    set(handles.editVisaAddr2, 'Visible', 'on');
    set(handles.textVisaAddr3, 'Visible', 'on');
    set(handles.editVisaAddr3, 'Visible', 'on');
    set(handles.textVisaAddr4, 'Visible', 'on');
    set(handles.editVisaAddr4, 'Visible', 'on');
end
if (~isempty(find(strcmp(guiFlags, 'trigger'),1)))
    set(handles.popupmenuTrigger, 'Enable', 'on');
    set(handles.textTrigger, 'Enable', 'on');
else
    set(handles.popupmenuTrigger, 'Enable', 'off');
    set(handles.textTrigger, 'Enable', 'off');
end
if (~isempty(find(strcmp(guiFlags, 'clkSource'),1)))
    set(handles.popupmenuClockSource, 'Enable', 'on');
    set(handles.textClockSource, 'Enable', 'on');
else
    set(handles.popupmenuClockSource, 'Enable', 'off');
    set(handles.textClockSource, 'Enable', 'off');
end
% interleaving is implemented for M8190A, 95A, 96A, 94A, 98A
if (~isempty(find(strcmp(guiFlags, 'ilv'),1)))
    set(handles.checkboxInterleaving, 'Enable', 'on');
    set(handles.textInterleaving, 'Enable', 'on');
else
    set(handles.checkboxInterleaving, 'Enable', 'off');
    set(handles.textInterleaving, 'Enable', 'off');
end
% amplifier type only for M8190A, 81180A/B and N824xA
if (~isempty(find(strcmp(guiFlags, 'ampType'),1)))
    set(handles.checkboxSetAmpType, 'Enable', 'on');
    if (get(handles.checkboxSetAmpType, 'Value'))
        set(handles.popupmenuAmpType, 'Enable', 'on');
        set(handles.textAmpType, 'Enable', 'on');
    else
        set(handles.popupmenuAmpType, 'Enable', 'off');
        set(handles.textAmpType, 'Enable', 'off');
    end
else
    set(handles.checkboxSetAmpType, 'Enable', 'off');
    set(handles.popupmenuAmpType, 'Enable', 'off');
    set(handles.textAmpType, 'Enable', 'off');
end
% amplitude/offset for M8196A, M8194A, M8195A, M8190A, 81180A, 81150A, 81160A, 33xxx
if (~isempty(find(strcmp(guiFlags, 'amplitude'),1)))
    set(handles.checkboxSetAmpl, 'Enable', 'on');
    set(handles.textAmpl, 'Enable', 'on');
    val = get(handles.checkboxSetAmpl,'Value');
    set(handles.editAmpl, 'Enable', onoff{val+1});
else
    set(handles.checkboxSetAmpl, 'Enable', 'off');
    set(handles.textAmpl, 'Enable', 'off');
end
if (~isempty(find(strcmp(guiFlags, 'offset'),1)))
    set(handles.checkboxSetOffs, 'Enable', 'on');
    set(handles.textOffset, 'Enable', 'on');
    val = get(handles.checkboxSetOffs,'Value');
    set(handles.editOffs, 'Enable', onoff{val+1});
else
    set(handles.checkboxSetOffs, 'Enable', 'off');
    set(handles.textOffset, 'Enable', 'off');
end
popupmenuAmplScale_Callback([], [], handles);
% hardware skew is available for M8190A, M8121A, M8195A, M8199A, 811xx
if (~isempty(find(strcmp(guiFlags, 'skew'),1)) || ~isempty(find(strcmp(guiFlags, 'sw_skew'),1)))
    set(handles.checkboxSetSkew, 'Enable', 'on');
    set(handles.checkboxSetGainCorr, 'Enable', 'on');
    set(handles.textSkew, 'Enable', 'on');
    set(handles.textGainCorr, 'Enable', 'on');
else
    set(handles.checkboxSetSkew, 'Enable', 'off');
    set(handles.checkboxSetGainCorr, 'Enable', 'off');
    set(handles.checkboxSetSkew, 'Value', 0);
    set(handles.checkboxSetGainCorr, 'Value', 0);
    set(handles.textSkew, 'Enable', 'off');
    set(handles.textGainCorr, 'Enable', 'off');
end
if (~isempty(find(strcmp(guiFlags, 'sampleMarker'),1)))
    set(handles.textSampleMarker, 'Visible', 'on');
    set(handles.popupmenuSampleMarker, 'Visible', 'on');
else
    set(handles.textSampleMarker, 'Visible', 'off');
    set(handles.popupmenuSampleMarker, 'Visible', 'off');
end
% Multi-AWG Setup and Sync module are only available with M8190A, M8121A, M8195A, M8194A, M8199A
if (~isempty(find(strcmp(guiFlags, 'multimodule'),1)))
    set(handles.popupmenuAWGCount, 'Value', 1);
    popupmenuAWGCount_Callback([], [], handles);
end
if (~isempty(find(strcmp(guiFlags, 'psg'),1)))
    set(handles.uipanelPSG, 'Visible', 'on');
    set(handles.uipanelRecorder, 'Visible', 'off');
else
    set(handles.uipanelPSG, 'Visible', 'off');
    set(handles.uipanelRecorder, 'Visible', 'on');
end
checkVisaAddr(handles, [], 1);
checkboxSAattached_Callback([], [], handles);
checkUserSampleRate(handles);
if (~isempty(strfind(arbModel, 'M9336A')) || ~isempty(strfind(arbModel, 'M320')) || ~isempty(strfind(arbModel, 'M5300x')))
    if (~isempty(driverHandle) && isvalid(driverHandle))
        set(handles.pushbuttonTestAWG1, 'Background', 'green');
        set(handles.pushbuttonTestAWG1, 'String', 'Disconnect');
    else
        set(handles.pushbuttonTestAWG1, 'String', 'Connect');
    end
else
    set(handles.pushbuttonTestAWG1, 'String', 'Test connection');
end
if (~isempty(strfind(arbModel, 'M5300x')))
    set(handles.popupmenuTrigger, 'String', {'Auto';'SWHVI';'External';'SWHVIPerCycle';'ExternalPerCycle'});
else
    set(handles.popupmenuTrigger, 'String', {'Continuous';'Triggered';'Gated';'Leave Unchanged'});
end

% Set sample marker frequency properly for M8199A/B
if contains(arbModel, 'M8199B')
    rlist = get(handles.popupmenuSampleMarker, 'String');
    r = 'Sample rate / 16';
    p = find(strcmp(r, rlist));
    if (~isempty(p))
        set(handles.popupmenuSampleMarker, 'Value', p);
        set(handles.popupmenuSampleMarker, 'Background', 'yellow');
    end
    drawnow();
    pause(0.5);
    set(handles.editUserSampleRate, 'Background', 'white');
    set(handles.popupmenuSampleMarker, 'Background', 'white');
end

if contains(arbModel, 'M8199A')
    val = get(handles.popupmenuMode, 'Value');
    if (get(handles.checkboxUserSampleRate, 'Value'))
        fs = str2double(get(handles.editUserSampleRate, 'String'));
        if (~isnan(fs))
            if (val == 2 && fs <= 130e9)
                fs = 2 * fs;
            elseif (val == 1 && fs > 130e9)
                fs = fs / 2;
            end
            set(handles.editUserSampleRate, 'String', iqengprintf(fs));
            set(handles.editUserSampleRate, 'Background', 'yellow');
        end
    end
    rlist = get(handles.popupmenuSampleMarker, 'String');
    r = rlist{get(handles.popupmenuSampleMarker, 'Value')};
    if (val == 2 && strcmpi(r, 'Sample rate / 8'))
        r = 'Sample rate / 16';
    elseif (val == 1 && strcmp(r, 'Sample rate / 16'))
        r = 'Sample rate / 8';
    end
    p = find(strcmp(r, rlist));
    if (~isempty(p))
        set(handles.popupmenuSampleMarker, 'Value', p);
        set(handles.popupmenuSampleMarker, 'Background', 'yellow');
    end
    drawnow();
    pause(0.5);
    set(handles.editUserSampleRate, 'Background', 'white');
    set(handles.popupmenuSampleMarker, 'Background', 'white');
end

if contains(arbModel, 'M8135A')
    set(handles.popupmenuConnectionType, 'Value', 1);
    set(handles.editVisaAddr, 'Visible', 'off');
    set(handles.editIPAddress, 'Visible', 'on');
    set(handles.editPort, 'Visible', 'on');
    set(handles.textVisaAddr, 'String', 'IP Address / Port');
end


% --- Executes during object creation, after setting all properties.
function popupmenuModel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuModel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editOffs_Callback(hObject, eventdata, handles)
% hObject    handle to editOffs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editOffs as text
%        str2double(get(hObject,'String')) returns contents of editOffs as a double
paramChangedNote(handles);
checkScalarOrVector(hObject, 1, 16);



function checkScalarOrVector(hObject, minLen, maxLen)
if (~exist('minLen', 'var'))
    minLen = 1;
end
if (~exist('maxLen', 'var'))
    maxLen = 0;
end
value = [];
try
    value = iqparse(get(hObject, 'String'), 'vector');
catch ex
    msgbox(ex.message);
end
if (isvector(value) && ...
       (minLen <= 0 || length(value) >= minLen) && ...
       (maxLen <= 0 || length(value) <= maxLen))
    set(hObject, 'BackgroundColor', 'white');
else
    set(hObject, 'BackgroundColor', 'red');
end



% --- Executes on button press in checkboxSetOffs.
function checkboxSetOffs_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSetOffs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = get(handles.checkboxSetOffs,'Value');
onoff = {'off' 'on'};
set(handles.editOffs, 'Enable', onoff{val+1});
paramChangedNote(handles);


% --- Executes on button press in checkboxRST.
function checkboxRST_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxRST (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxRST
paramChangedNote(handles);


function editDefaultFc_Callback(hObject, eventdata, handles)
% hObject    handle to editDefaultFc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDefaultFc as text
%        str2double(get(hObject,'String')) returns contents of editDefaultFc as a double
value = [];
try
    value = iqparse(get(hObject, 'String'), 'vector');
catch ex
    msgbox(ex.message);
end
if (isscalar(value) && value >= 0)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editDefaultFc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDefaultFc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxTooltips.
function checkboxTooltips_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxTooltips (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxTooltips



function editDACRange_Callback(hObject, eventdata, handles)
% hObject    handle to editDACRange (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDACRange as text
%        str2double(get(hObject,'String')) returns contents of editDACRange as a double
value = [];
try
    value = iqparse(get(hObject, 'String'), 'vector');
catch ex
    msgbox(ex.message);
end
if (isscalar(value) && value >= 0)
    if (value > 100)
        set(hObject,'BackgroundColor','yellow');
        warndlg('Sample values will be clipped if DAC range is set to > 100%');
    else
        set(hObject,'BackgroundColor','white');
    end
else
    set(hObject,'BackgroundColor','red');
end
paramChangedNote(handles);


% --- Executes during object creation, after setting all properties.
function editDACRange_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDACRange (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function menuFile_Callback(hObject, eventdata, handles)
% hObject    handle to menuFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menuLoadSettings_Callback(hObject, eventdata, handles)
% hObject    handle to menuLoadSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqloadsettings(handles);
modelChange_Callback(hObject, 'load', handles);


% --------------------------------------------------------------------
function menuSaveSettings_Callback(hObject, eventdata, handles)
% hObject    handle to menuSaveSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqsavesettings(handles);


% --- Executes on button press in checkboxInterleaving.
function checkboxInterleaving_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxInterleaving (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxInterleaving
if (get(hObject,'Value'))
    msgbox({'Please use the GUI or Soft Front Panel of the AWG to adjust' ...
            'channel 2 to be delayed by 1/2 sample period with respect to' ...
            'channel 1. An easy way to check the correct delay is to generate' ...
            'a multitone signal with tones between DC and fs/4, observe the' ...
            'signal on a spectrum analyzer and adjust the channel 2 delay' ...
            'until the images in the second Nyquist band are minimial.'}, 'Note');
end



function editCarrierFreq_Callback(hObject, eventdata, handles)
% hObject    handle to editCarrierFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCarrierFreq as text
%        str2double(get(hObject,'String')) returns contents of editCarrierFreq as a double
paramChangedNote(handles);
try
    carrier = str2double(get(handles.editCarrierFreq, 'String'));
    defaultFc = str2double(get(handles.editDefaultFc, 'String'));
    if (carrier ~= 0 && defaultFc == 0)
        set(handles.editDefaultFc, 'String', iqengprintf(carrier));
    end
catch
end


% --- Executes during object creation, after setting all properties.
function editCarrierFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCarrierFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxSetCarrierFreq.
function checkboxSetCarrierFreq_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSetCarrierFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkboxSetCarrierFreq
val = get(handles.checkboxSetCarrierFreq, 'Value');
onoff = {'off' 'on'};
set(handles.editCarrierFreq, 'Enable', onoff{val+1});
%paramChangedNote(handles);


function paramChangedNote(handles)
% at least one parameter has changed --> notify user that the change will
% only be sent to hardware on the next waveform download
set(handles.textNote, 'Background', 'yellow');


function checkVisaAddr(handles, editHandle, isAWGAddr)
if (isAWGAddr == 1)
    visaAddr = upper(strtrim(get(handles.editVisaAddr, 'String')));
else
    visaAddr = get(editHandle, 'String');
end
connTypes = cellstr(get(handles.popupmenuConnectionType, 'String'));
connType = connTypes{get(handles.popupmenuConnectionType, 'Value')};
arbModels = cellstr(get(handles.popupmenuModel, 'String'));
arbModel = arbModels{get(handles.popupmenuModel, 'Value')};
isOK = 1;
if (~isAWGAddr || (~isempty(strfind(arbModel, 'M81')) && strcmpi(connType, 'visa')))
    if (isempty(regexp(visaAddr, '^TCPIP\d::[-\w.]+::\w+\d+(,\d+)?::(INSTR|SOCKET)$', 'once')))
        isOK = 0;
        warndlg({'VISA address format is incorrect, please double check the spelling.' ...
                'You can find the VISA address of the AWG in the firmware window, ' ...
                'resp. in "Help->About" of the SoftFrontPanel. For Scopes, you can ' ...
                'find it under Utilities->SCPI Preferences'}, 'replace');
    end
end
if (isAWGAddr && ...
    (~isempty(strfind(arbModel, 'M9336A')) || ...
     ~isempty(strfind(arbModel, 'M5300x'))) && ...
    (~strcmpi(connType, 'visa') || ~strncmp(visaAddr, 'PXI', 3)))
    isOK = 0;
    warndlg({'For M9336A and M5300x you have to select a VISA address that starts with PXI...'}, 'replace');
end
if (~isempty(editHandle))
    if (isOK)
        set(editHandle, 'Background', 'white');
    else
        set(editHandle, 'Background', 'red');
    end
end    


% --- Executes on button press in checkboxVisaAddrScope.
function checkboxVisaAddrScope_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxVisaAddrScope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxVisaAddrScope
checkboxVisaAddrScope_update(handles);


function checkboxVisaAddrScope_update(handles)
scopeConnected = get(handles.checkboxVisaAddrScope, 'Value');
if (~scopeConnected)
    set(handles.editVisaAddrScope, 'Enable', 'off');
    set(handles.pushbuttonTestScope, 'Enable', 'off');
    set(handles.pushbuttonTestScope, 'Background', [.9 .9 .9]);
else
    set(handles.editVisaAddrScope, 'Enable', 'on');
    set(handles.pushbuttonTestScope, 'Enable', 'on');
end


function editVisaAddrScope_Callback(hObject, eventdata, handles)
% hObject    handle to editVisaAddrScope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVisaAddrScope as text
%        str2double(get(hObject,'String')) returns contents of editVisaAddrScope as a double
checkVisaAddr(handles, hObject, 0);


% --- Executes during object creation, after setting all properties.
function editVisaAddrScope_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVisaAddrScope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function editVisaAddr2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVisaAddr2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonTestScope.
function pushbuttonTestScope_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTestScope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
scopeCfg.connectionType = 'visa';
scopeCfg.visaAddr = get(handles.editVisaAddrScope, 'String');
if (~isempty(strfind(scopeCfg.visaAddr, 'Enter VISA')))
    errordlg({'Please enter a valid VISA Address for the Scope. Typically something' ...
        'like: TCPIP0::ComputerName::inst0::INSTR.  You can find the correct' ...
        'address on the scope under Utilities -> Remote Connection'});
    return;
end
found = 0;
hMsgBox = msgbox('Trying to connect, please wait...', 'Please wait...', 'replace');
iqreset();
f = iqopen(scopeCfg);
try close(hMsgBox); catch ex; end
if (~isempty(f))
    try
        res = xquery(f, '*IDN?');
        if (~isempty(strfind(res, 'DSO')) || ...
            ~isempty(strfind(res, 'DSA')) || ...
            ~isempty(strfind(res, 'M8131')) || ...
            ~isempty(strfind(res, 'M8296')) || ...
            ~isempty(strfind(res, 'UXR')) || ...
            ~isempty(strfind(res, 'MXR')) || ...
            ~isempty(strfind(res, 'MSO')))
            found = 1;
        else
            errordlg({'Unexpected scope model:' '' res ...
                'Supported models are DSO, DSA, MSO, UXR, MXR, M8131A and M8296A'});
        end
    catch ex
        errordlg({'Error reading scope IDN:' '' ex.message});
    end
    iqclose(f);
end
if (found)
    set(hObject, 'Background', 'green');
else
    set(hObject, 'Background', 'red');
end


% --- Executes on button press in pushbuttonTestAWG2.
function pushbuttonTestAWG2_Callback(hObject, eventdata, handles)
[cfg, ~] = makeArbConfig(handles);
cfg.connectionType = 'visa';
if (strcmp(get(handles.editM8070ModuleID2, 'Visible'), 'on'))
    cfg.visaAddr = strtrim(get(handles.editVisaAddr, 'String'));
    cfg.M8070ModuleID = strtrim(get(handles.editM8070ModuleID2, 'String'));
else
    cfg.visaAddr = strtrim(get(handles.editVisaAddr2, 'String'));
end
testConnection(hObject, cfg);


% --- Executes on button press in pushbuttonTestAWG3.
function pushbuttonTestAWG3_Callback(hObject, eventdata, handles)
[cfg, ~] = makeArbConfig(handles);
cfg.connectionType = 'visa';
if (strcmp(get(handles.editM8070ModuleID3, 'Visible'), 'on'))
    cfg.visaAddr = strtrim(get(handles.editVisaAddr, 'String'));
    cfg.M8070ModuleID = strtrim(get(handles.editM8070ModuleID3, 'String'));
else
    cfg.visaAddr = strtrim(get(handles.editVisaAddr3, 'String'));
end
testConnection(hObject, cfg);


% --- Executes on button press in pushbuttonTestAWG4.
function pushbuttonTestAWG4_Callback(hObject, eventdata, handles)
[cfg, ~] = makeArbConfig(handles);
cfg.connectionType = 'visa';
if (strcmp(get(handles.editM8070ModuleID4, 'Visible'), 'on'))
    cfg.visaAddr = strtrim(get(handles.editVisaAddr, 'String'));
    cfg.M8070ModuleID = strtrim(get(handles.editM8070ModuleID4, 'String'));
else
    cfg.visaAddr = strtrim(get(handles.editVisaAddr4, 'String'));
end
testConnection(hObject, cfg);



% --- Executes on button press in pushbuttonTestAWG1.
function pushbuttonTestAWG1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTestAWG1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[cfg, ~] = makeArbConfig(handles);
testConnection(hObject, cfg);



function result = testConnection(hObject, arbConfig)
global driverHandle;
model = arbConfig.model;
checkmodel = [];
checkfeature = [];
checkproduct = [];
if (~isempty(strfind(model, 'M8190')))
    checkmodel = 'M8190A';
elseif (~isempty(strfind(model, 'M8121')))
    checkmodel = 'M8121A';
elseif (~isempty(strfind(model, 'M8195A')))
    checkmodel = 'M8195A';
elseif (~isempty(strfind(model, 'M8196A')) || ~isempty(strfind(model, 'MUXDAC')))
    checkmodel = 'M8196A';
elseif (~isempty(strfind(model, 'M8198A')))
    checkmodel = 'M8070B';
    checkproduct = 'M8198A';
elseif (~isempty(strfind(model, 'M8199B')))
    checkmodel = 'M8070B';
    checkproduct = 'M8199B';
elseif (~isempty(strfind(model, 'M8199B_NONILV')))
    checkmodel = 'M8070B';
    checkproduct = 'M8199B';
elseif (~isempty(strfind(model, 'M8199A')))
    checkmodel = 'M8070B';
    checkproduct = 'M8199A';
elseif (~isempty(strfind(model, 'M8199A_ILV')))
    checkmodel = 'M8070B';
    checkproduct = 'M8199A';
elseif (~isempty(strfind(model, 'M8194A')))
    checkmodel = 'M8194A';
elseif (~isempty(strfind(model, '81180')))
    checkmodel = '81180';
elseif (~isempty(strfind(model, '81150')))
    checkmodel = '81150';
elseif (~isempty(strfind(model, '81160')))
    checkmodel = '81160';
elseif (~isempty(strfind(model, 'N5182A')))
    checkmodel = 'N5182A';
elseif (~isempty(strfind(model, 'N5182B')))
    checkmodel = 'N5182B';
elseif (~isempty(strfind(model, 'N5172B')))
    checkmodel = 'N5172B';
elseif (~isempty(strfind(model, 'N5166B')))
    checkmodel = 'N5166B';
elseif (~isempty(strfind(model, 'E4438C')))
    checkmodel = 'E4438C';
elseif (~isempty(strfind(model, 'E8267D')))
    checkmodel = 'E8267D';
elseif (~isempty(strfind(model, '3351')))
    checkmodel = '3351';
elseif (~isempty(strfind(model, '3352')))
    checkmodel = '3352';
elseif (~isempty(strfind(model, '3361')))
    checkmodel = '3361';
elseif (~isempty(strfind(model, '3362')))
    checkmodel = '3362';
elseif (~isempty(strfind(model, 'M9383A')))
    checkmodel = 'M9383A';
elseif (~isempty(strfind(model, 'S91xxA')))
    checkmodel = 'M9415A';
elseif (~isempty(strfind(model, 'M9415A')))
    checkmodel = 'M9415A'; 
elseif (~isempty(strfind(model, 'M9410A')))
    checkmodel = 'M9410A';
elseif (~isempty(strfind(model, 'M9383B')))
    checkmodel = 'M9383B';
elseif (~isempty(strfind(model, 'M9384B')))
    checkmodel = 'M9384B';
elseif (~isempty(strfind(model, 'N824')))
    checkmodel = 'N824';
elseif (~isempty(strfind(model, 'M9336A')) || ~isempty(strfind(model, 'M320')) || ~isempty(strfind(model, 'M5300x')) || ~isempty(strfind(model, 'M5301x')))
    if (~isempty(driverHandle) && isvalid(driverHandle))
        iqdownload([], -1, 'arbConfig', arbConfig); % close the driver
        set(hObject, 'Background', '#e0e0e0');
        set(hObject, 'String', 'Connect');
    else
        driverHandle = iqdownload([], 0, 'arbConfig', arbConfig); % open the driver
        try close(hMsgbox); catch; end
        if (~isempty(driverHandle))
            set(hObject, 'Background', 'green');
            set(hObject, 'String', 'Disconnect');
            result = 1;
        else
            set(hObject, 'Background', 'red');
            result = 0;
        end
    end
    return;
elseif (~isempty(strfind(model, 'M9484C')))
    checkmodel = 'M9484C';
elseif (~isempty(strfind(model, 'M8135A')))
    arbConfigTmp = loadArbConfig(arbConfig);
    hMsgBox = msgbox('Trying to connect, please wait...', 'Please wait...', 'replace');
    try
        iqdownload_M8135A(arbConfigTmp, 0, [], 0, 0, 0, 0, 0, 0, 0, 0, 0); % iqdownload will test connection
        set(hObject, 'Background', 'green');
        result = 1;
    catch
        set(hObject, 'Background', 'red');
        result = 0; % any error here indicates connection or compatibility error
    end
    try close(hMsgBox); catch ex; end
    return;
else
    msgbox({'The "Test Connection" function is not yet implemented for this model.' ...
            'Please download a waveform and observe error messages'});
    result = 1;
    return;
end
if (~isempty(strfind(model, 'DUC')))
    checkfeature = 'DUC';
end
hMsgBox = msgbox('Trying to connect, please wait...', 'Please wait...', 'replace');
iqreset();
if (iqoptcheck(arbConfig, checkproduct, checkfeature, checkmodel))
    set(hObject, 'Background', 'green');
    result = 1;
else
    set(hObject, 'Background', 'red');
    result = 0;
end
try close(hMsgBox); catch ex; end


% --- Executes on button press in pushbuttonTestSA.
function pushbuttonTestSA_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTestSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[dummy saCfg] = makeArbConfig(handles);
if (~isempty(strfind(saCfg.visaAddr, 'Enter VISA')))
    errordlg({'Please enter a valid VISA Address for the Spectrum Analyzer. Typically' ...
        'something like: TCPIP0::IP-Address::inst0::INSTR.  You can find the correct' ...
        'IP address in the control panel of the spectrum analyzer'});
    return;
end
hMsgBox = msgbox('Trying to connect, please wait...', 'Please wait...', 'replace');
f = iqopen(saCfg);
try close(hMsgBox); catch ex; end
found = 0;
if (~isempty(f))
    res = xquery(f, '*IDN?');
    if (~isempty(strfind(res, 'E444')) || ...
        ~isempty(strfind(res, 'N9000')) || ...
        ~isempty(strfind(res, 'N9010')) || ...
        ~isempty(strfind(res, 'N902')) || ...
        ~isempty(strfind(res, 'N903')) || ...
        ~isempty(strfind(res, 'N904')))
        found = 1;
    else
        errordlg({'Unexpected spectrum analyzer type:' '' res ...
            'Supported models are PSA (E444xA), MXA (N902xA) and PXA (N903xA)'});
    end
    iqclose(f);
end
if (found)
    set(hObject, 'Background', 'green');
else
    set(hObject, 'Background', 'red');
end


% --- Executes on button press in pushbuttonSwapAWG2.
function pushbuttonSwapAWG2_Callback(hObject, eventdata, handles)
swapWithPrimary(handles, handles.editVisaAddr2, handles.editM8070ModuleID2);


% --- Executes on button press in pushbuttonSwapAWG3.
function pushbuttonSwapAWG3_Callback(hObject, eventdata, handles)
swapWithPrimary(handles, handles.editVisaAddr3, handles.editM8070ModuleID3);


% --- Executes on button press in pushbuttonSwapAWG4.
function pushbuttonSwapAWG4_Callback(hObject, eventdata, handles)
swapWithPrimary(handles, handles.editVisaAddr4, handles.editM8070ModuleID4);


function swapWithPrimary(handles, editVisaHandle, editModuleHandle)
awg1 = get(handles.editVisaAddr, 'String');
awg2 = get(editVisaHandle, 'String');
mod1 = get(handles.editM8070ModuleID, 'String');
mod2 = get(editModuleHandle, 'String');
if (strcmp(get(editModuleHandle, 'Visible'), 'on'))
    set(handles.editM8070ModuleID, 'String', strtrim(mod2));
    set(editModuleHandle, 'String', strtrim(mod1));
else
    set(editVisaHandle, 'String', awg1);
    set(handles.editVisaAddr, 'String', awg2);
end
set(handles.popupmenuConnectionType, 'Value', 2);
popupmenuConnectionType_Callback([], [], handles);
checkModuleIDs(handles);


% --- Executes on button press in pushbuttonTestM8192A.
function pushbuttonTestM8192A_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTestM8192A (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
M8192ACfg.connectionType = 'visa';
M8192ACfg.visaAddr = strtrim(get(handles.editVisaAddrM8192A, 'String'));
found = 0;
hMsgBox = msgbox('Trying to connect, please wait...', 'Please wait...', 'replace');
f = iqopen(M8192ACfg);
try close(hMsgBox); catch ex; end
if (~isempty(f))
    try
        res = xquery(f, '*IDN?');
        if (~isempty(strfind(res, 'M8192A')) || ~isempty(strfind(res, 'M8197A')))
            found = 1;
        else
            errordlg({'Unexpected IDN response:' '' res ...
                'Please specify the VISA address of a sync module' ...
                'and make sure the corresponding firmware is running'});
        end
    catch ex
        errordlg({'Error reading IDN:' '' ex.message});
    end
    iqclose(f);
end
if (found)
    set(hObject, 'Background', 'green');
else
    set(hObject, 'Background', 'red');
end


function editVisaAddrM8192A_Callback(hObject, eventdata, handles)
% hObject    handle to editVisaAddrM8192A (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVisaAddrM8192A as text
%        str2double(get(hObject,'String')) returns contents of editVisaAddrM8192A as a double


% --- Executes during object creation, after setting all properties.
function editVisaAddrM8192A_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVisaAddrM8192A (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxVisaAddrM8192A.
function checkboxVisaAddrM8192A_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxVisaAddrM8192A (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkboxVisaAddrM8192A
SyncConnected = get(handles.checkboxVisaAddrM8192A, 'Value');
if (SyncConnected)
    set(handles.editVisaAddrM8192A, 'Enable', 'on');
    set(handles.pushbuttonTestM8192A, 'Enable', 'on');
    set(handles.pushbuttonTestM8192A, 'Background', [.9 .9 .9]);
else
    set(handles.editVisaAddrM8192A, 'Enable', 'off');
    set(handles.pushbuttonTestM8192A, 'Enable', 'off');
    set(handles.pushbuttonTestM8192A, 'Background', [.9 .9 .9]);
    answer = questdlg({'Do you want to re-configure the Sync module to let'
        'the indiviudal AWG modules run individually?'}, 'Sync module configuration');
    switch (answer)
        case 'Yes'
            hMsgBox = msgbox('Trying to connect, please wait...', 'Please wait...', 'replace');
            try
                arbConfig = loadArbConfig();
                arbConfig.visaAddr = arbConfig.visaAddrM8192A;
                fsync = iqopen(arbConfig);
                xfprintf(fsync, ':ABOR');
                xfprintf(fsync, ':inst:mmod:conf 1');
                xfprintf(fsync, ':inst:slave:del:all');
                xfprintf(fsync, ':inst:mast ""');
                xquery(fsync, '*opc?');
                iqclose(fsync);
            catch ex
                msgbox(ex.message);
            end
            try close(hMsgBox); catch ex; end
        case 'No'
            % do nothing
        case 'Cancel'
            set(handles.checkboxVisaAddrM8192A, 'Value', 1);
    end
    popupmenuAWGCount_Callback([], [], handles);
end


% --- Executes on selection change in popupmenuTrigger.
function popupmenuTrigger_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuTrigger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuTrigger contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuTrigger
paramChangedNote(handles);


% --- Executes during object creation, after setting all properties.
function popupmenuTrigger_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuTrigger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxSetGainCorr.
function checkboxSetGainCorr_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSetGainCorr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxSetGainCorr
val = get(hObject,'Value');
onoff = {'off' 'on'};
set(handles.editGainCorr, 'Enable', onoff{val+1});
paramChangedNote(handles);



function editGainCorr_Callback(hObject, eventdata, handles)
% hObject    handle to editGainCorr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editGainCorr as text
%        str2double(get(hObject,'String')) returns contents of editGainCorr as a double


% --- Executes during object creation, after setting all properties.
function editGainCorr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editGainCorr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuAmplScale.
function popupmenuAmplScale_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuAmplScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuAmplScale contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuAmplScale
amplScaleList = cellstr(get(handles.popupmenuAmplScale, 'String'));
amplScaleVal = get(handles.popupmenuAmplScale, 'Value');
% !!! as long as it is not implemented - always set to 'Leave Unchanged'
if (amplScaleVal ~= 3)
    set(handles.popupmenuAmplScale, 'Value', 3);
    msgbox({'Setting the Amplitude Scale is not yet implemented in IQTools.' 
           'In the meantime, please use the Soft Front Panel to set it'});
end
amplScaleMode = amplScaleList{amplScaleVal};
arbModels = cellstr(get(handles.popupmenuModel, 'String'));
arbModel = arbModels{get(handles.popupmenuModel, 'Value')};
if (~isempty(strfind(arbModel, 'M8190A_DUC')) || ~isempty(strfind(arbModel, 'M8121A_DUC')))
    set(handles.popupmenuAmplScale, 'Enable', 'on');
    set(handles.textAmplScale, 'Enable', 'on');
    if (strcmp(amplScaleMode, 'User Defined'))
        set(handles.editAmplScale, 'Enable', 'on');
    else
        set(handles.editAmplScale, 'Enable', 'off');
    end
else
    set(handles.popupmenuAmplScale, 'Enable', 'off');
    set(handles.editAmplScale, 'Enable', 'off');
    set(handles.textAmplScale, 'Enable', 'off');
end


% --- Executes during object creation, after setting all properties.
function popupmenuAmplScale_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuAmplScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editAmplScale_Callback(hObject, eventdata, handles)
% hObject    handle to editAmplScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editAmplScale as text
%        str2double(get(hObject,'String')) returns contents of editAmplScale as a double
value = [];
try
    value = iqparse(get(hObject, 'String'), 'vector');
catch ex
    msgbox(ex.message);
end
if (isscalar(value) && isempty(find(value < 2.83)) && isempty(find(value > 1)))
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editAmplScale_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAmplScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxRemoteVSA.
function checkboxRemoteVSA_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxRemoteVSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxRemoteVSA
VSAConnected = get(handles.checkboxRemoteVSA, 'Value');
if (~VSAConnected)
    set(handles.editVisaAddrVSA, 'Enable', 'off');
    set(handles.pushbuttonTestVSA, 'Enable', 'off');
    set(handles.pushbuttonTestVSA, 'Background', [.9 .9 .9]);
else
    set(handles.editVisaAddrVSA, 'Enable', 'on');
    set(handles.pushbuttonTestVSA, 'Enable', 'on');
%    msgbox('Note: Remote VSA access is not completely implemented. Some functions are not yet available. Please continue to use "local" VSA in the meantime');
end



function editVisaAddrVSA_Callback(hObject, eventdata, handles)
% hObject    handle to editVisaAddrVSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVisaAddrVSA as text
%        str2double(get(hObject,'String')) returns contents of editVisaAddrVSA as a double
checkVisaAddr(handles, hObject, 0);


% --- Executes during object creation, after setting all properties.
function editVisaAddrVSA_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVisaAddrVSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonTestVSA.
function pushbuttonTestVSA_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTestVSA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
VSACfg.connectionType = 'visa';
VSACfg.visaAddr = get(handles.editVisaAddrVSA, 'String');
if (~isempty(strfind(VSACfg.visaAddr, 'Enter VISA')))
    errordlg({'Please enter a valid VISA Address for VSA. Typically something' ...
        'like: TCPIP0::ComputerName::5026::SOCKET.  You can find the correct' ...
        'address in the VSA software under Utilities -> SCPI Configuration'});
    return;
end
found = 0;
hMsgBox = msgbox('Trying to connect, please wait...', 'Please wait...', 'replace');
f = iqopen(VSACfg);
try close(hMsgBox); catch ex; end
if (~isempty(f))
    try
        res = xquery(f, '*IDN?');
        if (~isempty(strfind(res, '8960')) || ~isempty(strfind(res, 'N4391')) || ~isempty(strfind(res, 'OMA')))
            found = 1;
        else
            errordlg({'Unexpected reponse from VSA: ' '' res});
        end
    catch ex
        errordlg({'Error reading VSA IDN:' '' ex.message});
    end
    iqclose(f);
end
if (found)
    set(hObject, 'Background', 'green');
else
    set(hObject, 'Background', 'red');
end


% --- Executes on button press in checkboxM8195Acorr.
function checkboxM8195Acorr_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxM8195Acorr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkboxM8195Acorr
val = get(hObject, 'Value');
if (val)
    msgbox(['Note, this method of applying the M8195A correction is NOT recommended. ' ...
        'Instead, please open any of the waveform generation windows, click on "Show ' ...
        'Correction" and then on "Read M8195A built-in corrections"']);
end


% --- Executes on button press in pushbuttonTestDCA.
function pushbuttonTestDCA_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTestDCA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
DCACfg.connectionType = 'visa';
DCACfg.visaAddr = get(handles.editVisaAddrDCA, 'String');
if (~isempty(strfind(DCACfg.visaAddr, 'Enter VISA')))
    errordlg({'Please enter a valid VISA Address for DCA. Typically something' ...
        'like: TCPIP0::ComputerName::inst0::INSTR.  You can find the address' ...
        'of the DCA under Tools -> SCPI Programming -> SCPI Server setup'});
    return;
end
found = 0;
hMsgBox = msgbox('Trying to connect, please wait...', 'Please wait...', 'replace');
f = iqopen(DCACfg);
try close(hMsgBox); catch ex; end
if (~isempty(f))
    try
        res = xquery(f, '*IDN?');
        if (~isempty(strfind(res, 'N1010A')) || ~isempty(strfind(res, 'N1000A')) || ~isempty(strfind(res, '86100')))
            found = 1;
        else
            errordlg({'Unexpected IDN reponse from DCA: ' '' res});
        end
    catch ex
        errordlg({'Error reading DCA IDN:' '' ex.message});
    end
    iqclose(f);
end
if (found)
    set(hObject, 'Background', 'green');
else
    set(hObject, 'Background', 'red');
end



function editVisaAddrDCA_Callback(hObject, eventdata, handles)
% hObject    handle to editVisaAddrDCA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVisaAddrDCA as text
%        str2double(get(hObject,'String')) returns contents of editVisaAddrDCA as a double
checkVisaAddr(handles, hObject, 0);


% --- Executes during object creation, after setting all properties.
function editVisaAddrDCA_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVisaAddrDCA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxDCA.
function checkboxDCA_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxDCA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
checkboxDCA_update(handles);



function checkboxDCA_update(handles)
DCAConnected = get(handles.checkboxDCA, 'Value');
if (~DCAConnected)
    set(handles.editVisaAddrDCA, 'Enable', 'off');
    set(handles.pushbuttonTestDCA, 'Enable', 'off');
    set(handles.pushbuttonTestDCA, 'Background', [.9 .9 .9]);
else
    set(handles.editVisaAddrDCA, 'Enable', 'on');
    set(handles.pushbuttonTestDCA, 'Enable', 'on');
%    msgbox('Note: Remote VSA access is not completely implemented. Some functions are not yet available. Please continue to use "local" VSA in the meantime');
end



function result = checkfields(hObject, eventdata, handles)
% do nothing
result = [];


% --- Executes on selection change in popupmenuClockSource.
function popupmenuClockSource_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuClockSource (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
idx = get(handles.popupmenuClockSource, 'Value');
arbModels = cellstr(get(handles.popupmenuModel, 'String'));
arbModel = arbModels{get(handles.popupmenuModel, 'Value')};
switch (idx)
    case 1 % leave unchanged
        freqFlag = 'off';
    case 2 % int ref clk
        freqFlag = 'off';
    case 3 % axie ref clk
        freqFlag = 'off';
    case 4 % ext ref clk
        freqFlag = 'on';
    case 5 % ext sample clk
        if (~isempty(strfind(arbModel, 'M8195')) || ~isempty(strfind(arbModel, 'M8194')) || ...
                ~isempty(strfind(arbModel, 'M8196')))
            errordlg('M8194A/95A/96A AWGs do not support external sample clock');
            set(handles.popupmenuClockSource, 'Value', 2);
            freqFlag = 'off';
        else
            freqFlag = 'on';
        end
end
set(handles.editClockFreq, 'Enable', freqFlag);
set(handles.textClockFreq, 'Enable', freqFlag);


% --- Executes during object creation, after setting all properties.
function popupmenuClockSource_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuClockSource (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editClockFreq_Callback(hObject, eventdata, handles)
% hObject    handle to editClockFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = [];
try
    value = iqparse(get(hObject, 'String'), 'vector');
catch ex
    msgbox(ex.message);
end
if (isscalar(value) && value >= 0)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editClockFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editClockFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonLoad.
function pushbuttonLoad_Callback(hObject, eventdata, handles)
% workaround for loading legacy setups
iqloadsettings(handles);
[cfg, ~] = makeArbConfig(handles);
% set(handles.popupmenuAWGCount, 'Value', 1);
% if (~strncmp(get(handles.editVisaAddr2, 'String'), 'Enter VISA', 10))
%     set(handles.popupmenuAWGCount, 'Value', 2);
% end
% if (~strncmp(get(handles.editVisaAddr3, 'String'), 'Enter VISA', 10))
%     set(handles.popupmenuAWGCount, 'Value', 3);
% end
% if (~strncmp(get(handles.editVisaAddr4, 'String'), 'Enter VISA', 10))
%     set(handles.popupmenuAWGCount, 'Value', 4);
% end
popupmenuAWGCount_Callback([], [], handles);
modelChange_Callback(hObject, 'load', handles);
checkUserSampleRate(handles);
checkboxDCA_update(handles);
checkboxPSG_update(handles);
checkboxVisaAddrScope_update(handles);


% --- Executes on button press in pushbuttonSave.
function pushbuttonSave_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqsavesettings(handles);



function editPeaking_Callback(hObject, eventdata, handles)
% hObject    handle to editPeaking (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = [];
try
    value = iqparse(get(handles.editPeaking, 'String'), 'vector');
catch ex
    msgbox(ex.message);
end
if (isvector(value) || isempty(value))
    set(handles.editPeaking, 'BackgroundColor', 'white');
else
    set(handles.editPeaking, 'BackgroundColor', 'red');
end


% --- Executes during object creation, after setting all properties.
function editPeaking_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPeaking (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonCancel.
function pushbuttonCancel_Callback(hObject, eventdata, handles)
close(handles.output);


% --- Executes on selection change in popupmenuMode.
function popupmenuMode_Callback(hObject, eventdata, handles)
% when switching between M8199A ILV and non-ILV modes, try to adapt the user
% default sample rate automatically and change the Marker divide ratio
awgmodels = get(handles.popupmenuModel, 'String');
awgmodel = awgmodels{get(handles.popupmenuModel, 'Value')};
if strcmp(awgmodel, 'M8199A')
    val = get(handles.popupmenuMode, 'Value');
    if (get(handles.checkboxUserSampleRate, 'Value'))
        fs = str2double(get(handles.editUserSampleRate, 'String'));
        if (~isnan(fs))
            if (val == 2 && fs <= 130e9)
                fs = 2 * fs;
            elseif (val == 1 && fs > 130e9)
                fs = fs / 2;
            end
            set(handles.editUserSampleRate, 'String', iqengprintf(fs));
            set(handles.editUserSampleRate, 'Background', 'yellow');
        end
    end
    rlist = get(handles.popupmenuSampleMarker, 'String');
    r = rlist{get(handles.popupmenuSampleMarker, 'Value')};
    if (val == 2 && strcmpi(r, 'Sample rate / 8'))
        r = 'Sample rate / 16';
    elseif (val == 1 && strcmp(r, 'Sample rate / 16'))
        r = 'Sample rate / 8';
    end
    p = find(strcmp(r, rlist));
    if (~isempty(p))
        set(handles.popupmenuSampleMarker, 'Value', p);
        set(handles.popupmenuSampleMarker, 'Background', 'yellow');
    end
    drawnow();
    pause(0.5);
    set(handles.editUserSampleRate, 'Background', 'white');
    set(handles.popupmenuSampleMarker, 'Background', 'white');
end
modelChange_Callback(hObject, 'mode', handles);


% --- Executes during object creation, after setting all properties.
function popupmenuMode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editLOIPAddr_Callback(hObject, eventdata, handles)
% hObject    handle to editLOIPAddr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = strtrim(get(handles.editLOIPAddr, 'String'));
if (strcmp(val, '') || strcmp(val, 'xxx.xxx.xxx.xxx'))
    set(handles.editLOIPAddr, 'Background', 'yellow');
else
    set(handles.editLOIPAddr, 'Background', 'white');
end



% --- Executes during object creation, after setting all properties.
function editLOIPAddr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editLOIPAddr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuOutputType.
function popupmenuOutputType_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuOutputType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
paramChangedNote(handles);


% --- Executes during object creation, after setting all properties.
function popupmenuOutputType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuOutputType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSD1ModuleIndex_Callback(hObject, eventdata, handles)
% hObject    handle to editSD1ModuleIndex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSD1ModuleIndex as text
%        str2double(get(hObject,'String')) returns contents of editSD1ModuleIndex as a double


% --- Executes during object creation, after setting all properties.
function editSD1ModuleIndex_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSD1ModuleIndex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxRecorderConnected.
function checkboxRecorderConnected_Callback(hObject, eventdata, handles)
recorderConnected = get(handles.checkboxRecorderConnected, 'Value');
if (recorderConnected)
    set(handles.editRecorderAddr, 'Enable', 'on');
    set(handles.editRecorderPCIAddr, 'Enable', 'on');
    set(handles.popupmenuRecorderConnectionType, 'Enable', 'on');
    set(handles.textRecorderAddr, 'Enable', 'on');
    set(handles.pushbuttonTestRecorder, 'Enable', 'on');
else
    set(handles.editRecorderAddr, 'Enable', 'off');
    set(handles.editRecorderPCIAddr, 'Enable', 'off');
    set(handles.popupmenuRecorderConnectionType, 'Enable', 'off');
    set(handles.textRecorderAddr, 'Enable', 'off');
    set(handles.pushbuttonTestRecorder, 'Enable', 'off');
    set(handles.pushbuttonTestRecorder, 'Background', [.9 .9 .9]);
end
% update connection type
popupmenuRecorderConnectionType_Callback(hObject, eventdata, handles);



function editRecorderAddr_Callback(hObject, eventdata, handles)
% hObject    handle to editRecorderAddr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editRecorderAddr as text
%        str2double(get(hObject,'String')) returns contents of editRecorderAddr as a double


% --- Executes during object creation, after setting all properties.
function editRecorderAddr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editRecorderAddr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonTestRecorder.
function pushbuttonTestRecorder_Callback(hObject, eventdata, handles)
[cfg, ~] = makeArbConfig(handles);
hMsgBox = msgbox('Trying to connect, please wait...', 'Please wait...', 'replace');
res = iqstreamtool('arbConfig', cfg, 'cmd', 'Test Connection');
try close(hMsgBox); catch; end
if (res ~= 0)
    set(handles.pushbuttonTestRecorder, 'Background', 'green');
else
    set(handles.pushbuttonTestRecorder, 'Background', 'red');
end


% --- Executes on selection change in popupmenuRecorderConnectionType.
function popupmenuRecorderConnectionType_Callback(hObject, eventdata, handles)
value = get(handles.popupmenuRecorderConnectionType, 'Value');
switch value
    case 1
        set(handles.textRecorderAddr, 'String', 'IP address');
        set(handles.editRecorderAddr, 'Visible', 'on');
        set(handles.editRecorderPCIAddr, 'Visible', 'off');
    case 2
        set(handles.textRecorderAddr, 'String', 'PCIe module');
        set(handles.editRecorderAddr, 'Visible', 'off');
        set(handles.editRecorderPCIAddr, 'Visible', 'on');
end
recorderConnected = get(handles.checkboxRecorderConnected, 'Value');
if (recorderConnected && value == 1)
    set(handles.textRecorderPorts, 'Enable', 'on');
    set(handles.editRecorderPorts, 'Enable', 'on');
else
    set(handles.textRecorderPorts, 'Enable', 'off');
    set(handles.editRecorderPorts, 'Enable', 'off');
end


% --- Executes during object creation, after setting all properties.
function popupmenuRecorderConnectionType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuRecorderConnectionType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editRecorderPCIAddr_Callback(hObject, eventdata, handles)
% hObject    handle to editRecorderPCIAddr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editRecorderPCIAddr as text
%        str2double(get(hObject,'String')) returns contents of editRecorderPCIAddr as a double


% --- Executes during object creation, after setting all properties.
function editRecorderPCIAddr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editRecorderPCIAddr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editVisaAddr4_Callback(hObject, eventdata, handles)
% hObject    handle to editVisaAddr4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVisaAddr4 as text
%        str2double(get(hObject,'String')) returns contents of editVisaAddr4 as a double


% --- Executes during object creation, after setting all properties.
function editVisaAddr4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVisaAddr4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editVisaAddr2_Callback(hObject, eventdata, handles)


function editVisaAddr3_Callback(hObject, eventdata, handles)

function editVisaAddr3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVisaAddr3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuAWGCount.
function popupmenuAWGCount_Callback(hObject, eventdata, handles)
SyncConnected = get(handles.checkboxVisaAddrM8192A, 'Value');
cnt = get(handles.popupmenuAWGCount, 'Value');
pos = get(handles.iqtool, 'Position');
if (cnt == 1)
    if (~SyncConnected)
        pos(3) = 596;
    else
        pos(3) = 904;
        set(handles.editVisaAddr2, 'Enable', 'off');
        set(handles.pushbuttonTestAWG2, 'Enable', 'off');
        set(handles.pushbuttonSwapAWG2, 'Enable', 'off');
    end
    set(handles.pushbuttonTestAWG2, 'Background', [.9 .9 .9]);
end
if (cnt >= 2)
    arbIdx = get(handles.popupmenuModel, 'Value');
    arbModelIdx = handles.arbModelPtrs{arbIdx};
    arbModeIdx = get(handles.popupmenuMode, 'Value');
    arbModels = handles.modelInfo(:,1);
    arbModel = arbModels{arbModelIdx(arbModeIdx)};
    if (isempty(strfind(arbModel, 'M8190A')) && isempty(strfind(arbModel, 'M8121A')) && ...
        isempty(strfind(arbModel, 'M8195A')) && isempty(strfind(arbModel, 'M8194A')) && ...
        isempty(strfind(arbModel, 'M8198A')) && isempty(strfind(arbModel, 'M8199A')) && ...
		isempty(strfind(arbModel, 'M8199A_ILV')) && isempty(strfind(arbModel, 'M8199B')) ... % && isempty(strfind(arbModel, 'M8198B'))
        )
        set(handles.popupmenuAWGCount, 'Value', 1);
        warndlg('Multi-module operation is only supported for M8190A, M8195A, M8194A, M8121A, M8199A/B');
%         warndlg('Multi-module operation is only supported for M8190A, M8195A, M8194A, M8121A, M8199A/B, and M8198A');
        return;
    else
        pos(3) = 904;
        set(handles.editVisaAddr2, 'Enable', 'on');
        set(handles.editM8070ModuleID2, 'Enable', 'on');
        set(handles.pushbuttonTestAWG2, 'Enable', 'on');
        set(handles.pushbuttonSwapAWG2, 'Enable', 'on');
    end
end
if (cnt >= 3)
    set(handles.editVisaAddr3, 'Enable', 'on');
    set(handles.editM8070ModuleID3, 'Enable', 'on');
    set(handles.pushbuttonTestAWG3, 'Enable', 'on');
    set(handles.pushbuttonSwapAWG3, 'Enable', 'on');
else
    set(handles.editVisaAddr3, 'Enable', 'off');
    set(handles.editM8070ModuleID3, 'Enable', 'off');
    set(handles.pushbuttonTestAWG3, 'Enable', 'off');
    set(handles.pushbuttonSwapAWG3, 'Enable', 'off');
    set(handles.pushbuttonTestAWG3, 'Background', [.9 .9 .9]);
end
if (cnt >= 4)
    set(handles.editVisaAddr4, 'Enable', 'on');
    set(handles.editM8070ModuleID4, 'Enable', 'on');
    set(handles.pushbuttonTestAWG4, 'Enable', 'on');
    set(handles.pushbuttonSwapAWG4, 'Enable', 'on');
else
    set(handles.editVisaAddr4, 'Enable', 'off');
    set(handles.editM8070ModuleID4, 'Enable', 'off');
    set(handles.pushbuttonTestAWG4, 'Enable', 'off');
    set(handles.pushbuttonSwapAWG4, 'Enable', 'off');
    set(handles.pushbuttonTestAWG4, 'Background', [.9 .9 .9]);
end
set(handles.iqtool, 'Position', pos);
setAutoAddr(handles.editVisaAddr, handles.editVisaAddr2);
setAutoAddr(handles.editVisaAddr2, handles.editVisaAddr3);
setAutoAddr(handles.editVisaAddr3, handles.editVisaAddr4);
checkModuleIDs(handles);


function setAutoAddr(h1, h2)
% try to "guess" the VISA address of additional AWG modules based on the
% address of previous modules
if (strncmp(get(h2, 'String'), 'Enter', 5))
    addr = get(h1, 'String');
    addr2 = regexprep(addr, '::inst([0-9]*)', '::inst${num2str(str2double($1)+1)}');
    addr2 = regexprep(addr2, '::hislip([0-9]*)', '::hislip${num2str(str2double($1)+1)}');
    addr2 = regexprep(addr2, '::([0-9]*)::', '::${num2str(str2double($1)+1)}::');
    set(h2, 'String', addr2);
end



% --- Executes during object creation, after setting all properties.
function popupmenuAWGCount_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuAWGCount (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxVisaAddr2.
function checkboxVisaAddr2_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxVisaAddr2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxVisaAddr2



function editRecorderPorts_Callback(hObject, eventdata, handles)
% hObject    handle to editRecorderPorts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editRecorderPorts as text
%        str2double(get(hObject,'String')) returns contents of editRecorderPorts as a double


% --- Executes during object creation, after setting all properties.
function editRecorderPorts_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editRecorderPorts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonTestPowerSensor.
function pushbuttonTestPowerSensor_Callback(hObject, eventdata, handles)
powerSensorCfg.connectionType = 'visa';
powerSensorCfg.visaAddr = get(handles.editVisaAddrPowerSensor, 'String');
if (~isempty(strfind(powerSensorCfg.visaAddr, 'Enter VISA')))
    errordlg({'Please enter a valid VISA Address for the power sensor. Typically something' ...
        'like: TCPIP0::K-L20xx-xxxxx::inst0::INSTR.  You can find the product and serial' ...
        'number on a sticker on the power sensor'});
    return;
end
found = 0;
hMsgBox = msgbox('Trying to connect, please wait...', 'Please wait...', 'replace');
iqreset();
f = iqopen(powerSensorCfg);
try close(hMsgBox); catch ex; end
if (~isempty(f))
    try
        res = xquery(f, '*IDN?');
        if (~isempty(strfind(res, 'L20')) || ...
            ~isempty(strfind(res, 'K20')))
            found = 1;
        else
            errordlg({'Unexpected power sensor model:' '' res ...
                'Supported models are K-L20xx or K-K20xx'});
        end
    catch ex
        errordlg({'Error reading scope IDN:' '' ex.message});
    end
    iqclose(f);
end
if (found)
    set(hObject, 'Background', 'green');
else
    set(hObject, 'Background', 'red');
end


function editVisaAddrPowerSensor_Callback(hObject, eventdata, handles)
% hObject    handle to editVisaAddrPowerSensor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVisaAddrPowerSensor as text
%        str2double(get(hObject,'String')) returns contents of editVisaAddrPowerSensor as a double


% --- Executes during object creation, after setting all properties.
function editVisaAddrPowerSensor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVisaAddrPowerSensor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxPowerSensor.
function checkboxPowerSensor_Callback(hObject, eventdata, handles)
val = get(handles.checkboxPowerSensor, 'Value');
set(handles.pushbuttonTestPowerSensor, 'Background', [.9 .9 .9]);
if (val)
    set(handles.editVisaAddrPowerSensor, 'Enable', 'on');
    set(handles.editPowerSensorAverages, 'Enable', 'on');
    set(handles.pushbuttonTestPowerSensor, 'Enable', 'on');
else
    set(handles.editVisaAddrPowerSensor, 'Enable', 'off');
    set(handles.editPowerSensorAverages, 'Enable', 'off');
    set(handles.pushbuttonTestPowerSensor, 'Enable', 'off');
end


function editPowerSensorAverages_Callback(hObject, eventdata, handles)
% hObject    handle to editPowerSensorAverages (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPowerSensorAverages as text
%        str2double(get(hObject,'String')) returns contents of editPowerSensorAverages as a double


% --- Executes during object creation, after setting all properties.
function editPowerSensorAverages_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPowerSensorAverages (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuFilterSettings.
function popupmenuFilterSettings_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuFilterSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
paramChangedNote(handles);


% --- Executes during object creation, after setting all properties.
function popupmenuFilterSettings_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuFilterSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editM8070ModuleID_Callback(hObject, eventdata, handles)
checkModuleIDs(handles);


% flag invalid selection of module IDs
function checkModuleIDs(handles)
h = [handles.editM8070ModuleID, handles.editM8070ModuleID2, handles.editM8070ModuleID3, handles.editM8070ModuleID4];
m = zeros(1,4);
cnt = get(handles.popupmenuAWGCount, 'Value');
for i = 1:cnt
    m(i) = checkModuleIDFormat(h(i));
    if (i > 1 && m(i) > 0 && m(i-1) > 0 && m(i) ~= m(i-1) + 1) 
        set(h(i), 'background', 'red');
        set(h(i-1), 'background', 'red');
%        errordlg('Module IDs for AWG modules must be sequential', 'Error', 'replace');
    end
end


function res = checkModuleIDFormat(handle)
n = sscanf(get(handle, 'String'), 'M%d');
if (isempty(n) || n < 1 || n > 8)
    res = -1;
    set(handle, 'background', 'red');
else
    res = n;
    set(handle, 'String', sprintf('M%d', n));
    set(handle, 'background', 'white');
end


% --- Executes during object creation, after setting all properties.
function editM8070ModuleID_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editM8070ModuleID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuSampleMarker.
function popupmenuSampleMarker_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuSampleMarker (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuSampleMarker contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuSampleMarker


% --- Executes during object creation, after setting all properties.
function popupmenuSampleMarker_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuSampleMarker (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function menuPreferences_Callback(hObject, eventdata, handles)
% hObject    handle to menuPreferences (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


function editM8070ModuleID4_Callback(hObject, eventdata, handles)
checkModuleIDs(handles);


% --- Executes during object creation, after setting all properties.
function editM8070ModuleID4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editM8070ModuleID4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editM8070ModuleID3_Callback(hObject, eventdata, handles)
checkModuleIDs(handles);


% --- Executes during object creation, after setting all properties.
function editM8070ModuleID3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editM8070ModuleID3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editM8070ModuleID2_Callback(hObject, eventdata, handles)
checkModuleIDs(handles);


% --- Executes during object creation, after setting all properties.
function editM8070ModuleID2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editM8070ModuleID2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editUserSampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to editUserSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
checkUserSampleRate(handles);


function checkUserSampleRate(handles)
str = get(handles.editUserSampleRate, 'String');
isOK = 1;
if (~isempty(str))
    try
        val = iqparse(get(handles.editUserSampleRate, 'String'), 'scalar');
        if (~isreal(val) || ~isscalar(val) || val <= 0)
            isOK = 0;
        else
            arbConfig = makeArbConfig(handles);
            arbConfig = loadArbConfig(arbConfig);
            isOK = ~isempty(find(val >= arbConfig.minimumSampleRate & val <= arbConfig.maximumSampleRate, 1));
        end
    catch
        isOK = 0;
    end
end
if (isOK)
    set(handles.editUserSampleRate, 'BackgroundColor', 'white');
else
    % it seems that sometimes a single color change does not work...
    set(handles.editUserSampleRate, 'BackgroundColor', 'yellow');
    set(handles.editUserSampleRate, 'BackgroundColor', 'red');
end


% --- Executes during object creation, after setting all properties.
function editUserSampleRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editUserSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxUserSampleRate.
function checkboxUserSampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxUserSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = get(hObject,'Value');
onoff = {'off' 'on'};
set(handles.editUserSampleRate, 'Enable', onoff{val+1});
if (val)
    checkUserSampleRate(handles);
end


% --- Executes on button press in pushbuttonTestPSG.
function pushbuttonTestPSG_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTestPSG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
PSGCfg.connectionType = 'visa';
PSGCfg.visaAddr = get(handles.editVisaAddrPSG, 'String');
if (~isempty(strfind(PSGCfg.visaAddr, 'Enter VISA')))
    errordlg({'Please enter a valid VISA Address for PSG. Typically something' ...
        'like: TCPIP0::ComputerName::inst0::INSTR.  You can find the address' ...
        'of the PSG under Utilities -> LAN'});
    return;
end
found = 0;
hMsgBox = msgbox('Trying to connect, please wait...', 'Please wait...', 'replace');
f = iqopen(PSGCfg);
try close(hMsgBox); catch ex; end
if (~isempty(f))
    try
        res = xquery(f, '*IDN?');
        if (~isempty(strfind(res, 'E8257D')))
            found = 1;
        else
            errordlg({'Unexpected IDN reponse from PSG: ' '' res});
        end
    catch ex
        errordlg({'Error reading PSG IDN:' '' ex.message});
    end
    iqclose(f);
end
if (found)
    set(hObject, 'Background', 'green');
else
    set(hObject, 'Background', 'red');
end



function editVisaAddrPSG_Callback(hObject, eventdata, handles)
% hObject    handle to editVisaAddrPSG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editVisaAddrPSG as text
%        str2double(get(hObject,'String')) returns contents of editVisaAddrPSG as a double
checkVisaAddr(handles, hObject, 0);


% --- Executes during object creation, after setting all properties.
function editVisaAddrPSG_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVisaAddrPSG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxPSG.
function checkboxPSG_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxPSG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
checkboxPSG_update(handles);



function checkboxPSG_update(handles)
PSGConnected = get(handles.checkboxPSG, 'Value');
if (~PSGConnected)
    set(handles.editVisaAddrPSG, 'Enable', 'off');
    set(handles.pushbuttonTestPSG, 'Enable', 'off');
    set(handles.pushbuttonTestPSG, 'Background', [.9 .9 .9]);
else
    set(handles.editVisaAddrPSG, 'Enable', 'on');
    set(handles.pushbuttonTestPSG, 'Enable', 'on');
end



function editTimeout_Callback(hObject, eventdata, handles)
checkScalarOrVector(hObject, 1, 1);


% --- Executes during object creation, after setting all properties.
function editTimeout_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

