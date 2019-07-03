function [] = plot_ntsc_colorspace(intensity)
%PLOT_NTSC_COLORSPACE Plot the NTSC color space at a given intensity.
%   Last modified 28th August 2018.

steps = 400;
cmap = zeros(steps, steps, 3);

x = linspace(-1, 1, steps);
y = linspace(-1, 1, steps);

for i = 1:steps
    for j = 1:steps
        cmap(i, j, :) = ntsc2rgb([intensity, x(i), y(j)]);
    end
end

figure;
imagesc(x, y, cmap);

end

