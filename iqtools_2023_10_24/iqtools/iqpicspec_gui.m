function varargout = iqpicspec_gui(varargin)
% IQPICSPEC_GUI MATLAB code for iqpicspec_gui.fig
%      IQPICSPEC_GUI, by itself, creates a new IQPICSPEC_GUI or raises the existing
%      singleton*.
%
%      H = IQPICSPEC_GUI returns the handle to a new IQPICSPEC_GUI or the handle to
%      the existing singleton*.
%
%      IQPICSPEC_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQPICSPEC_GUI.M with the given input arguments.
%
%      IQPICSPEC_GUI('Property','Value',...) creates a new IQPICSPEC_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqpicspec_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqpicspec_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqpicspec_gui

% Last Modified by GUIDE v2.5 26-Nov-2020 15:24:56

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqpicspec_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @iqpicspec_gui_OutputFcn, ...
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


% --- Executes just before iqpicspec_gui is made visible.
function iqpicspec_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqpicspec_gui (see VARARGIN)

% Choose default command line output for iqpicspec_gui
handles.output = hObject;

arbConfig = loadArbConfig();
sr = get(handles.editSampleRate, 'String');
if (length(sr) == 0)
    set(handles.editSampleRate, 'String', iqengprintf(arbConfig.defaultSampleRate));
end
iqchannelsetup('setup', handles.pushbuttonChannelMapping, arbConfig);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes iqpicspec_gui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


% --- Outputs from this function are returned to the command line.
function varargout = iqpicspec_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function editSampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to editSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
checkfields(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function editSampleRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editStartFreq_Callback(hObject, eventdata, handles)
% hObject    handle to editStartFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editStartFreq as text
%        str2double(get(hObject,'String')) returns contents of editStartFreq as a double


% --- Executes during object creation, after setting all properties.
function editStartFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editStartFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editDuration_Callback(hObject, eventdata, handles)
% hObject    handle to editDuration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDuration as text
%        str2double(get(hObject,'String')) returns contents of editDuration as a double


% --- Executes during object creation, after setting all properties.
function editDuration_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDuration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonVisualize.
function pushbuttonVisualize_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonVisualize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
execute(handles, 0);


% --- Executes on button press in pushbuttonDownload.
function pushbuttonDownload_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
execute(handles, 1);


% --- Executes on button press in checkboxSequenceOnly.
function checkboxSequenceOnly_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSequenceOnly (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxSequenceOnly



function editBlankLines_Callback(hObject, eventdata, handles)
% hObject    handle to editBlankLines (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editBlankLines as text
%        str2double(get(hObject,'String')) returns contents of editBlankLines as a double


% --- Executes during object creation, after setting all properties.
function editBlankLines_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editBlankLines (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editFilename_Callback(hObject, eventdata, handles)
% hObject    handle to editFilename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFilename as text
%        str2double(get(hObject,'String')) returns contents of editFilename as a double


% --- Executes during object creation, after setting all properties.
function editFilename_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFilename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonGetFilename.
function pushbuttonGetFilename_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonGetFilename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (isfield(handles, 'filePath'))
    defaultPath = handles.filePath;
else
    defaultPath = [];
end
[filename, pathname] = uigetfile('*.png;*.jpg', 'Select image file', defaultPath);
if (filename ~= 0)
    set(handles.editFilename, 'String', fullfile(pathname, filename));
    handles.filePath = pathname;
    % Update handles structure
    guidata(hObject, handles);
end


function editStopFreq_Callback(hObject, eventdata, handles)
% hObject    handle to editStopFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editStopFreq as text
%        str2double(get(hObject,'String')) returns contents of editStopFreq as a double


% --- Executes during object creation, after setting all properties.
function editStopFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editStopFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editNumSamples_Callback(hObject, eventdata, handles)
% hObject    handle to editNumSamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNumSamples as text
%        str2double(get(hObject,'String')) returns contents of editNumSamples as a double


% --- Executes during object creation, after setting all properties.
function editNumSamples_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNumSamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editBlankValue_Callback(hObject, eventdata, handles)
% hObject    handle to editBlankValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editBlankValue as text
%        str2double(get(hObject,'String')) returns contents of editBlankValue as a double


% --- Executes during object creation, after setting all properties.
function editBlankValue_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editBlankValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editDynamic_Callback(hObject, eventdata, handles)
% hObject    handle to editDynamic (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDynamic as text
%        str2double(get(hObject,'String')) returns contents of editDynamic as a double


% --- Executes during object creation, after setting all properties.
function editDynamic_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDynamic (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxInvert.
function checkboxInvert_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxInvert (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxInvert


% --- Executes on button press in pushbuttonChannelMapping.
function pushbuttonChannelMapping_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonChannelMapping (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
arbConfig = loadArbConfig();
[val, str] = iqchanneldlg(get(hObject, 'UserData'), arbConfig, handles.iqtool);
if (~isempty(val))
    set(hObject, 'UserData', val);
    set(hObject, 'String', str);
end


function result = checkfields(hObject, eventdata, handles)
% This function verifies that all the fields have valid and consistent
% values. It is called from inside this script as well as from the
% iqconfig script when arbConfig changes (i.e. a different model or mode is
% selected). Returns 1 if all fields are OK, otherwise 0
result = 1;
arbConfig = loadArbConfig();

% --- editSampleRate
value = [];
try
    value = iqparse(get(handles.editSampleRate, 'String'), 'scalar');
catch ex
    msgbox(ex.message);
end
if (isscalar(value) && (~isempty(find(value >= arbConfig.minimumSampleRate & value <= arbConfig.maximumSampleRate, 1))))
    set(handles.editSampleRate,'BackgroundColor','white');
else
    set(handles.editSampleRate,'BackgroundColor','red');
end


function execute(handles, doDownload)
try
    sampleRate = iqparse(get(handles.editSampleRate, 'String'), 'scalar');
    startFreq = iqparse(get(handles.editStartFreq, 'String'), 'scalar');
    stopFreq = iqparse(get(handles.editStopFreq, 'String'), 'scalar');
    duration = iqparse(get(handles.editDuration, 'String'), 'scalar');
    filename = strtrim(get(handles.editFilename, 'String'));
    invert = get(handles.checkboxInvert, 'Value');
    dynamic = iqparse(get(handles.editDynamic, 'String'), 'scalar');
    blankLines = iqparse(get(handles.editBlankLines, 'String'), 'scalar');
    blankValue = iqparse(get(handles.editBlankValue, 'String'), 'scalar');
    numSamples = iqparse(get(handles.editNumSamples, 'String'), 'scalar');
    sequenceOnly = get(handles.checkboxSequenceOnly, 'Value');
    iqpicspec('sampleRate', sampleRate, 'startFreq', startFreq, 'stopFreq', stopFreq, ...
        'duration', duration, 'filename', filename, 'invert', invert, 'dynamic', dynamic, ...
        'blankLines', blankLines, 'blankValue', blankValue, 'numSamples', numSamples, ...
        'sequenceOnly', sequenceOnly, 'doDownload', doDownload);
catch ex
    errordlg(sprintf(ex.message));
end
