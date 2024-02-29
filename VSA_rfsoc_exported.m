classdef VSA_rfsoc_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        RFSoCBeamformerUIFigure        matlab.ui.Figure
        GridLayout                     matlab.ui.container.GridLayout
        LeftPanel                      matlab.ui.container.Panel
        ChannelselectListBox           matlab.ui.control.ListBox
        ChannelselectListBoxLabel      matlab.ui.control.Label
        VSACheckBox                    matlab.ui.control.CheckBox
        AvgSpinner                     matlab.ui.control.Spinner
        AvgSpinnerLabel                matlab.ui.control.Label
        CutterCheckBox                 matlab.ui.control.CheckBox
        TabGroup                       matlab.ui.container.TabGroup
        MainTab                        matlab.ui.container.Tab
        BFtypeListBox                  matlab.ui.control.ListBox
        BFtypeListBoxLabel             matlab.ui.control.Label
        DOAtypeListBox                 matlab.ui.control.ListBox
        DOAtypeListBoxLabel            matlab.ui.control.Label
        DOAresolutionEditField         matlab.ui.control.NumericEditField
        DOAresolutionEditField_3Label  matlab.ui.control.Label
        SignalpriorityButtonGroup      matlab.ui.container.ButtonGroup
        LessPowerfullButton            matlab.ui.control.RadioButton
        MostPowerfullButton            matlab.ui.control.RadioButton
        DebugTab                       matlab.ui.container.Tab
        patternCorrCheckBox            matlab.ui.control.CheckBox
        BWoffsetEditField              matlab.ui.control.NumericEditField
        BWoffsetEditFieldLabel         matlab.ui.control.Label
        GetSpectrumButton              matlab.ui.control.StateButton
        DiagonalFactorEditField        matlab.ui.control.NumericEditField
        DiagonalFactorEditFieldLabel   matlab.ui.control.Label
        UpdRateEditField               matlab.ui.control.NumericEditField
        UpdRateEditFieldLabel          matlab.ui.control.Label
        DebugCheckBox                  matlab.ui.control.CheckBox
        c2CheckBox                     matlab.ui.control.CheckBox
        c1CheckBox                     matlab.ui.control.CheckBox
        dataChanEditField              matlab.ui.control.NumericEditField
        dataChanEditFieldLabel         matlab.ui.control.Label
        CutoffsetEditField             matlab.ui.control.NumericEditField
        CutoffsetEditFieldLabel        matlab.ui.control.Label
        GetPatternButton               matlab.ui.control.StateButton
        SystemTab                      matlab.ui.container.Tab
        PowerCheckBox                  matlab.ui.control.CheckBox
        ModCheckBox                    matlab.ui.control.CheckBox
        gainGenSpinner                 matlab.ui.control.Spinner
        gainGenSpinnerLabel            matlab.ui.control.Label
        fcGenSpinner                   matlab.ui.control.Spinner
        fcGenSpinnerLabel              matlab.ui.control.Label
        ScanBWEditField                matlab.ui.control.NumericEditField
        ScanBWEditFieldLabel           matlab.ui.control.Label
        LoadVSAsetupButton             matlab.ui.control.Button
        SigBWEditField                 matlab.ui.control.NumericEditField
        SigBWEditFieldLabel            matlab.ui.control.Label
        MaxSignalsSpinner              matlab.ui.control.Spinner
        MaxSignalsSpinnerLabel         matlab.ui.control.Label
        RFSoCFsEditField               matlab.ui.control.NumericEditField
        RFSoCFsEditFieldLabel          matlab.ui.control.Label
        RFSoCFcEditField               matlab.ui.control.NumericEditField
        RFSoCFcEditFieldLabel          matlab.ui.control.Label
        ResetButton                    matlab.ui.control.StateButton
        PlutoButton                    matlab.ui.control.Button
        IQtoolsButton                  matlab.ui.control.Button
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
        %% App fields
        vsa = 1;
        ch = 5;
        bf = 'Steering';
        doa = 'MUSIC';
        cutter = 0;
        off = 500;
        gap = 0;
        ang_num = 1;

        diag = 0.1;
        bwOff = 0.1;

        dataChan = 2^14;
        scan_res = 1;
        debug = 0;
        avg_factor = 10;
        updrate = 10;
        c1 = 0;
        c2 = 0;
        patternCorr = 0;
        %%
        ula
        weights
        c = physconst('LightSpeed'); % propagation velocity [m/s]
        %% System
        fc = 5.7e9;
        fsRfsoc = 125e6;
        bw = 20e6;
        num = 2;
        scan_bw = 180;
        setupFile = [fileparts(mfilename('fullpath')) '\Settings\ofdm_iq_20_cal.setx'];
        
        server_ip = 'pynq'; % Use the appropriate IP address or hostname
        server_port = 4000; % Use the same port number used in the Python server

        gen_ip = '132.68.138.229';
        gen_port = 5025;
        %% Flags
        reset_req = 1;
        part_reset_req = 1;
        estimator;
    end
    properties (Access = public)
        scan_axis = -90:1:90;
        %% Hardcode (temporally)
        koef;
        num_elements = 4;
        maxkoef = 5;
        fcInt = 5.7e9;
        stateInt = 0;
        powInt = 0;
        modInt = 0;
    end

    methods (Access = public)

    end

    methods (Access = private)

        
        function [data_v, tcp_client, plot_handle, p_manual_mean, yspec_mean] = resetApp(app)
            [p_manual_mean, yspec_mean, plot_handle] = partReset(app);
            app.ResetButton.Text = 'Reseting...';
            app.ResetButton.BackgroundColor = 'r';
            drawnow%!!!!
            data_v = vsaDdc(0, app.fsRfsoc, app.fsRfsoc, app.dataChan, 1);
            vsaSetup(app.setupFile)
            tcp_client = rfsocConnect(app.server_ip, app.server_port, app.dataChan);
            clf(app.UIAxes);
            app.reset_req = 0;
            app.part_reset_req = 0;
            app.ResetButton.Text = 'Reset';
            app.ResetButton.BackgroundColor = 'g';
        end

        function [p_manual_mean, yspec_mean, plot_handle] = partReset(app)
            app.ResetButton.Text = 'Reseting...';
            app.ResetButton.BackgroundColor = 'y';
            drawnow%!!!!
            app.ula = antPrep(app.num_elements, app.c, app.fc);
            app.scan_axis = -app.scan_bw/2:app.scan_res:app.scan_bw/2;
            plot_handle = plotPrep(app, app.scan_axis);
            p_manual_mean = zeros(length(app.scan_axis), app.avg_factor);
            yspec_mean = zeros(length(app.scan_axis), app.avg_factor);
            app.estimator = doaEst(app.doa, app.ula, app.scan_axis, app.num, app.fc); %% Need to fix scan_axis
