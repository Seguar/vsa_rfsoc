function varargout = iqinterleavecal_gui(varargin)
% IQINTERLEAVECAL_GUI MATLAB code for iqinterleavecal_gui.fig
%      IQINTERLEAVECAL_GUI, by itself, creates a new IQINTERLEAVECAL_GUI or raises the existing
%      singleton*.
%
%      H = IQINTERLEAVECAL_GUI returns the handle to a new IQINTERLEAVECAL_GUI or the handle to
%      the existing singleton*.
%
%      IQINTERLEAVECAL_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQINTERLEAVECAL_GUI.M with the given input arguments.
%
%      IQINTERLEAVECAL_GUI('Property','Value',...) creates a new IQINTERLEAVECAL_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqinterleavecal_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqinterleavecal_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqinterleavecal_gui

% Last Modified by GUIDE v2.5 23-Jan-2020 15:18:07

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqinterleavecal_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @iqinterleavecal_gui_OutputFcn, ...
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


% --- Executes just before iqinterleavecal_gui is made visible.
function iqinterleavecal_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqinterleavecal_gui (see VARARGIN)

if (nargin > 1)
    parentHandles = varargin{1};
else
    parentHandles = [];
end
% Choose default command line output for iqinterleavecal_gui
handles.output = hObject;
handles.parentHandles = parentHandles;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes iqinterleavecal_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = iqinterleavecal_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in popupmenuPattern.
function popupmenuPattern_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuPattern (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuPattern contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuPattern


% --- Executes during object creation, after setting all properties.
function popupmenuPattern_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuPattern (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuOptimizer.
function popupmenuOptimizer_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuOptimizer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuOptimizer contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuOptimizer


% --- Executes during object creation, after setting all properties.
function popupmenuOptimizer_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuOptimizer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editParam1_Callback(hObject, eventdata, handles)
% hObject    handle to editParam1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editParam1 as text
%        str2double(get(hObject,'String')) returns contents of editParam1 as a double


% --- Executes during object creation, after setting all properties.
function editParam1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editParam1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editParam2_Callback(hObject, eventdata, handles)
% hObject    handle to editParam2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editParam2 as text
%        str2double(get(hObject,'String')) returns contents of editParam2 as a double


% --- Executes during object creation, after setting all properties.
function editParam2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editParam2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonRun.
function pushbuttonRun_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRun (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
patternList = get(handles.popupmenuPattern, 'String');
patternValue = get(handles.popupmenuPattern, 'Value');
pattern = patternList{patternValue};
optimizerList = get(handles.popupmenuOptimizer, 'String');
optimizerValue = get(handles.popupmenuOptimizer, 'Value');
optimizer = optimizerList{optimizerValue};
% set up parameter structure to call iqinterleavecal()
param.patternValue = patternValue;
param.pattern = pattern;
param.optimizerValue = optimizerValue;
param.optimizer = optimizer;
param.iterations = get(handles.editIterations, 'String');
param.param1 = get(handles.editParam1, 'String');
param.param2 = get(handles.editParam2, 'String');
param.parentHandles = handles.parentHandles;
param.axes = handles.axes1;
iqinterleavecal(param);



function editIterations_Callback(hObject, eventdata, handles)
% hObject    handle to editIterations (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editIterations as text
%        str2double(get(hObject,'String')) returns contents of editIterations as a double


% --- Executes during object creation, after setting all properties.
function editIterations_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editIterations (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
