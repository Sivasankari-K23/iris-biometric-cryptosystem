%% chart_segmentation_fix.m
% Shows how segmentation success rate improved across your three
% detection method attempts.

clear; clc;

stages = {'Hough Circle' newline '(original method)', ...
          'Fixed Threshold', ...
          'Adaptive Threshold' newline '(final method)'};
values = [44.17, 71.67, 100.00];  % 53/120, 86/120, 120/120

fig = figure('Color', 'white', 'Position', [100 100 850 500]);

barColors = [0.75 0.30 0.25;   % red-ish - worst
             0.80 0.65 0.20;   % amber - middle
             0.15 0.50 0.25];  % green - best

b = bar(values, 0.55, 'FaceColor', 'flat');
for i = 1:numel(values)
    b.CData(i,:) = barColors(i,:);
end

ylim([0 115]);
ylabel('Segmentation Success Rate (%)', 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'XTickLabel', stages, 'FontSize', 12, 'FontWeight', 'bold');
xtickangle(0);

title('Segmentation Reliability Across Methods', 'FontSize', 17, 'FontWeight', 'bold');
subtitle('Tested on 120 authorized iris images', 'FontSize', 11, 'FontAngle', 'italic');

grid on;
ax = gca;
ax.YGrid = 'on';
ax.XGrid = 'off';
box off;
ax.FontSize = 12;

for i = 1:numel(values)
    text(i, values(i) + 3, sprintf('%.1f%%', values(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 14, 'FontWeight', 'bold');
end

exportgraphics(fig, 'chart_segmentation_fix.png', 'Resolution', 300);
fprintf('Saved chart_segmentation_fix.png\n');
