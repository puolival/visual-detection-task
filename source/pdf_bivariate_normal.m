function [density] = pdf_bivariate_normal(x1, x2, mu1, mu2, ...
    sigma1, sigma2, V12)
%PDF_BIVARIATE_NORMAL Probability density function of bivariate normal
%distribution.
%
%   Input arguments:
%   ================
%   x1, x2 : vector of double
%     Each (x1(i), x2(j)) is a point at which to evaluate the PDF.
%   mu1, mu2 : double
%     Mean of each marginal distribution.
%   sigma1, sigma 2: double
%     Standard deviation of each marginal distribution.
%   V12 : double
%     Covariance between x1 and x2.
%
%   Reference: mathworld.wolfram.com.
%
%   Last modified 7th August 2018.

%% Compute variances.
var1 = sigma1^2;
var2 = sigma2^2;

%% Allocate memory for the result.
nx = length(x1);
ny = length(x2);

density = zeros(nx, ny);

%% Compute the density function.
for i = 1:nx
    for j = 1:ny
        % Correlation.
        rho = V12 / (sigma1*sigma2);
         z = (1/var1) * (x1(i)-mu2)^2 - ...
            (1/(sigma1*sigma2)) * 2*rho*(x1(i)-mu1)*(x2(j)-mu2) + ...
            (1/var2)*(x2(j)-mu2)^2;        
        density(i,j) = 1 / (2*pi*sigma1*sigma2*sqrt(1 - rho^2)) * ...
            exp(-z / (2*(1 - rho^2)));
    end
end
    
end

