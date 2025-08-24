import ballerina/log;

# Result returned by Cloudinary on a successful upload.
# Additional fields are carried in the open rest field to account for API evolution.
public type UploadResult record {|
    # Cloudinary asset identifier (UUID).
    string asset_id?;
    # Public identifier for the resource.
    string public_id?;
    # File format (e.g., png, jpg).
    string format?;
    # Resource type (e.g., image, video).
    string resource_type?;
    # Creation timestamp.
    string created_at?;
    # HTTPS URL to the resource.
    string secure_url?;
    # HTTP URL to the resource.
    string url?;
    json...;
|};

public type UploadOptions record {|
    # Target folder on Cloudinary. When omitted, uploads to root.
    string? folder = ();
    # Optional file name (public_id). If omitted, Cloudinary assigns one.
    string? filename = ();
|};

# # Result returned by Cloudinary destroy (delete) operation.
public type DestroyResult record {|
    # Result indicator (e.g., "ok", "not found").
    string result?;
    json...;
|};

# # Options for delete (destroy) operation.
public type DeleteOptions record {|
    # When true, also invalidates the cached CDN copy.
    boolean invalidate = false;
|};

# # Logs the operation with minimal context.
# + cloudName - Cloudinary cloud name
# + mode - "signed" or "unsigned"
# + folder - target folder
# + file - optional file name (public_id)
isolated function logUploadAttempt(string cloudName, string mode, string folder, string? file) {
    log:printInfo("cloudinary upload attempt", properties = {cloud: cloudName, mode, folder, file: file ?: "(auto)"});
}
