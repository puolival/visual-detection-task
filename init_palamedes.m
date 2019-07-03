function [] = init_palamedes(palamedes_dir, varargin)
%INIT_PTB Set filepaths for Palamedes
%   Input arguments:
%   palamedes_dir - The Palamedes installation directory.
%   verbose       - A flag indicating whether to print the added paths to
%                   the console (optional).
%
%   Last modified 11th December 2017.

%% Check whether to print added paths.
if (nargin > 1)
    verbose = varargin{1};
else
    verbose = 0;
end

%% Check if setup has been already done
if (~isempty(strfind(path, 'Palamedes')))
    return;
end

%% Get a list of PTB paths
paths = strsplit(genpath(palamedes_dir), ';');
n = length(paths);

%% Add the paths to the 'path' variable.
for i = 1:n
    if (verbose)
        fprintf('Adding path %s\n', paths{i});
    end
    addpath(paths{i});
end

end