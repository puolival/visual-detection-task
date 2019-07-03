%% Detection threshold calibration procedure
%
% Author: Tuomas Puoliväli (tuomas.puolivali@helsinki.fi).
% Last modified: 8th August 2018.
% License: 3-clause BSD
% Source: https://github.com/puolival/closed-loop
%
% This program is used to find an individual's detection threshold for the 
% closed-loop visual detection experiment.
%
% PREPARATIONS:
%
% The widths and heights of the fixation cross, target stimulus, and mask 
% are specified in degrees of visual angle, which depend on
%   (1) viewing distance (cm), and
%   (2) physical width and height of the monitor (cm)
% Please start by measuring these dimensions and adjusting the settings 
% accordingly.
%
% The trial structure is (at least for now) specified in numbers of frames.
% Since the duration of a frame is defined by the monitor refresh rate, it
% is important to start by selecting the refresh rate to get correct
% durations in seconds.
%
% NOTES:
%
% PsychToolbox might need to consume more Java heap memory than is allowed 
% by default in MATLAB. The maximum amount can be increased via HOME -> 
% Preferences -> General -> Java Heap Memory. 1024 MB has been sufficient
% for running this program without errors. [I don't know yet why 386 MB 
% of heap memory would not be sufficient, which is the MATLAB default 
% value.]
%
% NETSTATION EVENTS:
%
% STIM - Sent after a stimulus has been displayed. The onset time is the 
%        VBL from the Screen('Flip') command.
% CATC - Sent after a catch trial has been "displayed". Onset time is VBL.
% PRES - Sent when the participant responds "stimulus present".
% ABSE - Sent when the participant responds "stimulus absent".
%
% Thanks to Peter Scarfe for making available simple & well-commented
% PsychToolbox examples [1], which helped writing this program.
%
% REFERENCES:
%
% [1] Scarfe P. Accurate Timing Demo. Online; Accessed 20th November 2017.
% URL: http://peterscarfe.com/accuratetimingdemo.html
%
clear all; clc;

%% Settings: NetStation
% A flag for deciding whether to send triggers to EGI NetStation.
use_netstation = 0;
% If true, no user input is needed. The program will proceed after a random
% delay.
timing_test = 0;
% Available options are:
%   1 - Same y-coordinate with stimulus but on the right side of screen
%   2 - In place of stimulus
photodetector_square_location = 1;

%% Settings: Paths
ptb_path = 'C:\Users\Mirness\Desktop\closed-loop\ptb3';
palamedes_path = 'C:\Users\Mirness\Desktop\closed-loop\palamedes182';
datapixx_path = strcat('C:\Program Files\VPixx Technologies\', ...
    'Software Tools\DatapixxToolbox_trunk\mexdev\build\matlab\win64');

participant_identifier = input_required(strcat('Please input a', ...
    ' unique participant identifier\n'), 's');
save_path = 'C:\Users\Mirness\Desktop\closed-loop\data';

%% Settings: Set seed for the random number generator.
% Save important settings into a MATLAB structure so that saving them into
% a .MAT file is easier later on.
cfg = struct;
cfg.now = datestr(now, 'dd-mm-yyyy HH:MM:SS');

% MATLAB default settings will reset the PRNG seed to the same value at 
% each startup. To avoid having the same random numbers for several 
% participants, and to make everything reproducible, set a participant 
% specific seed.
cfg.participant_prng_seed = input_required(...
    'Please input a random seed for the PRNG\n', 'd');
rng(cfg.participant_prng_seed);

%% Settings: Experimental environment and stimuli
% Monitor and viewing distance
cfg.viewing_distance = 100; % cm
cfg.screen_physical_width = 53.3; % cm
cfg.screen_physical_height = 30; % cm

% Fixation cross
cfg.fixation_cross_horizontal_visual_angle = 0.3; % degrees
cfg.fixation_cross_vertical_visual_angle = 0.3; % degrees
cfg.fixation_cross_answer_color = [0.0, 0.5, 0.0, 1]; % RGBA

