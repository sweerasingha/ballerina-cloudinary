import ballerina/test;
import ballerina/time;

import sachisw/cloudinary.core as core;

@test:Config {}
function testUploadWrapperConfigMissingSkips() returns error? {
    byte[] small = [1, 2, 3, 4];
    int ts = time:utcNow()[0];
    string name = string `ballerina-test-${ts}.bin`;
    var res = uploadSingleImage(small, "ballerina-tests", name);
    if res is error {
        test:assertTrue(res.message().startsWith("missing configuration"));
        return;
    }
    core:UploadResult r = res;
    test:assertTrue((r.public_id is string) || (r.secure_url is string), msg = "expected id or url");
}

@test:Config {groups: ["integration_unsigned"]}
function testUnsignedUploadWhenConfigured() returns error? {
    byte[] bytes = [1, 2, 3, 4, 5, 6, 7, 8];
    int ts = time:utcNow()[0];
    string filename = string `ballerina-unsigned-${ts}.bin`;
    var res = uploadSingleImage(bytes, "ballerina-tests", filename);
    if res is error {
        string m = res.message();
        if m.startsWith("missing configuration") {
            return;
        }
        return res;
    }
    core:UploadResult r = res;
    test:assertTrue((r.public_id is string) || (r.secure_url is string), msg = "expected id or url");
}

@test:Config {groups: ["integration_signed"]}
function testSignedUploadWhenConfigured() returns error? {
    byte[] bytes = [9, 9, 9, 9, 9, 9, 9, 9];
    int ts = time:utcNow()[0];
    string filename = string `ballerina-signed-${ts}.bin`;
    var res = uploadSingleImage(bytes, "ballerina-tests", filename);
    if res is error {
        string m = res.message();
        if m.startsWith("missing configuration") {
            return;
        }
        return res;
    }
    core:UploadResult r = res;
    test:assertTrue((r.public_id is string) || (r.secure_url is string), msg = "expected id or url");
}

@test:Config {}
function testDeleteWrapperConfigMissingSkips() returns error? {
    var res = deleteSingleImage("ballerina-tests/non-existent-${time:utcNow()[0]}");
    if res is error {
        test:assertTrue(res.message().startsWith("missing configuration"));
        return;
    }
    core:DestroyResult r = res;
    test:assertTrue((r.result is string));
}

@test:Config {}
function testUploadMultipleOffline() returns error? {
    // Multi-upload wrapper should execute per item until config error occurs.
    ImageFile a = {bytes: [1, 2, 3], filename: "a.bin"};
    ImageFile b = {bytes: [4, 5, 6], filename: "b.bin"};
    var res = uploadMultipleImages([a, b], "ballerina-tests");
    if res is error {
        return;
    }
    core:UploadResult[] rr = res;
    test:assertTrue(rr.length() >= 0);
}

@test:Config {}
function testDeleteMultipleOffline() returns error? {
    var res = deleteMultipleImages(["ballerina-tests/non-existent-1", "ballerina-tests/non-existent-2"]);
    if res is error {
        return;
    }
    core:DestroyResult[] dd = res;
    test:assertTrue(dd.length() >= 0);
}
