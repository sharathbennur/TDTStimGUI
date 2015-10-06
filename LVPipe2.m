function varargout = LVPipe2(varargin)
% LVPipe2 MATLAB code for LVPipe2.fig
%      LVPipe2, by itself, creates a new LVPipe2 or raises the existing
%      singleton*.
%
%      H = LVPipe2 returns the handle to a new LVPipe2 or the handle to
%      the existing singleton*.
%
%      LVPipe2('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVPipe2.M with the given input arguments.
%
%      LVPipe2('Property','Value',...) creates a new LVPipe2 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before LVPipe2_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to LVPipe2_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
% NOTE: TDT's activex controls only work with 32-BIT Matlab (Sep 2011)

% Edit the above text to modify the response to help LVPipe2

% Last Modified by GUIDE v2.5 15-Jul-2011 14:59:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @LVPipe2_OpeningFcn, ...
                   'gui_OutputFcn',  @LVPipe2_OutputFcn, ...
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


% --- Executes just before LVPipe2 is made visible.
function LVPipe2_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to LVPipe2 (see VARARGIN)

% Choose default command line output for LVPipe2
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

global s1;

% setup
% if old, delete
oldS = instrfind('Port','COM1');
if ~isempty(oldS)
    disp('COM1 in use. Closing..')
    delete(oldS);
    clear oldS;
end

% Initialize Serial Port, make appropriate COM channel
s1 = serial('COM1',...
    'BaudRate',9600,...
    'timeout',10,...
    'inputbuffersize',2048,...
    'Terminator', 'CR/LF');

% UIWAIT makes LVPipe2 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = LVPipe2_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in stop_button.
function stop_button_Callback(hObject, eventdata, handles)
% hObject    handle to stop_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global TDT;
global s1;
FN = TDT.fns{TDT.evalfn};

%toggle the flag variable so that the other process will stop
set(handles.start_button,'UserData',0);
if strcmp(FN,'runToneNoise') || strcmp(FN,'runTone')
    % close all
    disp('Closing Serial, Stopped..')
    fclose(s1);
    TDT.NT = 0;
    % update number of trials
    set(handles.counter_text,'String',num2str(TDT.NT));
end
% end
guidata(hObject, handles);

% --- Executes on button press in start_button.
function start_button_Callback(hObject, eventdata, handles)
% hObject    handle to start_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%initialize the flag variable
set(handles.start_button,'UserData',1);
global s1;
global TDT;
FN = TDT.fns{TDT.evalfn};

if strcmp(FN,'runToneNoise') || strcmp(FN,'runTone')
    % open get data and do stuff
    fopen(s1);
    disp('Opening Serial, Started..')
end
    
% while the flag variable is one, the loop continues
while (get(handles.start_button,'UserData')==1)
    if strcmp(FN,'runToneNoise')
        % if there is data
        if (get(s1,'BytesAvailable')~=0)
            btag = fgetl(s1);
            disp(btag)
            feval(FN,btag);
            % update number of trials
            set(handles.counter_text,'String',num2str(TDT.NT));
        end
    elseif strcmp(FN,'runTone')
        % if there is data
        if (get(s1,'BytesAvailable')~=0)
            btag = fgetl(s1);
            disp(btag)
            feval(FN,btag);
            % update number of trials
            set(handles.counter_text,'String',num2str(TDT.NT));
        end
    else
        d = feval(FN);
        if d==1
            set(handles.start_button,'UserData',0);
        end
    end
        %"flushes the event queue" and updates the figure window
        %since Matlab is a single thread process, this command is requierd
        drawnow;
end

guidata(hObject, handles);

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global TDT;
global s1;

% delete stuff
if exist('s1','var')
    delete(s1);
    clear global s1;
    TDT.haltTDT;
    clear global TDT;
else
    disp('Already Stopped');
end

% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Executes on selection change in fn_pick.
function fn_pick_Callback(hObject, eventdata, handles)
% hObject    handle to fn_pick (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns fn_pick contents as cell array
%        contents{get(hObject,'Value')} returns selected item from fn_pick
global TDT;
TDT.evalfn = get(hObject,'Value');

% Now run the correct circuit
TDT.runTDT;

% --- Executes during object creation, after setting all properties.
function fn_pick_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fn_pick (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
global TDT;
TDT = PipeTDT2('C:\TDT\RPvdsEx\');

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% setup TDT
A = TDT.fns(1:numel(TDT.fns)/2);
% disp(A(1))
set(hObject,'String',A);
