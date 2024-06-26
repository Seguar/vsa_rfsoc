function result = iqoptcheck(arbConfig, model, feature, idn)
% check connection and installed options
% returns 0 if fail, 1 if pass
result = 0;
found = 0;
arbConfig = loadArbConfig(arbConfig);

% first, check if the necessary options are available
f = iqopen(arbConfig);
if (isempty(f))
    return;
end

% check IDN string if desired
if (exist('idn', 'var') && ~isempty(idn))
      idnresp = xquery(f, '*IDN?');
      if (isempty(strfind(idnresp, idn)))
            errordlg({'Unexpected *IDN? response from instrument: ' ...
                '' ...
                idnresp ...
                'Please select the appropriate instrument in the' ...
                'config window, "Instrument model" menu'});
            iqclose(f);
            return;
      end
end

% check options
opts = xquery(f, '*OPT?');
if (~isempty(feature))
    if (~iscell(feature))
        feature = { feature };
    end
    for i = 1:length(feature)
        if (isempty(strfind(opts, feature{i})))
            errordlg({['This function or selected mode requires a software license for option "' feature{i} '" to be installed.']});
            return;
        end
        if (strcmpi(feature{i}, 'SEQ') && ...
            (strcmp(arbConfig.model, 'M8195A_4ch_256k') || strcmp(arbConfig.model, 'M8195A_2ch_256k')))
            errordlg('M8195A can not be used in this mode because the sequencer is not available with internal memory');
            return;
        end
    end
end
needOpt = [];
switch (arbConfig.model)
    case 'M8190A_12bit'
        needOpt = '12G';
    case 'M8190A_14bit'
        needOpt = '14B';
end
if (~isempty(needOpt) && (isempty(strfind(opts, needOpt))))
    errordlg({['You have selected ' arbConfig.model ' mode'] ...
        ['but you are missing the associated license (' needOpt ')'] ...
        'Please choose another mode in the "Configure' ...
        'Instrument Connection" window'});
    return;
end

% check M8199A & M8199B
if (exist('idn', 'var') && ~isempty(strfind(idn, 'M8070')))
    try
        infJson = xquery(f, sprintf(':SYST:INF:DET:JSON? "%s"', arbConfig.M8070ModuleID));
    catch ex
        iqreset();
        errordlg(['Can not communicate with M8070B. Please try again. ' ...
            'If this does not solve the problem, exit and restart MATLAB. ' ...
            '(Error message: ' ex.message ')']);
        error(['Can not communicate with M8070B. Please try again. ' ...
            'If this does not solve the problem, exit and restart MATLAB. ' ...
            '(Error message: ' ex.message ')']);
    end
    try
        info = jsondecode(infJson);
    catch
        info = struct();
    end
    if ~isfield(info, 'ProductNumber')
        errordlg(sprintf(['Module "%s" does not exist. ' ...
            'Please enter a valid Module ID in the configuration window'], arbConfig.M8070ModuleID));
        return;
    end
    if ~strcmp(info.ProductNumber, 'M8199A') && ~strcmp(info.ProductNumber, 'M8199B') && ~strcmp(info.ProductNumber, 'M8198A') 
        errordlg(sprintf(['Module "%s" is an "%s". ' ...
            'Please enter the module ID of an M8199A, M8199B, M8198A in the configuration window'], arbConfig.M8070ModuleID, info.ProductNumber));
        return;
    end
    if (~isempty(model) && ~strcmp(model, info.ProductNumber))
        errordlg(sprintf(['Module "%s" is an "%s". ' ...
            'Please enter the module ID of an %s in the configuration window'], arbConfig.M8070ModuleID, info.ProductNumber, model));
        return;
    end
    if strcmp(info.ProductNumber, 'M8199A')
        ilvresp = xquery(f, sprintf(':SYST:INST:ILVMode? "%s.System"', arbConfig.M8070ModuleID));
        if ((str2double(ilvresp) ~= 1 && strcmp(arbConfig.model, 'M8199A_ILV')) || ...
            (str2double(ilvresp) ~= 0 && strcmp(arbConfig.model, 'M8199A')))
            errordlg(sprintf(['Interleave mode setting in M8070B and IQtools does not match. ' ...
                'Please change the mode in the IQtools configuration window or M8070B']));
            return;
        end
    end
end

% check M8195A Rev.1/Rev.2
if (exist('idn', 'var') && ~isempty(strfind(idn, 'M8195A')))
    switch arbConfig.model
        case 'M8195A_Rev1'
            if (isempty(strfind(opts, 'R12')) && isempty(strfind(opts, 'R14')))
                errordlg({'You selected M8195A Rev.1, but your instrument' ...
                    'appears to be a Rev. 2 instrument.' ...
                    'Please select the appropriate instrument in the' ...
                    '"Configure Instrument Connection" window'});
            return;
            end
        case {'M8195A_1ch' 'M8195A_1ch_mrk'}
            if (isempty(strfind(opts, '001')) && isempty(strfind(opts, '002')) && isempty(strfind(opts, '004')))
                errordlg({'You selected M8195A Rev. 2, 1-channel mode,' ...
                    'but it appears that your instrument is Rev. 1 unit.' ...
                    'Please select the appropriate instrument in the' ...
                    '"Configure Instrument Connection" window'});
            return;
            end
        case {'M8195A_2ch' 'M8195A_2ch_mrk' 'M8195A_2ch_dupl' 'M8195A_2ch_256k'}
            if (isempty(strfind(opts, '002')) && isempty(strfind(opts, '004')))
                errordlg({'You selected M8195A Rev. 2, 2-channel mode,' ...
                    'but your instrument does not support this mode or it is a Rev. 1 unit.' ...
                    'Please select the appropriate instrument in the' ...
                    '"Configure Instrument Connection" window'});
            return;
            end
        case {'M8195A_4ch' 'M8195A_4ch_256k'}
            if (isempty(strfind(opts, '004')))
                errordlg({'You selected M8195A Rev. 2, 4-channel mode,' ...
                    'but your instrument does not support this mode or it is a Rev. 1 unit.' ...
                    'Please select the appropriate instrument in the' ...
                    '"Configure Instrument Connection" window'});
            return;
            end
        otherwise
            errordlg(['unknown M8195A model: ' model]);
    end
end

% check if the correct model is selected
if (~isempty(model))
    if (~iscell(model))
        model = { model };
    end
    for i = 1:length(model)
        if (~isempty(strfind(arbConfig.model, model{i})))
            found = 1;
        end
    end
    if (~found)
        switch (model{1})
            case 'bit'
                errordlg({'This utility only works with the M8190A in 14bit' ...
                    'or 12bit mode. Please select one of these modes' ...
                    'in the "Configure Instrument Connection" window'});
                return;
            case 'DUC'
                errordlg({'This utility only works with the M8190A in' ...
                    'DUC mode. Please select one of DUC modes' ...
                    'in the "Configure Instrument Connection" window'});
                return;
            otherwise
                if (length(model) == 1)
                    errordlg({['This utility will only work with instrument model ' model{1} '.'] ...
                        'Please select the appropriate instrument in the' ...
                        '"Configure Instrument Connection" window'});
                else
                    str = sprintf(['This utility does not work with the selected instrument model or mode.\n' ...
                        'Supported models are: %s'], model{1});
                    for i = 2:length(model)
                        str = [str, ', ', model{i}];
                    end
                    str = sprintf(['%s.\nPlease select the appropriate instrument in the ' ...
                        '"Configure Instrument Connection" window'], str);
                    errordlg(str);
                end
                return;
        end
    end
end

iqclose(f);
% everything is fine --> return success
result = 1;
