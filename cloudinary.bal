import ballerina/log;

import sachisw/cloudinary.core as core;

# Cloud name of your Cloudinary account.
configurable string cloud_name = "demo";
# Unsigned upload preset name (required if not using signed uploads).
configurable string? upload_preset = ();
# API key for signed uploads.
configurable string? api_key = ();
# API secret for signed uploads.
configurable string? api_secret = ();

public type ImageFile record {|
    byte[] bytes;
    string? filename = ();
|};

# # Upload a single image.
# + bytes - image bytes
# + folder - optional target folder in Cloudinary root; when omitted, uploads to root
# + filename - optional public_id; when omitted, Cloudinary assigns one (or caller can pass the original filename)
# + return - UploadResult on success
public function uploadSingleImage(byte[] bytes, string? folder = (), string? filename = ()) returns core:UploadResult|error {
    core:CloudinaryClient c = check newClient();
    core:UploadOptions opts = {folder, filename};
    log:printInfo("upload single image", properties = {"cloud": cloud_name, "folder": folder is string ? folder : "(root)", "file": filename is string ? filename : "(auto)"});
    return check c->upload(bytes, opts);
}

# # Upload multiple images.
# + files - list of image items (bytes and optional filename per item)
# + folder - optional target folder applied to all uploads
# + return - array of UploadResult on success (one per input)
public function uploadMultipleImages(ImageFile[] files, string? folder = ()) returns core:UploadResult[]|error {
    core:CloudinaryClient c = check newClient();
    core:UploadResult[] out = [];
    foreach ImageFile f in files {
        core:UploadOptions opts = {folder, filename: f.filename};
        log:printInfo("upload image", properties = {"cloud": cloud_name, "folder": folder is string ? folder : "(root)", "file": f.filename is string ? f.filename : "(auto)"});
        core:UploadResult r = check c->upload(f.bytes, opts);
        out.push(r);
    }
    return out;
}

# # Delete a single image by public_id. Signed configuration is required.
# + publicId - Cloudinary public_id to delete
# + invalidate - when true, also invalidates cached CDN content
# + return - DestroyResult on success
public function deleteSingleImage(string publicId, boolean invalidate = false) returns core:DestroyResult|error {
    core:CloudinaryClient c = check newClient();
    if !(api_key is string && api_secret is string) {
        return error("missing configuration: delete requires api_key and api_secret");
    }
    core:DeleteOptions opts = {invalidate};
    log:printInfo("delete single image", properties = {"cloud": cloud_name, "public_id": publicId, "invalidate": invalidate});
    return check c->destroy(publicId, opts);
}

# # Delete multiple images by public_id. Signed configuration is required.
# + publicIds - list of Cloudinary public_ids to delete
# + invalidate - when true, also invalidates cached CDN content
# + return - array of DestroyResult on success (one per input)
public function deleteMultipleImages(string[] publicIds, boolean invalidate = false) returns core:DestroyResult[]|error {
    core:CloudinaryClient c = check newClient();
    if !(api_key is string && api_secret is string) {
        return error("missing configuration: delete requires api_key and api_secret");
    }
    core:DeleteOptions opts = {invalidate};
    core:DestroyResult[] out = [];
    foreach string id in publicIds {
        log:printInfo("delete image", properties = {"cloud": cloud_name, "public_id": id, "invalidate": invalidate});
        core:DestroyResult r = check c->destroy(id, opts);
        out.push(r);
    }
    return out;
}

function newClient() returns core:CloudinaryClient|error {
    core:CloudinaryConfig cfg = {
        cloudName: cloud_name,
        uploadPreset: upload_preset,
        apiKey: api_key,
        apiSecret: api_secret
    };
    return new (cfg);
}
