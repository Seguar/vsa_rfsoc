classdef PlutoControl_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure               matlab.ui.Figure
        GapEditField           matlab.ui.control.NumericEditField
        GapEditFieldLabel      matlab.ui.control.Label
        FcCWEditField          matlab.ui.control.NumericEditField
        FcCWEditFieldLabel     matlab.ui.control.Label
        UpdateButton           matlab.ui.control.Button
        CustomfileButton       matlab.ui.control.Button
        Gain890EditField       matlab.ui.control.NumericEditField
        Gain890EditFieldLabel  matlab.ui.control.Label
        FsMhzEditField         matlab.ui.control.NumericEditField
        FsMhzEditFieldLabel    matlab.ui.control.Label
        SignalButtonGroup      matlab.ui.container.ButtonGroup
        OffButton              matlab.ui.control.RadioButton
        CustomButton           matlab.ui.control.RadioButton
        OFDMButton             matlab.ui.control.RadioButton
        CWButton               matlab.ui.control.RadioButton
        FcMhzEditField         matlab.ui.control.NumericEditField
        FcMhzEditFieldLabel    matlab.ui.control.Label
    end


    properties (Access = private)
        fc = 5.7e9 % Description
        cwFc = 0;
        fs = 60e6;
        gain = 0;
        state = 'off';
        file;
        path;
        gap = 2000;
        updReq = 0;
    end
    
    properties (Access = public)
        tx % Description
    end
    
    methods (Access = private)
        
        function updatePluto(app)
            app.tx = sdrtx('Pluto');
            app.tx.ShowAdvancedProperties = true;
            app.tx.CenterFrequency = app.fc;
            app.tx.BasebandSampleRate = app.fs;
            app.tx.Gain = app.gain;
            txWaveform = complex(zeros(1000, 1));

            app.state
            switch app.state
                case 'CW'
                    sw = dsp.SineWave;
                    sw.Amplitude = 1;
                    sw.Frequency = app.cwFc;
                    sw.ComplexOutput = true;
                    sw.SampleRate = app.fs;
                    sw.SamplesPerFrame = 50000;
                    txWaveform = sw();                    
                case 'OFDM'
                    [packet]= Signal_Gen(app.fs);
                    sig_org = [packet(:,1)+1j*packet(:,2) ; zeros(1,app.gap)'];
                    sig_org   = sig_org(1:floor(length(sig_org)/24)*24);        
                    txWaveform    = sig_org/max(abs(sig_org));
                case 'Custom'
                    
                case 'Off'
                    release(app.tx)
%                     delete(app.tx)
            end
            if not(isempty(app.tx))
                transmitRepeat(app.tx,txWaveform);
            end
        end
    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            addpath(genpath([pwd '\Packet-Creator-VHT']))
%             while true
%                 if app.updReq
%                     updatePluto(app);
%                     app.updReq = 0;
%                 end
%             drawnow
%             end
        end

        % Value changed function: FcMhzEditField
        function FcMhzEditFieldValueChanged(app, event)
            app.fc = app.FcMhzEditField.Value*1e6;
            app.updReq = 1;
        end

        % Button pushed function: CustomfileButton
        function CustomfileButtonPushed(app, event)
            [app.file, app.path] = uigetfile('*.mat');  %open a mat file
        end

        % Value changed function: FsMhzEditField
        function FsMhzEditFieldValueChanged(app, event)
            app.fs = app.FsMhzEditField.Value*1e6;
            app.updReq = 1;
        end

        % Value changed function: Gain890EditField
        function Gain890EditFieldValueChanged(app, event)
            app.gain = app.Gain890EditField.Value;
            app.updReq = 1;
        end

        % Selection changed function: SignalButtonGroup
        function SignalButtonGroupSelectionChanged(app, event)
            app.state = app.SignalButtonGroup.SelectedObject.Text;
            app.updReq = 1;
        end

        % Button pushed function: UpdateButton
        function UpdateButtonPushed(app, event)
            updatePluto(app)
        end

        % Value changed function: FcCWEditField
        function FcCWEditFieldValueChanged(app, event)
            app.cwFc = app.FcCWEditField.Value;
            app.updReq = 1;
        end

        % Value changed function: GapEditField
        function GapEditFieldValueChanged(app, event)
            app.gap = app.GapEditField.Value;
            app.updReq = 1;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 241 377];
            app.UIFigure.Name = 'MATLAB App';

            % Create FcMhzEditFieldLabel
            app.FcMhzEditFieldLabel = uilabel(app.UIFigure);
            app.FcMhzEditFieldLabel.HorizontalAlignment = 'right';
            app.FcMhzEditFieldLabel.Position = [19 317 53 22];
            app.FcMhzEditFieldLabel.Text = 'Fc (Mhz)';

            % Create FcMhzEditField
            app.FcMhzEditField = uieditfield(app.UIFigure, 'numeric');
            app.FcMhzEditField.ValueChangedFcn = createCallbackFcn(app, @FcMhzEditFieldValueChanged, true);
            app.FcMhzEditField.Position = [87 317 100 22];
            app.FcMhzEditField.Value = 5700;

            % Create SignalButtonGroup
            app.SignalButtonGroup = uibuttongroup(app.UIFigure);
            app.SignalButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @SignalButtonGroupSelectionChanged, true);
            app.SignalButtonGroup.TitlePosition = 'centertop';
            app.SignalButtonGroup.Title = 'Signal';
            app.SignalButtonGroup.Position = [12 28 123 136];

            % Create CWButton
            app.CWButton = uiradiobutton(app.SignalButtonGroup);
            app.CWButton.Text = 'CW';
            app.CWButton.Position = [11 90 58 22];

            % Create OFDMButton
            app.OFDMButton = uiradiobutton(app.SignalButtonGroup);
            app.OFDMButton.Text = 'OFDM';
            app.OFDMButton.Position = [11 68 65 22];

            % Create CustomButton
            app.CustomButton = uiradiobutton(app.SignalButtonGroup);
            app.CustomButton.Text = 'Custom';
            app.CustomButton.Position = [11 46 65 22];

            % Create OffButton
            app.OffButton = uiradiobutton(app.SignalButtonGroup);
            app.OffButton.Text = 'Off';
            app.OffButton.Position = [11 23 38 22];
            app.OffButton.Value = true;

            % Create FsMhzEditFieldLabel
            app.FsMhzEditFieldLabel = uilabel(app.UIFigure);
            app.FsMhzEditFieldLabel.HorizontalAlignment = 'right';
            app.FsMhzEditFieldLabel.Position = [19 267 53 22];
            app.FsMhzEditFieldLabel.Text = 'Fs (Mhz)';

            % Create FsMhzEditField
            app.FsMhzEditField = uieditfield(app.UIFigure, 'numeric');
            app.FsMhzEditField.ValueChangedFcn = createCallbackFcn(app, @FsMhzEditFieldValueChanged, true);
            app.FsMhzEditField.Position = [87 267 100 22];
            app.FsMhzEditField.Value = 60;

            % Create Gain890EditFieldLabel
            app.Gain890EditFieldLabel = uilabel(app.UIFigure);
            app.Gain890EditFieldLabel.HorizontalAlignment = 'right';
            app.Gain890EditFieldLabel.Position = [2 220 70 22];
            app.Gain890EditFieldLabel.Text = 'Gain (-89:0)';

            % Create Gain890EditField
            app.Gain890EditField = uieditfield(app.UIFigure, 'numeric');
            app.Gain890EditField.ValueChangedFcn = createCallbackFcn(app, @Gain890EditFieldValueChanged, true);
            app.Gain890EditField.Position = [87 220 100 22];

            % Create CustomfileButton
            app.CustomfileButton = uibutton(app.UIFigure, 'push');
            app.CustomfileButton.ButtonPushedFcn = createCallbackFcn(app, @CustomfileButtonPushed, true);
            app.CustomfileButton.Position = [139 75 107 20];
            app.CustomfileButton.Text = 'Custom file';

            % Create UpdateButton
            app.UpdateButton = uibutton(app.UIFigure, 'push');
            app.UpdateButton.ButtonPushedFcn = createCallbackFcn(app, @UpdateButtonPushed, true);
            app.UpdateButton.Position = [73 178 100 22];
            app.UpdateButton.Text = 'Update';

            % Create FcCWEditFieldLabel
            app.FcCWEditFieldLabel = uilabel(app.UIFigure);
            app.FcCWEditFieldLabel.HorizontalAlignment = 'right';
            app.FcCWEditFieldLabel.Position = [140 127 42 22];
            app.FcCWEditFieldLabel.Text = 'Fc CW';

            % Create FcCWEditField
            app.FcCWEditField = uieditfield(app.UIFigure, 'numeric');
            app.FcCWEditField.ValueChangedFcn = createCallbackFcn(app, @FcCWEditFieldValueChanged, true);
            app.FcCWEditField.Position = [197 127 45 22];

            % Create GapEditFieldLabel
            app.GapEditFieldLabel = uilabel(app.UIFigure);
            app.GapEditFieldLabel.HorizontalAlignment = 'right';
            app.GapEditFieldLabel.Position = [150 97 28 22];
            app.GapEditFieldLabel.Text = 'Gap';

            % Create GapEditField
            app.GapEditField = uieditfield(app.UIFigure, 'numeric');
            app.GapEditField.ValueChangedFcn = createCallbackFcn(app, @GapEditFieldValueChanged, true);
            app.GapEditField.Position = [193 97 45 22];
            app.GapEditField.Value = 5000;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = PlutoControl_exported

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