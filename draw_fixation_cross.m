function [] = draw_fixation_cross(window_ptr, color, window_center_x, ...
    window_center_y, cross_half_width)
%DRAW_FIXATION_CROSS Function for drawing a fixation cross.
%
%   Input arguments:
%   window_ptr       - Pointer to the onscreen window.
%   color            - Color of the fixation cross (RGBA).
%   window_center_x  - X-coordinate of the window center point.
%   window_center_y  - Y-coordinate of the window center point
%   cross_half_width - Half-width of the fixation cross.
%
%   Last modified 11th December 2017.

% Draw the fixation cross in two parts.
Screen('DrawLine', window_ptr, color, ...
    window_center_x - cross_half_width, window_center_y, ...
    window_center_x + cross_half_width, window_center_y, 2);
Screen('DrawLine', window_ptr, color, ...
    window_center_x, window_center_y - cross_half_width, ...
    window_center_x, window_center_y + cross_half_width, 2);

end