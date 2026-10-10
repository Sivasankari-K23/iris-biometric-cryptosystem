%% diagnose_segmentation_failures.m
% Reprocesses every SKIPPED image from segmentation_results_30.mat and
% shows what's actually happening: what blob diameters were found (even
% if outside the accepted range), and whether an adaptive per-image
% threshold would have found a better pupil-sized blob.
%
% This tells us the REAL numbers needed to fix the range, instead of
% guessing again.

clear; clc;

load('segmentation_results_30.mat', 'authorizedResults', 'unauthorizedResults');

allResults = [authorizedResults, unauthorizedResults];
failedResults = allResults(~[allResults.ok]);

fprintf('Total failed images: %d\n\n', numel(failedResults));

% Only show detailed diagnostics for a manageable sample
sampleSize = min(20, numel(failedResults));
fprintf('Showing detailed diagnostics for %d sample failures:\n', sampleSize);
fprintf('=========================================================\n');

allFoundDiameters = [];  % collect across ALL failures for a final summary

for i = 1:numel(failedResults)
    entry = failedResults(i);

    I = imread(entry.imagePath);
    if ndims(I) == 3
        I = rgb2gray(I);
    end
    I = im2double(I);
    I_smooth = imgaussfilt(I, 2);

    % ---- Try the ORIGINAL fixed threshold (0.25) ----
    BW_fixed = I_smooth < 0.25;
    BW_fixed = bwareaopen(BW_fixed, 100);
    BW_fixed = imfill(BW_fixed, 'holes');
    stats_fixed = regionprops(bwconncomp(BW_fixed), 'Area', 'EquivDiameter');

    diametersFixed = [];
    if ~isempty(stats_fixed)
        areas = [stats_fixed.Area];
        [~, order] = sort(areas, 'descend');
        diametersFixed = [stats_fixed(order).EquivDiameter];
    end

    % ---- Try an ADAPTIVE threshold (based on this image's own darkness) ----
    adaptiveThresh = graythresh(I_smooth) * 0.5; % half of Otsu's level, biased dark
    BW_adapt = I_smooth < adaptiveThresh;
    BW_adapt = bwareaopen(BW_adapt, 100);
    BW_adapt = imfill(BW_adapt, 'holes');
    stats_adapt = regionprops(bwconncomp(BW_adapt), 'Area', 'EquivDiameter');

    diametersAdapt = [];
    if ~isempty(stats_adapt)
        areas = [stats_adapt.Area];
        [~, order] = sort(areas, 'descend');
        diametersAdapt = [stats_adapt(order).EquivDiameter];
    end

    if i <= sampleSize
        fprintf('\n[%d] %s / %s\n', i, entry.personName, entry.imageName);
        if isempty(diametersFixed)
            fprintf('    Fixed thresh (0.25): no blobs found at all\n');
        else
            fprintf('    Fixed thresh (0.25): top blob diameters = %s\n', ...
                mat2str(round(diametersFixed(1:min(3,end)), 1)));
        end
        if isempty(diametersAdapt)
            fprintf('    Adaptive thresh (%.3f): no blobs found at all\n', adaptiveThresh);
        else
            fprintf('    Adaptive thresh (%.3f): top blob diameters = %s\n', ...
                adaptiveThresh, mat2str(round(diametersAdapt(1:min(3,end)), 1)));
        end
    end

    allFoundDiameters = [allFoundDiameters, diametersFixed, diametersAdapt]; %#ok<AGROW>
end

fprintf('\n=========================================================\n');
if ~isempty(allFoundDiameters)
    fprintf('Across all failures, blob diameters found ranged: %.1f to %.1f\n', ...
        min(allFoundDiameters), max(allFoundDiameters));
    fprintf('Median: %.1f, 10th pct: %.1f, 90th pct: %.1f\n', ...
        median(allFoundDiameters), prctile(allFoundDiameters,10), prctile(allFoundDiameters,90));
else
    fprintf('No blobs found at all in any failed image, even with adaptive threshold.\n');
    fprintf('This suggests these specific images may have different lighting/format issues.\n');
end
