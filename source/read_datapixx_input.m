function [any, responses, reaction_times] = read_datapixx_input(varargin)
%READ_DATAPIXX_INPUT Read Datapixx digital input values.
%   Input arguments:
%   stimulus_onset_time - Stimulus onset time (optional). Needed for
%                         calculating reaction times.
%
%   Output arguments:
%   any            - A flag indicating whether there were any new
%                    responses.
%   responses      - A row vector of acquired digital input values.
%   reaction_times - Time since stimulus onset for each response. If the
%                    optional input paramteer stimulus_onset_time was not 
%                    provided, times since Datapixx powerup are returned.
%
%   NOTES:
%   Calling the Datapixx function ReadDinLog without a connected input 
%   device appears to result in an infinite loop.
%
%   Author: Tuomas Puoliväli
%   Email: tuomas.puolivali@helsinki.fi
%   Last modified: 15th December 2017

%% Read optional input values
if nargin == 1
    stimulus_onset_time = varargin{1};
else
    stimulus_onset_time = 0;
end

%% Read the digital input device status
input_status = Datapixx('GetDinStatus');

% Check that input state transition logging is switched on
if (input_status.logRunning)
    error(strcat('The digital input device has not been initialized ', ...
        'or the inputs are no longer recorded'));
end

%% Read the digital inputs
any = input_status.newLogFrames > 0;
if (any)
    responses = nan(1, 16);
    reaction_times = nan(1, 16);
else
    [responses, log_time_tags, underflow] = Datapixx('ReadDinLog', ...
        input_status.newLogFrames);
    if (underflow)
        % An underflow can occur if the Datapixx command ReadDinLog is
        % performed when there are no new frames. However, since we
        % first check the number of new frames using GetDinStatus and
        % only then attempt to read a corresponding amount, an
        % underflow should never happen. Therefore, if this block is
        % reached the experiment should ended and the cause of the
        % error investigated.
        error(strcat('An underflow occurred while attempting to ', ...
            'read data from the Datapixx device!'));
    end
    % Calculate response reaction time (RT)
    reaction_times = log_time_tags - stimulus_onset_time;    
end

end