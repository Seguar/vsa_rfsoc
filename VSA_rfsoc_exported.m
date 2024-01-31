classdef VSA_rfsoc_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        GridLayout                   matlab.ui.container.GridLayout
        LeftPanel                    matlab.ui.container.Panel
        MagicEditField               matlab.ui.control.NumericEditField
        MagicEditFieldLabel          matlab.ui.control.Label
        SignalpositionButtonGroup    matlab.ui.container.ButtonGroup
        Button_3                     matlab.ui.control.RadioButton
        Button_2                     matlab.ui.control.RadioButton
        Button                       matlab.ui.control.RadioButton
        BeamformingtypeListBox       matlab.ui.control.ListBox
        BeamformingtypeListBoxLabel  matlab.ui.control.Label
        DOAresolutionEditField       matlab.ui.control.NumericEditField
        DOAresolutionEditFieldLabel  matlab.ui.control.Label
        PlutoButton                  matlab.ui.control.Button
        IQtoolsButton                matlab.ui.control.Button
        dataChanEditField            matlab.ui.control.NumericEditField
        dataChanEditFieldLabel       matlab.ui.control.Label
        CutterCheckBox               matlab.ui.control.CheckBox
        ChannelselectListBox         matlab.ui.control.ListBox
        ChannelselectLabel           matlab.ui.control.Label
        CutoffsetEditField           matlab.ui.control.NumericEditField
        CutoffsetEditFieldLabel      matlab.ui.control.Label
        GapEditField                 matlab.ui.control.NumericEditField
        GapEditFieldLabel            matlab.ui.control.Label
        VSACheckBox                  matlab.ui.control.CheckBox
        RightPanel                   matlab.ui.container.Panel
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
        magic = 0;        
        dataChan = 2^14;
        scan_res = 1;

        %% Flags
        reset_req = 0;
        %% Hardcode (temporally)
        setupFile = 'ofdm_iq_20_cal.setx';
        fc = 5.7e9;
        fsRfsoc = 125e6;
        num = 3;
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
            addpath(genpath([pwd '\iqtools_2023_10_24']))
            addpath(genpath([pwd '\Packet-Creator-VHT']))
            c = physconst('LightSpeed'); % propagation velocity [m/s]


            
            [data_v, estimator, tcp_client, plot_handle, ula] = rfsocBfPrep(app, app.dataChan, app.setupFile, app.num, app.scan_res, app.fc, app.fsRfsoc);
            while true
                if app.reset_req
                    [data_v, estimator, tcp_client, plot_handle, ula] = rfsocBfPrep(app, app.dataChan, app.setupFile, app.num, app.scan_res, app.fc, app.fsRfsoc);
                    clf(app.UIAxes);
                    app.reset_req = 0;
                end
                try
                    [yspec, estimated_angle, bfSig, weights] = rfsocBf(app, app.vsa, app.ch, app.bf, app.off, app.gap, app.cutter, app.ang_num, estimator, data_v, tcp_client, app.fc, app.dataChan, app.magic, ula);
                catch
                    continue
                end

                %% plot
                app.UIAxes.Title.String = (['Direction of arrival', '   ||   Estimated angle = ' num2str(estimated_angle)]);
                set(plot_handle, 'YData', yspec/max(yspec));
%                 set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')