% Make the fixation cross isoluminant for neutral/answer colors.
% For now, this is achieved through a conversion to NTSC color space
% and back.
fixation_cross_yiq = rgb2ntsc(cfg.fixation_cross_answer_color(1:3));
fixation_cross_rgb = ntsc2rgb([fixation_cross_yiq(1), 0, 0]);
cfg.fixation_cross_neutral_color = [fixation_cross_rgb(1), ...
    fixation_cross_rgb(2), fixation_cross_rgb(3), 1]; % RGBA

% Target 
cfg.gabor_horizontal_visual_angle = 2.5; % degrees
cfg.gabor_vertical_visual_angle = 2.5; % degrees
cfg.gabor_color = [0.75, 0.75, 0.75, 1]; % RGBA

%% Settings: Input
% Keyboard keys used to provide answers
cfg.key_stim_present = 90; % = 'z' on a standard keyboard
cfg.key_stim_absent = 78; % = 'm' on a standard keyboard
cfg.key_escape = 27; % = ESC on a standard keyboard

%% Settings: Trial structure and number of trials
cfg.n_stimulus_trials = 30;
cfg.n_catch_trials = 30;
n_trials = cfg.n_stimulus_trials + cfg.n_catch_trials;

cfg.n_min_prestim_frames = 150; % = 1.5 s if 100 Hz monitor
cfg.n_max_prestim_frames = 300;
cfg.n_target_frames = 2;
cfg.n_min_delay_frames = 75; % after target
cfg.n_max_delay_frames = 125; % after target
cfg.n_max_response_frames = 300; % = 3 seconds

%% Connect to EGI NetStation
if (use_netstation) 
    NetStation('Connect', '10.10.10.42');
    NetStation('GetNTPSynchronize', '10.10.10.51');
    NetStation('StartRecording');
end

