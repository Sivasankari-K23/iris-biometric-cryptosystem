%% step4_fuzzy_commitment_30people.m
% Locks a random secret key for each of the 30 authorized people using
% their ENROLLMENT iris codes, via a repetition-code + XOR fuzzy
% commitment scheme (same approach as your original 10-person run).
%
% Requires iris_codes_30.mat (from step3_gabor_features_30people.m)

clear; clc;
rng('shuffle');

load('iris_codes_30.mat', 'irisCodesAuthorized');

%% ---------------- SETTINGS ----------------
keyLengthBits = 32;

%% ---------------- GROUP ENROLLMENT CODES BY PERSON ----------------
personNames = unique({irisCodesAuthorized.personName}, 'stable');
% sort numerically (Person1, Person2, ... Person30) instead of lexically
personNums = cellfun(@(s) sscanf(s, 'Person%d'), personNames);
[~, order] = sort(personNums);
personNames = personNames(order);

fprintf('Found %d authorized people.\n', numel(personNames));

vaults = struct('personName', {}, 'key', {}, 'lockedVault', {}, ...
    'repFactor', {}, 'keyLengthBits', {}, 'usedLength', {}, ...
    'keyHash', {}, 'codeRows', {}, 'codeCols', {});

for p = 1:numel(personNames)
    name = personNames{p};

    idxAll = find(strcmp({irisCodesAuthorized.personName}, name));
    enrollIdx = idxAll(contains({irisCodesAuthorized(idxAll).imageName}, 'Enroll', 'IgnoreCase', true));

    if isempty(enrollIdx)
        warning('%s: no enrollment images found, skipping.', name);
        continue;
    end

    % combine enrollment codes via majority vote (bit-by-bit average,
    % rounded) - more robust than using just one enrollment image
    enrollCodes = zeros(numel(enrollIdx), numel(irisCodesAuthorized(enrollIdx(1)).code));
    for e = 1:numel(enrollIdx)
        enrollCodes(e, :) = double(irisCodesAuthorized(enrollIdx(e)).code(:))';
    end
    enrollmentCode = mean(enrollCodes, 1) >= 0.5; % majority vote across enrollment images

    codeLength = numel(enrollmentCode);
    repFactor = floor(codeLength / keyLengthBits);
    usedLength = repFactor * keyLengthBits;

    % generate a random secret key for this person
    key = randi([0 1], 1, keyLengthBits);

    % repetition-encode: each key bit repeated repFactor times
    codeword = repelem(key, repFactor);

    % lock: XOR codeword with this person's enrollment iris code
    lockedVault = xor(codeword, enrollmentCode(1:usedLength));

    % cryptographic hash of the key - lets verification confirm "is this
    % the right key?" WITHOUT storing the key itself in a directly usable
    % form. Collision probability ~1/2^256, so no realistic chance of an
    % accidental match (unlike a simple weighted-sum checksum).
    keyHash = hashKey(key);

    vaults(end+1) = struct( ...
        'personName', name, ...
        'key', key, ...
        'lockedVault', lockedVault, ...
        'repFactor', repFactor, ...
        'keyLengthBits', keyLengthBits, ...
        'usedLength', usedLength, ...
        'keyHash', keyHash, ...
        'codeRows', size(irisCodesAuthorized(enrollIdx(1)).code, 1), ...
        'codeCols', size(irisCodesAuthorized(enrollIdx(1)).code, 2)); %#ok<SAGROW>

    if mod(p, 5) == 0
        fprintf('  Locked %d / %d vaults...\n', p, numel(personNames));
    end
end

fprintf('\nAll vaults created: %d people, %d-bit keys, repetition factor %d (code length used: %d bits)\n', ...
    numel(vaults), keyLengthBits, vaults(1).repFactor, vaults(1).usedLength);

%% ---------------- SAVE ----------------
save('vaults_30.mat', 'vaults');
fprintf('Saved fuzzy commitment vaults to vaults_30.mat\n');
fprintf('\nNote: "key" is stored here for evaluation purposes only.\n');
fprintf('In a real deployment, only "lockedVault" would be stored/shared -\n');
fprintf('the key itself should never be stored anywhere.\n');
fprintf('\nNext step: verification - test if genuine test images correctly\n');
fprintf('recover the key, and unauthorized/impostor attempts correctly fail.\n');
