classdef stepper < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure matlab.ui.Figure
        TabGroup matlab.ui.container.TabGroup
        ControlTab matlab.ui.container.Tab
        ConnectionTab matlab.ui.container.Tab
        MotionTab matlab.ui.container.Tab
        MechanicsTab matlab.ui.container.Tab
        RandomTab matlab.ui.container.Tab
        PositionTab matlab.ui.container.Tab
        AdvancedTab matlab.ui.container.Tab

        % Control tab
        Knob matlab.ui.control.Knob
        DegreeEditFieldLabel matlab.ui.control.Label
        DegreeEditField matlab.ui.control.NumericEditField
        degButton matlab.ui.control.Button
        degButton_2 matlab.ui.control.Button
        degButton_3 matlab.ui.control.Button
        degButton_4 matlab.ui.control.Button
        degButton_5 matlab.ui.control.Button
        degButton_6 matlab.ui.control.Button
        Reset0Button matlab.ui.control.Button
        StopButton matlab.ui.control.Button

        % Connection tab
        PortListLabel matlab.ui.control.Label
        PortListDropDown matlab.ui.control.DropDown
        RefreshPortsButton matlab.ui.control.Button
        BaudLabel matlab.ui.control.Label
        BaudDropDown matlab.ui.control.DropDown
        AddressLabel matlab.ui.control.Label
        AddressDropDown matlab.ui.control.DropDown
        VerboseCheckBox matlab.ui.control.CheckBox
        ChoseportandpressthebuttonButton matlab.ui.control.Button
        StatusTextArea matlab.ui.control.TextArea

        % Motion settings tab
        PositionSpeedLabel matlab.ui.control.Label
        PositionSpeedEditField matlab.ui.control.NumericEditField
        AngleLimitLabel matlab.ui.control.Label
        AngleLimitEditField matlab.ui.control.NumericEditField
        Step1Label matlab.ui.control.Label
        Step1EditField matlab.ui.control.NumericEditField
        Step2Label matlab.ui.control.Label
        Step2EditField matlab.ui.control.NumericEditField
        Step3Label matlab.ui.control.Label
        Step3EditField matlab.ui.control.NumericEditField
        ApplyMotionSettingsButton matlab.ui.control.Button

        % Mechanics settings tab
        MotorStepsPerRevLabel matlab.ui.control.Label
        MotorStepsPerRevEditField matlab.ui.control.NumericEditField
        SubdivisionLabel matlab.ui.control.Label
        SubdivisionEditField matlab.ui.control.NumericEditField
        Gear1TeethLabel matlab.ui.control.Label
        Gear1TeethEditField matlab.ui.control.NumericEditField
        Gear2TeethLabel matlab.ui.control.Label
        Gear2TeethEditField matlab.ui.control.NumericEditField
        DegPerPulseLabel matlab.ui.control.Label
        DegPerPulseEditField matlab.ui.control.NumericEditField
        ApplyMechanicsSettingsButton matlab.ui.control.Button
        SendSubdivisionButton matlab.ui.control.Button

        % Random movement tab
        RandomMinStepLabel matlab.ui.control.Label
        RandomMinStepEditField matlab.ui.control.NumericEditField
        RandomMaxStepLabel matlab.ui.control.Label
        RandomMaxStepEditField matlab.ui.control.NumericEditField
        RandomPeriodLabel matlab.ui.control.Label
        RandomPeriodEditField matlab.ui.control.NumericEditField
        RandomConstrainedCheckBox matlab.ui.control.CheckBox
        RandomStartButton matlab.ui.control.Button
        RandomStopButton matlab.ui.control.Button
        RandomStatusLabel matlab.ui.control.Label

        % Position / calibration tab
        CurrentPositionLabel matlab.ui.control.Label
        CurrentPositionEditField matlab.ui.control.NumericEditField
        SetCurrentPositionButton matlab.ui.control.Button
        ResetCurrentPositionButton matlab.ui.control.Button
        AcquireCurrentPositionButton matlab.ui.control.Button
        MirrorDisplayCheckBox matlab.ui.control.CheckBox
        PositionInfoLabel matlab.ui.control.Label

        % Advanced/test tab
        EnableButton matlab.ui.control.Button
        DisableButton matlab.ui.control.Button
        EmergencyStopButton matlab.ui.control.Button
        ClearStatusButton matlab.ui.control.Button
        RawPacketLabel matlab.ui.control.Label
        RawPacketEditField matlab.ui.control.EditField
        SendRawPacketButton matlab.ui.control.Button
        ReadEncoderButton matlab.ui.control.Button
    end

    properties (Access = public)
        port = [];
        portList = [];
        Arduino = [];              % serialport object, kept name for compatibility with VSA app
        angle = 0;                 % logical mechanical angle in degrees
        angleLims = 180;

        % MKS SERVO42C UART protocol settings.
        MksAddress uint8 = uint8(hex2dec('E0'));
        MksBaud double = 9600;
        MksPositionSpeed double = 15;      % 0..127, command speed byte uses bit 7 for reverse
        MksMotorStepsPerRev double = 200;  % 1.8 degree motor
        MksSubdivision double = 16;        % microstep subdivision configured in driver
        MksGear1Teeth double = 30;         % motor gear teeth
        MksGear2Teeth double = 60;         % output gear teeth
        MksVerbose logical = false;

        % UI step buttons in degrees
        Step1Deg double = 1;
        Step2Deg double = 10;
        Step3Deg double = 90;

        % Random movement mode, based on the MKS reference timer pattern.
        RandomTimer = [];
        RandomModeEnabled logical = false;
        RandomMinStepDeg double = 1;
        RandomMaxStepDeg double = 30;
        RandomPeriodSec double = 1.0;
        RandomConstrained logical = true;

        % Display coordinate option. When enabled, UI degrees are mirrored:
        % displayed angle = -motor/logical angle. Motor protocol commands stay unchanged.
        MirrorDisplayedDegrees logical = false;
    end

    methods (Access = public)

        function displayAngle = motorToDisplayAngle(app, motorAngle)
            if app.MirrorDisplayedDegrees
                displayAngle = -double(motorAngle);
            else
                displayAngle = double(motorAngle);
            end
        end

        function motorAngle = displayToMotorAngle(app, displayAngle)
            if app.MirrorDisplayedDegrees
                motorAngle = -double(displayAngle);
            else
                motorAngle = double(displayAngle);
            end
        end

        function updateFields(app)
            app.angle = max(-app.angleLims, min(app.angleLims, app.angle));
            displayAngle = app.motorToDisplayAngle(app.angle);
            if ~isempty(app.Knob) && isvalid(app.Knob)
                app.Knob.Limits = [-app.angleLims app.angleLims];
                app.Knob.Value = displayAngle;
            end
            if ~isempty(app.DegreeEditField) && isvalid(app.DegreeEditField)
                app.DegreeEditField.Limits = [-app.angleLims app.angleLims];
                app.DegreeEditField.Value = displayAngle;
            end
            if ~isempty(app.CurrentPositionEditField) && isvalid(app.CurrentPositionEditField)
                app.CurrentPositionEditField.Limits = [-app.angleLims app.angleLims];
                app.CurrentPositionEditField.Value = displayAngle;
            end
            if ~isempty(app.PositionInfoLabel) && isvalid(app.PositionInfoLabel)
                if app.MirrorDisplayedDegrees
                    app.PositionInfoLabel.Text = sprintf('Displayed position: %.6g deg | motor/internal: %.6g deg | mirrored display ON', displayAngle, app.angle);
                else
                    app.PositionInfoLabel.Text = sprintf('Displayed position: %.6g deg | motor/internal: %.6g deg | mirrored display OFF', displayAngle, app.angle);
                end
            end
        end

        function tf = isConnected(app)
            tf = ~isempty(app.Arduino) && isvalid(app.Arduino);
        end

        function logStatus(app, msg)
            line = string(sprintf('[%s] %s', datestr(now, 'HH:MM:SS'), char(msg)));
            try
                old = string(app.StatusTextArea.Value);
                app.StatusTextArea.Value = [old; line];
                if numel(app.StatusTextArea.Value) > 150
                    app.StatusTextArea.Value = app.StatusTextArea.Value(end-149:end);
                end
                drawnow limitrate nocallbacks;
            catch
                disp(line);
            end
        end

        function chk = checksum(~, vec)
            % MKS checksum: low byte of sum(address + command + payload).
            chk = uint8(mod(sum(double(uint8(vec))), 256));
        end

        function s = hexString(~, vec)
            if isempty(vec)
                s = '';
                return;
            end
            s = strjoin(arrayfun(@(b)sprintf('%02X', b), uint8(vec), 'UniformOutput', false), ' ');
        end

        function ok = writePacket(app, payload)
            % payload must be [address command data...], checksum is appended here.
            ok = false;
            if ~isConnected(app)
                uialert(app.UIFigure, 'Stepper serial port is not connected.', 'Serial error');
                return;
            end
            packet = uint8([payload app.checksum(payload)]);
            try
                write(app.Arduino, packet, 'uint8');
                ok = true;
                if app.MksVerbose
                    app.logStatus(['MKS TX: ' app.hexString(packet)]);
                end
            catch ME
                uialert(app.UIFigure, ['MKS serial write failed: ' ME.message], 'Serial error');
            end
        end

        function [angleDeg, degPerPulse] = pulsesToRealAngle(app, pulses)
            if app.MksSubdivision <= 0 || app.MksMotorStepsPerRev <= 0 || app.MksGear1Teeth <= 0 || app.MksGear2Teeth <= 0
                angleDeg = NaN;
                degPerPulse = NaN;
                return;
            end
            degPerPulse = (360.0 / (app.MksMotorStepsPerRev * app.MksSubdivision)) * (app.MksGear1Teeth / app.MksGear2Teeth);
            angleDeg = double(pulses) * degPerPulse;
        end

        function pulses = angleToPulses(app, angleDeg)
            [~, degPerPulse] = app.pulsesToRealAngle(1);
            if isnan(degPerPulse) || degPerPulse <= 0
                pulses = NaN;
                return;
            end
            pulses = round(abs(angleDeg) / degPerPulse);
        end

        function syncSettingsFromUi(app)
            % Read all editable settings from tabs into app properties.
            try
                app.MksBaud = str2double(app.BaudDropDown.Value);
            catch
            end
            try
                app.MksAddress = uint8(hex2dec(erase(app.AddressDropDown.Value, '0x')));
            catch
            end
            app.MksVerbose = logical(app.VerboseCheckBox.Value);
            app.MksPositionSpeed = double(app.PositionSpeedEditField.Value);
            app.angleLims = abs(double(app.AngleLimitEditField.Value));
            app.Step1Deg = abs(double(app.Step1EditField.Value));
            app.Step2Deg = abs(double(app.Step2EditField.Value));
            app.Step3Deg = abs(double(app.Step3EditField.Value));
            if ~isempty(app.RandomMinStepEditField) && isvalid(app.RandomMinStepEditField)
                app.RandomMinStepDeg = abs(double(app.RandomMinStepEditField.Value));
                app.RandomMaxStepDeg = abs(double(app.RandomMaxStepEditField.Value));
                app.RandomPeriodSec = double(app.RandomPeriodEditField.Value);
                app.RandomConstrained = logical(app.RandomConstrainedCheckBox.Value);
            end
            if ~isempty(app.MirrorDisplayCheckBox) && isvalid(app.MirrorDisplayCheckBox)
                app.MirrorDisplayedDegrees = logical(app.MirrorDisplayCheckBox.Value);
            end
            app.MksMotorStepsPerRev = double(app.MotorStepsPerRevEditField.Value);
            app.MksSubdivision = double(app.SubdivisionEditField.Value);
            app.MksGear1Teeth = double(app.Gear1TeethEditField.Value);
            app.MksGear2Teeth = double(app.Gear2TeethEditField.Value);
            app.updateDegPerPulseField();
            app.updateStepButtonText();
            app.updateFields();
        end

        function syncUiFromSettings(app)
            baudItems = {'9600','19200','25000','38400','57600','115200'};
            app.BaudDropDown.Items = baudItems;
            b = sprintf('%d', app.MksBaud);
            if ~any(strcmp(baudItems, b))
                app.BaudDropDown.Items = [baudItems {b}];
            end
            app.BaudDropDown.Value = b;
            app.AddressDropDown.Items = arrayfun(@(v)sprintf('0x%X', v), hex2dec('E0'):hex2dec('E9'), 'UniformOutput', false);
            app.AddressDropDown.Value = sprintf('0x%X', double(app.MksAddress));
            app.VerboseCheckBox.Value = app.MksVerbose;
            app.PositionSpeedEditField.Value = app.MksPositionSpeed;
            app.AngleLimitEditField.Value = app.angleLims;
            app.Step1EditField.Value = app.Step1Deg;
            app.Step2EditField.Value = app.Step2Deg;
            app.Step3EditField.Value = app.Step3Deg;
            if ~isempty(app.RandomMinStepEditField) && isvalid(app.RandomMinStepEditField)
                app.RandomMinStepEditField.Value = app.RandomMinStepDeg;
                app.RandomMaxStepEditField.Value = app.RandomMaxStepDeg;
                app.RandomPeriodEditField.Value = app.RandomPeriodSec;
                app.RandomConstrainedCheckBox.Value = app.RandomConstrained;
            end
            if ~isempty(app.MirrorDisplayCheckBox) && isvalid(app.MirrorDisplayCheckBox)
                app.MirrorDisplayCheckBox.Value = app.MirrorDisplayedDegrees;
            end
            app.MotorStepsPerRevEditField.Value = app.MksMotorStepsPerRev;
            app.SubdivisionEditField.Value = app.MksSubdivision;
            app.Gear1TeethEditField.Value = app.MksGear1Teeth;
            app.Gear2TeethEditField.Value = app.MksGear2Teeth;
            app.updateDegPerPulseField();
            app.updateStepButtonText();
            app.updateFields();
        end

        function updateDegPerPulseField(app)
            [~, degPerPulse] = app.pulsesToRealAngle(1);
            if ~isempty(app.DegPerPulseEditField) && isvalid(app.DegPerPulseEditField)
                app.DegPerPulseEditField.Value = degPerPulse;
            end
        end

        function updateStepButtonText(app)
            if ~isempty(app.degButton) && isvalid(app.degButton)
                app.degButton.Text = sprintf('-%g deg', app.Step1Deg);
                app.degButton_4.Text = sprintf('+%g deg', app.Step1Deg);
                app.degButton_2.Text = sprintf('-%g deg', app.Step2Deg);
                app.degButton_5.Text = sprintf('+%g deg', app.Step2Deg);
                app.degButton_3.Text = sprintf('-%g deg', app.Step3Deg);
                app.degButton_6.Text = sprintf('+%g deg', app.Step3Deg);
            end
        end

        function ok = validateMotionSettings(app)
            ok = false;
            if isnan(app.MksPositionSpeed) || app.MksPositionSpeed < 0 || app.MksPositionSpeed > 127
                uialert(app.UIFigure, 'MKS position speed must be in the range 0..127.', 'Input error');
                return;
            end
            if isnan(app.angleLims) || app.angleLims <= 0
                uialert(app.UIFigure, 'Angle limit must be positive.', 'Input error');
                return;
            end
            if any(isnan([app.Step1Deg app.Step2Deg app.Step3Deg])) || any([app.Step1Deg app.Step2Deg app.Step3Deg] <= 0)
                uialert(app.UIFigure, 'Step button values must be positive.', 'Input error');
                return;
            end
            if any(isnan([app.RandomMinStepDeg app.RandomMaxStepDeg app.RandomPeriodSec])) || app.RandomMinStepDeg <= 0 || app.RandomMaxStepDeg <= 0 || app.RandomMinStepDeg > app.RandomMaxStepDeg || app.RandomPeriodSec < 0.05
                uialert(app.UIFigure, 'Random settings must be valid: min/max > 0, min <= max, period >= 0.05 s.', 'Input error');
                return;
            end
            ok = true;
        end

        function ok = validateMechanicsSettings(app)
            ok = false;
            if any(isnan([app.MksMotorStepsPerRev app.MksSubdivision app.MksGear1Teeth app.MksGear2Teeth]))
                uialert(app.UIFigure, 'Mechanical settings must be numeric.', 'Input error');
                return;
            end
            if app.MksMotorStepsPerRev <= 0 || app.MksSubdivision < 1 || app.MksSubdivision > 256 || app.MksGear1Teeth <= 0 || app.MksGear2Teeth <= 0
                uialert(app.UIFigure, 'Check mechanics: steps/rev > 0, subdivision 1..256, gear teeth > 0.', 'Input error');
                return;
            end
            ok = true;
        end

        function ok = sendMoveDelta(app, deltaAngleDeg)
            % Relative position command, equivalent to MKS SERVO42C command 0xFD.
            ok = false;
            syncSettingsFromUi(app);
            if ~validateMotionSettings(app) || ~validateMechanicsSettings(app)
                return;
            end
            if abs(deltaAngleDeg) < 1e-9
                ok = true;
                return;
            end
            pulseCount = app.angleToPulses(deltaAngleDeg);
            if isnan(pulseCount) || pulseCount < 1 || pulseCount > 4294967294
                uialert(app.UIFigure, 'Pulse count is out of range. Check microstep / gear settings.', 'Input error');
                return;
            end

            FWD = uint8(0);
            RWD = uint8(128);
            if deltaAngleDeg >= 0
                speedByte = bitor(uint8(app.MksPositionSpeed), FWD);
            else
                speedByte = bitor(uint8(app.MksPositionSpeed), RWD);
            end

            raw = typecast(uint32(pulseCount), 'uint8');  % MATLAB host endian -> send big endian below
            payload = uint8([app.MksAddress uint8(hex2dec('FD')) speedByte raw(4) raw(3) raw(2) raw(1)]);
            ok = app.writePacket(payload);
            if ok
                app.logStatus(sprintf('Move %.6g deg => %u pulses', deltaAngleDeg, pulseCount));
            end
        end

        function setAngle(app, displayValue)
            % Absolute displayed-angle move. Internally app.angle remains the
            % motor/protocol angle. If mirrored display is enabled, a displayed
            % +X degree command maps to motor/internal -X degrees.
            syncSettingsFromUi(app);
            displayValue = double(displayValue);
            displayValue = max(-app.angleLims, min(app.angleLims, displayValue));
            motorTarget = app.displayToMotorAngle(displayValue);
            motorTarget = max(-app.angleLims, min(app.angleLims, motorTarget));
            delta = motorTarget - app.angle;
            if sendMoveDelta(app, delta)
                app.angle = motorTarget;
                updateFields(app);
            end
        end

        function moveByStep(app, deltaAngleDeg)
            syncSettingsFromUi(app);
            targetDisplay = app.motorToDisplayAngle(app.angle) + double(deltaAngleDeg);
            if targetDisplay < -app.angleLims || targetDisplay > app.angleLims
                app.logStatus('Move ignored: displayed angle limit reached.');
                return;
            end
            setAngle(app, targetDisplay);
        end

        function stopMotor(app)
            % MKS stop command 0xF7.
            payload = uint8([app.MksAddress uint8(hex2dec('F7'))]);
            app.writePacket(payload);
        end

        function enableMotor(app, enabled)
            % MKS enable command 0xF3, payload 1=enable, 0=disable.
            if enabled
                en = uint8(1);
            else
                en = uint8(0);
            end
            payload = uint8([app.MksAddress uint8(hex2dec('F3')) en]);
            app.writePacket(payload);
        end

        function sendSubdivisionToDriver(app)
            % MKS subdivision command 0x84, payload = subdivision byte, 1..256.
            syncSettingsFromUi(app);
            if ~validateMechanicsSettings(app)
                return;
            end
            payload = uint8([app.MksAddress uint8(hex2dec('84')) uint8(app.MksSubdivision)]);
            if app.writePacket(payload)
                app.logStatus(sprintf('Subdivision sent to driver: %d', app.MksSubdivision));
            end
        end

        function sendRawPayload(app)
            txt = char(app.RawPacketEditField.Value);
            tokens = regexp(txt, '[0-9A-Fa-f]{1,2}', 'match');
            if isempty(tokens)
                uialert(app.UIFigure, 'Enter hex bytes, for example: E0 F7', 'Raw packet');
                return;
            end
            bytes = uint8(hex2dec(tokens));
            if numel(bytes) < 2
                uialert(app.UIFigure, 'Raw payload must include at least address and command.', 'Raw packet');
                return;
            end
            app.writePacket(bytes(:).');
        end


        function setCurrentPositionFromField(app)
            % Calibration only: does not move the motor. It tells the app what
            % the current mechanical angle should be considered to be.
            syncSettingsFromUi(app);
            displayValue = max(-app.angleLims, min(app.angleLims, double(app.CurrentPositionEditField.Value)));
            app.angle = max(-app.angleLims, min(app.angleLims, app.displayToMotorAngle(displayValue)));
            updateFields(app);
            app.logStatus(sprintf('Current displayed position set to %.6g deg, motor/internal %.6g deg (no motor movement).', displayValue, app.angle));
        end

        function resetCurrentPositionZero(app)
            % Calibration only: define the present physical position as 0 deg.
            % This is different from Move to 0, which physically moves the motor.
            app.angle = 0;
            updateFields(app);
            app.logStatus('Current logical position reset to 0 deg (no motor movement).');
        end

        function queryAndSetCurrentPosition(app)
            % MKS reference uses command 0x36 to query position/encoder value.
            % If a valid response is available, parse bytes 2..5 as a uint32
            % pulse count and convert it to a logical angle using mechanics settings.
            syncSettingsFromUi(app);
            if ~isConnected(app)
                uialert(app.UIFigure, 'Stepper serial port is not connected.', 'Serial error');
                return;
            end
            payload = uint8([app.MksAddress uint8(hex2dec('36'))]);
            if ~app.writePacket(payload)
                return;
            end
            pause(0.08);
            try
                n = app.Arduino.NumBytesAvailable;
                if n < 5
                    app.logStatus('Position query sent, but response was too short to parse.');
                    return;
                end
                rx = read(app.Arduino, n, 'uint8');
                if app.MksVerbose
                    app.logStatus(['MKS RX: ' app.hexString(rx)]);
                end
                posU32 = bitshift(uint32(rx(2)), 24) + bitshift(uint32(rx(3)), 16) + bitshift(uint32(rx(4)), 8) + uint32(rx(5));
                [angleDeg, ~] = app.pulsesToRealAngle(double(posU32));
                if isnan(angleDeg)
                    app.logStatus('Position query parse failed: invalid mechanics settings.');
                    return;
                end
                app.angle = max(-app.angleLims, min(app.angleLims, angleDeg));
                updateFields(app);
                app.logStatus(sprintf('Current position acquired from motor: %u pulses => motor/internal %.6g deg, displayed %.6g deg.', posU32, app.angle, app.motorToDisplayAngle(app.angle)));
            catch ME
                app.logStatus(['Position query parse failed: ' ME.message]);
            end
        end

        function [targetPos, ok] = chooseConstrainedRandomTarget(app)
            % Based on the MKS reference app: choose a random target within
            % calibrated limits and keep the move length between min/max.
            ok = false;
            targetPos = app.motorToDisplayAngle(app.angle);
            low = -app.angleLims;
            high = app.angleLims;
            cur = max(low, min(high, app.motorToDisplayAngle(app.angle)));
            minStep = app.RandomMinStepDeg;
            maxStep = app.RandomMaxStepDeg;

            if low >= high
                return;
            end

            for k = 1:30
                candidate = low + rand() * (high - low);
                delta = abs(candidate - cur);
                if delta >= minStep && delta <= maxStep
                    targetPos = candidate;
                    ok = true;
                    return;
                end
            end

            % Deterministic fallback if the random draw did not find a good point.
            forwardCandidate = min(high, cur + max(minStep, 0.01));
            reverseCandidate = max(low, cur - max(minStep, 0.01));
            if abs(forwardCandidate - cur) >= 0.01 && abs(forwardCandidate - cur) <= maxStep
                targetPos = forwardCandidate;
                ok = true;
            elseif abs(reverseCandidate - cur) >= 0.01 && abs(reverseCandidate - cur) <= maxStep
                targetPos = reverseCandidate;
                ok = true;
            end
        end

        function startRandomMode(app)
            syncSettingsFromUi(app);
            if ~isConnected(app)
                uialert(app.UIFigure, 'Stepper serial port is not connected.', 'Serial error');
                return;
            end
            if ~validateMotionSettings(app) || ~validateMechanicsSettings(app)
                return;
            end
            app.stopRandomMode();
            app.RandomTimer = timer('ExecutionMode', 'fixedRate', ...
                'Period', app.RandomPeriodSec, ...
                'TimerFcn', @(~,~)app.randomMoveTick());
            start(app.RandomTimer);
            app.RandomModeEnabled = true;
            if ~isempty(app.RandomStartButton) && isvalid(app.RandomStartButton)
                app.RandomStartButton.Enable = 'off';
            end
            if ~isempty(app.RandomStopButton) && isvalid(app.RandomStopButton)
                app.RandomStopButton.Enable = 'on';
            end
            if ~isempty(app.RandomStatusLabel) && isvalid(app.RandomStatusLabel)
                app.RandomStatusLabel.Text = 'Random mode running';
            end
            app.logStatus(sprintf('Random mode ON: step %.6g..%.6g deg, period %.3g s, constrained=%d.', app.RandomMinStepDeg, app.RandomMaxStepDeg, app.RandomPeriodSec, app.RandomConstrained));
        end

        function stopRandomMode(app)
            if ~isempty(app.RandomTimer)
                try
                    if isvalid(app.RandomTimer)
                        stop(app.RandomTimer);
                        delete(app.RandomTimer);
                    end
                catch
                end
                app.RandomTimer = [];
            end
            wasOn = app.RandomModeEnabled;
            app.RandomModeEnabled = false;
            if ~isempty(app.RandomStartButton) && isvalid(app.RandomStartButton)
                app.RandomStartButton.Enable = 'on';
            end
            if ~isempty(app.RandomStopButton) && isvalid(app.RandomStopButton)
                app.RandomStopButton.Enable = 'off';
            end
            if ~isempty(app.RandomStatusLabel) && isvalid(app.RandomStatusLabel)
                app.RandomStatusLabel.Text = 'Random mode stopped';
            end
            if wasOn && ~isempty(app.StatusTextArea) && isvalid(app.StatusTextArea)
                app.logStatus('Random mode OFF.');
            end
        end

        function randomMoveTick(app)
            if ~isConnected(app)
                app.stopRandomMode();
                return;
            end
            syncSettingsFromUi(app);
            if app.RandomConstrained
                [targetPos, ok] = app.chooseConstrainedRandomTarget();
                if ~ok
                    app.logStatus('Random tick skipped: unable to find target inside limits.');
                    return;
                end
                setAngle(app, targetPos);
                if ~isempty(app.RandomStatusLabel) && isvalid(app.RandomStatusLabel)
                    app.RandomStatusLabel.Text = sprintf('Target %.3f deg', targetPos);
                end
            else
                step = app.RandomMinStepDeg + rand() * (app.RandomMaxStepDeg - app.RandomMinStepDeg);
                if rand() < 0.5
                    step = -step;
                end
                moveByStep(app, step);
                if ~isempty(app.RandomStatusLabel) && isvalid(app.RandomStatusLabel)
                    app.RandomStatusLabel.Text = sprintf('Step %.3f deg', step);
                end
            end
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            cd(fileparts(mfilename('fullpath')))
            app.syncUiFromSettings();
            PortListDropDownOpening(app, []);
            app.logStatus('Stepper app initialized with MKS SERVO42C protocol, random mode, current-position reset, and mirrored degree display.');
        end

        % Drop down opening function: PortListDropDown
        function PortListDropDownOpening(app, event)
            try
                app.portList = serialportlist("available");
            catch
                app.portList = strings(0,1);
            end
            if isempty(app.portList)
                app.PortListDropDown.Items = {'No ports'};
                app.PortListDropDown.Value = 'No ports';
                app.port = [];
            else
                app.PortListDropDown.Items = cellstr(app.portList);
                if isempty(app.port) || ~any(strcmp(app.PortListDropDown.Items, app.port))
                    app.port = app.PortListDropDown.Items{1};
                end
                app.PortListDropDown.Value = app.port;
            end
        end

        % Button pushed function: ChoseportandpressthebuttonButton
        function ChoseportandpressthebuttonButtonPushed(app, event)
            syncSettingsFromUi(app);
            if ~isConnected(app)
                if isempty(app.port) || strcmp(app.port, 'No ports')
                    PortListDropDownOpening(app, event);
                end
                if isempty(app.port) || strcmp(app.port, 'No ports')
                    uialert(app.UIFigure, 'No serial port selected.', 'Serial error');
                    return;
                end
                try
                    app.Arduino = serialport(app.port, app.MksBaud);
                    flush(app.Arduino);
                    app.ChoseportandpressthebuttonButton.Text = [string(app.port) " connected"];
                    app.ChoseportandpressthebuttonButton.BackgroundColor = 'g';
                    enableMotor(app, true);
                    app.logStatus(sprintf('Connected to %s @ %.0f, address 0x%X', app.port, app.MksBaud, app.MksAddress));
                catch ME
                    app.Arduino = [];
                    uialert(app.UIFigure, ['Connection failed: ' ME.message], 'Serial error');
                end
            else
                try
                    stopMotor(app);
                    enableMotor(app, false);
                catch
                end
                try
                    delete(app.Arduino);
                catch
                end
                app.Arduino = [];
                app.ChoseportandpressthebuttonButton.Text = "Disconnected";
                app.ChoseportandpressthebuttonButton.BackgroundColor = 'r';
                app.logStatus('Disconnected.');
            end
        end

        % Callback function: PortListDropDown, PortListDropDown
        function PortListDropDownValueChanged(app, event)
            app.port = app.PortListDropDown.Value;
        end

        function SettingsValueChanged(app, event)
            oldMirror = app.MirrorDisplayedDegrees;
            syncSettingsFromUi(app);
            updateFields(app);
            if oldMirror ~= app.MirrorDisplayedDegrees
                if app.MirrorDisplayedDegrees
                    app.logStatus('Mirrored displayed degrees enabled. Motor/internal angle is unchanged.');
                else
                    app.logStatus('Mirrored displayed degrees disabled. Motor/internal angle is unchanged.');
                end
            end
        end

        % Value changed function: Knob
        function KnobValueChanged(app, event)
            setAngle(app, app.Knob.Value);
        end

        % Value changed function: DegreeEditField
        function DegreeEditFieldValueChanged(app, event)
            setAngle(app, app.DegreeEditField.Value);
        end

        % Button pushed function: Reset0Button
        function Reset0ButtonPushed(app, event)
            setAngle(app, 0);
        end

        function StopButtonPushed(app, event)
            stopMotor(app);
        end

        % Button pushed function: DisableButton
        function DisableButtonPushed(app, event)
            stopMotor(app);
            enableMotor(app, false);
        end

        function EnableButtonPushed(app, event)
            enableMotor(app, true);
        end

        % Button pushed function: degButton
        function degButtonPushed(app, event)
            moveByStep(app, -app.Step1Deg);
        end

        % Button pushed function: degButton_2
        function degButton_2Pushed(app, event)
            moveByStep(app, -app.Step2Deg);
        end

        % Button pushed function: degButton_3
        function degButton_3Pushed(app, event)
            moveByStep(app, -app.Step3Deg);
        end

        % Button pushed function: degButton_4
        function degButton_4Pushed(app, event)
            moveByStep(app, app.Step1Deg);
        end

        % Button pushed function: degButton_5
        function degButton_5Pushed(app, event)
            moveByStep(app, app.Step2Deg);
        end

        % Button pushed function: degButton_6
        function degButton_6Pushed(app, event)
            moveByStep(app, app.Step3Deg);
        end

        function ApplyMotionSettingsButtonPushed(app, event)
            syncSettingsFromUi(app);
            if validateMotionSettings(app)
                app.logStatus('Motion settings applied.');
            end
        end

        function ApplyMechanicsSettingsButtonPushed(app, event)
            syncSettingsFromUi(app);
            if validateMechanicsSettings(app)
                app.logStatus('Mechanics settings applied.');
            end
        end

        function SendSubdivisionButtonPushed(app, event)
            sendSubdivisionToDriver(app);
        end

        function ClearStatusButtonPushed(app, event)
            app.StatusTextArea.Value = string.empty(0,1);
        end

        function SendRawPacketButtonPushed(app, event)
            sendRawPayload(app);
        end


        function StartRandomButtonPushed(app, event)
            startRandomMode(app);
        end

        function StopRandomButtonPushed(app, event)
            stopRandomMode(app);
        end

        function RandomSettingsValueChanged(app, event)
            syncSettingsFromUi(app);
        end

        function SetCurrentPositionButtonPushed(app, event)
            setCurrentPositionFromField(app);
        end

        function ResetCurrentPositionButtonPushed(app, event)
            resetCurrentPositionZero(app);
        end

        function AcquireCurrentPositionButtonPushed(app, event)
            queryAndSetCurrentPosition(app);
        end

        function ReadEncoderButtonPushed(app, event)
            queryAndSetCurrentPosition(app);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 720 760];
            app.UIFigure.Name = 'Stepper MKS SERVO42C';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [1 1 720 760];

            % Create tabs
            app.ControlTab = uitab(app.TabGroup);
            app.ControlTab.Title = 'Control';
            app.ConnectionTab = uitab(app.TabGroup);
            app.ConnectionTab.Title = 'Connection';
            app.MotionTab = uitab(app.TabGroup);
            app.MotionTab.Title = 'Motion';
            app.MechanicsTab = uitab(app.TabGroup);
            app.MechanicsTab.Title = 'Mechanics';
            app.RandomTab = uitab(app.TabGroup);
            app.RandomTab.Title = 'Random';
            app.PositionTab = uitab(app.TabGroup);
            app.PositionTab.Title = 'Position';
            app.AdvancedTab = uitab(app.TabGroup);
            app.AdvancedTab.Title = 'Advanced';

            % ---------------- Control tab ----------------
            app.Knob = uiknob(app.ControlTab, 'continuous');
            app.Knob.Limits = [-180 180];
            app.Knob.ValueChangedFcn = createCallbackFcn(app, @KnobValueChanged, true);
            app.Knob.Position = [165 250 380 380];

            app.DegreeEditFieldLabel = uilabel(app.ControlTab);
            app.DegreeEditFieldLabel.HorizontalAlignment = 'right';
            app.DegreeEditFieldLabel.Position = [255 205 50 22];
            app.DegreeEditFieldLabel.Text = 'Degree';

            app.DegreeEditField = uieditfield(app.ControlTab, 'numeric');
            app.DegreeEditField.ValueChangedFcn = createCallbackFcn(app, @DegreeEditFieldValueChanged, true);
            app.DegreeEditField.Position = [320 205 120 22];

            app.degButton = uibutton(app.ControlTab, 'push');
            app.degButton.ButtonPushedFcn = createCallbackFcn(app, @degButtonPushed, true);
            app.degButton.Position = [205 155 100 25];
            app.degButton.Text = '-1 deg';

            app.degButton_4 = uibutton(app.ControlTab, 'push');
            app.degButton_4.ButtonPushedFcn = createCallbackFcn(app, @degButton_4Pushed, true);
            app.degButton_4.Position = [415 155 100 25];
            app.degButton_4.Text = '+1 deg';

            app.degButton_2 = uibutton(app.ControlTab, 'push');
            app.degButton_2.ButtonPushedFcn = createCallbackFcn(app, @degButton_2Pushed, true);
            app.degButton_2.Position = [205 120 100 25];
            app.degButton_2.Text = '-10 deg';

            app.degButton_5 = uibutton(app.ControlTab, 'push');
            app.degButton_5.ButtonPushedFcn = createCallbackFcn(app, @degButton_5Pushed, true);
            app.degButton_5.Position = [415 120 100 25];
            app.degButton_5.Text = '+10 deg';

            app.degButton_3 = uibutton(app.ControlTab, 'push');
            app.degButton_3.ButtonPushedFcn = createCallbackFcn(app, @degButton_3Pushed, true);
            app.degButton_3.Position = [205 85 100 25];
            app.degButton_3.Text = '-90 deg';

            app.degButton_6 = uibutton(app.ControlTab, 'push');
            app.degButton_6.ButtonPushedFcn = createCallbackFcn(app, @degButton_6Pushed, true);
            app.degButton_6.Position = [415 85 100 25];
            app.degButton_6.Text = '+90 deg';

            app.Reset0Button = uibutton(app.ControlTab, 'push');
            app.Reset0Button.ButtonPushedFcn = createCallbackFcn(app, @Reset0ButtonPushed, true);
            app.Reset0Button.Position = [310 85 90 25];
            app.Reset0Button.Text = 'Move to 0';

            app.StopButton = uibutton(app.ControlTab, 'push');
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonPushed, true);
            app.StopButton.Position = [310 50 90 25];
            app.StopButton.Text = 'Stop';

            % ---------------- Connection tab ----------------
            app.PortListLabel = uilabel(app.ConnectionTab);
            app.PortListLabel.HorizontalAlignment = 'right';
            app.PortListLabel.Position = [65 670 80 22];
            app.PortListLabel.Text = 'Port';

            app.PortListDropDown = uidropdown(app.ConnectionTab);
            app.PortListDropDown.DropDownOpeningFcn = createCallbackFcn(app, @PortListDropDownOpening, true);
            app.PortListDropDown.ValueChangedFcn = createCallbackFcn(app, @PortListDropDownValueChanged, true);
            app.PortListDropDown.Position = [160 670 180 22];

            app.RefreshPortsButton = uibutton(app.ConnectionTab, 'push');
            app.RefreshPortsButton.ButtonPushedFcn = createCallbackFcn(app, @PortListDropDownOpening, true);
            app.RefreshPortsButton.Position = [355 670 100 23];
            app.RefreshPortsButton.Text = 'Refresh';

            app.BaudLabel = uilabel(app.ConnectionTab);
            app.BaudLabel.HorizontalAlignment = 'right';
            app.BaudLabel.Position = [65 630 80 22];
            app.BaudLabel.Text = 'Baud';

            app.BaudDropDown = uidropdown(app.ConnectionTab);
            app.BaudDropDown.ValueChangedFcn = createCallbackFcn(app, @SettingsValueChanged, true);
            app.BaudDropDown.Position = [160 630 180 22];

            app.AddressLabel = uilabel(app.ConnectionTab);
            app.AddressLabel.HorizontalAlignment = 'right';
            app.AddressLabel.Position = [65 590 80 22];
            app.AddressLabel.Text = 'Address';

            app.AddressDropDown = uidropdown(app.ConnectionTab);
            app.AddressDropDown.ValueChangedFcn = createCallbackFcn(app, @SettingsValueChanged, true);
            app.AddressDropDown.Position = [160 590 180 22];

            app.VerboseCheckBox = uicheckbox(app.ConnectionTab);
            app.VerboseCheckBox.ValueChangedFcn = createCallbackFcn(app, @SettingsValueChanged, true);
            app.VerboseCheckBox.Position = [160 550 180 22];
            app.VerboseCheckBox.Text = 'Verbose TX log';

            app.ChoseportandpressthebuttonButton = uibutton(app.ConnectionTab, 'push');
            app.ChoseportandpressthebuttonButton.ButtonPushedFcn = createCallbackFcn(app, @ChoseportandpressthebuttonButtonPushed, true);
            app.ChoseportandpressthebuttonButton.Position = [160 510 250 26];
            app.ChoseportandpressthebuttonButton.Text = 'Choose port and connect';

            app.StatusTextArea = uitextarea(app.ConnectionTab);
            app.StatusTextArea.Position = [40 30 640 440];
            app.StatusTextArea.Editable = 'off';
            app.StatusTextArea.Value = {'Status'};

            % ---------------- Motion tab ----------------
            app.PositionSpeedLabel = uilabel(app.MotionTab);
            app.PositionSpeedLabel.HorizontalAlignment = 'right';
            app.PositionSpeedLabel.Position = [55 665 145 22];
            app.PositionSpeedLabel.Text = 'Position speed 0..127';

            app.PositionSpeedEditField = uieditfield(app.MotionTab, 'numeric');
            app.PositionSpeedEditField.ValueChangedFcn = createCallbackFcn(app, @SettingsValueChanged, true);
            app.PositionSpeedEditField.Limits = [0 127];
            app.PositionSpeedEditField.RoundFractionalValues = 'on';
            app.PositionSpeedEditField.Position = [220 665 110 22];

            app.AngleLimitLabel = uilabel(app.MotionTab);
            app.AngleLimitLabel.HorizontalAlignment = 'right';
            app.AngleLimitLabel.Position = [55 625 145 22];
            app.AngleLimitLabel.Text = 'Angle limit, deg';

            app.AngleLimitEditField = uieditfield(app.MotionTab, 'numeric');
            app.AngleLimitEditField.ValueChangedFcn = createCallbackFcn(app, @SettingsValueChanged, true);
            app.AngleLimitEditField.Position = [220 625 110 22];

            app.Step1Label = uilabel(app.MotionTab);
            app.Step1Label.HorizontalAlignment = 'right';
            app.Step1Label.Position = [55 565 145 22];
            app.Step1Label.Text = 'Small step, deg';

            app.Step1EditField = uieditfield(app.MotionTab, 'numeric');
            app.Step1EditField.ValueChangedFcn = createCallbackFcn(app, @SettingsValueChanged, true);
            app.Step1EditField.Position = [220 565 110 22];

            app.Step2Label = uilabel(app.MotionTab);
            app.Step2Label.HorizontalAlignment = 'right';
            app.Step2Label.Position = [55 525 145 22];
            app.Step2Label.Text = 'Medium step, deg';

            app.Step2EditField = uieditfield(app.MotionTab, 'numeric');
            app.Step2EditField.ValueChangedFcn = createCallbackFcn(app, @SettingsValueChanged, true);
            app.Step2EditField.Position = [220 525 110 22];

            app.Step3Label = uilabel(app.MotionTab);
            app.Step3Label.HorizontalAlignment = 'right';
            app.Step3Label.Position = [55 485 145 22];
            app.Step3Label.Text = 'Large step, deg';

            app.Step3EditField = uieditfield(app.MotionTab, 'numeric');
            app.Step3EditField.ValueChangedFcn = createCallbackFcn(app, @SettingsValueChanged, true);
            app.Step3EditField.Position = [220 485 110 22];

            app.ApplyMotionSettingsButton = uibutton(app.MotionTab, 'push');
            app.ApplyMotionSettingsButton.ButtonPushedFcn = createCallbackFcn(app, @ApplyMotionSettingsButtonPushed, true);
            app.ApplyMotionSettingsButton.Position = [220 435 160 26];
            app.ApplyMotionSettingsButton.Text = 'Apply motion settings';

            % ---------------- Mechanics tab ----------------
            app.MotorStepsPerRevLabel = uilabel(app.MechanicsTab);
            app.MotorStepsPerRevLabel.HorizontalAlignment = 'right';
            app.MotorStepsPerRevLabel.Position = [40 665 170 22];
            app.MotorStepsPerRevLabel.Text = 'Motor full steps / rev';

            app.MotorStepsPerRevEditField = uieditfield(app.MechanicsTab, 'numeric');
            app.MotorStepsPerRevEditField.ValueChangedFcn = createCallbackFcn(app, @SettingsValueChanged, true);
            app.MotorStepsPerRevEditField.Position = [230 665 120 22];

            app.SubdivisionLabel = uilabel(app.MechanicsTab);
            app.SubdivisionLabel.HorizontalAlignment = 'right';
            app.SubdivisionLabel.Position = [40 625 170 22];
            app.SubdivisionLabel.Text = 'Subdivision 1..256';

            app.SubdivisionEditField = uieditfield(app.MechanicsTab, 'numeric');
            app.SubdivisionEditField.ValueChangedFcn = createCallbackFcn(app, @SettingsValueChanged, true);
            app.SubdivisionEditField.Limits = [1 256];
            app.SubdivisionEditField.RoundFractionalValues = 'on';
            app.SubdivisionEditField.Position = [230 625 120 22];

            app.Gear1TeethLabel = uilabel(app.MechanicsTab);
            app.Gear1TeethLabel.HorizontalAlignment = 'right';
            app.Gear1TeethLabel.Position = [40 585 170 22];
            app.Gear1TeethLabel.Text = 'Motor gear teeth';

            app.Gear1TeethEditField = uieditfield(app.MechanicsTab, 'numeric');
            app.Gear1TeethEditField.ValueChangedFcn = createCallbackFcn(app, @SettingsValueChanged, true);
            app.Gear1TeethEditField.Position = [230 585 120 22];

            app.Gear2TeethLabel = uilabel(app.MechanicsTab);
            app.Gear2TeethLabel.HorizontalAlignment = 'right';
            app.Gear2TeethLabel.Position = [40 545 170 22];
            app.Gear2TeethLabel.Text = 'Output gear teeth';

            app.Gear2TeethEditField = uieditfield(app.MechanicsTab, 'numeric');
            app.Gear2TeethEditField.ValueChangedFcn = createCallbackFcn(app, @SettingsValueChanged, true);
            app.Gear2TeethEditField.Position = [230 545 120 22];

            app.DegPerPulseLabel = uilabel(app.MechanicsTab);
            app.DegPerPulseLabel.HorizontalAlignment = 'right';
            app.DegPerPulseLabel.Position = [40 485 170 22];
            app.DegPerPulseLabel.Text = 'Output deg / pulse';

            app.DegPerPulseEditField = uieditfield(app.MechanicsTab, 'numeric');
            app.DegPerPulseEditField.Editable = 'off';
            app.DegPerPulseEditField.Position = [230 485 120 22];

            app.ApplyMechanicsSettingsButton = uibutton(app.MechanicsTab, 'push');
            app.ApplyMechanicsSettingsButton.ButtonPushedFcn = createCallbackFcn(app, @ApplyMechanicsSettingsButtonPushed, true);
            app.ApplyMechanicsSettingsButton.Position = [230 435 180 26];
            app.ApplyMechanicsSettingsButton.Text = 'Apply mechanics settings';

            app.SendSubdivisionButton = uibutton(app.MechanicsTab, 'push');
            app.SendSubdivisionButton.ButtonPushedFcn = createCallbackFcn(app, @SendSubdivisionButtonPushed, true);
            app.SendSubdivisionButton.Position = [230 395 180 26];
            app.SendSubdivisionButton.Text = 'Send subdivision to driver';


            % ---------------- Random tab ----------------
            app.RandomMinStepLabel = uilabel(app.RandomTab);
            app.RandomMinStepLabel.HorizontalAlignment = 'right';
            app.RandomMinStepLabel.Position = [45 665 165 22];
            app.RandomMinStepLabel.Text = 'Min random step, deg';

            app.RandomMinStepEditField = uieditfield(app.RandomTab, 'numeric');
            app.RandomMinStepEditField.ValueChangedFcn = createCallbackFcn(app, @RandomSettingsValueChanged, true);
            app.RandomMinStepEditField.Limits = [0.001 Inf];
            app.RandomMinStepEditField.Position = [230 665 120 22];
            app.RandomMinStepEditField.Value = 1;

            app.RandomMaxStepLabel = uilabel(app.RandomTab);
            app.RandomMaxStepLabel.HorizontalAlignment = 'right';
            app.RandomMaxStepLabel.Position = [45 625 165 22];
            app.RandomMaxStepLabel.Text = 'Max random step, deg';

            app.RandomMaxStepEditField = uieditfield(app.RandomTab, 'numeric');
            app.RandomMaxStepEditField.ValueChangedFcn = createCallbackFcn(app, @RandomSettingsValueChanged, true);
            app.RandomMaxStepEditField.Limits = [0.001 Inf];
            app.RandomMaxStepEditField.Position = [230 625 120 22];
            app.RandomMaxStepEditField.Value = 30;

            app.RandomPeriodLabel = uilabel(app.RandomTab);
            app.RandomPeriodLabel.HorizontalAlignment = 'right';
            app.RandomPeriodLabel.Position = [45 585 165 22];
            app.RandomPeriodLabel.Text = 'Period, s';

            app.RandomPeriodEditField = uieditfield(app.RandomTab, 'numeric');
            app.RandomPeriodEditField.ValueChangedFcn = createCallbackFcn(app, @RandomSettingsValueChanged, true);
            app.RandomPeriodEditField.Limits = [0.05 60];
            app.RandomPeriodEditField.Position = [230 585 120 22];
            app.RandomPeriodEditField.Value = 1.0;

            app.RandomConstrainedCheckBox = uicheckbox(app.RandomTab);
            app.RandomConstrainedCheckBox.ValueChangedFcn = createCallbackFcn(app, @RandomSettingsValueChanged, true);
            app.RandomConstrainedCheckBox.Position = [230 545 330 22];
            app.RandomConstrainedCheckBox.Text = 'Constrain targets by angle limit';
            app.RandomConstrainedCheckBox.Value = true;

            app.RandomStartButton = uibutton(app.RandomTab, 'push');
            app.RandomStartButton.ButtonPushedFcn = createCallbackFcn(app, @StartRandomButtonPushed, true);
            app.RandomStartButton.Position = [230 495 160 28];
            app.RandomStartButton.Text = 'Start random mode';

            app.RandomStopButton = uibutton(app.RandomTab, 'push');
            app.RandomStopButton.ButtonPushedFcn = createCallbackFcn(app, @StopRandomButtonPushed, true);
            app.RandomStopButton.Position = [410 495 160 28];
            app.RandomStopButton.Text = 'Stop random mode';
            app.RandomStopButton.Enable = 'off';

            app.RandomStatusLabel = uilabel(app.RandomTab);
            app.RandomStatusLabel.Position = [70 445 580 22];
            app.RandomStatusLabel.Text = 'Random mode stopped';

            uilabel(app.RandomTab, 'Position', [70 405 580 44], ...
                'Text', 'Constrained mode selects random target angles inside +/- angle limit. Unconstrained mode sends random relative steps. Both use normal MKS 0xFD relative moves.');

            % ---------------- Position tab ----------------
            app.CurrentPositionLabel = uilabel(app.PositionTab);
            app.CurrentPositionLabel.HorizontalAlignment = 'right';
            app.CurrentPositionLabel.Position = [45 665 165 22];
            app.CurrentPositionLabel.Text = 'Current position, deg';

            app.CurrentPositionEditField = uieditfield(app.PositionTab, 'numeric');
            app.CurrentPositionEditField.Position = [230 665 120 22];
            app.CurrentPositionEditField.Value = 0;

            app.SetCurrentPositionButton = uibutton(app.PositionTab, 'push');
            app.SetCurrentPositionButton.ButtonPushedFcn = createCallbackFcn(app, @SetCurrentPositionButtonPushed, true);
            app.SetCurrentPositionButton.Position = [370 662 150 28];
            app.SetCurrentPositionButton.Text = 'Set current';

            app.ResetCurrentPositionButton = uibutton(app.PositionTab, 'push');
            app.ResetCurrentPositionButton.ButtonPushedFcn = createCallbackFcn(app, @ResetCurrentPositionButtonPushed, true);
            app.ResetCurrentPositionButton.Position = [230 615 180 28];
            app.ResetCurrentPositionButton.Text = 'Reset current to 0';

            app.AcquireCurrentPositionButton = uibutton(app.PositionTab, 'push');
            app.AcquireCurrentPositionButton.ButtonPushedFcn = createCallbackFcn(app, @AcquireCurrentPositionButtonPushed, true);
            app.AcquireCurrentPositionButton.Position = [430 615 190 28];
            app.AcquireCurrentPositionButton.Text = 'Acquire from motor';

            app.MirrorDisplayCheckBox = uicheckbox(app.PositionTab);
            app.MirrorDisplayCheckBox.ValueChangedFcn = createCallbackFcn(app, @SettingsValueChanged, true);
            app.MirrorDisplayCheckBox.Position = [230 570 260 22];
            app.MirrorDisplayCheckBox.Text = 'Mirror displayed degrees';
            app.MirrorDisplayCheckBox.Value = false;

            app.PositionInfoLabel = uilabel(app.PositionTab);
            app.PositionInfoLabel.Position = [70 535 610 22];
            app.PositionInfoLabel.Text = 'Displayed position: 0 deg | motor/internal: 0 deg';

            uilabel(app.PositionTab, 'Position', [70 455 590 66], ...
                'Text', 'Mirror displayed degrees changes only the UI coordinate mapping. The MKS motor/protocol angle is kept internally; when mirrored, displayed +X maps to motor/internal -X. Reset current to 0 is calibration only.');

            % ---------------- Advanced tab ----------------
            app.EnableButton = uibutton(app.AdvancedTab, 'push');
            app.EnableButton.ButtonPushedFcn = createCallbackFcn(app, @EnableButtonPushed, true);
            app.EnableButton.Position = [70 665 120 26];
            app.EnableButton.Text = 'Enable motor';

            app.DisableButton = uibutton(app.AdvancedTab, 'push');
            app.DisableButton.ButtonPushedFcn = createCallbackFcn(app, @DisableButtonPushed, true);
            app.DisableButton.Position = [210 665 120 26];
            app.DisableButton.Text = 'Disable motor';

            app.EmergencyStopButton = uibutton(app.AdvancedTab, 'push');
            app.EmergencyStopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonPushed, true);
            app.EmergencyStopButton.Position = [350 665 120 26];
            app.EmergencyStopButton.Text = 'Stop';

            app.ReadEncoderButton = uibutton(app.AdvancedTab, 'push');
            app.ReadEncoderButton.ButtonPushedFcn = createCallbackFcn(app, @ReadEncoderButtonPushed, true);
            app.ReadEncoderButton.Position = [70 620 160 26];
            app.ReadEncoderButton.Text = 'Query position';

            app.ClearStatusButton = uibutton(app.AdvancedTab, 'push');
            app.ClearStatusButton.ButtonPushedFcn = createCallbackFcn(app, @ClearStatusButtonPushed, true);
            app.ClearStatusButton.Position = [250 620 120 26];
            app.ClearStatusButton.Text = 'Clear status';

            app.RawPacketLabel = uilabel(app.AdvancedTab);
            app.RawPacketLabel.HorizontalAlignment = 'right';
            app.RawPacketLabel.Position = [35 555 170 22];
            app.RawPacketLabel.Text = 'Raw payload hex';

            app.RawPacketEditField = uieditfield(app.AdvancedTab, 'text');
            app.RawPacketEditField.Position = [220 555 300 22];
            app.RawPacketEditField.Value = 'E0 F7';

            app.SendRawPacketButton = uibutton(app.AdvancedTab, 'push');
            app.SendRawPacketButton.ButtonPushedFcn = createCallbackFcn(app, @SendRawPacketButtonPushed, true);
            app.SendRawPacketButton.Position = [540 553 120 26];
            app.SendRawPacketButton.Text = 'Send raw';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = stepper

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
            try
                app.stopRandomMode();
            catch
            end
            try
                if isConnected(app)
                    stopMotor(app);
                    enableMotor(app, false);
                    delete(app.Arduino);
                end
            catch
            end

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
