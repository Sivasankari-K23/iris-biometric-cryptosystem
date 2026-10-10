%% demo_identify.m
% IDENTIFICATION DEMO: give it ONE test image, and it checks that image
% against EVERY enrolled vault (all 30 people), reporting:
%   - "ACCESS GRANTED: <Name>" if it matches one of them
%   - "ACCESS DENIED - Unauthorized" if it matches none of them
%
% Runs the full pipeline from scratch on the given image: segmentation
% -> normalization -> Gabor feature extraction -> tries unlocking every
% vault with rotation search.
%
% Requires: vaults_30.mat, hashKey.m

clear; clc;

%% ---------------- SELECT TEST IMAGE (file picker) ----------------
defaultFolder = 'C:\Users\DELL\Documents\MATLAB\Iris_Fuzzy_Vault\Dataset';

[fileName, filePath] = uigetfile( ...
    {'*.jpg;*.jpeg;*.png;*.bmp', 'Image Files (*.jpg, *.jpeg, *.png, *.bmp)'}, ...
    'Select an iris image to test', ...
    defaultFolder);

if isequal(fileName, 0)
    fprintf('No image selected. Demo cancelled.\n');
    return;
end

testImagePath = fullfile(filePath, fileName);

load('vaults_30.mat', 'vaults');

shiftRange = -15:15;
wavelength = 8;
orientation = 0;

fprintf('========================================================\n');
fprintf('  IRIS-BASED FUZZY VAULT - IDENTIFICATION DEMO\n');
fprintf('========================================================\n');
fprintf('Test image: %s\n\n', testImagePath);

%% ---------------- STEP 1: SEGMENT ----------------
if ~exist(testImagePath, 'file')
    error('Image file not found: %s', testImagePath);
end

fprintf('Processing image...\n');
segResult = segmentSingleImageAdaptive(testImagePath, 45, 135, [0.5 0.4 0.6 0.7 0.3]);

if ~segResult.ok
    fprintf('\n*** COULD NOT PROCESS IMAGE *** (segmentation failed: %s)\n', segResult.reason);
    fprintf('Try a clearer / better-lit iris image.\n');
    return;
end

%% ---------------- STEP 2: NORMALIZE ----------------
I = imread(testImagePath);
if ndims(I) == 3, I = rgb2gray(I); end
I = im2double(I);
normImg = unwrapIrisVectorized(I, segResult.pupilCenter, segResult.pupilRadius, ...
    segResult.irisCenter, segResult.irisRadius, 64, 360);

%% ---------------- STEP 3: GABOR FEATURE EXTRACTION ----------------
gaborFilt = gabor(wavelength, orientation);
[~, phase] = imgaborfilt(normImg, gaborFilt);
testCodeMatrix = phase > 0;

%% ---------------- STEP 4/5: TRY EVERY VAULT ----------------
fprintf('Checking against all %d enrolled vaults...\n\n', numel(vaults));

matchedPerson = '';
matchedShift = NaN;

for p = 1:numel(vaults)
    v = vaults(p);

    [~, matched, bestShift] = decodeKeyWithRotationSearch( ...
        testCodeMatrix, v.lockedVault, v.repFactor, v.keyLengthBits, v.usedLength, ...
        shiftRange, v.keyHash);

    if matched
        matchedPerson = v.personName;
        matchedShift = bestShift;
        break; % found a match - stop checking further vaults
    end
end

%% ---------------- RESULT ----------------
fprintf('========================================================\n');
if ~isempty(matchedPerson)
    fprintf('  RESULT: *** ACCESS GRANTED: %s ***\n', matchedPerson);
    fprintf('  (matched with rotation shift = %d)\n', matchedShift);
else
    fprintf('  RESULT: *** ACCESS DENIED - Unauthorized ***\n');
    fprintf('  (no enrolled vault could be unlocked with this iris)\n');
end
fprintf('========================================================\n');


