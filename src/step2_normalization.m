%% step2_normalize_30people.m
% Unwraps each segmented iris (pupil boundary -> iris boundary annulus)
% into a fixed-size 64x360 rectangle using the standard rubber-sheet
% model. Same output size as your original 10-person run, so downstream
% Gabor feature extraction code can be reused unchanged.
%
% Requires segmentation_results_30.mat (from step1_segment_30people_v3.m)

clear; clc;

load('segmentation_results_30.mat', 'authorizedResults', 'unauthorizedResults');

%% ---------------- SETTINGS ----------------
numRadialSamples = 64;   % rows of output
numAngularSamples = 360; % columns of output

%% ---------------- NORMALIZE AUTHORIZED ----------------
fprintf('=== Normalizing AUTHORIZED people ===\n');
normalizedAuthorized = normalizeSet(authorizedResults, numRadialSamples, numAngularSamples);

%% ---------------- NORMALIZE UNAUTHORIZED ----------------
fprintf('\n=== Normalizing UNAUTHORIZED (imposter) people ===\n');
normalizedUnauthorized = normalizeSet(unauthorizedResults, numRadialSamples, numAngularSamples);

%% ---------------- SAVE ----------------
save('normalized_data_30.mat', 'normalizedAuthorized', 'normalizedUnauthorized');
fprintf('\nSaved normalized iris rectangles to normalized_data_30.mat\n');
fprintf('Next step: Gabor feature extraction -> binary iris codes.\n');


%% ==========================================================
%% HELPER: normalize a whole result set
%% ==========================================================
function normResults = normalizeSet(resultSet, numRadialSamples, numAngularSamples)

    okEntries = resultSet([resultSet.ok]);

    normResults = struct('personName', {}, 'imageName', {}, 'imagePath', {}, ...
        'normImage', {});

    for i = 1:numel(okEntries)
        entry = okEntries(i);

        I = imread(entry.imagePath);
        if ndims(I) == 3
            I = rgb2gray(I);
        end
        I = im2double(I);

        normImg = unwrapIris(I, entry.pupilCenter, entry.pupilRadius, ...
            entry.irisCenter, entry.irisRadius, numRadialSamples, numAngularSamples);

        outEntry.personName = entry.personName;
        outEntry.imageName = entry.imageName;
        outEntry.imagePath = entry.imagePath;
        outEntry.normImage = normImg;

        normResults(end+1) = outEntry; %#ok<AGROW>

        if mod(i, 20) == 0 || i == numel(okEntries)
            fprintf('  Normalized %d / %d images...\n', i, numel(okEntries));
        end
    end
end


%% ==========================================================
%% HELPER: unwrap one iris using the rubber-sheet model (vectorized)
%% ==========================================================
function normImg = unwrapIris(I, pupilCenter, pupilRadius, irisCenter, irisRadius, ...
        numRadialSamples, numAngularSamples)

    [imgH, imgW] = size(I);

    thetaVals = linspace(0, 2*pi, numAngularSamples + 1);
    thetaVals(end) = []; % avoid duplicate 0/2pi column

    rVals = linspace(0, 1, numRadialSamples)';

    % Build full coordinate grids for ALL sample points at once
    % (rows = radial steps, cols = angular steps)
    cosT = cos(thetaVals);  % 1 x numAngularSamples
    sinT = sin(thetaVals);

    xp = pupilCenter(1) + pupilRadius * cosT;  % 1 x numAngularSamples
    yp = pupilCenter(2) + pupilRadius * sinT;
    xi = irisCenter(1) + irisRadius * cosT;
    yi = irisCenter(2) + irisRadius * sinT;

    % broadcast: (numRadialSamples x 1) .* (1 x numAngularSamples) -> full grid
    X = (1 - rVals) .* xp + rVals .* xi;   % numRadialSamples x numAngularSamples
    Y = (1 - rVals) .* yp + rVals .* yi;

    X = min(max(X, 1), imgW);
    Y = min(max(Y, 1), imgH);

    % single vectorized call instead of 23,040 individual calls
    normImg = interp2(I, X, Y, 'linear', 0);
end
