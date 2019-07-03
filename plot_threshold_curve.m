function [] = plot_threshold_curve(PM)
%PLOT_THRESHOLD_CURVE Plot the detection threshold as a function of trial
%number.
%   Last modified 8th August 2018.

figure;

plot(linspace(1, PM.last_trial, PM.last_trial), PM.xStaircase, '-', ...
    'linewidth', 2)
hold on;

xlabel('Trial number');
ylabel('Detection threshold');
title('Threshold calibration procedure');

ylim([min(PM.xStaircase)-0.01, 0.26]);
xlim([-1, PM.last_trial+1]);

end

