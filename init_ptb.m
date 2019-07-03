function [] = init_ptb(ptb_dir, varargin)
%INIT_PTB Set filepaths for Psychtoolbox.
%   Input arguments:
%   ptb_dir - PsychToolbox installation directory.
%   verbose - A flag indicating whether to print the added paths to
%             console (optional).
%
%   Last modified 11th December 2017.

%% Check whether to print added paths.
if (nargin > 1)
    verbose = varargin{1};
else
    verbose = 0;
end

%% Check if setup has been already done
if (~isempty(strfind(path, 'Psychtoolbox')))
    return;
end

%% Get a list of PTB paths
paths = strsplit(genpath(ptb_dir), ';');
n = length(paths);

%% Add the paths to the 'path' variable.
for i = 1:n
    if (verbose)
        fprintf('Adding path %s\n', paths{i});
    end
    addpath(paths{i});
end

end