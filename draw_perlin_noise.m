function [] = draw_perlin_noise(window_ptr, window_center_x, ...
    window_center_y, noise_texture, noise_rect, noise_seed)
%MAKE_PERLIN_NOISE Helper function for generating Perlin noise.
%
%   Input arguments:
%   window_ptr      - Pointer to the on-screen window.
%   noise_texture   - Texture containing the Perlin noise
%   noise_rect      - The part of the texture that should be drawn.
%
%   Author: Tuomas Puoliväli
%   Email: tuomas.puolivali@helsinki.fi
%   Last modified: 2nd January 2018
%   License: Revised 3-clause BSD

%% Settings
%noise_seed = 1;

%%
noise_width = noise_rect(3);
noise_height = noise_rect(4);

%% Draw the texture.
% Draw the noise at the center of the screen.
noise_position = [window_center_x - noise_width / 2, ...
   window_center_y - noise_height / 2, window_center_x + ...
   noise_width / 2, window_center_y + noise_height / 2];

%
Screen('DrawTexture', window_ptr, noise_texture, noise_rect, ...
   noise_position, 0, [], [], [], [], [], [0.5, noise_seed, 0, 0]);

end