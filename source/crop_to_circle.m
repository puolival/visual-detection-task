function [Y] = crop_to_circle(X, radius, s)
%CROP_TO_CIRCLE Crop texture data to a circle.
%   Last modified 7th August 2018.

%% Find the center.
[n_rows, n_cols] = size(X);
cx = (n_rows + mod(n_rows, 2)) / 2;
cy = (n_cols + mod(n_cols, 2)) / 2;

%% Crop to circle.
Y = zeros(n_rows, n_cols);
for i = 1:n_rows
    for j = 1:n_cols
        % Compute Euclidean distance from the center.
        d = sqrt((i-cx)^2 + (j-cy)^2) + 50; % + space for smoothing
        % Smooth around edges.
        if (d < radius)
            % Noise disk
            Y(i, j) = X(i, j);  
        else
            if (abs(d-radius) < 50)
                % Transition zone
                a = abs(d - radius) / 50;
                Y(i, j) = (1-a)*X(i, j) + a*s;
            else
                % Background
                Y(i, j) = s;
            end
        end
    end
end

% previous version:
% Y(i, j) = s + (X(i, j) - s) * exp(-0.1 * abs(d-radius));

end

