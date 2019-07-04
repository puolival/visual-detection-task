function [dprime, criterion] = sdt_1afc(pH, pF)
%SDT Calculate signal detection theory (SDT) measures for one-alternative
%forced-choice (1AFC) task.
%   [dprime, criterion] = sdt(pH, pF). 
%
%   This function can be used for tasks where:
%   (1) One of two stimulus states is presented per trial (target absent or
%   target present). Hence N=1
%   (2) There are two possible response choices (present and absent).
%   Therefore m=2.
%
%   A task with N=1 and m=2 is called 1-AFC in [1].
%
%   Input arguments:
%   pH        - Proportion of hits (target-present trials in which the 
%               observed responded 'yes')
%   pF        - Proportion of false alarms (target-absent trials in which 
%               the observer responded 'yes')
%
%   Output arguments:
%   dprime    - The sensitivity index d'. A high d' indicates easier
%               detection of the presented stimuli.
%   criterion - Bias towards a certain response.
%
%   References:
%   Kingdom FAA, Prins N (2010): Phychophysics: A practical introduction. 
%   p. 155, 175
%
%   Last modified 18th December 2017
%   Author: Tuomas Puoliväli
%   Email: tuomas.puolivali@helsinki.fi

%% To avoid +/-Inf & NaN results
if (pH > 1-eps)
    pH = 1-eps;
end
if (pH < eps)
    pH = eps;
end
if (pF > 1-eps)
    pF = 1-eps;
end
if (pF < eps)
    pF = eps;
end

%% Z-transform the hit and false alarm rates
z_pH = icdf('normal', pH, 0, 1);
z_pF = icdf('normal', pF, 0, 1);

%% Calculate d-prime and criterion
dprime = z_pH - z_pF;
criterion = -0.5 * (z_pH + z_pF);

end