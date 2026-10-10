function h = hashKey(key)
% hashKey - computes a SHA-256 hash of a binary key vector.
% Used to verify "is this the correct key?" without ever storing or
% exposing the key itself - collision probability is ~1/2^256,
% effectively eliminating accidental false matches.
%
% key: a 1xN vector of 0s and 1s (logical or double)
% h: a 64-character hex string

    bytes = uint8(double(key(:))'); % row vector of 0/1 values as bytes

    md = java.security.MessageDigest.getInstance('SHA-256');
    md.update(bytes);
    hashBytes = typecast(md.digest(), 'uint8');

    h = sprintf('%02x', hashBytes);
end
