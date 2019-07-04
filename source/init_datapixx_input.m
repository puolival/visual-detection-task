function [] = init_datapixx_input()
%INIT_DATAPIXX_INPUT Initialize the datapixx input device.
%   Author: Tuomas Puoliväli
%   Email: tuomas.puolivali@helsinki.fi
%   Last modified: 15th December 2017.

%% Settings
% Define the DEFAULT digital input device parameters explicitly for
% improved backwards compatibility and documentation.
din_buffer_base_address = 12e6;
din_num_buffer_frames = 1000;

%% Start listening for input transitions.
% Setup.
Datapixx('SetDinLog', din_buffer_base_address, din_num_buffer_frames); 

% Configure: Ignore DIN transitions for 30 ms after a transition has been 
% observed.
Datapixx('EnableDinDebounce');

% Start logging.
Datapixx('StartDinLog');

end

