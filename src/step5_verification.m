%% step5_verify_fuzzy_vault_30people_v3.m
% Improvements over v2:
%   1) GENUINE attempts now combine Test1+Test2 via majority vote before
%      decoding (reduces noise, same trick used for enrollment) - models
%      a realistic system that captures a couple of frames per attempt.
%   2) Wider rotation search range (-15 to +15) for extra alignment margin.
%
% IMPOSTOR testing is left UNCHANGED (still single images, not combined) -
% so it remains an equally strict (or stricter) test of security.
%
% Requires vaults_30.mat (with keyHash field) and iris_codes_30.mat

clear; clc;

load('vaults_30.mat', 'vaults');
load('iris_codes_30.mat', 'irisCodesAuthorized', 'irisCodesUnauthorized');

numPeople = numel(vaults);
repFactor = vaults(1).repFactor;
keyLengthBits = vaults(1).keyLengthBits;
usedLength = vaults(1).usedLength;
codeRows = vaults(1).codeRows;
codeCols = vaults(1).codeCols;

shiftRange = -15:15;

%% ==========================================================
%% PART 1: GENUINE ATTEMPTS (Test1 + Test2 COMBINED per person)
%% ==========================================================
fprintf('=== GENUINE attempts (Test1+Test2 combined, rotation search) ===\n');

genuineResults = [];

for p = 1:numPeople
    personName = vaults(p).personName;
    trueKey = vaults(p).key;
    lockedVault = vaults(p).lockedVault;
    storedHash = vaults(p).keyHash;

    testIdx = find(strcmp({irisCodesAuthorized.personName}, personName) & ...
        contains({irisCodesAuthorized.imageName}, 'Test', 'IgnoreCase', true));

    if isempty(testIdx)
        continue;
    end

    % combine all test images for this person via majority vote
    combinedStack = zeros(numel(testIdx), codeRows, codeCols);
    for t = 1:numel(testIdx)
        combinedStack(t, :, :) = double(irisCodesAuthorized(testIdx(t)).code);
    end
    combinedTestCode = squeeze(mean(combinedStack, 1)) >= 0.5;

    [recoveredKey, matched, bestShift] = decodeKeyWithRotationSearch( ...
        combinedTestCode, lockedVault, repFactor, keyLengthBits, usedLength, ...
        codeRows, codeCols, shiftRange, storedHash);

    exactMatch = matched && isequal(recoveredKey, trueKey);
    bitErrors = sum(recoveredKey ~= trueKey);

    genuineResults(end+1).personName = personName; %#ok<SAGROW>
    genuineResults(end).exactMatch = exactMatch;
    genuineResults(end).bitErrors = bitErrors;
    genuineResults(end).bestShift = bestShift;
end

genuineSuccessRate = mean([genuineResults.exactMatch]) * 100;
fprintf('Genuine Accept Rate (GAR): %.2f%% (%d / %d exact key recoveries)\n', ...
    genuineSuccessRate, sum([genuineResults.exactMatch]), numel(genuineResults));
fprintf('Average key bit errors (genuine, best shift found): %.3f out of %d bits\n', ...
    mean([genuineResults.bitErrors]), keyLengthBits);

%% ==========================================================
%% PART 2a: IMPOSTOR - other authorized people (UNCHANGED - single images)
%% ==========================================================
fprintf('\n=== IMPOSTOR attempts - other authorized people (single images, rotation search) ===\n');

impostorAuthResults = [];

for p = 1:numPeople
    lockedVault = vaults(p).lockedVault;
    storedHash = vaults(p).keyHash;
    ownName = vaults(p).personName;

    otherIdx = find(~strcmp({irisCodesAuthorized.personName}, ownName) & ...
        contains({irisCodesAuthorized.imageName}, 'Test', 'IgnoreCase', true));

    for t = 1:numel(otherIdx)
        testCodeMatrix = irisCodesAuthorized(otherIdx(t)).code;
        [~, matched, ~] = decodeKeyWithRotationSearch( ...
            testCodeMatrix, lockedVault, repFactor, keyLengthBits, usedLength, ...
            codeRows, codeCols, shiftRange, storedHash);

        impostorAuthResults(end+1).falseAccept = matched; %#ok<SAGROW>
    end

    if mod(p, 10) == 0
        fprintf('  Tested vault %d / %d...\n', p, numPeople);
    end
