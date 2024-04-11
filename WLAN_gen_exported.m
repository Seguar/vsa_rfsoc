classdef WLAN_gen_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        WLANVHTgenUIFigure   matlab.ui.Figure
        zerosEditField       matlab.ui.control.NumericEditField
        zerosEditFieldLabel  matlab.ui.control.Label
        VHTWLANGENLabel      matlab.ui.control.Label
        SavesignalButton     matlab.ui.control.Button
        RandDataCheckBox     matlab.ui.control.CheckBox
        BWListBox            matlab.ui.control.ListBox
        BWListBoxLabel       matlab.ui.control.Label
        MCSSlider            matlab.ui.control.Slider
        MCSSliderLabel       matlab.ui.control.Label
        FrameEditField       matlab.ui.control.NumericEditField
        FrameEditFieldLabel  matlab.ui.control.Label
        fsEditField          matlab.ui.control.NumericEditField
        fsEditFieldLabel     matlab.ui.control.Label
    end

    
    properties (Access = private)
        fs = 60e6;
        frame = 500;
        bw = 20;
        isDataRand = 1;
        mcs = 4;
        zer = 0;
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            addpath(genpath([pwd '\Packet-Creator-VHT']))
        end

        % Value changed function: fsEditField
        function fsEditFieldValueChanged(app, event)
            app.fs = app.fsEditField.Value;            
        end

        % Value changed function: FrameEditField
        function FrameEditFieldValueChanged(app, event)
            app.frame = app.FrameEditField.Value;            
        end

        % Value changed function: BWListBox
        function BWListBoxValueChanged(app, event)
            app.bw = str2double(app.BWListBox.Value);            
        end

        % Value changed function: RandDataCheckBox
        function RandDataCheckBoxValueChanged(app, event)
            app.isDataRand = app.RandDataCheckBox.Value;            
        end

        % Value changed function: MCSSlider
        function MCSSliderValueChanged(app, event)
            app.mcs = floor(app.MCSSlider.Value);
        end

        % Button pushed function: SavesignalButton
        function SavesignalButtonPushed(app, event)
            Y = wlanGen(app.fs, app.frame, app.bw, app.mcs, app.isDataRand);
            XDelta = 1/(app.fs*1e6);
            InputZoom = 1;
            XStart = 0;
            Y = [Y.' zeros(1, app.zer)].';
            [baseFileName, folder] = uiputfile([pwd ['.\Signals\wlan_ofdm_FS' num2str(app.fs) 'mhz_BW_' num2str(app.bw) 'mhz' num2str(app.mcs) 'MCS.mat']]);
            fullFileName = fullfile(folder, baseFileName);
            save(fullFileName, "Y", "XDelta", "InputZoom", "XStart")
        end

        % Value changed function: zerosEditField
        function zerosEditFieldValueChanged(app, event)
            app.zer = app.zerosEditField.Value;
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create WLANVHTgenUIFigure and hide until all components are created
            app.WLANVHTgenUIFigure = uifigure('Visible', 'off');
            app.WLANVHTgenUIFigure.Position = [100 100 195 300];
            app.WLANVHTgenUIFigure.Name = 'WLAN VHT gen';

            % Create fsEditFieldLabel
            app.fsEditFieldLabel = uilabel(app.WLANVHTgenUIFigure);
            app.fsEditFieldLabel.HorizontalAlignment = 'right';
            app.fsEditFieldLabel.Position = [25 214 25 22];
            app.fsEditFieldLabel.Text = 'fs';

            % Create fsEditField
            app.fsEditField = uieditfield(app.WLANVHTgenUIFigure, 'numeric');
            app.fsEditField.Limits = [1 Inf];
            app.fsEditField.ValueChangedFcn = createCallbackFcn(app, @fsEditFieldValueChanged, true);
            app.fsEditField.Position = [72 214 58 22];
            app.fsEditField.Value = 60;

            % Create FrameEditFieldLabel
            app.FrameEditFieldLabel = uilabel(app.WLANVHTgenUIFigure);
            app.FrameEditFieldLabel.HorizontalAlignment = 'right';
            app.FrameEditFieldLabel.Position = [17 176 40 22];
            app.FrameEditFieldLabel.Text = 'Frame';

            % Create FrameEditField
            app.FrameEditField = uieditfield(app.WLANVHTgenUIFigure, 'numeric');
            app.FrameEditField.Limits = [0 Inf];
            app.FrameEditField.ValueChangedFcn = createCallbackFcn(app, @FrameEditFieldValueChanged, true);
            app.FrameEditField.Position = [72 176 58 22];
            app.FrameEditField.Value = 500;

            % Create MCSSliderLabel
            app.MCSSliderLabel = uilabel(app.WLANVHTgenUIFigure);
            app.MCSSliderLabel.HorizontalAlignment = 'right';
            app.MCSSliderLabel.Position = [155 235 32 22];
            app.MCSSliderLabel.Text = 'MCS';

            % Create MCSSlider
            app.MCSSlider = uislider(app.WLANVHTgenUIFigure);
            app.MCSSlider.Limits = [0 9];
            app.MCSSlider.MajorTicks = [0 1 2 3 4 5 6 7 8 9];
            app.MCSSlider.Orientation = 'vertical';
            app.MCSSlider.ValueChangedFcn = createCallbackFcn(app, @MCSSliderValueChanged, true);
            app.MCSSlider.MinorTicks = [0 1 2 3 4 5 6 7 8 9];
            app.MCSSlider.Position = [157 70 3 150];
            app.MCSSlider.Value = 4;

            % Create BWListBoxLabel
            app.BWListBoxLabel = uilabel(app.WLANVHTgenUIFigure);
            app.BWListBoxLabel.HorizontalAlignment = 'right';
            app.BWListBoxLabel.Position = [25 133 25 22];
            app.BWListBoxLabel.Text = 'BW';

            % Create BWListBox
            app.BWListBox = uilistbox(app.WLANVHTgenUIFigure);
            app.BWListBox.Items = {'20', '40', '80', '160'};
            app.BWListBox.ValueChangedFcn = createCallbackFcn(app, @BWListBoxValueChanged, true);
            app.BWListBox.Position = [72 83 58 74];
            app.BWListBox.Value = '20';

            % Create RandDataCheckBox
            app.RandDataCheckBox = uicheckbox(app.WLANVHTgenUIFigure);
            app.RandDataCheckBox.ValueChangedFcn = createCallbackFcn(app, @RandDataCheckBoxValueChanged, true);
            app.RandDataCheckBox.Text = 'Rand Data';
            app.RandDataCheckBox.Position = [17 50 79 22];
            app.RandDataCheckBox.Value = true;

            % Create SavesignalButton
            app.SavesignalButton = uibutton(app.WLANVHTgenUIFigure, 'push');
            app.SavesignalButton.ButtonPushedFcn = createCallbackFcn(app, @SavesignalButtonPushed, true);
            app.SavesignalButton.Position = [48 6 100 22];
            app.SavesignalButton.Text = 'Save signal';

            % Create VHTWLANGENLabel
            app.VHTWLANGENLabel = uilabel(app.WLANVHTgenUIFigure);
            app.VHTWLANGENLabel.FontWeight = 'bold';
            app.VHTWLANGENLabel.Position = [53 265 98 22];
            app.VHTWLANGENLabel.Text = 'VHT WLAN GEN';

            % Create zerosEditFieldLabel
            app.zerosEditFieldLabel = uilabel(app.WLANVHTgenUIFigure);
            app.zerosEditFieldLabel.HorizontalAlignment = 'right';
            app.zerosEditFieldLabel.Position = [34 29 35 22];
            app.zerosEditFieldLabel.Text = 'zeros';

            % Create zerosEditField
            app.zerosEditField = uieditfield(app.WLANVHTgenUIFigure, 'numeric');
            app.zerosEditField.Limits = [0 Inf];
            app.zerosEditField.ValueChangedFcn = createCallbackFcn(app, @zerosEditFieldValueChanged, true);
            app.zerosEditField.Position = [84 29 100 22];

            % Show the figure after all components are created
            app.WLANVHTgenUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = WLAN_gen_exported

            runningApp = getRunningApp(app);

            % Check for running singleton app
            if isempty(runningApp)

                % Create UIFigure and components
                createComponents(app)

                % Register the app with App Designer
                registerApp(app, app.WLANVHTgenUIFigure)

                % Execute the startup function
                runStartupFcn(app, @startupFcn)
            else

                % Focus the running singleton app
                figure(runningApp.WLANVHTgenUIFigure)

                app = runningApp;
            end

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.WLANVHTgenUIFigure)
        end
    end
end