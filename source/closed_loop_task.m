%% Detection task
%
% Author: Tuomas Puoliväli (tuomas.puolivali@helsinki.fi).
% Last modified: 17th January 2018.
% License: 3-clause BSD
% Source: https://github.com/puolival/closed-loop
%
% This program is used to run the main threshold visual detection task 
% after a detection threshold has been sought using the program 
% closed_loop_calibrate.m.
%
% Many of the various settings are directly transferred from the
% calibration procedure via the structure 'cfg'. This should facilitate 
% avoiding mistakes, since a given setting is only defined once.
%
% PREPARATIONS:
%
% Perform the calibration procedure.
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
% Authors thank Peter Scarfe for making available well-commented
% PsychToolbox examples [1], which helped writing this program.
%
% NETSTATION EVENTS:
%
% STIM - Sent after a stimulus has been displayed. The onset time is the 
%        VBL from the Screen('Flip') command. Use offset times for data 
%        analysis.
% CATC - Sent after a catch trial has been "displayed". Similar to STIM.
% PRES - Sent when the participant responds "stimulus present".
% ABSE - Sent when the participant responds "stimulus absent".
%
% REFERENCES:
%
% [1] Scarfe P. Accurate Timing Demo. Online; Accessed 20th November 2017.
% URL: http://peterscarfe.com/accuratetimingdemo.html
%
clear all; clc; %#ok

%% Settings: NetStation
% A flag for deciding whether to send triggers to EGI NetStation.
use_netstation = 0;

%% Settings: Paths
CL = struct;
ptb_path = 'C:\Users\Mirness\Desktop\closed-loop\ptb3';
palamedes_path = 'C:\Users\Mirness\Desktop\closed-loop\palamedes182';

participant_identifier = input(strcat('Please input your unique', ...
    ' participant identifier\n'), 's');
data_path = 'C:\Users\Mirness\Desktop\closed-loop\data';

%% Settings: Seed for PRNG
% MATLAB default settings will reset the PRNG seed to the same value at 
% each startup. To avoid having the same random numbers for several 
% participants, and to make everything reproducible, set a participant 
% specific seed.
CL.participant_prng_seed = input(strcat('Please input a random seed', ...
    ' for the PRNG\n'));
rng(CL.participant_prng_seed);

%% Settings: Number of trials
CL.n_stimulus_trials = 100;
CL.n_catch_trials = 100;
n_trials = CL.n_stimulus_trials + CL.n_catch_trials;

