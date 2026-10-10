%% chart_hamming_distance.m
% Shows the Hamming distance separation - core evidence that the iris
% codes actually distinguish between people.

clear; clc;

categories = {'Same Person', 'Different Person'};
values = [0.3671, 0.5000];

fig = figure('Color', 'white', 'Position', [100 100 850 550]);

barColors = [0.15 0.50 0.25;   % green - good (low distance = similar/same person)
             0.75 0.20 0.20];  % red - different person (high distance)

b = bar(values, 0.45, 'FaceColor', 'flat');
for i = 1:numel(values)
    b.CData(i,:) = barColors(i,:);
end

ylim([0 0.6]);
ylabel('Mean Hamming Distance', 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'XTickLabel', categories, 'FontSize', 13, 'FontWeight', 'bold');
xtickangle(0);

title('Iris Code Discriminability', 'FontSize', 17, 'FontWeight', 'bold');

hold on;
yline(0.5, '--', 'Random baseline (0.5)', 'Color', [0.4 0.4 0.4], ...
    'LabelHorizontalAlignment', 'left', 'FontSize', 10, 'LineWidth', 1.2);

grid on;
ax = gca;
ax.YGrid = 'on';
ax.XGrid = 'off';
box off;
ax.FontSize = 12;

for i = 1:numel(values)
    text(i, values(i) + 0.03, sprintf('%.4f', values(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 14, 'FontWeight', 'bold');
end

% highlight the separation gap
gap = values(2) - values(1);
annotation('doublearrow', [0.5 0.5], [0.38 0.62], 'Color', [0.2 0.2 0.6], 'LineWidth', 1.2);
text(1.5, mean(values), sprintf('  gap: %.4f', gap), 'FontSize', 11, ...
    'Color', [0.2 0.2 0.6], 'FontWeight', 'bold');

exportgraphics(fig, 'chart_hamming_distance.png', 'Resolution', 300);
fprintf('Saved chart_hamming_distance.png\n');
