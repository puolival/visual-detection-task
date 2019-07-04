function [window_ptr, window_center_x, window_center_y, ...
    screen_width_px, screen_height_px, bgcolor] = ptb_init_screen()
%PTB_INIT_SCREEN Initialize a screen for drawing
%   Author: Tuomas Puoliväli
%   Email: tuomas.puolivali@helsinki.fi
%   Last modified: 9th August 2018

%% Enable synchronization tests.
Screen('Preference', 'SkipSyncTests', 0);

%% Initialize the screen
PsychDefaultSetup(2);
screens = Screen('Screens');
screen_number = max(screens);
bgcolor = BlackIndex(screen_number);

gray = (WhiteIndex(screen_number) + BlackIndex(screen_number)) / 2;
[window_ptr, window_rect] = PsychImaging('OpenWindow', screen_number, ...
    gray, [], 32, 2, [], [],  kPsychNeed32BPCFloat);

%% Retrieve the maximum priority number and set max priority
top_priority_level = MaxPriority(window_ptr);
Priority(top_priority_level);

%% Hide cursor
HideCursor();

%% Set fonts for drawing text
Screen('TextFont', window_ptr, 'Arial Black');
Screen('TextSize', window_ptr, 24);

%% Compute constants
screen_width_px = window_rect(3);
screen_height_px = window_rect(4);
window_center_x = screen_width_px / 2;
window_center_y = screen_height_px / 2;

end