%% ==========================================================
%% SEGMENTATION (adaptive threshold, same as step1_v3)
%% ==========================================================
function result = segmentSingleImageAdaptive(imgPath, minPupilDiameter, maxPupilDiameter, thresholdMultipliers)
    result.ok = false;
    result.pupilCenter = [];
    result.pupilRadius = [];
    result.irisCenter = [];
    result.irisRadius = [];
    result.reason = '';

    irisRadiusMultiplier = 1.55;
    irisRadiusMin = 75;
    irisRadiusMax = 95;

    try
        I = imread(imgPath);
        if ndims(I) == 3, I = rgb2gray(I); end
        I = im2double(I);
        I_smooth = imgaussfilt(I, 2);
        otsuLevel = graythresh(I_smooth);

        for m = 1:numel(thresholdMultipliers)
            threshVal = otsuLevel * thresholdMultipliers(m);
            BW = I_smooth < threshVal;
            BW = bwareaopen(BW, 100);
            BW = imfill(BW, 'holes');
            stats = regionprops(bwconncomp(BW), 'Area', 'Centroid', 'EquivDiameter');

            if isempty(stats), continue; end

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
                    irisRadius = max(irisRadiusMin, min(irisRadiusMax, irisRadius));

                    result.pupilCenter = pupilCenter;
                    result.pupilRadius = pupilRadius;
                    result.irisCenter = irisCenter;
                    result.irisRadius = irisRadius;
                    result.ok = true;
                    return;
                end
            end
        end
        result.reason = 'no valid pupil blob found across all threshold attempts';
    catch ME
        result.reason = ME.message;
    end
end


%% ==========================================================
%% NORMALIZATION (vectorized rubber-sheet unwrap, same as step2)
%% ==========================================================
function normImg = unwrapIrisVectorized(I, pupilCenter, pupilRadius, irisCenter, irisRadius, ...
        numRadialSamples, numAngularSamples)

    [imgH, imgW] = size(I);
    thetaVals = linspace(0, 2*pi, numAngularSamples + 1);
    thetaVals(end) = [];
    rVals = linspace(0, 1, numRadialSamples)';

    cosT = cos(thetaVals);
    sinT = sin(thetaVals);

    xp = pupilCenter(1) + pupilRadius * cosT;
    yp = pupilCenter(2) + pupilRadius * sinT;
    xi = irisCenter(1) + irisRadius * cosT;
    yi = irisCenter(2) + irisRadius * sinT;

    X = (1 - rVals) .* xp + rVals .* xi;
    Y = (1 - rVals) .* yp + rVals .* yi;

    X = min(max(X, 1), imgW);
    Y = min(max(Y, 1), imgH);

    normImg = interp2(I, X, Y, 'linear', 0);
end


%% ==========================================================
%% VAULT UNLOCK WITH ROTATION SEARCH (same as step5_v3)
%% ==========================================================
function [recoveredKey, matched, bestShift] = decodeKeyWithRotationSearch( ...
        testCodeMatrix, lockedVault, repFactor, keyLengthBits, usedLength, shiftRange, storedHash)

    matched = false;
    bestShift = NaN;
    recoveredKey = zeros(1, keyLengthBits);

    for s = shiftRange
        shiftedMatrix = circshift(testCodeMatrix, s, 2);
        shiftedCode = double(shiftedMatrix(:))';
        shiftedCode = shiftedCode(1:usedLength);

        noisyCodeword = xor(shiftedCode, lockedVault);

        candidateKey = zeros(1, keyLengthBits);
        for k = 1:keyLengthBits
            segment = noisyCodeword((k-1)*repFactor + 1 : k*repFactor);
            candidateKey(k) = mean(segment) >= 0.5;
        end

        candidateHash = hashKey(candidateKey);

        if strcmp(candidateHash, storedHash)
            recoveredKey = candidateKey;
            matched = true;
            bestShift = s;
            return;
        end
    end
end
