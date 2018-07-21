% V2 UPDATES Computes only the components to target and the countdown intervals
% The rest of the maze logic is handled by a matlab script, for reason that
% controlling from matlab also makes it easier to make quick changes and to
% integrate well with continuous result plots.

% Name
% -----
% 2x2 Goal Fetch Maze
%
% Author
% --------
% Ryan Y.
%
% Instructions
% -------
% This statescript file uses the C++ preprocessor to enable more readable code and
% for variables to be extended to callbacks. It enables you to NAME your
% statescript functions. It also prevents having to re-write when changing
% port numbers across the file.
%
% Before using this statescript file, you must send it through the C++
% preprocessor (a painless single command). Simply type,
%
% ' mcpp goalmaze.csc goalmaze.sc '
%
% and it runs the C++ preprocessor, performing simply subsitution on the #define
% directives. The end product is a statescript code. This approach make it EASIER
% for the coder and the reader.
%
% Maze Operation
% --------------
% Every 20 seconds, a new platform is randomly chosen to cue. The animal then
% has an opportunity to visit the well and receive reward.
% 
% TODO Update docstring
% ------------------------------------------------

% ==============================================================
% ==================== Digtal I/Os =============================
% ==============================================================

% INPUTS
% Statescript Poke Inputs
int poke1 =  1;
int poke2 =  2
int poke3 =  3
int poke4 =  4  
int pokeHome = 5
% Statescript control inputs
int startTask = 21

% OUTPUTS
% Digital output  LEDs
int led1    = 17
int led2    = 18
int led3    = 19
int led4    = 20
int ledHome = 21;

% For this first iteration, tone and light are on the same dio channel

% Digital output TONEs
int tone1    = 1
int tone2    = 2
int tone3    = 3
int tone4    = 4;
int toneHome = 5;

% Digital output REWARDs
int reward1    = 6
int reward2    = 7
int reward3    = 8
int reward4    = 9;
int rewardHome = 10;

