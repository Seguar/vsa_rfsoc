classdef VSA_rfsoc_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        GridLayout                     matlab.ui.container.GridLayout
        LeftPanel                      matlab.ui.container.Panel
        AvgEditField                   matlab.ui.control.NumericEditField
        AvgEditFieldLabel              matlab.ui.control.Label
        CutterCheckBox                 matlab.ui.control.CheckBox
        TabGroup                       matlab.ui.container.TabGroup
        MainTab                        matlab.ui.container.Tab
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
        UpdRateEditField               matlab.ui.control.NumericEditField
        UpdRateEditFieldLabel          matlab.ui.control.Label
        DOAtypeListBox                 matlab.ui.control.ListBox
        DOAtypeListBoxLabel            matlab.ui.control.Label
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
        SignalsEditField               matlab.ui.control.NumericEditField
        SignalsEditFieldLabel          matlab.ui.control.Label
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
        ContextMenu                    matlab.ui.container.ContextMenu
        Menu                           matlab.ui.container.Menu
        Menu2                          matlab.ui.container.Menu
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

        %% Flags
        reset_req = 1;

        %         scan_axis = -90:1:90;

    end
    properties (Access = public)
        %         scan_axis = -90:scan_res:90;
        scan_axis = -90:1:90;
        %% Hardcode (temporally)
        setupFile = 'ofdm_iq_20_cal.setx';
        fc = 5.7e9;
        fsRfsoc = 125e6;
        num = 3;
    end

    methods (Access = public)

    end

    methods (Access = private)


    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.UIFigure.Visible = 'off';
            movegui(app.UIFigure,"east")
            app.UIFigure.Visible = 'on';

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
            app.c = physconst('LightSpeed'); % propagation velocity [m/s]
            %             warning('off','all')
            lambda = app.c/app.fc;
            cPhSh = @(a) 360*(lambda/2)*sind(a)/lambda; % Calculation of constant phase shift between elements
            deg2comp = @(a) exp(1i*deg2rad(a)); % Degrees to complex (1 round) convertion
            powCalc = @(x) round(max(db(fftshift(fft(x))))/2, 1); % Power from FFT calculations

            sig_scan = exp(1j*2*pi*app.fc*(1/100e9:1/100e9:10/100e9));
            sig_scan = [sig_scan;sig_scan;sig_scan;sig_scan]';



            while true
                if app.reset_req
                    [data_v, estimator, tcp_client, plot_handle, app.ula] = rfsocBfPrep(app, app.dataChan, app.setupFile, app.num, app.scan_res, app.fc, app.fsRfsoc);
                    p_manual_mean = zeros(length(app.scan_axis), app.avg_factor);
                    yspec_mean = zeros(length(app.scan_axis), app.avg_factor);
                    clf(app.UIAxes);
                    app.reset_req = 0;
                end
                try
                    [yspec, estimated_angle, ~, app.weights, rawData] = rfsocBf(app, app.vsa, app.ch, app.bf, app.off, app.gap, app.cutter, app.ang_num, estimator, data_v, tcp_client, app.fc, app.dataChan, app.magic, app.ula, ...
                        app.c1, app.c2);
                catch
                    continue
                end
                if isnan(app.weights)
                    continue
                end
                %% Bugs
                app.weights = conj(app.weights);
                switch app.bf
                    case 'Steering'
                        app.weights = app.weights;
                    case 'MVDR'
                        if app.magic
                            app.weights = conj(app.weights);
                        else
                            app.weights = app.weights;
                        end
                    case 'PC'
                        app.weights = app.weights;
                    otherwise
                        app.weights = conj(app.weights);
                end
                %% Pattern calc
                R = rawData'*rawData;
                p_manual = zeros(length(app.scan_axis),1);
                for i=1:length(app.scan_axis)
                    w_scan = exp(1j * pi * (0:3)' * sind(app.scan_axis(i)))*2;
                    w_scan = (w_scan.*app.weights');
                    r_weighted = w_scan.'*sig_scan.';
                    p_manual(i) = norm(r_weighted);
                end
                [p_manual_mean_db, p_manual_mean]  = avgData(p_manual, p_manual_mean);                
                [yspec_db, yspec_mean]  = avgData(yspec, yspec_mean);
                %% Plot
                app.UIAxes.Title.String = (['Direction of arrival', '   ||   Estimated angle = ' num2str(estimated_angle)]);
                set(plot_handle, 'YData', yspec_db, 'LineWidth', 1.5);
                plot(app.UIAxes2, app.scan_axis,p_manual_mean_db);
                % Xlines
                estimated_angle = [estimated_angle NaN NaN];
                am = guiXline(am, app.UIAxes, main, estimated_angle(1));
                bs = guiXline(bs, app.UIAxes, sub, estimated_angle(2));
                                
                am2 = guiXline(am2, app.UIAxes2, main, estimated_angle(1));
                bs2 = guiXline(bs2, app.UIAxes2, sub, estimated_angle(2));

                if sum(~isnan(estimated_angle)) > 2
                    cs = guiXline(cs, app.UIAxes, sub, estimated_angle(3));
                    cs2 = guiXline(cs2, app.UIAxes2, sub, estimated_angle(3));
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

        % Callback function
        function UIAxesButtonDown(app, event)
            %             clf(app.UIAxes);
        end

        % Callback function
        function UIAxesButtonDown2(app, event)
            %             clf(app.UIAxes);
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

        % Callback function
        function DOAresolutionEditFieldValueChanged(app, event)
            app.scan_res = app.DOAresolutionEditField.Value;
            app.reset_req = 1;
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

        % Value changed function: SignalsEditField
        function SignalsEditFieldValueChanged(app, event)
            app.num = app.SignalsEditField.Value;
            app.reset_req = 1;
        end

        % Value changed function: DOAtypeListBox
        function DOAtypeListBoxValueChanged(app, event)
            app.doa = app.DOAtypeListBox.Value;
            
        end

        % Value changed function: AvgEditField
        function AvgEditFieldValueChanged(app, event)
            app.avg_factor = app.AvgEditField.Value;
            app.reset_req = 1;
        end

        % Value changed function: UpdRateEditField
        function UpdRateEditFieldValueChanged(app, event)
            app.updrate = app.UpdRateEditField.Value;
            
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {666, 666};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {163, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 729 666];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);
            app.UIFigure.Scrollable = 'on';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {163, '1x'};
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
            app.IQtoolsButton.Position = [41 41 100 22];
            app.IQtoolsButton.Text = 'IQtools';

            % Create PlutoButton
            app.PlutoButton = uibutton(app.LeftPanel, 'push');
            app.PlutoButton.ButtonPushedFcn = createCallbackFcn(app, @PlutoButtonPushed, true);
            app.PlutoButton.Position = [41 73 100 22];
            app.PlutoButton.Text = 'Pluto';

            % Create ResetButton
            app.ResetButton = uibutton(app.LeftPanel, 'state');
            app.ResetButton.ValueChangedFcn = createCallbackFcn(app, @ResetButtonValueChanged, true);
            app.ResetButton.Text = 'Reset';
            app.ResetButton.Position = [40 11 100 22];

            % Create TabGroup
            app.TabGroup = uitabgroup(app.LeftPanel);
            app.TabGroup.Position = [6 158 151 507];

            % Create MainTab
            app.MainTab = uitab(app.TabGroup);
            app.MainTab.Title = 'Main';

            % Create BFtypeListBoxLabel
            app.BFtypeListBoxLabel = uilabel(app.MainTab);
            app.BFtypeListBoxLabel.HorizontalAlignment = 'right';
            app.BFtypeListBoxLabel.Position = [-3 429 79 43];
            app.BFtypeListBoxLabel.Text = {'BF'; 'type'};

            % Create BFtypeListBox
            app.BFtypeListBox = uilistbox(app.MainTab);
            app.BFtypeListBox.Items = {'Without', 'Steering', 'MVDR', 'DMR', 'PC', 'LCMV'};
            app.BFtypeListBox.ValueChangedFcn = createCallbackFcn(app, @BFtypeListBoxValueChanged, true);
            app.BFtypeListBox.Position = [80 363 74 111];
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
            app.DOAresolutionEditField_3Label.Position = [-2 65 58 28];
            app.DOAresolutionEditField_3Label.Text = {'DOA'; 'resolution'};

            % Create DOAresolutionEditField
            app.DOAresolutionEditField = uieditfield(app.MainTab, 'numeric');
            app.DOAresolutionEditField.Limits = [0.0001 Inf];
            app.DOAresolutionEditField.Position = [71 71 77 22];
            app.DOAresolutionEditField.Value = 1;

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

            % Create DOAtypeListBoxLabel
            app.DOAtypeListBoxLabel = uilabel(app.DebugTab);
            app.DOAtypeListBoxLabel.HorizontalAlignment = 'right';
            app.DOAtypeListBoxLabel.Position = [-5 280 79 43];
            app.DOAtypeListBoxLabel.Text = {'DOA'; 'type'};

            % Create DOAtypeListBox
            app.DOAtypeListBox = uilistbox(app.DebugTab);
            app.DOAtypeListBox.Items = {'MVDR', 'DMR', 'PC', 'LCMV'};
            app.DOAtypeListBox.ValueChangedFcn = createCallbackFcn(app, @DOAtypeListBoxValueChanged, true);
            app.DOAtypeListBox.Position = [78 214 74 111];
            app.DOAtypeListBox.Value = 'MVDR';

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

            % Create SignalsEditFieldLabel
            app.SignalsEditFieldLabel = uilabel(app.SystemTab);
            app.SignalsEditFieldLabel.HorizontalAlignment = 'right';
            app.SignalsEditFieldLabel.Position = [5 331 55 28];
            app.SignalsEditFieldLabel.Text = 'Signals';

            % Create SignalsEditField
            app.SignalsEditField = uieditfield(app.SystemTab, 'numeric');
            app.SignalsEditField.Limits = [1 5];
            app.SignalsEditField.ValueDisplayFormat = '%.0f';
            app.SignalsEditField.ValueChangedFcn = createCallbackFcn(app, @SignalsEditFieldValueChanged, true);
            app.SignalsEditField.Position = [75 337 77 22];
            app.SignalsEditField.Value = 3;

            % Create CutterCheckBox
            app.CutterCheckBox = uicheckbox(app.LeftPanel);
            app.CutterCheckBox.ValueChangedFcn = createCallbackFcn(app, @CutterCheckBoxValueChanged, true);
            app.CutterCheckBox.Text = 'Cutter';
            app.CutterCheckBox.Position = [67 103 55 22];

            % Create AvgEditFieldLabel
            app.AvgEditFieldLabel = uilabel(app.LeftPanel);
            app.AvgEditFieldLabel.HorizontalAlignment = 'right';
            app.AvgEditFieldLabel.Position = [38 124 55 22];
            app.AvgEditFieldLabel.Text = 'Avg';

            % Create AvgEditField
            app.AvgEditField = uieditfield(app.LeftPanel, 'numeric');
            app.AvgEditField.Limits = [1 Inf];
            app.AvgEditField.ValueChangedFcn = createCallbackFcn(app, @AvgEditFieldValueChanged, true);
            app.AvgEditField.Position = [107 124 30 22];
            app.AvgEditField.Value = 10;

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
            xlabel(app.UIAxes2, 'X')
            ylabel(app.UIAxes2, 'Y')
            zlabel(app.UIAxes2, 'Z')
            app.UIAxes2.XGrid = 'on';
            app.UIAxes2.XMinorGrid = 'on';
            app.UIAxes2.YGrid = 'on';
            app.UIAxes2.Layout.Row = 2;
            app.UIAxes2.Layout.Column = 1;

            % Create ContextMenu
            app.ContextMenu = uicontextmenu(app.UIFigure);

            % Create Menu
            app.Menu = uimenu(app.ContextMenu);
            app.Menu.Text = 'Menu';

            % Create Menu2
            app.Menu2 = uimenu(app.ContextMenu);
            app.Menu2.Text = 'Menu2';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
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
                registerApp(app, app.UIFigure)

                % Execute the startup function
                runStartupFcn(app, @startupFcn)
            else

                % Focus the running singleton app
                figure(runningApp.UIFigure)

                app = runningApp;
            end

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end