end

farAuth = mean([impostorAuthResults.falseAccept]) * 100;
fprintf('False Accept Rate (other authorized people): %.4f%% (%d / %d falsely accepted)\n', ...
    farAuth, sum([impostorAuthResults.falseAccept]), numel(impostorAuthResults));

%% ==========================================================
%% PART 2b: IMPOSTOR - unauthorized people (UNCHANGED - single images)
%% ==========================================================
fprintf('\n=== IMPOSTOR attempts - unauthorized people (single images, rotation search) ===\n');

impostorUnauthResults = [];

for p = 1:numPeople
    lockedVault = vaults(p).lockedVault;
    storedHash = vaults(p).keyHash;

    for u = 1:numel(irisCodesUnauthorized)
        testCodeMatrix = irisCodesUnauthorized(u).code;
        [~, matched, ~] = decodeKeyWithRotationSearch( ...
            testCodeMatrix, lockedVault, repFactor, keyLengthBits, usedLength, ...
            codeRows, codeCols, shiftRange, storedHash);

        impostorUnauthResults(end+1).falseAccept = matched; %#ok<SAGROW>
    end

    if mod(p, 10) == 0
        fprintf('  Tested vault %d / %d (%d unauthorized attempts each)...\n', ...
            p, numPeople, numel(irisCodesUnauthorized));
    end
end

farUnauth = mean([impostorUnauthResults.falseAccept]) * 100;
fprintf('False Accept Rate (unauthorized people): %.4f%% (%d / %d falsely accepted)\n', ...
    farUnauth, sum([impostorUnauthResults.falseAccept]), numel(impostorUnauthResults));

%% ==========================================================
%% SUMMARY
%% ==========================================================
fprintf('\n========================================================\n');
fprintf('FINAL SUMMARY v3 - Iris-Based Fuzzy Commitment (30 people)\n');
fprintf('Test1+Test2 COMBINED for genuine attempts, shift range %d to %d\n', ...
    min(shiftRange), max(shiftRange));
fprintf('========================================================\n');
fprintf('Genuine Accept Rate (GAR):                    %.2f%%\n', genuineSuccessRate);
fprintf('False Accept Rate - other authorized people:  %.4f%%\n', farAuth);
fprintf('False Accept Rate - unauthorized people:       %.4f%%\n', farUnauth);
fprintf('Total genuine attempts: %d (one combined attempt per person)\n', numel(genuineResults));
fprintf('Total impostor attempts (authorized cross):    %d\n', numel(impostorAuthResults));
fprintf('Total impostor attempts (unauthorized):        %d\n', numel(impostorUnauthResults));
fprintf('========================================================\n');

save('verification_results_30_v3.mat', 'genuineResults', 'impostorAuthResults', 'impostorUnauthResults', ...
    'genuineSuccessRate', 'farAuth', 'farUnauth');
fprintf('\nSaved verification results to verification_results_30_v3.mat\n');


%% ==========================================================
%% HELPER: decode key trying multiple rotation shifts, using SHA-256
%% hash to identify the correct one
%% ==========================================================
function [recoveredKey, matched, bestShift] = decodeKeyWithRotationSearch( ...
        testCodeMatrix, lockedVault, repFactor, keyLengthBits, usedLength, ...
        codeRows, codeCols, shiftRange, storedHash)

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

    shiftedCode = double(testCodeMatrix(:))';
    shiftedCode = shiftedCode(1:usedLength);
    noisyCodeword = xor(shiftedCode, lockedVault);
    for k = 1:keyLengthBits
        segment = noisyCodeword((k-1)*repFactor + 1 : k*repFactor);
        recoveredKey(k) = mean(segment) >= 0.5;
    end
end
