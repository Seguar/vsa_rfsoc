function plot_handle = plotPrep(app, scan_axis)
%% Graph handles
min_ang = scan_axis(1);
max_ang = scan_axis(end);
clf(app.UIAxes);
clf(app.UIAxes2);
yspec = zeros(1, length(scan_axis));
plot_handle = plot(app.UIAxes, scan_axis, yspec);

app.UIAxes.XLim = [min_ang max_ang];
app.UIAxes2.XLim = [min_ang max_ang];
app.UIAxes.YLim = [0 1];
app.UIAxes2.YLim = [-30 0.5];
app.UIAxes.LineWidth = 1.5;
app.UIAxes2.LineWidth = 1.5;
app.UIAxes.XLabel.String  = ('\Theta^o');
app.UIAxes.YLabel.String  = ('Power');
app.UIAxes2.XLabel.String  = ('\Theta^o');
app.UIAxes2.YLabel.String  = ('Power');
app.UIAxes.FontSize = 16;
app.UIAxes2.FontSize = 16;