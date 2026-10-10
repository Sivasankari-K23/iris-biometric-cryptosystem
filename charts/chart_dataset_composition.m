%% chart_dataset_composition.m
% Shows the scale of your dataset - authorized vs unauthorized.

clear; clc;

categories = {'Authorized' newline '(30 people)', 'Unauthorized' newline '(57 people)'};
imageCounts = [120, 305];

fig = figure('Color', 'white', 'Position', [100 100 750 500]);

barColors = [0.20 0.45 0.65;   % blue - authorized
             0.55 0.55 0.55];  % grey - unauthorized

b = bar(imageCounts, 0.45, 'FaceColor', 'flat');
for i = 1:numel(imageCounts)
    b.CData(i,:) = barColors(i,:);
end

ylim([0 350]);
ylabel('Number of Images', 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'XTickLabel', categories, 'FontSize', 13, 'FontWeight', 'bold');
xtickangle(0);

title('Dataset Composition', 'FontSize', 17, 'FontWeight', 'bold');
subtitle('425 total iris images used for testing and evaluation', 'FontSize', 11, 'FontAngle', 'italic');

grid on;
ax = gca;
ax.YGrid = 'on';
ax.XGrid = 'off';
box off;
ax.FontSize = 12;

for i = 1:numel(imageCounts)
    text(i, imageCounts(i) + 10, sprintf('%d images', imageCounts(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 14, 'FontWeight', 'bold');
end

exportgraphics(fig, 'chart_dataset_composition.png', 'Resolution', 300);
fprintf('Saved chart_dataset_composition.png\n');
