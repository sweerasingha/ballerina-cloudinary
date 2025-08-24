import ballerina/crypto;
import ballerina/http;
import ballerina/log;
import ballerina/mime;
import ballerina/time;

public type CloudinaryConfig record {
    # Cloudinary cloud name (account identifier).
    string cloudName;
    # Unsigned upload preset name. Required for unsigned uploads.
    string? uploadPreset = ();
    # API key for signed uploads.
    string? apiKey = ();
    # API secret for signed uploads.
    string? apiSecret = ();
};

# # Minimal client for Cloudinary Image Upload API.
public client class CloudinaryClient {
    private final http:Client httpClient;
    private final CloudinaryConfig cfg;

    public function init(CloudinaryConfig cfg) returns error? {
        if cfg.cloudName.trim().length() == 0 {
            return error("cloudName is required");
        }
        self.cfg = cfg;
        string base = string `https://api.cloudinary.com/v1_1/${cfg.cloudName}/image`;
        self.httpClient = check new (base);
    }

    # Uploads the given bytes as a file.
    # + bytes - file bytes
    # + opts - upload options such as folder and optional filename
    # + return - UploadResult on success
    remote function upload(byte[] bytes, UploadOptions opts) returns UploadResult|error {
        string mode = (self.cfg.apiKey is string && self.cfg.apiSecret is string) ? "signed" : "unsigned";
        log:printDebug("preparing multipart for upload", properties = {mode, folder: opts.folder, file: opts.filename ?: "(auto)"});
        mime:Entity imagePart = new;
        _ = imagePart.addHeader("Content-Disposition", string `form-data; name="file"; filename="${opts.filename ?: "file"}"`);
        mime:Error? be = imagePart.setByteArray(bytes, contentType = "application/octet-stream");
        if be is mime:Error {
            return error("failed to set byte array");
        }

        mime:Entity? folderPart = ();
        if opts.folder is string {
            mime:Entity f = new;
            _ = f.addHeader("Content-Disposition", "form-data; name=\"folder\"");
            mime:Error? fe = f.setText(<string>opts.folder);
            if fe is mime:Error {
                return error("failed to set folder");
            }
            folderPart = f;
        }

        http:Request req = new;

        if self.cfg.apiKey is string && self.cfg.apiSecret is string {
            int ts = time:utcNow()[0];
            string tsStr = ts.toString();
            // Build signable params: folder, timestamp, and optional public_id
            map<string> signParams = {timestamp: tsStr};
            if opts.folder is string {
                signParams["folder"] = <string>opts.folder;
            }
            if opts.filename is string {
                signParams["public_id"] = <string>opts.filename;
            }
            string signature = computeSignature(signParams, <string>self.cfg.apiSecret);

            mime:Entity apiKeyPart = new;
            _ = apiKeyPart.addHeader("Content-Disposition", "form-data; name=\"api_key\"");
            mime:Error? kErr = apiKeyPart.setText(<string>self.cfg.apiKey);
            if kErr is mime:Error {
                return error("failed to set api_key");
            }

            mime:Entity tsPart = new;
            _ = tsPart.addHeader("Content-Disposition", "form-data; name=\"timestamp\"");
            mime:Error? tErr = tsPart.setText(tsStr);
            if tErr is mime:Error {
                return error("failed to set timestamp");
            }

            mime:Entity sigPart = new;
            _ = sigPart.addHeader("Content-Disposition", "form-data; name=\"signature\"");
            mime:Error? sErr = sigPart.setText(signature);
            if sErr is mime:Error {
                return error("failed to set signature");
            }

            if opts.filename is string {
                mime:Entity pidPart = new;
                _ = pidPart.addHeader("Content-Disposition", "form-data; name=\"public_id\"");
                mime:Error? pErr = pidPart.setText(<string>opts.filename);
                if pErr is mime:Error {
                    return error("failed to set public_id");
                }
                if folderPart is mime:Entity {
                    req.setBodyParts([imagePart, <mime:Entity>folderPart, apiKeyPart, tsPart, sigPart, pidPart]);
                } else {
                    req.setBodyParts([imagePart, apiKeyPart, tsPart, sigPart, pidPart]);
                }
            } else {
                if folderPart is mime:Entity {
                    req.setBodyParts([imagePart, <mime:Entity>folderPart, apiKeyPart, tsPart, sigPart]);
                } else {
                    req.setBodyParts([imagePart, apiKeyPart, tsPart, sigPart]);
                }
            }
        } else if self.cfg.uploadPreset is string {
            mime:Entity presetPart = new;
            _ = presetPart.addHeader("Content-Disposition", "form-data; name=\"upload_preset\"");
            mime:Error? prErr = presetPart.setText(<string>self.cfg.uploadPreset);
            if prErr is mime:Error {
                return error("failed to set upload_preset");
            }
            if opts.filename is string {
                mime:Entity pidPart = new;
                _ = pidPart.addHeader("Content-Disposition", "form-data; name=\"public_id\"");
                mime:Error? pErr2 = pidPart.setText(<string>opts.filename);
                if pErr2 is mime:Error {
                    return error("failed to set public_id");
                }
                if folderPart is mime:Entity {
                    req.setBodyParts([imagePart, presetPart, <mime:Entity>folderPart, pidPart]);
                } else {
                    req.setBodyParts([imagePart, presetPart, pidPart]);
                }
            } else {
                if folderPart is mime:Entity {
                    req.setBodyParts([imagePart, presetPart, <mime:Entity>folderPart]);
                } else {
                    req.setBodyParts([imagePart, presetPart]);
                }
            }
        } else {
            return error("missing configuration: provide apiKey/apiSecret for signed or uploadPreset for unsigned uploads");
        }

        log:printInfo("uploading to cloudinary", properties = {cloud: self.cfg.cloudName, mode, folder: opts.folder is string ? <string>opts.folder : "(root)", file: opts.filename ?: "(auto)"});
        http:Response resp = check self.httpClient->post("/upload", req);

        if resp.statusCode < 200 || resp.statusCode >= 300 {
            json|error ej = resp.getJsonPayload();
            string msg = "upload failed";
            if ej is json && ej is map<json> {
                json e = ej["error"];
                if e is map<json> {
                    json m = e["message"];
                    if m is string {
                        msg = m;
                    }
                }
            }
            log:printError("cloudinary error", properties = {status: resp.statusCode, msg});
            return error(string `cloudinary: ${msg} (${resp.statusCode})`);
        }

        json j = check resp.getJsonPayload();
        UploadResult r = check j.cloneWithType(UploadResult);
        return r;
    }

    # Deletes a resource by public_id. Signed request is required.
    # + publicId - full public_id (optionally including folder)
    # + opts - delete options
    # + return - DestroyResult on success
    remote function destroy(string publicId, DeleteOptions opts) returns DestroyResult|error {
        if !(self.cfg.apiKey is string && self.cfg.apiSecret is string) {
            return error("missing configuration: destroy requires apiKey and apiSecret");
        }

        int ts = time:utcNow()[0];
        string tsStr = ts.toString();
        // sign params: public_id, timestamp (and invalidate if true)
        map<string> signParams = {public_id: publicId, timestamp: tsStr};
        if opts.invalidate {
            signParams["invalidate"] = "true";
        }
        string signature = computeSignature(signParams, <string>self.cfg.apiSecret);

        http:Request req = new;
        mime:Entity pidPart = new;
        _ = pidPart.addHeader("Content-Disposition", "form-data; name=\"public_id\"");
        _ = pidPart.setText(publicId);

        mime:Entity apiKeyPart = new;
        _ = apiKeyPart.addHeader("Content-Disposition", "form-data; name=\"api_key\"");
        _ = apiKeyPart.setText(<string>self.cfg.apiKey);

        mime:Entity tsPart = new;
        _ = tsPart.addHeader("Content-Disposition", "form-data; name=\"timestamp\"");
        _ = tsPart.setText(tsStr);

        mime:Entity sigPart = new;
        _ = sigPart.addHeader("Content-Disposition", "form-data; name=\"signature\"");
        _ = sigPart.setText(signature);

        if opts.invalidate {
            mime:Entity invPart = new;
            _ = invPart.addHeader("Content-Disposition", "form-data; name=\"invalidate\"");
            _ = invPart.setText("true");
            req.setBodyParts([pidPart, apiKeyPart, tsPart, sigPart, invPart]);
        } else {
            req.setBodyParts([pidPart, apiKeyPart, tsPart, sigPart]);
        }

        log:printInfo("destroying from cloudinary", properties = {cloud: self.cfg.cloudName, public_id: publicId, invalidate: opts.invalidate});
        // Destroy endpoint is under the same resource type base: /destroy
        http:Response resp = check self.httpClient->post("/destroy", req);

        if resp.statusCode < 200 || resp.statusCode >= 300 {
            json|error ej = resp.getJsonPayload();
            string msg = "destroy failed";
            if ej is json && ej is map<json> {
                json e = ej["error"];
                if e is map<json> {
                    json m = e["message"];
                    if m is string {
                        msg = m;
                    }
                }
            }
            log:printError("cloudinary error", properties = {status: resp.statusCode, msg});
            return error(string `cloudinary: ${msg} (${resp.statusCode})`);
        }

        json j = check resp.getJsonPayload();
        DestroyResult r = check j.cloneWithType(DestroyResult);
        return r;
    }
}

