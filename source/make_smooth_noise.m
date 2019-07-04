%% Make smooth Perlin noise.
%
% First use the function 'generate_perlin_noise_mat.m'.7
%
% Last modified: 31th July 2018.
% Author: Tuomas Puoliväli (tuomas.puolivali@helsinki.fi)
%

%% Load the Perlin noise data.
noise_fpath = 'C:\Users\Mirness\Desktop\closed-loop';
noise_fname = strcat(noise_fpath, '\perlin_noise.mat');
noise_data = load(noise_fname);

%% Extract the data
noise_data.X = squeeze(noise_data.X(: , :, :, 1));
[n_noise_frames, n_rows, n_cols] = size(noise_data.X);

%% Allocate memory for the smooth Perlin noise.
duration = n_noise_frames; % seconds
fps = 120; % frames per second
perlin_noise = zeros(fps * (duration-1), n_rows, n_cols);

 %% Add the original frames.
perlin_noise(1:fps:fps*(duration-1), :, :) = noise_data.X(1:end-1, :, :);

%% Add interpolated frames.
for i = 1:duration-1
    fprintf('Interpolating frames step %3d\n', i);
    perlin_noise(2+fps*(i-1):fps*i, :, :) = lin_interp(squeeze(...
        noise_data.X(i+1, :, :)), squeeze(noise_data.X(i, :, :)), fps-1);
end
fprintf('Done.\n');

%% Save the smooth noise to disk.
save_data = 0;
if (save_data)
    fprintf('Saving the data to disk..\n');
    save_fname = strcat(noise_fpath, '\perlin_noise_smooth.mat');
    save(save_fname, 'perlin_noise', '-v7.3');
    fprintf('Done.\n');
end

%% make movie for testing
make_avi = 1;
if (make_avi)
    video_obj = VideoWriter(...
        'C:\Users\Mirness\Desktop\closed-loop\perlin.avi');
    open(video_obj);
    [n, ~, ~] = size(perlin_noise);
    for j = 1:n
        imshow(squeeze(perlin_noise(j, :, :)));
        f = getframe;
        writeVideo(video_obj, f);
        fprintf('Writing frame %4f\n', j);
    end
    close(video_obj);
end
