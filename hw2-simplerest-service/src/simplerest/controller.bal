import ballerina/http;
import ballerina/math;

function genIntId() returns error?|int {
    return math:randomInRange(100, 100000000000);
}

function createUser(User userRecord) returns @tainted User|Error {
    json|error userJson = json.constructFrom(userRecord);
    if (userJson is json) {
        int docId = <int>genIntId();
        var addUser = couchDbEndpoint->put("/" + baseName + "/" + docId.toString(), userJson);
        if (addUser is http:Response) {
            var msg = addUser.getJsonPayload();
            if (msg is json) {
                if (addUser.statusCode == 201) {
                    User success = {
                        id: docId,
                        username: <string>userRecord?.username,
                        firstName: <string>userRecord?.firstName,
                        lastName: <string>userRecord?.lastName,
                        email: <string>userRecord?.email,
                        phone: <string>userRecord?.phone
                    };
                    return success;
                } else {
                    Error fail = {
                        code: addUser.statusCode,
                        message: msg.reason.toString()
                    };
                    return fail;
                }
            }
        }
    }
    Error fail = {
        code: 500,
        message: "System error"
    };
    return fail;
}

function getDocumentRevById(string documentId) returns @tainted error?|string {
    var getDocument = couchDbEndpoint->get("/" + baseName + "/" + documentId);
    if (getDocument is http:Response) {
        var msg = getDocument.getJsonPayload();
        if (msg is json) {
            if (getDocument.statusCode == 200) {
                return msg._rev.toString();
            }
        }
    }
}

function findUser(int userId) returns @tainted User|Error {
    var getUser = couchDbEndpoint->get("/" + baseName + "/" + userId.toString());
    if (getUser is http:Response) {
        var msg = getUser.getJsonPayload();
        if (msg is json) {
            if (getUser.statusCode == 200) {
                User success = {
                    id: userId,
                    username: msg.username.toString(),
                    firstName: msg.firstName.toString(),
                    lastName: msg.lastName.toString(),
                    email: msg.email.toString(),
                    phone: msg.phone.toString()
                };
                return success;
            } else {
                Error fail = {
                    code: getUser.statusCode,
                    message: msg.reason.toString()
                };
                return fail;
            }
        }
    }
    Error fail = {
        code: 500,
        message: "System error"
    };
    return fail;
}

function deleteUser(int userId) returns @tainted Error {
    string strUserId = <string>userId.toString();
    var docRev = getDocumentRevById(strUserId);
    if (docRev is string) {
        var delUser = couchDbEndpoint->delete("/" + baseName + "/" + strUserId + "?rev=" + <@untainted>docRev);
        if (delUser is http:Response) {
            var msg = delUser.getJsonPayload();
            if (msg is json) {
                if (delUser.statusCode == 200) {
                    Error success = {
                        code: delUser.statusCode,
                        message: "User " + strUserId + " has been deleted!"
                    };
                    return success;
                } else {
                    Error fail = {
                        code: delUser.statusCode,
                        message: msg.reason.toString()
                    };
                    return fail;
                }
            }
        }
    } else {
        Error fail = {
            code: 403,
            message: "User not found!"
        };
        return fail;
    }
    Error fail = {
        code: 500,
        message: "System error"
    };
    return fail;
}

function updateUser(User userRecord) returns @tainted User|Error {
    string strUserId = <string>userRecord?.id.toString();
    var docRev = getDocumentRevById(strUserId);
    if (docRev is string) {
        json|error userJson = json.constructFrom(userRecord);
        if (userJson is json) {
            var changeUser = couchDbEndpoint->put("/" + baseName + "/" + strUserId + "?rev=" + <@untainted>docRev, userJson);
            if (changeUser is http:Response) {
                var msg = changeUser.getJsonPayload();
                if (msg is json) {
                    if (changeUser.statusCode == 201) {
                        User success = {
                            id: <int>userRecord?.id,
                            username: <string>userRecord?.username,
                            firstName: <string>userRecord?.firstName,
                            lastName: <string>userRecord?.lastName,
                            email: <string>userRecord?.email,
                            phone: <string>userRecord?.phone
                        };
                        return success;
                    } else {
                        Error fail = {
                            code: changeUser.statusCode,
                            message: msg.reason.toString()
                        };
                        return fail;
                    }
                }
            }
        }
    } else {
        Error fail = {
            code: 403,
            message: "User not found!"
        };
        return fail;
    }
    Error fail = {
        code: 500,
        message: "System error"
    };
    return fail;
}

