function [success] = init_datapixx(varargin)
%INIT_DATAPIXX Initialize DataPixx
%   This function will first attempt to open a connection to the Datapixx
%   device. If opening the connection succeeds then all previous running 
%   schedules will be stopped and all TTL digital outputs will be set to 
%   zero.
%
%   This function will also check whether the short circuit protection has 
%   been triggered. If yes, the connection is automatically closed.
%
%   Input arguments:
%   verbose        - A flag indicating whether possible Datapixx errors 
%                    should be printed to the console.
%   expected_vfreq - Run a Datapixx video status check and compare the 
%                    vertical frequency to a given expected value (unit Hz)
%                    with 1 Hz tolerance (optional).
%
%   Output arguments:
%   success        - A flag indicating whether initializing the Datapixx 
%                    device succeeded.
%
%   Author: Tuomas Puoliväli
%   Email: tuomas.puolivali@helsinki.fi
%   Last modified: 12th December 2017.

%% Settings
if (nargin > 0)
    verbose = varargin{1};
else
    verbose = 0;  
end

vfreq_tolerance = 1; % Unit: Hz
if (nargin == 2)
    expected_vfreq = varargin{2};
else
    expected_vfreq = nan;
end

%% Attempt to open a connection to the Datapixx device
success = 0;
try
    % TODO: suppress possible error message by default 
    is_ready = Datapixx('Open');
    if (is_ready)
        success = 1;
    end
catch exception
    if (verbose)
       disp(exception);
    end    
    success = 0;
end

%% Check short-circuit protection status
if (success)
    fault_state = Datapixx('Is5VFault');
    if (fault_state)
        Datapixx('Close');
        success = 0;
    end
    if (fault_state && verbose)
        fprintf(strcat('Datapixx short circuit protection has been ', ...
            'triggered. Check device status before continuing'));
    end
end

%% Stop all existing schedules.
if (success)
    % Stop running all DAC, ADC, DOUT, DIN, AUD, AUX, and MIC schedules.
    Datapixx('StopAllSchedules');
    Datapixx('RegWrRd'); % Make the stop command effective.
end

%% Set all digital TTL outputs to zero.
if (success)
    Datapixx('SetDoutValues', 0);
    Datapixx('RegWrRd');
end

%% Test the vertical frequency
if (success && ~isnan(expected_vfreq))
    % Run a video status check.
    video_status = Datapixx('GetVideoStatus');
    if (abs(expected_vfreq - video_status.verticalFrequency) < ...
            vfreq_tolerance)
        % OK!
    else
        % The vertical frequency deviates more than a given tolerance from 
        % the expected value. Close the Datapixx and report the problem.
        if (verbose)
            fprintf('Incorrect vertical frequency %3.1f\n', ...
                video_status.verticalFrequency);
        end
        Datapixx('Close');
        success = 0;                   
    end
end

end