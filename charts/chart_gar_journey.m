%% chart_gar_journey.m
% Shows the GAR improvement journey across your three iterations.

clear; clc;

stages = {'Basic Decoding' newline '(no rotation search)', ...
          '+ Rotation Search', ...
          '+ Combined Test' newline 'Images'};
values = [23.33, 53.33, 96.67];

fig = figure('Color', 'white', 'Position', [100 100 850 500]);

% green gradient - darker green = better result
barColors = [0.75 0.85 0.70;   % light green
             0.45 0.70 0.45;   % medium green
             0.15 0.50 0.25];  % dark green

b = bar(values, 0.55, 'FaceColor', 'flat');
for i = 1:numel(values)
    b.CData(i,:) = barColors(i,:);
end

ylim([0 110]);
ylabel('Genuine Accept Rate (%)', 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'XTickLabel', stages, 'FontSize', 12, 'FontWeight', 'bold');
xtickangle(0);

title('GAR Improvement Through Iterative Refinement', 'FontSize', 17, 'FontWeight', 'bold');
subtitle('Each stage adds one targeted fix to the verification pipeline', 'FontSize', 11, 'FontAngle', 'italic');

grid on;
ax = gca;
ax.YGrid = 'on';
ax.XGrid = 'off';
box off;
ax.FontSize = 12;

for i = 1:numel(values)
    text(i, values(i) + 3, sprintf('%.2f%%', values(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 14, 'FontWeight', 'bold');
end

% arrows showing progression
annotation('arrow', [0.36 0.49], [0.45 0.35], 'Color', [0.3 0.3 0.3], 'LineWidth', 1.5);
annotation('arrow', [0.63 0.76], [0.32 0.20], 'Color', [0.3 0.3 0.3], 'LineWidth', 1.5);

exportgraphics(fig, 'chart_gar_journey.png', 'Resolution', 300);
fprintf('Saved chart_gar_journey.png\n');
