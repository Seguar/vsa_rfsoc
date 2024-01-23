function varargout = iqampdepphase(varargin)
% IQAMPDEPPHASE MATLAB code for iqampdepphase.fig
%      IQAMPDEPPHASE, by itself, creates a new IQAMPDEPPHASE or raises the existing
%      singleton*.
%
%      H = IQAMPDEPPHASE returns the handle to a new IQAMPDEPPHASE or the handle to
%      the existing singleton*.
%
%      IQAMPDEPPHASE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQAMPDEPPHASE.M with the given input arguments.
%
%      IQAMPDEPPHASE('Property','Value',...) creates a new IQAMPDEPPHASE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqampdepphase_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqampdepphase_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqampdepphase

% Last Modified by GUIDE v2.5 22-Nov-2022 18:47:46

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqampdepphase_OpeningFcn, ...
                   'gui_OutputFcn',  @iqampdepphase_OutputFcn, ...
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


% --- Executes just before iqampdepphase is made visible.
function iqampdepphase_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqampdepphase (see VARARGIN)

% Choose default command line output for iqampdepphase
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes iqampdepphase wait for user response (see UIRESUME)
% uiwait(handles.figure1);

%% StartupFcn from App designer
acs = load(iqampCorrFilename());
if (isfield(acs, 'nonLinCorr'))
    if (isfield(acs.nonLinCorr, 'ampDepPhaseCorr'))
      set(handles.checkbox1,'Value', acs.nonLinCorr.ampDepPhaseCorr);
    end

    if (isfield(acs.nonLinCorr, 'exponent'))
         set(handles.editExp, 'String', acs.nonLinCorr.exponent)
    end
    if (isfield(acs.nonLinCorr, 'ampDepPhase'))
         set(handles.editAmpDepPhase, 'String', acs.nonLinCorr.ampDepPhase)
    end
    if (isfield(acs.nonLinCorr, 'absPhase'))
         set(handles.editAbsPhase, 'String', acs.nonLinCorr.absPhase)
    end
    if (isfield(acs.nonLinCorr, 'gain'))
        set(handles.editGain, 'String', acs.nonLinCorr.gain)
    end
end



% --- Outputs from this function are returned to the command line.
function varargout = iqampdepphase_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox1

doUpdate(hObject, eventdata, handles);

function editExp_Callback(hObject, eventdata, handles)
% hObject    handle to editExp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editExp as text
%        str2double(get(hObject,'String')) returns contents of editExp as a double
doUpdate(hObject, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function editExp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editExp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editAmpDepPhase_Callback(hObject, eventdata, handles)
% hObject    handle to editAmpDepPhase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editAmpDepPhase as text
%        str2double(get(hObject,'String')) returns contents of editAmpDepPhase as a double
doUpdate(hObject, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function editAmpDepPhase_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAmpDepPhase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editAbsPhase_Callback(hObject, eventdata, handles)
% hObject    handle to editAbsPhase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editAbsPhase as text
%        str2double(get(hObject,'String')) returns contents of editAbsPhase as a double
doUpdate(hObject, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function editAbsPhase_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAbsPhase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editGain_Callback(hObject, eventdata, handles)
% hObject    handle to editGain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editGain as text
%        str2double(get(hObject,'String')) returns contents of editGain as a double
doUpdate(hObject, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function editGain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editGain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function doUpdate(hObject, eventdata, handles)
enable = get(handles.checkbox1,'Value');

exponent = str2double(get(handles.editExp, 'String'));
ampDepPhase = str2double(get(handles.editAmpDepPhase, 'String'));
absPhase = str2double(get(handles.editAbsPhase , 'String'));
gain = str2double(get(handles.editGain , 'String'));
acs = load(iqampCorrFilename());
acs.nonLinCorr.ampDepPhaseCorr = enable;
acs.nonLinCorr.exponent = exponent;
acs.nonLinCorr.ampDepPhase = ampDepPhase;
acs.nonLinCorr.absPhase = absPhase;
acs.nonLinCorr.gain = gain;
save(iqampCorrFilename(), '-struct', 'acs');

