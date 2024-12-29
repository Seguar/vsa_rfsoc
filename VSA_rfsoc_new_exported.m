classdef VSA_rfsoc_new_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        RFSoCBeamformerUIFigure        matlab.ui.Figure
        GridLayout                     matlab.ui.container.GridLayout
        LeftPanel                      matlab.ui.container.Panel
        MirrorCheckBox_3               matlab.ui.control.CheckBox
        SignalpriorityButtonGroup      matlab.ui.container.ButtonGroup
        LessPowerfullButton            matlab.ui.control.RadioButton
        MostPowerfullButton            matlab.ui.control.RadioButton
        ChannelselectListBox           matlab.ui.control.ListBox
        ChannelselectListBoxLabel      matlab.ui.control.Label
        PlotCheckBox                   matlab.ui.control.CheckBox
        CustomCommandTextArea          matlab.ui.control.TextArea
        CustomCommandTextAreaLabel     matlab.ui.control.Label
        VSACheckBox                    matlab.ui.control.CheckBox
        AvgSpinner                     matlab.ui.control.Spinner
        AvgSpinnerLabel                matlab.ui.control.Label
        TabGroup                       matlab.ui.container.TabGroup
        MainTab                        matlab.ui.container.Tab
        TXLabel                        matlab.ui.control.Label
        RXLabel                        matlab.ui.control.Label
        DACBFmodeListBox               matlab.ui.control.ListBox
        DACBFmodeListBoxLabel          matlab.ui.control.Label
        AngleSpinner                   matlab.ui.control.Spinner
        AngleSpinnerLabel              matlab.ui.control.Label
        BFtypeListBox                  matlab.ui.control.ListBox
        BFtypeListBoxLabel             matlab.ui.control.Label
        DOAtypeListBox                 matlab.ui.control.ListBox
        DOAtypeListBoxLabel            matlab.ui.control.Label
        DOAresolutionEditField         matlab.ui.control.NumericEditField
        DOAresolutionEditField_3Label  matlab.ui.control.Label
        SystemTab                      matlab.ui.container.Tab
        PrintphasemissmatchButton      matlab.ui.control.Button
        Ch4SpinnerLabel                matlab.ui.control.Label
        Ch4Spinner                     matlab.ui.control.Spinner
        Ch3SpinnerLabel                matlab.ui.control.Label
        Ch3Spinner                     matlab.ui.control.Spinner
        Ch2SpinnerLabel                matlab.ui.control.Label
        Ch2Spinner                     matlab.ui.control.Spinner
        Ch1Spinner                     matlab.ui.control.Spinner
        Ch1SpinnerLabel                matlab.ui.control.Label
        ChannelcontrolDropDown         matlab.ui.control.DropDown
        ChannelcontrolDropDownLabel    matlab.ui.control.Label
        MirrorCheckBox_2               matlab.ui.control.CheckBox
        SREditField                    matlab.ui.control.NumericEditField
        SREditFieldLabel               matlab.ui.control.Label
        FeEditField                    matlab.ui.control.NumericEditField
        FeEditFieldLabel               matlab.ui.control.Label
        FcEditField                    matlab.ui.control.NumericEditField
        FcEditFieldLabel               matlab.ui.control.Label
        DacSignalDropDown              matlab.ui.control.DropDown
        DacSignalDropDownLabel         matlab.ui.control.Label
        AntennaFcSpinner               matlab.ui.control.Spinner
        AntennaFcSpinnerLabel          matlab.ui.control.Label
        AntennaLabel                   matlab.ui.control.Label
        SyncButton                     matlab.ui.control.Button
        MirrorCheckBox                 matlab.ui.control.CheckBox
        SYNCDropDown                   matlab.ui.control.DropDown
        SYNCDropDownLabel              matlab.ui.control.Label
        EvenNyquistZoneCheckBox_2      matlab.ui.control.CheckBox
        dataStreamCheckBox             matlab.ui.control.CheckBox
        RFSoCFcSpinner_2               matlab.ui.control.Spinner
        RFSoCFcSpinner_2Label          matlab.ui.control.Label
        DACsLabel                      matlab.ui.control.Label
        ADCsLabel                      matlab.ui.control.Label
        EvenNyquistZoneCheckBox        matlab.ui.control.CheckBox
        RecalibrateADCsButton          matlab.ui.control.Button
        ScanBWEditField                matlab.ui.control.NumericEditField
        ScanBWEditFieldLabel           matlab.ui.control.Label
        LoadVSAsetupButton             matlab.ui.control.Button
        SigBWSpinner                   matlab.ui.control.Spinner
        SigBWSpinnerLabel              matlab.ui.control.Label
        MaxSignalsSpinner              matlab.ui.control.Spinner
        MaxSignalsSpinnerLabel         matlab.ui.control.Label
        RFSoCFsSpinner                 matlab.ui.control.Spinner
        RFSoCFsSpinnerLabel            matlab.ui.control.Label
        RFSoCFcSpinner                 matlab.ui.control.Spinner
        RFSoCFcSpinnerLabel            matlab.ui.control.Label
        mmWaveFrontEndTab              matlab.ui.container.Tab
        AmplitudeAutocalStartButton_2  matlab.ui.control.Button
        PhaseAutocalStartButton_2      matlab.ui.control.Button
        TXLabel_2                      matlab.ui.control.Label
        AmplitudeAutocalStartButton    matlab.ui.control.Button
        RXLabel_2                      matlab.ui.control.Label
        PhaseAutocalStartButton        matlab.ui.control.Button
        DCLeakageAutocalStartButton    matlab.ui.control.Button
        StepangEditField               matlab.ui.control.NumericEditField
        StepangEditFieldLabel          matlab.ui.control.Label
        StarrangEditField              matlab.ui.control.NumericEditField
        StarrangEditFieldLabel         matlab.ui.control.Label
        ArduinoGUIButton               matlab.ui.control.Button
        StartanglecalibrationsButton   matlab.ui.control.Button
        Gauge                          matlab.ui.control.SemicircularGauge
        DebugTab                       matlab.ui.container.Tab
        SaveButton                     matlab.ui.control.Button
        NumberofsavedfilesEditField    matlab.ui.control.NumericEditField
        NumberofsavedfilesLabel        matlab.ui.control.Label
        DebugCheckBox_2                matlab.ui.control.CheckBox
        CutterCheckBox                 matlab.ui.control.CheckBox
        iterEditField                  matlab.ui.control.NumericEditField
        iterEditFieldLabel             matlab.ui.control.Label
        alphaEditField                 matlab.ui.control.NumericEditField
        alphaEditFieldLabel            matlab.ui.control.Label
        gammaEditField                 matlab.ui.control.NumericEditField
        gammaEditFieldLabel            matlab.ui.control.Label
        alg_scan_resEditField          matlab.ui.control.NumericEditField
        alg_scan_resEditFieldLabel     matlab.ui.control.Label
        mis_angEditField               matlab.ui.control.NumericEditField
        mis_angEditFieldLabel          matlab.ui.control.Label
        patternCorrCheckBox            matlab.ui.control.CheckBox
        BWEditField                    matlab.ui.control.NumericEditField
        BWEditFieldLabel               matlab.ui.control.Label
        GetSpectrumButton              matlab.ui.control.StateButton
        DLFEditField                   matlab.ui.control.NumericEditField
        DLFEditFieldLabel              matlab.ui.control.Label
        UpdRateEditField               matlab.ui.control.NumericEditField
        UpdRateEditFieldLabel          matlab.ui.control.Label
        MatlabPatternCheckBox          matlab.ui.control.CheckBox
        c2CheckBox                     matlab.ui.control.CheckBox
        c1CheckBox                     matlab.ui.control.CheckBox
        dataChanEditField              matlab.ui.control.NumericEditField
        dataChanEditFieldLabel         matlab.ui.control.Label
        CutoffsetEditField             matlab.ui.control.NumericEditField
        CutoffsetEditFieldLabel        matlab.ui.control.Label
        GetPatternButton               matlab.ui.control.StateButton
        DevicesTab                     matlab.ui.container.Tab
        IPEditField                    matlab.ui.control.EditField
        IPEditFieldLabel               matlab.ui.control.Label
        ModulationCheckBox             matlab.ui.control.CheckBox
        PowerCheckBox                  matlab.ui.control.CheckBox
        AmplitudeSpinner               matlab.ui.control.Spinner
        AmplitudeSpinnerLabel          matlab.ui.control.Label
        FrequencySpinner               matlab.ui.control.Spinner
        FrequencySpinnerLabel          matlab.ui.control.Label
        DevicecontrolDropDown          matlab.ui.control.DropDown
        DevicecontrolDropDownLabel     matlab.ui.control.Label
        ResetButton                    matlab.ui.control.StateButton
        RightPanel                     matlab.ui.container.Panel
        GridLayout2                    matlab.ui.container.GridLayout
        UIAxes2                        matlab.ui.control.UIAxes
        UIAxes                         matlab.ui.control.UIAxes
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end

    properties (Access = private)
        Property % Description
        rxBoardControl_app;
        %% App fields
        vsa = 1;
        ch = 5;
        bf = 'Steering';
        doa = 'MVDR';
        cutter = 0;
        off = 500;
        gap = 0;
        ang_num = 1;

        diag = 1;
        bwOff = 0.1;

        dataChan = 2^13;
        scan_res = 1;
        debug = 0;
        plotUpd = 1;
        MatlabPattern = 0;
        avg_factor = 1;
        updrate = 10;
        c1 = 0;
        c2 = 0;
        patternCorr = 0;
        numFiles = 1;
        saveFlg = 0;
        saveName;
        %%
        ula
        fcAnt = 4500e6;
        weights
        c = physconst('LightSpeed'); % propagation velocity [m/s]
        alg_scan_res = 1;
        mis_ang = 15;
        alpha = 1.1;
        gamma = 1;
        iter = 1;
        %% System
        fc = 1e9;
        fsRfsoc = 250e6;
        fsDAC = 500e6;
        bw = 249e6;
        num = 1;
        scan_bw = 180;
        setupFile = [fileparts(mfilename('fullpath')) '\Settings\ofdm_iq_100_16.setx'];

        server_ip = 'pynq'; % Use the appropriate IP address or hostname http://192.168.3.1/lab
        %         server_ip = '132.68.138.226'; % Use the appropriate IP address or hostname http://192.168.3.1/lab

        %         server_ip = '132.68.138.226'; % Use the appropriate IP address or hostname http://192.168.3.1/lab
        server_port = 4000; % Use the same port number used in the Python server


        %% Devices
        %         gen_ip = '132.68.138.225';
        % gen_ip = 'A-N5182B-052325';
        gen_ip = '132.68.138.193';

        gen_port = 5025;

        visaDevList;
        currentDevIP = "";
        currentDev = "";
        lorx = struct('Model', "N5182B", 'IP', "", "State", 1, 'Power', 5, 'Fc', 2000, 'Mod', 0);
        lotx = struct('Model', "E8267D", 'IP', "132.68.138.223", "State", 1, 'Power', 10, 'Fc', 28050, 'Mod', 0);

        %% Downconverter
        phase_cal = 0;
        arduino;
        phase_gauge;
        start_ang = -60;
        step_ang = 10;
        cur_ang = 0;
        phase_cal_butt = 0;

        autocal = 0;
        autocal_threshold = 50;
        autocal_min_array = [];
        autocal_registers = [];
        autocal_rx_amp = 0;
        autocal_rx_phase = 0;
        %% Upconverter
        autocal_tx_amp = 0;
        autocal_tx_phase = 0;
        %% Flags
        reset_req = 1;
        part_reset_req = 1;
        estimator;
        plotMirror = 0;
        %%
        commands = [];
        dataStream = 1;
        nyquistZone = 1;
        nyquistZone_d0 = 1;
        nyquistZone_d1 = 1;
        fc_d0 = 4.5e9;
        fc_d1 = 4.5e9;

        dacPow = [1,1,1,1];
        da = 1;
        bwDac = 499e6;
        fsOrig = 60e6;
        dacFilt = 0;
        resmp = 0;

        adcMirror = 1;
        dacMirror = 1;
        dacAngle = 0;
        dacSignalType = 0;

        dacBF = 'Off';
        dacBFon = 0;
        dacTestArray;
        dacFc = 0;
        dacFe = 50;
        dacSR = 1;
        dacAmp = 2^14-1;
        dacGain = [199, 199, 199, 199];
        adcGain = [80, 199, 140, 70]; % Calibrated with metal surface
        dacActiveCh = [1,1,1,1];
        dphase = [0,0,0,0];
        %         dphaseCorr = [0,9,-132,-18];
        %         dphaseCorr = [0,-22,-37,-162];
        dgainCorr = [199,199,199,199];
        dphaseCorr = [0,0,-40,-173];
        %         dphaseCorr = [0,15,-36,144];
        phase = [0,0,0,0];
        % phase = [0,-68,-23,-30]; % [  0.         -68.16668724 -23.64564807 -30.27015883] [  0.         -87.57967336 -41.12039743 -49.63200857]
        %         phase = [0,13,-20,-18];
        manualControlState = "DAC phase";

        phaseMax = 179; %RFSoC limits
        phaseMin = -179; %RFSoC limits
        %% Reset vars
        data_v
        setup_v
        %% Part reset vars
        p_manual_mean, yspec_mean, plot_handle, tcp_client

        %%
        rawData;
    end
    properties (Access = public)
        scan_axis = -90:1:90;
        %% Hardcode (temporally)
        koef;
        num_elements = 4;

        fcInt = 5.7e9;
        stateInt = 0;
        powInt = 0;
        modInt = 0;

        fcSig = 5.7e9;
        fsSig = 60e6;
        gainSig = 0;
        txSig = complex(zeros(1000, 1));
        txInt;
        tx = [];


        sigPath = '.\Signals\';
        settPath = '.\Settings\';
    end

    methods (Access = public)

    end

    methods (Access = private)


        function resetApp(app)
            partReset(app);
            app.dacTestArray = app.scan_axis;
            app.ResetButton.Text = 'Reseting...';
            app.ResetButton.BackgroundColor = 'r';
            drawnow%!!!!
            [app.data_v, app.setup_v] = vsaDdc(0, app.fsRfsoc, app.fsRfsoc, app.dataChan, 1);
            vsaSetup(app.setupFile)
            commandsHandler(app, ['da ' num2str(app.da)]);
            commandsHandler(app, ['dataStream ' num2str(app.dataStream)]);
            disp(app.commands)
            app.tcp_client = rfsocConnect(app.server_ip, app.server_port, app.commands);
            app.commands = [];
            flush(app.tcp_client)
            clf(app.UIAxes);
            app.reset_req = 0;
            app.part_reset_req = 0;
            app.ResetButton.Text = 'Reset';
            app.ResetButton.BackgroundColor = 'g';
        end

        function partReset(app)
            app.ResetButton.Text = 'Reseting...';
            app.ResetButton.BackgroundColor = 'y';
            drawnow%!!!!
            app.ula = antPrep(app.num_elements, app.c, app.fcAnt);
            app.scan_axis = -app.scan_bw/2:app.scan_res:app.scan_bw/2;
            app.plot_handle = plotPrep(app, app.scan_axis);
            app.p_manual_mean = zeros(length(app.scan_axis), app.avg_factor);
            app.yspec_mean = zeros(length(app.scan_axis), app.avg_factor);
            app.estimator = doaEst(app.doa, app.ula, app.scan_axis, app.num, app.fcAnt); %% Need to fix scan_axis
            %             app.koef = antSinglePattern(app.fc, app.scan_axis)';
            load koef
            app.koef = koef;
            app.koef = interp1(linspace(1,length(app.koef),length(app.koef))', app.koef, linspace(1,length(app.koef),length(app.scan_axis))', 'linear', 'extrap');
            app.part_reset_req = 0;
            app.ResetButton.Text = 'Reset';
            app.ResetButton.BackgroundColor = 'g';
        end

        function commandsHandler(app, command)
            if isempty(app.commands)
                app.commands = command;
            else
                app.commands = append(app.commands, '#', command);
            end
        end

        function phase_relation_deg = PAcheck(app, data)
            [~, ~, phase_relation] = cphase(data, 1);
            phase_relation_deg = rad2deg(phase_relation);
            disp('-----')
            disp('Phase missmatch:')
            fprintf('   %.2f\n',phase_relation_deg);
            plot(real(data(1:100,:))/max(max(real(data(1:100,:)))))
            hold on
            plot(imag(data(1:100,:))/max(max(imag(data(1:100,:)))), '--')
            legend('Ch1 I', 'Ch2 I', 'Ch3 I', 'Ch4 I', 'Ch1 Q', 'Ch2 Q', 'Ch3 Q', 'Ch4 Q')
            ylim([-1.2 1.2])
            title('Phase and Amplitudes check')
            xlabel('Time')
            ylabel('Amplitude')
            hold off
            uistack(gcf,'top')
        end
    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            cd(fileparts(mfilename('fullpath')))
            %             addpath(genpath([pwd '\iqtools_2023_10_24']))
            addpath(genpath([pwd '\Packet-Creator-VHT']))
            addpath(genpath([pwd '\Functions']))
            pwd
            %             load koef
            %             app.koef = koef;
            app.RFSoCBeamformerUIFigure.Visible = 'off';
            movegui(app.RFSoCBeamformerUIFigure,"east")
            app.RFSoCBeamformerUIFigure.Visible = 'on';
            main.line = '-b';
            main.txt = 'Main';
            sub.line = '--c';
            sub.txt = 'Sub';
            dacmain.line = '-m';
            dacmain.txt = 'Dac';
            count = 1;
            autocal_cnt = 0;
            inphase_state = 1;
            data = [];
            data_dc = [];
            fileCnt = 1;
            am = [];
            bs = [];
            cs = [];
            adac = [];
            am2 = [];
            bs2 = [];
            cs2 = [];
            adac2 = [];
            saveFile = [];
            app.commands = ['fc ' num2str(app.fc/1e6) '/' num2str(app.nyquistZone) '/' ...
                num2str(app.fc_d0/1e6) '/' num2str(app.nyquistZone_d0) '/' ...
                num2str(app.fc_d1/1e6) '/' num2str(app.nyquistZone_d1) ...
                '# dataChan ' num2str(app.dataChan*8)];
            warning('off','all')
            while true
                if app.reset_req
                    resetApp(app);
                elseif app.part_reset_req
                    partReset(app);
                end
                if app.debug
                    disp('New data')
                    tic
                end
                if app.dataStream
                    try
                        [yspec, estimated_angle, bfSig, app.weights, app.rawData] = rfsocBf(app, app.vsa, app.ch, app.bf, app.off, app.gap, app.cutter, ...
                            app.ang_num, app.data_v, app.tcp_client, app.fcAnt, app.dataChan, app.diag, app.bwOff, app.ula, app.scan_axis, ...
                            app.c1, app.c2, app.fsRfsoc, app.bw, app.c, app.estimator, app.alg_scan_res, app.mis_ang, app.alpha, app.gamma, app.iter, app.setup_v, app.debug);
                        if isnan(app.weights)
                            disp("No signal")
                            app.weights = 0;
                            %                             continue
                        end
                    catch
                        disp("Error in rfsocBf")
                        if not(isempty(app.commands))
                            oldComs = app.commands;
                            writeline(app.tcp_client, app.commands);
                            if string(oldComs) == string(app.commands)
                                app.commands = [];
                            end
                        else
                            writeline(app.tcp_client, 'alive 1');
                        end
                        continue
                    end
                    if app.debug
                        bf_time = toc;
                        disp(['bf time ' num2str(bf_time) ' s'])
                    end
                end
                %                     disp('___')
                %                     toc
                %% Pattern calc
                if app.plotUpd
                    app.weights = conj(app.weights);
                    p_manual = beamPatternCalc(app.weights, app.fcAnt, app.scan_axis, length(app.weights));

                    %% Avg
                    [p_manual_mean_vec, app.p_manual_mean]  = avgData(p_manual, app.p_manual_mean);
                    p_manual_mean_db = 20*log10(p_manual_mean_vec) - max(20*log10(p_manual_mean_vec));
                    [yspec_mean_vec, app.yspec_mean]  = avgData(yspec, app.yspec_mean);
                    if app.patternCorr
                        yspec_mean_vec = yspec_mean_vec.*(1./app.koef);
                    end
                    %% Plot
                    if app.plotMirror
                        yspec_mean_vec = flip(yspec_mean_vec);
                        estimated_angle = -1*estimated_angle;
                        p_manual_mean_db = flip(p_manual_mean_db);
                        app.dacAngle = -1*app.dacAngle;
                    end

                    app.UIAxes.Title.String = (['Direction of Arrival:' newline  'Estimated Angles = ' num2str(estimated_angle) newline 'DAC Angles = ' num2str(app.dacAngle)]);

                    set(app.plot_handle, 'YData', (yspec_mean_vec/max(yspec_mean_vec)), 'LineWidth', 1.5);
                    plot(app.UIAxes2, app.scan_axis,p_manual_mean_db, 'LineWidth', 1.5);
                    % Xlines
                    estimated_angle = [estimated_angle NaN NaN]; % To prevent errors in xlines indexing
                    am = guiXline(am, app.UIAxes, main, estimated_angle(1), 'right');
                    am2 = guiXline(am2, app.UIAxes2, main, estimated_angle(1), 'right');
                    if app.dacBFon
                        adac = guiXline(adac, app.UIAxes, dacmain, app.dacAngle, 'left');
                        adac2 = guiXline(adac2, app.UIAxes2, dacmain, app.dacAngle, 'left');
                    end
                    %% GUI lines
                    if sum(~isnan(estimated_angle)) > 1
                        bs = guiXline(bs, app.UIAxes, sub, estimated_angle(2), 'center');
                        bs2 = guiXline(bs2, app.UIAxes2, sub, estimated_angle(2), 'center');
                        null_diff = round(p_manual_mean_db((app.scan_axis == estimated_angle(1))) - p_manual_mean_db((app.scan_axis == estimated_angle(2))));
                        app.UIAxes2.Title.String = (['Beam Pattern' newline  'Gain Difference = ' ...
                            num2str(abs(null_diff)) ' dB']);
                        if sum(~isnan(estimated_angle)) > 2
                            cs = guiXline(cs, app.UIAxes, sub, estimated_angle(3), 'center');
                            cs2 = guiXline(cs2, app.UIAxes2, sub, estimated_angle(3), 'center');
                        end
                    else
                        null_diff = round(p_manual_mean_db((app.scan_axis == estimated_angle(1))) - min(p_manual_mean_db));
                        app.UIAxes2.Title.String = (['Beam Pattern' newline  'Gain Difference = ' ...
                            num2str(abs(null_diff)) ' dB']);
                    end
                    %% BF pattern
                    if app.MatlabPattern
                        if count >= app.updrate
                            plotResponse(app.ula,app.fcAnt,app.c,...
                                'AzimuthAngles',app.scan_axis,...
                                'Unit','db',...
                                'Weights',app.weights.');
                            count = 1;
                        else
                            count = count + 1;
                        end
                    end
                end
                %% Raw Data save
                if app.saveFlg
                    if fileCnt >= app.numFiles
                        fileCnt = 1;
                        app.saveFlg = 0;
                        save(app.saveName, 'saveFile')
                        saveFile = [];
                    else
                        saveFile(fileCnt).raw = app.rawData;
                        fileCnt = fileCnt + 1;
                    end
                end
                %% RX DC Leakage autocal
                while app.autocal % if for on-line
                    % --- Safely initialize data_dc if it doesn't exist or is empty ---
                    if ~exist('data_dc','var') || isempty(data_dc)
                        data_dc = 0;
                    end

                    % --- If we haven't finished the in-phase and quadrature sweeps (0->66) ---
                    if autocal_cnt <= 66

                        % --- If autocal_cnt == 33, reset to 'inphase_state=0' and re-init min array ---
                        if autocal_cnt == 33
                            inphase_state = 0;
                            app.rxBoardControl_app.registers = app.autocal_registers;
                            app.autocal_min_array = inf(1,4);   % [inf inf inf inf]
                        end

                        % --- Filter your signal and accumulate power
                        % --- DC leakage on narrow band
                        writeline(app.tcp_client, 'alive 1');
                        rawData = 0;
                        rawData = tcpDataRec(app.tcp_client, (app.dataChan * 8), 8); % Comment for on-line
                        rawData = filtSig(rawData, app.fsRfsoc, 1e6);%  Comment for on-line
                        % rawData = filtSig(app.rawData, app.fsRfsoc, 1e6); % Uncomment for on-line
                        data_dc = data_dc + bandpower(rawData);

                        % --- Once we reach avg_factor accumulations, average and update ---
                        if count == app.avg_factor

                            data_dc = data_dc / app.avg_factor;  % average across 'avg_factor'
                            mask    = data_dc < app.autocal_min_array;

                            % Update registers for channels that found a new minimum
                            if any(mask)
                                % For each channel that has lower data_dc, update autocal_registers
                                for iCh = find(mask)
                                    if inphase_state
                                        fName = ['RX' num2str(iCh) '_DAC_I'];
                                    else
                                        fName = ['RX' num2str(iCh) '_DAC_Q'];
                                    end
                                    % Store “best so far” register + min power
                                    app.autocal_registers.(fName) = app.rxBoardControl_app.registers.(fName);
                                    app.autocal_min_array(iCh)    = data_dc(iCh);
                                end
                            end

                            % Now increment the current DAC values by updating rxBoardControl_app
                            % If inphase_state == 1 => we’re sweeping 'I' values
                            if inphase_state
                                for iCh = 1:4
                                    fName = ['RX' num2str(iCh) '_DAC_I'];
                                    app.rxBoardControl_app.registers.(fName) = autocal_cnt + 30;
                                end
                            else
                                % else we’re sweeping 'Q' values => offset by -63
                                for iCh = 1:4
                                    fName = ['RX' num2str(iCh) '_DAC_Q'];
                                    app.rxBoardControl_app.registers.(fName) = autocal_cnt - 33;
                                end
                            end

                            % Bump the autocal counter, reset count + data_dc, then update board
                            autocal_cnt = autocal_cnt + 1;
                            count       = 1;
                            data_dc     = [];

                            app.rxBoardControl_app.updateFields;
                            app.rxBoardControl_app.updateRXboard;

                        else
                            % If we haven’t yet reached app.avg_factor, just increment
                            count = count + 1;
                        end

                    else
                        % --- Done with 0->66 sweep => switch to inphase_state=1 or stop calibration
                        inphase_state = 1;
                        autocal_cnt   = 0;
                        count         = 1;
                        app.autocal   = 0;


                        app.rxBoardControl_app.registers = app.autocal_registers;
                        app.rxBoardControl_app.updateFields;
                        app.rxBoardControl_app.updateRXboard;
                        app.DCLeakageAutocalStartButton.BackgroundColor = 'g';

                    end
                end
                %% RX Amplitude autocal
                cal_flag = 0;
                while app.autocal_rx_amp
                    if ~(cal_flag) % First value only
                        rawData = 0;
                        rawData = tcpDataRec(app.tcp_client, (app.dataChan * 8), 8);
                        rawData = filtSig(rawData, app.fsRfsoc, app.bw);
                        min_val = min(max(real(rawData)));
                        min_ch = find(max(real(rawData) == min_val)); % Min channel
                        bs_left = [1,1,1,1];
                        bs_right = [199,199,199,199];
                        cal_flag = 1;
                    end

                    if cal_flag
                        bs_middle = round((bs_left+bs_right)/2);
                        if any(bs_middle > 199)
                            disp(bs_middle)
                            uialert(app.RFSoCBeamformerUIFigure,'Out of limits, check Fc and BW','Calibration Error');
                            app.autocal_rx_amp = 0;
                            break
                        end
                        bs_middle(min_ch) = 199;
                        app.adcGain = bs_middle;
                        
                        commandsHandler(app, ['again ' strjoin(arrayfun(@num2str, app.adcGain, 'UniformOutput', false), '/');]);
                        writeline(app.tcp_client, app.commands);
                        app.commands = [];
                        rawData = 0;
                        rawData = tcpDataRec(app.tcp_client, (app.dataChan * 8), 8);
                        rawData = filtSig(rawData, app.fsRfsoc, app.bw);
                        PAcheck(app, rawData);
                        all_max = max(real(rawData));
                        min_val = all_max(min_ch);
                        all_max = all_max/min_val;
                        round_max = round(all_max, 1); % 5% precision
                        % round_max = round(all_max); % 1% precision
                        mask = round_max == round_max(min_ch);
                        if all(mask) %% end
                            cal_flag = 0;
                            app.autocal_rx_amp = 0;
                            disp(app.adcGain);
                            app.AmplitudeAutocalStartButton.BackgroundColor = 'g';
                        end

                        for i=1:4
                            if round_max(i) < round_max(min_ch)
                                bs_left(i) =  bs_middle(i) + 1;
                            elseif round_max(i) > round_max(min_ch)
                                bs_right(i) =  bs_middle(i) - 1;
                            else
                                app.adcGain(i) = bs_middle(i);
                            end
                        end
                        disp(app.adcGain);
                    end                    
                end
                %% RX Phase autocal
                while app.autocal_rx_phase % if for on-line
                    genCtrl(app.gen_ip, app.gen_port, 0, 5, 2e9, 0);
                    pause(1)
                    genCtrl(app.gen_ip, app.gen_port, 1, 5, 2e9, 0);
                    pause(0.1)
                    % writeline(app.tcp_client, 'alive 1');
                    rawData = 0;
                    rawData = tcpDataRec(app.tcp_client, (app.dataChan * 8), 8);
                    rawData = filtSig(rawData, app.fsRfsoc, app.bw);

                    phase_relation_deg = PAcheck(app, rawData);
                    phase_relation_deg = abs(phase_relation_deg);
                    % phase_relation_deg(phase_relation_deg > 180) = abs(phase_relation_deg(phase_relation_deg > 180) - 360);
                    if all(phase_relation_deg < 100)
                        app.PhaseAutocalStartButton.BackgroundColor = 'g';
                        app.autocal_rx_phase = 0;
                    end
                    writeline(app.tcp_client, 'alive 1');
                end
                %% TX Amplitude autocal
                cal_flag = 0;
                min_val = inf;
                while app.autocal_tx_amp
                    if ~(cal_flag) % First value only
                        for i=1:4
                            app.dacGain = [0,0,0,0];
                            app.dacGain(i) = 199;
                            commandsHandler(app, ['dgain ' strjoin(arrayfun(@num2str, app.dacGain, 'UniformOutput', false), '/');]);
                            writeline(app.tcp_client, app.commands);
                            app.commands = [];
                            rawData = 0;
                            rawData = tcpDataRec(app.tcp_client, (app.dataChan * 8), 8);
                            rawData = filtSig(rawData, app.fsRfsoc, app.bw);
                            data = sum(rawData,2);
                            if min_val > max(real(data))
                                min_val = max(real(data));
                                min_ch = i; % Min channel
                            end
                            plot(real(data(1:100))/max(max(real(data(1:100)))))
                            hold on
                            % plot(imag(data(1:100))/max(max(imag(data(1:100)))))
                            ylim([-1.2 1.2])
                            uistack(gcf,'top')

                        end
                        bs_left = 1;
                        bs_right = 199;
                        mask = [0,0,0,0];
                        bs_middle = [0,0,0,0];
                        mask(min_ch) = 1;
                        bs_middle(min_ch) = 199;
                        cal_flag = 1;
                        j = 1;
                        hold off
                    end
                    if cal_flag
                        if mask(j) && j <= 3
                            j = j + 1;
                            bs_left = 1;
                            bs_right = 199;
                        end
                        bs_middle(j) = round((bs_left+bs_right)/2);
                        if any(bs_middle > 199)
                            disp(bs_middle)
                            uialert(app.RFSoCBeamformerUIFigure,'Out of limits, check Fc and BW','Calibration Error');
                            app.autocal_tx_amp = 0;
                            break
                        end
                        % bs_middle(min_ch) = 199;
                        app.dacGain = [0,0,0,0];
                        app.dacGain(j) = bs_middle(j);
                        commandsHandler(app, ['dgain ' strjoin(arrayfun(@num2str, app.dacGain, 'UniformOutput', false), '/');]);
                        writeline(app.tcp_client, app.commands);
                        app.commands = [];
                        rawData = 0;
                        rawData = tcpDataRec(app.tcp_client, (app.dataChan * 8), 8);
                        rawData = filtSig(rawData, app.fsRfsoc, app.bw);
                        % PAcheck(app, rawData);
                        data = sum(rawData,2);
                        all_max = max(real(data));
                        % min_val = all_max(min_ch);
                        all_max = all_max/min_val;
                        round_max = round(all_max, 1); % 5% precision
                        % round_max = round(all_max); % 1% precision
                        mask(j) = round_max == min_val/min_val;
                        if all(mask) %% end
                            app.dgainCorr = bs_middle;
                            app.dacGain = bs_middle;
                            commandsHandler(app, ['dgain ' strjoin(arrayfun(@num2str, app.dacGain, 'UniformOutput', false), '/');]);
                            cal_flag = 0;
                            app.autocal_tx_amp = 0;
                            disp(bs_middle);
                            app.AmplitudeAutocalStartButton_2.BackgroundColor = 'g';
                        end

                        % for i=1:4
                        if round_max < min_val/min_val
                            bs_left =  bs_middle(j) + 1;
                        elseif round_max > min_val/min_val
                            bs_right =  bs_middle(j) - 1;
                        else
                            app.dacGain(j) = bs_middle(j);
                        end
                        % end
                        disp(app.dacGain);
                    end
                end
                %% TX Phase autocal
                phaseStep = 1; % Change for preciesion
                all_min = inf(1,4);
                while app.autocal_tx_phase
                    for curCh=2:4
                        app.dacActiveCh(curCh) = 1;
                        app.dacGain = app.dgainCorr.*app.dacActiveCh;
                        commandsHandler(app, ['dgain ' strjoin(arrayfun(@num2str, app.dacGain, 'UniformOutput', false), '/');]);
                        for curPhase=app.phaseMin:phaseStep:app.phaseMax
                            disp(curPhase)
                            app.dphase(curCh) = curPhase;
                            app.dphase = app.dphase.*app.dacActiveCh;
                            commandsHandler(app, ['dphase ' strjoin(arrayfun(@num2str, app.dphase*100, 'UniformOutput', false), '/');]);
                            writeline(app.tcp_client, app.commands);
                            app.commands = [];

                            rawData = 0;
                            rawData = tcpDataRec(app.tcp_client, (app.dataChan * 8), 8);
                            rawData = filtSig(rawData, app.fsRfsoc, app.bw);
                            % PAcheck(app, rawData);
                            data = sum(rawData,2);
                            all_max = max(real(data));
                            if all_max < all_min
                                all_min = all_max;
                                if curPhase < 0 % Convert to corrections
                                    app.dphaseCorr(curCh) = curPhase + 180;
                                else
                                    app.dphaseCorr(curCh) = curPhase - 180;
                                end
                            end

                            if curPhase == app.phaseMax
                                app.dacActiveCh = [1,0,0,0];
                                disp(app.dphaseCorr)
                            end
                        end
                    end
                    app.PhaseAutocalStartButton_2.BackgroundColor = 'g';
                    app.autocal_tx_phase = 0;
                    app.dacActiveCh = [1,1,1,1];
                    app.dacGain = app.dgainCorr.*app.dacActiveCh;
                    commandsHandler(app, ['dgain ' strjoin(arrayfun(@num2str, app.dacGain, 'UniformOutput', false), '/');]);
                end
                %% RX Angles cal
                while app.phase_cal
                    app.StartanglecalibrationsButton.Text = ['Set ' num2str(app.cur_ang) ' deg and press'];
                    app.Gauge.Value = app.cur_ang;
                    app.phase_cal_butt = 0;
                    uiwait
                    %                             app.StartanglecalibrationsButton.BackgroundColor = 'g';
                    writeline(app.tcp_client, 'alive 1');
                    rawData = 0;
                    rawData = tcpDataRec(app.tcp_client, (app.dataChan * 8), 8);
                    rawData = filtSig(rawData, app.fsRfsoc, app.bw);
                    save([pwd '\phase_cal\' num2str(app.cur_ang) '.mat'], 'rawData')

                    if app.cur_ang == -(app.start_ang)
                        phase_scan_axis = -abs(app.start_ang):app.step_ang:abs(app.start_ang);
                        list = dir([pwd '\phase_cal\*.mat']);
                        for k=1:length(phase_scan_axis)
                            sig_temp = load([pwd '\phase_cal\' num2str(phase_scan_axis(k)), '.mat']);
                            sig = sig_temp.rawData;
                            meas_mat(:,:,k) = sig;
                        end
                        app.StartanglecalibrationsButton.Text = 'Press to start calibrations';
                        [steering_correction, ~, ~] = phase_pattern_generator(meas_mat,phase_scan_axis,app.scan_res,app.num_elements,app.fcAnt, app.c);
                        save('steering_correction.mat', 'steering_correction');
                        app.phase_cal = 0;
                        app.cur_ang = 0;
                    else
                        app.cur_ang = app.cur_ang + app.step_ang;
                    end
                end
                %% DAC BF
                if app.dacBFon
                    switch app.dacBF
                        case 'Random'
                            app.dacAngle = randi([-app.scan_bw/2,app.scan_bw/2],1);
                        case 'Scaning'
                            app.dacAngle = app.dacTestArray(1);
                            app.dacTestArray = [app.dacTestArray(2:end) app.dacTestArray(1)];
                        case 'Rescaning'
                            app.dacAngle = app.dacTestArray(1);
                            app.dacTestArray = [app.dacTestArray(end) app.dacTestArray(1:end-1)];
                        case 'Tracking'
                            app.dacAngle = estimated_angle(1);
                        case 'Retracking'
                            app.dacAngle = -estimated_angle(1);
                        case 'Tr_s'
                            app.dacAngle = round(estimated_angle(1)/10);
                        case 'Retr_s'
                            app.dacAngle = round(-estimated_angle(1)/10);
                        otherwise
                            app.dacAngle = app.AngleSpinner.Value;
                    end
                    beamforming = phased.SteeringVector('SensorArray',app.ula);
                    weight = beamforming(app.fcAnt, app.dacAngle);
                    %                     weight = weight/norm(weight)*2;
                    app.dphase = angle(weight).';
                    app.dphase = round(rad2deg(app.dphase), 2);
                    app.dphase = app.dphase + app.dphaseCorr;
                    % Find the indices where the absolute value of dphase exceeds phaseMax
                    indices = abs(app.dphase) > app.phaseMax;
                    app.dphase(indices) = -(app.dphase(indices) - min(max(app.dphase(indices), app.phaseMin), app.phaseMax));

                    commandsHandler(app, ['dphase ' strjoin(arrayfun(@num2str, app.dphase*100, 'UniformOutput', false), '/');]);
                end
                %% TCP/IP tx
                if not(isempty(app.commands))
                    oldComs = app.commands;
                    writeline(app.tcp_client, app.commands);
                    if string(oldComs) == string(app.commands)
                        app.commands = [];
                    end
                else
                    writeline(app.tcp_client, 'alive 1');
                end
                if app.debug
                    full_time = toc;
                    disp(['Full time ' num2str(full_time) ' s'])
                    disp('--------------------------------')
                end
                %                 end
            end
        end

        % Value changed function: VSACheckBox
        function VSACheckBoxValueChanged(app, event)
            app.vsa = app.VSACheckBox.Value;
        end

        % Value changed function: ChannelselectListBox
        function ChannelselectListBoxValueChanged(app, event)
            app.ch = str2double(app.ChannelselectListBox.Value);
        end

        % Value changed function: dataChanEditField
        function dataChanEditFieldValueChanged(app, event)
            app.dataChan = app.dataChanEditField.Value;
            commandsHandler(app, ['dataChan ' num2str(app.dataChanEditField.Value*8)]);
            app.reset_req = 1;
        end

        % Value changed function: CutterCheckBox
        function CutterCheckBoxValueChanged(app, event)
            app.cutter = app.CutterCheckBox.Value;
        end

        % Value changed function: BFtypeListBox
        function BFtypeListBoxValueChanged(app, event)
            app.bf = app.BFtypeListBox.Value;
        end

        % Selection changed function: SignalpriorityButtonGroup
        function SignalpriorityButtonGroupSelectionChanged(app, event)
            ang_num_txt  = app.SignalpriorityButtonGroup.SelectedObject.Text;
            switch ang_num_txt
                case 'Most Powerfull'
                    app.ang_num = 1;
                case 'Less Powerfull'
                    app.ang_num = 2;
            end
        end

        % Value changed function: CutoffsetEditField
        function CutoffsetEditFieldValueChanged(app, event)
            app.off = app.CutoffsetEditField.Value;
        end

        % Value changed function: MatlabPatternCheckBox
        function MatlabPatternCheckBoxValueChanged(app, event)
            app.MatlabPattern = app.MatlabPatternCheckBox.Value;
        end

        % Value changed function: GetPatternButton
        function GetPatternButtonValueChanged(app, event)
            plotResponse(app.ula,app.fc,app.c,...
                'AzimuthAngles',app.scan_axis,...
                'Unit','db',...
                'Weights',app.weights.');
            uistack(gcf,'top')
        end

        % Value changed function: ResetButton
        function ResetButtonValueChanged(app, event)
            app.reset_req = app.ResetButton.Value;
        end

        % Value changed function: c1CheckBox
        function c1CheckBoxValueChanged(app, event)
            app.c1 = app.c1CheckBox.Value;
        end

        % Value changed function: c2CheckBox
        function c2CheckBoxValueChanged(app, event)
            app.c2 = app.c2CheckBox.Value;
        end

        % Value changed function: RFSoCFcSpinner
        function RFSoCFcSpinnerValueChanged(app, event)
            app.fc = app.RFSoCFcSpinner.Value*1e6*app.adcMirror;
            commandsHandler(app, ['fc ' num2str(app.fc/1e6) '/' num2str(app.nyquistZone) '/' ...
                num2str(app.fc_d0/1e6) '/' num2str(app.nyquistZone_d0) '/' ...
                num2str(app.fc_d1/1e6) '/' num2str(app.nyquistZone_d1)]);
            app.part_reset_req = 1;
        end

        % Value changed function: RFSoCFsSpinner
        function RFSoCFsSpinnerValueChanged(app, event)
            app.fsRfsoc = app.RFSoCFsSpinner.Value*1e6;
            app.part_reset_req = 1;
        end

        % Value changed function: MaxSignalsSpinner
        function MaxSignalsSpinnerValueChanged(app, event)
            app.num = app.MaxSignalsSpinner.Value;
            app.part_reset_req = 1;
        end

        % Value changed function: DOAtypeListBox
        function DOAtypeListBoxValueChanged(app, event)
            app.doa = app.DOAtypeListBox.Value;
            app.part_reset_req = 1;
        end

        % Value changed function: AvgSpinner
        function AvgSpinnerValueChanged(app, event)
            app.avg_factor = app.AvgSpinner.Value;
            app.part_reset_req = 1;
        end

        % Value changed function: UpdRateEditField
        function UpdRateEditFieldValueChanged(app, event)
            app.updrate = app.UpdRateEditField.Value;
        end

        % Value changed function: DOAresolutionEditField
        function DOAresolutionEditFieldValueChanged(app, event)
            app.scan_res = app.DOAresolutionEditField.Value;
            app.part_reset_req = 1;
        end

        % Value changed function: DLFEditField
        function DLFEditFieldValueChanged2(app, event)
            app.diag = app.DLFEditField.Value;
        end

        % Value changed function: GetSpectrumButton
        function GetSpectrumButtonValueChanged(app, event)
            plotSpectrum(app.estimator)
            uistack(gcf,'top')
        end

        % Value changed function: SigBWSpinner
        function SigBWSpinnerValueChanged(app, event)
            app.bw = app.SigBWSpinner.Value*1e6;
        end

        % Button pushed function: LoadVSAsetupButton
        function LoadVSAsetupButtonPushed(app, event)
            [file, path] = uigetfile([pwd '.\Settings\*.setx']);
            app.setupFile = [path file];
            app.reset_req = 1;
        end

        % Value changed function: ScanBWEditField
        function ScanBWEditFieldValueChanged(app, event)
            app.scan_bw = app.ScanBWEditField.Value;
            app.part_reset_req = 1;
        end

        % Value changed function: BWEditField
        function BWEditFieldValueChanged(app, event)
            app.bwOff = app.BWEditField.Value;
        end

        % Callback function
        function fcGenSpinnerValueChanged(app, event)
            app.fcInt = app.fcGenSpinner.Value*1e6;
            %             app.fcIntSpinner.Value = app.fcGenSpinner.Value;
            genCtrl(app.gen_ip, app.gen_port, app.stateInt, app.powInt, app.fcInt, app.modInt);
        end

        % Callback function
        function gainGenSpinnerValueChanged(app, event)
            app.powInt = app.gainGenSpinner.Value;
            %             app.gainIntSpinner.Value = app.gainGenSpinner.Value;
            genCtrl(app.gen_ip, app.gen_port, app.stateInt, app.powInt, app.fcInt, app.modInt);
        end

        % Callback function
        function ModCheckBoxValueChanged(app, event)
            app.modInt = app.ModCheckBox.Value;
            genCtrl(app.gen_ip, app.gen_port, app.stateInt, app.powInt, app.fcInt, app.modInt);
        end

        % Callback function
        function PowerCheckBoxValueChanged(app, event)
            app.stateInt = app.PowerCheckBox.Value;
            genCtrl(app.gen_ip, app.gen_port, app.stateInt, app.powInt, app.fcInt, app.modInt);
        end

        % Value changed function: patternCorrCheckBox
        function patternCorrCheckBoxValueChanged(app, event)
            app.patternCorr = app.patternCorrCheckBox.Value;
        end

        % Value changed function: mis_angEditField
        function mis_angEditFieldValueChanged(app, event)
            app.mis_ang = app.mis_angEditField.Value;
        end

        % Value changed function: alg_scan_resEditField
        function alg_scan_resEditFieldValueChanged(app, event)
            app.alg_scan_res = app.alg_scan_resEditField.Value;
        end

        % Value changed function: gammaEditField
        function gammaEditFieldValueChanged(app, event)
            app.gamma = app.gammaEditField.Value;
        end

        % Value changed function: alphaEditField
        function alphaEditFieldValueChanged(app, event)
            app.alpha = app.alphaEditField.Value;
        end

        % Value changed function: iterEditField
        function iterEditFieldValueChanged(app, event)
            app.iter = app.iterEditField.Value;
        end

        % Value changed function: CustomCommandTextArea
        function CustomCommandTextAreaValueChanged(app, event)
            commandsHandler(app, string(app.CustomCommandTextArea.Value));
            disp(app.commands)
        end

        % Button pushed function: RecalibrateADCsButton
        function RecalibrateADCsButtonPushed(app, event)
            commandsHandler(app, ['cal ' num2str(app.bw/1e6)]);
        end

        % Value changed function: dataStreamCheckBox
        function dataStreamCheckBoxValueChanged(app, event)
            app.dataStream = app.dataStreamCheckBox.Value;
            commandsHandler(app, ['dataStream ' num2str(app.dataStream)]);
        end

        % Value changed function: EvenNyquistZoneCheckBox
        function EvenNyquistZoneCheckBoxValueChanged(app, event)
            app.nyquistZone = app.EvenNyquistZoneCheckBox.Value + 1;
            commandsHandler(app, ['fc ' num2str(app.fc/1e6) '/' num2str(app.nyquistZone) '/' ...
                num2str(app.fc_d0/1e6) '/' num2str(app.nyquistZone_d0) '/' ...
                num2str(app.fc_d1/1e6) '/' num2str(app.nyquistZone_d1)]);

        end

        % Value changed function: DebugCheckBox_2
        function DebugCheckBox_2ValueChanged(app, event)
            app.debug = app.DebugCheckBox_2.Value;
        end

        % Value changed function: PlotCheckBox
        function PlotCheckBoxValueChanged(app, event)
            app.plotUpd = app.PlotCheckBox.Value;
        end

        % Value changed function: NumberofsavedfilesEditField
        function NumberofsavedfilesEditFieldValueChanged(app, event)
            app.numFiles = app.NumberofsavedfilesEditField.Value + 1;
        end

        % Button pushed function: SaveButton
        function SaveButtonPushed(app, event)
            app.saveFlg = 1;
            [baseFileName, folder] = uiputfile([pwd ['.\Signals\'  num2str(app.numFiles - 1) '_RawSavesFromRfsoc.mat']]);
            app.saveName = fullfile(folder, baseFileName);
        end

        % Value changed function: SYNCDropDown
        function SYNCDropDownValueChanged(app, event)
            app.da = app.SYNCDropDown.Value;

        end

        % Value changed function: RFSoCFcSpinner_2
        function RFSoCFcSpinner_2ValueChanged(app, event)
            app.fc_d0 = app.RFSoCFcSpinner_2.Value*1e6*app.dacMirror;
            commandsHandler(app, ['fc ' num2str(app.fc/1e6) '/' num2str(app.nyquistZone) '/' ...
                num2str(app.fc_d0/1e6) '/' num2str(app.nyquistZone_d0) '/' ...
                num2str(app.fc_d0/1e6) '/' num2str(app.nyquistZone_d0)]);

        end

        % Callback function
        function RFSoCFcSpinner_3ValueChanged(app, event)
            %             app.fc_d1 = app.AntennaFcSpinner.Value*1e6;
            %             commandsHandler(app, ['fc ' num2str(app.fc/1e6) '/' num2str(app.nyquistZone) '/' ...
            %                 num2str(app.fc_d0/1e6) '/' num2str(app.nyquistZone_d0) '/' ...
            %                 num2str(app.fc_d1/1e6) '/' num2str(app.nyquistZone_d1)]);

        end

        % Value changed function: AngleSpinner
        function AngleSpinnerValueChanged(app, event)
            app.dacAngle = app.AngleSpinner.Value;

        end

        % Value changed function: EvenNyquistZoneCheckBox_2
        function EvenNyquistZoneCheckBox_2ValueChanged(app, event)
            app.nyquistZone_d0 = app.EvenNyquistZoneCheckBox_2.Value + 1;
            commandsHandler(app, ['fc ' num2str(app.fc/1e6) '/' num2str(app.nyquistZone) '/' ...
                num2str(app.fc_d0/1e6) '/' num2str(app.nyquistZone_d0) '/' ...
                num2str(app.fc_d1/1e6) '/' num2str(app.nyquistZone_d1)]);

        end

        % Callback function
        function EvenNyquistZoneCheckBox_3ValueChanged(app, event)
            app.nyquistZone_d1 = app.EvenNyquistZoneCheckBox_3.Value + 1;
            commandsHandler(app, ['fc ' num2str(app.fc/1e6) '/' num2str(app.nyquistZone) '/' ...
                num2str(app.fc_d0/1e6) '/' num2str(app.nyquistZone_d0) '/' ...
                num2str(app.fc_d1/1e6) '/' num2str(app.nyquistZone_d1)]);

        end

        % Callback function
        function PhaseSpinner_2ValueChanged(app, event)
            app.dphase(3) = app.PhaseSpinner_2.Value;
            commandsHandler(app, ['dphase ' strjoin(arrayfun(@num2str, app.dphase, 'UniformOutput', false), '/');]);

        end

        % Callback function
        function LoadSignalButtonPushed(app, event)
            [file, path] = uigetfile([pwd '.\Signals\*.mat']);
            filename = [path file];
            sigInt16 = sigPrepare(filename, app.fsOrig, app.fsDAC, app.bwDac);
            commandsHandler(app, ['dac0 ' strjoin(arrayfun(@num2str, sigInt16, 'UniformOutput', false), '/');]);
            app.part_reset_req = 1;
        end

        % Callback function
        function LoadSignalButton_2Pushed(app, event)
            [file, path] = uigetfile([pwd '.\Signals\*.mat']);
            filename = [path file];
            sigInt16 = sigPrepare(filename, app.fsOrig, app.fsDAC, app.bwDac);
            commandsHandler(app, ['dac1 ' strjoin(arrayfun(@num2str, sigInt16, 'UniformOutput', false), '/');]);
            app.part_reset_req = 1;
        end

        % Callback function
        function PowerCheckBox_2ValueChanged(app, event)
            app.dacPow(1) = app.PowerCheckBox_2.Value;
            commandsHandler(app, ['dacPow ' strjoin(arrayfun(@num2str, app.dacPow, 'UniformOutput', false), '/');]);

        end

        % Callback function
        function PowerCheckBox_3ValueChanged(app, event)
            app.dacPow(3) = app.PowerCheckBox_3.Value;
            commandsHandler(app, ['dacPow ' strjoin(arrayfun(@num2str, app.dacPow, 'UniformOutput', false), '/');]);

        end

        % Callback function
        function ResampleCheckBoxValueChanged(app, event)
            app.resmp = app.ResampleCheckBox.Value;
            if app.resmp
                app.fsOrig = app.fsOrig;
            else
                app.fsOrig = app.fsDAC;
            end
        end

        % Callback function
        function FilterCheckBoxValueChanged(app, event)
            app.dacFilt = app.FilterCheckBox.Value;
            if app.dacFilt
                app.bwDac = app.bwDac;
            else
                app.bwDac = app.fsDAC - 1e6;
            end
        end

        % Callback function
        function FiltBWEditFieldValueChanged(app, event)
            app.bwDac = app.FiltBWEditField.Value*1e6;
        end

        % Callback function
        function OrigFSEditFieldValueChanged(app, event)
            app.fsOrig = app.OrigFSEditField.Value*1e6;
        end

        % Button pushed function: StartanglecalibrationsButton
        function StartanglecalibrationsButtonPushed(app, event)
            if app.phase_cal
                app.phase_cal = 1;
            else
                if exist('phase_cal', 'dir')
                    rmdir('phase_cal', 's')
                end
                mkdir('phase_cal')
                app.cur_ang = app.start_ang;
                %                 [baseFileName, folder] = uiputfile([pwd 'steering_correction_' num2str(app.start_ang) '_' num2str(app.step_ang) 'deg_res.mat']);
                %                 app.saveName = fullfile(folder, baseFileName);
                app.phase_cal = 1;
            end
            uiresume
            app.phase_cal_butt = 1;

        end

        % Value changed function: StepangEditField
        function StepangEditFieldValueChanged(app, event)
            app.step_ang = app.StepangEditField.Value;
        end

        % Value changed function: StarrangEditField
        function StarrangEditFieldValueChanged(app, event)
            app.start_ang = app.StarrangEditField.Value;
        end

        % Button pushed function: ArduinoGUIButton
        function ArduinoGUIButtonPushed(app, event)
            % arduino_prog();
            app.rxBoardControl_app = rxBoardControl;
            app.ArduinoGUIButton.BackgroundColor = 'g';
        end

        % Value changed function: MirrorCheckBox
        function MirrorCheckBoxValueChanged(app, event)
            if app.MirrorCheckBox.Value
                app.adcMirror = -1;
            else
                app.adcMirror = 1;
            end
            app.fc = app.RFSoCFcSpinner.Value*1e6*app.adcMirror;
            commandsHandler(app, ['fc ' num2str(app.fc/1e6) '/' num2str(app.nyquistZone) '/' ...
                num2str(app.fc_d0/1e6) '/' num2str(app.nyquistZone_d0) '/' ...
                num2str(app.fc_d0/1e6) '/' num2str(app.nyquistZone_d0)]);
        end

        % Button pushed function: SyncButton
        function SyncButtonPushed(app, event)
            commandsHandler(app, ['sync ' num2str(1)]);

        end

        % Value changed function: AntennaFcSpinner
        function AntennaFcSpinnerValueChanged(app, event)
            app.fcAnt = app.AntennaFcSpinner.Value*1e6;
            app.part_reset_req = 1;
        end

        % Value changed function: DacSignalDropDown
        function DacSignalDropDownValueChanged(app, event)
            value = app.DacSignalDropDown.Value;
            switch value
                case 'Off'
                    app.dacSignalType = 0;
                case 'CW'
                    app.dacSignalType = 1;
                case 'SAW'
                    app.dacSignalType = 2;
                case 'Chirp'
                    app.dacSignalType = 3;
                case 'OFDM'
                    app.dacSignalType = 4;
            end
            commandsHandler(app, ['source ' num2str(app.dacSignalType) '/' num2str(app.dacSR) '/' ...
                num2str(app.dacFc) '/' num2str(app.dacFe) '/' num2str(app.dacAmp)]);

        end

        % Value changed function: FcEditField
        function FcEditFieldValueChanged(app, event)
            app.dacFc = app.FcEditField.Value;
            commandsHandler(app, ['source ' num2str(app.dacSignalType) '/' num2str(app.dacSR) '/' ...
                num2str(app.dacFc) '/' num2str(app.dacFe) '/' num2str(app.dacAmp)]);

        end

        % Callback function
        function SREditFieldValueChanged(app, event)
            app.dacSR = app.SREditField.Value;
            commandsHandler(app, ['source ' num2str(app.dacSignalType) '/' num2str(app.dacSR) '/' ...
                num2str(app.dacFc) '/' num2str(app.dacFe) '/' num2str(app.dacAmp)]);

        end

        % Value changed function: FeEditField
        function FeEditFieldValueChanged(app, event)
            app.dacFe = app.FeEditField.Value;
            commandsHandler(app, ['source ' num2str(app.dacSignalType) '/' num2str(app.dacSR) '/' ...
                num2str(app.dacFc) '/' num2str(app.dacFe) '/' num2str(app.dacAmp)]);

        end

        % Value changed function: MirrorCheckBox_2
        function MirrorCheckBox_2ValueChanged(app, event)
            if app.MirrorCheckBox_2.Value
                app.dacMirror = -1;
            else
                app.dacMirror = 1;
            end
            app.fc_d0 = app.RFSoCFcSpinner_2.Value*1e6*app.dacMirror;
            app.fc_d1 = app.RFSoCFcSpinner_2.Value*1e6*app.dacMirror;
            commandsHandler(app, ['fc ' num2str(app.fc/1e6) '/' num2str(app.nyquistZone) '/' ...
                num2str(app.fc_d0/1e6) '/' num2str(app.nyquistZone_d0) '/' ...
                num2str(app.fc_d0/1e6) '/' num2str(app.nyquistZone_d0)]);

        end

        % Value changed function: DACBFmodeListBox
        function DACBFmodeListBoxValueChanged(app, event)
            app.dacBF = app.DACBFmodeListBox.Value;
            if string(app.dacBF) == 'Off'
                app.dacBFon = 0;
            else
                app.dacBFon = 1;
            end
        end

        % Callback function
        function SendButtonPushed(app, event)
            control
            commandsHandler(app, ['source ' num2str(app.dacSignalType) '/' num2str(app.dacSR) '/' ...
                num2str(app.dacFc) '/' num2str(app.dacFe) '/' num2str(app.dacAmp)]);
        end

        % Value changed function: ChannelcontrolDropDown
        function ChannelcontrolDropDownValueChanged(app, event)
            app.manualControlState = app.ChannelcontrolDropDown.Value;
            switch app.manualControlState
                case "DAC gain"
                    app.Ch1Spinner.Limits = [0, 199];
                    app.Ch2Spinner.Limits = [0, 199];
                    app.Ch3Spinner.Limits = [0, 199];
                    app.Ch4Spinner.Limits = [0, 199];
                    app.Ch1Spinner.Value = app.dacGain(1);
                    app.Ch2Spinner.Value = app.dacGain(2);
                    app.Ch3Spinner.Value = app.dacGain(3);
                    app.Ch4Spinner.Value = app.dacGain(4);
                case "DAC phase"
                    app.Ch1Spinner.Limits = [-179, 179];
                    app.Ch2Spinner.Limits = [-179, 179];
                    app.Ch3Spinner.Limits = [-179, 179];
                    app.Ch4Spinner.Limits = [-179, 179];
                    app.Ch1Spinner.Value = app.dphase(1);
                    app.Ch2Spinner.Value = app.dphase(2);
                    app.Ch3Spinner.Value = app.dphase(3);
                    app.Ch4Spinner.Value = app.dphase(4);
                case "ADC gain"
                    app.Ch1Spinner.Limits = [1, 199];
                    app.Ch2Spinner.Limits = [1, 199];
                    app.Ch3Spinner.Limits = [1, 199];
                    app.Ch4Spinner.Limits = [1, 199];
                    app.Ch1Spinner.Value = app.adcGain(1);
                    app.Ch2Spinner.Value = app.adcGain(2);
                    app.Ch3Spinner.Value = app.adcGain(3);
                    app.Ch4Spinner.Value = app.adcGain(4);
                case "ADC phase"
                    app.Ch1Spinner.Limits = [-179, 179];
                    app.Ch2Spinner.Limits = [-179, 179];
                    app.Ch3Spinner.Limits = [-179, 179];
                    app.Ch4Spinner.Limits = [-179, 179];
                    app.Ch1Spinner.Value = app.phase(1);
                    app.Ch2Spinner.Value = app.phase(2);
                    app.Ch3Spinner.Value = app.phase(3);
                    app.Ch4Spinner.Value = app.phase(4);
            end
        end

        % Value changed function: Ch1Spinner
        function Ch1SpinnerValueChanged(app, event)
            switch app.manualControlState
                case "DAC gain"
                    app.dacGain(1) = app.Ch1Spinner.Value;
                    commandsHandler(app, ['dgain ' strjoin(arrayfun(@num2str, app.dacGain, 'UniformOutput', false), '/');]);
                case "DAC phase"
                    app.dphaseCorr(1) = app.Ch1Spinner.Value;
                    commandsHandler(app, ['dphase ' strjoin(arrayfun(@num2str, app.dphaseCorr*100, 'UniformOutput', false), '/');]);
                case "ADC gain"
                    app.adcGain(1) = app.Ch1Spinner.Value;
                    commandsHandler(app, ['again ' strjoin(arrayfun(@num2str, app.adcGain, 'UniformOutput', false), '/');]);
                case "ADC phase"
                    app.phase(1) = app.Ch1Spinner.Value;
                    commandsHandler(app, ['phase ' strjoin(arrayfun(@num2str, app.phase*100, 'UniformOutput', false), '/');]);
            end
        end

        % Value changed function: Ch2Spinner
        function Ch2SpinnerValueChanged(app, event)
            switch app.manualControlState
                case "DAC gain"
                    app.dacGain(2) = app.Ch2Spinner.Value;
                    commandsHandler(app, ['dgain ' strjoin(arrayfun(@num2str, app.dacGain, 'UniformOutput', false), '/');]);
                case "DAC phase"
                    app.dphaseCorr(2) = app.Ch2Spinner.Value;
                    commandsHandler(app, ['dphase ' strjoin(arrayfun(@num2str, app.dphaseCorr*100, 'UniformOutput', false), '/');]);
                case "ADC gain"
                    app.adcGain(2) = app.Ch2Spinner.Value;
                    commandsHandler(app, ['again ' strjoin(arrayfun(@num2str, app.adcGain, 'UniformOutput', false), '/');]);
                case "ADC phase"
                    app.phase(2) = app.Ch2Spinner.Value;
                    commandsHandler(app, ['phase ' strjoin(arrayfun(@num2str, app.phase*100, 'UniformOutput', false), '/');]);
            end
        end

        % Value changed function: Ch3Spinner
        function Ch3SpinnerValueChanged(app, event)
            switch app.manualControlState
                case "DAC gain"
                    app.dacGain(3) = app.Ch3Spinner.Value;
                    commandsHandler(app, ['dgain ' strjoin(arrayfun(@num2str, app.dacGain, 'UniformOutput', false), '/');]);
                case "DAC phase"
                    app.dphaseCorr(3) = app.Ch3Spinner.Value;
                    commandsHandler(app, ['dphase ' strjoin(arrayfun(@num2str, app.dphaseCorr*100, 'UniformOutput', false), '/');]);
                case "ADC gain"
                    app.adcGain(3) = app.Ch3Spinner.Value;
                    commandsHandler(app, ['again ' strjoin(arrayfun(@num2str, app.adcGain, 'UniformOutput', false), '/');]);
                case "ADC phase"
                    app.phase(3) = app.Ch3Spinner.Value;
                    commandsHandler(app, ['phase ' strjoin(arrayfun(@num2str, app.phase*100, 'UniformOutput', false), '/');]);
            end
        end

        % Value changed function: Ch4Spinner
        function Ch4SpinnerValueChanged(app, event)
            switch app.manualControlState
                case "DAC gain"
                    app.dacGain(4) = app.Ch4Spinner.Value;
                    commandsHandler(app, ['dgain ' strjoin(arrayfun(@num2str, app.dacGain, 'UniformOutput', false), '/');]);
                case "DAC phase"
                    app.dphaseCorr(4) = app.Ch4Spinner.Value;
                    commandsHandler(app, ['dphase ' strjoin(arrayfun(@num2str, app.dphaseCorr*100, 'UniformOutput', false), '/');]);
                case "ADC gain"
                    app.adcGain(4) = app.Ch4Spinner.Value;
                    commandsHandler(app, ['again ' strjoin(arrayfun(@num2str, app.adcGain, 'UniformOutput', false), '/');]);
                case "ADC phase"
                    app.phase(4) = app.Ch4Spinner.Value;
                    commandsHandler(app, ['phase ' strjoin(arrayfun(@num2str, app.phase*100, 'UniformOutput', false), '/');]);
            end
        end

        % Value changed function: DevicecontrolDropDown
        function DevicecontrolDropDownValueChanged(app, event)
            app.currentDev = string(app.DevicecontrolDropDown.Items(app.DevicecontrolDropDown.Value));
            try
                app.currentDevIP = regexp(app.visaDevList.ResourceName(app.DevicecontrolDropDown.Value), '\d+\.\d+\.\d+\.\d+', 'match', 'once');
            catch
                disp(app.lotx.Model)
            end
            switch app.currentDev
                case app.lorx.Model
                    app.lorx.IP = app.currentDevIP;
                    app.PowerCheckBox.Value = app.lorx.State;
                    app.ModulationCheckBox.Value = app.lorx.Mod;
                    app.FrequencySpinner.Value = app.lorx.Fc;
                    app.AmplitudeSpinner.Value = app.lorx.Power;
                case app.lotx.Model
                    app.currentDevIP = app.lotx.IP;
                    app.PowerCheckBox.Value = app.lotx.State;
                    app.ModulationCheckBox.Value = app.lotx.Mod;
                    app.FrequencySpinner.Value = app.lotx.Fc;
                    app.AmplitudeSpinner.Value = app.lotx.Power;
                case "Custom"
                    app.currentDevIP = app.IPEditField.Value;
                    app.PowerCheckBox.Value = 0;
                    app.ModulationCheckBox.Value = 0;
                    app.FrequencySpinner.Value = 100;
                    app.AmplitudeSpinner.Value = -100;
                otherwise
                    app.PowerCheckBox.Value = 0;
                    app.ModulationCheckBox.Value = 0;
                    app.FrequencySpinner.Value = 100;
                    app.AmplitudeSpinner.Value = -100;
            end
        end

        % Value changed function: FrequencySpinner
        function FrequencySpinnerValueChanged(app, event)
            genCtrl(app.currentDevIP, app.gen_port, app.PowerCheckBox.Value, app.AmplitudeSpinner.Value, app.FrequencySpinner.Value*1e6, app.ModulationCheckBox.Value);
        end

        % Value changed function: AmplitudeSpinner
        function AmplitudeSpinnerValueChanged(app, event)
            genCtrl(app.currentDevIP, app.gen_port, app.PowerCheckBox.Value, app.AmplitudeSpinner.Value, app.FrequencySpinner.Value*1e6, app.ModulationCheckBox.Value);
        end

        % Value changed function: PowerCheckBox
        function PowerCheckBoxValueChanged2(app, event)
            genCtrl(app.currentDevIP, app.gen_port, app.PowerCheckBox.Value, app.AmplitudeSpinner.Value, app.FrequencySpinner.Value*1e6, app.ModulationCheckBox.Value);
        end

        % Value changed function: ModulationCheckBox
        function ModulationCheckBoxValueChanged(app, event)
            genCtrl(app.currentDevIP, app.gen_port, app.PowerCheckBox.Value, app.AmplitudeSpinner.Value, app.FrequencySpinner.Value*1e6, app.ModulationCheckBox.Value);
        end

        % Value changed function: IPEditField
        function IPEditFieldValueChanged(app, event)
            %             app.currentDevIP = app.IPEditField.Value;

        end

        % Button pushed function: PrintphasemissmatchButton
        function PrintphasemissmatchButtonPushed(app, event)
            PAcheck(app, app.rawData);
        end

        % Value changed function: MirrorCheckBox_3
        function MirrorCheckBox_3ValueChanged(app, event)
            app.plotMirror = app.MirrorCheckBox_3.Value;
        end

        % Drop down opening function: DevicecontrolDropDown
        function DevicecontrolDropDownOpening(app, event)
            try
                app.DevicecontrolDropDownLabel.Text = 'Loading...';
                app.visaDevList = visadevlist;
            catch
                app.visaDevList.Model = [];
            end
            app.DevicecontrolDropDownLabel.Text = 'Device control';
            app.DevicecontrolDropDown.Items = [app.visaDevList.Model; "E8267D"; "Custom"];
        end

        % Button pushed function: DCLeakageAutocalStartButton
        function DCLeakageAutocalStartButtonPushed(app, event)
            app.DCLeakageAutocalStartButton.BackgroundColor = 'r';
            if isempty(app.rxBoardControl_app)
                uialert(app.RFSoCBeamformerUIFigure,'Set up arduino connection first','Autocal Error');
            else
                app.autocal = 1;
                if isempty(app.autocal_registers)
                    app.autocal_registers = app.rxBoardControl_app.registers;
                else
                    app.rxBoardControl_app.registers = app.autocal_registers;
                    app.rxBoardControl_app.updateFields;
                    app.rxBoardControl_app.updateRXboard;
                end
                app.autocal_min_array = inf(1,app.num_elements);
            end
        end

        % Close request function: RFSoCBeamformerUIFigure
        function RFSoCBeamformerUIFigureCloseRequest(app, event)
            delete(app)
        end

        % Button pushed function: AmplitudeAutocalStartButton
        function RXAmplitudeAutocalStartButtonPushed(app, event)
            if app.autocal_rx_amp
                app.autocal_rx_amp = 0;
            else
                app.AmplitudeAutocalStartButton.BackgroundColor = 'r';
                app.adcGain = [199,199,199,199];
                commandsHandler(app, ['again ' strjoin(arrayfun(@num2str, app.adcGain, 'UniformOutput', false), '/');]);
                writeline(app.tcp_client, app.commands);
                app.commands = [];
                app.autocal_rx_amp = 1;
            end

        end

        % Button pushed function: PhaseAutocalStartButton
        function RXPhaseAutocalStartButtonPushed(app, event)
            if app.autocal_rx_phase
                app.autocal_rx_phase = 0;
            else
                app.PhaseAutocalStartButton.BackgroundColor = 'r';
                app.phase = [0,0,0,0];
                commandsHandler(app, ['phase ' strjoin(arrayfun(@num2str, app.phase, 'UniformOutput', false), '/');]);
                writeline(app.tcp_client, app.commands);
                app.commands = [];
                app.autocal_rx_phase = 1;
            end
        end

        % Button pushed function: AmplitudeAutocalStartButton_2
        function TXAmplitudeAutocalStartButtonPushed(app, event)
            if app.autocal_tx_amp
                app.autocal_tx_amp = 0;
            else
                app.AmplitudeAutocalStartButton_2.BackgroundColor = 'r';
                app.autocal_tx_amp = 1;
            end
        end

        % Button pushed function: PhaseAutocalStartButton_2
        function TXPhaseAutocalStartButtonPushed(app, event)
            if app.autocal_tx_phase
                app.autocal_tx_phase = 0;
            else
                app.PhaseAutocalStartButton_2.BackgroundColor = 'r';
                app.dphaseCorr = [0,0,0,0];
                app.dphase = [0,0,0,0];
                % app.dacActiveCh = [1,1,0,0];
                % app.dacGain = app.dgainCorr*app.dacActiveCh;   %% Ch1 + Ch2 on                  
                % commandsHandler(app, ['dgain ' strjoin(arrayfun(@num2str, app.dacGain, 'UniformOutput', false), '/');]);
                % commandsHandler(app, ['dphase ' strjoin(arrayfun(@num2str, app.dphase*100, 'UniformOutput', false), '/');]);
                % writeline(app.tcp_client, app.commands);
                % app.commands = [];
                app.autocal_tx_phase = 1;
            end
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.RFSoCBeamformerUIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {949, 949};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {234, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create RFSoCBeamformerUIFigure and hide until all components are created
            app.RFSoCBeamformerUIFigure = uifigure('Visible', 'off');
            app.RFSoCBeamformerUIFigure.AutoResizeChildren = 'off';
            app.RFSoCBeamformerUIFigure.Position = [100 100 835 949];
            app.RFSoCBeamformerUIFigure.Name = 'RFSoC Beamformer';
            app.RFSoCBeamformerUIFigure.CloseRequestFcn = createCallbackFcn(app, @RFSoCBeamformerUIFigureCloseRequest, true);
            app.RFSoCBeamformerUIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);
            app.RFSoCBeamformerUIFigure.Scrollable = 'on';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.RFSoCBeamformerUIFigure);
            app.GridLayout.ColumnWidth = {234, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create ResetButton
            app.ResetButton = uibutton(app.LeftPanel, 'state');
            app.ResetButton.ValueChangedFcn = createCallbackFcn(app, @ResetButtonValueChanged, true);
            app.ResetButton.Text = 'Reset';
            app.ResetButton.Position = [133 3 100 22];

            % Create TabGroup
            app.TabGroup = uitabgroup(app.LeftPanel);
            app.TabGroup.Position = [9 209 219 720];

            % Create MainTab
            app.MainTab = uitab(app.TabGroup);
            app.MainTab.Title = 'Main';

            % Create DOAresolutionEditField_3Label
            app.DOAresolutionEditField_3Label = uilabel(app.MainTab);
            app.DOAresolutionEditField_3Label.HorizontalAlignment = 'right';
            app.DOAresolutionEditField_3Label.Position = [23 657 58 28];
            app.DOAresolutionEditField_3Label.Text = {'DOA'; 'resolution'};

            % Create DOAresolutionEditField
            app.DOAresolutionEditField = uieditfield(app.MainTab, 'numeric');
            app.DOAresolutionEditField.Limits = [0.0001 Inf];
            app.DOAresolutionEditField.ValueChangedFcn = createCallbackFcn(app, @DOAresolutionEditFieldValueChanged, true);
            app.DOAresolutionEditField.Position = [96 663 77 22];
            app.DOAresolutionEditField.Value = 1;

            % Create DOAtypeListBoxLabel
            app.DOAtypeListBoxLabel = uilabel(app.MainTab);
            app.DOAtypeListBoxLabel.HorizontalAlignment = 'right';
            app.DOAtypeListBoxLabel.Position = [-9 587 79 43];
            app.DOAtypeListBoxLabel.Text = {'DOA'; 'type'};

            % Create DOAtypeListBox
            app.DOAtypeListBox = uilistbox(app.MainTab);
            app.DOAtypeListBox.Items = {'MVDR', 'MVDRman', 'MVDRman_corr', 'MUSIC', 'Beamscan', 'MUSICR', 'ESPRITE', 'ESPRITEBS', 'WSFR'};
            app.DOAtypeListBox.ValueChangedFcn = createCallbackFcn(app, @DOAtypeListBoxValueChanged, true);
            app.DOAtypeListBox.Position = [74 458 113 174];
            app.DOAtypeListBox.Value = 'MVDR';

            % Create BFtypeListBoxLabel
            app.BFtypeListBoxLabel = uilabel(app.MainTab);
            app.BFtypeListBoxLabel.HorizontalAlignment = 'right';
            app.BFtypeListBoxLabel.Position = [-8 413 79 43];
            app.BFtypeListBoxLabel.Text = {'BF'; 'type'};

            % Create BFtypeListBox
            app.BFtypeListBox = uilistbox(app.MainTab);
            app.BFtypeListBox.Items = {'Without', 'Steering', 'MVDR', 'DMR', 'PC', 'PC_corr', 'LCMV', 'RVL', 'RAB PC', 'DL MVDR', 'DL ITER MVDR', 'QCB'};
            app.BFtypeListBox.ValueChangedFcn = createCallbackFcn(app, @BFtypeListBoxValueChanged, true);
            app.BFtypeListBox.Position = [75 225 112 233];
            app.BFtypeListBox.Value = 'Steering';

            % Create AngleSpinnerLabel
            app.AngleSpinnerLabel = uilabel(app.MainTab);
            app.AngleSpinnerLabel.HorizontalAlignment = 'right';
            app.AngleSpinnerLabel.Position = [39 179 36 22];
            app.AngleSpinnerLabel.Text = 'Angle';

            % Create AngleSpinner
            app.AngleSpinner = uispinner(app.MainTab);
            app.AngleSpinner.Limits = [-90 90];
            app.AngleSpinner.ValueChangedFcn = createCallbackFcn(app, @AngleSpinnerValueChanged, true);
            app.AngleSpinner.Position = [90 179 77 22];

            % Create DACBFmodeListBoxLabel
            app.DACBFmodeListBoxLabel = uilabel(app.MainTab);
            app.DACBFmodeListBoxLabel.HorizontalAlignment = 'right';
            app.DACBFmodeListBoxLabel.Position = [10 146 54 27];
            app.DACBFmodeListBoxLabel.Text = {'DAC'; 'BF mode'};

            % Create DACBFmodeListBox
            app.DACBFmodeListBox = uilistbox(app.MainTab);
            app.DACBFmodeListBox.Items = {'GUI', 'Random', 'Scaning', 'Rescaning', 'Tracking', 'Retracking', 'Tr_s', 'Retr_s', 'Off'};
            app.DACBFmodeListBox.ValueChangedFcn = createCallbackFcn(app, @DACBFmodeListBoxValueChanged, true);
            app.DACBFmodeListBox.Position = [80 1 89 172];
            app.DACBFmodeListBox.Value = 'Off';

            % Create RXLabel
            app.RXLabel = uilabel(app.MainTab);
            app.RXLabel.WordWrap = 'on';
            app.RXLabel.FontSize = 16;
            app.RXLabel.FontWeight = 'bold';
            app.RXLabel.Position = [94 637 25 22];
            app.RXLabel.Text = 'RX';

            % Create TXLabel
            app.TXLabel = uilabel(app.MainTab);
            app.TXLabel.FontSize = 16;
            app.TXLabel.FontWeight = 'bold';
            app.TXLabel.Position = [94 201 26 22];
            app.TXLabel.Text = 'TX';

            % Create SystemTab
            app.SystemTab = uitab(app.TabGroup);
            app.SystemTab.Title = 'System';

            % Create RFSoCFcSpinnerLabel
            app.RFSoCFcSpinnerLabel = uilabel(app.SystemTab);
            app.RFSoCFcSpinnerLabel.HorizontalAlignment = 'right';
            app.RFSoCFcSpinnerLabel.Position = [17 605 44 27];
            app.RFSoCFcSpinnerLabel.Text = {'RFSoC'; 'Fc'};

            % Create RFSoCFcSpinner
            app.RFSoCFcSpinner = uispinner(app.SystemTab);
            app.RFSoCFcSpinner.Limits = [1 10000];
            app.RFSoCFcSpinner.ValueChangedFcn = createCallbackFcn(app, @RFSoCFcSpinnerValueChanged, true);
            app.RFSoCFcSpinner.Position = [76 610 77 22];
            app.RFSoCFcSpinner.Value = 1000;

            % Create RFSoCFsSpinnerLabel
            app.RFSoCFsSpinnerLabel = uilabel(app.SystemTab);
            app.RFSoCFsSpinnerLabel.HorizontalAlignment = 'right';
            app.RFSoCFsSpinnerLabel.Position = [17 572 44 27];
            app.RFSoCFsSpinnerLabel.Text = {'RFSoC'; 'Fs'};

            % Create RFSoCFsSpinner
            app.RFSoCFsSpinner = uispinner(app.SystemTab);
            app.RFSoCFsSpinner.Limits = [1 500];
            app.RFSoCFsSpinner.ValueDisplayFormat = '%.0f';
            app.RFSoCFsSpinner.ValueChangedFcn = createCallbackFcn(app, @RFSoCFsSpinnerValueChanged, true);
            app.RFSoCFsSpinner.Position = [76 577 77 22];
            app.RFSoCFsSpinner.Value = 250;

            % Create MaxSignalsSpinnerLabel
            app.MaxSignalsSpinnerLabel = uilabel(app.SystemTab);
            app.MaxSignalsSpinnerLabel.HorizontalAlignment = 'right';
            app.MaxSignalsSpinnerLabel.Position = [48 49 71 22];
            app.MaxSignalsSpinnerLabel.Text = 'Max Signals';

            % Create MaxSignalsSpinner
            app.MaxSignalsSpinner = uispinner(app.SystemTab);
            app.MaxSignalsSpinner.Limits = [1 5];
            app.MaxSignalsSpinner.ValueDisplayFormat = '%.0f';
            app.MaxSignalsSpinner.ValueChangedFcn = createCallbackFcn(app, @MaxSignalsSpinnerValueChanged, true);
            app.MaxSignalsSpinner.Position = [134 49 45 22];
            app.MaxSignalsSpinner.Value = 1;

            % Create SigBWSpinnerLabel
            app.SigBWSpinnerLabel = uilabel(app.SystemTab);
            app.SigBWSpinnerLabel.HorizontalAlignment = 'right';
            app.SigBWSpinnerLabel.Position = [36 539 25 28];
            app.SigBWSpinnerLabel.Text = {'Sig'; 'BW'};

            % Create SigBWSpinner
            app.SigBWSpinner = uispinner(app.SystemTab);
            app.SigBWSpinner.Limits = [1 500];
            app.SigBWSpinner.ValueDisplayFormat = '%.0f';
            app.SigBWSpinner.ValueChangedFcn = createCallbackFcn(app, @SigBWSpinnerValueChanged, true);
            app.SigBWSpinner.Position = [76 545 77 22];
            app.SigBWSpinner.Value = 249;

            % Create LoadVSAsetupButton
            app.LoadVSAsetupButton = uibutton(app.SystemTab, 'push');
            app.LoadVSAsetupButton.ButtonPushedFcn = createCallbackFcn(app, @LoadVSAsetupButtonPushed, true);
            app.LoadVSAsetupButton.Position = [114 16 102 22];
            app.LoadVSAsetupButton.Text = 'Load VSA setup';

            % Create ScanBWEditFieldLabel
            app.ScanBWEditFieldLabel = uilabel(app.SystemTab);
            app.ScanBWEditFieldLabel.HorizontalAlignment = 'right';
            app.ScanBWEditFieldLabel.Position = [11 16 33 28];
            app.ScanBWEditFieldLabel.Text = {'Scan'; 'BW'};

            % Create ScanBWEditField
            app.ScanBWEditField = uieditfield(app.SystemTab, 'numeric');
            app.ScanBWEditField.Limits = [2 180];
            app.ScanBWEditField.RoundFractionalValues = 'on';
            app.ScanBWEditField.ValueChangedFcn = createCallbackFcn(app, @ScanBWEditFieldValueChanged, true);
            app.ScanBWEditField.Position = [59 22 44 22];
            app.ScanBWEditField.Value = 180;

            % Create RecalibrateADCsButton
            app.RecalibrateADCsButton = uibutton(app.SystemTab, 'push');
            app.RecalibrateADCsButton.ButtonPushedFcn = createCallbackFcn(app, @RecalibrateADCsButtonPushed, true);
            app.RecalibrateADCsButton.Position = [67 452 100 35];
            app.RecalibrateADCsButton.Text = {'Recalibrate'; 'ADCs'};

            % Create EvenNyquistZoneCheckBox
            app.EvenNyquistZoneCheckBox = uicheckbox(app.SystemTab);
            app.EvenNyquistZoneCheckBox.ValueChangedFcn = createCallbackFcn(app, @EvenNyquistZoneCheckBoxValueChanged, true);
            app.EvenNyquistZoneCheckBox.Text = 'Even Nyquist Zone';
            app.EvenNyquistZoneCheckBox.Position = [64 512 123 22];

            % Create ADCsLabel
            app.ADCsLabel = uilabel(app.SystemTab);
            app.ADCsLabel.FontWeight = 'bold';
            app.ADCsLabel.Position = [93 630 38 22];
            app.ADCsLabel.Text = 'ADCs';

            % Create DACsLabel
            app.DACsLabel = uilabel(app.SystemTab);
            app.DACsLabel.FontWeight = 'bold';
            app.DACsLabel.Position = [93 431 38 22];
            app.DACsLabel.Text = {'DACs'; ''};

            % Create RFSoCFcSpinner_2Label
            app.RFSoCFcSpinner_2Label = uilabel(app.SystemTab);
            app.RFSoCFcSpinner_2Label.HorizontalAlignment = 'right';
            app.RFSoCFcSpinner_2Label.Position = [42 403 44 27];
            app.RFSoCFcSpinner_2Label.Text = {'RFSoC'; 'Fc'};

            % Create RFSoCFcSpinner_2
            app.RFSoCFcSpinner_2 = uispinner(app.SystemTab);
            app.RFSoCFcSpinner_2.Limits = [1 10000];
            app.RFSoCFcSpinner_2.ValueChangedFcn = createCallbackFcn(app, @RFSoCFcSpinner_2ValueChanged, true);
            app.RFSoCFcSpinner_2.Position = [101 408 77 22];
            app.RFSoCFcSpinner_2.Value = 4500;

            % Create dataStreamCheckBox
            app.dataStreamCheckBox = uicheckbox(app.SystemTab);
            app.dataStreamCheckBox.ValueChangedFcn = createCallbackFcn(app, @dataStreamCheckBoxValueChanged, true);
            app.dataStreamCheckBox.Text = 'dataStream';
            app.dataStreamCheckBox.Position = [133 630 84 22];
            app.dataStreamCheckBox.Value = true;

            % Create EvenNyquistZoneCheckBox_2
            app.EvenNyquistZoneCheckBox_2 = uicheckbox(app.SystemTab);
            app.EvenNyquistZoneCheckBox_2.ValueChangedFcn = createCallbackFcn(app, @EvenNyquistZoneCheckBox_2ValueChanged, true);
            app.EvenNyquistZoneCheckBox_2.Text = 'Even Nyquist Zone';
            app.EvenNyquistZoneCheckBox_2.Position = [58 370 123 22];

            % Create SYNCDropDownLabel
            app.SYNCDropDownLabel = uilabel(app.SystemTab);
            app.SYNCDropDownLabel.HorizontalAlignment = 'right';
            app.SYNCDropDownLabel.Position = [43 658 39 22];
            app.SYNCDropDownLabel.Text = 'SYNC';

            % Create SYNCDropDown
            app.SYNCDropDown = uidropdown(app.SystemTab);
            app.SYNCDropDown.Items = {'all', 'dac', 'none'};
            app.SYNCDropDown.ItemsData = [2 1 0];
            app.SYNCDropDown.ValueChangedFcn = createCallbackFcn(app, @SYNCDropDownValueChanged, true);
            app.SYNCDropDown.Position = [97 658 100 22];
            app.SYNCDropDown.Value = 1;

            % Create MirrorCheckBox
            app.MirrorCheckBox = uicheckbox(app.SystemTab);
            app.MirrorCheckBox.ValueChangedFcn = createCallbackFcn(app, @MirrorCheckBoxValueChanged, true);
            app.MirrorCheckBox.Text = 'Mirror';
            app.MirrorCheckBox.Position = [160 609 54 22];

            % Create SyncButton
            app.SyncButton = uibutton(app.SystemTab, 'push');
            app.SyncButton.ButtonPushedFcn = createCallbackFcn(app, @SyncButtonPushed, true);
            app.SyncButton.Position = [64 162 100 22];
            app.SyncButton.Text = 'Sync';

            % Create AntennaLabel
            app.AntennaLabel = uilabel(app.SystemTab);
            app.AntennaLabel.FontWeight = 'bold';
            app.AntennaLabel.Position = [87 140 53 22];
            app.AntennaLabel.Text = 'Antenna';

            % Create AntennaFcSpinnerLabel
            app.AntennaFcSpinnerLabel = uilabel(app.SystemTab);
            app.AntennaFcSpinnerLabel.HorizontalAlignment = 'right';
            app.AntennaFcSpinnerLabel.Position = [30 112 50 27];
            app.AntennaFcSpinnerLabel.Text = {'Antenna'; 'Fc'};

            % Create AntennaFcSpinner
            app.AntennaFcSpinner = uispinner(app.SystemTab);
            app.AntennaFcSpinner.Limits = [1 Inf];
            app.AntennaFcSpinner.ValueDisplayFormat = '%.0f';
            app.AntennaFcSpinner.ValueChangedFcn = createCallbackFcn(app, @AntennaFcSpinnerValueChanged, true);
            app.AntennaFcSpinner.Position = [95 117 105 22];
            app.AntennaFcSpinner.Value = 4500;

            % Create DacSignalDropDownLabel
            app.DacSignalDropDownLabel = uilabel(app.SystemTab);
            app.DacSignalDropDownLabel.HorizontalAlignment = 'right';
            app.DacSignalDropDownLabel.Position = [43 335 60 22];
            app.DacSignalDropDownLabel.Text = 'DacSignal';

            % Create DacSignalDropDown
            app.DacSignalDropDown = uidropdown(app.SystemTab);
            app.DacSignalDropDown.Items = {'OFDM', 'CW', 'SAW', 'Chirp', 'Off'};
            app.DacSignalDropDown.ValueChangedFcn = createCallbackFcn(app, @DacSignalDropDownValueChanged, true);
            app.DacSignalDropDown.Position = [118 335 68 22];
            app.DacSignalDropDown.Value = 'Off';

            % Create FcEditFieldLabel
            app.FcEditFieldLabel = uilabel(app.SystemTab);
            app.FcEditFieldLabel.HorizontalAlignment = 'right';
            app.FcEditFieldLabel.Position = [4 301 25 22];
            app.FcEditFieldLabel.Text = 'Fc';

            % Create FcEditField
            app.FcEditField = uieditfield(app.SystemTab, 'numeric');
            app.FcEditField.ValueChangedFcn = createCallbackFcn(app, @FcEditFieldValueChanged, true);
            app.FcEditField.Position = [44 301 25 22];

            % Create FeEditFieldLabel
            app.FeEditFieldLabel = uilabel(app.SystemTab);
            app.FeEditFieldLabel.HorizontalAlignment = 'right';
            app.FeEditFieldLabel.Position = [80 301 25 22];
            app.FeEditFieldLabel.Text = 'Fe';

            % Create FeEditField
            app.FeEditField = uieditfield(app.SystemTab, 'numeric');
            app.FeEditField.ValueChangedFcn = createCallbackFcn(app, @FeEditFieldValueChanged, true);
            app.FeEditField.Position = [113 301 32 22];
            app.FeEditField.Value = 50;

            % Create SREditFieldLabel
            app.SREditFieldLabel = uilabel(app.SystemTab);
            app.SREditFieldLabel.HorizontalAlignment = 'right';
            app.SREditFieldLabel.Position = [151 301 25 22];
            app.SREditFieldLabel.Text = 'SR';

            % Create SREditField
            app.SREditField = uieditfield(app.SystemTab, 'numeric');
            app.SREditField.Position = [181 301 26 22];
            app.SREditField.Value = 1;

            % Create MirrorCheckBox_2
            app.MirrorCheckBox_2 = uicheckbox(app.SystemTab);
            app.MirrorCheckBox_2.ValueChangedFcn = createCallbackFcn(app, @MirrorCheckBox_2ValueChanged, true);
            app.MirrorCheckBox_2.Text = 'Mirror';
            app.MirrorCheckBox_2.Position = [152 431 54 22];

            % Create ChannelcontrolDropDownLabel
            app.ChannelcontrolDropDownLabel = uilabel(app.SystemTab);
            app.ChannelcontrolDropDownLabel.HorizontalAlignment = 'right';
            app.ChannelcontrolDropDownLabel.Position = [11 263 50 27];
            app.ChannelcontrolDropDownLabel.Text = {'Channel'; 'control'};

            % Create ChannelcontrolDropDown
            app.ChannelcontrolDropDown = uidropdown(app.SystemTab);
            app.ChannelcontrolDropDown.Items = {'DAC gain', 'DAC phase', 'ADC gain', 'ADC phase'};
            app.ChannelcontrolDropDown.ValueChangedFcn = createCallbackFcn(app, @ChannelcontrolDropDownValueChanged, true);
            app.ChannelcontrolDropDown.Position = [76 268 119 22];
            app.ChannelcontrolDropDown.Value = 'DAC phase';

            % Create Ch1SpinnerLabel
            app.Ch1SpinnerLabel = uilabel(app.SystemTab);
            app.Ch1SpinnerLabel.HorizontalAlignment = 'center';
            app.Ch1SpinnerLabel.Position = [66 249 27 22];
            app.Ch1SpinnerLabel.Text = 'Ch1';

            % Create Ch1Spinner
            app.Ch1Spinner = uispinner(app.SystemTab);
            app.Ch1Spinner.Limits = [-179 179];
            app.Ch1Spinner.ValueChangedFcn = createCallbackFcn(app, @Ch1SpinnerValueChanged, true);
            app.Ch1Spinner.HorizontalAlignment = 'center';
            app.Ch1Spinner.Position = [51 231 63 22];

            % Create Ch2Spinner
            app.Ch2Spinner = uispinner(app.SystemTab);
            app.Ch2Spinner.Limits = [-179 179];
            app.Ch2Spinner.ValueChangedFcn = createCallbackFcn(app, @Ch2SpinnerValueChanged, true);
            app.Ch2Spinner.HorizontalAlignment = 'center';
            app.Ch2Spinner.Position = [117 231 63 22];

            % Create Ch2SpinnerLabel
            app.Ch2SpinnerLabel = uilabel(app.SystemTab);
            app.Ch2SpinnerLabel.HorizontalAlignment = 'center';
            app.Ch2SpinnerLabel.Position = [132 249 27 22];
            app.Ch2SpinnerLabel.Text = 'Ch2';

            % Create Ch3Spinner
            app.Ch3Spinner = uispinner(app.SystemTab);
            app.Ch3Spinner.Limits = [-179 179];
            app.Ch3Spinner.ValueChangedFcn = createCallbackFcn(app, @Ch3SpinnerValueChanged, true);
            app.Ch3Spinner.HorizontalAlignment = 'center';
            app.Ch3Spinner.Position = [51 195 63 22];

            % Create Ch3SpinnerLabel
            app.Ch3SpinnerLabel = uilabel(app.SystemTab);
            app.Ch3SpinnerLabel.HorizontalAlignment = 'center';
            app.Ch3SpinnerLabel.Position = [66 213 27 22];
            app.Ch3SpinnerLabel.Text = 'Ch3';

            % Create Ch4Spinner
            app.Ch4Spinner = uispinner(app.SystemTab);
            app.Ch4Spinner.Limits = [-179 179];
            app.Ch4Spinner.ValueChangedFcn = createCallbackFcn(app, @Ch4SpinnerValueChanged, true);
            app.Ch4Spinner.HorizontalAlignment = 'center';
            app.Ch4Spinner.Position = [117 195 63 22];

            % Create Ch4SpinnerLabel
            app.Ch4SpinnerLabel = uilabel(app.SystemTab);
            app.Ch4SpinnerLabel.HorizontalAlignment = 'center';
            app.Ch4SpinnerLabel.Position = [132 213 27 22];
            app.Ch4SpinnerLabel.Text = 'Ch4';

            % Create PrintphasemissmatchButton
            app.PrintphasemissmatchButton = uibutton(app.SystemTab, 'push');
            app.PrintphasemissmatchButton.ButtonPushedFcn = createCallbackFcn(app, @PrintphasemissmatchButtonPushed, true);
            app.PrintphasemissmatchButton.Position = [52 491 136 22];
            app.PrintphasemissmatchButton.Text = 'Print phase missmatch';

            % Create mmWaveFrontEndTab
            app.mmWaveFrontEndTab = uitab(app.TabGroup);
            app.mmWaveFrontEndTab.Title = 'mmWave FrontEnd';

            % Create Gauge
            app.Gauge = uigauge(app.mmWaveFrontEndTab, 'semicircular');
            app.Gauge.Limits = [-90 90];
            app.Gauge.Position = [17 330 189 102];

            % Create StartanglecalibrationsButton
            app.StartanglecalibrationsButton = uibutton(app.mmWaveFrontEndTab, 'push');
            app.StartanglecalibrationsButton.ButtonPushedFcn = createCallbackFcn(app, @StartanglecalibrationsButtonPushed, true);
            app.StartanglecalibrationsButton.Position = [42 237 140 58];
            app.StartanglecalibrationsButton.Text = 'Start angle calibrations';

            % Create ArduinoGUIButton
            app.ArduinoGUIButton = uibutton(app.mmWaveFrontEndTab, 'push');
            app.ArduinoGUIButton.ButtonPushedFcn = createCallbackFcn(app, @ArduinoGUIButtonPushed, true);
            app.ArduinoGUIButton.Position = [62 637 104 23];
            app.ArduinoGUIButton.Text = 'Arduino GUI';

            % Create StarrangEditFieldLabel
            app.StarrangEditFieldLabel = uilabel(app.mmWaveFrontEndTab);
            app.StarrangEditFieldLabel.HorizontalAlignment = 'right';
            app.StarrangEditFieldLabel.Position = [18 301 54 22];
            app.StarrangEditFieldLabel.Text = 'Starr ang';

            % Create StarrangEditField
            app.StarrangEditField = uieditfield(app.mmWaveFrontEndTab, 'numeric');
            app.StarrangEditField.Limits = [-90 90];
            app.StarrangEditField.RoundFractionalValues = 'on';
            app.StarrangEditField.ValueChangedFcn = createCallbackFcn(app, @StarrangEditFieldValueChanged, true);
            app.StarrangEditField.Position = [80 301 29 22];
            app.StarrangEditField.Value = -60;

            % Create StepangEditFieldLabel
            app.StepangEditFieldLabel = uilabel(app.mmWaveFrontEndTab);
            app.StepangEditFieldLabel.HorizontalAlignment = 'right';
            app.StepangEditFieldLabel.Position = [115 301 53 22];
            app.StepangEditFieldLabel.Text = 'Step ang';

            % Create StepangEditField
            app.StepangEditField = uieditfield(app.mmWaveFrontEndTab, 'numeric');
            app.StepangEditField.Limits = [0.01 50];
            app.StepangEditField.ValueChangedFcn = createCallbackFcn(app, @StepangEditFieldValueChanged, true);
            app.StepangEditField.Position = [176 301 24 22];
            app.StepangEditField.Value = 10;

            % Create DCLeakageAutocalStartButton
            app.DCLeakageAutocalStartButton = uibutton(app.mmWaveFrontEndTab, 'push');
            app.DCLeakageAutocalStartButton.ButtonPushedFcn = createCallbackFcn(app, @DCLeakageAutocalStartButtonPushed, true);
            app.DCLeakageAutocalStartButton.Position = [62 581 100 51];
            app.DCLeakageAutocalStartButton.Text = {'DC Leakage'; 'Autocal'; 'Start'};

            % Create PhaseAutocalStartButton
            app.PhaseAutocalStartButton = uibutton(app.mmWaveFrontEndTab, 'push');
            app.PhaseAutocalStartButton.ButtonPushedFcn = createCallbackFcn(app, @RXPhaseAutocalStartButtonPushed, true);
            app.PhaseAutocalStartButton.Position = [64 457 100 51];
            app.PhaseAutocalStartButton.Text = {'Phase'; 'Autocal'; 'Start'};

            % Create RXLabel_2
            app.RXLabel_2 = uilabel(app.mmWaveFrontEndTab);
            app.RXLabel_2.FontSize = 14;
            app.RXLabel_2.FontWeight = 'bold';
            app.RXLabel_2.Position = [95 663 25 22];
            app.RXLabel_2.Text = 'RX';

            % Create AmplitudeAutocalStartButton
            app.AmplitudeAutocalStartButton = uibutton(app.mmWaveFrontEndTab, 'push');
            app.AmplitudeAutocalStartButton.ButtonPushedFcn = createCallbackFcn(app, @RXAmplitudeAutocalStartButtonPushed, true);
            app.AmplitudeAutocalStartButton.Position = [63 519 100 51];
            app.AmplitudeAutocalStartButton.Text = {'Amplitude'; 'Autocal'; 'Start'};

            % Create TXLabel_2
            app.TXLabel_2 = uilabel(app.mmWaveFrontEndTab);
            app.TXLabel_2.FontSize = 14;
            app.TXLabel_2.FontWeight = 'bold';
            app.TXLabel_2.Position = [95 195 25 22];
            app.TXLabel_2.Text = 'TX';

            % Create PhaseAutocalStartButton_2
            app.PhaseAutocalStartButton_2 = uibutton(app.mmWaveFrontEndTab, 'push');
            app.PhaseAutocalStartButton_2.ButtonPushedFcn = createCallbackFcn(app, @TXPhaseAutocalStartButtonPushed, true);
            app.PhaseAutocalStartButton_2.Position = [59 49 100 51];
            app.PhaseAutocalStartButton_2.Text = {'Phase'; 'Autocal'; 'Start'};

            % Create AmplitudeAutocalStartButton_2
            app.AmplitudeAutocalStartButton_2 = uibutton(app.mmWaveFrontEndTab, 'push');
            app.AmplitudeAutocalStartButton_2.ButtonPushedFcn = createCallbackFcn(app, @TXAmplitudeAutocalStartButtonPushed, true);
            app.AmplitudeAutocalStartButton_2.Position = [58 126 100 51];
            app.AmplitudeAutocalStartButton_2.Text = {'Amplitude'; 'Autocal'; 'Start'};

            % Create DebugTab
            app.DebugTab = uitab(app.TabGroup);
            app.DebugTab.Title = 'Debug';

            % Create GetPatternButton
            app.GetPatternButton = uibutton(app.DebugTab, 'state');
            app.GetPatternButton.ValueChangedFcn = createCallbackFcn(app, @GetPatternButtonValueChanged, true);
            app.GetPatternButton.Text = 'GetPattern';
            app.GetPatternButton.Position = [69 430 100 22];

            % Create CutoffsetEditFieldLabel
            app.CutoffsetEditFieldLabel = uilabel(app.DebugTab);
            app.CutoffsetEditFieldLabel.HorizontalAlignment = 'right';
            app.CutoffsetEditFieldLabel.Position = [31 268 57 22];
            app.CutoffsetEditFieldLabel.Text = 'Cut offset';

            % Create CutoffsetEditField
            app.CutoffsetEditField = uieditfield(app.DebugTab, 'numeric');
            app.CutoffsetEditField.ValueChangedFcn = createCallbackFcn(app, @CutoffsetEditFieldValueChanged, true);
            app.CutoffsetEditField.Position = [131 268 38 22];
            app.CutoffsetEditField.Value = 500;

            % Create dataChanEditFieldLabel
            app.dataChanEditFieldLabel = uilabel(app.DebugTab);
            app.dataChanEditFieldLabel.HorizontalAlignment = 'right';
            app.dataChanEditFieldLabel.Position = [23 295 58 22];
            app.dataChanEditFieldLabel.Text = 'dataChan';

            % Create dataChanEditField
            app.dataChanEditField = uieditfield(app.DebugTab, 'numeric');
            app.dataChanEditField.Limits = [1024 131072];
            app.dataChanEditField.ValueChangedFcn = createCallbackFcn(app, @dataChanEditFieldValueChanged, true);
            app.dataChanEditField.Position = [95 295 74 22];
            app.dataChanEditField.Value = 8192;

            % Create c1CheckBox
            app.c1CheckBox = uicheckbox(app.DebugTab);
            app.c1CheckBox.ValueChangedFcn = createCallbackFcn(app, @c1CheckBoxValueChanged, true);
            app.c1CheckBox.Text = 'c1';
            app.c1CheckBox.Position = [134 349 35 22];

            % Create c2CheckBox
            app.c2CheckBox = uicheckbox(app.DebugTab);
            app.c2CheckBox.ValueChangedFcn = createCallbackFcn(app, @c2CheckBoxValueChanged, true);
            app.c2CheckBox.Text = 'c2';
            app.c2CheckBox.Position = [134 322 35 22];

            % Create MatlabPatternCheckBox
            app.MatlabPatternCheckBox = uicheckbox(app.DebugTab);
            app.MatlabPatternCheckBox.ValueChangedFcn = createCallbackFcn(app, @MatlabPatternCheckBoxValueChanged, true);
            app.MatlabPatternCheckBox.Text = 'MatlabPattern';
            app.MatlabPatternCheckBox.Position = [87 375 97 22];

            % Create UpdRateEditFieldLabel
            app.UpdRateEditFieldLabel = uilabel(app.DebugTab);
            app.UpdRateEditFieldLabel.HorizontalAlignment = 'right';
            app.UpdRateEditFieldLabel.Position = [22 403 55 22];
            app.UpdRateEditFieldLabel.Text = 'UpdRate';

            % Create UpdRateEditField
            app.UpdRateEditField = uieditfield(app.DebugTab, 'numeric');
            app.UpdRateEditField.Limits = [1 Inf];
            app.UpdRateEditField.ValueChangedFcn = createCallbackFcn(app, @UpdRateEditFieldValueChanged, true);
            app.UpdRateEditField.Position = [92 403 77 22];
            app.UpdRateEditField.Value = 10;

            % Create DLFEditFieldLabel
            app.DLFEditFieldLabel = uilabel(app.DebugTab);
            app.DLFEditFieldLabel.HorizontalAlignment = 'right';
            app.DLFEditFieldLabel.Position = [56 517 55 28];
            app.DLFEditFieldLabel.Text = 'DLF';

            % Create DLFEditField
            app.DLFEditField = uieditfield(app.DebugTab, 'numeric');
            app.DLFEditField.ValueChangedFcn = createCallbackFcn(app, @DLFEditFieldValueChanged2, true);
            app.DLFEditField.Position = [126 523 43 22];
            app.DLFEditField.Value = 1;

            % Create GetSpectrumButton
            app.GetSpectrumButton = uibutton(app.DebugTab, 'state');
            app.GetSpectrumButton.ValueChangedFcn = createCallbackFcn(app, @GetSpectrumButtonValueChanged, true);
            app.GetSpectrumButton.Text = 'GetSpectrum';
            app.GetSpectrumButton.Position = [69 457 100 22];

            % Create BWEditFieldLabel
            app.BWEditFieldLabel = uilabel(app.DebugTab);
            app.BWEditFieldLabel.HorizontalAlignment = 'right';
            app.BWEditFieldLabel.Position = [56 484 55 28];
            app.BWEditFieldLabel.Text = 'BW';

            % Create BWEditField
            app.BWEditField = uieditfield(app.DebugTab, 'numeric');
            app.BWEditField.Limits = [0 45];
            app.BWEditField.ValueChangedFcn = createCallbackFcn(app, @BWEditFieldValueChanged, true);
            app.BWEditField.Position = [126 490 43 22];
            app.BWEditField.Value = 0.1;

            % Create patternCorrCheckBox
            app.patternCorrCheckBox = uicheckbox(app.DebugTab);
            app.patternCorrCheckBox.ValueChangedFcn = createCallbackFcn(app, @patternCorrCheckBoxValueChanged, true);
            app.patternCorrCheckBox.Text = 'patternCorr';
            app.patternCorrCheckBox.Position = [86 241 83 22];

            % Create mis_angEditFieldLabel
            app.mis_angEditFieldLabel = uilabel(app.DebugTab);
            app.mis_angEditFieldLabel.HorizontalAlignment = 'right';
            app.mis_angEditFieldLabel.Position = [60 658 51 22];
            app.mis_angEditFieldLabel.Text = 'mis_ang';

            % Create mis_angEditField
            app.mis_angEditField = uieditfield(app.DebugTab, 'numeric');
            app.mis_angEditField.Limits = [0.1 20];
            app.mis_angEditField.ValueChangedFcn = createCallbackFcn(app, @mis_angEditFieldValueChanged, true);
            app.mis_angEditField.Position = [126 658 43 22];
            app.mis_angEditField.Value = 15;

            % Create alg_scan_resEditFieldLabel
            app.alg_scan_resEditFieldLabel = uilabel(app.DebugTab);
            app.alg_scan_resEditFieldLabel.HorizontalAlignment = 'right';
            app.alg_scan_resEditFieldLabel.Position = [34 631 77 22];
            app.alg_scan_resEditFieldLabel.Text = 'alg_scan_res';

            % Create alg_scan_resEditField
            app.alg_scan_resEditField = uieditfield(app.DebugTab, 'numeric');
            app.alg_scan_resEditField.Limits = [0.001 10];
            app.alg_scan_resEditField.ValueChangedFcn = createCallbackFcn(app, @alg_scan_resEditFieldValueChanged, true);
            app.alg_scan_resEditField.Position = [126 631 43 22];
            app.alg_scan_resEditField.Value = 1;

            % Create gammaEditFieldLabel
            app.gammaEditFieldLabel = uilabel(app.DebugTab);
            app.gammaEditFieldLabel.HorizontalAlignment = 'right';
            app.gammaEditFieldLabel.Position = [65 604 46 22];
            app.gammaEditFieldLabel.Text = 'gamma';

            % Create gammaEditField
            app.gammaEditField = uieditfield(app.DebugTab, 'numeric');
            app.gammaEditField.Limits = [0 Inf];
            app.gammaEditField.ValueChangedFcn = createCallbackFcn(app, @gammaEditFieldValueChanged, true);
            app.gammaEditField.Position = [126 604 43 22];
            app.gammaEditField.Value = 1;

            % Create alphaEditFieldLabel
            app.alphaEditFieldLabel = uilabel(app.DebugTab);
            app.alphaEditFieldLabel.HorizontalAlignment = 'right';
            app.alphaEditFieldLabel.Position = [76 577 35 22];
            app.alphaEditFieldLabel.Text = 'alpha';

            % Create alphaEditField
            app.alphaEditField = uieditfield(app.DebugTab, 'numeric');
            app.alphaEditField.Limits = [0 Inf];
            app.alphaEditField.ValueChangedFcn = createCallbackFcn(app, @alphaEditFieldValueChanged, true);
            app.alphaEditField.Position = [126 577 43 22];
            app.alphaEditField.Value = 1.1;

            % Create iterEditFieldLabel
            app.iterEditFieldLabel = uilabel(app.DebugTab);
            app.iterEditFieldLabel.HorizontalAlignment = 'right';
            app.iterEditFieldLabel.Position = [86 550 25 22];
            app.iterEditFieldLabel.Text = 'iter';

            % Create iterEditField
            app.iterEditField = uieditfield(app.DebugTab, 'numeric');
            app.iterEditField.Limits = [1 Inf];
            app.iterEditField.ValueChangedFcn = createCallbackFcn(app, @iterEditFieldValueChanged, true);
            app.iterEditField.Position = [126 550 43 22];
            app.iterEditField.Value = 1;

            % Create CutterCheckBox
            app.CutterCheckBox = uicheckbox(app.DebugTab);
            app.CutterCheckBox.ValueChangedFcn = createCallbackFcn(app, @CutterCheckBoxValueChanged, true);
            app.CutterCheckBox.Text = 'Cutter';
            app.CutterCheckBox.Position = [89 220 55 22];

            % Create DebugCheckBox_2
            app.DebugCheckBox_2 = uicheckbox(app.DebugTab);
            app.DebugCheckBox_2.ValueChangedFcn = createCallbackFcn(app, @DebugCheckBox_2ValueChanged, true);
            app.DebugCheckBox_2.Text = 'Debug';
            app.DebugCheckBox_2.Position = [91 195 57 22];

            % Create NumberofsavedfilesLabel
            app.NumberofsavedfilesLabel = uilabel(app.DebugTab);
            app.NumberofsavedfilesLabel.HorizontalAlignment = 'right';
            app.NumberofsavedfilesLabel.Position = [18 157 62 27];
            app.NumberofsavedfilesLabel.Text = {'Number of'; 'saved files'};

            % Create NumberofsavedfilesEditField
            app.NumberofsavedfilesEditField = uieditfield(app.DebugTab, 'numeric');
            app.NumberofsavedfilesEditField.Limits = [0 10000];
            app.NumberofsavedfilesEditField.ValueChangedFcn = createCallbackFcn(app, @NumberofsavedfilesEditFieldValueChanged, true);
            app.NumberofsavedfilesEditField.Position = [95 162 100 22];

            % Create SaveButton
            app.SaveButton = uibutton(app.DebugTab, 'push');
            app.SaveButton.ButtonPushedFcn = createCallbackFcn(app, @SaveButtonPushed, true);
            app.SaveButton.Position = [82 132 100 22];
            app.SaveButton.Text = 'Save';

            % Create DevicesTab
            app.DevicesTab = uitab(app.TabGroup);
            app.DevicesTab.Title = 'Devices';

            % Create DevicecontrolDropDownLabel
            app.DevicecontrolDropDownLabel = uilabel(app.DevicesTab);
            app.DevicecontrolDropDownLabel.HorizontalAlignment = 'right';
            app.DevicecontrolDropDownLabel.Position = [4 658 82 22];
            app.DevicecontrolDropDownLabel.Text = 'Device control';

            % Create DevicecontrolDropDown
            app.DevicecontrolDropDown = uidropdown(app.DevicesTab);
            app.DevicecontrolDropDown.ItemsData = [1 2 3 4 5 6 7 8 9];
            app.DevicecontrolDropDown.DropDownOpeningFcn = createCallbackFcn(app, @DevicecontrolDropDownOpening, true);
            app.DevicecontrolDropDown.ValueChangedFcn = createCallbackFcn(app, @DevicecontrolDropDownValueChanged, true);
            app.DevicecontrolDropDown.Position = [101 658 100 22];
            app.DevicecontrolDropDown.Value = 1;

            % Create FrequencySpinnerLabel
            app.FrequencySpinnerLabel = uilabel(app.DevicesTab);
            app.FrequencySpinnerLabel.HorizontalAlignment = 'right';
            app.FrequencySpinnerLabel.Position = [11 604 62 22];
            app.FrequencySpinnerLabel.Text = 'Frequency';

            % Create FrequencySpinner
            app.FrequencySpinner = uispinner(app.DevicesTab);
            app.FrequencySpinner.ValueDisplayFormat = '%.0f';
            app.FrequencySpinner.ValueChangedFcn = createCallbackFcn(app, @FrequencySpinnerValueChanged, true);
            app.FrequencySpinner.Position = [88 604 100 22];

            % Create AmplitudeSpinnerLabel
            app.AmplitudeSpinnerLabel = uilabel(app.DevicesTab);
            app.AmplitudeSpinnerLabel.HorizontalAlignment = 'right';
            app.AmplitudeSpinnerLabel.Position = [14 574 59 22];
            app.AmplitudeSpinnerLabel.Text = 'Amplitude';

            % Create AmplitudeSpinner
            app.AmplitudeSpinner = uispinner(app.DevicesTab);
            app.AmplitudeSpinner.Limits = [-144 30];
            app.AmplitudeSpinner.ValueDisplayFormat = '%.0f';
            app.AmplitudeSpinner.ValueChangedFcn = createCallbackFcn(app, @AmplitudeSpinnerValueChanged, true);
            app.AmplitudeSpinner.Position = [88 574 100 22];

            % Create PowerCheckBox
            app.PowerCheckBox = uicheckbox(app.DevicesTab);
            app.PowerCheckBox.ValueChangedFcn = createCallbackFcn(app, @PowerCheckBoxValueChanged2, true);
            app.PowerCheckBox.Text = 'Power';
            app.PowerCheckBox.Position = [23 533 56 22];

            % Create ModulationCheckBox
            app.ModulationCheckBox = uicheckbox(app.DevicesTab);
            app.ModulationCheckBox.ValueChangedFcn = createCallbackFcn(app, @ModulationCheckBoxValueChanged, true);
            app.ModulationCheckBox.Text = 'Modulation';
            app.ModulationCheckBox.Position = [119 534 80 22];

            % Create IPEditFieldLabel
            app.IPEditFieldLabel = uilabel(app.DevicesTab);
            app.IPEditFieldLabel.HorizontalAlignment = 'right';
            app.IPEditFieldLabel.Position = [48 630 25 22];
            app.IPEditFieldLabel.Text = 'IP';

            % Create IPEditField
            app.IPEditField = uieditfield(app.DevicesTab, 'text');
            app.IPEditField.ValueChangedFcn = createCallbackFcn(app, @IPEditFieldValueChanged, true);
            app.IPEditField.Position = [88 630 100 22];
            app.IPEditField.Value = '132.68.138.1';

            % Create AvgSpinnerLabel
            app.AvgSpinnerLabel = uilabel(app.LeftPanel);
            app.AvgSpinnerLabel.HorizontalAlignment = 'right';
            app.AvgSpinnerLabel.Position = [19 180 26 22];
            app.AvgSpinnerLabel.Text = 'Avg';

            % Create AvgSpinner
            app.AvgSpinner = uispinner(app.LeftPanel);
            app.AvgSpinner.Limits = [1 Inf];
            app.AvgSpinner.ValueChangedFcn = createCallbackFcn(app, @AvgSpinnerValueChanged, true);
            app.AvgSpinner.Position = [59 180 56 22];
            app.AvgSpinner.Value = 1;

            % Create VSACheckBox
            app.VSACheckBox = uicheckbox(app.LeftPanel);
            app.VSACheckBox.ValueChangedFcn = createCallbackFcn(app, @VSACheckBoxValueChanged, true);
            app.VSACheckBox.Text = 'VSA';
            app.VSACheckBox.Position = [126 180 46 22];
            app.VSACheckBox.Value = true;

            % Create CustomCommandTextAreaLabel
            app.CustomCommandTextAreaLabel = uilabel(app.LeftPanel);
            app.CustomCommandTextAreaLabel.HorizontalAlignment = 'right';
            app.CustomCommandTextAreaLabel.Position = [6 38 60 27];
            app.CustomCommandTextAreaLabel.Text = {'Custom'; 'Command'};

            % Create CustomCommandTextArea
            app.CustomCommandTextArea = uitextarea(app.LeftPanel);
            app.CustomCommandTextArea.ValueChangedFcn = createCallbackFcn(app, @CustomCommandTextAreaValueChanged, true);
            app.CustomCommandTextArea.Position = [81 43 146 24];

            % Create PlotCheckBox
            app.PlotCheckBox = uicheckbox(app.LeftPanel);
            app.PlotCheckBox.ValueChangedFcn = createCallbackFcn(app, @PlotCheckBoxValueChanged, true);
            app.PlotCheckBox.Text = 'Plot';
            app.PlotCheckBox.Position = [177 180 43 22];
            app.PlotCheckBox.Value = true;

            % Create ChannelselectListBoxLabel
            app.ChannelselectListBoxLabel = uilabel(app.LeftPanel);
            app.ChannelselectListBoxLabel.HorizontalAlignment = 'right';
            app.ChannelselectListBoxLabel.Position = [120 105 50 43];
            app.ChannelselectListBoxLabel.Text = {'Channel'; 'select'};

            % Create ChannelselectListBox
            app.ChannelselectListBox = uilistbox(app.LeftPanel);
            app.ChannelselectListBox.Items = {'Ch1', 'Ch2', 'Ch3', 'Ch4', 'All'};
            app.ChannelselectListBox.ItemsData = {'1', '2', '3', '4', '5', ''};
            app.ChannelselectListBox.ValueChangedFcn = createCallbackFcn(app, @ChannelselectListBoxValueChanged, true);
            app.ChannelselectListBox.Position = [174 71 52 98];
            app.ChannelselectListBox.Value = '5';

            % Create SignalpriorityButtonGroup
            app.SignalpriorityButtonGroup = uibuttongroup(app.LeftPanel);
            app.SignalpriorityButtonGroup.AutoResizeChildren = 'off';
            app.SignalpriorityButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @SignalpriorityButtonGroupSelectionChanged, true);
            app.SignalpriorityButtonGroup.Title = 'Signal priority';
            app.SignalpriorityButtonGroup.Position = [8 79 113 83];

            % Create MostPowerfullButton
            app.MostPowerfullButton = uiradiobutton(app.SignalpriorityButtonGroup);
            app.MostPowerfullButton.Text = 'Most Powerfull';
            app.MostPowerfullButton.Position = [11 37 101 22];
            app.MostPowerfullButton.Value = true;

            % Create LessPowerfullButton
            app.LessPowerfullButton = uiradiobutton(app.SignalpriorityButtonGroup);
            app.LessPowerfullButton.Text = 'Less Powerfull';
            app.LessPowerfullButton.Position = [11 15 100 22];

            % Create MirrorCheckBox_3
            app.MirrorCheckBox_3 = uicheckbox(app.LeftPanel);
            app.MirrorCheckBox_3.ValueChangedFcn = createCallbackFcn(app, @MirrorCheckBox_3ValueChanged, true);
            app.MirrorCheckBox_3.Text = 'Mirror';
            app.MirrorCheckBox_3.Position = [4 3 52 22];

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.RightPanel);
            app.GridLayout2.ColumnWidth = {'100x'};
            app.GridLayout2.RowHeight = {'100x', '100x'};
            app.GridLayout2.RowSpacing = 1.33333333333333;
            app.GridLayout2.Padding = [2.5 1.33333333333333 2.5 1.33333333333333];

            % Create UIAxes
            app.UIAxes = uiaxes(app.GridLayout2);
            title(app.UIAxes, 'Title')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.FontWeight = 'bold';
            app.UIAxes.LineWidth = 1;
            app.UIAxes.XGrid = 'on';
            app.UIAxes.XMinorGrid = 'on';
            app.UIAxes.YGrid = 'on';
            app.UIAxes.SubtitleFontWeight = 'bold';
            app.UIAxes.Layout.Row = 1;
            app.UIAxes.Layout.Column = 1;

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.GridLayout2);
            title(app.UIAxes2, 'Beam Pattern')
            xlabel(app.UIAxes2, 'X')
            ylabel(app.UIAxes2, 'Y')
            zlabel(app.UIAxes2, 'Z')
            app.UIAxes2.FontWeight = 'bold';
            app.UIAxes2.XGrid = 'on';
            app.UIAxes2.XMinorGrid = 'on';
            app.UIAxes2.YGrid = 'on';
            app.UIAxes2.Layout.Row = 2;
            app.UIAxes2.Layout.Column = 1;

            % Show the figure after all components are created
            app.RFSoCBeamformerUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = VSA_rfsoc_new_exported

            runningApp = getRunningApp(app);

            % Check for running singleton app
            if isempty(runningApp)

                % Create UIFigure and components
                createComponents(app)

                % Register the app with App Designer
                registerApp(app, app.RFSoCBeamformerUIFigure)

                % Execute the startup function
                runStartupFcn(app, @startupFcn)
            else

                % Focus the running singleton app
                figure(runningApp.RFSoCBeamformerUIFigure)

                app = runningApp;
            end

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.RFSoCBeamformerUIFigure)
        end
    end
end