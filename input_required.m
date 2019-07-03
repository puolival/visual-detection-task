function [response] = input_required(message, mode)
%INPUT_REQUIRED Show message and ask for input. Repeat until a response is
%provided.
%   Last modified 22th January 2018

%% Repeat the question if no input is given.
if (mode == 'd')
    response = input(message);
elseif (mode == 's')
    response = input(message, 's');
else
    error('Unknown mode!');
end
if (isempty(response))
    response = input_required(message, mode);
end

end

