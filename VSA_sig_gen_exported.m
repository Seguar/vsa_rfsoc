classdef VSA_sig_gen_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure  matlab.ui.Figure
        Button_2  matlab.ui.control.Button
        Button    matlab.ui.control.Button
        UITable   matlab.ui.control.Table
    end

    
    properties (Access = private)
        tabData;        
        emptyRow = zeros(1,5);
        minRow = 1;
        minColl = 5;
        indices;
    end
    
    methods (Access = private)
        
        function updTab(app)             
            app.UITable.Data = app.UITable.Data;
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.UITable.Data = app.emptyRow;
            app.indices = size(app.UITable.Data);
%             updTab(app)
        end

        % Cell edit callback: UITable
        function UITableCellEdit(app, event)
            [row, col] = event.Indices;
            app.UITable.Data(row, col) = event.NewData;
%             updTab(app)
        end

        % Button pushed function: Button_2
        function Button_2Pushed(app, event)
            app.indices
            if app.indices(1) > size(app.UITable.Data, 1)
                app.indices(1) = size(app.UITable.Data, 1);
            end
            app.UITable.Data(app.indices(1),:) = [];
%             updTab(app)
        end

        % Button pushed function: Button
        function ButtonPushed(app, event)
%             app.minRow = app.minRow + 1;
            app.indices
            if app.indices(1) > size(app.UITable.Data, 1)
                app.indices(1) = size(app.UITable.Data, 1);
            else
                rowToInsert = app.indices(1);
            end
            if size(app.UITable.Data, 1) > 1
                app.UITable.Data = [app.UITable.Data(1:rowToInsert,:); app.emptyRow; app.UITable.Data(rowToInsert+1:end,:)];
            else
                app.UITable.Data = [app.UITable.Data(1:rowToInsert,:); app.emptyRow];
            end
%             updTab(app)
        end

        % Cell selection callback: UITable
        function UITableCellSelection(app, event)
            event.Indices
            app.indices = event.Indices;            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'MATLAB App';

            % Create UITable
            app.UITable = uitable(app.UIFigure);
            app.UITable.ColumnName = {'Name'; 'Type'; 'Fc'; 'Amp'; 'Deg'};
            app.UITable.RowName = {};
            app.UITable.ColumnSortable = true;
            app.UITable.ColumnEditable = true;
            app.UITable.CellEditCallback = createCallbackFcn(app, @UITableCellEdit, true);
            app.UITable.CellSelectionCallback = createCallbackFcn(app, @UITableCellSelection, true);
            app.UITable.Position = [17 235 379 217];

            % Create Button
            app.Button = uibutton(app.UIFigure, 'push');
            app.Button.ButtonPushedFcn = createCallbackFcn(app, @ButtonPushed, true);
            app.Button.Position = [379 452 17 21];
            app.Button.Text = '+';

            % Create Button_2
            app.Button_2 = uibutton(app.UIFigure, 'push');
            app.Button_2.ButtonPushedFcn = createCallbackFcn(app, @Button_2Pushed, true);
            app.Button_2.Position = [361 452 17 21];
            app.Button_2.Text = '-';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = VSA_sig_gen_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

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