import ballerina/http;
import ballerinax/redis;
import ballerina/crypto;
import ballerina/docker;

configurable string redisUri = "localhost:6379";
configurable string redisPassword = "";
configurable boolean redisConnectionPooling = true;
configurable boolean redisIsClusterConnection = false;
configurable boolean redisSsl = false;
configurable boolean redisStartTls = false;
configurable boolean redisVerifyPeer = false;
configurable int redisConnectionTimeout = 500;
configurable string httpsP12Path = ?;
configurable string httpsP12Password = ?;
configurable string passKey = ?;

public type User record {
    string login;
    string password;
    UserProfile body;
};

public type UserProfile record {
    string firstName;
    string lastName;
    int age;
    string about;
};

class Registration {

    public function cryptoPass(string pass) returns string|error {
        byte[] hmacPass = checkpanic crypto:hmacSha256(pass.toBytes(), passKey.toBytes());
        return hmacPass.toBase16();
    }

    public function saveProfile(User user, string pass) returns boolean|error {
        redis:ClientEndpointConfiguration redisConfig = {
            host: redisUri,
            password: redisPassword,
            options: {
                connectionPooling: redisConnectionPooling,
                isClusterConnection: redisIsClusterConnection,
                ssl: redisSsl,
                startTls: redisStartTls,
                verifyPeer: redisVerifyPeer,
                connectionTimeout: redisConnectionTimeout
            }
        };

        redis:Client conn = checkpanic new (redisConfig);

        int|error checkUserResult = conn->exists([user.login]);

        if (checkUserResult is int) {
            if (checkUserResult == 1) {
                return false;
            } else {

                json userJson = checkpanic user.cloneWithType(json);

                string|error addUserResult = conn->set(user.login, userJson.toString());

                if (addUserResult is string) {
                    return true;
                }

                if (addUserResult is error) {
                    return addUserResult;
                }
            }
        }

        if (checkUserResult is error) {
            return checkUserResult;
        }

        conn.stop();

        return false;
    }
}

listener http:Listener regEp = new (9085, config = {secureSocket: {keyStore: {
            path: httpsP12Path,
            password: httpsP12Password
        }}});

@docker:Config {
    name: "hw5-reg-service",
    tag: "v1.0-x86_64",
    registry: "index.docker.io/$env{DOCKER_USER}",
    buildImage: true,
    push: true,
    username: "$env{DOCKER_USER}",
    password: "$env{DOCKER_PASS}"
}
service on regEp {
    resource function post createUser(http:Caller caller, http:Request req, @http:Payload {} User userData) {

        Registration reg = new;

        json userJsonBody = checkpanic userData.body.cloneWithType(json);

        string|error encryptedPass = reg.cryptoPass(userData.password);

        if (encryptedPass is string) {
            boolean|error saveProfileResult = reg.saveProfile(userData, encryptedPass);

            if (saveProfileResult is boolean) {
                if (saveProfileResult == true) {
                    http:Response response = new;
                    response.statusCode = http:STATUS_CREATED;
                    response.setJsonPayload(<@untainted>userJsonBody);
                    checkpanic caller->respond(<@untainted>response);
                } else {
                    http:Response response = new;
                    response.statusCode = http:STATUS_BAD_REQUEST;
                    json jsonResBody = {"error": "User already exists!"};
                    response.setJsonPayload(<@untainted>jsonResBody);
                    checkpanic caller->respond(<@untainted>response);
                }
            }

            if (saveProfileResult is error) {
                http:Response response = new;
                response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                json jsonResBody = {"error": saveProfileResult.message()};
                response.setJsonPayload(<@untainted>jsonResBody);
                checkpanic caller->respond(<@untainted>response);
            }

        }

        if (encryptedPass is error) {
            http:Response response = new;
            response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            json jsonResBody = {"error": encryptedPass.message()};
            response.setJsonPayload(<@untainted>jsonResBody);
            checkpanic caller->respond(<@untainted>response);
        }

        http:Response response = new;
        response.statusCode = http:STATUS_BAD_REQUEST;
        checkpanic caller->respond(<@untainted>response);
    }
}
