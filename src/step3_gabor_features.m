%% step3_gabor_features_30people.m
% Converts each normalized 64x360 iris rectangle into a binary iris
% code using 2D Gabor filtering - same approach as your original
% 10-person run.
%
% Requires normalized_data_30.mat (from step2_normalize_30people.m)

clear; clc;

load('normalized_data_30.mat', 'normalizedAuthorized', 'normalizedUnauthorized');

%% ---------------- GABOR FILTER SETTINGS ----------------
% Same style of settings used in typical iris-code Gabor extraction -
% adjust wavelength/orientation if your original 10-person script used
% different values (check iris_codes.mat generation script if you have it).
wavelength = 8;
orientation = 0;   % 0 degrees - horizontal filter, standard for iris texture

%% ---------------- EXTRACT FOR AUTHORIZED ----------------
fprintf('=== Extracting Gabor iris codes: AUTHORIZED ===\n');
irisCodesAuthorized = extractCodes(normalizedAuthorized, wavelength, orientation);

%% ---------------- EXTRACT FOR UNAUTHORIZED ----------------
fprintf('\n=== Extracting Gabor iris codes: UNAUTHORIZED ===\n');
irisCodesUnauthorized = extractCodes(normalizedUnauthorized, wavelength, orientation);

%% ---------------- SAVE ----------------
save('iris_codes_30.mat', 'irisCodesAuthorized', 'irisCodesUnauthorized');
fprintf('\nSaved binary iris codes to iris_codes_30.mat\n');

%% ---------------- QUICK SANITY CHECK: SAME vs DIFFERENT PERSON DISTANCES ----------------
fprintf('\n=== Sanity check: Hamming distance analysis ===\n');
checkHammingDistances(irisCodesAuthorized);


%% ==========================================================
%% HELPER: extract codes for a whole set
%% ==========================================================
function codes = extractCodes(normSet, wavelength, orientation)
    codes = struct('personName', {}, 'imageName', {}, 'code', {});

    gaborFilt = gabor(wavelength, orientation);

    for i = 1:numel(normSet)
        entry = normSet(i);

        [mag, phase] = imgaborfilt(entry.normImage, gaborFilt);

        % binary code: 1 where phase is positive, 0 otherwise
        % (standard approach - encodes phase information, robust to
        % overall brightness differences between images)
        binaryCode = phase > 0;

        outEntry.personName = entry.personName;
        outEntry.imageName = entry.imageName;
        outEntry.code = binaryCode;

        codes(end+1) = outEntry; %#ok<AGROW>

        if mod(i, 20) == 0 || i == numel(normSet)
            fprintf('  Extracted %d / %d codes...\n', i, numel(normSet));
        end
    end
end


%% ==========================================================
%% HELPER: sanity check - same-person vs different-person Hamming distances
%% ==========================================================
function checkHammingDistances(codes)
    personNames = unique({codes.personName});

    sameDistances = [];
    diffDistances = [];

    for p = 1:numel(personNames)
        thisPersonIdx = find(strcmp({codes.personName}, personNames{p}));

        % same-person pairs
        for i = 1:numel(thisPersonIdx)
            for j = i+1:numel(thisPersonIdx)
                d = hammingDist(codes(thisPersonIdx(i)).code, codes(thisPersonIdx(j)).code);
                sameDistances(end+1) = d; %#ok<AGROW>
            end
        end

        % different-person pairs (compare against next person only, to keep this fast)
        if p < numel(personNames)
            otherIdx = find(strcmp({codes.personName}, personNames{p+1}));
            if ~isempty(thisPersonIdx) && ~isempty(otherIdx)
                d = hammingDist(codes(thisPersonIdx(1)).code, codes(otherIdx(1)).code);
                diffDistances(end+1) = d; %#ok<AGROW>
            end
        end
    end

    fprintf('Same-person Hamming distance:      mean = %.4f (n=%d pairs)\n', ...
        mean(sameDistances), numel(sameDistances));
    fprintf('Different-person Hamming distance:  mean = %.4f (n=%d pairs)\n', ...
        mean(diffDistances), numel(diffDistances));
    fprintf('(Lower same-person distance and higher different-person distance = good separation)\n');
end

function d = hammingDist(codeA, codeB)
    d = sum(codeA(:) ~= codeB(:)) / numel(codeA);
end