isolated function toHex(byte[] bytes) returns string {
    string[] hexDigits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"];
    string out = "";
    foreach byte b in bytes {
        int hi = (b & 0xF0) >> 4;
        int lo = b & 0x0F;
        out = out + hexDigits[hi] + hexDigits[lo];
    }
    return out;
}

isolated function computeSignature(map<string> params, string apiSecret) returns string {
    // Sort keys lexicographically and join as k=v pairs with '&', then append secret and sha1.
    string[] keys = [];
    foreach var k in params.keys() {
        keys.push(k);
    }
    sortStrings(keys);
    string joined = "";
    int i = 0;
    foreach string k in keys {
        string v = <string>params[k];
        string part = string `${k}=${v}`;
        joined = i == 0 ? part : string `${joined}&${part}`;
        i += 1;
    }
    string data = string `${joined}${apiSecret}`;
    byte[] sha = crypto:hashSha1(data.toBytes());
    return toHex(sha);
}

isolated function sortStrings(string[] arr) {
    int n = arr.length();
    int i = 0;
    while i < n {
        int j = i + 1;
        while j < n {
            if arr[j] < arr[i] {
                string tmp = arr[i];
                arr[i] = arr[j];
                arr[j] = tmp;
            }
            j += 1;
        }
        i += 1;
    }
}
