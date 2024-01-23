function [result, count, errmsg] = iqparse(str, varargin)
% works like str2double, but understands kHz, MHz, GHz, ms, us, ns, etc.
% optional parameters are:
% 'nothrow' - don't call error(), but return errmsg
% 'integer' - allow integers only
% 'scalar' - accept scalars only
% 'vector' - accept scalars or vectors

nothrow = false;
integer = false;
scalar = false;
vector = false;
for i = 1:(nargin-1)
    switch lower(varargin{i})
        case 'nothrow'; nothrow = true;
        case 'integer'; integer = true;
        case 'scalar'; scalar = true;
        case 'vector'; scalar = false; vector = true; % explicitly expect vector (backward compatibility)
        otherwise
            error('iqparse was called with invalid option: %s', varargin{i});
    end
end
if (~ischar(str) && ~isstring(str))
    error('iqparse must be called with a string argument (was: %s)', class(str));
end

count = -1;
result = [];
errmsg = '';
% first, try "eval" to keep backward compatibility
try
    if (vector)
        result = evalin('base', ['[' str ']']);
    else
        result = evalin('base', str);
    end
    count = length(result);
catch
    % try to parse a number, potentially followed by a unit or another number
    [result, count, errmsg, nidx] = sscanf(str, '%g', 1);
    if (count ~= 1)
        errmsg = sprintf('invalid expression: "%s"', str);
        count = -1;
    else
        % found a number --> look for a unit or another number
        errmsg = '';
        [unit, rem] = strtok(str(nidx:end), ' ,;');
        if (~isempty(unit))
            switch upper(unit)
                case {'T', 'THZ'}; result = result * 1e12;
                case {'G', 'GHZ'}; result = result * 1e9;
                case {'MHZ'}; result = result * 1e6;
                case {'K', 'KHZ'}; result = result * 1e3;
                case {'S', 'SEC'} % nothing to do
                case {'MS', 'MSEC'}; result = result * 1e-3;
                case {'U', 'US', 'USEC'}; result = result * 1e-6;
                case {'N', 'NS', 'NSEC'}; result = result * 1e-9;
                case {'P', 'PS', 'PSEC'}; result = result * 1e-12;
                case {'F', 'FS', 'FSEC'}; result = result * 1e-15;
                % special case: M can be 1e6 or 1e-6, depending on case
                case 'M'
                    if unit == 'M'
                        result = result * 1e6;
                    else
                        result = result * 1e-3;
                    end
                otherwise
                    % if another number is following, parse it and append
                    if unit(1) >= '0' && unit(1) <= '9' || unit(1) == '-'
                        rem = str(nidx:end);
                    else
                        result = [];
                        count = -1;
                        rem = '';
                        errmsg = sprintf('invalid unit: "%s"', unit);
                    end
            end
            if (~isempty(rem))
                % try to parse next entry and append if error free
                [result2, count2, errmsg2] = iqparse(rem, varargin{:});
                if (count2 > 0)
                    result = [result result2];
                    count = count + count2;
                else
                    count = -1;
                    result = [];
                    errmsg = errmsg2;
                end
            end
        end
    end
end

% check validity
if (scalar && count > 1)
    result = [];
    count = -1;
    errmsg = sprintf('expected a scalar value, got: "%s"', str);
end
if (integer && ~isequal(result, floor(result)))
    result = [];
    count = -1;
    errmsg = sprintf('expected integer value(s), got: "%s"', str);
end
if (~nothrow && count == -1)
    error(errmsg);
end
