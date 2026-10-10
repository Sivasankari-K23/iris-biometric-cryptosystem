%% create_results_barchart.m
% Creates a clean, poster-ready HORIZONTAL bar chart of your final
% results (GAR, FAR) and saves it as a high-resolution PNG.

clear; clc;

%% ---------------- YOUR RESULTS ----------------
% each label is its own line - horizontal bars handle long text cleanly
categoryLabels = {'False Accept Rate' newline '(unauthorized)', ...
                   'False Accept Rate' newline '(authorized cross)', ...
                   'Genuine Accept Rate' newline '(GAR)'};
values = [0.00, 0.00, 96.67];  % reversed order so GAR appears at TOP of chart

%% ---------------- CREATE FIGURE ----------------
fig = figure('Color', 'white', 'Position', [100 100 900 500]);

barColors = [0.75 0.20 0.20;   % red - FAR (unauthorized)
             0.75 0.20 0.20;   % red - FAR (authorized cross)
             0.20 0.55 0.30];  % green - GAR

b = barh(values, 0.55, 'FaceColor', 'flat');
for i = 1:numel(values)
    b.CData(i,:) = barColors(i,:);
end

xlim([0 110]);
xlabel('Percentage (%)', 'FontSize', 14, 'FontWeight', 'bold');

set(gca, 'YTickLabel', categoryLabels, 'FontSize', 13, 'FontWeight', 'bold');

title('Iris-Based Fuzzy Vault: Final Performance', 'FontSize', 17, 'FontWeight', 'bold');
subtitle('30 Authorized Users | 10,890 Impostor Attempts Tested', 'FontSize', 11, 'FontAngle', 'italic');

grid on;
ax = gca;
ax.XGrid = 'on';
ax.YGrid = 'off';
box off;
ax.FontSize = 12;

% add value labels at the end of each bar
for i = 1:numel(values)
    text(values(i) + 2, i, sprintf('%.2f%%', values(i)), ...
        'VerticalAlignment', 'middle', 'FontSize', 14, 'FontWeight', 'bold');
end

%% ---------------- SAVE HIGH-RESOLUTION PNG ----------------
exportgraphics(fig, 'results_barchart.png', 'Resolution', 300);
fprintf('Saved results_barchart.png (300 DPI, ready for poster use)\n');
