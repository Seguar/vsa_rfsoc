classdef stepper_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure              matlab.ui.Figure
        DisableButton         matlab.ui.control.Button
        Reset0Button          matlab.ui.control.Button
        degButton_6           matlab.ui.control.Button
        degButton_5           matlab.ui.control.Button
        degButton_4           matlab.ui.control.Button
        degButton_3           matlab.ui.control.Button
        degButton_2           matlab.ui.control.Button
        degButton             matlab.ui.control.Button
        DegreeEditField       matlab.ui.control.NumericEditField
        DegreeEditFieldLabel  matlab.ui.control.Label
        Knob                  matlab.ui.control.Knob
        ChoseportandpressthebuttonButton  matlab.ui.control.Button
        PortListDropDown      matlab.ui.control.DropDown
        PortListLabel         matlab.ui.control.Label
    end

    
    properties (Access = public)
        port = [];
        portList = [];
        Arduino = [];
        angle = 0;
        angleLims = 180;
    end

    methods (Access = public)

        function updateFields(app)
            app.Knob.Value = app.angle;
            app.DegreeEditField.Value = app.angle;
        end
        
        function setAngle(app, value)
            writeline(app.Arduino, ['o ' num2str(value)]);
            readBack = readline(app.Arduino)
        end
    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            cd(fileparts(mfilename('fullpath')))
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

        % Button pushed function: ChoseportandpressthebuttonButton
        function ChoseportandpressthebuttonButtonPushed(app, event)
            if isempty(app.Arduino)
                app.Arduino = serialport(app.port,9600);
                app.ChoseportandpressthebuttonButton.Text = [app.port " connected"];
                app.ChoseportandpressthebuttonButton.BackgroundColor = 'g';
            else
                clear app.Arduino
                app.Arduino = [];
                app.ChoseportandpressthebuttonButton.Text = "Disconnected";
                app.ChoseportandpressthebuttonButton.BackgroundColor = 'r';
            end
        end

        % Value changed function: PortListDropDown
        function PortListDropDownValueChanged(app, event)
            app.port = app.PortListDropDown.Value;
        end

        % Value changed function: Knob
        function KnobValueChanged(app, event)
            app.angle = app.Knob.Value;
            app.angle = round(app.angle);
            app.DegreeEditField.Value = app.angle;

            setAngle(app, app.angle);
            updateFields(app);
        end

        % Value changed function: DegreeEditField
        function DegreeEditFieldValueChanged(app, event)
            app.angle = app.DegreeEditField.Value;
            app.Knob.Value = app.angle;

            setAngle(app, app.angle);
            updateFields(app);
        end

        % Button pushed function: Reset0Button
        function Reset0ButtonPushed(app, event)
            app.angle = 0;
            writeline(app.Arduino, 'w');
            updateFields(app);
        end

        % Button pushed function: DisableButton
        function DisableButtonPushed(app, event)
            writeline(app.Arduino, 's');

        end

        % Button pushed function: degButton
        function degButtonPushed(app, event)
            if app.angle - 1 <= -app.angleLims
                disp('Limmits')
            else
                app.angle = app.angle - 1;
                writeline(app.Arduino, 'a')
            end
            updateFields(app);
        end

        % Button pushed function: degButton_2
        function degButton_2Pushed(app, event)
            if app.angle - 10 <= -app.angleLims
                disp('Limmits')
            else
                app.angle = app.angle - 10;
                writeline(app.Arduino, 'q')
            end
            updateFields(app);
        end

        % Button pushed function: degButton_3
        function degButton_3Pushed(app, event)
            if app.angle - 90 <= -app.angleLims
                disp('Limmits')
            else
                app.angle = app.angle - 90;
                writeline(app.Arduino, 'r')
            end
            updateFields(app);
        end

        % Button pushed function: degButton_4
        function degButton_4Pushed(app, event)
            if app.angle + 1 >= app.angleLims
                disp('Limmits')
            else
                app.angle = app.angle + 1;
                writeline(app.Arduino, 'd')
            end
            updateFields(app);
        end

        % Button pushed function: degButton_5
        function degButton_5Pushed(app, event)
            if app.angle + 10 >= app.angleLims
                disp('Limmits')
            else
                app.angle = app.angle + 10;
                writeline(app.Arduino, 'e')
            end
            updateFields(app);
        end

        % Button pushed function: degButton_6
        function degButton_6Pushed(app, event)
            if app.angle + 90 >= app.angleLims
                disp('Limmits')
            else
                app.angle = app.angle + 90;
                writeline(app.Arduino, 'f')
            end
            updateFields(app);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 543 699];
            app.UIFigure.Name = 'MATLAB App';

            % Create PortListLabel
            app.PortListLabel = uilabel(app.UIFigure);
            app.PortListLabel.HorizontalAlignment = 'right';
            app.PortListLabel.Position = [99 659 49 22];
            app.PortListLabel.Text = 'Port List';

            % Create PortListDropDown
            app.PortListDropDown = uidropdown(app.UIFigure);
            app.PortListDropDown.DropDownOpeningFcn = createCallbackFcn(app, @PortListDropDownOpening, true);
            app.PortListDropDown.ValueChangedFcn = createCallbackFcn(app, @PortListDropDownValueChanged, true);
            app.PortListDropDown.Position = [163 659 100 22];

            % Create ChoseportandpressthebuttonButton
            app.ChoseportandpressthebuttonButton = uibutton(app.UIFigure, 'push');
            app.ChoseportandpressthebuttonButton.ButtonPushedFcn = createCallbackFcn(app, @ChoseportandpressthebuttonButtonPushed, true);
            app.ChoseportandpressthebuttonButton.Position = [288 659 186 22];
            app.ChoseportandpressthebuttonButton.Text = 'Chose port and press the button';

            % Create Knob
            app.Knob = uiknob(app.UIFigure, 'continuous');
            app.Knob.Limits = [-180 180];
            app.Knob.ValueChangedFcn = createCallbackFcn(app, @KnobValueChanged, true);
            app.Knob.Position = [102 214 352 352];

            % Create DegreeEditFieldLabel
            app.DegreeEditFieldLabel = uilabel(app.UIFigure);
            app.DegreeEditFieldLabel.HorizontalAlignment = 'right';
            app.DegreeEditFieldLabel.Position = [205 170 44 22];
            app.DegreeEditFieldLabel.Text = 'Degree';

            % Create DegreeEditField
            app.DegreeEditField = uieditfield(app.UIFigure, 'numeric');
            app.DegreeEditField.ValueChangedFcn = createCallbackFcn(app, @DegreeEditFieldValueChanged, true);
            app.DegreeEditField.Position = [264 170 100 22];

            % Create degButton
            app.degButton = uibutton(app.UIFigure, 'push');
            app.degButton.ButtonPushedFcn = createCallbackFcn(app, @degButtonPushed, true);
            app.degButton.Position = [178 127 100 23];
            app.degButton.Text = '-1 deg';

            % Create degButton_2
            app.degButton_2 = uibutton(app.UIFigure, 'push');
            app.degButton_2.ButtonPushedFcn = createCallbackFcn(app, @degButton_2Pushed, true);
            app.degButton_2.Position = [178 97 100 23];
            app.degButton_2.Text = '-10 deg';

            % Create degButton_3
            app.degButton_3 = uibutton(app.UIFigure, 'push');
            app.degButton_3.ButtonPushedFcn = createCallbackFcn(app, @degButton_3Pushed, true);
            app.degButton_3.Position = [178 67 100 23];
            app.degButton_3.Text = '-90 deg';

            % Create degButton_4
            app.degButton_4 = uibutton(app.UIFigure, 'push');
            app.degButton_4.ButtonPushedFcn = createCallbackFcn(app, @degButton_4Pushed, true);
            app.degButton_4.Position = [299 127 100 23];
            app.degButton_4.Text = '+1 deg';

            % Create degButton_5
            app.degButton_5 = uibutton(app.UIFigure, 'push');
            app.degButton_5.ButtonPushedFcn = createCallbackFcn(app, @degButton_5Pushed, true);
            app.degButton_5.Position = [299 97 100 23];
            app.degButton_5.Text = '+10 deg';

            % Create degButton_6
            app.degButton_6 = uibutton(app.UIFigure, 'push');
            app.degButton_6.ButtonPushedFcn = createCallbackFcn(app, @degButton_6Pushed, true);
            app.degButton_6.Position = [299 67 100 23];
            app.degButton_6.Text = '+90 deg';

            % Create Reset0Button
            app.Reset0Button = uibutton(app.UIFigure, 'push');
            app.Reset0Button.ButtonPushedFcn = createCallbackFcn(app, @Reset0ButtonPushed, true);
            app.Reset0Button.Position = [236 39 100 23];
            app.Reset0Button.Text = 'Reset 0';

            % Create DisableButton
            app.DisableButton = uibutton(app.UIFigure, 'push');
            app.DisableButton.ButtonPushedFcn = createCallbackFcn(app, @DisableButtonPushed, true);
            app.DisableButton.Position = [237 11 100 23];
            app.DisableButton.Text = 'Disable';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = stepper_exported

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