%             app.koef = antSinglePattern(app.fc, app.scan_axis)';
            load koef
            app.koef = koef;
            app.koef = interp1(linspace(1,length(app.koef),length(app.koef))', app.koef, linspace(1,length(app.koef),length(app.scan_axis))', 'linear', 'extrap');
            app.part_reset_req = 0;
            app.ResetButton.Text = 'Reset';
            app.ResetButton.BackgroundColor = 'g';
        end
    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            cd(fileparts(mfilename('fullpath')))
            addpath(genpath([pwd '\iqtools_2023_10_24']))
            addpath(genpath([pwd '\Packet-Creator-VHT']))
            addpath(genpath([pwd '\Functions']))
%             load koef
%             app.koef = koef;
            app.RFSoCBeamformerUIFigure.Visible = 'off';
            movegui(app.RFSoCBeamformerUIFigure,"east")
            app.RFSoCBeamformerUIFigure.Visible = 'on';
            main.line = '-b';
            main.txt = 'Main';
            sub.line = '--c';
            sub.txt = 'Sub';
            count = 1;
            am = [];
            bs = [];
            cs = [];
            am2 = [];
            bs2 = [];
            cs2 = [];

            warning('off','all')
            while true
                if app.reset_req                    
                    [data_v, tcp_client, plot_handle, p_manual_mean, yspec_mean] = resetApp(app);
                elseif app.part_reset_req                    
                    [p_manual_mean, yspec_mean, plot_handle] = partReset(app);
                end
                try
                    [yspec, estimated_angle, bfSig, app.weights, rawData] = rfsocBf(app, app.vsa, app.ch, app.bf, app.off, app.gap, app.cutter, ...
                        app.ang_num, data_v, tcp_client, app.fc, app.dataChan, app.diag, app.bwOff, app.ula, app.scan_axis, ...
                        app.c1, app.c2, app.fsRfsoc, app.bw, app.c, app.estimator, app.fcInt);
                    if isnan(app.weights)
                        disp("No signal")
                        continue
                    end
                catch
                    disp("Error in rfsocBf")
                    continue
                end
                %% Pattern calc
                app.weights = conj(app.weights);
                p_manual = beamPatternCalc(app.weights, app.fc, app.scan_axis, app.num_elements);
                
                %% Avg
                [p_manual_mean_vec, p_manual_mean]  = avgData(p_manual, p_manual_mean);
                p_manual_mean_db = 20*log10(p_manual_mean_vec) - max(20*log10(p_manual_mean_vec));    
                [yspec_mean_vec, yspec_mean]  = avgData(yspec, yspec_mean);
                if app.patternCorr
                    yspec_mean_vec = yspec_mean_vec.*(1./app.koef);
                end
                %% Plot
                app.UIAxes.Title.String = (['Direction of Arrival' newline  'Estimated Angles = ' num2str(estimated_angle)]);
                
                set(plot_handle, 'YData', (yspec_mean_vec/max(yspec_mean_vec)), 'LineWidth', 1.5);
