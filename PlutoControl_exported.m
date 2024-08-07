classdef PlutoControl_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        PlutoControlUIFigure  matlab.ui.Figure
        DevIdSpinner          matlab.ui.control.Spinner
        DevIdSpinnerLabel     matlab.ui.control.Label
        GapEditField          matlab.ui.control.NumericEditField
        GapEditFieldLabel     matlab.ui.control.Label
        FcCWEditField         matlab.ui.control.NumericEditField
        FcCWEditFieldLabel    matlab.ui.control.Label
        CustomfileButton      matlab.ui.control.Button
        GainKnob              matlab.ui.control.Knob
        GainKnobLabel         matlab.ui.control.Label
        FsMhzSpinner          matlab.ui.control.Spinner
        FsMhzSpinnerLabel     matlab.ui.control.Label
        SignalButtonGroup     matlab.ui.container.ButtonGroup
        OffButton             matlab.ui.control.RadioButton
        CustomButton          matlab.ui.control.RadioButton
        WLANButton            matlab.ui.control.RadioButton
        CWButton              matlab.ui.control.RadioButton
        FcMhzSpinner          matlab.ui.control.Spinner
        FcMhzSpinnerLabel     matlab.ui.control.Label
        ContextMenu           matlab.ui.container.ContextMenu
        WLANsettingsMenu      matlab.ui.container.Menu
    end


    properties (Access = private)
        fc = 5.7e9 % Description
        cwFc = 0;
        fs = 60e6;
        gain = 0;
        state = 'off';
        gap = 2000;    
        devId = 0;
        file = 'ofdm_60mhz.mat'
        Y;
        absPath = fileparts(mfilename('fullpath')); % absolute path to the folder containing the mlapp file
        path = [fileparts(mfilename('fullpath')) '.\Signals\'];
    end

    properties (Access = public)
        tx % Description
    end

    methods (Access = private)

        function updatePluto(app)
            app.tx = sdrtx('Pluto', 'RadioID', ['usb:' num2str(app.devId)]);
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
                case 'WLAN'
                    [packet]= Signal_Gen(app.fs);
                    sig_org = [packet(:,1)+1j*packet(:,2) ; zeros(1,app.gap)'];
                    sig_org   = sig_org(1:floor(length(sig_org)/24)*24);
                    txWaveform    = sig_org/max(abs(sig_org));
                case 'Custom'
                    if isempty(app.Y)
                        disp('No proper signal is selected')
                    end
                    txWaveform = app.Y;
                case 'Off'
                    release(app.tx)
            end
            if (size(txWaveform,1) < size(txWaveform,2))
                txWaveform = txWaveform.';
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
            load([app.path app.file])
            app.Y = Y;
        end

        % Value changed function: FcMhzSpinner
        function FcMhzSpinnerValueChanged(app, event)
            app.fc = app.FcMhzSpinner.Value*1e6;
            updatePluto(app)
        end

        % Button pushed function: CustomfileButton
        function CustomfileButtonPushed(app, event)
            [app.file, app.path] = uigetfile([pwd '.\Signals\*.mat']);  %open a mat file
            load([app.path app.file])
            app.Y = Y;
            updatePluto(app)
        end

        % Value changed function: FsMhzSpinner
        function FsMhzSpinnerValueChanged(app, event)
            app.fs = app.FsMhzSpinner.Value*1e6;
            updatePluto(app)
        end

        % Value changed function: GainKnob
        function GainKnobValueChanged(app, event)
            app.gain = app.GainKnob.Value;
            updatePluto(app)
        end

        % Selection changed function: SignalButtonGroup
        function SignalButtonGroupSelectionChanged(app, event)
            app.state = app.SignalButtonGroup.SelectedObject.Text;
            updatePluto(app)
        end

        % Value changed function: FcCWEditField
        function FcCWEditFieldValueChanged(app, event)
            app.cwFc = app.FcCWEditField.Value;
            updatePluto(app)
        end

        % Value changed function: GapEditField
        function GapEditFieldValueChanged(app, event)
            app.gap = app.GapEditField.Value;
            updatePluto(app)
        end

        % Menu selected function: WLANsettingsMenu
        function WLANsettingsMenuSelected(app, event)
            WLAN_gen
        end

        % Value changed function: DevIdSpinner
        function DevIdSpinnerValueChanged(app, event)
            app.devId = app.DevIdSpinner.Value;
%             release(app.tx)
            updatePluto(app)
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create PlutoControlUIFigure and hide until all components are created
            app.PlutoControlUIFigure = uifigure('Visible', 'off');
            app.PlutoControlUIFigure.Position = [100 100 241 377];
            app.PlutoControlUIFigure.Name = 'Pluto Control';

            % Create FcMhzSpinnerLabel
            app.FcMhzSpinnerLabel = uilabel(app.PlutoControlUIFigure);
            app.FcMhzSpinnerLabel.HorizontalAlignment = 'right';
            app.FcMhzSpinnerLabel.Position = [26 306 53 22];
            app.FcMhzSpinnerLabel.Text = 'Fc (Mhz)';

            % Create FcMhzSpinner
            app.FcMhzSpinner = uispinner(app.PlutoControlUIFigure);
            app.FcMhzSpinner.Limits = [70 6000];
            app.FcMhzSpinner.ValueChangedFcn = createCallbackFcn(app, @FcMhzSpinnerValueChanged, true);
            app.FcMhzSpinner.Position = [88 306 100 22];
            app.FcMhzSpinner.Value = 5700;

            % Create SignalButtonGroup
            app.SignalButtonGroup = uibuttongroup(app.PlutoControlUIFigure);
            app.SignalButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @SignalButtonGroupSelectionChanged, true);
            app.SignalButtonGroup.TitlePosition = 'centertop';
            app.SignalButtonGroup.Title = 'Signal';
            app.SignalButtonGroup.Position = [12 28 123 136];

            % Create CWButton
            app.CWButton = uiradiobutton(app.SignalButtonGroup);
            app.CWButton.Text = 'CW';
            app.CWButton.Position = [11 90 58 22];

            % Create WLANButton
            app.WLANButton = uiradiobutton(app.SignalButtonGroup);
            app.WLANButton.Text = 'WLAN';
            app.WLANButton.Position = [11 68 65 22];

            % Create CustomButton
            app.CustomButton = uiradiobutton(app.SignalButtonGroup);
            app.CustomButton.Text = 'Custom';
            app.CustomButton.Position = [11 46 65 22];

            % Create OffButton
            app.OffButton = uiradiobutton(app.SignalButtonGroup);
            app.OffButton.Text = 'Off';
            app.OffButton.Position = [11 23 38 22];
            app.OffButton.Value = true;

            % Create FsMhzSpinnerLabel
            app.FsMhzSpinnerLabel = uilabel(app.PlutoControlUIFigure);
            app.FsMhzSpinnerLabel.HorizontalAlignment = 'right';
            app.FsMhzSpinnerLabel.Position = [25 267 53 22];
            app.FsMhzSpinnerLabel.Text = 'Fs (Mhz)';

            % Create FsMhzSpinner
            app.FsMhzSpinner = uispinner(app.PlutoControlUIFigure);
            app.FsMhzSpinner.Limits = [1 61.44];
            app.FsMhzSpinner.ValueChangedFcn = createCallbackFcn(app, @FsMhzSpinnerValueChanged, true);
            app.FsMhzSpinner.Position = [87 267 100 22];
            app.FsMhzSpinner.Value = 60;

            % Create GainKnobLabel
            app.GainKnobLabel = uilabel(app.PlutoControlUIFigure);
            app.GainKnobLabel.HorizontalAlignment = 'right';
            app.GainKnobLabel.Position = [28 241 31 22];
            app.GainKnobLabel.Text = 'Gain';

            % Create GainKnob
            app.GainKnob = uiknob(app.PlutoControlUIFigure, 'continuous');
            app.GainKnob.Limits = [-89 0];
            app.GainKnob.ValueChangedFcn = createCallbackFcn(app, @GainKnobValueChanged, true);
            app.GainKnob.Position = [100 184 60 60];

            % Create CustomfileButton
            app.CustomfileButton = uibutton(app.PlutoControlUIFigure, 'push');
            app.CustomfileButton.ButtonPushedFcn = createCallbackFcn(app, @CustomfileButtonPushed, true);
            app.CustomfileButton.Position = [139 75 107 20];
            app.CustomfileButton.Text = 'Custom file';

            % Create FcCWEditFieldLabel
            app.FcCWEditFieldLabel = uilabel(app.PlutoControlUIFigure);
            app.FcCWEditFieldLabel.HorizontalAlignment = 'right';
            app.FcCWEditFieldLabel.Position = [140 127 42 22];
            app.FcCWEditFieldLabel.Text = 'Fc CW';

            % Create FcCWEditField
            app.FcCWEditField = uieditfield(app.PlutoControlUIFigure, 'numeric');
            app.FcCWEditField.ValueChangedFcn = createCallbackFcn(app, @FcCWEditFieldValueChanged, true);
            app.FcCWEditField.Position = [197 127 45 22];

            % Create GapEditFieldLabel
            app.GapEditFieldLabel = uilabel(app.PlutoControlUIFigure);
            app.GapEditFieldLabel.HorizontalAlignment = 'right';
            app.GapEditFieldLabel.Position = [150 97 28 22];
            app.GapEditFieldLabel.Text = 'Gap';

            % Create GapEditField
            app.GapEditField = uieditfield(app.PlutoControlUIFigure, 'numeric');
            app.GapEditField.ValueChangedFcn = createCallbackFcn(app, @GapEditFieldValueChanged, true);
            app.GapEditField.Position = [193 97 45 22];
            app.GapEditField.Value = 5000;

            % Create DevIdSpinnerLabel
            app.DevIdSpinnerLabel = uilabel(app.PlutoControlUIFigure);
            app.DevIdSpinnerLabel.HorizontalAlignment = 'right';
            app.DevIdSpinnerLabel.Position = [35 348 37 22];
            app.DevIdSpinnerLabel.Text = 'DevId';

            % Create DevIdSpinner
            app.DevIdSpinner = uispinner(app.PlutoControlUIFigure);
            app.DevIdSpinner.Limits = [0 64];
            app.DevIdSpinner.RoundFractionalValues = 'on';
            app.DevIdSpinner.ValueChangedFcn = createCallbackFcn(app, @DevIdSpinnerValueChanged, true);
            app.DevIdSpinner.Position = [87 348 100 22];

            % Create ContextMenu
            app.ContextMenu = uicontextmenu(app.PlutoControlUIFigure);

            % Create WLANsettingsMenu
            app.WLANsettingsMenu = uimenu(app.ContextMenu);
            app.WLANsettingsMenu.MenuSelectedFcn = createCallbackFcn(app, @WLANsettingsMenuSelected, true);
            app.WLANsettingsMenu.Text = 'WLAN settings';
            
            % Assign app.ContextMenu
            app.WLANButton.ContextMenu = app.ContextMenu;

            % Show the figure after all components are created
            app.PlutoControlUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = PlutoControl_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.PlutoControlUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.PlutoControlUIFigure)
        end
    end
end