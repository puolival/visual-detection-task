function [] = bitset_dout_datapixx(bit_position, bit_status, varargin)
%BITSET_DOUT_DATAPIXX Sets the state of the n:th digital output bit while 
%retaining the state of all other bits. Synchronized to video output.
%
%   Input arguments:
%   bit_position - Which bit to set. Position 1 is the LSB.
%   bit_status   - Must be either 'on' or 'off'.
%   verbose      - A flag for deciding whether to print the current and new
%                  status to console (optional).
%   
%   Author: Tuomas Puoliväli
%   Email: tuomas.puolivali@helsinki.fi
%   Last modified: 18th December 2017

%% Validate input
if (bit_position > 24 || bit_position < 1)
    error('The bit position must be an integer in the range 1-24');
end
switch lower(bit_status)
    case 'on'
        bit_on = 1;
    case 'off'
        bit_on = 0;
    otherwise
        error('The bit status must be either ON or OFF');
end

%% Settings
% The nargin parameter takes into account the compulsory parameters.
if (nargin == 3)
    verbose = varargin{1};
else
    verbose = 0;
end

%% Read the present state
% Read the current digital output state.
try
    bitstate = Datapixx('GetDoutValues');
catch exception
    % TODO: suppress datapixx warning by default
    error('Failed to retrieve present state. No connection?');
end

%% Set the new state
if (bit_on)
    new_bitstate = bitor(bitstate, bitshift(bit_on, bit_position-1));
else
    % For some odd reason, there is no (??) bit-level NOT in MATLAB. Here
    % 2^24-1 will first give a bit string with all bits set, and the XOR 
    % will then set the n:th bit as 0.
    new_bitstate = bitand(bitstate, ...
        bitxor(2^24-1, bitshift(1, bit_position-1)));
end
try
    Datapixx('SetDoutValues', new_bitstate);
    % Update the outputs at the leading edge of the next video vertical 
    % sync pulse.
    Datapixx('RegWrVideoSync');
catch
    error('Failed to write the new state. No connection?');
end

%% Print state change to console
if (verbose)
    fprintf('%s original state\n', num2str(dec2bin(bitstate, 24)));
    fprintf('%s new state\n', num2str(dec2bin(new_bitstate, 24)));
end

end