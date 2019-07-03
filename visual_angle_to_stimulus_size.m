function [stimulus_width_px, stimulus_height_px] = ...
    visual_angle_to_stimulus_size(horizontal_visual_angle, ...
    vertical_visual_angle, screen_physical_width, ...
    screen_physical_height, viewing_distance, screen_width_px, ...
    screen_height_px)
%VISUAL_ANGLE_TO_STIMULUS_SIZE Fi
%   Input arguments:
%   horizontal_visual_angle - The desired horizontal visual angle (degrees)
%   vertical_visual_angle   - The desired vertical visual angle (degrees)
%   screen_physical_width   - The physical width of the monitor (cm)
%   screen_physical_height  - The physical height of the monitor (cm)
%   viewing_distance        - Distance from the observer's eyes to the
%                             monitor (cm)
%   screen_width_px         - Screen width in pixels
%   screen_height_px        - Screen height in pixels
%
%   Output arguments:
%   stimulus_width_px       - The width of stimulus in pixels
%   stimulus_height_px      - The height of stimulus in pixels
%
%   Author: Tuomas Puolivali (tuomas.puolivali@helsinki.fi).
%   Last modified: 17th November 2017.
%

%% Convert the units of the visual angles from degrees to radians.
horizontal_visual_angle = deg2rad(horizontal_visual_angle);
vertical_visual_angle = deg2rad(vertical_visual_angle);

%% Find the correct physical size for the stimulus
stimulus_physical_width = 2*viewing_distance ...
    * tan(horizontal_visual_angle/2);
stimulus_physical_height = 2*viewing_distance ...
    * tan(vertical_visual_angle/2);

%% Convert the physical units (cm) into units on the screen (px)
% Round to nearest integers.
stimulus_width_px = round(stimulus_physical_width * ...
    (screen_width_px / screen_physical_width));
stimulus_height_px = round(stimulus_physical_height * ...
    (screen_height_px / screen_physical_height));

end