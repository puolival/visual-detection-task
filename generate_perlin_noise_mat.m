%% Script for generating Perlin noise.
%
% This script first generates Perlin noise using the PsychToolbox 
% functions. The noise patch is then made circular and windowed to smooth
% the edges. 
%
% Author: Tuomas Puolivali (tuomas.puolivali@helsinki.fi).
% Last modified 11th September 2018.

%% Settings
ptb_path = 'C:\Users\Mirness\Desktop\closed-loop\ptb3';
save_fpath = 'C:\Users\Mirness\Desktop\closed-loop\';

%% Settings
n_frames = 11; % Number of noise frames.
viewing_distance = 100; % cm
screen_physical_width = 54; % cm
screen_physical_height = 30; % cm
noise_visual_angle = 5;

%% Setup Psychtoolbox paths.
init_ptb(ptb_path);

%% Initialize Psychtoolbox & open a new screen for drawing.
PsychDefaultSetup(2);
screens = Screen('Screens');
screenNumber = max(screens);

bgcolor = BlackIndex(screenNumber);
[window_ptr, window_rect] = PsychImaging('Openwindow', screenNumber, ...
    [0.5, 0.5, 0.5, 0], [], 32, 2, [], [],  kPsychNeed32BPCFloat);

% Retrieve the maximum priority number and set max priority
topPriorityLevel = MaxPriority(window_ptr);
Priority(topPriorityLevel);
    
ifi = Screen('GetFlipInterval', window_ptr);

%% Compute constants
screen_width_px = window_rect(3);
screen_height_px = window_rect(4);
window_center_x = screen_width_px / 2;
window_center_y = screen_height_px / 2;

%% Prepare the noise
% Map visual angle to number of pixels.
[noise_width, noise_height] = visual_angle_to_stimulus_size(...
    noise_visual_angle, noise_visual_angle, ...
    screen_physical_width, screen_physical_height, viewing_distance, ...
    screen_width_px, screen_height_px);

% The noise is drawn to the center of the screen. The position is computed
% within the function draw_perlin_noise but we need it also here to be 
% able to extract pixels from the correct part of the window.
[noise_texture, noise_rect] = make_perlin_noise(window_ptr, ...
    noise_width, noise_height);
noise_position = [window_center_x - noise_width / 2, ...
   window_center_y - noise_height / 2, window_center_x + ...
   noise_width / 2, window_center_y + noise_height / 2];

% Add some empty space around the noise.
space = 50;
noise_position(1) = noise_position(1) - space;
noise_position(3) = noise_position(3) + space;
noise_position(2) = noise_position(2) - space;
noise_position(4) = noise_position(4) + space;

%% Main program
X = zeros(n_frames, noise_rect(4)+2*space, noise_rect(3)+2*space, 3);

% Get vbl
vbl = Screen('Flip', window_ptr);

for i = 1:n_frames
    % Draw the Perlin noise
    draw_perlin_noise(window_ptr, window_center_x, ...
        window_center_y, noise_texture, noise_rect, randi(1000));
    vbl = Screen('Flip', window_ptr, vbl + ifi);   
    
    % Read the Perlin noise pixel data.
    img_perlin = Screen('GetImage', window_ptr, noise_position, [], 1);
    X(i, :, :, :) = img_perlin;
    
    % End the program if any key is pressed.
    [key_down, ~, key_code] = KbCheck;
    if (key_down)
        break;
    end
end

% Make the noise circular i.e. first frame = last frame.
X(end, :, :, :) = X(1, :, :, :);

%% Shift min and max
% First normalize to [0, 1].
X_min = min(X(:));
X_max = max(X(:));
X = X - X_min;
X = X / X_max;

% Next squeeze the data to [0.4, 0.6].
X = 0.2 * X;
X = X + 0.4;

%% Crop to circle.
[~, ~, ~, n_rgb_channels] = size(X);
r = (noise_height + mod(noise_height, 2)) / 2;
for i = 1:n_frames
    for j = 1:n_rgb_channels
        X(i, :, :, j) = crop_to_circle(squeeze(X(i, :, :, j)), r, 0.5);
    end
end

%% Release all resources.
sca;

%% Save the result to disk.
fname = strcat(save_fpath, '\perlin_noise.mat');
save(fname, 'X', 'noise_visual_angle', 'viewing_distance', ...
    'screen_physical_width', 'screen_physical_height', ...
    'screen_width_px', 'screen_height_px');

% %% Compute spectra
% S = zeros(512, 512);
% for i = 1:n_frames
%     S = S + (1/i) * log10(abs(fftshift(fft2(squeeze(X(i, :, :, 1)), ...
%         512, 512))));
% end
%     
% figure;
% surf(S);
% shading interp;
% xlabel('Frequency bin');
% ylabel('Frequency bin');
% xlim([1, 512]);
% ylim([1, 512]);
