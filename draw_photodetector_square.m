function [] = draw_photodetector_square(...
    window_ptr, mode, rect)
%DRAW_PHOTODETECTOR_SQUARE Summary of this function goes here
%   Last modified 9th January 2018

black = BlackIndex(window_ptr);
white = WhiteIndex(window_ptr);
gray = (0.1*white+0.9*black) / 2;

if (mode == 1)
    Screen('FillRect', window_ptr, [gray, gray, gray, 0.5], rect);
elseif (mode == 2)
    Screen('FillRect', window_ptr, [white, white, white, 0.5], rect);
else
    error('Invalid mode');
end

end

