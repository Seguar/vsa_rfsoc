function varargout = multi_pdw(varargin)
%    msg = 'Sorry, this function (multi_pdw.m) is not available in this version of IQtools. Please contact Keysight for support.';
%    errordlg(msg);
%    error(msg);
    multi_pulse(varargin{:});
    varargout{1} = 0;   % total samples
    varargout{2} = 0;   % amplitude shift
    varargout{3} = 0;   % time shift
    varargout{4} = 0;   % ??
end
