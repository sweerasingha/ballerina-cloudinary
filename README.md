# Cloudinary Client for Ballerina

[![Ballerina Central](https://img.shields.io/badge/Ballerina-Central-blue?logo=ballerina)](https://central.ballerina.io/sachisw/cloudinary)
[![License](https://img.shields.io/badge/license-Apache--2.0-green)](./LICENSE)

Typed Ballerina client for **Cloudinary Images** with support for:

- ✅ Unsigned uploads using an `upload_preset`
- ✅ Signed uploads using `api_key` + `api_secret` with a SHA1 timestamp signature
- ✅ Signed delete (destroy) by `public_id`

---

## 🚀 Installation

```bash
bal add sachisw/cloudinary
````

---

## ⚙️ Configuration

Provide configurables via **`Config.toml`** under `[sachisw.cloudinary]`.
For local testing, you can either set values directly or override with CLI `-C` flags.
Avoid committing real secrets—prefer environment interpolation like `${CLOUDINARY_API_KEY}`.

### Unsigned uploads (`Config.toml`)

```toml
# For unsigned uploads in local testing, set a known preset 
# or provide via -Cupload_preset
# upload_preset = "my_unsigned_preset"

[sachisw.cloudinary]
cloud_name = "demo"
upload_preset = "my_unsigned_preset"

[ballerina.log]
level = "INFO"
```

### Signed uploads & delete (`Config.toml`)

```toml
[sachisw.cloudinary]
api_key = "demo_api_key"
api_secret = "demo_api_secret"
cloud_name = "demo"

[ballerina.log]
level = "INFO"
```

### CLI override examples

```bash
# Unsigned
bal run -Ccloud_name=your_cloud -Cupload_preset=your_unsigned_preset

# Signed
bal run -Ccloud_name=your_cloud -Capi_key=$CLOUDINARY_API_KEY -Capi_secret=$CLOUDINARY_API_SECRET
```

---

## 📦 Public API

Root helpers (return types come from `sachisw/cloudinary.core`):

* `uploadSingleImage(bytes, folder?, filename?) -> UploadResult | error`
* `uploadMultipleImages(ImageFile[], folder?) -> UploadResult[] | error`
* `deleteSingleImage(publicId, invalidate?) -> DestroyResult | error`
* `deleteMultipleImages(publicIds, invalidate?) -> DestroyResult[] | error`

Where `ImageFile` is:

```ballerina
type ImageFile record { 
    byte[] bytes; 
    string? filename; 
};
```

---

## 💡 Usage Examples

### 1. Upload a single image

```ballerina
import ballerina/io;
import sachisw/cloudinary;

public function main() returns error? {
    byte[] img = check io:fileReadBytes("./cat.jpg");
    var res = check cloudinary:uploadSingleImage(img, "samples", "cats/cat1");
    io:println(res.secure_url ?: res.url ?: "uploaded");
}
```

### 2. Upload multiple images

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

### 3. Delete a single image

```ballerina
import sachisw/cloudinary;

public function main() returns error? {
    // Requires signed configuration (api_key and api_secret).
    var out = check cloudinary:deleteSingleImage("samples/cats/cat1", true);
}
```

### 4. Delete multiple images

```ballerina
import sachisw/cloudinary;

public function main() returns error? {
    string[] ids = ["samples/a", "samples/b"];
    var out = check cloudinary:deleteMultipleImages(ids, true);
}
```

---

## 📝 Notes

* For **unsigned uploads**, configure an `upload_preset` in your Cloudinary account and set it in `Config.toml` or via `-Cupload_preset`.
* For **signed uploads/delete**, both `api_key` and `api_secret` must be provided.
* Logging can be controlled with the `[ballerina.log]` section in `Config.toml`.
* Errors bubble up as `error` with Cloudinary messages when available.

---