%% Prepare output directory.
% Create the output directory (<save_path>\<participant_identifier>\) if 
% it does not exist yet.
spath = strcat(save_path, '\', participant_identifier);
if ~exist(spath, 'dir')
    mkdir(spath);
else
    if (exist(strcat(spath, '\threshold.mat'), 'file'))
        error('Please give a unique participant identifier!');
    else
        % If the output directory exists but the threshold.mat file does
        % not then perhaps starting the program did not succeed on first
        % attempt. Allow continuation.
    end
end

%% Initialize Psychtoolbox and Palamedes.
cfg.ptb_init_verbose = 0; % set as 1 to print added paths
cfg.palamedes_init_verbose = 0; % set as 1 to print added paths
init_ptb(ptb_path, cfg.ptb_init_verbose);
init_palamedes(palamedes_path, cfg.palamedes_init_verbose);
%init_datapixx_lib(datapixx_path);

%% Initialize the screen
[window_ptr, window_center_x, window_center_y, ...
    screen_width_px, screen_height_px, bgcolor] = ptb_init_screen();

% Retrieve the inter-frame-interval.
cfg.ifi = Screen('GetFlipInterval', window_ptr);

%% Make gabor patch
[gabor_width, gabor_height] = visual_angle_to_stimulus_size(...
    cfg.gabor_horizontal_visual_angle, cfg.gabor_vertical_visual_angle, ...
    cfg.screen_physical_width, cfg.screen_physical_height, ...
    cfg.viewing_distance, screen_width_px, screen_height_px);

% Define the Gabor patch appearance.
cfg.gabor_size = gabor_width;
cfg.gabor_phase = 0; % degrees
cfg.gabor_num_cycles = 9; 
cfg.gabor_sigma = cfg.gabor_size / 5;
cfg.gabor_freq = cfg.gabor_num_cycles / cfg.gabor_size; % Hz?

% Create the gabor.
gabor_texture = CreateProceduralGabor(window_ptr, gabor_width, ...
    gabor_height, [], [bgcolor, bgcolor, bgcolor, 1], 1, 0.5);

%% Fixation cross settings
% Compute the width in pixels
[fixation_cross_width, ~] = visual_angle_to_stimulus_size(...
    cfg.fixation_cross_horizontal_visual_angle, ...
    cfg.fixation_cross_vertical_visual_angle, ...
    cfg.screen_physical_width, cfg.screen_physical_height, ...
    cfg.viewing_distance, screen_width_px, screen_height_px);

cfg.fxhw = round(fixation_cross_width / 2); % half-width

%% Photodetector rectangle
if (photodetector_square_location == 1)
    % Same y-coordinate with stimulus but on the right side of screen.
    photodetector_rect = [screen_width_px-100, window_center_y - ...
        cfg.gabor_size/2, screen_width_px, ...
        window_center_y+cfg.gabor_size/2];
elseif (photodetector_square_location == 2)
    % Draw in place of stimulus.
    photodetector_rect = [window_center_x-100, window_center_y - 100, ...
        window_center_x+100, window_center_y+100];
else
    error('Unknown photodetector location mode!');
end

%% Initialize the Palamedes data structure
% PM = PAL_AMRF_setupRF('priorAlphaRange', 0:0.0001:0.5, ...
%     'stopCriterion', 'reversals', 'stopRule', 15, 'PF', @PAL_Logistic, ...
%     'xMin', 0, 'xMax', 0.5);

PM = PAL_AMUD_setupUD('stopCriterion', 'reversals', 'stopRule', 15, ...
    'xMin', 0, 'xMax', 0.25, 'stepSizeUp', 0.01, ...
    'stepSizeDown', 0.01, 'startValue', 0.25);

%% Draw random stimulation and Gabor orientation sequences
% The value 1 is used to refer to stimulus trials and the value 0 is used
% to refer to catch trials.
stim_present = [ones(cfg.n_stimulus_trials, 1); ...
    zeros(cfg.n_catch_trials, 1)]; 
stim_present = stim_present(randperm(n_trials));

PM.stim_present = stim_present;
PM.stim_angle = randi([0, 359], [n_trials, 1]);
PM.answer = nan(n_trials, 1);
PM.stim_onset = nan(n_trials, 1);

cfg.prestim_frames = randi([cfg.n_min_prestim_frames, ...
    cfg.n_max_prestim_frames], n_trials, 1);
cfg.n_delay_frames = randi([cfg.n_min_delay_frames, ...
    cfg.n_max_delay_frames], n_trials, 1);

%% Load pre-computed Perlin noise data from disk.
noise_path = strcat('C:\Users\Mirness\Desktop\closed-loop', ...
    '\perlin_noise.mat');
noise_data = load(noise_path);

% Extract the Perlin noise from the file (keep only one color channel 
% since it is gray-scale) and discard other data.
perlin_noise = squeeze(noise_data.X(:, :, :, 1));
clear noise_data;
[n_noise_frames, ~, ~] = size(perlin_noise);

[~, perlin_width, perlin_height] = size(perlin_noise);
[noise_texture, noise_rect] = make_perlin_noise(window_ptr, ...
    perlin_width, perlin_height);

%% Perlin noise interpolation settings.
noise_frame_ind = 1;
noise_interp_step = 1;
cfg.n_noise_interp_steps = 1000;

%% Get VBL
vbl = Screen('Flip', window_ptr);

%% Instructions
% Inform the participant that the experiment is about to begin.
timer = 10;
screen_capture_taken = 0;

for i = 1:1000 % 5 seconds    
    % Show the message
    if (mod(i, 100) == 0 && i > 0)
        timer = timer - 1;
    end
    msg = sprintf(strcat('Starting in %d seconds ..\n\n\n\n', ...
        'Press %s for YES and %s for NO'), timer, ...
        char(cfg.key_stim_present), char(cfg.key_stim_absent));
    DrawFormattedText(window_ptr, msg, 'center', ...
        window_center_y-cfg.gabor_size/2-40, [0, 0.45, 0, 1]);
    % Update the screen.
    vbl = Screen('Flip', window_ptr, vbl + 0.5 * cfg.ifi);     
end

%% Main program
trial = 1;
exit_experiment = 0;

while ~PM.stop && trial <= n_trials
    % Pre-stimulus fixation cross
    for i = 1:cfg.prestim_frames(trial)
        % Draw the Perlin noise
        [noise_texture, noise_interp_step, noise_frame_ind] = ...
            update_noise(window_ptr, perlin_noise, noise_frame_ind, ...
            noise_interp_step, cfg.n_noise_interp_steps);      
        draw_perlin_noise(window_ptr, window_center_x, ...
            window_center_y, noise_texture, noise_rect, trial);
        % Draw the fixation cross.
        draw_fixation_cross(window_ptr, ...
            cfg.fixation_cross_neutral_color, window_center_x, ...
            window_center_y, cfg.fxhw);
        % Draw photodetector square.
        if (timing_test)
            draw_photodetector_square(window_ptr, 1, ...
                photodetector_rect); %#ok
        end
        % Update the screen.
        vbl = Screen('Flip', window_ptr, vbl + 0.5 * cfg.ifi);
        Screen('Close', noise_texture);
    end
    
    for i = 1:cfg.n_target_frames
        % Draw the Perlin noise
        [noise_texture, noise_interp_step, noise_frame_ind] = ...
            update_noise(window_ptr, perlin_noise, noise_frame_ind, ...
            noise_interp_step, cfg.n_noise_interp_steps);             
        draw_perlin_noise(window_ptr, window_center_x, ...
            window_center_y, noise_texture, noise_rect, trial);       
        % PM.xCurrent is the gabor contrast
        gabor_settings = [cfg.gabor_phase, cfg.gabor_freq, ...
            cfg.gabor_sigma, PM.xCurrent, 1.0, 0, 0, 0]';
        % Draw the Gabor
        if (stim_present(trial))
            Screen('BlendFunction', window_ptr, ...
                GL_ONE_MINUS_SRC_ALPHA, GL_SRC_ALPHA);
            Screen('DrawTextures', window_ptr, gabor_texture, [], [], ...
                 PM.stim_angle(trial), [], 0.5, [], [], ...
                 kPsychDontDoRotation, gabor_settings);
            Screen('BlendFunction', window_ptr, GL_ONE, GL_ZERO);
        end
        % Draw the fixation cross.
        draw_fixation_cross(window_ptr, ... 
            cfg.fixation_cross_neutral_color, window_center_x, ...
            window_center_y, cfg.fxhw);
        % Draw photodetector square
        if (timing_test)
            draw_photodetector_square(window_ptr, 2, ...
                photodetector_rect); %#ok
        end
        % Update the screen.
        [vbl, stim_onset_time] = Screen('Flip', window_ptr, ...
            vbl + 0.5 * cfg.ifi);
        PM.stim_onset(trial) = stim_onset_time;
        Screen('Close', noise_texture);
        % Send trigger to Netstation
        if (use_netstation)
            if (stim_present(trial)) %#ok
                NetStation('Event', 'STIM', vbl, cfg.n_target_frames * ...
                    cfg.ifi, 'sti#', trial);
            else
                NetStation('Event', 'CATC', vbl, cfg.n_target_frames * ...
                    cfg.ifi, 'cat#', trial);                
            end
        end                        
    end

    % Delay
    for i = 1:cfg.n_delay_frames(trial)
        % Draw the Perlin noise
        [noise_texture, noise_interp_step, noise_frame_ind] = ...
            update_noise(window_ptr, perlin_noise, noise_frame_ind, ...
            noise_interp_step, cfg.n_noise_interp_steps);             
        draw_perlin_noise(window_ptr, window_center_x, ...
            window_center_y, noise_texture, noise_rect, trial);       
        % Draw the fixation cross.
        draw_fixation_cross(window_ptr, ...
            cfg.fixation_cross_neutral_color, window_center_x, ...
            window_center_y, cfg.fxhw);
        % Draw photodetector square
        if (timing_test)
            draw_photodetector_square(window_ptr, 1, ...
                photodetector_rect); %#ok
        end
        % Update the screen.
        vbl = Screen('Flip', window_ptr, vbl + 0.5 * cfg.ifi);
        Screen('Close', noise_texture);       
    end

    % Response frames
    response_frame = 0;
    while 1
        % Draw the Perlin noise
        [noise_texture, noise_interp_step, noise_frame_ind] = ...
            update_noise(window_ptr, perlin_noise, noise_frame_ind, ...
            noise_interp_step, cfg.n_noise_interp_steps);             
        draw_perlin_noise(window_ptr, window_center_x, ...
            window_center_y, noise_texture, noise_rect, trial);        
        %Draw the fixation cross.
        draw_fixation_cross(window_ptr, ...
            cfg.fixation_cross_answer_color, window_center_x, ...
            window_center_y, cfg.fxhw);
        % Draw photodetector square
        if (timing_test)
            draw_photodetector_square(window_ptr, 1, ...
                photodetector_rect); %#ok
        end
        % Check keyboard
        Screen('DrawingFinished', window_ptr);
        [key_down, ~, key_code] = KbCheck;
        if (key_down)
            if find(key_code==1) == cfg.key_stim_present
                % The answer is correct if a stimulus was actually shown.
                correct_response = (stim_present(trial) == 1);
                PM.answer(trial) = 1; % stim present
                %PM = PAL_AMRF_updateRF(PM, PM.xCurrent, correct_response);
                PM = PAL_AMUD_updateUD(PM, correct_response);
                if (use_netstation)
                    NetStation('Event', 'PRES', [], [], 'pre#', trial);
                end
                break;
            elseif find(key_code==1) == cfg.key_stim_absent
                % The answer is correct if a stimulus was actually not 
                % shown.
                correct_response = (stim_present(trial) == 0);
                PM.answer(trial) = 0; % stim absent
                %PM = PAL_AMRF_updateRF(PM, PM.xCurrent, correct_response);
                PM = PAL_AMUD_updateUD(PM, correct_response);                
                if (use_netstation)
                    NetStation('Event', 'ABSE', [], [], 'abs#', trial);
                end                
                break;
            elseif find(key_code==1) == cfg.key_escape
                % Pressing the escape key will terminate the program.
                exit_experiment = 1;
                break;
            end
        end
        if (timing_test)
            % Proceed after a random delay.
            if (randi(10) == 1) %#ok
                break;
            end
        end
        if (response_frame == cfg.n_max_response_frames)
            % Proceed to next trial if responding takes longer than the
            % allowed maximum.
            break;
        end
        vbl = Screen('Flip', window_ptr, vbl + 0.5 * cfg.ifi);     
        Screen('Close', noise_texture);        
        response_frame = response_frame + 1;
    end
    if (exit_experiment)
        break;        
    end   
    trial = trial + 1; % next trial
    PM.last_trial = trial;
end

%% The end
% Inform the participant that the experiment ended (and request him or her 
% to remain still). Show the final detection threshold.
if (~isempty(PM.x))
    msg = strcat('The experiment ended. Thanks!\n\n', sprintf(...
        'Your detection threshold is %1.4f\n', PM.x(end)));
else
    msg = 'No trials were completed\n\n';
end
msg_color = [0, 0.45, 0, 1];

for i = 1:500 % 5 seconds    
    % Draw the fixation cross.
    draw_fixation_cross(window_ptr, ...
        cfg.fixation_cross_neutral_color, window_center_x, ...
        window_center_y, cfg.fxhw);
    % Show the message
    DrawFormattedText(window_ptr, msg, 'center', window_center_y-80, ...
        msg_color);
    % Update the screen.
    vbl = Screen('Flip', window_ptr, vbl + 0.5 * cfg.ifi);    
        % Save the first drawn frame to disk.
        if (~screen_capture_taken && (i > 1))
            img = Screen('GetImage', window_ptr);
            imwrite(img, './cal-end.png');
            screen_capture_taken = 1;
        end                            


end

%% Release all resources.
ShowCursor(); % Make the cursor visible again.
sca;

%% Save results to disk
save(strcat(spath, '\threshold.mat'), 'PM', 'cfg'); 
% TODO: should we just save everything?

%% Close connection to EGI NetStation.
if (use_netstation)
    NetStation('StopRecording');
    NetStation('Disconnect')
end
