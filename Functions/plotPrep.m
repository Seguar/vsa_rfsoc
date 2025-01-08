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
app.UIAxes.LineWidth = 2.5;
app.UIAxes2.LineWidth = 2.5;
% app.UIAxes.LineWidth = 4.5;
% app.UIAxes2.LineWidth = 4.5;
app.UIAxes.XLabel.String  = ('\Theta^o');
app.UIAxes.YLabel.String  = ('DOA Normalized Spectrum');
app.UIAxes2.XLabel.String  = ('\Theta^o');
app.UIAxes2.YLabel.String  = ('Gain Pattern (dB)');
% app.UIAxes.FontSize = 34;
% app.UIAxes2.FontSize = 34;
app.UIAxes.FontSize = 30;
app.UIAxes2.FontSize = 30;