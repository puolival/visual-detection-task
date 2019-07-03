function [noise_texture, noise_interp_step, noise_frame_ind] = ...
    update_noise(window_ptr, perlin_noise, noise_frame_ind, ...
    noise_interp_step, n_noise_interp_steps)
%UDPATE_NOISE 
%   Last modified 6th August 2018.

%% Compute interpolation weights.
w = linspace(0, 1, n_noise_interp_steps);
noise_data = ...
    w(noise_interp_step) * ...
    squeeze(perlin_noise(noise_frame_ind+1, :, :)) + ...
    (1-w(noise_interp_step)) * squeeze(...
     perlin_noise(noise_frame_ind, :, :));

% noise_data = lin_interp(squeeze(...
%     perlin_noise(noise_frame_ind+1, :, :)), squeeze(...
%     perlin_noise(noise_frame_ind, :, :)), n_noise_interp_steps-1);

noise_texture = Screen('MakeTexture', window_ptr, noise_data);

if (noise_interp_step == n_noise_interp_steps)
    noise_interp_step = 1;
    noise_frame_ind = noise_frame_ind + 1;
end

[n_frames, ~, ~] = size(perlin_noise);
if (noise_frame_ind == n_frames)
    noise_frame_ind = 1;
end

noise_interp_step = noise_interp_step + 1;

end

