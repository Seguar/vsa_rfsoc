function varargout = iqtosound_gui(varargin)
% IQTOSOUND_GUI MATLAB code for iqtosound_gui.fig
%      IQTOSOUND_GUI, by itself, creates a new IQTOSOUND_GUI or raises the existing
%      singleton*.
%
%      H = IQTOSOUND_GUI returns the handle to a new IQTOSOUND_GUI or the handle to
%      the existing singleton*.
%
%      IQTOSOUND_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQTOSOUND_GUI.M with the given input arguments.
%
%      IQTOSOUND_GUI('Property','Value',...) creates a new IQTOSOUND_GUI or raises
%      the existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqtosound_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqtosound_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqtosound_gui

% Last Modified by GUIDE v2.5 02-Mar-2020 13:41:53

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqtosound_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @iqtosound_gui_OutputFcn, ...
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

% --- Executes just before iqtosound_gui is made visible.
function iqtosound_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqtosound_gui (see VARARGIN)

% Choose default command line output for iqtosound_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

initialize_gui(hObject, handles, false);

% UIWAIT makes iqtosound_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = iqtosound_gui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --------------------------------------------------------------------
function initialize_gui(fig_handle, handles, isreset)
% If the metricdata field is present and the reset flag is false, it means
% we are we are just re-initializing a GUI by calling it from the cmd line
% while it is up. So, bail out as we dont want to reset the data.
if isfield(handles, 'metricdata') && ~isreset
    return;
end

% Min and max frequencies
handles.toneFrequencyMinHz = 200;
handles.toneFrequencyMaxHz = 600;
handles.tracePlayDurationS = 0.5;
handles.toneZeroHz = (handles.toneFrequencyMaxHz + handles.toneFrequencyMinHz) / 2;

set(handles.editToneFreqMinHz, 'String', num2str(handles.toneFrequencyMinHz));
set(handles.editToneFreqMaxHz, 'String', num2str(handles.toneFrequencyMaxHz));
set(handles.editSoundDurationS, 'String', num2str(handles.tracePlayDurationS));

% Update rate of acquisition
handles.updateRatePerSecond = 0;
handles.loopUpdates = true;

set(handles.editLoopRateS, 'String', num2str(handles.updateRatePerSecond));
set(handles.checkboxContinuousCapture, 'Value', handles.loopUpdates);

% Sound card sample rate
handles.soundCardSampleRateHz = 8192;

% Event handling and arming
handles.isEventArmed = true;

% handles.metricdata.volume  = 0;
% 
% set(handles.density, 'String', handles.metricdata.density);
% set(handles.volume,  'String', handles.metricdata.volume);
% set(handles.mass, 'String', 0);
% 
% set(handles.unitgroup, 'SelectedObject', handles.english);
% 
% set(handles.text4, 'String', 'lb/cu.in');
% set(handles.text5, 'String', 'cu.in');
% set(handles.text6, 'String', 'lb');

% Update handles structure
guidata(handles.figure1, handles);