% ==============================================================
% ==============TASK PARAMETERS AND CONSTANTS===================
% ==============================================================
% TODO BRING ORDER to this :(
int reset_dur = 20000

int reward_dur = 1200
int remind_dur = 10000
int stimstack  = 0

int check_cycle     = 1
int statescript_end = 0

int remind = 0;

int flash_dur               = 150
int flash_iti               = 70
int flash_count             = 10
int flash_counter           = 0
%int flash_stim_duration     = 10000
int continuous_flash        = 0;
int continuous_flash_period = 575;

% How often to check whether time is up
int timepoint   = 1
int initialized = 0 ;

% Output selectors
int light  = 0
int reward = 0
int true   = 1 ;

int trialstack=0
int flashstack=0;

% ==============================================================
% ==================== FUNCTIONS ===============================
% ==============================================================

% --------------------------------------------------------------
% CUE TYPE 1: Discrete stimulus presentation function
% --------------------------------------------------------------
int stimon=0
int stim_duration = 750
int clear_queue_next_stim=0
function 11
  %stimon=0
  if clear_queue_next_stim==1 do
    clear queue
    clear_queue_next_stim = 0
    stimstack             = 0
  end
  stimstack      = stimstack+1
  portout[light] = 1
  stimon         = 1
  statescript_end       = 1      % tracks whether or not statescript itself is allowed to perform it's stimulus end: matlab part has its own killswitch -- matlab can flip this to 0 and void a future destrcution
  disp(stim_duration)
  while stimon == 1 do every check_cycle
	%disp('cycle')
  then do
	%disp('here')
  	if statescript_end == 1 && stimstack <= 0 do
  		portout[led1]    = 0
  		portout[led2]    = 0
  		portout[led3]    = 0
  		portout[led4]    = 0
  		portout[ledHome] = 0
      	stimstack        = 0
  	end
  end
end;

% --------------------------------------------------------------
% REWARD PRESENTATION FUNCTION
% --------------------------------------------------------------
int clear_queue_next_rew=0;
function 12
  disp('Rewarding ...')
  disp(reward)
  if clear_queue_next_rew == 0 do
    clear queue % somehow this is executing AFTER stimulus restarts ... which seems impossible unless matlab is executing unbelievably fast ... can try to wait for a message
    clear_queue_next_rew = 0
    disp('...RQC') % reward cue cleared
  end
  disp('...RF') % reward cue cleared
  portout[reward]   = 1
  do in reward_dur
    portout[reward] = 0
  end
end;

% --------------------------------------------------------------
% Discrete count flash SUBFUNCTION
% --------------------------------------------------------------%
function 14
  flashstack = flashstack - 1
  if (flashstack == 0) do
	   flash_counter = flash_count
      if (trialstack == 1) do
        while (flash_counter > 0) do every flash_iti
		      portout[light]=1
            do in flash_dur
			         portout[light] = 0
            end
          flash_counter=0
	       end
         flashstack     = 0
         portout[light] = 0
     end
  end
end;

% --------------------------------------------------------------
% Trial timer
% --------------------------------------------------------------
function 13
  trialstack = trialstack + 1
  disp(trialstack)
  if (trialstack == 1) do
	disp('cstart')
	if (remind == 1) do in remind_dur
		flashstack = flashstack + 1
      trigger(14)
	end
  end
  do in reset_dur
      trialstack = trialstack - 1
      disp(trialstack)
      if ( trialstack == 0 ) do
        disp('cend')
	  %trigger(13)
       % Just in case there is another asynchronous block that is pushing the the stack during this, make the stack pop to 0
      end
  end
end;

% --------------------------------------------------------------
% Continuous light flash SUBFUNCTION
% --------------------------------------------------------------
function 15
  while continuous_flash == 1 do every continuous_flash_period
      portout[light] = 1
      do in flash_dur
    		portout[light] = 0
    	end
    end
end;

% --------------------------------------------------------------
% Sound Error
% --------------------------------------------------------------
int error_on = 0
function 19
	sound('error.wav')
end;

% --------------------------------------------------------------
% Block lockout function
% --------------------------------------------------------------
int blocklockout_period = 3000
int block_stack = 0
function 16
	disp('blocklockout start')
	block_stack = block_stack+1
	disp(block_stack)
	do in blocklockout_period
		block_stack  = block_stack  - 1
		disp(block_stack)
		if ( block_stack == 0 ) do
			disp('blocklockout end')
		end
	end
end;

% --------------------------------------------------------------
% Cue Type 2: Time continuous light flash function
% --------------------------------------------------------------
int clear_queue_next_stim=0
function 17
  if clear_queue_next_stim == 1 do
    clear queue
    clear_queue_next_stim = 0
    block_stack           = 0
    trialstack            = 0
  end
  continuous_flash = 1
  trigger(15) % turn on cotinuous light flash
end;

% --------------------------------------------------------------
% Nose poke end detection
% ... operationalizes when a poke truly ends (often it triggers
% on and off while the animal licks.
% -------------------------------------------------------------- 
int pokeend_stack = 0
int pokeend_dur = 1000
function 18
	pokeend_stack = pokeend_stack+1
	do in pokeend_dur
		%disp('Checking')
		pokeend_stack= pokeend_stack-1
		if pokeend_stack == 0 do
			disp('function 18 : port END')
		end
	end
end;

% --------------------------------------------------------------
% CUE TYPE 1: Extension! Extend length
% Purpose: Extends the length of actively running stimuli
% --------------------------------------------------------------
function 20

disp('stim extension!')
  stimstack       = stimstack+1
  statescript_end = 1
  disp(stim_duration)

  if stimon == 1 do 
	%disp('cycle')
  	if statescript_end == 1 && stimstack <= 0 do
  		portout[led1]    = 0
  		portout[led2]    = 0
  		portout[led3]    = 0
  		portout[led4]    = 0
  		portout[ledHome] = 0
      	stimstack        = 0
  	end
  end
end;

int terminal_ir_mode = 0
int termirstack = 0
int ir_stim_to_terminate = 11
function 21
    disp('function 21 : terminate by ir')
    termirstack     = termirstack + 1
    statescript_end = 1      % tracks whether or not statescript itself is allowed to perform it's stimulus end: matlab part has its own killswitch -- matlab can flip this to 0 and void a future destrcution
    %disp(stim_duration)
    if (terminal_ir_mode == 1) do in stim_duration
          termirstack = termirstack - 1
          if termirstack <= 0 do
              disp('function 21 : commanding stim to end')
              if ir_stim_to_terminate == 11 do
                  stimon      = 0
                  disp('function 21 : of type 11')
              else if ir_stim_to_terminate == 17 do
                  continuous_flash = 0
                  disp('function 21 : of type 17')
              end
              continuous_flash = 0
              termirstack = 0
          end
    end
    while stimon == 1 do every check_cycle
      %disp('cycle')
    then do
      %disp('here')
      if statescript_end == 1 && termirstack <= 0 do
          portout[led1]    = 0
          portout[led2]    = 0
          portout[led3]    = 0
          portout[led4]    = 0
          portout[ledHome] = 0
          termirstack      = 0
      end
    end
end;

% ==============================================================
% ==================== ZONE TRIGGERS ===========================
% ==============================================================
function 1
	disp('zone 1 enter')
end;
function 2
	disp('zone 2 enter')
end;
function 3
	disp('zone 3 enter')
end;
function 4
	disp('zone 4 enter')
end;
function 5
	disp('zone 1 exit')
end;
function 6
	disp('zone 2 exit')
end;
function 7
	disp('zone 3 exit')
end;
function 8
	disp('zone 4 exit')
end;

% ==============================================================
% ================== CALLBACK REPORTS ==========================
% ==============================================================
% ---- Port  16  ----
callback portin[1] up
  %disp('port POKE 1 up')
end
callback portin[1] down
  %disp('port POKE 1 down')
  trigger(18)
end;
% ---- Port  17  ----
callback portin[2] up
  %disp('port POKE 2 up')
end;
callback portin[2] down
  %disp('port POKE 2 down')
  trigger(18)
end;
% ---- Port  18  ----
callback portin[3] up
  %disp('port POKE 3 up')
end;

callback portin[3] down
  %disp('port POKE 3 down')
  trigger(18)
end;
% ---- Port  19  ----
callback portin[4] up
  disp('port POKE 4 up')
end
callback portin[4] down
  disp('port POKE 4 down')
  trigger(18)
end;
% ---- Port  19  ----
callback portin[5] up
  %disp('port POKE 5 up')
end
callback portin[5] down
  %disp('port POKE 5 down')
  trigger(18)
end;
% ---- Port  19  ----
callback portin[6] up
  %disp('port POKE 5 up')
end
callback portin[6] down
  %disp('port POKE 5 down')
  trigger(18)
end;

% --- IR BEAMS --- 
callback portin[13] up
  disp('port HOMEIR up')
end
callback portin[13] down
  disp('port HOMEIR down')
end;
int hometrial = 0
callback portin[12] up
  disp('port TRIALIR up and home trial is')
  disp(hometrial)
end
callback portin[12] down
  disp('port TRIALIR down')
 termirstack=0
  if terminal_ir_mode == 1 && hometrial == 0 do
      trigger(21)
  end
end;
callback portin[15] up
  disp('port TRIALIR up and home trial is')
  disp(hometrial)
end
callback portin[15] down
  disp('port TRIALIR down')
 termirstack=0
  if terminal_ir_mode == 1 && hometrial == 0 do
      trigger(21)
  end
end;

disp('compile end');
