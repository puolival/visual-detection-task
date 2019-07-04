function [noise_texture, noise_rect] = make_perlin_noise(window_ptr, ...
    noise_width, noise_height)
%MAKE_PERLIN_NOISE Helper function for generating Perlin noise.
%
%   Input arguments:
%   window_ptr      - Pointer to the on-screen window.
%   noise_width     - Width of the noise patch (unit: pixels)
%   noise_height    - Height of the noise patch (unit: pixels) 
%
%   Output arguments:
%   noise_texture   - Texture containing the Perlin noise
%   noise_rect      - The part of the texture that should be drawn.
%
%   Author: Tuomas Puoliväli
%   Email: tuomas.puolivali@helsinki.fi
%   Last modified: 2nd January 2018
%   License: Revised 3-clause BSD

%% Settings
noise_type = 'Perlin'; % Must be either 'Perlin' or 'ClassicPerlin'.
r = 64; % Factor for controlling the spatial frequency.

%% Make the texture
[noise_texture, ~] = CreateProceduralNoise(window_ptr, ...
   noise_width*r, noise_height*r, noise_type, [0.5, 0.5, 0.5, 1]);

noise_rect = [0, 0, noise_width, noise_height];

end