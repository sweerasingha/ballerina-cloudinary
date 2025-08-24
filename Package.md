# Package Overview
Typed Cloudinary client for Ballerina, enabling unsigned/signed image uploads and signed deletions (destroy).

# Cloudinary client for Ballerina

Typed client for Cloudinary Images with:

- Unsigned uploads using an `upload_preset`.
- Signed uploads using `api_key` and `api_secret` with a SHA1 timestamp signature.
- Signed delete (destroy) by `public_id`.

## Install

```bash
bal add sachisw/cloudinary
```

## Configure

Provide configurables in Config.toml under the [sachisw.cloudinary] table.

- `cloud_name` (required)
- `upload_preset` (unsigned uploads), or `api_key` and `api_secret` (signed uploads and delete)

Config.toml examples

Unsigned uploads

```toml
# For unsigned uploads in local testing, set a known preset
# or provide via -Cupload_preset
# upload_preset = "my_unsigned_preset"

[sachisw.cloudinary]
cloud_name = "demo"
upload_preset = "my_unsigned_preset"   # uncomment and set if using unsigned uploads

[ballerina.log]
level = "INFO"
```

Signed uploads and delete

```toml
[sachisw.cloudinary]
api_key = "demo_api_key"
api_secret = "demo_api_secret"
cloud_name = "demo"

[ballerina.log]
level = "INFO"
```

## Public API

Root helpers (return types come from `sachisw/cloudinary.core`):

- `uploadSingleImage(bytes, folder?, filename?) -> UploadResult | error`
- `uploadMultipleImages(ImageFile[], folder?) -> UploadResult[] | error`
- `deleteSingleImage(publicId, invalidate?) -> DestroyResult | error`
- `deleteMultipleImages(publicIds, invalidate?) -> DestroyResult[] | error`

Where `ImageFile` is `record { byte[] bytes; string? filename; }`.

## Usage examples

### 1) Upload a single image

```ballerina
import ballerina/io;
import sachisw/cloudinary;

public function main() returns error? {
    // Reads a local file and uploads it to an optional folder with an optional public_id.
    byte[] img = check io:fileReadBytes("./cat.jpg");
    var res = check cloudinary:uploadSingleImage(img, "samples", "cats/cat1");
    io:println(res.secure_url ?: res.url ?: "uploaded");
}
```

### 2) Upload multiple images

```ballerina
import ballerina/io;
import sachisw/cloudinary;

public function main() returns error? {
    cloudinary:ImageFile[] files = [
        { bytes: check io:fileReadBytes("./a.jpg") },
        { bytes: check io:fileReadBytes("./b.jpg") }
    ];
    var results = check cloudinary:uploadMultipleImages(files, "samples");
    foreach var r in results {
        io:println(r.secure_url ?: r.url ?: "uploaded");
    }
}
```

### 3) Delete a single image

```ballerina
import sachisw/cloudinary;

public function main() returns error? {
    // Requires signed configuration (api_key and api_secret).
    var out = check cloudinary:deleteSingleImage("samples/cats/cat1", true);
}
```

### 4) Delete multiple images

```ballerina
import sachisw/cloudinary;

public function main() returns error? {
    string[] ids = ["samples/a", "samples/b"];
    var out = check cloudinary:deleteMultipleImages(ids, true);
}
```

## Notes

- For unsigned uploads, configure `upload_preset` on your Cloudinary account.
- For signed uploads and delete, both `api_key` and `api_secret` must be set.
- Errors surface as `error` with Cloudinary messages when available.