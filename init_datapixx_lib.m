function [] = init_datapixx_lib(datapixx_fpath)
%INIT_DATAPIXX_LIB Add path to Datapixx MEX file.
%   Last modified 8th January 2018.

if (exist(datapixx_fpath, 'dir'))
    % Check if setup has been already done
    if (~contains(path, 'Datapixx'))
        addpath(datapixx_fpath);
    end
else
    error('The path to the Datapixx MEX file does not exist');
end

end

