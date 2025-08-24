import ballerina/test;

@test:Config {}
function testTypesShape() {
    CloudinaryConfig cfg = {cloudName: "demo"};
    test:assertEquals(cfg.cloudName, "demo");

    DeleteOptions d = {invalidate: true};
    test:assertTrue(d.invalidate);
}

@test:Config {}
function testUploadResultIsOpenRecord() {
    UploadResult r = {public_id: "x", secure_url: "https://example.com/x", ["foo"]: "bar"};
    test:assertEquals(r.public_id, "x");
    test:assertEquals(r["foo"], "bar");
}

@test:Config {}
function testClientInitRequiresCloudName() {
    CloudinaryConfig bad = {cloudName: ""};
    CloudinaryClient|error c = new (bad);
    test:assertTrue(c is error, msg = "expected error for empty cloud name");
}

@test:Config {}
function testUploadAndDestroyRequireProperConfig() returns error? {
    CloudinaryConfig cfg = {cloudName: "demo"};
    CloudinaryClient c = check new (cfg);

    // upload without unsigned preset or signed keys should error before network
    UploadOptions uo = {folder: (), filename: ()};
    var up = c->upload([1, 2], uo);
    test:assertTrue(up is error);

    // destroy without signed keys should error before network
    DeleteOptions delOpts = {invalidate: false};
    var del = c->destroy("samples/demo", delOpts);
    test:assertTrue(del is error);
}