% --- Executes on button press in pushbuttonPlaySound.
function pushbuttonPlaySound_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonPlaySound (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Arm the player
handles.isEventArmed = true;
guidata(hObject, handles);

% Make sure VSA is connected and is in vector mode
vsaApp = vsafunc([], 'open');
if (~isempty(vsaApp))
    hMsgBox = msgbox('Configuring VSA software. Please wait...', 'Please wait...', 'replace');
    vsafunc(vsaApp, 'setupforradarsound', handles.toneFrequencyMinHz,...
        handles.toneFrequencyMaxHz, handles.tracePlayDurationS, handles.soundCardSampleRateHz);
    
    try
        close(hMsgBox);
    catch ex
    end
else
   hMsgBox = msgbox('VSA not connected. Cannot play signals');
   return
end

while handles.isEventArmed && get(handles.checkboxContinuousCapture, 'Value')      
    vsafunc(vsaApp, 'setupforradarsound', handles.toneFrequencyMinHz,...
        handles.toneFrequencyMaxHz, handles.tracePlayDurationS, handles.soundCardSampleRateHz);
    
    % Wait and get next pulse
    pause(handles.updateRatePerSecond)
    handles = guidata(hObject);
end

% --- Executes on button press in checkboxContinuousCapture.
function checkboxContinuousCapture_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxContinuousCapture (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxContinuousCapture

% --- Executes on button press in pushbuttonStopSound.
function pushbuttonStopSound_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonStopSound (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.isEventArmed = false;
guidata(hObject, handles);

function editLoopRateS_Callback(hObject, eventdata, handles)
% hObject    handle to editLoopRateS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editLoopRateS as text
%        str2double(get(hObject,'String')) returns contents of editLoopRateS as a double
value = [];
try
    value = str2double(get(hObject,'String'));
catch ex
    msgbox(ex.message);
end
if (value >= 0)
    set(hObject,'BackgroundColor','white');
    handles.updateRatePerSecond = value;
    guidata(hObject, handles);
else
    set(hObject,'BackgroundColor','red');
end

% --- Executes on button press in pushbuttonTestMinFreq.
function pushbuttonTestMinFreq_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTestMinFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
   % Create the tone
   timeArray = 0:1/handles.soundCardSampleRateHz:handles.tracePlayDurationS;
   soundData = sin(2*pi*timeArray*handles.toneFrequencyMinHz);
   
   % Generate the sound
   sound(soundData, handles.soundCardSampleRateHz)   
catch ex
    msgbox(ex.message);
end

% --- Executes on button press in pushbuttonTestMaxFreq.
function pushbuttonTestMaxFreq_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTestMaxFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
   % Create the tone
   timeArray = 0:1/handles.soundCardSampleRateHz:handles.tracePlayDurationS;
   soundData = sin(2*pi*timeArray*handles.toneFrequencyMaxHz);
   
   % Generate the sound
   sound(soundData, handles.soundCardSampleRateHz)
catch ex
    msgbox(ex.message);
end


% --- Executes on button press in pushbuttonPreviewChirpSignal.
function pushbuttonPreviewChirpSignal_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonPreviewChirpSignal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
   % Create time array
   timeArray = 0:1/handles.soundCardSampleRateHz:handles.tracePlayDurationS;
   
   % Create the frequency ramp
   freqData = timeArray / max(timeArray);
   
   % Linear (y = mx + b)
   freqData = freqData.*(handles.toneFrequencyMaxHz - handles.toneFrequencyMinHz)...
       + handles.toneFrequencyMinHz;
   
   % Frequency to samples
   linearAmp = ones(1,length(freqData));
   phaseSignal = 2 * pi * cumsum(freqData) / handles.soundCardSampleRateHz;
   soundData = linearAmp .* exp(1i * phaseSignal);
   
   % Generate the sound
   sound(real(soundData), handles.soundCardSampleRateHz)
catch ex
    msgbox(ex.message);
end

% --- Executes on button press in pushbuttonPreviewCWSignal.
function pushbuttonPreviewCWSignal_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonPreviewCWSignal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
   % Create the tone (half of start and stop)
   timeArray = 0:1/handles.soundCardSampleRateHz:handles.tracePlayDurationS;
   soundData = sin(2*pi*timeArray*(handles.toneFrequencyMaxHz + handles.toneFrequencyMinHz)/2);
   
   % Generate the sound
   sound(soundData, handles.soundCardSampleRateHz)
catch ex
    msgbox(ex.message);
end


function editToneFreqMinHz_Callback(hObject, eventdata, handles)
% hObject    handle to editToneFreqMinHz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editToneFreqMinHz as text
%        str2double(get(hObject,'String')) returns contents of editToneFreqMinHz as a double
value = [];
try
    value = str2double(get(hObject,'String'));
catch ex
    msgbox(ex.message);
end
if (value <= handles.toneFrequencyMaxHz)
    set(hObject,'BackgroundColor','white');
    handles.toneFrequencyMinHz = value;
    guidata(hObject, handles);
else
    set(hObject,'BackgroundColor','red');
end

function editToneFreqMaxHz_Callback(hObject, eventdata, handles)
% hObject    handle to editToneFreqMaxHz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editToneFreqMaxHz as text
%        str2double(get(hObject,'String')) returns contents of editToneFreqMaxHz as a double
value = [];
try
    value = str2double(get(hObject,'String'));
catch ex
    msgbox(ex.message);
end
if (value >= handles.toneFrequencyMinHz)
    set(hObject,'BackgroundColor','white');
    handles.toneFrequencyMaxHz = value;
    guidata(hObject, handles);
else
    set(hObject,'BackgroundColor','red');
end

function editSoundDurationS_Callback(hObject, eventdata, handles)
% hObject    handle to editSoundDurationS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSoundDurationS as text
%        str2double(get(hObject,'String')) returns contents of editSoundDurationS as a double
value = [];
try
    value = str2double(get(hObject,'String'));
catch ex
    msgbox(ex.message);
end
if (value >= 0.2)
    set(hObject,'BackgroundColor','white');
    handles.tracePlayDurationS = value;
    guidata(hObject, handles);
else
    set(hObject,'BackgroundColor','red');
end

% --- Executes during object creation, after setting all properties.
function editToneFreqMinHz_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editToneFreqMinHz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function editToneFreqMaxHz_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editToneFreqMaxHz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function editSoundDurationS_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSoundDurationS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function editLoopRateS_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editLoopRateS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
