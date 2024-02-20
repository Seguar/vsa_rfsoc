classdef VSA_rfsoc_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        RFSoCBeamformerUIFigure        matlab.ui.Figure
        GridLayout                     matlab.ui.container.GridLayout
        LeftPanel                      matlab.ui.container.Panel
        AvgSpinner                     matlab.ui.control.Spinner
        AvgSpinnerLabel                matlab.ui.control.Label
        CutterCheckBox                 matlab.ui.control.CheckBox
        TabGroup                       matlab.ui.container.TabGroup
        MainTab                        matlab.ui.container.Tab
        DOAtypeListBox                 matlab.ui.control.ListBox
        DOAtypeListBoxLabel            matlab.ui.control.Label
        DOAresolutionEditField         matlab.ui.control.NumericEditField
        DOAresolutionEditField_3Label  matlab.ui.control.Label
        SignalpositionButtonGroup      matlab.ui.container.ButtonGroup
        Button_3                       matlab.ui.control.RadioButton
        Button_2                       matlab.ui.control.RadioButton
        Button                         matlab.ui.control.RadioButton
        VSACheckBox                    matlab.ui.control.CheckBox
        BFtypeListBox                  matlab.ui.control.ListBox
        BFtypeListBoxLabel             matlab.ui.control.Label
        DebugTab                       matlab.ui.container.Tab
        GetSpectrumButton              matlab.ui.control.StateButton
        MagicEditField                 matlab.ui.control.NumericEditField
        MagicEditFieldLabel            matlab.ui.control.Label
        UpdRateEditField               matlab.ui.control.NumericEditField
        UpdRateEditFieldLabel          matlab.ui.control.Label
        DebugCheckBox                  matlab.ui.control.CheckBox
        ChannelselectListBox           matlab.ui.control.ListBox
        ChannelselectLabel             matlab.ui.control.Label
        c2CheckBox                     matlab.ui.control.CheckBox
        c1CheckBox                     matlab.ui.control.CheckBox
        dataChanEditField              matlab.ui.control.NumericEditField
        dataChanEditFieldLabel         matlab.ui.control.Label
        CutoffsetEditField             matlab.ui.control.NumericEditField
        CutoffsetEditFieldLabel        matlab.ui.control.Label
        GetPatternButton               matlab.ui.control.StateButton
        SystemTab                      matlab.ui.container.Tab
        ScanBWEditField                matlab.ui.control.NumericEditField
        ScanBWEditFieldLabel           matlab.ui.control.Label
        LoadVSAsetupButton             matlab.ui.control.Button
        SigBWEditField                 matlab.ui.control.NumericEditField
        SigBWEditFieldLabel            matlab.ui.control.Label
        SignalsSpinner                 matlab.ui.control.Spinner
        SignalsSpinnerLabel            matlab.ui.control.Label
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
        doa = 'MVDR';
        cutter = 1;
        off = 500;
        gap = 0;
        ang_num = 1;
        magic = 0.1;
        dataChan = 2^14;
        scan_res = 1;
        debug = 0;
        avg_factor = 10;
        updrate = 10;
        c1 = 0;
        c2 = 0;
        %%
        ula
        weights
        c
        %% System
        fc = 5.7e9;
        fsRfsoc = 125e6;
        bw = 20e6;
        num = 3;
        scan_bw = 180;
        setupFile = '.\settings\ofdm_iq_20_cal.setx';
        %% Flags
        reset_req = 1;
        estimator;
    end
    properties (Access = public)
        scan_axis = -90:1:90;
        %% Hardcode (temporally)
        
        num_elements = 4;
    end

    methods (Access = public)

    end

    methods (Access = private)


    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            cd(fileparts(mfilename('fullpath')))
            pwd
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
            addpath(genpath([pwd '\iqtools_2023_10_24']))
            addpath(genpath([pwd '\Packet-Creator-VHT']))
            addpath(genpath([pwd '\Functions']))
            app.c = physconst('LightSpeed'); % propagation velocity [m/s]
