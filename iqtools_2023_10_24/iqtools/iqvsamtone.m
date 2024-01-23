function result = iqvsamtone(varargin)
% iqvsamtone generates a calibration file for pre-distortion by 
% measuring the magnitude of the tones in a multi-tone signal
% usage: iqvsacal_mtone('param_name', value, 'param_name', value, ...)
% valid parameter names are:
%   tone - array of frequencies to be measured
%   fc - center frequency in Hz (0 in case of baseband data)
%   recalibrate - add new corr values to existing file
%
% iqvsamtone looks for a variable called hVsaApp in the base MATLAB context.
% If it exists, it is assumed to be a handle to an instance of the VSA
% software. If it does not exist, it opens a new instance

result = [];
tone = [];
fc = 0;
useHW = 1;
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'tone';           tone = varargin{i+1};
            case 'fc';             fc = varargin{i+1};
            case 'recalibrate';    recalibrate = varargin{i+1};
            case 'usehw';          useHW = varargin{i+1};
            otherwise error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
        return;
    end
    i = i+2;
end
% make sure tone vector is the correct shape
if (size(tone,2) > 1)
    tone = tone';
end
result = newVSACal(tone, fc, recalibrate, useHW);
end

function result = newVSACal(tone, fc, recalibrate, useHW)
    result = [];
    origTone = tone;
    ifc = fc;
    if (min(tone) > 0 && fc == 0)
        ifc = 1;
    end
    vsaFc = fc + (max(tone) + min(tone)) / 2;
    vsaSpan = (max(tone) - min(tone)) * 1.01;
    if (vsaSpan < 10e6)
        vsaSpan = 10e6;
    end
    vsaApp = vsafunc([], 'open');
    if (~isempty(vsaApp))
        hMsgBox = msgbox('Configuring VSA software. Please wait...');
        % if hardware is used, set up VSA, otherwise assume that it has
        % been set up before
        if (useHW)
            vsafunc(vsaApp, 'preset', 'vector');
            vsafunc(vsaApp, 'fromHW');
            vsafunc(vsaApp, 'input', ifc);
            vsafunc(vsaApp, 'freq', vsaFc, vsaSpan, 6401, 'flattop', 3);
            vsafunc(vsaApp, 'trace', 1, 'Tones');
            vsafunc(vsaApp, 'start', 1);
            vsafunc(vsaApp, 'autorange');
            vsafunc(vsaApp, 'autoscale');
        end
        try
            close(hMsgBox);
        catch
        end
        res = questdlg('Please check input range and press OK to start calibration.','VSA Calibration','OK','Cancel','OK');
        if (~strcmp(res, 'OK'))
            return;
        end
        result = vsafunc(vsaApp, 'mtone', origTone, fc, recalibrate);
        if (~isempty(result))
            iqshowcorr();
        end
    end
end

