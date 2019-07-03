function [Y] = lin_interp(X1, X2, N)
%LIN_INTERP Linear interpolation between two images.
%   Input arguments:
%   X1 - Image of size [n_rows x n_cols]. (It must be gray scale or 
%        1-channel).
%   X2 - Image of size [n_rows x n_cols].
%   N  - Number of interpolation points.
%
%   Output arguments:
%   Y  - The interpolated images.

% mode == 1 : interpolation includes X1 and X2 as end-points
% mode == 2 : interpolation does not include X1 and X2 but only values
%             between them.
mode = 2;
if (mode == 1)
    % No actions needed.
elseif (mode == 2)
    N = N + 2;
end

%% Compute interpolation weights.
w = linspace(0, 1, N);

%% Allocate memory for the interpolated images.
[n_rows, n_cols] = size(X1);
Y = zeros(N, n_rows, n_cols);

%% Interpolate
for i = 1:N
    Y(i, :, :) = w(i)*X1 + (1-w(i))*X2;
end
if (mode == 2)
    Y = Y(2:end-1, :, :);
end

end

