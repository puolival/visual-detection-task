function [h, c, l] = rgb2hcl(r, g, b)
%RGB2HCL Transformation from RGB to HCL color space.
%
%   NOTE: unfinished code, not working properly.
%
%   Last modified 28th August 2018.

% Q is a tuning parameter.
gamma = 3;
alpha = (1/100) * (min([r, g, b])/max([r,g,b]));
q = exp(alpha*gamma);

% Neither of these approaches seem to work.
%h = rad2deg(atan2(g-b, r-g));
h = rad2deg(atan((g-b)/(r-g)));
if (r-g < 0)
    if (g-b >= 0)
        h = 90 + h;
    else
        h = h - 90;
    end
end

%
c = (q * abs(r-g) + abs(g-b) + abs(b-r)) / 3;
l = (q * max([r, g, b]) + (1-q) * min([r, g, b])) / 2;

end