%                 set(plot_handle, 'YData', (yspec_mean_vec), 'LineWidth', 1.5);
                plot(app.UIAxes2, app.scan_axis,p_manual_mean_db, 'LineWidth', 1.5);
                % Xlines
                estimated_angle = [estimated_angle NaN NaN]; % To prevent errors in xlines indexing
                am = guiXline(am, app.UIAxes, main, estimated_angle(1));
                am2 = guiXline(am2, app.UIAxes2, main, estimated_angle(1));

                if sum(~isnan(estimated_angle)) > 1
                    bs = guiXline(bs, app.UIAxes, sub, estimated_angle(2));
                    bs2 = guiXline(bs2, app.UIAxes2, sub, estimated_angle(2));
                    null_diff = p_manual_mean_db(find(app.scan_axis == estimated_angle(1))) - p_manual_mean_db(find(app.scan_axis == estimated_angle(2)));
                    app.UIAxes2.Title.String = (['Beam Pattern' newline  'Power Advantage = ' ...
                        num2str(abs(null_diff)) ' dB']);
                    if sum(~isnan(estimated_angle)) > 2
                        cs = guiXline(cs, app.UIAxes, sub, estimated_angle(3));
                        cs2 = guiXline(cs2, app.UIAxes2, sub, estimated_angle(3));
                    end
                else
                    null_diff = p_manual_mean_db(find(app.scan_axis == estimated_angle(1))) - min(p_manual_mean_db);
                    app.UIAxes2.Title.String = (['Beam Pattern' newline  'Power Advantage = ' ...
                        num2str(abs(null_diff)) ' dB']);
                end

                if app.debug
                    if count >= app.updrate
                        plotResponse(app.ula,app.fc,app.c,...
                            'AzimuthAngles',app.scan_axis,...
                            'Unit','db',...
                            'Weights',app.weights.');
                        count = 1;
                    else
                        count = count + 1;
                    end
                end
            end
        end

        % Value changed function: VSACheckBox
        function VSACheckBoxValueChanged(app, event)
            app.vsa = app.VSACheckBox.Value;
        end

        % Callback function
        function BeamformingButtonGroupSizeChanged(app, event)
            app.position = app.BeamformingButtonGroup.Position;
        end

        % Callback function
        function BeamformingCheckBoxValueChanged(app, event)
            app.bf = app.BeamformingCheckBox.Value;
        end

        % Value changed function: ChannelselectListBox
        function ChannelselectListBoxValueChanged(app, event)
            app.ch = str2double(app.ChannelselectListBox.Value);
        end

        % Value changed function: dataChanEditField
        function dataChanEditFieldValueChanged(app, event)
            app.dataChan = app.dataChanEditField.Value;
            app.reset_req = 1;
        end

        % Button pushed function: IQtoolsButton
        function IQtoolsButtonPushed(app, event)
            iqtools
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

        % Value changed function: DebugCheckBox
        function DebugCheckBoxValueChanged(app, event)
            app.debug = app.DebugCheckBox.Value;
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

        % Button pushed function: PlutoButton
        function PlutoButtonPushed(app, event)
            PlutoControl
        end

        % Value changed function: c1CheckBox
        function c1CheckBoxValueChanged(app, event)
            app.c1 = app.c1CheckBox.Value;
        end

        % Value changed function: c2CheckBox
        function c2CheckBoxValueChanged(app, event)
            app.c2 = app.c2CheckBox.Value;
        end

        % Value changed function: RFSoCFcEditField
        function RFSoCFcEditFieldValueChanged(app, event)
            app.fc = app.RFSoCFcEditField.Value*1e6;
            app.reset_req = 1;
        end

        % Value changed function: RFSoCFsEditField
        function RFSoCFsEditFieldValueChanged(app, event)
            app.fsRfsoc = app.RFSoCFsEditField.Value*1e6;
            app.reset_req = 1;
        end

        % Value changed function: MaxSignalsSpinner
        function MaxSignalsSpinnerValueChanged(app, event)
            app.num = app.MaxSignalsSpinner.Value;
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

        % Value changed function: DiagonalFactorEditField
        function DiagonalFactorEditFieldValueChanged2(app, event)
            app.diag = app.DiagonalFactorEditField.Value;
        end

        % Value changed function: GetSpectrumButton
        function GetSpectrumButtonValueChanged(app, event)
            plotSpectrum(app.estimator)
            uistack(gcf,'top')            
        end

        % Value changed function: SigBWEditField
        function SigBWEditFieldValueChanged(app, event)
            app.bw = app.SigBWEditField.Value*1e6;            
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

        % Value changed function: BWoffsetEditField
        function BWoffsetEditFieldValueChanged(app, event)
            app.bwOff = app.BWoffsetEditField.Value;            
        end

        % Value changed function: fcGenSpinner
        function fcGenSpinnerValueChanged(app, event)
            app.fcInt = app.fcGenSpinner.Value*1e6;
            genCtrl(app.gen_ip, app.gen_port, app.stateInt, app.powInt, app.fcInt, app.modInt);
        end

        % Value changed function: gainGenSpinner
        function gainGenSpinnerValueChanged(app, event)
            app.powInt = app.gainGenSpinner.Value;
            genCtrl(app.gen_ip, app.gen_port, app.stateInt, app.powInt, app.fcInt, app.modInt);
        end

        % Value changed function: ModCheckBox
        function ModCheckBoxValueChanged(app, event)
            app.modInt = app.ModCheckBox.Value;
            genCtrl(app.gen_ip, app.gen_port, app.stateInt, app.powInt, app.fcInt, app.modInt);
        end

        % Value changed function: PowerCheckBox
        function PowerCheckBoxValueChanged(app, event)
            app.stateInt = app.PowerCheckBox.Value;
            genCtrl(app.gen_ip, app.gen_port, app.stateInt, app.powInt, app.fcInt, app.modInt);
        end

        % Value changed function: patternCorrCheckBox
        function patternCorrCheckBoxValueChanged(app, event)
            app.patternCorr = app.patternCorrCheckBox.Value;            
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.RFSoCBeamformerUIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {666, 666};
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
            app.RFSoCBeamformerUIFigure.Position = [100 100 800 666];
            app.RFSoCBeamformerUIFigure.Name = 'RFSoC Beamformer';
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

            % Create IQtoolsButton
            app.IQtoolsButton = uibutton(app.LeftPanel, 'push');
            app.IQtoolsButton.ButtonPushedFcn = createCallbackFcn(app, @IQtoolsButtonPushed, true);
            app.IQtoolsButton.Position = [112 41 100 22];
            app.IQtoolsButton.Text = 'IQtools';

            % Create PlutoButton
            app.PlutoButton = uibutton(app.LeftPanel, 'push');
            app.PlutoButton.ButtonPushedFcn = createCallbackFcn(app, @PlutoButtonPushed, true);
            app.PlutoButton.Position = [112 73 100 22];
            app.PlutoButton.Text = 'Pluto';

            % Create ResetButton
            app.ResetButton = uibutton(app.LeftPanel, 'state');
            app.ResetButton.ValueChangedFcn = createCallbackFcn(app, @ResetButtonValueChanged, true);
            app.ResetButton.Text = 'Reset';
            app.ResetButton.Position = [111 11 100 22];

            % Create TabGroup
            app.TabGroup = uitabgroup(app.LeftPanel);
            app.TabGroup.Position = [9 158 219 507];

            % Create MainTab
            app.MainTab = uitab(app.TabGroup);
            app.MainTab.Title = 'Main';

            % Create SignalpriorityButtonGroup
            app.SignalpriorityButtonGroup = uibuttongroup(app.MainTab);
            app.SignalpriorityButtonGroup.AutoResizeChildren = 'off';
            app.SignalpriorityButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @SignalpriorityButtonGroupSelectionChanged, true);
            app.SignalpriorityButtonGroup.Title = 'Signal priority';
            app.SignalpriorityButtonGroup.Position = [69 26 113 83];

            % Create MostPowerfullButton
            app.MostPowerfullButton = uiradiobutton(app.SignalpriorityButtonGroup);
            app.MostPowerfullButton.Text = 'Most Powerfull';
            app.MostPowerfullButton.Position = [11 37 101 22];
            app.MostPowerfullButton.Value = true;

            % Create LessPowerfullButton
            app.LessPowerfullButton = uiradiobutton(app.SignalpriorityButtonGroup);
            app.LessPowerfullButton.Text = 'Less Powerfull';
            app.LessPowerfullButton.Position = [11 15 100 22];

            % Create DOAresolutionEditField_3Label
            app.DOAresolutionEditField_3Label = uilabel(app.MainTab);
            app.DOAresolutionEditField_3Label.HorizontalAlignment = 'right';
            app.DOAresolutionEditField_3Label.Position = [28 444 58 28];
            app.DOAresolutionEditField_3Label.Text = {'DOA'; 'resolution'};

            % Create DOAresolutionEditField
            app.DOAresolutionEditField = uieditfield(app.MainTab, 'numeric');
            app.DOAresolutionEditField.Limits = [0.0001 Inf];
            app.DOAresolutionEditField.ValueChangedFcn = createCallbackFcn(app, @DOAresolutionEditFieldValueChanged, true);
            app.DOAresolutionEditField.Position = [101 450 77 22];
            app.DOAresolutionEditField.Value = 1;

            % Create DOAtypeListBoxLabel
            app.DOAtypeListBoxLabel = uilabel(app.MainTab);
            app.DOAtypeListBoxLabel.HorizontalAlignment = 'right';
            app.DOAtypeListBoxLabel.Position = [-6 381 79 43];
            app.DOAtypeListBoxLabel.Text = {'DOA'; 'type'};

            % Create DOAtypeListBox
            app.DOAtypeListBox = uilistbox(app.MainTab);
            app.DOAtypeListBox.Items = {'MVDR', 'MUSIC', 'Beamscan', 'MUSICR', 'ESPRITE', 'ESPRITEBS', 'WSFR'};
            app.DOAtypeListBox.ValueChangedFcn = createCallbackFcn(app, @DOAtypeListBoxValueChanged, true);
            app.DOAtypeListBox.Position = [77 292 98 134];
            app.DOAtypeListBox.Value = 'MUSIC';

            % Create BFtypeListBoxLabel
            app.BFtypeListBoxLabel = uilabel(app.MainTab);
            app.BFtypeListBoxLabel.HorizontalAlignment = 'right';
            app.BFtypeListBoxLabel.Position = [-6 242 79 43];
            app.BFtypeListBoxLabel.Text = {'BF'; 'type'};

            % Create BFtypeListBox
            app.BFtypeListBox = uilistbox(app.MainTab);
            app.BFtypeListBox.Items = {'Without', 'Steering', 'MVDR', 'DMR', 'PC', 'LCMV', 'RVL', 'RAB PC', 'DL MVDR'};
            app.BFtypeListBox.ValueChangedFcn = createCallbackFcn(app, @BFtypeListBoxValueChanged, true);
            app.BFtypeListBox.Position = [77 117 98 170];
            app.BFtypeListBox.Value = 'Steering';

            % Create DebugTab
            app.DebugTab = uitab(app.TabGroup);
            app.DebugTab.Title = 'Debug';

            % Create GetPatternButton
            app.GetPatternButton = uibutton(app.DebugTab, 'state');
            app.GetPatternButton.ValueChangedFcn = createCallbackFcn(app, @GetPatternButtonValueChanged, true);
            app.GetPatternButton.Text = 'GetPattern';
            app.GetPatternButton.Position = [35 176 100 22];

            % Create CutoffsetEditFieldLabel
            app.CutoffsetEditFieldLabel = uilabel(app.DebugTab);
            app.CutoffsetEditFieldLabel.HorizontalAlignment = 'right';
            app.CutoffsetEditFieldLabel.Position = [8 33 57 22];
            app.CutoffsetEditFieldLabel.Text = 'Cut offset';

            % Create CutoffsetEditField
            app.CutoffsetEditField = uieditfield(app.DebugTab, 'numeric');
            app.CutoffsetEditField.ValueChangedFcn = createCallbackFcn(app, @CutoffsetEditFieldValueChanged, true);
            app.CutoffsetEditField.Position = [108 33 38 22];
            app.CutoffsetEditField.Value = 500;

            % Create dataChanEditFieldLabel
            app.dataChanEditFieldLabel = uilabel(app.DebugTab);
            app.dataChanEditFieldLabel.HorizontalAlignment = 'right';
            app.dataChanEditFieldLabel.Position = [4 71 58 22];
            app.dataChanEditFieldLabel.Text = 'dataChan';

            % Create dataChanEditField
            app.dataChanEditField = uieditfield(app.DebugTab, 'numeric');
            app.dataChanEditField.Limits = [5000 Inf];
            app.dataChanEditField.ValueChangedFcn = createCallbackFcn(app, @dataChanEditFieldValueChanged, true);
            app.dataChanEditField.Position = [76 71 74 22];
            app.dataChanEditField.Value = 16384;

            % Create c1CheckBox
            app.c1CheckBox = uicheckbox(app.DebugTab);
            app.c1CheckBox.ValueChangedFcn = createCallbackFcn(app, @c1CheckBoxValueChanged, true);
            app.c1CheckBox.Text = 'c1';
            app.c1CheckBox.Position = [76 105 35 22];

            % Create c2CheckBox
            app.c2CheckBox = uicheckbox(app.DebugTab);
            app.c2CheckBox.ValueChangedFcn = createCallbackFcn(app, @c2CheckBoxValueChanged, true);
            app.c2CheckBox.Text = 'c2';
            app.c2CheckBox.Position = [117 105 35 22];

            % Create DebugCheckBox
            app.DebugCheckBox = uicheckbox(app.DebugTab);
            app.DebugCheckBox.ValueChangedFcn = createCallbackFcn(app, @DebugCheckBoxValueChanged, true);
            app.DebugCheckBox.Text = 'Debug';
            app.DebugCheckBox.Position = [15 105 57 22];

            % Create UpdRateEditFieldLabel
            app.UpdRateEditFieldLabel = uilabel(app.DebugTab);
            app.UpdRateEditFieldLabel.HorizontalAlignment = 'right';
            app.UpdRateEditFieldLabel.Position = [2 138 55 22];
            app.UpdRateEditFieldLabel.Text = 'UpdRate';

            % Create UpdRateEditField
            app.UpdRateEditField = uieditfield(app.DebugTab, 'numeric');
            app.UpdRateEditField.Limits = [1 Inf];
            app.UpdRateEditField.ValueChangedFcn = createCallbackFcn(app, @UpdRateEditFieldValueChanged, true);
            app.UpdRateEditField.Position = [72 138 77 22];
            app.UpdRateEditField.Value = 10;

            % Create DiagonalFactorEditFieldLabel
            app.DiagonalFactorEditFieldLabel = uilabel(app.DebugTab);
            app.DiagonalFactorEditFieldLabel.HorizontalAlignment = 'right';
            app.DiagonalFactorEditFieldLabel.Position = [10 327 55 28];
            app.DiagonalFactorEditFieldLabel.Text = {'Diagonal'; 'Factor'};

            % Create DiagonalFactorEditField
            app.DiagonalFactorEditField = uieditfield(app.DebugTab, 'numeric');
            app.DiagonalFactorEditField.ValueChangedFcn = createCallbackFcn(app, @DiagonalFactorEditFieldValueChanged2, true);
            app.DiagonalFactorEditField.Position = [80 333 78 22];
            app.DiagonalFactorEditField.Value = 0.1;

            % Create GetSpectrumButton
            app.GetSpectrumButton = uibutton(app.DebugTab, 'state');
            app.GetSpectrumButton.ValueChangedFcn = createCallbackFcn(app, @GetSpectrumButtonValueChanged, true);
            app.GetSpectrumButton.Text = 'GetSpectrum';
            app.GetSpectrumButton.Position = [36 211 100 22];

            % Create BWoffsetEditFieldLabel
            app.BWoffsetEditFieldLabel = uilabel(app.DebugTab);
            app.BWoffsetEditFieldLabel.HorizontalAlignment = 'right';
            app.BWoffsetEditFieldLabel.Position = [8 286 55 28];
            app.BWoffsetEditFieldLabel.Text = {'BW'; 'offset'};

            % Create BWoffsetEditField
            app.BWoffsetEditField = uieditfield(app.DebugTab, 'numeric');
            app.BWoffsetEditField.Limits = [0 45];
            app.BWoffsetEditField.ValueChangedFcn = createCallbackFcn(app, @BWoffsetEditFieldValueChanged, true);
            app.BWoffsetEditField.Position = [78 292 78 22];
            app.BWoffsetEditField.Value = 0.1;

            % Create patternCorrCheckBox
            app.patternCorrCheckBox = uicheckbox(app.DebugTab);
            app.patternCorrCheckBox.ValueChangedFcn = createCallbackFcn(app, @patternCorrCheckBoxValueChanged, true);
            app.patternCorrCheckBox.Text = 'patternCorr';
            app.patternCorrCheckBox.Position = [15 5 83 22];

            % Create SystemTab
            app.SystemTab = uitab(app.TabGroup);
            app.SystemTab.Title = 'System';

            % Create RFSoCFcEditFieldLabel
            app.RFSoCFcEditFieldLabel = uilabel(app.SystemTab);
            app.RFSoCFcEditFieldLabel.HorizontalAlignment = 'right';
            app.RFSoCFcEditFieldLabel.Position = [1 423 55 28];
            app.RFSoCFcEditFieldLabel.Text = {'RFSoC'; 'Fc'};

            % Create RFSoCFcEditField
            app.RFSoCFcEditField = uieditfield(app.SystemTab, 'numeric');
            app.RFSoCFcEditField.Limits = [500 6000];
            app.RFSoCFcEditField.ValueChangedFcn = createCallbackFcn(app, @RFSoCFcEditFieldValueChanged, true);
            app.RFSoCFcEditField.Position = [71 429 77 22];
            app.RFSoCFcEditField.Value = 5700;

            % Create RFSoCFsEditFieldLabel
            app.RFSoCFsEditFieldLabel = uilabel(app.SystemTab);
            app.RFSoCFsEditFieldLabel.HorizontalAlignment = 'right';
            app.RFSoCFsEditFieldLabel.Position = [5 376 55 28];
            app.RFSoCFsEditFieldLabel.Text = {'RFSoC'; 'Fs'};

            % Create RFSoCFsEditField
            app.RFSoCFsEditField = uieditfield(app.SystemTab, 'numeric');
            app.RFSoCFsEditField.Limits = [1 125];
            app.RFSoCFsEditField.ValueDisplayFormat = '%.0f';
            app.RFSoCFsEditField.ValueChangedFcn = createCallbackFcn(app, @RFSoCFsEditFieldValueChanged, true);
            app.RFSoCFsEditField.Position = [75 382 77 22];
            app.RFSoCFsEditField.Value = 125;

            % Create MaxSignalsSpinnerLabel
            app.MaxSignalsSpinnerLabel = uilabel(app.SystemTab);
            app.MaxSignalsSpinnerLabel.HorizontalAlignment = 'right';
            app.MaxSignalsSpinnerLabel.Position = [21 269 71 22];
            app.MaxSignalsSpinnerLabel.Text = 'Max Signals';

            % Create MaxSignalsSpinner
            app.MaxSignalsSpinner = uispinner(app.SystemTab);
            app.MaxSignalsSpinner.Limits = [1 5];
            app.MaxSignalsSpinner.ValueDisplayFormat = '%.0f';
            app.MaxSignalsSpinner.ValueChangedFcn = createCallbackFcn(app, @MaxSignalsSpinnerValueChanged, true);
            app.MaxSignalsSpinner.Position = [107 269 45 22];
            app.MaxSignalsSpinner.Value = 2;

            % Create SigBWEditFieldLabel
            app.SigBWEditFieldLabel = uilabel(app.SystemTab);
            app.SigBWEditFieldLabel.HorizontalAlignment = 'right';
            app.SigBWEditFieldLabel.Position = [4 327 55 28];
            app.SigBWEditFieldLabel.Text = {'Sig'; 'BW'};

            % Create SigBWEditField
            app.SigBWEditField = uieditfield(app.SystemTab, 'numeric');
            app.SigBWEditField.Limits = [1 125];
            app.SigBWEditField.ValueDisplayFormat = '%.0f';
            app.SigBWEditField.ValueChangedFcn = createCallbackFcn(app, @SigBWEditFieldValueChanged, true);
            app.SigBWEditField.Position = [74 333 77 22];
            app.SigBWEditField.Value = 20;

            % Create LoadVSAsetupButton
            app.LoadVSAsetupButton = uibutton(app.SystemTab, 'push');
            app.LoadVSAsetupButton.ButtonPushedFcn = createCallbackFcn(app, @LoadVSAsetupButtonPushed, true);
            app.LoadVSAsetupButton.Position = [33 211 102 22];
            app.LoadVSAsetupButton.Text = 'Load VSA setup';

            % Create ScanBWEditFieldLabel
            app.ScanBWEditFieldLabel = uilabel(app.SystemTab);
            app.ScanBWEditFieldLabel.HorizontalAlignment = 'right';
            app.ScanBWEditFieldLabel.Position = [52 158 33 28];
            app.ScanBWEditFieldLabel.Text = {'Scan'; 'BW'};

            % Create ScanBWEditField
            app.ScanBWEditField = uieditfield(app.SystemTab, 'numeric');
            app.ScanBWEditField.Limits = [2 360];
            app.ScanBWEditField.RoundFractionalValues = 'on';
            app.ScanBWEditField.ValueChangedFcn = createCallbackFcn(app, @ScanBWEditFieldValueChanged, true);
            app.ScanBWEditField.Position = [100 164 44 22];
            app.ScanBWEditField.Value = 180;

            % Create fcGenSpinnerLabel
            app.fcGenSpinnerLabel = uilabel(app.SystemTab);
            app.fcGenSpinnerLabel.HorizontalAlignment = 'right';
            app.fcGenSpinnerLabel.Position = [35 117 38 22];
            app.fcGenSpinnerLabel.Text = 'fcGen';

            % Create fcGenSpinner
            app.fcGenSpinner = uispinner(app.SystemTab);
            app.fcGenSpinner.Limits = [1 6000];
            app.fcGenSpinner.ValueChangedFcn = createCallbackFcn(app, @fcGenSpinnerValueChanged, true);
            app.fcGenSpinner.Position = [81 117 69 22];
            app.fcGenSpinner.Value = 5700;

            % Create gainGenSpinnerLabel
            app.gainGenSpinnerLabel = uilabel(app.SystemTab);
            app.gainGenSpinnerLabel.HorizontalAlignment = 'right';
            app.gainGenSpinnerLabel.Position = [21 84 51 22];
            app.gainGenSpinnerLabel.Text = 'gainGen';

            % Create gainGenSpinner
            app.gainGenSpinner = uispinner(app.SystemTab);
            app.gainGenSpinner.Limits = [-144 30];
            app.gainGenSpinner.RoundFractionalValues = 'on';
            app.gainGenSpinner.ValueChangedFcn = createCallbackFcn(app, @gainGenSpinnerValueChanged, true);
            app.gainGenSpinner.Position = [87 84 64 22];

            % Create ModCheckBox
            app.ModCheckBox = uicheckbox(app.SystemTab);
            app.ModCheckBox.ValueChangedFcn = createCallbackFcn(app, @ModCheckBoxValueChanged, true);
            app.ModCheckBox.Text = 'Mod';
            app.ModCheckBox.Position = [25 50 45 22];

            % Create PowerCheckBox
            app.PowerCheckBox = uicheckbox(app.SystemTab);
            app.PowerCheckBox.ValueChangedFcn = createCallbackFcn(app, @PowerCheckBoxValueChanged, true);
            app.PowerCheckBox.Text = 'Power';
            app.PowerCheckBox.Position = [118 52 56 22];

            % Create CutterCheckBox
            app.CutterCheckBox = uicheckbox(app.LeftPanel);
            app.CutterCheckBox.ValueChangedFcn = createCallbackFcn(app, @CutterCheckBoxValueChanged, true);
            app.CutterCheckBox.Text = 'Cutter';
            app.CutterCheckBox.Position = [172 103 55 22];

            % Create AvgSpinnerLabel
            app.AvgSpinnerLabel = uilabel(app.LeftPanel);
            app.AvgSpinnerLabel.HorizontalAlignment = 'right';
            app.AvgSpinnerLabel.Position = [112 124 26 22];
            app.AvgSpinnerLabel.Text = 'Avg';

            % Create AvgSpinner
            app.AvgSpinner = uispinner(app.LeftPanel);
            app.AvgSpinner.Limits = [1 Inf];
            app.AvgSpinner.ValueChangedFcn = createCallbackFcn(app, @AvgSpinnerValueChanged, true);
            app.AvgSpinner.Position = [152 124 56 22];
            app.AvgSpinner.Value = 10;

            % Create VSACheckBox
            app.VSACheckBox = uicheckbox(app.LeftPanel);
            app.VSACheckBox.ValueChangedFcn = createCallbackFcn(app, @VSACheckBoxValueChanged, true);
            app.VSACheckBox.Text = 'VSA';
            app.VSACheckBox.Position = [117 103 46 22];
            app.VSACheckBox.Value = true;

            % Create ChannelselectListBoxLabel
            app.ChannelselectListBoxLabel = uilabel(app.LeftPanel);
            app.ChannelselectListBoxLabel.HorizontalAlignment = 'right';
            app.ChannelselectListBoxLabel.Position = [1 94 50 43];
            app.ChannelselectListBoxLabel.Text = {'Channel'; 'select'};

            % Create ChannelselectListBox
            app.ChannelselectListBox = uilistbox(app.LeftPanel);
            app.ChannelselectListBox.Items = {'Ch1', 'Ch2', 'Ch3', 'Ch4', 'All'};
            app.ChannelselectListBox.ItemsData = {'1', '2', '3', '4', '5', ''};
            app.ChannelselectListBox.ValueChangedFcn = createCallbackFcn(app, @ChannelselectListBoxValueChanged, true);
            app.ChannelselectListBox.Position = [55 41 52 98];
            app.ChannelselectListBox.Value = '5';

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
        function app = VSA_rfsoc_exported

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