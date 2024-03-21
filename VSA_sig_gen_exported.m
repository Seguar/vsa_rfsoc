classdef VSA_sig_gen_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure   matlab.ui.Figure
        Toolbar    matlab.ui.container.Toolbar
        PushTool   matlab.ui.container.toolbar.PushTool
        PushTool2  matlab.ui.container.toolbar.PushTool
        PushTool3  matlab.ui.container.toolbar.PushTool
        PushTool4  matlab.ui.container.toolbar.PushTool
        UITable    matlab.ui.control.Table
    end

    
    properties (Access = private)
        emptyRow = {};
        minRow = 1;
        minColl = 6;
        indices;
        tabData;
        nameOpts = categorical({'Option 1', 'Option 2'});
        typeOpts = categorical({'CW', 'OFDM', 'WLAN', 'Custom'});

    end
    
    methods (Access = private)        
        function updTab(app)             
            app.UITable.Data = table(app.tabData);
            app.UITable.ColumnEditable = true;
%             app.UITable.
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.emptyRow = {app.nameOpts(1), app.typeOpts(1), 0, 0, 0, 0};
            app.tabData = app.emptyRow;
            app.indices = size(app.tabData);
%             app.UITable.ColumnFormat = {{'CW', 'OFDM', 'WLAN', 'Custom'}};
            updTab(app)
        end

        % Cell edit callback: UITable
        function UITableCellEdit(app, event)
            [row, col] = event.Indices;
            app.tabData(row, col) = event.NewData;
            updTab(app)
        end

        % Clicked callback: PushTool3
        function MinusRow(app, event)
            app.indices
            if app.indices(1) > size(app.tabData, 1)
                app.indices(1) = size(app.tabData, 1);
            end
            app.tabData(app.indices(1),:) = [];
            updTab(app)
        end

        % Clicked callback: PushTool4
        function PlusRow(app, event)
%             app.minRow = app.minRow + 1;
            app.indices
            if app.indices(1) > size(app.tabData, 1)
                app.indices(1) = size(app.tabData, 1);
            else
                rowToInsert = app.indices(1);
            end
            if size(app.tabData, 1) > 1
                app.tabData = [app.tabData(1:rowToInsert,:); app.emptyRow; app.tabData(rowToInsert+1:end,:)];
            else
                app.tabData = [app.tabData(1:rowToInsert,:); app.emptyRow];
            end
            updTab(app)
        end

        % Cell selection callback: UITable
        function UITableCellSelection(app, event)
            event.Indices
            app.indices = event.Indices;            
        end

        % Clicked callback: PushTool2
        function PushTool2Clicked(app, event)
            try
                writematrix(app.tabData, uiputfile('*.xls'))
            catch
                disp('Not correct file')
            end
        end

        % Clicked callback: PushTool
        function PushToolClicked(app, event)
            try
                app.tabData = readtable(uigetfile('*.xls'));
            catch
                disp('Not correct file')
            end
            updTab(app)
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 475 378];
            app.UIFigure.Name = 'MATLAB App';

            % Create Toolbar
            app.Toolbar = uitoolbar(app.UIFigure);

            % Create PushTool
            app.PushTool = uipushtool(app.Toolbar);
            app.PushTool.ClickedCallback = createCallbackFcn(app, @PushToolClicked, true);
            app.PushTool.Icon = 'FolderFileProject.svg';

            % Create PushTool2
            app.PushTool2 = uipushtool(app.Toolbar);
            app.PushTool2.ClickedCallback = createCallbackFcn(app, @PushTool2Clicked, true);
            app.PushTool2.Icon = 'Save.svg';

            % Create PushTool3
            app.PushTool3 = uipushtool(app.Toolbar);
            app.PushTool3.ClickedCallback = createCallbackFcn(app, @MinusRow, true);
            app.PushTool3.Icon = 'SubtractMinusRemove.svg';
            app.PushTool3.Separator = 'on';

            % Create PushTool4
            app.PushTool4 = uipushtool(app.Toolbar);
            app.PushTool4.ClickedCallback = createCallbackFcn(app, @PlusRow, true);
            app.PushTool4.Icon = 'AddPlus.svg';

            % Create UITable
            app.UITable = uitable(app.UIFigure);
            app.UITable.BackgroundColor = [1 1 1;0.9412 0.9412 0.9412];
            app.UITable.ColumnName = {'Name'; 'Type'; 'Fc'; 'Amplitude'; 'Angel'; 'State'};
            app.UITable.RowName = {};
            app.UITable.ColumnSortable = true;
            app.UITable.ColumnEditable = true;
            app.UITable.CellEditCallback = createCallbackFcn(app, @UITableCellEdit, true);
            app.UITable.CellSelectionCallback = createCallbackFcn(app, @UITableCellSelection, true);
            app.UITable.Position = [1 94 475 285];

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