import ballerina/auth;
import ballerina/http;
import ballerina/config;

auth:OutboundBasicAuthProvider couchDbAuthProvider = new ({
    username: config:getAsString("db.dbUser"),
    password: config:getAsString("db.dbPass")
});
http:BasicAuthHandler couchDbAuthHandler = new (couchDbAuthProvider);
http:Client couchDbEndpoint = new (config:getAsString("db.dbHost"), {
        auth: {
            authHandler: couchDbAuthHandler
        }
    });

string baseName = config:getAsString("db.dbName");

function checkExistBase(string baseName) returns @tainted boolean {
    var checkExist = couchDbEndpoint->get("/" + baseName);
    if (checkExist is http:Response) {
        if (checkExist.statusCode == 200) {
            var msg = checkExist.getJsonPayload();
            if (msg is json) {
                return msg.db_name == baseName;
            }
        }
    }
    return false;
}

function createBase(string baseName) returns @tainted boolean {
    var createDb = couchDbEndpoint->put("/" + baseName, null);
    if (createDb is http:Response) {
        return createDb.statusCode == 201;
    }
    return false;
}

function createBaseInNotExist(string baseName) returns @tainted boolean {
    if (checkExistBase(baseName) != true) {
        return createBase(baseName);
    }
    return false;
}
