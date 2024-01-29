classdef VSA_rfsoc_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        GridLayout                    matlab.ui.container.GridLayout
        LeftPanel                     matlab.ui.container.Panel
        BeamformingtypeListBox        matlab.ui.control.ListBox
        BeamformingtypeListBoxLabel   matlab.ui.control.Label
        SignalPositionEditField       matlab.ui.control.NumericEditField
        SignalPositionEditFieldLabel  matlab.ui.control.Label
        DOAresolutionEditField        matlab.ui.control.NumericEditField
        DOAresolutionEditFieldLabel   matlab.ui.control.Label
        PlutoButton                   matlab.ui.control.Button
        IQtoolsButton                 matlab.ui.control.Button
        dataChanEditField             matlab.ui.control.NumericEditField
        dataChanEditFieldLabel        matlab.ui.control.Label
        CutterCheckBox                matlab.ui.control.CheckBox
        ChannelselectListBox          matlab.ui.control.ListBox
        ChannelselectLabel            matlab.ui.control.Label
        CutoffsetEditField            matlab.ui.control.NumericEditField
        CutoffsetEditFieldLabel       matlab.ui.control.Label
        GapEditField                  matlab.ui.control.NumericEditField
        GapEditFieldLabel             matlab.ui.control.Label
        VSACheckBox                   matlab.ui.control.CheckBox
        RightPanel                    matlab.ui.container.Panel
        UIAxes                        matlab.ui.control.UIAxes
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end


    properties (Access = private)
        Property % Description
        vsa = 1;
        ch = 5;
        bf = 'Steering';
        cutter = 1;
        off = 150;
        gap = 0;
        dataChan = 2^14;
        reset_req = 0;
        scan_res = 1;
        ang_num = 1;
    end

    methods (Access = public)
%     vsa = app.VSACheckBox.Value;
%         function [vsa, ch, bf, off, gap, cutter, dataChan] = chkParams(app)
%             vsa = app.VSACheckBox.Value;
%             ch = str2num(app.ChannelselectListBox.Value);
%             bf = app.BeamformingCheckBox.Value;
%             cutter = app.CutterCheckBox.Value;
%             off = app.CutoffsetEditField.Value;
%             gap = app.GapEditField.Value;
%             dataChan = app.dataChanEditField.Value;
%         end
    end

    methods (Access = private)


    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            addpath(genpath([pwd '\iqtools_2023_10_24']))
            addpath(genpath([pwd '\Packet-Creator-VHT']))
            
            num = 3;
            setupFile = 'ofdm_iq_20_cal.setx';
            [data_v, estimator, tcp_client, plot_handle] = rfsocBfPrep(app, app.dataChan, setupFile, num, app.scan_res);
            while true
                if app.reset_req
                    [data_v, estimator, tcp_client, plot_handle] = rfsocBfPrep(app, app.dataChan, setupFile, num, app.scan_res);
                    clf(app.UIAxes);
                    app.reset_req = 0;
                end
                [yspec, estimated_angle, bfSig] = rfsocBf(app, app.vsa, app.ch, app.bf, app.off, app.gap, app.cutter, app.ang_num, estimator, data_v, tcp_client);

                %% plot
                app.UIAxes.Title.String = (['Direction of arrival', '   ||   Estimated angle = ' num2str(estimated_angle)]);
%                 set(plot_handle, 'YData', yspec); 
                set(plot_handle, 'YData', yspec/max(yspec)); 
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

        % Value changed function: SignalPositionEditField
        function SignalPositionEditFieldValueChanged(app, event)
            app.ang_num = app.SignalPositionEditField.Value;
            
        end

        % Value changed function: BeamformingtypeListBox
        function BeamformingtypeListBoxValueChanged(app, event)
            app.bf = app.BeamformingtypeListBox.Value;
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
            app.CutoffsetEditField.Position = [138 304 38 22];
            app.CutoffsetEditField.Value = 150;

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
            app.IQtoolsButton.Position = [60 146 100 22];
            app.IQtoolsButton.Text = 'IQtools';

            % Create PlutoButton
            app.PlutoButton = uibutton(app.LeftPanel, 'push');
            app.PlutoButton.Position = [60 108 100 22];
            app.PlutoButton.Text = 'Pluto';

            % Create DOAresolutionEditFieldLabel
            app.DOAresolutionEditFieldLabel = uilabel(app.LeftPanel);
            app.DOAresolutionEditFieldLabel.HorizontalAlignment = 'right';
            app.DOAresolutionEditFieldLabel.Position = [49 65 58 28];
            app.DOAresolutionEditFieldLabel.Text = {'DOA'; 'resolution'};

            % Create DOAresolutionEditField
            app.DOAresolutionEditField = uieditfield(app.LeftPanel, 'numeric');
            app.DOAresolutionEditField.ValueChangedFcn = createCallbackFcn(app, @DOAresolutionEditFieldValueChanged, true);
            app.DOAresolutionEditField.Position = [121 71 29 22];
            app.DOAresolutionEditField.Value = 1;

            % Create SignalPositionEditFieldLabel
            app.SignalPositionEditFieldLabel = uilabel(app.LeftPanel);
            app.SignalPositionEditFieldLabel.HorizontalAlignment = 'right';
            app.SignalPositionEditFieldLabel.Position = [38 25 55 28];
            app.SignalPositionEditFieldLabel.Text = {'Signal'; 'Position'};

            % Create SignalPositionEditField
            app.SignalPositionEditField = uieditfield(app.LeftPanel, 'numeric');
            app.SignalPositionEditField.ValueChangedFcn = createCallbackFcn(app, @SignalPositionEditFieldValueChanged, true);
            app.SignalPositionEditField.Position = [107 31 74 22];
            app.SignalPositionEditField.Value = 1;

            % Create BeamformingtypeListBoxLabel
            app.BeamformingtypeListBoxLabel = uilabel(app.LeftPanel);
            app.BeamformingtypeListBoxLabel.HorizontalAlignment = 'right';
            app.BeamformingtypeListBoxLabel.Position = [24 483 79 43];
            app.BeamformingtypeListBoxLabel.Text = {'Beamforming'; 'type'};

            % Create BeamformingtypeListBox
            app.BeamformingtypeListBox = uilistbox(app.LeftPanel);
            app.BeamformingtypeListBox.Items = {'Without', 'Steering', 'MVDR', 'LVCM'};
            app.BeamformingtypeListBox.ValueChangedFcn = createCallbackFcn(app, @BeamformingtypeListBoxValueChanged, true);
            app.BeamformingtypeListBox.Position = [107 454 74 74];
            app.BeamformingtypeListBox.Value = 'Steering';

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
            app.UIAxes.Position = [1 6 495 653];

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