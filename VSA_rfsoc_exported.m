classdef VSA_rfsoc_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        GridLayout                   matlab.ui.container.GridLayout
        LeftPanel                    matlab.ui.container.Panel
        TabGroup                     matlab.ui.container.TabGroup
        MainTab                      matlab.ui.container.Tab
        MagicEditField               matlab.ui.control.NumericEditField
        MagicEditFieldLabel          matlab.ui.control.Label
        DOAresolutionEditField       matlab.ui.control.NumericEditField
        DOAresolutionEditFieldLabel  matlab.ui.control.Label
        ResetButton                  matlab.ui.control.StateButton
        PlutoButton                  matlab.ui.control.Button
        IQtoolsButton                matlab.ui.control.Button
        SignalpositionButtonGroup    matlab.ui.container.ButtonGroup
        Button_3                     matlab.ui.control.RadioButton
        Button_2                     matlab.ui.control.RadioButton
        Button                       matlab.ui.control.RadioButton
        CutterCheckBox               matlab.ui.control.CheckBox
        VSACheckBox                  matlab.ui.control.CheckBox
        BeamformingtypeListBox       matlab.ui.control.ListBox
        BeamformingtypeListBoxLabel  matlab.ui.control.Label
        DebugTab                     matlab.ui.container.Tab
        DebugCheckBox                matlab.ui.control.CheckBox
        ChannelselectListBox         matlab.ui.control.ListBox
        ChannelselectLabel           matlab.ui.control.Label
        c2CheckBox                   matlab.ui.control.CheckBox
        c1CheckBox                   matlab.ui.control.CheckBox
        dataChanEditField            matlab.ui.control.NumericEditField
        dataChanEditFieldLabel       matlab.ui.control.Label
        CutoffsetEditField           matlab.ui.control.NumericEditField
        CutoffsetEditFieldLabel      matlab.ui.control.Label
        GetPatternButton             matlab.ui.control.StateButton
        SystemTab                    matlab.ui.container.Tab
        RightPanel                   matlab.ui.container.Panel
        GridLayout2                  matlab.ui.container.GridLayout
        UIAxes2                      matlab.ui.control.UIAxes
        UIAxes                       matlab.ui.control.UIAxes
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
        cutter = 1;
        off = 500;
        gap = 0;
        ang_num = 1;
        magic = 0.1;
        dataChan = 2^14;
        scan_res = 1;
        debug = 0;

        c1 = 0;
        c2 = 0;
        %%
        ula
        weights
        c

        %% Flags
        reset_req = 0;
        %% Hardcode (temporally)
        setupFile = 'ofdm_iq_20_cal.setx';
        fc = 5.7e9;
        fsRfsoc = 125e6;
        num = 2;
        %         scan_axis = -90:1:90;

    end
    properties (Access = public)
        scan_axis = -90:1:90;
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
            count = 0;
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



            [data_v, estimator, tcp_client, plot_handle, app.ula] = rfsocBfPrep(app, app.dataChan, app.setupFile, app.num, app.scan_res, app.fc, app.fsRfsoc);
            while true

                if app.reset_req
                    delete(tcp_client)
                    [data_v, estimator, tcp_client, plot_handle, app.ula] = rfsocBfPrep(app, app.dataChan, app.setupFile, app.num, app.scan_res, app.fc, app.fsRfsoc);
                    clf(app.UIAxes);
                    app.reset_req = 0;
                end
                try
                    [yspec, estimated_angle, bfSig, app.weights, rawData] = rfsocBf(app, app.vsa, app.ch, app.bf, app.off, app.gap, app.cutter, app.ang_num, estimator, data_v, tcp_client, app.fc, app.dataChan, app.magic, app.ula, ...
                        app.c1, app.c2);
                catch
                    continue
                end
                if isnan(app.weights)
                    continue
                end
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
                %% plot
                app.UIAxes.Title.String = (['Direction of arrival', '   ||   Estimated angle = ' num2str(estimated_angle)]);
                set(plot_handle, 'YData', yspec/max(yspec));
                R = rawData'*rawData;
                results = zeros(length(app.scan_axis),1);
              p_manual = zeros(length(app.scan_axis),1);
                for i=1:length(app.scan_axis)
                    w_scan = exp(1j * pi * (0:3)' * sind(app.scan_axis(i)))*2;
                    w_scan = (w_scan.*app.weights');
                    r_weighted = w_scan.'*sig_scan.';
                    p_manual(i) = 20*log10(norm(r_weighted));
                end
                p_manual = p_manual - max(p_manual);
                estimated_angle = [estimated_angle NaN NaN];
                plot(app.UIAxes2, app.scan_axis,p_manual);
                am = guiXline(am, app.UIAxes, main, estimated_angle(1));
                bs = guiXline(bs, app.UIAxes, sub, estimated_angle(2));
                %                 cs = guiXline(cs, app.UIAxes, sub, estimated_angle(3));
                am2 = guiXline(am2, app.UIAxes2, main, estimated_angle(1));
                bs2 = guiXline(bs2, app.UIAxes2, sub, estimated_angle(2));
                %                 cs2 = guiXline(cs2, app.UIAxes2, sub, estimated_angle(3));
    
                if app.debug
                    if count == 10
                        plotResponse(app.ula,app.fc,app.c,...
                            'AzimuthAngles',app.scan_axis,...
                            'Unit','db',...
                            'Weights',app.weights.');
                        count = 0;
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

        % Value changed function: DOAresolutionEditField
        function DOAresolutionEditFieldValueChanged(app, event)
            app.scan_res = app.DOAresolutionEditField.Value;
            app.reset_req = 1;
        end

        % Value changed function: BeamformingtypeListBox
        function BeamformingtypeListBoxValueChanged(app, event)
            app.bf = app.BeamformingtypeListBox.Value;
        end

        % Selection changed function: SignalpositionButtonGroup
        function SignalpositionButtonGroupSelectionChanged(app, event)
            app.ang_num = str2double(app.SignalpositionButtonGroup.SelectedObject.Text);
        end

        % Value changed function: MagicEditField
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
            %             figure(app.UIFigure)
            %             app.UIFigure.WindowStyle = 'alwaysontop';
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

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {636, 636};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {272, '1x'};
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
            app.UIFigure.Position = [100 100 934 636];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);
            app.UIFigure.Scrollable = 'on';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {272, '1x'};
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
            app.IQtoolsButton.Position = [80 95 100 22];
            app.IQtoolsButton.Text = 'IQtools';

            % Create PlutoButton
            app.PlutoButton = uibutton(app.LeftPanel, 'push');
            app.PlutoButton.ButtonPushedFcn = createCallbackFcn(app, @PlutoButtonPushed, true);
            app.PlutoButton.Position = [83 220 100 22];
            app.PlutoButton.Text = 'Pluto';

            % Create ResetButton
            app.ResetButton = uibutton(app.LeftPanel, 'state');
            app.ResetButton.ValueChangedFcn = createCallbackFcn(app, @ResetButtonValueChanged, true);
            app.ResetButton.Text = 'Reset';
            app.ResetButton.Position = [83 156 100 22];

            % Create TabGroup
            app.TabGroup = uitabgroup(app.LeftPanel);
            app.TabGroup.Position = [7 306 260 329];

            % Create MainTab
            app.MainTab = uitab(app.TabGroup);
            app.MainTab.Title = 'Main';

            % Create BeamformingtypeListBoxLabel
            app.BeamformingtypeListBoxLabel = uilabel(app.MainTab);
            app.BeamformingtypeListBoxLabel.HorizontalAlignment = 'right';
            app.BeamformingtypeListBoxLabel.Position = [12 246 79 43];
            app.BeamformingtypeListBoxLabel.Text = {'Beamforming'; 'type'};

            % Create BeamformingtypeListBox
            app.BeamformingtypeListBox = uilistbox(app.MainTab);
            app.BeamformingtypeListBox.Items = {'Without', 'Steering', 'MVDR', 'DMR', 'PC', 'LCMV'};
            app.BeamformingtypeListBox.ValueChangedFcn = createCallbackFcn(app, @BeamformingtypeListBoxValueChanged, true);
            app.BeamformingtypeListBox.Position = [95 180 74 111];
            app.BeamformingtypeListBox.Value = 'Steering';

            % Create VSACheckBox
            app.VSACheckBox = uicheckbox(app.MainTab);
            app.VSACheckBox.ValueChangedFcn = createCallbackFcn(app, @VSACheckBoxValueChanged, true);
            app.VSACheckBox.Text = 'VSA';
            app.VSACheckBox.Position = [188 129 46 22];
            app.VSACheckBox.Value = true;

            % Create CutterCheckBox
            app.CutterCheckBox = uicheckbox(app.MainTab);
            app.CutterCheckBox.ValueChangedFcn = createCallbackFcn(app, @CutterCheckBoxValueChanged, true);
            app.CutterCheckBox.Text = 'Cutter';
            app.CutterCheckBox.Position = [188 159 55 22];

            % Create SignalpositionButtonGroup
            app.SignalpositionButtonGroup = uibuttongroup(app.MainTab);
            app.SignalpositionButtonGroup.AutoResizeChildren = 'off';
            app.SignalpositionButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @SignalpositionButtonGroupSelectionChanged, true);
            app.SignalpositionButtonGroup.Title = 'Signal position';
            app.SignalpositionButtonGroup.Position = [1 1 100 106];

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

            % Create DOAresolutionEditFieldLabel
            app.DOAresolutionEditFieldLabel = uilabel(app.MainTab);
            app.DOAresolutionEditFieldLabel.HorizontalAlignment = 'right';
            app.DOAresolutionEditFieldLabel.Position = [124 55 58 28];
            app.DOAresolutionEditFieldLabel.Text = {'DOA'; 'resolution'};

            % Create DOAresolutionEditField
            app.DOAresolutionEditField = uieditfield(app.MainTab, 'numeric');
            app.DOAresolutionEditField.ValueChangedFcn = createCallbackFcn(app, @DOAresolutionEditFieldValueChanged, true);
            app.DOAresolutionEditField.Position = [196 61 29 22];
            app.DOAresolutionEditField.Value = 1;

            % Create MagicEditFieldLabel
            app.MagicEditFieldLabel = uilabel(app.MainTab);
            app.MagicEditFieldLabel.HorizontalAlignment = 'right';
            app.MagicEditFieldLabel.Position = [1 129 38 22];
            app.MagicEditFieldLabel.Text = 'Magic';

            % Create MagicEditField
            app.MagicEditField = uieditfield(app.MainTab, 'numeric');
            app.MagicEditField.ValueChangedFcn = createCallbackFcn(app, @MagicEditFieldValueChanged, true);
            app.MagicEditField.Position = [53 129 100 22];
            app.MagicEditField.Value = 0.1;

            % Create DebugTab
            app.DebugTab = uitab(app.TabGroup);
            app.DebugTab.Title = 'Debug';

            % Create GetPatternButton
            app.GetPatternButton = uibutton(app.DebugTab, 'state');
            app.GetPatternButton.ValueChangedFcn = createCallbackFcn(app, @GetPatternButtonValueChanged, true);
            app.GetPatternButton.Text = 'GetPattern';
            app.GetPatternButton.Position = [103 22 100 22];

            % Create CutoffsetEditFieldLabel
            app.CutoffsetEditFieldLabel = uilabel(app.DebugTab);
            app.CutoffsetEditFieldLabel.HorizontalAlignment = 'right';
            app.CutoffsetEditFieldLabel.Position = [78 64 57 22];
            app.CutoffsetEditFieldLabel.Text = 'Cut offset';

            % Create CutoffsetEditField
            app.CutoffsetEditField = uieditfield(app.DebugTab, 'numeric');
            app.CutoffsetEditField.ValueChangedFcn = createCallbackFcn(app, @CutoffsetEditFieldValueChanged, true);
            app.CutoffsetEditField.Position = [178 64 38 22];
            app.CutoffsetEditField.Value = 500;

            % Create dataChanEditFieldLabel
            app.dataChanEditFieldLabel = uilabel(app.DebugTab);
            app.dataChanEditFieldLabel.HorizontalAlignment = 'right';
            app.dataChanEditFieldLabel.Position = [69 121 58 22];
            app.dataChanEditFieldLabel.Text = 'dataChan';

            % Create dataChanEditField
            app.dataChanEditField = uieditfield(app.DebugTab, 'numeric');
            app.dataChanEditField.ValueChangedFcn = createCallbackFcn(app, @dataChanEditFieldValueChanged, true);
            app.dataChanEditField.Position = [141 121 74 22];
            app.dataChanEditField.Value = 16384;

            % Create c1CheckBox
            app.c1CheckBox = uicheckbox(app.DebugTab);
            app.c1CheckBox.ValueChangedFcn = createCallbackFcn(app, @c1CheckBoxValueChanged, true);
            app.c1CheckBox.Text = 'c1';
            app.c1CheckBox.Position = [178 159 35 22];

            % Create c2CheckBox
            app.c2CheckBox = uicheckbox(app.DebugTab);
            app.c2CheckBox.ValueChangedFcn = createCallbackFcn(app, @c2CheckBoxValueChanged, true);
            app.c2CheckBox.Text = 'c2';
            app.c2CheckBox.Position = [218 159 35 22];

            % Create ChannelselectLabel
            app.ChannelselectLabel = uilabel(app.DebugTab);
            app.ChannelselectLabel.HorizontalAlignment = 'right';
            app.ChannelselectLabel.Position = [18 266 50 28];
            app.ChannelselectLabel.Text = {'Channel'; 'select'};

            % Create ChannelselectListBox
            app.ChannelselectListBox = uilistbox(app.DebugTab);
            app.ChannelselectListBox.Items = {'Ch1', 'Ch2', 'Ch3', 'Ch4', 'All'};
            app.ChannelselectListBox.ItemsData = {'1', '2', '3', '4', '5', ''};
            app.ChannelselectListBox.ValueChangedFcn = createCallbackFcn(app, @ChannelselectListBoxValueChanged, true);
            app.ChannelselectListBox.Position = [82 198 81 98];
            app.ChannelselectListBox.Value = '5';

            % Create DebugCheckBox
            app.DebugCheckBox = uicheckbox(app.DebugTab);
            app.DebugCheckBox.ValueChangedFcn = createCallbackFcn(app, @DebugCheckBoxValueChanged, true);
            app.DebugCheckBox.Text = 'Debug';
            app.DebugCheckBox.Position = [39 159 57 22];

            % Create SystemTab
            app.SystemTab = uitab(app.TabGroup);
            app.SystemTab.Title = 'System';

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
            app.UIAxes.XGrid = 'on';
            app.UIAxes.XMinorGrid = 'on';
            app.UIAxes.YGrid = 'on';
            app.UIAxes.Layout.Row = 1;
            app.UIAxes.Layout.Column = 1;

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.GridLayout2);
            title(app.UIAxes2, 'Title')
            xlabel(app.UIAxes2, 'X')
            ylabel(app.UIAxes2, 'Y')
            zlabel(app.UIAxes2, 'Z')
            app.UIAxes2.XGrid = 'on';
            app.UIAxes2.XMinorGrid = 'on';
            app.UIAxes2.YGrid = 'on';
            app.UIAxes2.Layout.Row = 2;
            app.UIAxes2.Layout.Column = 1;

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