%                 p1 = pattern(ula,app.fc,app.scan_axis,0,'PropagationSpeed',c,'CoordinateSystem','rectangular','Type','directivity', 'Weights',double(weights));
%                 plot(app.UIAxes2 ,app.scan_axis, p1, LineWidth=1.5);
%                 xline(app.UIAxes, estimated_angle(app.ang_num))
%                 plot(app.UIAxes,estimated_angle(app.ang_num), 1, '.', MarkerSize=30);
%                 txtPlt = text(0, 0, '', 'Color', 'blue', 'FontSize', 14);
%                 txt = [newline newline '\uparrow' newline num2str(estimated_angle(app.ang_num)) char(176)];
%                 set(app.UIAxes, 'String', txt, 'Position', [estimated_angle, max(yspec)]);
%                 drawnow update % Makes callbacks stop working
%                 drawnow limitrate
%                 drawnow limitrate nocallbacks
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

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {660, 660};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {182, '1x'};
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
            app.UIFigure.Position = [100 100 787 660];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);
            app.UIFigure.Scrollable = 'on';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {182, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create VSACheckBox
            app.VSACheckBox = uicheckbox(app.LeftPanel);
            app.VSACheckBox.ValueChangedFcn = createCallbackFcn(app, @VSACheckBoxValueChanged, true);
            app.VSACheckBox.Text = 'VSA';
            app.VSACheckBox.Position = [87 418 46 22];
            app.VSACheckBox.Value = true;

            % Create GapEditFieldLabel
            app.GapEditFieldLabel = uilabel(app.LeftPanel);
            app.GapEditFieldLabel.HorizontalAlignment = 'right';
            app.GapEditFieldLabel.Position = [38 387 55 22];
            app.GapEditFieldLabel.Text = 'Gap';

            % Create GapEditField
            app.GapEditField = uieditfield(app.LeftPanel, 'numeric');
            app.GapEditField.Position = [143 387 38 22];

            % Create CutoffsetEditFieldLabel
            app.CutoffsetEditFieldLabel = uilabel(app.LeftPanel);
            app.CutoffsetEditFieldLabel.HorizontalAlignment = 'right';
            app.CutoffsetEditFieldLabel.Position = [38 304 57 22];
            app.CutoffsetEditFieldLabel.Text = 'Cut offset';

            % Create CutoffsetEditField
            app.CutoffsetEditField = uieditfield(app.LeftPanel, 'numeric');
            app.CutoffsetEditField.ValueChangedFcn = createCallbackFcn(app, @CutoffsetEditFieldValueChanged, true);
            app.CutoffsetEditField.Position = [138 304 38 22];
            app.CutoffsetEditField.Value = 500;

            % Create ChannelselectLabel
            app.ChannelselectLabel = uilabel(app.LeftPanel);
            app.ChannelselectLabel.HorizontalAlignment = 'right';
            app.ChannelselectLabel.Position = [38 625 50 28];
            app.ChannelselectLabel.Text = {'Channel'; 'select'};

            % Create ChannelselectListBox
            app.ChannelselectListBox = uilistbox(app.LeftPanel);
            app.ChannelselectListBox.Items = {'Ch1', 'Ch2', 'Ch3', 'Ch4', 'All'};
            app.ChannelselectListBox.ItemsData = {'1', '2', '3', '4', '5', ''};
            app.ChannelselectListBox.ValueChangedFcn = createCallbackFcn(app, @ChannelselectListBoxValueChanged, true);
            app.ChannelselectListBox.Position = [102 557 81 98];
            app.ChannelselectListBox.Value = '5';

            % Create CutterCheckBox
            app.CutterCheckBox = uicheckbox(app.LeftPanel);
            app.CutterCheckBox.ValueChangedFcn = createCallbackFcn(app, @CutterCheckBoxValueChanged, true);
            app.CutterCheckBox.Text = 'Cutter';
            app.CutterCheckBox.Position = [80 350 55 22];
            app.CutterCheckBox.Value = true;

            % Create dataChanEditFieldLabel
            app.dataChanEditFieldLabel = uilabel(app.LeftPanel);
            app.dataChanEditFieldLabel.HorizontalAlignment = 'right';
            app.dataChanEditFieldLabel.Position = [35 260 58 22];
            app.dataChanEditFieldLabel.Text = 'dataChan';

            % Create dataChanEditField
            app.dataChanEditField = uieditfield(app.LeftPanel, 'numeric');
            app.dataChanEditField.ValueChangedFcn = createCallbackFcn(app, @dataChanEditFieldValueChanged, true);
            app.dataChanEditField.Position = [107 260 74 22];
            app.dataChanEditField.Value = 16384;

            % Create IQtoolsButton
            app.IQtoolsButton = uibutton(app.LeftPanel, 'push');
            app.IQtoolsButton.ButtonPushedFcn = createCallbackFcn(app, @IQtoolsButtonPushed, true);
            app.IQtoolsButton.Position = [54 234 100 22];
            app.IQtoolsButton.Text = 'IQtools';

            % Create PlutoButton
            app.PlutoButton = uibutton(app.LeftPanel, 'push');
            app.PlutoButton.Position = [55 202 100 22];
            app.PlutoButton.Text = 'Pluto';

            % Create DOAresolutionEditFieldLabel
            app.DOAresolutionEditFieldLabel = uilabel(app.LeftPanel);
            app.DOAresolutionEditFieldLabel.HorizontalAlignment = 'right';
            app.DOAresolutionEditFieldLabel.Position = [39 166 58 28];
            app.DOAresolutionEditFieldLabel.Text = {'DOA'; 'resolution'};

            % Create DOAresolutionEditField
            app.DOAresolutionEditField = uieditfield(app.LeftPanel, 'numeric');
            app.DOAresolutionEditField.ValueChangedFcn = createCallbackFcn(app, @DOAresolutionEditFieldValueChanged, true);
            app.DOAresolutionEditField.Position = [111 172 29 22];
            app.DOAresolutionEditField.Value = 1;

            % Create BeamformingtypeListBoxLabel
            app.BeamformingtypeListBoxLabel = uilabel(app.LeftPanel);
            app.BeamformingtypeListBoxLabel.HorizontalAlignment = 'right';
            app.BeamformingtypeListBoxLabel.Position = [24 483 79 43];
            app.BeamformingtypeListBoxLabel.Text = {'Beamforming'; 'type'};

            % Create BeamformingtypeListBox
            app.BeamformingtypeListBox = uilistbox(app.LeftPanel);
            app.BeamformingtypeListBox.Items = {'Without', 'Steering', 'MVDR', 'LCMV'};
            app.BeamformingtypeListBox.ValueChangedFcn = createCallbackFcn(app, @BeamformingtypeListBoxValueChanged, true);
            app.BeamformingtypeListBox.Position = [107 454 74 74];
            app.BeamformingtypeListBox.Value = 'Steering';

            % Create SignalpositionButtonGroup
            app.SignalpositionButtonGroup = uibuttongroup(app.LeftPanel);
            app.SignalpositionButtonGroup.AutoResizeChildren = 'off';
            app.SignalpositionButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @SignalpositionButtonGroupSelectionChanged, true);
            app.SignalpositionButtonGroup.Title = 'Signal position';
            app.SignalpositionButtonGroup.Position = [40 52 100 106];

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

            % Create MagicEditFieldLabel
            app.MagicEditFieldLabel = uilabel(app.LeftPanel);
            app.MagicEditFieldLabel.HorizontalAlignment = 'right';
            app.MagicEditFieldLabel.Position = [29 18 38 22];
            app.MagicEditFieldLabel.Text = 'Magic';

            % Create MagicEditField
            app.MagicEditField = uieditfield(app.LeftPanel, 'numeric');
            app.MagicEditField.ValueChangedFcn = createCallbackFcn(app, @MagicEditFieldValueChanged, true);
            app.MagicEditField.Position = [82 18 100 22];

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            % Create UIAxes
            app.UIAxes = uiaxes(app.RightPanel);
            title(app.UIAxes, 'Title')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.XGrid = 'on';
            app.UIAxes.XMinorGrid = 'on';
            app.UIAxes.YGrid = 'on';
            app.UIAxes.Position = [1 265 598 394];

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.RightPanel);
            title(app.UIAxes2, 'Title')
            xlabel(app.UIAxes2, 'X')
            ylabel(app.UIAxes2, 'Y')
            zlabel(app.UIAxes2, 'Z')
            app.UIAxes2.Position = [1 6 598 260];

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