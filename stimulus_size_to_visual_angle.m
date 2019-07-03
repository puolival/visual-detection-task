function [horizontal_visual_angle, vertical_visual_angle] = ...
    stimulus_size_to_visual_angle(screen_physical_width, ...
    screen_physical_height, viewing_distance, screen_width_px, ...
    screen_height_px, stimulus_width_px, stimulus_height_px)
%STIMULUS_SIZE_TO_VISUAL_ANGLE Compute the visual angle of a stimulus 
%based on the parameters of the experiment.
%   Input arguments:
%   screen_physical_width   - Physical width of the screen (cm)
%   screen_physical_height  - Physical height of the screen (cm)
%   viewing_distance        - Distance from the observer's eyes to the 
%                             center of the monitor (cm)
%   screen_width_px         - Screen width in pixels
%   screen_height_px        - Screen height in pixels
%   stimulus_width_px       - Stimulus width in pixels
%   stimulus_height_px      - Stimulus height in pixels
%
%   Output arguments:
%   horizontal_visual_angle - The horizontal visual angle (degrees of arc)
%   vertical_visual_angle   - The vertical visual angle(degrees of arc)
%
%   Author: Tuomas Puolivali (tuomas.puolivali@helsinki.fi).
%   Last modified: 17th November 2017.
%   

%% Convert the width and height of the stimulus into physical units.
stimulus_physical_width = stimulus_width_px * ...
    (screen_physical_width / screen_width_px);
stimulus_physical_height = stimulus_height_px * ...
    (screen_physical_height / screen_height_px);

%% Calculate the horizontal and vertical visual angles.
horizontal_visual_angle = rad2deg(2*atan(stimulus_physical_width / ...
    (2*viewing_distance)));
vertical_visual_angle = rad2deg(2*atan(stimulus_physical_height / ...
    (2*viewing_distance)));

end