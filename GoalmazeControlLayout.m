function varargout = GoalmazeControlLayout(varargin)
%   ____             _                          ____            _             _ 
%  / ___| ___   __ _| |_ __ ___   __ _ _______ / ___|___  _ __ | |_ _ __ ___ | |
% | |  _ / _ \ / _` | | '_ ` _ \ / _` |_  / _ \ |   / _ \| '_ \| __| '__/ _ \| |
% | |_| | (_) | (_| | | | | | | | (_| |/ /  __/ |__| (_) | | | | |_| | | (_) | |
%  \____|\___/ \__,_|_|_| |_| |_|\__,_/___\___|\____\___/|_| |_|\__|_|  \___/|_|
%                                                                               
%  _                            _   
% | |    __ _ _   _  ___  _   _| |_ 
% | |   / _` | | | |/ _ \| | | | __|
% | |__| (_| | |_| | (_) | |_| | |_ 
% |_____\__,_|\__, |\___/ \__,_|\__|
%             |___/                 
% GOALMAZECONTROLLAYOUT MATLAB code for GoalmazeControlLayout.fig
%      GOALMAZECONTROLLAYOUT, by itself, creates a new
%      GOALMAZECONTROLLAYOUT or raises the existing singleton*.
%
%      H = GOALMAZECONTROLLAYOUT returns the handle to a new
%      GOALMAZECONTROLLAYOUT or the handle to the existing singleton*.
%
%      GOALMAZECONTROLLAYOUT('CALLBACK',hObject,eventData,handles,...)
%      calls the local function named CALLBACK in GOALMAZECONTROLLAYOUT.M
%      with the given input arguments.
%
%      GOALMAZECONTROLLAYOUT('Property','Value',...) creates a new
%      GOALMAZECONTROLLAYOUT or raises the existing singleton*.  Starting
%      from the left, property value pairs are applied to the GUI before
%      GoalmazeControlLayout_OpeningFcn gets called.  An unrecognized
%      property name or invalid value makes property application stop.  All
%      inputs are passed to GoalmazeControlLayout_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
%
% Edit the above text to modify the response to help GoalmazeControlLayout
%
% Last Modified by GUIDE v2.5 30-Jun-2018 21:00:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GoalmazeControlLayout_OpeningFcn, ...
                   'gui_OutputFcn',  @GoalmazeControlLayout_OutputFcn, ...
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


% --- Executes just before GoalmazeControlLayout is made visible.
function GoalmazeControlLayout_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GoalmazeControlLayout (see VARARGIN)

% Declare the globals from my maze code
global maze const state perf tones

% Add my logo
im=imread('logo.bmp');%im(im>1)=256;
image(handles.axes_logo,im);
colormap(handles.axes_logo,'gray');
handles.axes_logo.Visible='off';

axes_status_CreateFcn(handles.axes_status,[],handles)

% Display the current sequence number
if ~isempty(const) && isfield(const,'sequence')
  handles.constseq_report.String = num2str(const.sequence);
else
  handles.constseq_report.String = 'unset';
end

handles.visualize_notes_printloc = 0;


% Choose default command line output for GoalmazeControlLayout
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

pb_snup_Callback(hObject, [] ,handles);

% UIWAIT makes GoalmazeControlLayout wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GoalmazeControlLayout_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function GoalmzeControlLayout_RecreateObjects()
% 

function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to visualize_notes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of visualize_notes as text
%        str2double(get(hObject,'String')) returns contents of visualize_notes as a double


% --- Executes during object creation, after setting all properties.
function visualize_notes_CreateFcn(hObject, ~, ~)
% hObject    handle to visualize_notes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in toggle_profiler.
function toggle_profiler_Callback(~, ~, ~)
% hObject    handle to toggle_profiler (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global const
if isfield(const.app,'profiler')
  const.app.profiler = ~const.app.profiler;
else
  const.app.profiler=true;
end

if const.app.profiler
  profile on ;
else
  % End profiler if it's on
  status=profile('status');
  if isequal(status.ProfilerStatus,'on')
    profile viewer;
    profile off ; 
    const.app.profiler=false;
  end
end
% Hint: get(hObject,'Value') returns toggle state of toggle_profiler


% --- Executes on button press in listbox_debug.
function listbox_debug_Callback(hObject, ~, ~)
% hObject    handle to listbox_debug (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global const

switch hObject.String{hObject.Value}
  case 'Debugger Off'   
    const.app.debug=[];
    dbclear all;
  case 'RestartStimulus'
    dbstop in goalmaze_cns at restartStimulus
  case 'Plot Perf'
    dbstop in plotmaze
  case 'Correct-Incorrect'
    dbstop in goalmaze_cns at Correct
    dbstop in goalmaze_cns at Incorrect
  case 'Messages'
    keyboard
    const.app.debug='messages';
end

% Hint: get(hObject,'Value') returns toggle state of listbox_debug



function edit_rewarddur_Callback(hObject, ~, ~)
% hObject    handle to edit_rewarddur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_rewarddur as text
%        str2double(get(hObject,'String')) returns contents of edit_rewarddur as a double
global const
sendScQtControlMessage(sprintf('reward_dur=%d',str2num(hObject.String)*1000));
const.reward.dur = str2double(hObject.String);
addtonotes( sprintf('Reward Duration=%s',hObject.String) );

% --- Executes during object creation, after setting all properties.
function edit_rewarddur_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_rewarddur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global const
hObject.String = const.reward.dur;

% --- Executes on slider movement.
function slider_sequence_Callback(hObject, ~, handles)
% hObject    handle to slider_sequence (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global const state;
const.sequence = ceil(hObject.Value);
handles.constseq_report.String = num2str(const.sequence);
state.sequence  = nan(1,const.sequence);
state.sequence_queue = nan(1,const.sequence);
addtonotes( sprintf('Sequence=%d',ceil(hObject.Value)) );

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider_sequence_CreateFcn(hObject, ~, ~)
% hObject    handle to slider_sequence (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

global const;
hObject.Value = const.sequence;

% --- Executes on button press in rb_mode_seq.
function rb_mode_seq_Callback(~, ~, ~)
% hObject    handle to rb_mode_seq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rb_mode_seq


% --- Executes on button press in rb_mode_simultaneous_different.
function rb_mode_simultaneous_different_Callback(~, ~, ~)
% hObject    handle to rb_mode_simultaneous_different (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global const
const.seq.mode = 'differentiate';
% Hint: get(hObject,'Value') returns toggle state of rb_mode_simultaneous_different


% --- Executes on button press in rb_mode_crosson.
function rb_mode_crosson_Callback(hObject, eventdata, handles)
% hObject    handle to rb_mode_crosson (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rb_mode_crosson


% --- Executes on button press in rb_mode_crossof.
function rb_mode_crossof_Callback(hObject, eventdata, handles)
% hObject    handle to rb_mode_crossof (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rb_mode_crossof


% --- Executes on button press in cb_reminder.
function cb_reminder_Callback(hObject, eventdata, handles)
% hObject    handle to cb_reminder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_reminder


% --- Executes on button press in cb_unlimitedstimtime.
function cb_unlimitedstimtime_Callback(hObject, eventdata, handles)
% hObject    handle to cb_unlimitedstimtime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global const
const.unlimitedstimulus = hObject.Value;
sendScQtControlMessage(sprintf('expiration_mode=%d',hObject.Value));

% --- Executes on button press in cb_unlimitedtrialtime.
function cb_unlimitedtrialtime_Callback(hObject, eventdata, handles)
% hObject    handle to cb_unlimitedtrialtime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global const
const.trialtime_inf = hObject.Value;

% --- Executes on button press in pb_save.
function pb_save_Callback(hObject, eventdata, handles)
% hObject    handle to pb_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Get first session name
if ~isfield(handles,'save') || isempty(handles.save.name)
  sessionname = inputdlg('Provide the first session name');
  handles.edit_savename.String = sessionname{1};
  handles.save=[];
  handles.save.name=sessionname{1};
  guidata(hObject,handles);
end
goalmaze_cns(sprintf('0 save %s',handles.save.name));

% --- Executes on button press in pb_toggle_all.
function pb_toggle_all_Callback(hObject, eventdata, handles)
% hObject    handle to pb_toggle_all (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
persistent onstate;
if isempty(onstate)
  goalmaze_cns('0 all on');
  onstate=true;
elseif onstate==true
  goalmaze_cns('0 all off');
  onstate=false;
elseif onstate==false
  goalmaze_cns('0 all on');
  onstate=true;
end

% --- Executes on button press in pb_report.
function pb_report_Callback(hObject, eventdata, handles)
% hObject    handle to pb_report (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
goalmaze_cns('0 report');

% --- Executes on button press in pb_flash.
function pb_flash_Callback(hObject, eventdata, handles)
% hObject    handle to pb_flash (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
goalmaze_cns('0 flash');

% --- Executes on button press in pb_plotmaze.
function pb_plotmaze_Callback(hObject, eventdata, handles)
% hObject    handle to pb_plotmaze (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
goalmaze_cns('0 plotmaze');


function editnotes_Callback(hObject, eventdata, handles)
% hObject    handle to editnotes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editnotes as text
%        str2double(get(hObject,'String')) returns contents of editnotes as a double
global state;
data = guidata(hObject);
if ~isfield(data,'row_print') || ~isfield(data,'row_total')
    data.row_print=5;
    data.row_total=5;
    guidata(hObject,data);
end
row_print = data.row_print;
row_total = data.row_total;
notes = hObject.String;
if ~isempty(notes)
  if ~isfield(state,'sessionnotes');state.sessionnotes=[];end
  state.sessionnotes = char(state.sessionnotes, timemessage(notes));
end
if size(state.sessionnotes,1)>row_print
   start = max(1,size(state.sessionnotes,1)-row_print);
   stop = min(size(state.sessionnotes,1),size(state.sessionnotes,1)-row_print+row_total);
    handles.visualize_notes.String = state.sessionnotes(start:stop,:);
else
  handles.visualize_notes.String = state.sessionnotes;
end
hObject.String=[]; % Clear the edit box


% --- Executes during object creation, after setting all properties.
function editnotes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editnotes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in pb_start.
function pb_start_Callback(hObject, eventdata, handles)
% hObject    handle to pb_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.axes_status.Color = 'green';
goalmaze_cns('0 maze start');

% --- Executes on button press in pb_stop.
function pb_stop_Callback(hObject, eventdata, handles)
% hObject    handle to pb_stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.axes_status.Color = 'red';
goalmaze_cns('0 maze stop');
addtonotes('maze stopped');

% --- Executes on button press in pb_clearstart.
function pb_clearstart_Callback(hObject, eventdata, handles)
% hObject    handle to pb_clearstart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
goalmaze_cns('0 maze clear');
handles.visualize_notes.String='';
handles.editnotes.String='';
readmit(handles); % Any gui edits or buttons that the user changed in the last session, allow them to carry over
goalmaze_cns('0 maze start');
addtonotes('maze cleared and started');

% --- Executes on button press in pb_clear.
function pb_clear_Callback(hObject, eventdata, handles)
% hObject    handle to pb_clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
goalmaze_cns('0 maze clear');
handles.visualize_notes.String='';
handles.editnotes.String='';
readmit(handles); % Any gui edits or buttons that the user changed in the last session, allow them to carry over
addtonotes('maze cleared');



function edit_savename_Callback(hObject, eventdata, handles)
% hObject    handle to edit_savename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_savename as text
%        str2double(get(hObject,'String')) returns contents of edit_savename as a double
h=guidata(hObject);
h.save.name=hObject.String;
guidata(hObject,h);

% --- Executes during object creation, after setting all properties.
function edit_savename_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_savename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit6_Callback(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit6 as text
%        str2double(get(hObject,'String')) returns contents of edit6 as a double

goalmaze_cns(sprintf('0 reward %s',hObject.String));
addtonotes(sprintf('Flipping reward %s',hObject.String));

% --- Executes during object creation, after setting all properties.
function edit6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox11.
function checkbox11_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox11


% --- Executes on button press in checkbox10.
function checkbox10_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox10


% --- Executes on button press in cb_adapton.
function cb_adapton_Callback(hObject, eventdata, handles)
% hObject    handle to cb_adapton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_adapton



function edit_correctlockout_Callback(hObject, eventdata, handles)
% hObject    handle to edit_correctlockout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_correctlockout as text
%        str2double(get(hObject,'String')) returns contents of edit_correctlockout as a double
global const
const.correctpokelockout = str2double(hObject.String);
addtonotes(sprintf('CorrectLockout = %s',hObject.String));

% --- Executes during object creation, after setting all properties.
function edit_correctlockout_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_correctlockout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global const
if ~isempty(const) && isfield(const,'correctpokelockout')
  hObject.String=num2str(const.correctpokelockout);
end

function edit_incorrectlockout_Callback(hObject, eventdata, handles)
% hObject    handle to edit_incorrectlockout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_incorrectlockout as text
%        str2double(get(hObject,'String')) returns contents of edit_incorrectlockout as a double
global const
const.incorrectpokelockout = str2double(hObject.String);
addtonotes(sprintf('IncorrectLockout=%s',hObject.String));

% --- Executes during object creation, after setting all properties.
function edit_incorrectlockout_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_incorrectlockout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global const
if ~isempty(const) && isfield(const,'incorrectpokelockout')
  hObject.String=num2str(const.incorrectpokelockout);
end


function edit_minadapt_Callback(hObject, eventdata, handles)
% hObject    handle to edit_minadapt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global const
% const.cue.adapt.min = 

% Hints: get(hObject,'String') returns contents of edit_minadapt as text
%        str2double(get(hObject,'String')) returns contents of edit_minadapt as a double


% --- Executes during object creation, after setting all properties.
function edit_minadapt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_minadapt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_maxadapt_Callback(hObject, eventdata, handles)
% hObject    handle to edit_maxadapt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_maxadapt as text
%        str2double(get(hObject,'String')) returns contents of edit_maxadapt as a double


% --- Executes during object creation, after setting all properties.
function edit_maxadapt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_maxadapt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_stepadapt_Callback(hObject, eventdata, handles)
% hObject    handle to edit_stepadapt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_stepadapt as text
%        str2double(get(hObject,'String')) returns contents of edit_stepadapt as a double


% --- Executes during object creation, after setting all properties.
function edit_stepadapt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_stepadapt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_initadapt_Callback(hObject, eventdata, handles)
% hObject    handle to edit_initadapt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_initadapt as text
%        str2double(get(hObject,'String')) returns contents of edit_initadapt as a double


% --- Executes during object creation, after setting all properties.
function edit_initadapt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_initadapt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit16_Callback(hObject, eventdata, handles)
% hObject    handle to edit16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit16 as text
%        str2double(get(hObject,'String')) returns contents of edit16 as a double


% --- Executes during object creation, after setting all properties.
function edit16_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_allowedincorrect_Callback(hObject, eventdata, handles)
% hObject    handle to edit_allowedincorrect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_allowedincorrect as text
%        str2double(get(hObject,'String')) returns contents of edit_allowedincorrect as a double
global const
const.train.allowedincorrect = str2double(hObject.String);
addtonotes(sprintf('Allowed Incorrect = %d',str2num(hObject.String)));

% --- Executes during object creation, after setting all properties.
function edit_allowedincorrect_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_allowedincorrect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global const
if isfield(const,'allowedincorrect')
  hObject.String = num2str(const.train.allowedincorrect);
end


function edit_allowedcorrect_Callback(hObject, ~, ~)
% hObject    handle to edit_allowedcorrect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_allowedcorrect as text
%        str2double(get(hObject,'String')) returns contents of edit_allowedcorrect as a double

global const;
const.train.allowedcorrect=str2double(hObject.String);
addtonotes(sprintf('Allowed Correct = %d',str2num(hObject.String)));

% --- Executes during object creation, after setting all properties.
function edit_allowedcorrect_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_allowedcorrect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global const;
hObject.String = num2str(const.train.allowedcorrect);


function edit_blocklockoutperiod_Callback(hObject, ~, ~)
% hObject    handle to edit_blocklockoutperiod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_blocklockoutperiod as text
%        str2double(get(hObject,'String')) returns contents of edit_blocklockoutperiod as a double
global const
const.blocklockout_period = str2double(hObject.String);
sendScQtControlMessage(sprintf('blocklockout_period=%d',const.blocklockout_period*1e3));
addtonotes(sprintf('blocklockout_period=%2.3f',const.blocklockout_period));

% --- Executes during object creation, after setting all properties.
function edit_blocklockoutperiod_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_blocklockoutperiod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global const
if ~isempty(const) && isfield(const,'blocklockout_period')
  hObject.String=num2str(const.blocklockout_period);
end



function edit_seqdelay_Callback(hObject, ~, ~)
% hObject    handle to edit_seqdelay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_seqdelay as text
%        str2double(get(hObject,'String')) returns contents of edit_seqdelay as a double
global const
const.seqdelay = str2double(hObject.String);

% --- Executes during object creation, after setting all properties.
function edit_seqdelay_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_seqdelay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global const
if ~isempty(const)
  hObject.String = num2str(const.seqdelay);
end


% --- Executes on button press in rb_alternation.
function rb_alternation_Callback(hObject, eventdata, handles)
% hObject    handle to rb_alternation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global const


% Hint: get(hObject,'Value') returns toggle state of rb_alternation


% --- Executes on button press in cb_excludelast.
function cb_excludelast_Callback(hObject, ~, ~)
% hObject    handle to cb_excludelast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global const;
const.exclude_currentzone=hObject.Value;
addtonotes('Mode: Exclude previous zone/poke from upcoming pick enabled');

% Hint: get(hObject,'Value') returns toggle state of cb_excludelast


% --- Executes on button press in cb_equalrewards.
function cb_equalrewards_Callback(hObject, ~, ~)
% hObject    handle to cb_equalrewards (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global const
const.reward.equal=hObject.Value;
addtonotes('Reward values equalized across sequence');

% Hint: get(hObject,'Value') returns toggle state of cb_equalrewards



function edit_rewardmult_Callback(hObject, ~, ~)
% hObject    handle to edit_rewardmult (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_rewardmult as text
%        str2double(get(hObject,'String')) returns contents of edit_rewardmult as a double
global const;
const.reward.mult=str2double(hObject.String);
addtonotes(sprintf('RewardMultiplier=%s',hObject.String));

% --- Executes during object creation, after setting all properties.
function edit_rewardmult_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_rewardmult (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global const;
hObject.String = num2str(const.reward.mult);


% --- Executes during object creation, after setting all properties.
function cb_equalrewards_CreateFcn(hObject, ~, ~)
% hObject    handle to cb_equalrewards (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
global const
hObject.Value = const.reward.equal;


% --- Executes on button press in pb_wrong.
function pb_wrong_Callback(~, ~, ~)
% hObject    handle to pb_wrong (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
goalmaze_cns('0 wrong');


% --- Executes on button press in pb_pz.
function pb_pz_Callback(~, ~, ~)
% hObject    handle to pb_pz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global const
const.pokingoff=false;
const.zoningoff=false;
addtonotes(sprintf('Poke- and zone-driven selection allowed'));

% Hint: get(hObject,'Value') returns toggle state of pb_pz


% --- Executes during object creation, after setting all properties.
function pb_pz_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pb_pz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

function ts_message = timemessage(message)
% This is a special function that appends a time stamp to the beginning of
% the message. It's used for my experiment logging, so that I can have near
% precise timing of the messages that I'm dropping in my notes.
% Pass in MESSAGE and it uses SCQTCONTROLLEROUTPUT to lookup the most recent
% timestamp. It outputs TS_MESSAGE, the timestamped message.
global scQtControllerOutput
try % Look for the last time stamp and take that
  recent_time = strtok(scQtControllerOutput{end});
  index = 0; nEntries=numel(scQtControllerOutput);
  while ~any(isstrprop(recent_time,'digit')) && index < nEntries
    index=index+1;
    recent_time = strtok(scQtControllerOutput{end-index});
  end
catch ME; recent_time = '0'; end
ts_message = sprintf('%s %s', recent_time,message);

function addtonotes(newstr)
  global state;
  if isfield(state,'sessionnotes')
    state.sessionnotes = char(state.sessionnotes,timemessage(newstr));
  else
    state.sessionnotes = timemessage(newstr);
  end

% Function Object list (for the purposes of re-admitting session options
% after clear)
function readmit(handles)
% Reruns callbacks to reinject gui values into the goalmaze code after a
% clear command has been issued.

objs = {...
  'slider_sequence','edit_seqdelay'...
  ,'cb_unlimitedstimtime','cb_unlimitedtrialtime',...
  'edit_rewarddur',...
  'cb_homezone','cb_hzeachtrial','homezonetrial','edit_hzmult',...
  'edit_rewardmult','edit_correctlockout','edit_incorrectlockout',...
  'edit_blocklockoutperiod','edit_allowedcorrect','edit_allowedincorrect',...
  'wmflag','edit_wmup','edit_wmdown','wmmax','wmmin',...
  'cb_homezone','cb_nextstimzone','cb_hzeachtrial',...
  'rb_crosson','rb_crossoff','rb_alternation','cb_adaption','cb_minadapt',...
  'cb_maxadapt','cb_stepadapt','cb_initadapt','cb_equalreward','rb_p','rb_z','rb_pz'
  };

h=guidata(handles.(objs{1}));
try 
  readmitted=[];
  for o = objs,o=o{1};
    eval(sprintf('%s_Callback(h.(''%s''),[],h);',o,o));
    %eval(sprintf('guidata(h.(''%s'').h',o));
    readmitted = [readmitted ' ' o];
  end
catch ME
  o=cast(o,'char');
  warndlg(sprintf('Readmission process skipping gui objects after %s\n\n-------Successfully injected-------\n%s.',o,readmitted),'GUI Readmission');
end
mazemodegroup_SelectionChangedFcn([],[],handles);

function flashobject(hObject)

function restore(origcolor)

function edit_eval_Callback(hObject, eventdata, handles)
% hObject    handle to edit_eval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_eval as text
%        str2double(get(hObject,'String')) returns contents of edit_eval as a double
goalmaze_cns(['0 eval ' hObject.String]);
hObject.String=[];

% --- Executes during object creation, after setting all properties.
function edit_eval_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_eval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over visualize_notes.
function visualize_notes_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to visualize_notes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function edit_wl_Callback(hObject, ~, ~)
% hObject    handle to edit_wl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isunix; eval(['!echo "' hObject.String '" >> feature_wishlist.txt']); end
hObject.String=[];

% Hints: get(hObject,'String') returns contents of edit_wl as text
%        str2double(get(hObject,'String')) returns contents of edit_wl as a double


% --- Executes during object creation, after setting all properties.
function edit_wl_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_wl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cb_nextstimzone.
function cb_nextstimzone_Callback(hObject, ~, ~)
% hObject    handle to cb_nextstimzone (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global const
const.nextstim_zonecross = hObject.Value;

% --- Executes on button press in cb_homezone.
function cb_homezone_Callback(hObject, ~, ~)
% hObject    handle to cb_homezone (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global const
const.resetzone_after_blocklockout = hObject.Value;

% --- Executes on button press in cb_discourageshort.
function cb_discourageshort_Callback(hObject, ~, ~)
% hObject    handle to cb_discourageshort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global const
const.train.discourage_short_of_pair_first = hObject.Value;
addtonotes('Mode: discourageshortdistance=enabled');

% Hint: get(hObject,'Value') returns toggle state of cb_discourageshort


% --- Executes during object creation, after setting all properties.
function cb_homezone_CreateFcn(hObject, ~, ~)
% hObject    handle to cb_homezone (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
global const
hObject.Value = const.resetzone_after_blocklockout;


% --- Executes during object creation, after setting all properties.
function cb_nextstimzone_CreateFcn(hObject, ~, ~)
% hObject    handle to cb_nextstimzone (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
global const
hObject.Value = const.nextstim_zonecross;


% --- Executes on button press in rb_z.
function rb_z_Callback(~, ~, ~)
% hObject    handle to rb_z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global const
const.zoningoff=false;
const.pokingoff=true;
addtonotes(sprintf('Only zone-driven selection allowed'));

% Hint: get(hObject,'Value') returns toggle state of rb_z


% --- Executes on button press in rb_p.
function rb_p_Callback(~, ~, ~)
% hObject    handle to rb_p (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global const
const.zoningoff=true;
const.pokingoff=false;
addtonotes(sprintf('Only poke-driven selection allowed'));

% Hint: get(hObject,'Value') returns toggle state of rb_p


% --- Executes on selection change in listbox2.
function listbox2_Callback(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox2


% --- Executes during object creation, after setting all properties.
function listbox2_CreateFcn(hObject, ~, ~)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in cb_hzeachtrial.
function cb_hzeachtrial_Callback(hObject, ~, handles)
% hObject    handle to cb_hzeachtrial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global const maze state
const.home.on = hObject.Value;
if ~const.home.on
  goalmaze_cns('eval setnormal');
  const.trialtype{1} = 'normal';
  handles.currNstim.ForegroundColor = 'red';
  handles.currNstim.String = sprintf('Off');
  if state.gostate
      goalmaze_cns('0 errorlockout false');
      goalmaze_cns(sprintf('0 restart %d %s',randsample(maze.normal,1),'normal'));
  end
else 
  state.home.currNstim = 0;
  handles.currNstim.ForegroundColor = [.85 .38 .1];
  handles.currNstim.String = sprintf('Home\nTrial');
  if state.gostate
      goalmaze_cns('0 errorlockout false');
      goalmaze_cns(sprintf('0 restart %d %s',maze.home,'home'));
  else
    goalmaze_cns('eval setnormal');
    state.trialtype{1} = 'normal';
    state.home.currNstim =  const.home.everyNstim+100;
  end
end
% Hint: get(hObject,'Value') returns toggle state of cb_hzeachtrial


% --- Executes on mouse press over axes background.
function axes_datestr_ButtonDownFcn(hObject, ~, ~)
% hObject    handle to axes_datestr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
answer = inputdlg('Which F1 Axis?','Axis Choice');
answer = answer(1);
f=sfigure(1);
copyobj(f.Children(answer),hObject);


% --- Executes during object creation, after setting all properties.
function cb_hzeachtrial_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cb_hzeachtrial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
global const
hObject.Value = const.home.on;


% --- Executes during object creation, after setting all properties.
function tagversion_CreateFcn(hObject, ~, ~)
% hObject    handle to tagversion (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
global const
hObject.String = sprintf('Version %s\nCommit %s',const.app.version,const.app.commit);


% --- Executes during object creation, after setting all properties.
function mazemodegroup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mazemodegroup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% global const
% switch const.seq.mode
%   case 'crosson'
%       hObject.SelectedObject.String = 'Cross On (Zone)';
%   case 'crossoff'
%       hObject.SelectedObject.String = 'Cross Off (Zone)';
%   case 'alternate'
%       hObject.SelectedObject.String= 'Alternation';
%   case 'differentiate'
%       hObject.SelectedObject.String = 'Simultaneous Different';
%   case 'simultaneous'
%       hObject.SelectedObject.String= 'Simultaneous Same';
% end

% --- Executes when entered data in editable cell(s) in AdaptionTable.
function AdaptionTable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to AdaptionTable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
global const
for i = 1:numel(eventdata.NewData)
  
  switch eventdata.Indices(i,1)
  case 1 % working memory
    field = 'wm';
  case 2    
    field = 'kk';
  end
  
  switch eventdata.Indices(i,2)
  case 1
    const.(field).flag = eventdata.NewData(i);
    handles.AdaptionTable.UserData;
  case 2
    const.(field).init = eventdata.NewData(i);
  case 3
    const.(field).min = eventdata.NewData(i);
  case 4   
    const.(field).max = eventdata.NewData(i);
  end
  
  drawnow;
  
end

% --- Executes during object creation, after setting all properties.
function wmflag_CreateFcn(hObject, eventdata, handles)
% hObject    handle to wmflag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
global const
hObject.Value = const.adapt.wm.flag;
% if const.adapt.wm.flag
%     handles.cb_unlimitedstimtime.Value = false;
%     const.unlimitedstimulus = false;
%     sendScQtControlMessage(sprintf('expiration_mode=%d',0));
% else
%     const.unlimitedstimulus = true;
%     handles.cb_unlimitedstimtime.Value = true;
%     sendScQtControlMessage(sprintf('expiration_mode=%d',1));
% end

% --- Executes on button press in wmflag.
function wmflag_Callback(hObject, eventdata, handles)
% hObject    handle to wmflag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of wmflag
global const
const.adapt.wm.flag= hObject.Value;
if const.adapt.wm.flag
  global state
  handles.wmvalue.ForegroundColor = [.85 .38 .1];
  handles.wmvalue.String = sprintf('%2.1f',state.adapt.wm/1e3);
  % const.unlimitedstimulus = false;
  % handles.cb_unlimitedstimtime.Value = false;
  % sendScQtControlMessage(sprintf('expiration_mode=%d',0));
else
  handles.wmvalue.ForegroundColor = 'red';
  handles.wmvalue.String = 'Off';
  % const.unlimitedstimulus = true;
  % handles.cb_unlimitedstimtime.Value = true;
  % sendScQtControlMessage(sprintf('expiration_mode=%d',1));
end


function wminit_Callback(hObject, eventdata, handles)
% hObject    handle to wminit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of wminit as text
%        str2double(get(hObject,'String')) returns contents of wminit as a double
global const state
const.adapt.wm.init = str2double(hObject.String)*1e3;
state.adapt.wm = const.adapt.wm.init;
if const.adapt.wm.flag
  handles.wmvalue.String  = [hObject.String ' sec'];
else
  handles.wmvalue.String  = ['off'];
end

  

% --- Executes during object creation, after setting all properties.
function wminit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to wminit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global const
hObject.String = num2str(const.adapt.wm.init/1e3);


function wmmin_Callback(hObject, eventdata, handles)
% hObject    handle to wmmin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of wmmin as text
%        str2double(get(hObject,'String')) returns contents of wmmin as a double
global const
const.adapt.wm.min = str2double(hObject.String)*1e3;


% --- Executes during object creation, after setting all properties.
function wmmin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to wmmin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global const
hObject.String = num2str(const.adapt.wm.min/1e3);


function wmmax_Callback(hObject, eventdata, handles)
% hObject    handle to wmmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of wmmax as text
%        str2double(get(hObject,'String')) returns contents of wmmax as a double
global const
const.adapt.wm.max = str2double(hObject.String)*1e3;

% --- Executes during object creation, after setting all properties.
function wmmax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to wmmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global const
hObject.String = num2str(const.adapt.wm.max/1e3);


% --- Executes during object creation, after setting all properties.
function cb_unlimitedtrialtime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cb_unlimitedtrialtime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
global const
hObject.Value = const.trialtime_inf;


% --- Executes during object creation, after setting all properties.
function cb_unlimitedstimtime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cb_unlimitedstimtime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
global const
hObject.Value = const.unlimitedstimulus;
addtonotes(sprintf('Unlimited Stim Mode = %d',const.unlimitedstimulus));
handles.wmflag.Value = hObject.Value;


% --- Executes during object creation, after setting all properties.
function wmvalue_CreateFcn(hObject, eventdata, handles)
% hObject    handle to wmvalue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
global state
hObject.String = state.adapt.wm;


function homezonetrial_Callback(hObject, eventdata, handles)
% hObject    handle to homezonetrial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global const
const.home.everyNstim = str2double(hObject.String);

% --- Executes during object creation, after setting all properties.
function homezonetrial_CreateFcn(hObject, eventdata, handles)
% hObject    handle to homezonetrial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global const
hObject.String = num2str(const.home.everyNstim);


% --- Executes during object creation, after setting all properties.
function axes_status_CreateFcn(hObject, eventdata, handles)
% hObject    handle to statusaxes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
axes(hObject);
p=patch(0,0,'white');
p.EdgeAlpha=1;
p.FaceAlpha=1;
hObject.Color = 'red';
xticks(hObject,[]);
yticks(hObject,[]);

function axes_logo_CreateFcn(hObject,eventdata,handles)


% --- Executes during object creation, after setting all properties.
function currNstim_CreateFcn(hObject, eventdata, handles)
% hObject    handle to currNstim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
global state
hObject.String = 'trial count';


% --- Executes on selection change in specialtraining.
function specialtraining_Callback(hObject, eventdata, handles)
% hObject    handle to specialtraining (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns specialtraining contents as cell array
%        contents{get(hObject,'Value')} returns selected item from specialtraining
global const
map = {...
  'patternbreak','Pattern Break'; ...
  'weightdistance','Weight Distance'; ...
  'weightperf','Weight Performance';...
  'flashremind','Reminder Stimulus';...
  'excprev','Exclude Previous Stimulus'...
};
ons = hObject.Value;
offs = setdiff(1:size(map,1),ons);
message = [];
for v = ons
  const.train.(map{v,1}) = true;
  message = sprintf('%s %s = %d;',message,map{v,2},true);
end
for v = offs
  const.train.(map{v,1}) = false;
  message = sprintf('%s %s = %d;',message,map{v,2},false);
end
addtonotes(message);


% --- Executes during object creation, after setting all properties.
function specialtraining_CreateFcn(hObject, eventdata, handles)
% hObject    handle to specialtraining (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
global const
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
map = {...
  'patternbreak','Pattern Break'; ...
  'weightdistance','Weight Distance'; ...
  'weightperf','Weight Performance';...
  'flashremind','Reminder Stimulus';...
  'excprev','Exclude Previous Stimulus'...
};
message=[];
hObject.Value = [];
for m = map'
  if const.train.(m{1})
    position=find(ismember(hObject.String,m{2}));
    if ~(position <= 1 || position > numel(hObject.String))
      hObject.Value = [hObject.Value position'];
      message = sprintf('%s %s = %d;',message,map{position,2},true);
    end
  else
    position=find(ismember(hObject.String,m{2}));
    if ~(position <= 1 || position > numel(hObject.String))
      message = sprintf('%s %s = %d;',message,map{position,2},false);
    end
  end
end
addtonotes(message);

% --- Executes on button press in cb_homeerror.
function cb_homeerror_Callback(hObject, eventdata, handles)
% hObject    handle to cb_homeerror (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_homeerror
global const
const.home.error = hObject.Value;


function edit_homeerrorafter_Callback(hObject, eventdata, handles)
% hObject    handle to edit_homeerrorafter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_homeerrorafter as text
%        str2double(get(hObject,'String')) returns contents of edit_homeerrorafter as a double


% --- Executes during object creation, after setting all properties.
function edit_homeerrorafter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_homeerrorafter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in checkbox28.
function checkbox28_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox28 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox28



function edit_wmup_Callback(hObject, eventdata, handles)
% hObject    handle to edit_wmup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_wmup as text
%        str2double(get(hObject,'String')) returns contents of edit_wmup as a double
global const
const.adapt.wm.stepup = str2double(hObject.String);

% --- Executes during object creation, after setting all properties.
function edit_wmup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_wmup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global const
hObject.String = num2str(const.adapt.wm.stepup);



function edit_wmdown_Callback(hObject, eventdata, handles)
% hObject    handle to edit_wmdown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_wmdown as text
%        str2double(get(hObject,'String')) returns contents of edit_wmdown as a double
global const
const.adapt.wm.stepdown = str2double(hObject.String);

% --- Executes during object creation, after setting all properties.
function edit_wmdown_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_wmdown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global const
hObject.String = num2str(const.adapt.wm.stepdown);


% --- Executes on button press in pb_initreminder.
function pb_initreminder_Callback(hObject, eventdata, handles)
% hObject    handle to pb_initreminder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global state
light = state.sequence_queue(1);
sendScQtControlMessage(sprintf('light=%d',light));
sendScQtControlMessage('trigger(14)');

% --- Executes on button press in pb_homewelltog.
function pb_homewelltog_Callback(hObject, eventdata, handles)
% hObject    handle to pb_homewelltog (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global maze
sendScQtControlMessage(sprintf('portout[%d]=flip',maze.leds(maze.home)));


% --- Executes when selected object is changed in mazemodegroup.
function mazemodegroup_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in mazemodegroup 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global const

% --- If no hboject, being called from another object, search handles for the proper text --- 
if isempty(hObject)
    hObject.String = handles.mazemodegroup.SelectedObject.String;
end

% --- Set Mode --- 
switch hObject.String
    case 'Show sequential'
        const.seq.mode = 'normal';
        const.seq.stim = [11 11];
        sendScQtControlMessage('ir_stim_to_terminate=11')
        addtonotes('Mode = Sequential');
    case 'Show simultaneous, different lighting'
        const.seq.mode = 'differentiate';
        const.seq.stim = [11 17];
        addtonotes('Mode=Simultaneous');
    case 'Show simultaneous, same lighting'
        const.seq.stim = [11 11];
        cons.seq.mode = 'simultaneous';
        sendScQtControlMessage('ir_stim_to_terminate=11')
    case 'Stim on zone cross'
        const.seq.stim = [11 17];
        const.seq.mode = 'crosson';
        addtonotes('Mode=CrossOn');
    case 'Stim off zone cross'
        const.seq.mode = 'crossoff';
        const.seq.stim = [11 17];
        addtonotes('Mode=CrossOff');
    case 'Well alternation'
        const.seq.stim = [nan nan];
        const.seq.mode = 'alternate';
    case 'Cue trial then memory trial'
        const.seq.stim = [11, 17];
        const.seq.mode = 'cuememory';
        sendScQtControlMessage('ir_stim_to_terminate=17')
    otherwise
        error(sprintf('%s does not match any options',hObject.String),'Invalid selection');
end


function edit_hzmult_Callback(hObject, ~, ~)
% hObject    handle to edit_hzmult (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_hzmult as text
%        str2double(get(hObject,'String')) returns contents of edit_hzmult as a double
global const
const.home.multiplier = str2double(hObject.String);

% --- Executes during object creation, after setting all properties.
function edit_hzmult_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_hzmult (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global const
hObject.String = num2str(const.home.multiplier);


% --- Executes on button press in trialirbeam.
function trialirbeam_Callback(hObject, eventdata, handles)
% hObject    handle to trialirbeam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of trialirbeam
global const
if hObject.Value
    const.adapt.wm.control = 'irbeam';
    if strcmp(const.adapt.wm.controlimp,'statescript')
        sendScQtControlMessage('terminal_ir_mode=1');
    end
else
    const.adapt.wm.control = 'none';
    sendScQtControlMessage('terminal_ir_mode=0');
end
addtonotes(sprintf('controlir_beam=%d',hObject.Value));

% --- Executes during object creation, after setting all properties.
function trialirbeam_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trialirbeam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
global const
if strcmp(const.adapt.wm.control,'irbeam')
    hObject.Value = true;
else
    hObject.Value = false;
end
hObject.TooltipString = sprintf('On - Stimulus timer determined by ir beam cross.\nOff - Stimulus timer determined by beginning of stimulus');



% --- Executes on button press in pb_resetperf.
function pb_resetperf_Callback(hObject, eventdata, handles)
% hObject    handle to pb_resetperf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
goalmaze_cns('0 eval ResetPerf()');


% --- Executes on button press in cb_plottoggle.
function cb_plottoggle_Callback(hObject, eventdata, handles)
% hObject    handle to cb_plottoggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_plottoggle
global const
const.ploton = hObject.Value;


% --- Executes during object creation, after setting all properties.
function cb_plottoggle_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cb_plottoggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
global const
hObject.Value = const.ploton;


% --- Executes during object creation, after setting all properties.
function cb_homeerror_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cb_homeerror (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
global const
hObject.Value = const.home.error;



function edit_nextinstruction_Callback(hObject, eventdata, handles)
% hObject    handle to edit_nextinstruction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_nextinstruction as text
%        str2double(get(hObject,'String')) returns contents of edit_nextinstruction as a double
global state;
state.preload_instruction = str2num(hObject.String);
hObject.BackgroundColor = 'green';
hObject.ForegroundColor = 'white';

% --- Executes during object creation, after setting all properties.
function edit_nextinstruction_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_nextinstruction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_snup.
function pb_snup_Callback(hObject, eventdata, handles)
% hObject    handle to pb_snup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
stride = 2;
data = guidata(handles.editnotes);
if ~isfield(data,'row_print') || ~isfield(data,'row_total')
  data.row_print = 5;
  data.row_total = 5;
end
data.row_print = data.row_print + stride;
guidata(handles.editnotes,data);
editnotes_Callback(handles.editnotes,eventdata,handles)

% --- Executes on button press in pb_sndown.
function pb_sndown_Callback(hObject, eventdata, handles)
% hObject    handle to pb_sndown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
stride = 2;
data = guidata(handles.editnotes);
if ~isfield(data,'row_print')
  data.row_print = 0;
else
  data.row_print = data.row_print - stride;
end

guidata(handles.editnotes,data);
editnotes_Callback(handles.editnotes,eventdata,handles)


% --- Executes on button press in cb_errorperflag.
function cb_errorperflag_Callback(hObject, eventdata, handles)
% hObject    handle to cb_errorperflag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global const;
const.adapt.blocklockout.flag = hObject.Value;



function edit38_Callback(hObject, eventdata, handles)
% hObject    handle to edit38 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit38 as text
%        str2double(get(hObject,'String')) returns contents of edit38 as a double


% --- Executes during object creation, after setting all properties.
function edit38_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit38 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit39_Callback(hObject, eventdata, handles)
% hObject    handle to edit39 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit39 as text
%        str2double(get(hObject,'String')) returns contents of edit39 as a double


% --- Executes during object creation, after setting all properties.
function edit39_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit39 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit40_Callback(hObject, eventdata, handles)
% hObject    handle to edit40 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit40 as text
%        str2double(get(hObject,'String')) returns contents of edit40 as a double


% --- Executes during object creation, after setting all properties.
function edit40_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit40 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit41_Callback(hObject, eventdata, handles)
% hObject    handle to edit41 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit41 as text
%        str2double(get(hObject,'String')) returns contents of edit41 as a double


% --- Executes during object creation, after setting all properties.
function edit41_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit41 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit42_Callback(hObject, eventdata, handles)
% hObject    handle to edit42 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit42 as text
%        str2double(get(hObject,'String')) returns contents of edit42 as a double


% --- Executes during object creation, after setting all properties.
function edit42_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit42 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in tgl_manhomeir.
function tgl_manhomeir_Callback(hObject, eventdata, handles)
% hObject    handle to tgl_manhomeir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global state
state.manual_homeir = hObject.Value;


% --- Executes during object creation, after setting all properties.
function tgl_manhomeir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tgl_manhomeir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
global state
hObject.Value = state.manual_homeir;


% --------------------------------------------------------------------
function file_Callback(hObject, eventdata, handles)
% hObject    handle to file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton19.
function pushbutton19_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function cb_errorperflag_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cb_errorperflag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
global const
hObject.Value = const.adapt.blocklockout.flag;


% --- Executes on button press in radiobutton16.
function radiobutton16_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton16

function pb_snup_CreateFcn(~,~,~)
