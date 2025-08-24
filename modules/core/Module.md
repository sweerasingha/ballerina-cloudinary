# core module

Types and client for Cloudinary Image Upload API, plus signed destroy (delete).

- CloudinaryClient: client to perform signed or unsigned uploads and signed destroy.
- UploadResult: typed response model for common fields; open to allow vendor extensions.
- DestroyResult: typed response for delete results.
- Helper utils for hashing and time.
