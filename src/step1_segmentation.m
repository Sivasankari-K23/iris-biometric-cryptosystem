%% step1_segment_30people_v3.m
% Segments all 30 authorized people + unauthorized folders using
% ADAPTIVE per-image thresholding (diagnostic showed this finds a much
% more complete, correctly-sized pupil blob than one fixed threshold).
%
% Includes a fallback: if the first adaptive attempt doesn't find a
% plausible pupil-sized blob, tries a few other threshold strengths
% before giving up on that image.

clear; clc;

%% ---------------- SETTINGS ----------------
datasetFolder = 'C:\Users\DELL\Documents\MATLAB\Iris_Fuzzy_Vault\Dataset';

minPupilDiameter = 45;
maxPupilDiameter = 135;

% Try these Otsu multipliers in order until one finds a valid pupil blob
thresholdMultipliers = [0.5, 0.4, 0.6, 0.7, 0.3];

irisRadiusMultiplier = 1.55;
irisRadiusMin = 75;
irisRadiusMax = 95;

%% ---------------- FIND ALL SUBFOLDERS ----------------
allFolders = dir(datasetFolder);
allFolders = allFolders([allFolders.isdir]);
allFolders = allFolders(~ismember({allFolders.name}, {'.', '..'}));

authorizedFolders = {};
unauthorizedFolders = {};
for i = 1:numel(allFolders)
    name = allFolders(i).name;
    if startsWith(name, 'Person')
        authorizedFolders{end+1} = name; %#ok<AGROW>
    else
        unauthorizedFolders{end+1} = name; %#ok<AGROW>
    end
end

fprintf('Found %d authorized (Person) folders and %d unauthorized folders.\n', ...
    numel(authorizedFolders), numel(unauthorizedFolders));

%% ---------------- SEGMENT AUTHORIZED ----------------
fprintf('\n=== Segmenting AUTHORIZED people ===\n');
authorizedResults = processFolderSet(datasetFolder, authorizedFolders, ...
    minPupilDiameter, maxPupilDiameter, thresholdMultipliers, ...
    irisRadiusMultiplier, irisRadiusMin, irisRadiusMax, true);

okCount = sum([authorizedResults.ok]);
fprintf('\nAuthorized segmentation done: %d OK, %d skipped (out of %d total)\n', ...
    okCount, numel(authorizedResults)-okCount, numel(authorizedResults));

%% ---------------- SEGMENT UNAUTHORIZED ----------------
fprintf('\n=== Segmenting UNAUTHORIZED (imposter) people ===\n');
unauthorizedResults = processFolderSet(datasetFolder, unauthorizedFolders, ...
    minPupilDiameter, maxPupilDiameter, thresholdMultipliers, ...
    irisRadiusMultiplier, irisRadiusMin, irisRadiusMax, false);

okCountU = sum([unauthorizedResults.ok]);
fprintf('Unauthorized segmentation done: %d OK, %d skipped (out of %d total)\n', ...
    okCountU, numel(unauthorizedResults)-okCountU, numel(unauthorizedResults));

%% ---------------- SAVE RESULTS ----------------
save('segmentation_results_30.mat', 'authorizedResults', 'unauthorizedResults');
fprintf('\nSaved all segmentation results to segmentation_results_30.mat\n');
fprintf('Next step: normalization (unwrap iris ring into rectangle) for all OK entries.\n');


%% ==========================================================
%% HELPER: process a set of folders
%% ==========================================================
function results = processFolderSet(datasetFolder, folderList, minPupilDiameter, maxPupilDiameter, ...
        thresholdMultipliers, irisRadiusMultiplier, irisRadiusMin, irisRadiusMax, verbose)

    results = struct('personName', {}, 'imageName', {}, 'imagePath', {}, ...
        'pupilCenter', {}, 'pupilRadius', {}, 'irisCenter', {}, 'irisRadius', {}, 'ok', {});

    for p = 1:numel(folderList)
        folderName = folderList{p};
        folderPath = fullfile(datasetFolder, folderName);

        imgFiles = [dir(fullfile(folderPath, '*.jpg')); ...
                    dir(fullfile(folderPath, '*.jpeg')); ...
                    dir(fullfile(folderPath, '*.png')); ...
                    dir(fullfile(folderPath, '*.bmp'))];

        for i = 1:numel(imgFiles)
            imgPath = fullfile(imgFiles(i).folder, imgFiles(i).name);

            result = segmentSingleImageAdaptive(imgPath, minPupilDiameter, maxPupilDiameter, ...
                thresholdMultipliers, irisRadiusMultiplier, irisRadiusMin, irisRadiusMax);

            entry.personName = folderName;
            entry.imageName = imgFiles(i).name;
            entry.imagePath = imgPath;
            entry.pupilCenter = result.pupilCenter;
            entry.pupilRadius = result.pupilRadius;
            entry.irisCenter = result.irisCenter;
            entry.irisRadius = result.irisRadius;
            entry.ok = result.ok;

            results(end+1) = entry; %#ok<AGROW>

            if verbose && ~result.ok
                fprintf('  SKIPPED: %s / %s (%s)\n', folderName, imgFiles(i).name, result.reason);
            end
        end

        if verbose && mod(p, 5) == 0
            fprintf('  Processed %d / %d...\n', p, numel(folderList));
        end
    end
end


%% ==========================================================
%% HELPER: segment one image, trying multiple adaptive thresholds
%% ==========================================================
function result = segmentSingleImageAdaptive(imgPath, minPupilDiameter, maxPupilDiameter, ...
        thresholdMultipliers, irisRadiusMultiplier, irisRadiusMin, irisRadiusMax)

    result.ok = false;
    result.pupilCenter = [];
    result.pupilRadius = [];
    result.irisCenter = [];
    result.irisRadius = [];
    result.reason = '';

    try
        I = imread(imgPath);
        if ndims(I) == 3
            I = rgb2gray(I);
        end
        I = im2double(I);
        I_smooth = imgaussfilt(I, 2);

        otsuLevel = graythresh(I_smooth);

        for m = 1:numel(thresholdMultipliers)
            threshVal = otsuLevel * thresholdMultipliers(m);

            BW = I_smooth < threshVal;
            BW = bwareaopen(BW, 100);
            BW = imfill(BW, 'holes');

            CC = bwconncomp(BW);
            stats = regionprops(CC, 'Area', 'Centroid', 'EquivDiameter');

            if isempty(stats)
                continue;
            end

            areas = [stats.Area];
            [~, order] = sort(areas, 'descend');

            for k = 1:length(order)
                s = stats(order(k));
                diameter = s.EquivDiameter;

                if diameter >= minPupilDiameter && diameter <= maxPupilDiameter
                    pupilCenter = s.Centroid;
                    pupilRadius = diameter / 2;

                    irisCenter = pupilCenter;
                    irisRadius = round(irisRadiusMultiplier * pupilRadius);
                    irisRadius = max(irisRadiusMin, irisRadius);
                    irisRadius = min(irisRadiusMax, irisRadius);

                    result.pupilCenter = pupilCenter;
                    result.pupilRadius = pupilRadius;
                    result.irisCenter = irisCenter;
                    result.irisRadius = irisRadius;
                    result.ok = true;
                    return; % success - stop trying more thresholds
                end
            end
        end

        result.reason = 'no valid pupil blob found across all threshold attempts';

    catch ME
        result.reason = ME.message;
    end
end