%% Load experiment settings and the participant's detection threshold.
fname = strcat(data_path, '\', participant_identifier, '\threshold.mat');
if (exist(fname, 'file'))
    calibration_data = load(fname);
    if (~isempty(calibration_data.PM.x))
        detection_threshold = calibration_data.PM.x(end);
        cfg = calibration_data.cfg;
    else
        error(strcat('The calibration file exists but not trials', ...
            ' were completed!'));
    end
    clear calibration_data;
else
    error('The calibration procedure has not been performed!');
end

%% Settings: Closed-loop
stim_listen_addr = '0.0.0.0';
stim_listen_port = 7171;

%% Start listening for stimulation instructions
fprintf('Waiting for connection ..\n');
sck = tcpip(stim_listen_addr, stim_listen_port, ...
    'NetworkRole', 'server');
fopen(sck);
%fwrite(sck, 'Hi. I am the stimulus computer.'); % for testing purposes

%% Connect to EGI NetStation
if (use_netstation) 
    NetStation('Connect', '10.10.10.42');
    NetStation('GetNTPSynchronize', '10.10.10.51');
    NetStation('StartRecording');
end

%% Initialize Psychtoolbox and Palamedes.
init_ptb(ptb_path, cfg.ptb_init_verbose);
init_palamedes(palamedes_path, cfg.palamedes_init_verbose);

%% Initialize the screen
[window_ptr, window_center_x, window_center_y, ...
    screen_width_px, screen_height_px, bgcolor] = ptb_init_screen();

% Check that the inter-frame-interval or monitor refresh rate is identical
% to the calibration session.
ifi = Screen('GetFlipInterval', window_ptr);
ifi_tolerance = 0.05; % percent
if (abs((ifi-cfg.ifi)/cfg.ifi) > ifi_tolerance)
    sca;
    error(strcat('The monitor refresh rate was different for the ', ...
        'calibration procedure!'));
end

%% Make gabor patch
% Create the gabor.
gabor_texture = CreateProceduralGabor(window_ptr, cfg.gabor_size, ...
    cfg.gabor_size, [], [bgcolor, bgcolor, bgcolor, 1], 1, 0.5);

% Detection threshold sets the Gabor contrast.
gabor_settings = [cfg.gabor_phase, cfg.gabor_freq, cfg.gabor_sigma, ...
    detection_threshold, 1.0, 0, 0, 0]';

%% Settings for the trial structure.
% The value 1 is used to refer to stimulus trials and the value 0 is used
% to refer to catch trials.
stim_present = [ones(CL.n_stimulus_trials, 1); ...
    zeros(CL.n_catch_trials, 1)]; 
stim_present = stim_present(randperm(n_trials));

CL.stim_present = stim_present;
CL.stim_angle = randi([0, 359], [n_trials, 1]);
CL.answers = nan(n_trials, 1);
CL.prestim_frames = randi([cfg.n_min_prestim_frames, ...
    cfg.n_max_prestim_frames], n_trials, 1);

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

%% Get VBL
vbl = Screen('Flip', window_ptr);

%% Instructions
% Inform the participant that the experiment is about to begin.
timer = 10;
for i = 1:1000 % 5 seconds    
    % Show the message
    if (mod(i, 100) == 0 && i > 0)
        timer = timer - 1;
    end
    msg = sprintf('Starting in %d seconds ..', timer);
    DrawFormattedText(window_ptr, msg, 'center', ...
        window_center_y-cfg.gabor_size/2-40, [0, 0.45, 0, 1]);
    % Update the screen.
    vbl = Screen('Flip', window_ptr, vbl + 0.5 * cfg.ifi);     
end

%% Main program
trial = 1;
exit_experiment = 0;

% Send a starting signal to the data processing computer.
fwrite(sck, 'START\n');

while trial <= n_trials
    % TODO: no longer possible to exit the program at any time easily.
    % Fix.
    if (sck.BytesAvailable == 0)
        % Draw the Perlin noise
        [noise_texture, noise_interp_step, noise_frame_ind] = ...
            update_noise(window_ptr, perlin_noise, noise_frame_ind, ...
            noise_interp_step, cfg.n_noise_interp_steps);
        draw_perlin_noise(window_ptr, window_center_x, ...
            window_center_y, noise_texture, noise_rect, 1);
        % Draw the fixation cross.
        draw_fixation_cross(window_ptr, ...
            cfg.fixation_cross_neutral_color, window_center_x, ...
            window_center_y, cfg.fxhw);
        % Update the screen.
        vbl = Screen('Flip', window_ptr, vbl + 0.5 * cfg.ifi);
        Screen('Close', noise_texture);       
    else
        flushinput(sck);
        for i = 1:cfg.n_target_frames
            % Draw the Perlin noise
            %
            [noise_texture, noise_interp_step, noise_frame_ind] = ...
                update_noise(window_ptr, perlin_noise, noise_frame_ind, ...
                noise_interp_step, cfg.n_noise_interp_steps);
            draw_perlin_noise(window_ptr, window_center_x, ...
                window_center_y, noise_texture, noise_rect, 1);
            % Draw the Gabor
            %
            Screen('BlendFunction', window_ptr, ...
                GL_ONE_MINUS_SRC_ALPHA, GL_SRC_ALPHA);
            Screen('DrawTextures', window_ptr, gabor_texture, ...
                [], [], CL.stim_angle(trial), [], 0.5, [], [], ...
                kPsychDontDoRotation, gabor_settings);
            Screen('BlendFunction', window_ptr, GL_ONE, GL_ZERO);
            % Draw the fixation cross.
            %
            draw_fixation_cross(window_ptr, ...
                cfg.fixation_cross_neutral_color, window_center_x, ...
                window_center_y, cfg.fxhw);
            % Update the screen.
            %
            vbl = Screen('Flip', window_ptr, vbl + 0.5 * cfg.ifi);
            Screen('Close', noise_texture);           
            % Send trigger to Netstation
            %
            if (use_netstation)
                if (stim_present(trial)) %#ok
                    NetStation('Event', 'STIM', vbl, cfg.ifi, ...
                        'sti#', trial);
                else
                    NetStation('Event', 'CATC', vbl, cfg.ifi, ...
                        'cat#', trial);
                end
            end
        end
       
        % Delay
        for i = 1:cfg.n_delay_frames
            % Draw the Perlin noise
            [noise_texture, noise_interp_step, noise_frame_ind] = ...
                update_noise(window_ptr, perlin_noise, noise_frame_ind, ...
                noise_interp_step, cfg.n_noise_interp_steps);
            draw_perlin_noise(window_ptr, window_center_x, ...
                window_center_y, noise_texture, noise_rect, 1);
            % Draw the fixation cross.
            draw_fixation_cross(window_ptr, ...
                cfg.fixation_cross_neutral_color, window_center_x, ...
                window_center_y, cfg.fxhw);
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
                window_center_y, noise_texture, noise_rect, 1);
            % Draw the fixation cross.
            draw_fixation_cross(window_ptr, ...
                cfg.fixation_cross_answer_color, window_center_x, ...
                window_center_y, cfg.fxhw);
            %
            Screen('DrawingFinished', window_ptr);
            [key_down, ~, key_code] = KbCheck;
            if (key_down)
                if find(key_code==1) == cfg.key_stim_present
                    CL.answers(trial) = 1; % stim present
                    if (use_netstation)
                        NetStation('Event', 'PRES', [], [], 'pre#', trial);
                    end
                    break;
                elseif find(key_code==1) == cfg.key_stim_absent
                    CL.answers(trial) = 0; % stim absent
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
        CL.last_trial = trial;
    end
    
