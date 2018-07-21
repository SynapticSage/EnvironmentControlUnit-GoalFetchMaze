function goalmaze_cns(newline)
%   ____             _                         
%  / ___| ___   __ _| |_ __ ___   __ _ _______ 
% | |  _ / _ \ / _` | | '_ ` _ \ / _` |_  / _ \
% | |_| | (_) | (_| | | | | | | | (_| |/ /  __/
%  \____|\___/ \__,_|_|_| |_| |_|\__,_/___\___|
%                                              
%   ____  __       _   _       _     ____            _   _           __  
%  / /  \/  | __ _| |_| | __ _| |__ |  _ \ ___  _ __| |_(_) ___  _ __\ \ 
% | || |\/| |/ _` | __| |/ _` | '_ \| |_) / _ \| '__| __| |/ _ \| '_ \| |
% | || |  | | (_| | |_| | (_| | |_) |  __/ (_) | |  | |_| | (_) | | | | |
% | ||_|  |_|\__,_|\__|_|\__,_|_.__/|_|   \___/|_|   \__|_|\___/|_| |_| |
%  \_\                                                               /_/ 
% This is a different breed of statescript code that runs in Matlab, like
% L Frank suggested for Statescript in Python, but Matlab.
%
% This is the _CNS portion, in that is is like the central nervous system, or the brains of the operation. The _PNS .sc portion are like the limbs/musculature used by this code to interact with the maze.

% Function Shortcuts (highlight the text and us ctrl+D to navigate)
% -------------------
% SetParameters
% RestartStimulus
%
% ParseStatescriptMessages
% ParseCommands
% Correct
% Incorrect
%
%
% FEATURES NEEDED
% ------------------
%
% - Block version of cue - memory training
% - More unified performance table
% - Auto plotting of unique slices of performance
%   characteristics
% - Better gui menu for mode selection, like a popup menu
%   (gui master becoming too cluttered)
%
% Consult wishlist.txt

  %% ---------------- (A) Preprocessing ----------------

  % ---- Statescript QT Callback Variables ----
  %Required global variables
  global goalinit pokeinit 
  % ---- Local Callback Variables ----
  global maze const state perf tones;
  
  %debug = ''; % {'ci','restart','plotmaze','plotmaze_error'}
  %const.app.debug=debug;

  % ---- Initialize Maze Variables and Logic? ----
  if nargin==0 && isempty(goalinit)

    fprintf('INITIALIZING');

    SetParameters();
    ReinstateGui();

    [Y,Fs] = audioread('error.wav');
    tones  = audioplayer(Y,Fs);
    
    % STARTUP
    fprintf('Startup delay = %d seconds\n',const.dur.start);
    pause(const.dur.start);
    if state.gostate; restartStimulus([],{'home','cue'}); else; sendScQtControlMessage('disp(''disp start maze ... with semi-colon terminator to initiate maze'')'); end

    % We inititalized!
    goalinit = true;
    pokeinit = false;

    set(0,'defaultAxesFontSize',12);
    f=figure(1);clf;
    sz=get(0,'screensize');
    f.Position = [sz(1:2) sz(3)/2 sz(4)/2];
    return
  end

  % If no message fed into this function return immediately
  try if isempty(newline) ||  isequal(strtrim(newline), '~~~') || isempty(goalinit) || ~goalinit; return; end; catch; return; end
  originalnewline = newline;
  newline = originalnewline;

  % Consume any alphanumeric characters, e.g. Error: or SCQT: that can
  % proceed a time
  [tok, ~] = strtok(newline,' ');
  if any(isstrprop(tok(1:end),'alpha')), return; end
  %keyboard;

  %% ---------------- (B) PARSE Statescript/Commands ----------------
  % Get current time & process
  [currtime,newline] = scclock(newline);
  if ~pokeinit; pokeinit=true; end

  % ----------------------------------------------------------------------
  % String commands or DIO state change?
  state.maze.id    = [];
  state.maze.onoff = [];
  zone             = [];
  din              = [];  dout   = []; % Initialize din dout (just in case they're not later)
  fdin             = [];  %infdin = []; 
  hasstring        = any(isstrprop(newline(2:end),'alpha'));
  if hasstring % Command/Message

      %% --- PARSE USER COMMANDS and STATESCRIPT-2-MATLAB messages --------
      [newline,rem] = strtok(newline);

      % Goal maze commands (user inputs and things happen)
      ParseCommands(newline,rem)
      if state.gostate == false; fprintf('maze=off '); return; end % if the maze has been issued a pause command at the statescript console by the user, pause the maze execution

      % Commands from statescript to the matlab brains
      exitRequested = ParseStatescriptMessages(newline);
      if exitRequested; return; end

  else % DIO state change

    %% ACQUIRE DIO
    % -----------------------------------------------------------------------
     if ~const.pokingoff % Zone only mode
        [din,dout,newline] = portstate(newline);
        if (sum(din) || sum(dout)) && ~isempty(const.app.debug)
            fprintf('din=%s .. dout=%s\n',num2str(din),num2str(dout));
        end
        if const.app.stimdoutcheck && state.gostate
          stimulusDoutCheck(dout);
        end
        if state.manual_homeir
            din(maze.homeirbeam) = true;
        end
        % make list of dins on
        fdin = find(din);
        % make list of din inputs on
        %infdin = fdin(ismember(fdin,maze.inputs));
        state.platforms = platform(din, 'find');
        state.input = fdin; 
        state.output = find(dout); 
      end
  end
  %if const.pokingoff ; din = []; end % if the nose poke input options is set to "off", we apply that effect here, by wiping digital input set

  if const.app.stimdoutcheck && state.gostate
    trialchecksum()
  end

  %% Post-string Exit Conditions
  % -----------------------------------------------------------------------
  guiUpdate();
  if state.gostate == false; fprintf('maze=off '); return; end
  if isempty(din) || const.resetzone_after_blocklockout && state.afterblocklockout; return; end % apprently, even is hasstring is false, sometimes else condition cannot find port info, so we need to exit if we
  %% Continue on to processing location?

  % Are we in a blockmode lockout?
  if state.blocklockout
    %pokeHappened_upstate=~isempty(state.maze.id) && state.maze.onoff==1;
    %TODO  Figure out why the above condition doesn't work
    pokeHappened_upstate = any(state.platforms);
    notHomewell = ~din(maze.home);
    if pokeHappened_upstate && notHomewell
      blocklockout(true);
      recordperformance('errlockout');
      if const.ploton
        plotmaze(perf,maze,state);
      else
         calcPctCorr();
      end
    end
    fprintf('blocklockout'); return;
  end
  % Is there a zone or an input?
  if ~sum(din) && ~sum(zone); return; end
  % Is there at least no string left if zone has been processed?
  if ~isempty(newline) && ~isempty(zone); return; end % IF THERE IS A STRING LEFT AFTER READING THE PORTS (and zone strings have not been processed), exit ..
  %assert(~isempty(state.sequence_queue),'Instruction set should not be empty as at this point');

  %% ------------ (C) PROCESS INPUTS? ---------
  % -----------------------------------------------------------------------
  processInputs = (~hasstring || ~isempty(zone)); % When to check for state or zone changes!
  if processInputs
    
    debugmessage('\nProcessing: trialtype=(''%s %s'')', state.trialtype{:});

    % Non well events?
    potentialNonWellTriggers();
      
    % Well events
    if ~inLockout()
      % ---- Debug Triggers --------
        debugmessage('\nLockout: ')
        debugmessage('...not in lockout...input detected...'); 
        debugmessage('din = %s -- dout = %s, zone=%s .... ',num2str(din),num2str(dout),num2str(zone)); 
        %assert(~isempty(state.sequence_queue));
      % ---- Test Correct or Incorrect --------
      if decideIfSkip()
      else
        if decideIfRight(),     Correct();
        elseif decideIfWrong(), Incorrect();
        else,                   potentialTimeExtension(); %FIXME time extension can occur if decideIfRight runs while state.sequence_queue is nan or empty
        end
      end % decideIfSkip
    else
        potentialTimeExtension()
    end % -- end lockout thread

    % Ensure that statescript hasn't fucked up my stimuli, cutting them off
    stimuluschecksum()

  end % -- end location process

% --------------------------------------------------------------------
% -------------------- HELPER FUNCTIONS ------------------------------ 
% -------------------------------------------------------------------- 
  function checksumRewardOff(reward,dur)
    % checksum that ensures the reward function actually terminated the reward properly
    % (you would think I wouldn't need this, but statescript fucks it up now and then)

    global timerBufferCnt;
    if isempty(timerBufferCnt); timerBufferCnt = 0; end
    if nargin == 1; dur = const.reward.dur; end
    executeString = sprintf('disp(''Timed reward end''); sendScQtControlMessage(''portout[%d]=0'');',maze.rewards(reward));
    
    T = timer();
    T.StartDelay = dur/1e3;
    T.TimerFcn = executeString;
    buffpos = mod(timerBufferCnt,5)+1;
    try
      state.timers(buffpos) = T;
    catch E
      for i = 1:buffpos-1
        if numel(state.timers) < i || isempty(state.timers(i))
          state.timers(i)=timer();
        end
      end
      state.timers(buffpos) = T;
    end
    start(state.timers(buffpos));
    pause(const.dur.statescriptExecTime);
    timerBufferCnt = timerBufferCnt + 1;

  end

  function calcPctCorr()
    for i = maze.platforms
      incorrects    = sum(perf.isinrow(-i,perf.record(:)));
      corrects      = sum(perf.isinrow(i,perf.record(:)));
      perct         = corrects/(corrects+incorrects);
      perf.total(i) = corrects + incorrects;
      if corrects || incorrects
        perf.percent(i) = perct;
      else
        perf.percent(i) = 0;
      end
    end
  end

  % ----------------------------------------------------------------------
  % Function : potentialNonWellTriggers
  % Purpose  : Any process that might require messages sentb based on
  %             non-well inputs is computed here.
  % Input    :  MAZE GLOBALS
  % ----------------------------------------------------------------------
  function [] = potentialNonWellTriggers()
    if strcmp(const.adapt.wm.controlimp,'matlab')
        if din( maze.trialirbeam ) == false
            sendScQtControlMessage('trigger(21)');
        end
    end
    
  end

  % ----------------------------------------------------------------------
  % Function : stimulusDoutCheck
  % Purpose  : Checks for improper douts and if so removes them
  % Input    : dout - current dout as logical vec
  % ---------------------------------------------------------------------- 
  function stimulusDoutCheck(dout)
    if sum(dout(maze.leds)) > numel(state.sequence_queue) % are there more douts than there ought to be?
      improper = setdiff(find(dout),maze.leds(state.sequence_queue));
      for i = improper
        sendScQtControlMessage(sprintf('portout[%d]=0',i));
      end
    end
  end
  function ReinstateGui()
    global gui
    if ~isfield(gui,'guiHandle')
      const.guiHandle = GoalmazeControlLayout();
      gui.guiHandle = const.guiHandle;
    else
      const.guiHandle = gui.guiHandle;
    end
  end
    % --------------------------------------------------------------------
    % Name :    guiUpdate
    % Purpose : updates the graphical user interface with the latest values
    % Input :   MAZE GLOBALS
    % --------------------------------------------------------------------
    function guiUpdate()
        gdata = guidata(const.guiHandle); %TODO see if could have a persistent pointer to this through const
        updateAdaptions(gdata);
        updateStatus(gdata);
        updateHome(gdata);
        function updateAdaptions(gdata)
          if const.adapt.wm.flag
           gdata.wmvalue.String = sprintf('%2.3f sec',state.adapt.wm/1e3);
          end
        end
        function updateStatus(gdata)
          if state.gostate
              if state.blocklockout
                  %whitebg('red')
                  gdata.axes_status.Color = [255,99,71]/255;
              else
                  gdata.axes_status.Color = 'green';
              end
          else
            gdata.axes_status.Color = 'red';
          end
        end
      function updateHome(gdata)
        if const.home.on
          if state.home.currNstim == 0
            gdata.currNstim.String = sprintf('Home\ntrial');
          else
            switch mod(state.home.currNstim,10)
              case {0,4,5,6,7,8,9}, str = 'th';
              case 1, str = 'st';
              case 2, str = 'nd';
              case 3, str = 'rd';
            end
            gdata.currNstim.String = sprintf('%d%s\ntrial',state.home.currNstim,str);
          end
        end

      end
    end
    % --------------------------------------------------------------------
    % Name :    portdown
    % Purpose : runs or stores code that can be run on portdown events
    % Input :   list of ports, a function
    % --------------------------------------------------------------------
    function portdown(varargin)
       persistant P, F
       if isempty(varargin) % ACTION MODE 
           for i = 1:numel(P)
               if din(P(i)), feval(F{i}); end
           end
       else
           portlist = varargin{1};
           funclist = varargin{2};
       end
    end
  % --------------------------------------------------------------------
  % Function : recordperformance
  % Purpose  : function that handles the general task of recording
  %            performance metrics. abstracts everything about perfor-
  %            mmance recording.
  % Input    : empty or can specify the type of recording event.
  % TODO     : Slowly reorganizing to have tables of relevant properties
  %             instead of confusing mixtures of struct variables. Someone
  %             else may have to deal with this code someday if anyone
  %             continues goal pursuit experiments.
  % --------------------------------------------------------------------
  function recordperformance(type)

    function classification = label_region(platform)
        switch platform
        case maze.home, classification = 1;
        otherwise, classification = 0;
        end
    end
    function [wm, correct] = label_wm_and_correct(type)
        switch type
        case 'sequence_correct'
            wm = true;
            correct = true;
        case 'sequence_incorrect'
            wm = true;
            correct = false;
        case 'correct'
            wm = false;
            correct = true;
        case 'incorrect'
            wm = false;
            correct = false;
        otherwise;
            wm = nan;
            correct = nan;
        end
    end

    udesc = perf.tc; % normal/home, wm/not_wm, end_seq/not_end_seq

    N = seqN();
    ishome = ismember(state.sequence,maze.home) ;

    % Common operations
    perf.precord(end+1:end+numel(state.platforms))  = maze.platforms(state.platforms);
    perf.ptime(end+1:end+numel(state.platforms))    = currtime;
    perf.pseq(end+1:end+numel(state.platforms))     = N;

    % Common table operations
    udesc.poke = maze.platforms(infdin);
    udesc.time = currtime;
    udesc.seq  = N;
    %udesc.region  = label_region(udesc.poke);
    [udesc.wm, udesc.correct] = label_wm_and_correct(udesc.poke);

    switch type

    case 'errlockout'

      state.bcount        = state.bcount + 1;
      perf.brecord(end+1) = state.bcount;
      perf.btime(end+1)   = currtime;
      perf.pseq(end)      = nan;

    case 'correct'

      perf.arecord(end+1) = maze.home;
      perf.atime(end+1)   = currtime;

      % Home well specific
      %if const.home.error && ishome
      if ishome
          perf.hrecord(end+1) = true;
          perf.htime(end+1)   = currtime;
          unifiedDescription(3) = 1;
      end
      
      if isequal(const.seq.mode, 'alternate')
        state.sequence_queue = state.platforms;
        ishome = false;
      end

      % Non Home Well Performance
      perf.correct         = perf.correct + 1;
      perf.end.poke        = perf.end.poke + 1;
      if const.home.on == false ||  ~ishome
          perf.record(end+1)  = state.sequence_queue(1);
          perf.time(end+1)    = currtime;
          perf.seq(end+1)     = N;
          state.rcount        = state.rcount+1;
          perf.crecord(end+1) = state.rcount;
          perf.ctime(end+1)   = currtime;
      end

    case 'incorrect'

      perf.arecord(end+1) = -maze.home;
      perf.atime(end+1)   = currtime;

      % Home well specific
      %if const.home.error && ishome
      if  ishome
          perf.hrecord(end+1) = false;
          perf.htime(end+1)   = currtime;
          unifiedDescription(3) = 1;
      end

      % Non Home Well Performance
      perf.incorrect        = perf.incorrect + 1;
      nIncorrect = numel(state.sequence)-N+1;
      perf.end.poke         = perf.end.poke + 1;
      if const.home.on == false ||  ~ishome
              perf.record(end+1:end+nIncorrect) = -state.sequence_queue;
              perf.time(end+1:end+nIncorrect)   = currtime;
              perf.seq(end+1:end+nIncorrect) = N;
              perf.pseq(end+1)               = N;
              state.rcount        = 0;
              perf.crecord(end+1) = state.rcount;
              perf.ctime(end+1)   = currtime;
      end

    case 'sequence_correct'

      if isequal(const.seq.mode,'normal') || isequal(const.seq.mode,'differentiate')
        perf.stime(end+1) = currtime;
        perf.srecord(end+1) = true;
      elseif isequal(const.seq.mode,'crossoff')
        perf.wtime(end+1) = currtime;
        perf.wrecord(end+1) = true;
        unifiedDescription(4:5) = 1;
      end

    case 'sequence_incorrect'

        if isequal(const.seq.mode,'normal') || isequal(const.seq.mode,'differentiate')
          perf.stime(end+1)   = currtime;
          perf.srecord(end+1) = false;
        elseif isequal(const.seq.mode,'crossoff')
          perf.wtime(end+1)   = currtime;
          perf.wrecord(end+1) = false;
          unifiedDescription(4:5) = 1;
        end

    case 'cend'

      perf.incorrect                               = perf.incorrect + 1;
      if ~ishome
          perf.record(end+1:end+numel(state.sequence_queue)) = -state.sequence_queue;
          perf.time(end+1:end+numel(state.sequence_queue))   = currtime;
          perf.seq(end+1:end+numel(state.sequence_queue))    = seqN();
      end
      perf.end.abort = perf.end.abort + 1;

    otherwise, error('Unrecognized input');
    end 
  end
  % --------------------------------------------------------------------
  % Function : debugstop
  % Purpose  : decides whether to stop based on debug flags
  % Input    : the type of flag you'd like to stop on here
  % --------------------------------------------------------------------
  function debugstop(type)
      stopnow = false;
      if ~isempty(const.app.debug) && contains(const.app.debug,type)
         stopnow = true;
      end
      if stopnow; evalin('caller','keyboard'); end
  end
  % --------------------------------------------------------------------
  % Function : debugmessage
  % Purpose  : prints message if in debug mode
  % Input    : inputs that would provide to fprintf
  % --------------------------------------------------------------------
  function debugmessage(varargin)
      varargin{1} = ['\n>>>> DEBUG: ', varargin{1}];
      if ~isempty(const.app.debug);cprintf('red',varargin{:});end
  end
  % ------------ Home Well Func ---------------
  % --------------------------------------------------------------------
  % Function : selectTrialType()
  % Purpose  : Decides what type of trial should be used when home
  %             well is turned on.
  % Input    : Nothing, it reads state,maze,const,and perf
  % --------------------------------------------------------------------
  function out = selectTrialType(type)
    if nargin == 0; type=[]; end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% HOME / NORMAL TRIAL SELECTION
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Buffer Trial Type - for right now, the buffer is only for home/normal
    bufferpos = mod(state.home.currNstim,const.home.everyNstim)+1;
    state.trialbuffer{bufferpos} = state.trialtype{1};
    state.bufferpos = mod(state.bufferpos,const.home.everyNstim)+1;
    % If request trial type, then perform this switch
    if ~isempty(type) 
      if ischar(type)
        switch strtrim(type)
        case 'home'  
          out{1} = sethome();
        case 'normal'
          out{1} = setnormal();
        end
      elseif iscell(type)
        out = type;
      end
    else
        % If not, use the logical rule to switch trial
        if const.home.on 
            lastmistake_on_homewell = perf.arecord(end) == -5;
            if const.home.error && lastmistake_on_homewell
                out{1} = sethome();
            else
                % Decide what to do based on rules
                switch const.home.when
                case 'intertrial'
                    switch state.trialtype{1}
                    case 'home',      out{1} = 'normal';
                    case 'normal',    out{1} = 'home';
                      assert(~isnan(const.home.everyNstim));
                      if state.home.currNstim >= const.home.everyNstim
                        out{1} = 'home';
                      else
                        out{1} = 'normal';
                      end
                    end
                case 'error'
                    if perf.time(end) == currtime && perf.record(end)<0 
                        previous_poke_error = true;
                    else
                        previous_poke_error = false;
                    end
                    if previous_poke_error
                        switch state.trialtype{1}
                        case 'home',    out{1} = 'normal';
                        case 'normal',  out{1} = 'home';
                        end
                    end
                  case 'alternate'
                     %counter_exeeded = state.home.currNstim >= const.home.everyNstim;
                end
            end
        else
            out{1} = 'normal';
        end
    end
    
    if isempty(type) || (iscell(type) && ~isempty(type{2}))
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      %% Trial selection for special modes: Home normal have already been picked
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      out{2} = state.trialtype{2};
      if isequal(const.seq.mode,'cuememory') && isequal(out{1},'home')
          switch out{2}
          case {'inbound','cue'}
              % Switch mode
              out{2} = 'memory';
              state.trialtype{2}='memory';
          case {'outbound','memory'}
              % Switch mode
              out{2} = 'cue';
              state.trialtype{2}='cue';
          end
      end
    end
    
    switch out{1}
          case 'home', sethome();
          case 'normal', setnormal();
    end

    debugmessage('Out_newtrialtype = (%s, %s)\n', out{:});

  end
    % >>> --------------------------------------------------------------------
    % >>> Function : selectTrialType::sethome()
    % >>> Purpose  : handles all operations associated with setting a home
    % >>>               trial type.
    % >>> Input    : Nothing, it reads state,maze,const,and perf
    % >>> --------------------------------------------------------------------
    function out = sethome()
        out = 'home';
        state.trialtype{1} = out;
        state.allowedcorrect = 0;
        % Update state
        state.home.currNstim = 0;
        sendScQtControlMessage('hometrial=1');
        pause(2*const.dur.statescriptExecTime);
    end
    % >>> --------------------------------------------------------------------
    % >>> Function : selectTrialType::setnormal()
    % >>> Purpose  : handles all operations associated with setting a normal
    % >>>               trial type.
    % >>> Input    : Nothing, it reads state,maze,const,and perf
    % >>> --------------------------------------------------------------------
    function out = setnormal()
        out = 'normal';
        state.trialtype{1} = out;
        state.allowedcorrect = const.train.allowedcorrect;
        % Update state
        state.home.currNstim = state.home.currNstim + 1;
        sendScQtControlMessage('hometrial=0');
        pause(2*const.dur.statescriptExecTime);
    end
  % ------------ Reset Functions ---------------
  function executeReset()
  % Function resets all flags related to preventing execution of the maze code.
    % --- Matlab side ---
    blocklockout(false);
    currentstimoff('all');
    % --- Statescript side ---
    sendScQtControlMessage('clear queue')
    sendScQtControlMessage('trialstack=0')
    sendScQtControlMessage('flashstack=0')
    sendScQtControlMessage('block_stack=0')
    sendScQtControlMessage('pokeend_stack=0')
  end
  % ------------ Correct/Incorrect/Skip Decisions ------
  % --------------------------------------------------------------------
  % Name :      potentialTimeExtension
  % Purpose :   decides whether to send statescript messages about time
  %             extension et cetera based on DIO patterns.
  % Input :     MAZE GLOBALS
  % --------------------------------------------------------------------
  function potentialTimeExtension()
    if const.adapt.wm.flag
        if any(din(maze.home)) || any( ~din(maze.homeirbeam) )
            sendScQtControlMessage('trigger(20)');
        end
    end
  end
  % --------------------------------------------------------------------
  % Name :    inLockout
  % Purpose : decides whether we should be in lockout at the moment.
  % Input :   MAZE GLOBALS
  % --------------------------------------------------------------------
  function inlockout = inLockout()
    % --- Are we in lockout?  ---
    debugmessage('Lockout decision...');
    % (1) Poke timing related lockout condition
    pokelockout = false; % Assume we are not
    lastPokeCorrect = perf.record(end) > 0 && perf.ptime(end) == perf.time(end); % first condition: last true, second condition:last record time is last poke time (if blocklockout happened this should falsify)
    inputExists = sum(din) || sum(zone) ; % DIN REP - 08/14/17 Left off here
    anyIsDifferent = any(abs(perf.precord(end)) ~= state.platforms || isnan(perf.precord(end));
    firstRun = state.bcount == 0 && state.rcount == 0 && ~( perf.seq(end) > 1 );
    if lastPokeCorrect % LAST=CORRECT
       debugstop('lockout');
       % (A)
       lastPokeCorrect_insideLockout = ((currtime-perf.time(end))/1e3)<const.correctpokelockout;
       if lastPokeCorrect_insideLockout % if the last poke is for sure correct, and the time difference between now and last is less than a special lockout for correct pokes ...
           debugmessage('inside correct lockout window...');
           pokelockout=true;
       end
       % (B)
       if inputExists && anyIsDifferent || firstRun % but, if the previous "correct" sequence_queue is equal to the current poke sequence_queue, assume false again
          debugmessage('but alternated...');
          pokelockout = false;
        end
    else % LAST=NOT CORRECT
      % (A)
      lastPokeIncorrect_insideLockout = (currtime/1e3-perf.time(end)/1e3)<const.incorrectpokelockout;
      if lastPokeIncorrect_insideLockout % if the difference between now and the last poke is within the lockout, we are
        debugmessage('inside incorrect lockout window...');
        pokelockout = true;
      end
      % (B)
      if inputExists && anyIsDifferent || firstRun %... % but, if the previous "correct" sequence_queue is equal to the current poke sequence_queue, assume false again
          debugmessage('but alternated...');
          pokelockout = false;
      end
    end

    inlockout = state.zonedeltaflag || ~inputExists; % second condition: whether
    inlockout = inlockout || pokelockout;
  end
  % --------------------------------------------------------------------
  % Function : decideIfSkip
  % Purpose  : Contains all logic pertaining to decision whether to skip
  % processing an input when lockout conditions are not reached.
  % Input    : Nothing, it reads state,maze,const,and perf
  % --------------------------------------------------------------------
  function decision = decideIfSkip()
    if state.inRestart == true
      decision = true;
      fprintf('\ntrapped in restart\n');
    elseif ~isempty(state.platforms)
      decision = true; 
      warndlg('All inputs on');
    else
      switch const.seq.mode
        
        case 'alternate'
          decision = all(ismember(state.input, maze.irlist));
        otherwise
          switch state.trialtype{1}
          case 'home'
            homezone = any(din(maze.home));
            % Validate putatitve homepoke?
            homepokevalidated = true;
            if strcmp(const.home.ensuremethod,'irbeam') && ~any(ismember(state.input,maze.homeirbeam))
                homepokevalidated = false;
            end
            if homezone && homepokevalidated
              decision = false;
            else
              if const.home.error && ~homepokevalidated && ~homezone
                  decision = false;
              else
                  decision = true;
              end
            end
          otherwise
            decision = false;
        end
      end
    end % Guard against non-local well bug
  end
   
  % --------------------------------------------------------------------
  % Name : decideIfRight
  % Purpose : literally what is says. This function decides whether or not
  %             a poke is correct given the current state of the maze.
  % Input :    nada, it has access to the global structures about the maze
  % % --------------------------------------------------------------------
  function decision = decideIfRight()
    rules = const.seq.mode;
    switch rules
      case {'normal','crosson','crossoff','differentiate','cuememory','wtrack'}
        if any(isnan(state.sequence_queue))
            %keyboard;
            %warndlg('instruction is nan in decideIfRight()');
            decision = false;
            return;
            % save('nanerror','const','state','perf','maze');
        end
        noNans_within_instruction = ~any(isnan(state.sequence_queue));
        anyPokes_match_instruction = any(ismember(state.platforms,state.sequence_queue(1)));
        anyZones_match_instruction = any(ismember(zone,maze.zones(state.sequence_queue(1))));
        decision = noNans_within_instruction && (anyPokes_match_instruction || anyZones_match_instruction);
      case 'alternate'
        prevPokes    = perf.record(~isnan(perf.record)); % indexes all correct non-nan pokes
        fprintf('\nNUMELPOKES=%d\n', numel(prevPokes))
        if ~isempty(prevPokes) && prevPokes(end)>0
            nonIRInput = setdiff(state.input,maze.irlist);
            decision   = all(~ismember(nonIRInput,prevPokes(end))); % check if poke not in list of 
        else
            decision = true; % if there are not enough pokes to establish a sequence, it's correct
        end
      otherwise
        error('Unhandled mode %s', rules);
    end
 end
  % --------------------------------------------------------------------
  % Name : decideIfWrong
  % Purpose : handles the decision whether a poke is wrong, given the
  %             current state of the maze
  % Input :    nada, it has access to the global structures about the maze
  % --------------------------------------------------------------------
  function decision = decideIfWrong()
    rules = const.seq.mode;
    switch rules
      case {'normal','crosson','crossoff','differentiate','cuememory','wtrack'}
        anyInputs_from_Wells = any(ismember(state.platforms,maze.normal));
        decision = anyInputs_from_Wells;
      case 'alternate'
        prevPokes    = perf.record(~isnan(perf.record)); % indexes all correct non-nan pokes
        fprintf('\nNUMELPOKES=%d\n', numel(prevPokes))
        if ~isempty(prevPokes) && prevPokes(end)>0
            nonIRInput = setdiff(state.input,maze.irlist);
            decision   = ~all(~ismember(nonIRInput,prevPokes(end))); % check if poke not in list of 
        else
            decision = false; % if there are not enough pokes to establish a sequence, it's correct
        end
      otherwise, error('Unhandled mode %s', rules);
    end
  end
  % ----------- Code Sections
  % --------------------------------------------------------------------
  % Name : SetParameters
  % Purpose : 
  % Input :    nada, it has access to the global structures about the maze
  % --------------------------------------------------------------------
  function SetParameters()

        evalin('caller','global state perf maze const');
        
        rng(sum(clock()));
        
        const.app.profiler = false;      % Whether to turn the profiler on in some sections
        const.app.debug    = [];
        const.app.commit   = gitcommittag();
        const.app.ploton   = false;

         % ---- Stimuli in sequence  ----
        const.sequence  = 1;           % how many goals to have per sequence
        const.seqdelay  = 0.75;        % seconds
        const.pokedelay = 0.1;         % how many seconds to pause after a poke has been rendered before showing the next stimuli
        const.seq.mode  = 'differentiate'; % ['normal'|'crosson'|'crossoff'|'simultaneous'|'differentiate'|'alternate' ] , normal mode simply shows the stimuli in sequence upon presentation time, whether that be right after a well, or after a zone-crossing. 'crosson' shows the 1st stimulus at the normal time (which is usually a stimulus continually on), and the second stimulus is shown when the animal crosses out of its current zone. Simulateneous shows stimuli simultaneously but with the same presentation function. Differentiate is a version of simultaneous that uses a different presentation for each stimulus in the sequence.
        modeswitch(const.seq.mode);

        % ------ Trackers --------
        const.ploton = true; % turns plotting on!
        if isempty(state)
          state.input          = nan;
          state.sequence_queue = nan(1,const.sequence);
          state.sequence       = nan(1,const.sequence);
          %state.lastpoke = -inf; % previous poke time
          %state.lastpokeport = nan; % previous poke port
          state.storedrestart       = true; % works in conjunction with const.nextstim_zonecross mode
          state.gostate             = false; % 1 -- maze is executing -- 2 maze is paused (this is controlled by user in statescript in case something happens and the user wants to pause the maze, they can issue a command to this callback script to stop executing temporarily, without destroying its record of ongoing behavior.
          state.profilenum          = 0;
          state.zonedeltaflag       = false; %whether waiting for zone delta
          state.blocklockout        = false;
          state.maze.id             = nan;
          state.maze.onoff          = nan;
          state.nextstim.portdown   = false;
          state.pokeend.state       = nan; % Tracks the previous END time of a set of poke events -- everytime poking begins, this is set to nan, because the the current time is unknown. When the time become known via a statescript event, it sets to currtime.
          state.pokeend.savestate   = nan; % Tracks whether an action for poke end is saved. (Not implemented)
          state.bcount              = 0; % counter for number of consecutive blocklockout runs
          state.rcount              = 0;
          state.seq.shown           = 0;
          state.afterblocklockout   = false;
          state.trialtype           = {'normal','cue'}; % cell array that holds strings that describe the current trial mode - the first is always homewell versus normal well.
          state.trialbuffer         = {}; % holds the last N trials, where N is everyNstim (const.home.everyNstim)
          state.bufferpos           = 0;
          state.inRestart           = false; % Tracks whether there exists an instance of this callback that is calculating a resartStimulus()
          state.timers              = timer();     % Storage container for timers that are allowed to run
          state.preload_instruction = [];
          state.manual_homeir       = false;  % controls from GUI to manually evoke the home IR beam if the animal is correctly standing but not triggering the beam.
        end

        % ---- DIO Parameters ----
        maze.platforms =  1 : 5;          % <-- Labels to denote each platform in the code
        maze.leds      =  [17 23 19 20 21];        % <-- dout of leds
        maze.inputs    =  [1:4, 6];          % <-- din  of poke inputs
        maze.rewards   =  [5 7 8 9 10];	% <-- dout of reward wells
        maze.zones     =  1 : 5;          % <-- numbers used to denote each of the zones sent from statescript
        maze.home      =  5;              % <-- numbers used to denote each of the zones sent from statescript
        maze.homein    = maze.inputs(maze.home);
        maze.normal    =  setdiff(maze.zones,maze.home);
        maze.homeirbeam = 13;
        maze.trialirbeam = 12; % 14 is dead on the current board
        maze.irlist    = [maze.homeirbeam, maze.trialirbeam]; % lists out the event-related ir beams

        
        % -------------- HOME WELL -------------------------------------------
        const.home.ensuremethod     = 'irbeam'; % {zone|irbeam}
        const.home.on         = true; % Whether or not to activate the homezone
        const.home.everyNstim = 1; % How often does the animal have to visit the zone?
        const.home.when       = 'intertrial'; % intertrial | error
        const.home.errorstop  = false; % Whether to lockout for erroneous pokes
        const.home.multiplier = 0.5; % multiplier for the amount of reward
        state.home.currNstim  = 0;
        const.home.error    = false;
        const.home.aftererr = true;
        const.home.errcnt = 1;

        % ---- Durations  ----
        const.app.stimdoutcheck = true;
        const.dur.start = 1; %seconds - startup delay
        % (Rest of the durations programmed into the statescript component)
        % ---- Statescript consts ---
        const.dur.statescriptExecTime = 1e-3; %ms -- used to ensure statescript can see and react to a variable change, before it's undone, via pause()
        %     if const.sequence>1
        %     assert(const.incorrectpokelockout>=const.sequence*const.seqdelay);
        %     assert(const.incorrectpokelockout>=const.pokedelay);
        %     end
        % ---- Specific Modes and Persistent Information -----
        const.pokingoff = false;       % mode that turns the poke sensing off (to ensure relying purely on zone)
        const.zoningoff = true;        % mode that turns the zone sensing off that lets animal get milk from zone entrance
        % Block lockouts
        const.blocklockout_period = 10;    % Lockout the maze after incorrects (everything turns off) ... 0 toggles the mode off
        const.train.allowedincorrect     = 0;       % number of incorrects before stimulus restarted
        state.allowedincorrect     = const.train.allowedincorrect;
        const.train.allowedcorrect       = 0;       % number of corrects before stimulus restarted
        state.allowedcorrect = const.train.allowedcorrect;
        %state.allowedcorrect = const.train.allowedincorrect;
        const.correctpokelockout   = 10 ;   % seconds to lockout the same well after each poke has been rendered (incorrect)
        const.incorrectpokelockout = 10 ;   % seconds to lockout the same well after each poke has been rendered (incorrect)
        const.train.flash_cuememory = true;

        % ------ Adaptive stimulus presentation length -------
        % Documentation: This controls adaption of stimulus presentation time.
        % The brains of the operation are right now controlled in statescript.
        % The light off times are set there and written onto the statescript
        % event stack. For home well maze types, this should be written to
        % be controlled only at the home well poke and home well positional ir beam
        const.adapt.wm          = [];
        const.adapt.wm.flag     = true;
        const.adapt.wm.stepdown = 3.5 * 1e-2;    %percent to shorten when correct
        const.adapt.wm.stepup   = 3.5 * 1e-2;      %percent to lengthen when incorrect
        const.adapt.wm.min      = 0.0 * 1e3;  % floor of cue time, in statescript time
        const.adapt.wm.max      = 1 * 1e3;   % ceil of cue time, in statescript time,
        const.adapt.wm.init     = 0.5 * 1e3;  % initial value in seconds of cue time. in statescript time
        const.adapt.wm.control    = 'irbeam';     % none | irbeam , whether or not to use a dedicated ir beam to control the process
        const.adapt.wm.controlimp = 'statescript'; % implementation: matlab | statescript
        if const.adapt.wm.flag
          state.adapt.wm=const.adapt.wm.init;
        end

        function cycs = cycles(port_sequence, n)
            pats = numel(port_sequence) + 1;
            cycs = zeros(n,pats*2-1);
            for i = 1:pats % forward port_sequence
                temp = circshift(port_sequence, i-1); 
                cycs(:,i) = temp(1:n);
            end
            for i = 1:pats-1 % backward port_sequence
                temp = circshift(port_sequence(end:-1:1), i); 
                cycs(:,pats+i) = temp(1:n);
            end
        end
        function reps = repeats(ports, n)
            reps = repmat(ports', [1 n]);
        end

        % Maze features
        const.info.patterns  = {repeats(maze.normal,3), cycles(maze.normal, 2)}; % patterns to break
        const.info.distances = mazedistances('2x2');

        % Training modes
        const.train.distalonly          = false;
        const.train.weightdistance      = false;
        const.train.patternbreak        = false; % (UNWRITTEN TODO ) mode that attempts to break any cyclic path assumptions of a given animal
        const.train.discourage_short_of_pair_first = true; % decides to make the longest distance stimuli of the pair picked first.
        const.train.bias_short_pick     = false; % increases bias to short distance
        const.train.weightperf          = false;
        const.train.flashremind         = false;      % toggles whether stimuli reminded via flash
        const.train.excprev             = false;
        
        % Adaptive blocklockout length
        % The way this works, if turned on, is that every subsequent
        % blocklockout it is stepped up by the appropriate percentage
        % (longer lockout time), and if the animal finally gets something
        % correct, it immediately returns the stored value to the minimum.
        % We want the animal not to whilly nilly alternate wells. This
        % disinventives it.
        const.adapt.blocklockout        = []; % (NOT FULLY IMPLEMENTconst.blocklockout.restartlastED TODO )
        const.adapt.blocklockout.flag   = false;
        const.adapt.blocklockout.stepup = 60 * 1e-2;    %percent to shorten when correct
        const.adapt.blocklockout.min    = 2 * 1e3;  % floor of cue time, in statescript time
        const.adapt.blocklockout.max    = 20 * 1e3;   % ceil of cue time, in statescript time,
        if const.adapt.blocklockout.flag
          state.adapt.blocklockout=const.adapt.blocklockout.init;
        end
        const.adapt.blocklockout.downfunc = 'state.adapt.blocklockout=const.adapt.blocklockout.init';
        
        % Adaption for the time the second stimulus remains on in the
        % crossoff mode
        const.adapt.crossoff        = [];
        const.adapt.crossoff.flag   = false;
        const.adapt.crossoff.init   = 2.5;
        const.adapt.crossoff.min    = 0;
        const.adapt.crossoff.max    = 3; % seconds
        const.adapt.crossoff.stepup = 0.5;
        const.adapt.crossoff.stepdown = const.adapt.crossoff.stepup;
        state.adapt.crossoff          = const.adapt.crossoff.init;

        % Stimulus type and training
        const.selectany           = false;          % whether selects wells with equal prob or exlcudes previous
        const.unlimitedstimulus = 1; % mode that keeps stimulus constant to train
        const.flashstim           = false;        % toggles whether to use a flashing stimulus instead of a constant
        if const.flashstim
          const.seq.stim = [17 17];
        end
        if const.unlimitedstimulus == true && const.adapt.wm.flag == true
          warning('Incompatible modes'); 
        end

        % Trial length
        const.trialtime_inf = true;       % whether or not the animal has infinit time to complete a trial
        const.trialtime     = 20;

        % Stimulus restart options
        const.resetzone_after_blocklockout = false;
        const.exclude_currentzone          = false; % whether to exclude restarting a trial with the current zone the animal is in.
        const.nextstim_zonecross           = false;   % mode that waits for zone crosses before re-cuing
        const.nextstim_portdown            = false;   % mode that waits for zone crosses before re-cuing
        const.on_entexit                   = 0; % 1 - entrance , 2 - exit, 0 - off
        const.off_entexit = 0; % 1 - entrance , 2 - exit, 0 - off
        const.blocklockout.restartlast = false;

        % Reward
        const.reward.dur   = 0.85;
        const.reward.equal = false;
        const.reward.mult  = 0.55; % this times sequenceN
        const.reward.wait  = false; % this sort of thing does not work unless drop a break point and the global variables update because other code is allowed to execute. to get this mode working would need to split execution of correct/incorrect
        const.reward.scaleperf = false;
        
        state.btime=[];
        if isempty(perf)
            ResetPerf();
        end

        rng('shuffle')

        % Initializing save related information -- NOT WORKING BECAUSE OF
        % HOW STATESCRIPT CALLS MATLAB
        %const.savestring = num2str(randi(9,1,10));
        %const.savedestruct = onCleanup(@() savestate(const.savestring));
		const

        if const.incorrectpokelockout>const.blocklockout_period
            warning('Incorrect poke lockout greater than blocklockout period: can lead to undesired effects when the animal previously makes an incorrect poke, but immediately pokes a correct stimulus after blocklockout.');
        end

        SetParameters_Statescript(); % Handles the statescript portion of parameter setting

  end
  % ----------------------------------------------------------------------
  % Function : SetParameters_Statescript
  % Purpose  : Accomplishes the part of SetParameters that needs to upload
  % to statescript
  % Input :    nada, it has access to the global structures about the maze
  % ----------------------------------------------------------------------
  function  SetParameters_Statescript()

        sendScQtControlMessage(sprintf('blocklockout_period=%d',const.blocklockout_period*1e3));
        if const.adapt.wm.flag
          sendScQtControlMessage(sprintf('stim_duration=%d', round(state.adapt.wm)));
        end
        if const.adapt.blocklockout.flag
          sendScQtControlMessage(...
            sprintf('stim_duration=%d',state.adapt.blocklockout)...
            );
        end
        if ~const.trialtime_inf; sendScQtControlMessage(sprintf('reset_dur=%d',round(const.trialtime*1e3))); end
        sendScQtControlMessage(sprintf('reward_dur = %d',round(const.reward.dur*1e3)));
        sendScQtControlMessage(sprintf('expiration_mode=%d;',const.unlimitedstimulus))

        if strcmp(const.adapt.wm.control,'irbeam') && strcmp(const.adapt.wm.controlimp,'statescript')
            sendScQtControlMessage('expiration_mode=1'); %turn expiration mode off
            sendScQtControlMessage('terminal_ir_mode=1');
        else
            sendScQtControlMessage('terminal_ir_mode=0');
        end
    end

    function ResetPerf()
      perf = struct(...
            'adapt',struct('wm',nan,'time',nan),...
            'correct', 0,   'incorrect', 0,   ...
            'table', struct2table(struct('time',nan,'poke',nan,'seq',nan,'correct',nan,'region',nan,'wm',nan,'seqfin',nan,'cuemem',nan)),... the eventual successor for the arecord
            'record',  nan, 'time',      nan, ... main record (right/wrong for relevent task var) 
            'hrecord', nan, 'htime',     nan, ... home well right/wrong
            'arecord', nan, 'atime',     nan, ... record + hrecord
            'zrecord', nan, 'ztime',     nan, ... zone record
            'precord', nan, 'ptime',     nan, ... poke record
            'crecord', nan, 'ctime',     nan, ... correct record: number of corrects in a row
            'btime',   nan, 'brecord',   nan, ... blocklockout record: number of blocklockouts in a row
            'stime',   nan, 'srecord',   nan, ... sequence record
            'wtime',   nan, 'wrecord',   nan, ...
            'seq',nan,'pseq',nan,... sequence number of last correct/incorrect poke and of last poke resepectively
            'percent',zeros(size(maze.platforms)),'initialtime', datetime...
            ); 
        perf.end =  struct('poke',0,'abort',0);   % counts trials that ended in a decision versus those where trial abortion happened
        perf.tc  = perf.table;
        % Plotting functions related to performance
        perf.isinrow = @(x,y) sum(ismember(y,x),2)>0;
        perf.tr      = @(x) reshape(transpose(x),[],1);
        perf.platform_history = {};
        plotmaze(perf,maze,state);
    end


  function tag = gitcommittag()
    tag = '';
    if isunix()
      [~,tag] = system('git log --pretty=format:"%h" | head -n 1');
      tag=strtrim(tag);
    end
  end
  % ----------------------------------------------------------------------
  function saveConfig(filename)
   save(filename,'const');
  end
  % ----------------------------------------------------------------------
  function loadConfig()
    load(filename,'const');
  end
  % ----------------------------------------------------------------------
  function out = rectifiedNumeric(in)
    ind = ~isnan(in);
    out = abs(in(ind));
  end
  % ----------------------------------------------------------------------
  function decision = patternDetect(record)
    % const.info.patterns  = {[ 1 1 1 ; 2 2 2; 3 3 3; 4 4 4 ]}; % patterns to break
    decision = false; % default: assume pattern break is false unless proven otherwise
    for patmat = const.info.patterns

        patmat = patmat{1};
        numseq = size(patmat,2);
        numpat = size(patmat,1);

        if numel(record) <= numseq
            continue;
        end
        rec = record(end-numseq:end);
        patterndetect = false(1,numpat);

        for pat = 1:numpat
            patterndetect(pat) = isequal(rec,patmat(pat,:));
        end
        if any(patterndetect)
            decision = true;
            return; % exit early, don't even continue checking pattern matrix groups
        end
    end
  end
  % ----------------------------------------------------------------------
  function ParseCommands(newline,rem)
    newline=strtrim(newline);
    rem=strtrim(rem);
    if strcmp(newline,'maze')
      if contains(rem,'stop')
        state.gostate = false;
        allstimoff;
        stopall;
      end
      if contains(rem,'clear') % the clear session command
          evalin('caller','global perf state const');
          assignin('caller','perf',[]);
          assignin('caller','state',[]);
          assignin('caller','const',[]);
          SetParameters();
          ReinstateGui();
          %const.app.debug=debug;
      end
      if contains(rem,'start')
        if state.gostate == false
            state.gostate = true;
            fprintf('Reuploading statescript parameters.');
            SetParameters_Statescript();
        end
        allstimoff('reward',0);

        restartStimulus();
      end
  elseif strcmp(newline,'save') % 'save' command triggerd in matlab from statescript
      fprintf('save detected\n');
      savestate(rem);
  elseif strcmp(newline,'report') % 'report' command triggerd in matlab from statescript
      fprintf('report detected\n');
      reportstate();
  elseif strcmp(newline,'all')
      if contains(rem,'off')
        allstimoff;
      elseif contains(rem,'on')
        for i = maze.leds,
          sendScQtControlMessage(sprintf('portout[%d]=1;',i));
        end
      end
  elseif strcmp(newline,'flash')
      for j = 1:4
        for i = maze.leds,sendScQtControlMessage(sprintf('portout[%d]=1;',i));end
        pause(0.10);
        allstimoff([],0);
        pause(0.10);
      end
  elseif strcmp(newline,'profile')
      if contains(rem,'on')
        const.app.profiler=true;
      else
        const.app.profiler=false;
      end
  elseif strcmp(newline,'reward') && ~any(rem=='=')
      if contains(rem,'target')  % rewards the target sequence_queue
          sendScQtControlMessage(sprintf('reward=%d;',maze.rewards(state.sequence_queue(1))));
          sendScQtControlMessage('trigger(12);');
      elseif contains(rem,'prevpoke') % rewards the last poked sequence_queue
          sendScQtControlMessage(sprintf('reward=%d;',...
              maze.rewards(abs(perf.precord(end)))...
              ));
          sendScQtControlMessage('trigger(12);');
      elseif contains(rem,'prevzone') % rewards the last exited sequence_queue
         lastzone = find(perf.zrecord<0,1,'last');
         sendScQtControlMessage(sprintf('reward=%d;',...
              maze.rewards( abs(perf.zrecord(last))  )...
              ));
         sendScQtControlMessage('trigger(12);');
      elseif contains(rem,'all on')
          for i = maze.rewards
              sendScQtControlMessage(sprintf('portout[%d]=1;',i));
          end
      elseif contains(rem,'all off')
          for i = maze.rewards
              sendScQtControlMessage(sprintf('portout[%d]=0;',i));
          end
      elseif any(isstrprop(rem,'digit'))
          num=str2double(rem);
          sendScQtControlMessage(sprintf('portout[%d]=''flip'';',maze.rewards(num)));
      end
  elseif strcmp(newline,'restart')
      state.storedrestart = 1;
      state.zonedeltaflag = 0;
      if isempty(rem)
        restartStimulus();
      else
          [rem,rem2] = strtok(rem);
          rem=str2double(rem);
          restartStimulus(rem,rem2);
      end
   elseif strcmp(newline,'errorlockout')
     if strcmp(rem,'true')
         val=true;
     else
         val=false;
     end
     blocklockout(val);
   elseif strcmp(newline,'eval')
       eval(rem);
   elseif strcmp(newline,'plotmaze')
     temp=state;
     temp.blocklockout=false;
      plotmaze(perf,maze,temp);
      clear temp;
    elseif strcmp(newline,'wrong')
      Incorrect();
    end
    guiUpdate();
  end
  % ======================================================================
  % ================= PARSE STATESCRIPT ==================================
  % ======================================================================
  function exitRequested = ParseStatescriptMessages(newline)
    exitRequested=false;
    if strcmp(newline,'cstart')

      fprintf('cstart detected\n');
      % store clock start
      % TODO record trial starts and stops

    elseif contains(newline,'blocklockout')
        if contains(rem,'end')
            blocklockout(false);
            restartStimulus_modeDependent()
        end
    elseif strcmp(newline,'cend') && ~const.trialtime_inf && ~state.blocklockout

      % restart maze stimulus presentation
      fprintf('cend detected\n');
      % Incorrect!
      recordperformance('cend');
      if const.ploton
          plotmaze(perf,maze,state);
      else
          calcPctCorr();
      end
      adapt('up');
      restartStimulus_modeDependent()
      
    elseif strcmp(newline,'port')
      [tok,rem] = strtok(rem);
      %assert(tok,'POKE');
      if isequal(tok,'END')
        state.pokeend.state = currtime;
      else
        [tok,rem] = strtok(rem);
        state.maze.id = str2double(tok);
        [state.maze.onoff,~]=strtok(rem);
        if isequal(state.maze.onoff,'down')
          state.maze.onoff=-1;
        else
          state.maze.onoff=1;
        end
      end
    elseif strcmp(newline,'zone') % This means a zone was entered from the event triggered menu

        %keyboard
        % Pull out zone number and zone type (enter or exit)
        [zone,ztype] = strtok(rem);
        zone=str2double(zone);
        if contains(ztype,'enter'); ztype=1; % entrance
        else ztype=2; end % exit

        perf.zrecord(end+1) =  zone* (ztype-1.5)*2;
        perf.ztime(end+1)   =  currtime;

        % Turn off stimulus because exiting or entering?
        if ztype == const.off_entexit % yes, we are outside the range of the last poke
          %if state.pokeend.state < currtime
            currentstimoff('shown');
          %else
          %  state.pokeend.savestate = 1;
          %end
        end

        % If crosson sequence mode -- Finish showing stimulus because of entering or exiting
        if isequal(const.seq.mode,'crosson') && const.sequence>1
          % Iterate and show
          assert(~isempty(state.seq.shown))
          for c = state.seq.shown+1:const.sequence
            %currentstimoff;
            stimon(led(state.sequence(c)), 17);
          end
          if ~isempty(c)
            state.seq.shown=c;
          end
        end
        
         % If crossoff sequence mode -- Remove lights after they have been
        % shown
        if isequal(const.seq.mode,'crossoff') && ztype==1
          currentstimoff(1);
          currentstimoff(2);
        end

        % Pick a new stimulus because entering or exiting
        if ztype == const.on_entexit  && state.zonedeltaflag && state.storedrestart
          state.zonedeltaflag=false;
          restartStimulus();
        end
         
        if const.resetzone_after_blocklockout  && state.afterblocklockout && ztype==1 % add home position specifically!
          % Then the animal is at the home zone, then initiate the restart
          state.afterblocklockout = false;
          restartStimulus();
        end

        if ztype~=1 || const.zoningoff ; zone=[]; end
        
    elseif contains(newline,'down') % TODO why did you do this again?
        if const.selectany && perf.record(end)>0 % Is this to end the lockout period?
          perf.precord(end+1) = nan; perf.ptime(end+1) = nan; perf.record(end+1)=nan; perf.time(end+1)=nan;
        end
    elseif contains(newline,'compile')
        SetParameters_Statescript();
    else
        exitRequested=true;
    end
    guiUpdate();
  end
  % ======================================================================
  % ======================== CORRECT() ===================================
  % ======================================================================
  function Correct()

    fprintf('\n\tCHOSE %d (%d) CORRECT\n',state.sequence_queue,state.platforms);
    state.pokeend.state = nan; % now the current end time of a sequence of poking is unknown until statesscript sends a message
     
    decomission = ismember(state.sequence_queue,state.platforms);
    ishome = ismember(state.sequence,maze.home);

    % --- reward sizes not equal --- 
    rewardsizes_equal_not_on = ~const.reward.equal;
    if rewardsizes_equal_not_on && ~ishome
        if const.reward.scaleperf
            weights = weights .* (1-perf.percent);
            weights = max(weights, 0.25*max(weights));
            weights = weights/min(weights);  % normalize to minimum
            perfscale = weights(state.sequence_queue(decomission));
        else
            perfscale = 1;
        end

        memory_bonus = 0;
        switch state.trialtype{2}
        case 'memory', memory_bonus = 1;
        otherwise, memory_bonus = 0;
        end

        this_reward_dur = round(const.reward.dur*1e3*(seqN + memory_bonus)*const.reward.mult*perfscale);
        sendScQtControlMessage(sprintf('reward_dur=%d',this_reward_dur)); % Setup reward duration ... reward the sequence number times the regular amount .. if it's the second in the sequence, they get twice the reward
    end
    if ishome
        this_reward_dur = round(const.reward.dur*1e3*const.home.multiplier);
        this_reward_dur
        sendScQtControlMessage(sprintf('reward_dur=%d',this_reward_dur)); % Apply home well mujltiplier
        pause(const.dur.statescriptExecTime);
    end
    if ~exist('this_reward_dur','var'); this_reward_dur = const.reward.dur; end

    % -------- Handle the Reward and Turn Off Stimuli --------------------
    % --- Crosson or Differentiate Modes --- 
    if isequal(const.seq.mode,'crosson') || isequal(const.seq.mode,'differentiate') % Zone cross mode
      % --- if no stim left ---
      if numel(state.sequence_queue) - sum(decomission) > 0 && const.sequence~=1
        currentstimoff(seqN);
      else
        allstimoff('reward',false);
      end
    end
    
    % ------------ Store the Performance Statistics ----------------------
    recordperformance('correct')

    % --- Reward --- 
    if ~strcmp(const.seq.mode,'alternate')
      reward_this_well = state.sequence_queue(1);
    else
      reward_this_well = state.platforms(1);
    end
    sendScQtControlMessage(sprintf('reward=%d;', maze.rewards(reward_this_well))); % Setup which port to be rewarded
    sendScQtControlMessage('trigger(12);'); % Send out the reward command
    % NOw have to reset the duration to the normal
    checksumRewardOff(reward_this_well,this_reward_dur);
    this_reward_dur = round(const.reward.dur*1e3);
    sendScQtControlMessage(sprintf('reward_dur=%d',this_reward_dur)) % RESTORE the reward duration to normal TODO must keep track of the current level and increment the protection period insde the allstimoff

    % --- If cross off mode, remove lights after they have been shown --- 
    if isequal(const.seq.mode,'crossoff')
      currentstimoff(1);
      currentstimoff(2);
    end

    % ---------- Decomission Platform and Adapt Maze Behavior ------------  
    % If adapt cue is on
    if const.home.on == false || strcmp(state.trialtype{1},'normal') 
        adapt('down'); 
    end
    % De-queue the sequence_queue
    state.sequence_queue(decomission) = []; 

    % ------------- Finished Instruction Set Actions ---------------------
    % --- Wait for clear queue --- 
    if const.reward.wait; rewardwait(); end
    % --- Res Stim & Extra Perf Stats --- 
    allowedcorrect_exceeded = state.allowedcorrect<=1 || strcmp(state.trialtype{1},'home');
    no_instructions_remain = isempty(state.sequence_queue);
    if no_instructions_remain && allowedcorrect_exceeded
        restartStimulus();
        number_of_instructions = numel(state.sequence);
        if number_of_instructions > 1 
            recordperformance('sequence_correct');
        end
    % --- Time Ext --- 
    else
      % If the queue is empty, restart the stimulus!
        %sendScQtControlMessage('trigger(13);'); % extend time
        if isempty(state.sequence_queue)
            % if const.sequence == 1; state.lastpokeport=nan; end
            state.allowedcorrect = state.allowedcorrect-1;
            state.sequence_queue = state.sequence;
        end
    end

    % ------------ Plot Current Maze Status ------------------------------
    if const.ploton
      plotmaze(perf,maze,state);
    else
        calcPctCorr();
    end

  end
  % ----------------------------------------------------------------------
  % Function : stimuluschecksum
  % Purpose  : For certain modes, checks that stimuli are on when expected,
  %             in part because of unwanted issues with clear queue in state
  %             script and the janky way one has to kill events.
  % Input :    nada, it has access to the global structures about the maze
  % ----------------------------------------------------------------------
  function stimuluschecksum(dur)
    global timerBufferCnt;
    if isempty(timerBufferCnt); timerBufferCnt = 0; end
    if nargin == 0; dur =  1.5*const.reward.dur; end

    switch const.seq.mode
    case {'cuememory'}
        executeString = sprintf('stimon(maze.home, const.seq.stim(1));');
        if strcmp(state.trialtype{1}, 'home')
        T = timer();
        T.StartDelay = dur/1e3;
        T.TimerFcn = executeString;
        buffpos = mod(timerBufferCnt,5)+1;
        try
          state.timers(buffpos) = T;
        catch E
          for i = 1:buffpos-1
            if numel(state.timers) < i || isempty(state.timers(i))
              state.timers(i)=timer();
            end
          end
          state.timers(buffpos) = T;
        end
        start(state.timers(buffpos));
        pause(const.dur.statescriptExecTime);
        timerBufferCnt = timerBufferCnt + 1;
        end
    otherwise
    end

  end
  % ----------------------------------------------------------------------
  % Function : stimon
  % Purpose  : abstracts flipping a light stimulus on
  % Input :    nada, it has access to the global structures about the maze
  % ----------------------------------------------------------------------
  function stimon(light, stim)
    sendScQtControlMessage(['light=' num2str(light) ';']);
    sendScQtControlMessage(sprintf('trigger(%d);',stim));
  end
  % ----------------------------------------------------------------------
  % Function : rewardwait
  % Purpose  : implements a wait until statescript has time to execute
  %             clear cue. DOESN'T WORK BECAUSE scQtControllerOutput has 
  %             none of the new events written after the beginning of the
  %             function until 
  % Input :    nada, it has access to the global structures about the maze
  % ----------------------------------------------------------------------
  function rewardwait()

      global scQtControllerOutput
      searchlen = 20;
      searchpause = 0.01;
      
      a=strfind(scQtControllerOutput(end-searchlen:end),'...RF');
      while isempty(cat(2,a{:}))
        %pause(searchpause); 
        clear scQtControllerOutput
        global scQtControllerOutput
        a=strfind(scQtControllerOutput(end-searchlen:end),'...RF'); % open scQtControllerOutput
      end
  end
  
  % ======================================================================
  % ====================== INCORRECT() ===================================
  % ======================================================================
  function Incorrect()
    fprintf('\n\tCHOSE %d (%d) INCORRECT\n',state.sequence_queue,din);
    % Incorrect! -- nada, animal gets nothing

    % Store last input or zone
    if ~isempty(state.platforms), last = zone;
    else, last = state.platforms;
    end

    % Set trackers
    state.pokeend.state = nan; % now the current end time of a sequence of poking is unknown until statesscript sends a message
    %state.lastpoke=currtime;
    %state.lastpokeport = last;

    % ------------ Store the Performance Statistics ----------------------
    recordperformance('incorrect')

    % -------------------- Adapt Maze Behavior ---------------------------
    if const.home.on == false || strcmp(state.trialtype{1},'normal') 
        adapt('up'); 
    end
    
    % ------------- Finished Instruction Set Actions ---------------------
    % (1) Post-instruction Set Statistics
    try
      if const.sequence>1 && ~isempty(state.platforms) && any(ismember(state.platforms,state.sequence))
          recordperformance('sequence_incorrect');
      end
    catch ME
      warndlg('Likely a problem with current din or sequence value');
    end
    % (2) "Block lockouts" and Restart Stimuli
    if const.blocklockout_period > 0 % && (const.sequence==numel(state.sequence_queue))
        sendScQtControlMessage('block_stack = 0');
        if const.train.allowedincorrect>0 && state.allowedincorrect>0
            state.allowedincorrect = state.allowedincorrect-1;
        else
            blocklockout(true); % intitiate statescript lockout timer
        end
    else
        restartStimulus_modeDependent()
        % If plotting option is on, then plot stats whenever a digital in is
        % registered
        if const.ploton
          plotmaze(perf,maze,state);
        else
            calcPctCorr();
        end
    end
    
  end
  % ----------- General Actions
  % ----------------------------------------------------------------------
  function restartStimulus(selection,trialtype)
  % Reset the current goal, by randomly selecting a new sequence_queue
  % stimulus, presenting it, and coding it into this funciotn's
  % memory.
  
    % MODE alternation
    if isequal(const.seq.mode,'alternate')
        return
    end

    state.inRestart = true;
    des = onCleanup(@inRestOff);
    if const.resetzone_after_blocklockout && state.afterblocklockout
      return
    end

    % --------------------
    % DETERMINE TRIAL PROPERTIES
    % --------------------
    % if no params given
    if nargin == 0; selection = []; end
    if nargin <= 1; trialtype = {}; end
    % Handle empty params
    if isempty(trialtype)
        trialtype = selectTrialType();
    else
        trialtype = selectTrialType(trialtype);
    end

     % --------------------
     % GUI modifications?
     % --------------------
     if ~isempty(state.preload_instruction) && strcmp(trialtype{1},'normal')
         selection = state.preload_instruction;
         state.preload_instruction=[];
         gdata = guidata(const.guiHandle); %TODO see if could have a persistent pointer to this through const
         gdata.edit_nextinstruction.String = '';
         gdata.edit_nextinstruction.BackgroundColor = 'white';
         gdata.edit_nextinstruction.ForegroundColor = 'black';
     end

     % --------------------
     % Potetial assignments up front
     % --------------------
     % IF home trial, and a selection not given, assign it
     if isempty(selection) && strcmp(trialtype{1}, 'home')
          selection = maze.home;
     % if cuememory mode and not a home trial and a memory subtrial
     elseif isequal(const.seq.mode , 'cuememory') && isequal( trialtype, {'normal','memory'})
         selection = perf.platform_history{end}; %would be end-1 if already updated history to reflect previous
     end
      
     % --------------------
     % Potential bug: make sure stims are off before selection
     % --------------------
      if perf.record(end)>0
          allstimoff('reward',0); % NOT SURE IF DELAY SHOULD BE HERE OR NOT!
      else
          allstimoff('nextstim',0); % RYAN CHANGED TO NO DELAY, BUT IT'S POSSIBLE THIS IS WRONG
      end
%     end
   
     % --------------------
     % Select, if no selection
     % --------------------
    if isempty(selection)
      
        if const.nextstim_portdown && ~state.nextstate.portdown && ~state.maze.onoff==-1
          state.nextstate.portdown=true;
          assert(any(isnan([state.sequence_queue state.sequence])),'uh oh. instructions unclear at the end of restartStimulus');
          return;
        end
        
        % PICK A PLATFORM?
        [previous_sequence, startpick] = preparestimulus();
        selection = pickstimulus(previous_sequence,startpick)
        selection = checksumselection(selection);
         
    else
      
        selection=checksumselection(selection);
        perf.platform_history{end+1} = state.sequence; % update history
        % assign new instructions
        state.sequence_queue = selection;
        state.sequence=state.sequence_queue;
    end

    % As long as we satisfty the we're not on a regular trial subtyped as memory, then proceed
    applystimulus();

    % State resets for zone presentation modes and block trial modes
    state.zonedeltaflag = false;
    state.storedrestart = false;
    state.allowedincorrect = const.train.allowedincorrect;
    state.allowedcorrect   = const.train.allowedcorrect;
    assert(all(~isnan(state.sequence_queue)),'Picked instruction incorrectly');
    
    function inRestOff()
      state.inRestart = false;
    end
    
    function [previous_sequence, startpick] = preparestimulus()
        
        % AUTOMATICALLY SET TO LAST PLATFORM?
        previous_sequence = state.sequence;
        startpick=1;
        %TODO THIS IS A COMPLEX ENTRY FOR AN IF STATEMENT: simplify or name the conditions
        if perf.seq(end)==1 && const.blocklockout.restartlast && state.bcount == 0 && state.rcount==0 && sum([~isnan(perf.precord(:));~isnan(perf.zrecord(:))]) % if mode is turned on to pick closest stimulus to animal for the first stim at the end of a blocklockout, then
            % Figure out the last location, and select it for the current
            % stimulus
            lastpoke = find( ~isnan(perf.precord), 1, 'last');
            lastzone = find( ~isnan(perf.zrecord), 1, 'last');
            lp = perf.ptime(lastpoke);
            lz = perf.ztime(lastzone);
            if isempty( lp ); lp = -inf; end
            if isempty( lz ); lz = -inf; end
            if lz > lp
                state.sequence(1) = perf.zrecord(lastzone);
            else
                state.sequence(1) = perf.precord(lastpoke);
            end
            startpick=2;
        end
    end
    
    function applystimulus()
    % Apply the stimulus sequence you have picked
    
      fprintf('\n\tPLATFORM %s PICKED\n',num2str(state.sequence_queue));
      
      shown=0;
     
      if ~(strcmp(const.seq.mode, 'cuememory') && isequal( state.trialtype, {'normal', 'memory'})) || const.train.flash_cuememory
      
        %if poke; pause(const.pokedelay); end
        for sequence_queue = state.sequence_queue
            shown=shown+1;
            light = led(sequence_queue);
            
            if ~state.blocklockout
                % if cnt == 0; sendScQtControlMessage('clear_queue_next_stim=1'); end % this should already be set my allstimoff
                if isequal(state.trialtype,{'normal','memory'}) && strcmp(const.seq.mode, 'cuememory')
                    if const.adapt.wm.flag
                      stimon(light, const.seq.stim(2));
                    end
                else
                  stimon(light, const.seq.stim(shown));
                end  
            end
            %sendScQtControlMessage(sprintf('trigger(13);')); % start timer

            if isequal(const.seq.mode,'crosson'), break; end % if flashcross mode for sequencing, the next stimuli will be presented only when the animal crosses a zone
            if shown>1
                pause(const.seqdelay);
                if ~(strcmp(const.seq.mode,'differentiate') || strcmp(const.seq.mode,'crossoff') ); allstimoff([],false); end
            end
        end
      else

      end
      
      state.seq.shown = shown;
      
    end
    % --------------------------------------------------------------------
    function selection = pickstimulus(previous_sequence,start)
    % Restart stimulus subfunction that picks the ndisp(    ext stimuli  

      %rng('shuffle');
      %rng(sum(clock()));
    
      % Determine which stimuli at what sequence position to exclude
      % assert(numel(state.sequence) == const.sequence);
      if const.sequence == 1
        excseq = state.sequence; % previous sequence to avoid
      else
        excseq = nan(1,const.sequence);
      end
      if const.exclude_currentzone
        %TODO rather than this exclude whichever is earlier!
        if perf.ptime(end)>perf.ztime(end)
          excseq = [excseq; perf.precord(end), nan(1,const.sequence-1)];
        else
          excseq = [excseq; abs(perf.zrecord(end)), nan(1,const.sequence-1)];
        end
      end
      %Add to exclusion
      if start<=const.sequence && start~=1
        excseq = [excseq;nan(1,const.sequence)];
        excseq(end,start)=state.sequence(1,start);
      end
      
      % Iterate stimuli sequence and pick
      for k = start:const.sequence
        % Possibilium
        pickset = maze.platforms;
        if ~(const.selectany||const.nextstim_zonecross)
          select      = true(1,maze.platforms(end));
          exc         = excseq(~isnan(excseq(:,k)),k);
          select(exc) = false;
          select      = select & maze.platforms ~= maze.home;
          pickset     = pickset(select);
        end
        
        weights_to_use = getWeights(pickset);
        
        %Pick
        assert(~any(isnan(pickset)));
        state.sequence(1,k) = randsample(pickset,1,true,weights_to_use);
        if const.train.patternbreak
            while patternDetect([rectifiedNumeric(perf.record),state.sequence(1,k)])
                state.sequence(1,k) = randsample(pickset,1,true,weights_to_use);
            end
        end
        %Add to exclusion
        if k<const.sequence
          excseq=[excseq;nan(1,const.sequence)];
          excseq(end,k+1)=state.sequence(1,k);
        end
      end
      state.sequence = abs(state.sequence); % TODO figure out how this is picking negatives for the first stim sometimes!      
      
      if const.sequence > 1 && const.train.discourage_short_of_pair_first
        try
        if const.info.distances(last,state.sequence(1)) < const.info.distances(last,state.sequence(2))
          state.sequence=circshift(state.sequence,1);
        end
        catch
          warndlg('discourageshortpick malfunction');
        end
      end
      
      state.sequence_queue=state.sequence;
      if const.sequence>1;   assert(sum(state.sequence>0)==const.sequence && state.sequence(1)~=state.sequence(2)); end
      
      function weights_to_use = getWeights(pickset)
        % Weighting
        weights = ones(1,numel(maze.platforms));
        lastpoke = find( ~isnan(perf.precord), 1, 'last');
        lastzone = find( ~isnan(perf.zrecord), 1, 'last');
        lz_gt_lp = perf.ztime(lastzone) > perf.ptime(lastpoke);
        if lz_gt_lp
          last = abs(perf.zrecord(lastzone)); 
        else
          last = perf.precord(lastpoke);
        end
        fprintf('\n');
        % Weight by distance
        if const.train.weightdistance
          % Figure out the last location
          fprintf('...Weighting distance!');
          weights = const.info.distances(last,:);
        end
        % Weight by performance
        if const.train.weightperf && all(~isnan(perf.percent))
            fprintf('...Weighting performance!');
            weights = weights .* (1-perf.percent);
            weights = max(weights, 0.15*max(weights));
        end

        % Constrain to pickset
        if isempty(weights) || all(weights==0); weights = ones(size(maze.platforms)); end
            weights_to_use = weights(pickset);
        end
        
        selection = state.sequence;
    end
    
    function [selection] = checksumselection(selection)
        if isnan(selection) % hacky solution to occassional nan value
          warning('Something is wrong, nan picked for platform'); 
          while isnan(selection)  
            [ps, sp] = preparestimulus();
            selection = pickstimulus(ps,sp)
          end
        end
        
    end
    
  end
  % ----------------------------------------------------------------------
  function restartStimulus_modeDependent()
    % variable calls of restart stimulus that change parameters depending on
    % maze mode
    switch const.seq.mode
    case {'cuememory', 'wtrack'}
        restartStimulus([], {'home','cue'}); % if animal gets it wrong, we do not want to proceed with a memory set of trials
    case ''
        % The following section implements the prevention of restartStimulus
        % until an animal changes zone .. if it's being called by a port or
        % zone trigger (correct or incorrect), it marks that this has happened
        % with a flag, and then, the next time this function is triggered
        % (during zone transition)
        if const.nextstim_zonecross
            if (~state.storedrestart && ~state.zonedeltaflag)
                state.zonedeltaflag = true;
                state.storedrestart = true;
                return;
            elseif state.storedrestart && state.zonedeltaflag
                return;
            else
                state.storedrestart = false;
            end
        end
        restartStimulus();
    otherwise
        restartStimulus();
    end
  end
  % ----------------------------------------------------------------------
  function allstimoff(whenclear,delay)

    if nargin == 0
      whenclear='nextstim';
      delay = 1;
    elseif nargin == 1
      delay = 1;
    end

    sendScQtControlMessage('continuous_flash=0');
    sendScQtControlMessage('stimon=0');
    sendScQtControlMessage('stimstack=0');
    sendScQtControlMessage('statescript_end=0');
    sendScQtControlMessage('pokeend_stack=0');
    for i = maze.leds
      sendScQtControlMessage(sprintf('portout[%d]=0',i));
    end

    % TODO MAKE THIS CONDITIONAL ON POKE END!
    %pause(const.dur.statescriptExecTime + const.reward.dur*1.1);
    if delay
      pause(const.dur.statescriptExecTime + const.reward.dur*1.01);
    else
      pause(const.dur.statescriptExecTime);
    end

    if isequal(whenclear,'nextstim')
      sendScQtControlMessage('clear_queue_next_stim=1');
    elseif isequal(whenclear,'reward')
      sendScQtControlMessage('clear_queue_next_rew=1');
    end

%     sendScQtControlMessage('clear queue'); % clear out the event queue! This is awesome, becuase it allows me to fix my central biggest issue with queuing statescript events.
  end
  % ----------------------------------------------------------------------
  % ----------------------------------------------------------------------
  function currentstimoff(condition)
    if nargin == 0 ; condition = 'all'; end
    
    switch condition
      case 'all'
        sendScQtControlMessage('statescript_end=0');
        sendScQtControlMessage('pokeend_stack=0');
        for i = led(state.sequence_queue)
          shutdown_message(const.seq.stim(state.sequence_queue(i)));
          sendScQtControlMessage(sprintf('portout[%d]=0',led(state.sequence(i))));
        end
        sendScQtControlMessage('clear_queue_next_stim=1');
      case 'shown'
        for i = led(state.sequence_queue(1:state.seq.shown))
          shutdown_message(const.seq.stim(state.sequence_queue(i)));
          sendScQtControlMessage(sprintf('portout[%d]=0',led(state.sequence(i))));
        end
      case 'exceptunshown'
        for i = setdiff(maze.leds,led(1:state.seq.shown-1))
          sendScQtControlMessage(sprintf('portout[%d]=0',led(state.sequence(i))));
        end
      otherwise
        if isnumeric(condition)
          for i = condition
            shutdown_message(const.seq.stim(i));
            sendScQtControlMessage(sprintf('portout[%d]=0',led(state.sequence(i))));
          end
        end
    end
     
    % --------------------------------------------------------------------
    % Function : shutdown_message
    % Purpose  : Triggers a proper shutdown for the given TYPE of stimulus
    % Input    : statescript function number of stimuli
    % --------------------------------------------------------------------
    function shutdown_message(in)
      switch in
        case 11, sendScQtControlMessage('stimon=0'); sendScQtControlMessage('stimstack=0');
        case 17, sendScQtControlMessage('continuous_flash=0;');
      end
    end
  end
  % ----------------------------------------------------------------------
  % Function : adapt
  % Purpose  : increases or decreases difficulty for various apation
  %             sensative measures.
  % Input    : The direction of adaption, up or down
  % ----------------------------------------------------------------------
  function adapt(dir)
    for f = fieldnames(const.adapt)
        f = f{1};
        if const.adapt.(f).flag 
            switch dir
              case 'up'
                if isfield(const.adapt.(f),'upfunc')
                    eval(state.adapt.(f).upfunc);
                else
                    state.adapt.(f) = min(const.adapt.(f).max, state.adapt.(f)+(const.adapt.(f).stepup)*(const.adapt.(f).max-state.adapt.(f)));
                end 
              case 'down'
                if isfield(const.adapt.(f),'downfunc')
                    eval(const.adapt.(f).downfunc);
                else
                    state.adapt.(f) = max(const.adapt.(f).min, state.adapt.(f)-(const.adapt.(f).stepdown)*(state.adapt.(f)-const.adapt.(f).min));
                end
            end
            sendScQtControlMessage(sprintf('stim_duration=%d',round(state.adapt.(f))));
            perf.adapt.(f)(end+1) = state.adapt.(f);
        end
    end
    perf.adapt.time(end+1) = currtime;
    guiUpdate();
  end
  % ----------------------------------------------------------------------
  % ----------------------------------------------------------------------
  function blocklockout(bstate)
    if strcmp(const.seq.mode,'alternate')
      return;
    end
    
    if bstate==true
      state.sequence_queue=nan(1,const.sequence);
      state.sequence=nan(1,const.sequence);
      allstimoff('reward',false);
      sendScQtControlMessage('trigger(16);');
      if ~strcmp(tones.Tag,'on')
        fprintf('Playing sound!');
        tones.Tag='on';
        tones.stop();
        tones.play();
        state.blocklockout=true;
        % If next stimulus is supposed to be last before blocklockout, then
        % set that
%         if const.blocklockout.resartlast.flag
% %           const.blocklockout.restartlast.value = ;
%         end
      else
        if ~state.blocklockout
          fprintf('Playing sound! ');
          tones.stop();
          tones.play();
        end
      end

        state.btime(end+1) = currtime;

        % Record nans such that when return from blocklockout time lockouts
        % always evaluate to false AND alternation is always true.
        perf.precord(end+1) = nan;
        perf.ptime(end+1)   = nan;

    else % bstate == false
      
      state.afterblocklockout=true;
      fprintf('Sound off! ');
      tones.Tag='off';
      tones.pause();
      state.blocklockout=false;
      state.bcount=0;
      sendScQtControlMessage('clear queue');
      sendScQtControlMessage('block_stack=0');
      tones.stop();
      
    end
  end
	% ======================================================================	
 	% =========================== Parsing ==================================  		
    % ======================================================================
  function [out,rem] = scclock(newline)
      % Obtains the current time for a message
      [out,rem] = strtok(newline,' ');
      out=str2double(out);
      if out == 0
        global scQtControllerOutput
        % Fetch last time
        if isempty(scQtControllerOutput); return; end
        out = strtok(scQtControllerOutput{end});
        index = 0; nEntries=numel(scQtControllerOutput);
        while ~any(isstrprop(out,'digit')) && index < nEntries
          index=index+1;
          try
            out = strtok(scQtControllerOutput{end-index});
          catch
            return;
          end
        end
        out=str2double(out);
      end
  end
  % ----------------------------------------------------------------------
  % ----------------------------------------------------------------------
  function [din,dout,rem] = portstate(newline)
      % Reads digital port in and digital port
      % out from statescripts input/output numbers
			
      din = false(64,1);
      dout = false(64,1);

      % DIN
      [temp,rem] = strtok(newline,' ');
      temp = logical( dec2bin(round(str2double(temp))) - 48 ); % Convert to logical array
      temp = temp(end:-1:1); % Reverse the order
      din(1:numel(temp))=temp;

      % DOUT
      [temp,rem] = strtok(rem,' ');
      temp = logical(dec2bin(round(str2double(temp)))-48); % Convert to logical array
      temp=temp(end:-1:1); % Reverse the order
      dout(1:numel(temp))=temp;
  end
  % ------- Command Helper Functions
  function summary()
    if const.adapt.wm.on

    end

  end
  function savestate(savefile)
    savefile=strtrim(savefile);
    % Executes a save of the callback state and plots
    w=who;
    file =  sprintf('goalmaze_callback_state_(%s).mat',savefile);
    file=fullfile(pwd,file);
    if exist(file,'file')
      answer=questdlg('File already exists. Do you want to overwrite this?','Overwrite','yes','no','no');
      switch answer
        case 'yes', fprintf('Overwriting...');
        case 'no', return
      end
    end
    sendScQtControlMessage(sprintf('disp(''Saving %s ...'')',savefile));
    save(file,w{:});
    % Save the figure
    try 
        fg = figure(1);
        screensize = get( groot, 'Screensize' );
        screensize(3:4) = screensize(3:4) - 1;
        temppos = get(fg,'Position');
        fg.Position = screensize;
        figfile = sprintf('Graph_(%s)',savefile);
        savefig(fg,figfile); 
        saveas(fg,[figfile '.png']);
        fg.Position = temppos;
        drawnow;
    catch ME; 
        ME 
    end
    % Save the code used
    try eval(['!cp ' which(mfilename('fullpath')) ' ' sprintf('Code_%s.m',savefile) ]); catch ME; ME; end
    % Write the session notes to a file
    if isfield(state,'sessionnotes')
      fid = fopen(sprintf('Notes_(%s)',savefile),'w');
      if fid ~= -1
        fwrite(fid,[state.sessionnotes repmat(sprintf('\n'),size(state.sessionnotes,1),1)]');
        fclose(fid);
      end
    end
%     savefig(sprintf('PokeRewardRecord_(%s)',savefile),figure(2));
  end
  % ----------------------------------------------------------------------
  % ----------------------------------------------------------------------
  function reportstate()
      % Reports the state of key variables
      %vars={'trialstack','reward','light'};
      vars=who;
      for v=vars'
        eval(v{1})
        if isstruct(eval(v{1}))
          evalin('base', ['global ' v{1} '; open(''' v{1} ''')']);
        end
      end
      
      % TODO Find a better way to generate and pop-up values
%       any2csv(s,',',1,'tmp.csv');
%       if isunix
%         if ismac
%           !open tmp.csv;
%         else
%           !xdg-open tmp.csv;
%         end
%       end
      
  end
  function assertiontester()
    assert(numel(perf.record)  == numel(perf.time));
    assert(numel(perf.precord) == numel(perf.ptime));
    assert(numel(perf.zrecord) == numel(perf.ztime));
    assert(numel(perf.brecord) == numel(perf.btime));
  end
  function stopall()
    sendScQtControlMessage('clear queue');
    sendScQtControlMessage('block_stack=0');
    state.blocklockout=false;
  end
  function out = seqN()
      out =  numel(state.sequence) - numel(state.sequence_queue) + 1;
  end
  function trialchecksum()
    if ~ismember(state.sequence,maze.home) && strcmp(state.trialtype{1},'home')
      state.trialtype{1}='normal';
    end
  end
  function modeswitch(mode)
    % Handles any variable changes required for mode switch
    switch mode
        % Zone-based modes (requires camera)
      case 'normal',   const.seq.stim      = [11 11];
        sendScQtControlMessage('ir_stim_to_terminate=11')
      case 'crosson' , const.seq.stim      = [11 17];
      case 'crossoff', const.seq.stim      = [11 17];
        % Simulataenous presentation modes, sequence stimuli presented at once, either same or diff
      case 'differentiate', const.seq.stim = [11 17];
      case 'simultaneous', const.seq.stim  = [11 11];
        % Miscellaneous modes
      case 'alternate', const.seq.stim     = [nan nan];
      case 'cuememory', const.seq.stim        = [11 17];
        sendScQtControlMessage('ir_stim_to_terminate=17')
    end
  end
  % Maze Input and Platform numbering shortcuts
  function L = led(platform)
  % Takes a platform number and outputs the led
    L = maze.leds(platform)
  end
  function P = platform(input,opt)
  % Takes a platform num and outputs input number
    if islogical(input); input=find(input); end
    P = ismember(maze.inputs, input);
    if strcmp(opt,'find')
        P = find(P);
    end
  end
  function input(platform)
  % Takes a platform num and outputs input number
    I = maze.inputs(platform);
  end


  function mazedistances(maze)
    switch maze
    case '2x2
        dist                 = [0 38.5 54.5 38.5 0;
                                38.5 0 38.5 54.5 0;
                                54.5 38.5 0 38.5 0;
                                38.5 54.5 38.5 0 0
                                42   73   73 42  0]; % TRUE Distances between each well -- used for a modes that incentivize or preferentially select wells at longer distances (because when the task gets hard, in terms of cue duration, animals pick shorter paths)
        dist(dist == 54.5) = 38.5*2; % tempoary: setting up the
    otherwise
        error('Distances for %s have not been implemented yet!', maze)
  end

  %function set_mode(hObject)
  %  % --- Set Mode --- 
  %  switch hObject.String
  %  case 'Show sequential'
  %      const.seq.mode = 'normal';
  %      const.seq.stim = [11 11];
  %      addtonotes('Mode = Sequential');
  %  case 'Show simultaneous, different lighting'
  %      const.seq.mode = 'differentiate';
  %      const.seq.stim = [11 17];
  %      addtonotes('Mode=Simultaneous');
  %  case 'Show simultaneous, same lighting'
  %      const.seq.stim = [11 11];
  %      cons.seq.mode = 'simultaneous';
  %  case 'Second stim on zone cross'
  %      const.seq.stim = [11 17];
  %      const.seq.mode = 'crosson';
  %      addtonotes('Mode=CrossOn');
  %  case 'Second stim off zone cross'
  %      const.seq.mode = 'crossoff';
  %      const.seq.stim = [11 17];
  %      addtonotes('Mode=CrossOff');
  %  case 'Well alternation'
  %      const.seq.stim = [nan nan];
  %      const.seq.mode = 'alternate';
  %  case 'Cue then memory trial mode'
  %      const.seq.stim = [11 11];
  %      const.seq.mode = 'cuememory';
  %  otherwise
  %      error(sprintf('%s does not match any options',hObject.String),'Invalid selection');
  %  end
  %end

  %% Other possible callback globals available
  %   global scQtHistory; %multipurpose place to store processed event history
  %   global scQtControllerOutput; %the text output from the microcontroller
  %   global scQtCallBackHandle; %the handle to the function called for every new event

end
