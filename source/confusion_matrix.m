function [C] = confusion_matrix(CL)
%CONFUSION_MATRIX Calculate a standard confusion matrix from the
%closed-loop data structure CL which contains the participant's answers and
%the stimulation sequence.
%   C = confusion_matrix(CL)
%
%   Input arguments:
%   CL - The closed-loop task data structure.
%
%   Output arguments:
%   C  - A standard confusion matrix. 
%        C(1, 1) is the number of hits (true positives), 
%        C(2, 2) is the number of correct rejections (true negatives), 
%        C(1, 2) is the number of false alarms (false positives), and 
%        C(2, 1) is the number of misses (false negatives).
%
%   Author: Tuomas Puoliväli
%   Email: tuomas.puolivali@helsinki.fi
%   Last modified: 18th December 2017.

%% Settings
verbose = 1;

%% Extract the stimulation sequence and the participant's answers.
stimuli = CL.stim_present(1:CL.last_trial);
answers = CL.answers(1:CL.last_trial);

%% Check whether the last trial was completed
% If the last answer is not-a-number (NaN), the experiment was ended by the
% measurer by pressing an escape key. In such cases, exclude the last trial
% from calculating the confusion matrix.
if (isnan(answers(end)))
    stimuli = stimuli(1:end-1);
    answers = answers(1:end-1);
    if (verbose)
        fprintf(strcat('Last trial was not completed. The confusion', ...
            ' matrix is calculated using the remaining trials.'));
    end
end

%% Compute the confusion matrix
% The MATLAB function crosstab would be otherwise suitable for this task
% but it is not able to handle the cases where
% (1) there is just one response, or 
% (2) one of the columns or rows of the confusion matrix will be zero.
n_stimuli = length(stimuli);
C = zeros(2, 2);
for i = 1:n_stimuli
    if (stimuli(i) == 1) % target present
        if (answers(i) == 1) % hit
            C(1, 1) = C(1, 1) + 1;
        else % miss
            C(2, 1) = C(2, 1) + 1;
        end
    else % target absent
        if (answers(i) == 1) % false alarm
            C(1, 2) = C(1, 2) + 1;
        else % correct rejection
            C(2, 2) = C(2, 2) + 1;
        end
    end
end

end