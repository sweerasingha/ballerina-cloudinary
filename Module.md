# Cloudinary client for Ballerina

Typed client for Cloudinary Images with:

- Unsigned uploads using an `upload_preset`.
- Signed uploads using `api_key` and `api_secret` with a SHA1 timestamp signature.
- Signed delete (destroy) by `public_id`.

Backed by a small typed core module (`sachisw/cloudinary.core`).

## Install

```powershell
bal add sachisw/cloudinary
```

## Configure

Provide the following configurables at runtime via `Config.toml`, `Config.secrets.toml`, or CLI `-C` flags:

- `cloud_name` (required)
- `upload_preset` (unsigned uploads), or `api_key` and `api_secret` (signed uploads and delete)

Config.toml examples

Unsigned uploads

```toml
cloud_name = "your_cloud"
upload_preset = "unsigned_preset_name"
```

Signed uploads and delete

```toml
cloud_name = "your_cloud"
api_key = "${CLOUDINARY_API_KEY}"      # put actual value or use secrets indirection
api_secret = "${CLOUDINARY_API_SECRET}"
```

CLI override (example)

```powershell
bal run -Ccloud_name=your_cloud -Cupload_preset=unsigned_preset_name
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

## License

Apache-2.0