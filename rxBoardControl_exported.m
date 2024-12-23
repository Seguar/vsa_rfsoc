classdef rxBoardControl_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure               matlab.ui.Figure
        LoadRegsButton         matlab.ui.control.Button
        SaveRegsButton         matlab.ui.control.Button
        CFSpinner              matlab.ui.control.Spinner
        CFSpinnerLabel         matlab.ui.control.Label
        R2Spinner              matlab.ui.control.Spinner
        R2SpinnerLabel         matlab.ui.control.Label
        R1Spinner              matlab.ui.control.Spinner
        C1Spinner              matlab.ui.control.Spinner
        C1SpinnerLabel         matlab.ui.control.Label
        C2Spinner              matlab.ui.control.Spinner
        C2SpinnerLabel         matlab.ui.control.Label
        R3Spinner              matlab.ui.control.Spinner
        R3SpinnerLabel         matlab.ui.control.Label
        RM2Spinner             matlab.ui.control.Spinner
        RM2SpinnerLabel        matlab.ui.control.Label
        R1SpinnerLabel         matlab.ui.control.Label
        CM2Spinner             matlab.ui.control.Spinner
        CM2SpinnerLabel        matlab.ui.control.Label
        RMSpinner              matlab.ui.control.Spinner
        RMSpinnerLabel         matlab.ui.control.Label
        CMSpinner              matlab.ui.control.Spinner
        CMSpinnerLabel         matlab.ui.control.Label
        RX1_DAC_QSpinnerLabel  matlab.ui.control.Label
        RX1_DAC_ISpinnerLabel  matlab.ui.control.Label
        RX2_DAC_QSpinnerLabel  matlab.ui.control.Label
        RX2_DAC_ISpinnerLabel  matlab.ui.control.Label
        RX3_DAC_QSpinnerLabel  matlab.ui.control.Label
        RX3_DAC_ISpinnerLabel  matlab.ui.control.Label
        CBBSpinner             matlab.ui.control.Spinner
        RX1_DAC_QSpinner       matlab.ui.control.Spinner
        RX4_DAC_QSpinnerLabel  matlab.ui.control.Label
        CBBSpinnerLabel        matlab.ui.control.Label
        RX1_DAC_ISpinner       matlab.ui.control.Spinner
        RFSpinner              matlab.ui.control.Spinner
        RX2_DAC_QSpinner       matlab.ui.control.Spinner
        RFSpinnerLabel         matlab.ui.control.Label
        RX2_DAC_ISpinner       matlab.ui.control.Spinner
        VCSpinner              matlab.ui.control.Spinner
        RX3_DAC_QSpinner       matlab.ui.control.Spinner
        VCSpinnerLabel         matlab.ui.control.Label
        RX3_DAC_ISpinner       matlab.ui.control.Spinner
        PortListDropDown       matlab.ui.control.DropDown
        RX4_DAC_ISpinnerLabel  matlab.ui.control.Label
        RX4_DAC_QSpinner       matlab.ui.control.Spinner
        PortListDropDownLabel  matlab.ui.control.Label
        RX4_DAC_ISpinner       matlab.ui.control.Spinner
        ChoseportandpressthebuttonButton  matlab.ui.control.Button
    end


    properties (Access = public)
        Arduino = [];
        portList = [];
        port = [];
        readBack = [];
        registers = struct('RM2', 5, 'R3', 3, 'C2', 2, 'C1', 14, 'CM2', 2, ...
            'R1', 0, 'R2', 0, 'CF', 0, 'RF', 4, 'CBB', 15, 'CM', 4, 'RM', 2, ...
            'RX4_DAC_I', 32, 'RX4_DAC_Q', 32, 'RX3_DAC_I', 32, 'RX3_DAC_Q', 32, ...
            'RX2_DAC_I', 32, 'RX2_DAC_Q', 32, 'RX1_DAC_I', 32, 'RX1_DAC_Q', 32, 'VC', 1);
    end

    methods (Access = public)
        function updateRXboard(app)
            app.readBack = rxBoardControlF(app.registers, app.Arduino);
        end

        function pollButtons(app)
            app.registers.RM2 = app.RM2Spinner.Value;
            app.registers.R3 = app.R3Spinner.Value;
            app.registers.C2 = app.C2Spinner.Value;
            app.registers.C1 = app.C1Spinner.Value;
            app.registers.CM2 = app.CM2Spinner.Value;
            app.registers.R1 = app.R1Spinner.Value;
            app.registers.R2 = app.R2Spinner.Value;
            app.registers.CF = app.CFSpinner.Value;
            app.registers.RF = app.RFSpinner.Value;
            app.registers.CBB = app.CBBSpinner.Value;
            app.registers.CM = app.CMSpinner.Value;
            app.registers.RM = app.RMSpinner.Value;
            app.registers.RX4_DAC_I = app.RX4_DAC_ISpinner.Value;
            app.registers.RX4_DAC_Q = app.RX4_DAC_QSpinner.Value;
            app.registers.RX3_DAC_I = app.RX3_DAC_ISpinner.Value;
            app.registers.RX3_DAC_Q = app.RX3_DAC_QSpinner.Value;
            app.registers.RX2_DAC_I = app.RX2_DAC_ISpinner.Value;
            app.registers.RX2_DAC_Q = app.RX2_DAC_QSpinner.Value;
            app.registers.RX1_DAC_I = app.RX1_DAC_ISpinner.Value;
            app.registers.RX1_DAC_Q = app.RX1_DAC_QSpinner.Value;
            app.registers.VC = app.VCSpinner.Value;
        end

        function updateFields(app)
            app.RM2Spinner.Value = app.registers.RM2;
            app.R3Spinner.Value = app.registers.R3;
            app.C2Spinner.Value = app.registers.C2;
            app.C1Spinner.Value = app.registers.C1;
            app.CM2Spinner.Value = app.registers.CM2;
            app.R1Spinner.Value = app.registers.R1;
            app.R2Spinner.Value = app.registers.R2;
            app.CFSpinner.Value = app.registers.CF;
            app.RFSpinner.Value = app.registers.RF;
            app.CBBSpinner.Value = app.registers.CBB;
            app.CMSpinner.Value = app.registers.CM;
            app.RMSpinner.Value = app.registers.RM;
            app.RX4_DAC_ISpinner.Value = app.registers.RX4_DAC_I;
            app.RX4_DAC_QSpinner.Value = app.registers.RX4_DAC_Q;
            app.RX3_DAC_ISpinner.Value = app.registers.RX3_DAC_I;
            app.RX3_DAC_QSpinner.Value = app.registers.RX3_DAC_Q;
            app.RX2_DAC_ISpinner.Value = app.registers.RX2_DAC_I;
            app.RX2_DAC_QSpinner.Value = app.registers.RX2_DAC_Q;
            app.RX1_DAC_ISpinner.Value = app.registers.RX1_DAC_I;
            app.RX1_DAC_QSpinner.Value = app.registers.RX1_DAC_Q;
            app.VCSpinner.Value = app.registers.VC;
        end
    end

    methods (Access = private)

    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            cd(fileparts(mfilename('fullpath')))
            addpath(genpath([pwd '\Functions']))
        end

        % Drop down opening function: PortListDropDown
        function PortListDropDownOpening(app, event)
            app.port = [];
            try
                app.portList = serialportlist("available");
            catch
                app.portList = [];
            end
            app.PortListDropDown.Items = app.portList;
        end

        % Value changed function: PortListDropDown
        function PortListDropDownValueChanged(app, event)
            app.port = app.PortListDropDown.Value;
        end

        % Button pushed function: ChoseportandpressthebuttonButton
        function ChoseportandpressthebuttonButtonPushed(app, event)
            if isempty(app.Arduino)
                app.Arduino = serialport(app.port,115200);
                app.ChoseportandpressthebuttonButton.Text = [app.port " connected"];
                app.ChoseportandpressthebuttonButton.BackgroundColor = 'g';
            else
                clear app.Arduino
                app.Arduino = [];
                app.ChoseportandpressthebuttonButton.Text = "Disconnected";
                app.ChoseportandpressthebuttonButton.BackgroundColor = 'r';
            end
        end

        % Button pushed function: SaveRegsButton
        function SaveRegsButtonPushed(app, event)
            defaultFile = fullfile(pwd,'Settings','registers.mat');
            [baseFileName, folder] = uiputfile(defaultFile);
            if isequal(baseFileName,0) || isequal(folder,0)
                return; % user pressed Cancel
            end
            registers = app.registers;
            save(fullfile(folder, baseFileName), 'registers');
        end

        % Button pushed function: LoadRegsButton
        function LoadRegsButtonPushed(app, event)
            defaultPath = fullfile(pwd,'Settings','*.mat');
            [file, path] = uigetfile(defaultPath);
            if isequal(file,0) || isequal(path,0)
                return; % user pressed Cancel
            end
            data = load(fullfile(path,file));
            if isfield(data,'registers')
                app.registers = data.registers;
                updateFields(app);
                updateRXboard(app);
            else
                uialert(app.UIFigure,'File does not contain registers','Load Error');
            end
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            delete(app)
        end

        % Value changed function: RX4_DAC_ISpinner
        function RX4_DAC_ISpinnerValueChanged(app, event)
            pollButtons(app);
            updateRXboard(app);
        end

        % Value changed function: RX4_DAC_QSpinner
        function RX4_DAC_QSpinnerValueChanged(app, event)
            pollButtons(app);
            updateRXboard(app);
        end

        % Value changed function: RX3_DAC_ISpinner
        function RX3_DAC_ISpinnerValueChanged(app, event)
            pollButtons(app);
            updateRXboard(app);
        end

        % Value changed function: RX3_DAC_QSpinner
        function RX3_DAC_QSpinnerValueChanged(app, event)
            pollButtons(app);
            updateRXboard(app);
        end

        % Value changed function: VCSpinner
        function VCSpinnerValueChanged(app, event)
            pollButtons(app);
            updateRXboard(app);
        end

        % Value changed function: RX2_DAC_ISpinner
        function RX2_DAC_ISpinnerValueChanged(app, event)
            pollButtons(app);
            updateRXboard(app);
        end

        % Value changed function: RX2_DAC_QSpinner
        function RX2_DAC_QSpinnerValueChanged(app, event)
            pollButtons(app);
            updateRXboard(app);
        end

        % Value changed function: RFSpinner
        function RFSpinnerValueChanged(app, event)
            pollButtons(app);
            updateRXboard(app);
        end

        % Value changed function: RX1_DAC_ISpinner
        function RX1_DAC_ISpinnerValueChanged(app, event)
            pollButtons(app);
            updateRXboard(app);
        end

        % Value changed function: RX1_DAC_QSpinner
        function RX1_DAC_QSpinnerValueChanged(app, event)
            pollButtons(app);
            updateRXboard(app);
        end

        % Value changed function: CBBSpinner
        function CBBSpinnerValueChanged(app, event)
            pollButtons(app);
            updateRXboard(app);
        end

        % Value changed function: CMSpinner
        function CMSpinnerValueChanged(app, event)
            pollButtons(app);
            updateRXboard(app);
        end

        % Value changed function: RMSpinner
        function RMSpinnerValueChanged(app, event)
            pollButtons(app);
            updateRXboard(app);
        end

        % Value changed function: CM2Spinner
        function CM2SpinnerValueChanged(app, event)
            pollButtons(app);
            updateRXboard(app);
        end

        % Value changed function: RM2Spinner
        function RM2SpinnerValueChanged(app, event)
            pollButtons(app);
            updateRXboard(app);
        end

        % Value changed function: R3Spinner
        function R3SpinnerValueChanged(app, event)
            pollButtons(app);
            updateRXboard(app);
        end

        % Value changed function: C2Spinner
        function C2SpinnerValueChanged(app, event)
            pollButtons(app);
            updateRXboard(app);
        end

        % Value changed function: C1Spinner
        function C1SpinnerValueChanged(app, event)
            pollButtons(app);
            updateRXboard(app);
        end

        % Value changed function: R1Spinner
        function R1SpinnerValueChanged(app, event)
            pollButtons(app);
            updateRXboard(app);
        end

        % Value changed function: R2Spinner
        function R2SpinnerValueChanged(app, event)
            pollButtons(app);
            updateRXboard(app);
        end

        % Value changed function: CFSpinner
        function CFSpinnerValueChanged(app, event)
            pollButtons(app);
            updateRXboard(app);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 632 308];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create ChoseportandpressthebuttonButton
            app.ChoseportandpressthebuttonButton = uibutton(app.UIFigure, 'push');
            app.ChoseportandpressthebuttonButton.ButtonPushedFcn = createCallbackFcn(app, @ChoseportandpressthebuttonButtonPushed, true);
            app.ChoseportandpressthebuttonButton.Position = [366 253 186 22];
            app.ChoseportandpressthebuttonButton.Text = 'Chose port and press the button';

            % Create RX4_DAC_ISpinner
            app.RX4_DAC_ISpinner = uispinner(app.UIFigure);
            app.RX4_DAC_ISpinner.Limits = [0 63];
            app.RX4_DAC_ISpinner.ValueChangedFcn = createCallbackFcn(app, @RX4_DAC_ISpinnerValueChanged, true);
            app.RX4_DAC_ISpinner.Position = [511 178 45 22];
            app.RX4_DAC_ISpinner.Value = 32;

            % Create PortListDropDownLabel
            app.PortListDropDownLabel = uilabel(app.UIFigure);
            app.PortListDropDownLabel.HorizontalAlignment = 'right';
            app.PortListDropDownLabel.Position = [154 253 49 22];
            app.PortListDropDownLabel.Text = 'Port List';

            % Create RX4_DAC_QSpinner
            app.RX4_DAC_QSpinner = uispinner(app.UIFigure);
            app.RX4_DAC_QSpinner.Limits = [0 63];
            app.RX4_DAC_QSpinner.ValueChangedFcn = createCallbackFcn(app, @RX4_DAC_QSpinnerValueChanged, true);
            app.RX4_DAC_QSpinner.Position = [511 157 45 22];
            app.RX4_DAC_QSpinner.Value = 32;

            % Create RX4_DAC_ISpinnerLabel
            app.RX4_DAC_ISpinnerLabel = uilabel(app.UIFigure);
            app.RX4_DAC_ISpinnerLabel.HorizontalAlignment = 'right';
            app.RX4_DAC_ISpinnerLabel.Position = [426 178 70 22];
            app.RX4_DAC_ISpinnerLabel.Text = 'RX4_DAC_I';

            % Create PortListDropDown
            app.PortListDropDown = uidropdown(app.UIFigure);
            app.PortListDropDown.Items = {'Com'};
            app.PortListDropDown.DropDownOpeningFcn = createCallbackFcn(app, @PortListDropDownOpening, true);
            app.PortListDropDown.ValueChangedFcn = createCallbackFcn(app, @PortListDropDownValueChanged, true);
            app.PortListDropDown.Position = [218 253 100 22];
            app.PortListDropDown.Value = 'Com';

            % Create RX3_DAC_ISpinner
            app.RX3_DAC_ISpinner = uispinner(app.UIFigure);
            app.RX3_DAC_ISpinner.Limits = [0 63];
            app.RX3_DAC_ISpinner.ValueChangedFcn = createCallbackFcn(app, @RX3_DAC_ISpinnerValueChanged, true);
            app.RX3_DAC_ISpinner.Position = [371 178 45 22];
            app.RX3_DAC_ISpinner.Value = 32;

            % Create VCSpinnerLabel
            app.VCSpinnerLabel = uilabel(app.UIFigure);
            app.VCSpinnerLabel.HorizontalAlignment = 'right';
            app.VCSpinnerLabel.Position = [504 107 25 22];
            app.VCSpinnerLabel.Text = 'VC';

            % Create RX3_DAC_QSpinner
            app.RX3_DAC_QSpinner = uispinner(app.UIFigure);
            app.RX3_DAC_QSpinner.Limits = [0 63];
            app.RX3_DAC_QSpinner.ValueChangedFcn = createCallbackFcn(app, @RX3_DAC_QSpinnerValueChanged, true);
            app.RX3_DAC_QSpinner.Position = [371 158 45 22];
            app.RX3_DAC_QSpinner.Value = 32;

            % Create VCSpinner
            app.VCSpinner = uispinner(app.UIFigure);
            app.VCSpinner.Limits = [0 1];
            app.VCSpinner.ValueChangedFcn = createCallbackFcn(app, @VCSpinnerValueChanged, true);
            app.VCSpinner.Position = [544 107 45 22];
            app.VCSpinner.Value = 1;

            % Create RX2_DAC_ISpinner
            app.RX2_DAC_ISpinner = uispinner(app.UIFigure);
            app.RX2_DAC_ISpinner.Limits = [0 63];
            app.RX2_DAC_ISpinner.ValueChangedFcn = createCallbackFcn(app, @RX2_DAC_ISpinnerValueChanged, true);
            app.RX2_DAC_ISpinner.Position = [235 178 45 22];
            app.RX2_DAC_ISpinner.Value = 32;

            % Create RFSpinnerLabel
            app.RFSpinnerLabel = uilabel(app.UIFigure);
            app.RFSpinnerLabel.HorizontalAlignment = 'right';
            app.RFSpinnerLabel.Position = [364 107 25 22];
            app.RFSpinnerLabel.Text = 'RF';

            % Create RX2_DAC_QSpinner
            app.RX2_DAC_QSpinner = uispinner(app.UIFigure);
            app.RX2_DAC_QSpinner.Limits = [0 63];
            app.RX2_DAC_QSpinner.ValueChangedFcn = createCallbackFcn(app, @RX2_DAC_QSpinnerValueChanged, true);
            app.RX2_DAC_QSpinner.Position = [235 158 45 22];
            app.RX2_DAC_QSpinner.Value = 32;

            % Create RFSpinner
            app.RFSpinner = uispinner(app.UIFigure);
            app.RFSpinner.Limits = [0 15];
            app.RFSpinner.ValueChangedFcn = createCallbackFcn(app, @RFSpinnerValueChanged, true);
            app.RFSpinner.Position = [404 107 45 22];
            app.RFSpinner.Value = 4;

            % Create RX1_DAC_ISpinner
            app.RX1_DAC_ISpinner = uispinner(app.UIFigure);
            app.RX1_DAC_ISpinner.Limits = [0 63];
            app.RX1_DAC_ISpinner.ValueChangedFcn = createCallbackFcn(app, @RX1_DAC_ISpinnerValueChanged, true);
            app.RX1_DAC_ISpinner.Position = [99 178 45 22];
            app.RX1_DAC_ISpinner.Value = 32;

            % Create CBBSpinnerLabel
            app.CBBSpinnerLabel = uilabel(app.UIFigure);
            app.CBBSpinnerLabel.HorizontalAlignment = 'right';
            app.CBBSpinnerLabel.Position = [359 87 30 22];
            app.CBBSpinnerLabel.Text = 'CBB';

            % Create RX4_DAC_QSpinnerLabel
            app.RX4_DAC_QSpinnerLabel = uilabel(app.UIFigure);
            app.RX4_DAC_QSpinnerLabel.HorizontalAlignment = 'right';
            app.RX4_DAC_QSpinnerLabel.Position = [420 157 76 22];
            app.RX4_DAC_QSpinnerLabel.Text = 'RX4_DAC_Q';

            % Create RX1_DAC_QSpinner
            app.RX1_DAC_QSpinner = uispinner(app.UIFigure);
            app.RX1_DAC_QSpinner.Limits = [0 63];
            app.RX1_DAC_QSpinner.ValueChangedFcn = createCallbackFcn(app, @RX1_DAC_QSpinnerValueChanged, true);
            app.RX1_DAC_QSpinner.Position = [99 158 45 22];
            app.RX1_DAC_QSpinner.Value = 32;

            % Create CBBSpinner
            app.CBBSpinner = uispinner(app.UIFigure);
            app.CBBSpinner.Limits = [0 31];
            app.CBBSpinner.ValueChangedFcn = createCallbackFcn(app, @CBBSpinnerValueChanged, true);
            app.CBBSpinner.Position = [404 87 45 22];
            app.CBBSpinner.Value = 15;

            % Create RX3_DAC_ISpinnerLabel
            app.RX3_DAC_ISpinnerLabel = uilabel(app.UIFigure);
            app.RX3_DAC_ISpinnerLabel.HorizontalAlignment = 'right';
            app.RX3_DAC_ISpinnerLabel.Position = [286 178 70 22];
            app.RX3_DAC_ISpinnerLabel.Text = 'RX3_DAC_I';

            % Create RX3_DAC_QSpinnerLabel
            app.RX3_DAC_QSpinnerLabel = uilabel(app.UIFigure);
            app.RX3_DAC_QSpinnerLabel.HorizontalAlignment = 'right';
            app.RX3_DAC_QSpinnerLabel.Position = [280 158 76 22];
            app.RX3_DAC_QSpinnerLabel.Text = 'RX3_DAC_Q';

            % Create RX2_DAC_ISpinnerLabel
            app.RX2_DAC_ISpinnerLabel = uilabel(app.UIFigure);
            app.RX2_DAC_ISpinnerLabel.HorizontalAlignment = 'right';
            app.RX2_DAC_ISpinnerLabel.Position = [150 178 70 22];
            app.RX2_DAC_ISpinnerLabel.Text = 'RX2_DAC_I';

            % Create RX2_DAC_QSpinnerLabel
            app.RX2_DAC_QSpinnerLabel = uilabel(app.UIFigure);
            app.RX2_DAC_QSpinnerLabel.HorizontalAlignment = 'right';
            app.RX2_DAC_QSpinnerLabel.Position = [144 158 76 22];
            app.RX2_DAC_QSpinnerLabel.Text = 'RX2_DAC_Q';

            % Create RX1_DAC_ISpinnerLabel
            app.RX1_DAC_ISpinnerLabel = uilabel(app.UIFigure);
            app.RX1_DAC_ISpinnerLabel.HorizontalAlignment = 'right';
            app.RX1_DAC_ISpinnerLabel.Position = [14 178 70 22];
            app.RX1_DAC_ISpinnerLabel.Text = 'RX1_DAC_I';

            % Create RX1_DAC_QSpinnerLabel
            app.RX1_DAC_QSpinnerLabel = uilabel(app.UIFigure);
            app.RX1_DAC_QSpinnerLabel.HorizontalAlignment = 'right';
            app.RX1_DAC_QSpinnerLabel.Position = [8 158 76 22];
            app.RX1_DAC_QSpinnerLabel.Text = 'RX1_DAC_Q';

            % Create CMSpinnerLabel
            app.CMSpinnerLabel = uilabel(app.UIFigure);
            app.CMSpinnerLabel.HorizontalAlignment = 'right';
            app.CMSpinnerLabel.Position = [364 66 25 22];
            app.CMSpinnerLabel.Text = 'CM';

            % Create CMSpinner
            app.CMSpinner = uispinner(app.UIFigure);
            app.CMSpinner.Limits = [0 15];
            app.CMSpinner.ValueChangedFcn = createCallbackFcn(app, @CMSpinnerValueChanged, true);
            app.CMSpinner.Position = [404 66 45 22];
            app.CMSpinner.Value = 4;

            % Create RMSpinnerLabel
            app.RMSpinnerLabel = uilabel(app.UIFigure);
            app.RMSpinnerLabel.HorizontalAlignment = 'right';
            app.RMSpinnerLabel.Position = [364 46 25 22];
            app.RMSpinnerLabel.Text = 'RM';

            % Create RMSpinner
            app.RMSpinner = uispinner(app.UIFigure);
            app.RMSpinner.Limits = [0 15];
            app.RMSpinner.ValueChangedFcn = createCallbackFcn(app, @RMSpinnerValueChanged, true);
            app.RMSpinner.Position = [404 46 45 22];
            app.RMSpinner.Value = 2;

            % Create CM2SpinnerLabel
            app.CM2SpinnerLabel = uilabel(app.UIFigure);
            app.CM2SpinnerLabel.HorizontalAlignment = 'right';
            app.CM2SpinnerLabel.Position = [214 107 30 22];
            app.CM2SpinnerLabel.Text = 'CM2';

            % Create CM2Spinner
            app.CM2Spinner = uispinner(app.UIFigure);
            app.CM2Spinner.Limits = [0 7];
            app.CM2Spinner.ValueChangedFcn = createCallbackFcn(app, @CM2SpinnerValueChanged, true);
            app.CM2Spinner.Position = [259 107 45 22];
            app.CM2Spinner.Value = 2;

            % Create R1SpinnerLabel
            app.R1SpinnerLabel = uilabel(app.UIFigure);
            app.R1SpinnerLabel.HorizontalAlignment = 'right';
            app.R1SpinnerLabel.Position = [219 87 25 22];
            app.R1SpinnerLabel.Text = 'R1';

            % Create RM2SpinnerLabel
            app.RM2SpinnerLabel = uilabel(app.UIFigure);
            app.RM2SpinnerLabel.HorizontalAlignment = 'right';
            app.RM2SpinnerLabel.Position = [52 107 30 22];
            app.RM2SpinnerLabel.Text = 'RM2';

            % Create RM2Spinner
            app.RM2Spinner = uispinner(app.UIFigure);
            app.RM2Spinner.Limits = [0 15];
            app.RM2Spinner.ValueChangedFcn = createCallbackFcn(app, @RM2SpinnerValueChanged, true);
            app.RM2Spinner.Position = [97 107 45 22];
            app.RM2Spinner.Value = 5;

            % Create R3SpinnerLabel
            app.R3SpinnerLabel = uilabel(app.UIFigure);
            app.R3SpinnerLabel.HorizontalAlignment = 'right';
            app.R3SpinnerLabel.Position = [57 87 25 22];
            app.R3SpinnerLabel.Text = 'R3';

            % Create R3Spinner
            app.R3Spinner = uispinner(app.UIFigure);
            app.R3Spinner.Limits = [0 7];
            app.R3Spinner.ValueChangedFcn = createCallbackFcn(app, @R3SpinnerValueChanged, true);
            app.R3Spinner.Position = [97 87 45 22];
            app.R3Spinner.Value = 3;

            % Create C2SpinnerLabel
            app.C2SpinnerLabel = uilabel(app.UIFigure);
            app.C2SpinnerLabel.HorizontalAlignment = 'right';
            app.C2SpinnerLabel.Position = [57 66 25 22];
            app.C2SpinnerLabel.Text = 'C2';

            % Create C2Spinner
            app.C2Spinner = uispinner(app.UIFigure);
            app.C2Spinner.Limits = [0 7];
            app.C2Spinner.ValueChangedFcn = createCallbackFcn(app, @C2SpinnerValueChanged, true);
            app.C2Spinner.Position = [97 66 45 22];
            app.C2Spinner.Value = 2;

            % Create C1SpinnerLabel
            app.C1SpinnerLabel = uilabel(app.UIFigure);
            app.C1SpinnerLabel.HorizontalAlignment = 'right';
            app.C1SpinnerLabel.Position = [57 46 25 22];
            app.C1SpinnerLabel.Text = 'C1';

            % Create C1Spinner
            app.C1Spinner = uispinner(app.UIFigure);
            app.C1Spinner.Limits = [0 31];
            app.C1Spinner.ValueChangedFcn = createCallbackFcn(app, @C1SpinnerValueChanged, true);
            app.C1Spinner.Position = [97 46 45 22];
            app.C1Spinner.Value = 14;

            % Create R1Spinner
            app.R1Spinner = uispinner(app.UIFigure);
            app.R1Spinner.Limits = [0 1];
            app.R1Spinner.ValueChangedFcn = createCallbackFcn(app, @R1SpinnerValueChanged, true);
            app.R1Spinner.Position = [259 87 45 22];

            % Create R2SpinnerLabel
            app.R2SpinnerLabel = uilabel(app.UIFigure);
            app.R2SpinnerLabel.HorizontalAlignment = 'right';
            app.R2SpinnerLabel.Position = [219 66 25 22];
            app.R2SpinnerLabel.Text = 'R2';

            % Create R2Spinner
            app.R2Spinner = uispinner(app.UIFigure);
            app.R2Spinner.Limits = [0 1];
            app.R2Spinner.ValueChangedFcn = createCallbackFcn(app, @R2SpinnerValueChanged, true);
            app.R2Spinner.Position = [259 66 45 22];

            % Create CFSpinnerLabel
            app.CFSpinnerLabel = uilabel(app.UIFigure);
            app.CFSpinnerLabel.HorizontalAlignment = 'right';
            app.CFSpinnerLabel.Position = [219 46 25 22];
            app.CFSpinnerLabel.Text = 'CF';

            % Create CFSpinner
            app.CFSpinner = uispinner(app.UIFigure);
            app.CFSpinner.Limits = [0 7];
            app.CFSpinner.ValueChangedFcn = createCallbackFcn(app, @CFSpinnerValueChanged, true);
            app.CFSpinner.Position = [259 46 45 22];

            % Create SaveRegsButton
            app.SaveRegsButton = uibutton(app.UIFigure, 'push');
            app.SaveRegsButton.ButtonPushedFcn = createCallbackFcn(app, @SaveRegsButtonPushed, true);
            app.SaveRegsButton.Position = [100 219 100 22];
            app.SaveRegsButton.Text = 'Save Regs';

            % Create LoadRegsButton
            app.LoadRegsButton = uibutton(app.UIFigure, 'push');
            app.LoadRegsButton.ButtonPushedFcn = createCallbackFcn(app, @LoadRegsButtonPushed, true);
            app.LoadRegsButton.Position = [360 219 100 22];
            app.LoadRegsButton.Text = 'Load Regs';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = rxBoardControl_exported

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