%             warning('off','all')
            while true
                if app.reset_req
                    app.ResetButton.Text = 'Processing...';
                    app.ResetButton.BackgroundColor = 'r';
                    drawnow%!!!!
                    app.scan_axis = -app.scan_bw/2:app.scan_res:app.scan_bw/2;
                    [data_v, tcp_client, plot_handle, app.ula] = rfsocBfPrep(app, app.dataChan, app.setupFile, app.fc, app.fsRfsoc, app.c, app.scan_axis, app.num_elements);                    
                    p_manual_mean = zeros(length(app.scan_axis), app.avg_factor);
                    yspec_mean = zeros(length(app.scan_axis), app.avg_factor);
                    clf(app.UIAxes);
                    app.reset_req = 0;
                    app.ResetButton.Text = 'Reset';
                    app.ResetButton.BackgroundColor = 'g';
                end
                try
                    [yspec, estimated_angle, ~, app.weights, ~, app.estimator] = rfsocBf(app, app.vsa, app.ch, app.bf, app.off, app.gap, app.cutter, app.ang_num, app.doa, data_v, tcp_client, app.fc, app.dataChan, app.magic, app.ula, app.num, app.scan_axis, ...
                        app.c1, app.c2, app.fsRfsoc, app.bw);
                    if isnan(app.weights)
                        continue
                    end
                catch
                    print("Error in rfsocBf")
                    continue
                end
                %% Pattern calc
                app.weights = conj(app.weights);
                p_manual = beamPatternCalc(app.weights, app.fc, app.scan_axis, app.num_elements);
                %% Avg
                [p_manual_mean_db, p_manual_mean]  = avgData(p_manual, p_manual_mean);
                [yspec_db, yspec_mean]  = avgData(yspec, yspec_mean);
                %% Plot
                app.UIAxes.Title.String = (['Direction of arrival' newline  'Estimated angles = ' num2str(estimated_angle)]);
                set(plot_handle, 'YData', yspec_db, 'LineWidth', 1.5);
                plot(app.UIAxes2, app.scan_axis,p_manual_mean_db, 'LineWidth', 1.5);
                % Xlines
                estimated_angle = [estimated_angle NaN NaN]; % To prevent errors in xlines indexing
                am = guiXline(am, app.UIAxes, main, estimated_angle(1));
                am2 = guiXline(am2, app.UIAxes2, main, estimated_angle(1));
                if sum(~isnan(estimated_angle)) > 1
                    bs = guiXline(bs, app.UIAxes, sub, estimated_angle(2));
                    bs2 = guiXline(bs2, app.UIAxes2, sub, estimated_angle(2));
                    if sum(~isnan(estimated_angle)) > 2
                        cs = guiXline(cs, app.UIAxes, sub, estimated_angle(3));
                        cs2 = guiXline(cs2, app.UIAxes2, sub, estimated_angle(3));
                    end
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

        % Selection changed function: SignalpositionButtonGroup
        function SignalpositionButtonGroupSelectionChanged(app, event)
            app.ang_num = str2double(app.SignalpositionButtonGroup.SelectedObject.Text);
        end

        % Callback function
        function MagicEditFieldValueChanged(app, event)
            app.magic = app.MagicEditField.Value;
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

        % Value changed function: SignalsSpinner
        function SignalsSpinnerValueChanged(app, event)
            app.num = app.SignalsSpinner.Value;
            app.reset_req = 1;
        end

        % Value changed function: DOAtypeListBox
        function DOAtypeListBoxValueChanged(app, event)
            app.doa = app.DOAtypeListBox.Value;
        end

        % Value changed function: AvgSpinner
        function AvgSpinnerValueChanged(app, event)
            app.avg_factor = app.AvgSpinner.Value;
            app.reset_req = 1;
        end

        % Value changed function: UpdRateEditField
        function UpdRateEditFieldValueChanged(app, event)
            app.updrate = app.UpdRateEditField.Value;
        end

        % Value changed function: DOAresolutionEditField
        function DOAresolutionEditFieldValueChanged(app, event)
            app.scan_res = app.DOAresolutionEditField.Value;
            app.reset_req = 1;
        end

        % Value changed function: MagicEditField
        function MagicEditFieldValueChanged2(app, event)
            app.magic = app.MagicEditField.Value;
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
            [file, path] = uigetfile('*.setx');
            app.setupFile = [path file];
            app.reset_req = 1;
        end

        % Value changed function: ScanBWEditField
        function ScanBWEditFieldValueChanged(app, event)
            app.scan_bw = app.ScanBWEditField.Value;
            app.reset_req = 1;
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

            % Create BFtypeListBoxLabel
            app.BFtypeListBoxLabel = uilabel(app.MainTab);
            app.BFtypeListBoxLabel.HorizontalAlignment = 'right';
            app.BFtypeListBoxLabel.Position = [-6 429 79 43];
            app.BFtypeListBoxLabel.Text = {'BF'; 'type'};

            % Create BFtypeListBox
            app.BFtypeListBox = uilistbox(app.MainTab);
            app.BFtypeListBox.Items = {'Without', 'Steering', 'MVDR', 'DMR', 'PC', 'LCMV', 'RVL'};
            app.BFtypeListBox.ValueChangedFcn = createCallbackFcn(app, @BFtypeListBoxValueChanged, true);
            app.BFtypeListBox.Position = [77 363 74 111];
            app.BFtypeListBox.Value = 'Steering';

            % Create VSACheckBox
            app.VSACheckBox = uicheckbox(app.MainTab);
            app.VSACheckBox.ValueChangedFcn = createCallbackFcn(app, @VSACheckBoxValueChanged, true);
            app.VSACheckBox.Text = 'VSA';
            app.VSACheckBox.Position = [83 219 46 22];
            app.VSACheckBox.Value = true;

            % Create SignalpositionButtonGroup
            app.SignalpositionButtonGroup = uibuttongroup(app.MainTab);
            app.SignalpositionButtonGroup.AutoResizeChildren = 'off';
            app.SignalpositionButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @SignalpositionButtonGroupSelectionChanged, true);
            app.SignalpositionButtonGroup.Title = 'Signal position';
            app.SignalpositionButtonGroup.Position = [51 253 100 106];

            % Create Button
            app.Button = uiradiobutton(app.SignalpositionButtonGroup);
            app.Button.Text = '1';
            app.Button.Position = [11 60 58 22];
            app.Button.Value = true;

            % Create Button_2
            app.Button_2 = uiradiobutton(app.SignalpositionButtonGroup);
            app.Button_2.Text = '2';
            app.Button_2.Position = [11 38 65 22];

            % Create Button_3
            app.Button_3 = uiradiobutton(app.SignalpositionButtonGroup);
            app.Button_3.Text = '3';
            app.Button_3.Position = [11 16 65 22];

            % Create DOAresolutionEditField_3Label
            app.DOAresolutionEditField_3Label = uilabel(app.MainTab);
            app.DOAresolutionEditField_3Label.HorizontalAlignment = 'right';
            app.DOAresolutionEditField_3Label.Position = [4 176 58 28];
            app.DOAresolutionEditField_3Label.Text = {'DOA'; 'resolution'};

            % Create DOAresolutionEditField
            app.DOAresolutionEditField = uieditfield(app.MainTab, 'numeric');
            app.DOAresolutionEditField.Limits = [0.0001 Inf];
            app.DOAresolutionEditField.ValueChangedFcn = createCallbackFcn(app, @DOAresolutionEditFieldValueChanged, true);
            app.DOAresolutionEditField.Position = [77 182 77 22];
            app.DOAresolutionEditField.Value = 1;

            % Create DOAtypeListBoxLabel
            app.DOAtypeListBoxLabel = uilabel(app.MainTab);
            app.DOAtypeListBoxLabel.HorizontalAlignment = 'right';
            app.DOAtypeListBoxLabel.Position = [-5 115 79 43];
            app.DOAtypeListBoxLabel.Text = {'DOA'; 'type'};

            % Create DOAtypeListBox
            app.DOAtypeListBox = uilistbox(app.MainTab);
            app.DOAtypeListBox.Items = {'MVDR', 'MUSIC', 'MUSICR', 'Beamscan', 'ESPRITE', 'ESPRITEBS', 'WSFR', 'Monopulse'};
            app.DOAtypeListBox.ValueChangedFcn = createCallbackFcn(app, @DOAtypeListBoxValueChanged, true);
            app.DOAtypeListBox.Position = [78 49 74 111];
            app.DOAtypeListBox.Value = 'MVDR';

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

            % Create ChannelselectLabel
            app.ChannelselectLabel = uilabel(app.DebugTab);
            app.ChannelselectLabel.HorizontalAlignment = 'right';
            app.ChannelselectLabel.Position = [6 444 50 28];
            app.ChannelselectLabel.Text = {'Channel'; 'select'};

            % Create ChannelselectListBox
            app.ChannelselectListBox = uilistbox(app.DebugTab);
            app.ChannelselectListBox.Items = {'Ch1', 'Ch2', 'Ch3', 'Ch4', 'All'};
            app.ChannelselectListBox.ItemsData = {'1', '2', '3', '4', '5', ''};
            app.ChannelselectListBox.ValueChangedFcn = createCallbackFcn(app, @ChannelselectListBoxValueChanged, true);
            app.ChannelselectListBox.Position = [70 376 81 98];
            app.ChannelselectListBox.Value = '5';

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

            % Create MagicEditFieldLabel
            app.MagicEditFieldLabel = uilabel(app.DebugTab);
            app.MagicEditFieldLabel.HorizontalAlignment = 'right';
            app.MagicEditFieldLabel.Position = [3 248 55 22];
            app.MagicEditFieldLabel.Text = 'Magic';

            % Create MagicEditField
            app.MagicEditField = uieditfield(app.DebugTab, 'numeric');
            app.MagicEditField.ValueChangedFcn = createCallbackFcn(app, @MagicEditFieldValueChanged2, true);
            app.MagicEditField.Position = [73 248 78 22];
            app.MagicEditField.Value = 0.1;

            % Create GetSpectrumButton
            app.GetSpectrumButton = uibutton(app.DebugTab, 'state');
            app.GetSpectrumButton.ValueChangedFcn = createCallbackFcn(app, @GetSpectrumButtonValueChanged, true);
            app.GetSpectrumButton.Text = 'GetSpectrum';
            app.GetSpectrumButton.Position = [36 211 100 22];

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

            % Create SignalsSpinnerLabel
            app.SignalsSpinnerLabel = uilabel(app.SystemTab);
            app.SignalsSpinnerLabel.HorizontalAlignment = 'right';
            app.SignalsSpinnerLabel.Position = [15 269 45 22];
            app.SignalsSpinnerLabel.Text = 'Signals';

            % Create SignalsSpinner
            app.SignalsSpinner = uispinner(app.SystemTab);
            app.SignalsSpinner.Limits = [1 5];
            app.SignalsSpinner.ValueDisplayFormat = '%.0f';
            app.SignalsSpinner.ValueChangedFcn = createCallbackFcn(app, @SignalsSpinnerValueChanged, true);
            app.SignalsSpinner.Position = [75 269 77 22];
            app.SignalsSpinner.Value = 3;

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
            app.ScanBWEditFieldLabel.Position = [27 158 33 28];
            app.ScanBWEditFieldLabel.Text = {'Scan'; 'BW'};

            % Create ScanBWEditField
            app.ScanBWEditField = uieditfield(app.SystemTab, 'numeric');
            app.ScanBWEditField.Limits = [2 360];
            app.ScanBWEditField.RoundFractionalValues = 'on';
            app.ScanBWEditField.ValueChangedFcn = createCallbackFcn(app, @ScanBWEditFieldValueChanged, true);
            app.ScanBWEditField.Position = [75 164 100 22];
            app.ScanBWEditField.Value = 180;

            % Create CutterCheckBox
            app.CutterCheckBox = uicheckbox(app.LeftPanel);
            app.CutterCheckBox.ValueChangedFcn = createCallbackFcn(app, @CutterCheckBoxValueChanged, true);
            app.CutterCheckBox.Text = 'Cutter';
            app.CutterCheckBox.Position = [138 103 55 22];

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