end

%% Calculate d-prime and response criterion
% If the experiment is aborted during the first trial, CL.last_trial
% is not set, which is needed for confusion_matrix.
if (trial > 1)
    CL.C = confusion_matrix(CL);
    pH = CL.C(1, 1) / sum(CL.C(:, 1)); % proportion of hits
    pF = CL.C(1, 2) / sum(CL.C(:, 2)); % proportion of false alarms
    [dprime, criterion] = sdt_1afc(pH, pF);
else
    dprime = nan;
    criterion = nan;
end
% TODO: If pH = 0 or pF = 1 dprime will be +/- Inf, which would indicate
% that the calibration procedure failed (same for criterion). Anyway, if
% such situation would occur, it is probably better that the participant 
% is not informed .. ?

%% The end
%
% Inform the participant that the experiment ended (and request him or her 
% to remain still).
if (trial > 1)
    msg = sprintf(strcat(...
        'The experiment ended. Thanks!\n\n Your d-prime', ...
        ' was %1.3f and criterion %1.3f\n\n'), dprime, criterion);
else
    msg = strcat('The experiment ended during the first trial.\n\n', ...
        'No statistics available.\n\n');
end
msg_color = [0, 0.25, 0, 1];

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
end

%% Release all resources.
ShowCursor(); % Make the cursor visible again.
sca;

%% Save data
spath = strcat(data_path, '\', participant_identifier, '\task.mat');
save(spath, 'CL', 'cfg', 'dprime', 'criterion');

%% Close connection to EGI NetStation.
if (use_netstation)
    NetStation('StopRecording');
    NetStation('Disconnect')
end

%% Close connectio to data processing computer.
fwrite(sck, 'Bye.');
fclose(sck);

