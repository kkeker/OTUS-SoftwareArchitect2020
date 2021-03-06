import ballerina/http;
import ballerinax/redis;
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

public type UserProfile record {
    string firstName;
    string lastName;
    int age;
    string about;
};

class Profile {
    private redis:Client conn;

    function init() returns error? {
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

        self.conn = checkpanic new (redisConfig);
    }

    public function getProfile(string login) returns UserProfile|error {

        int|error checkUserResult = self.conn->exists([login]);
        if (checkUserResult is int) {
            if (checkUserResult == 1) {
                string userString = checkpanic self.conn->get(login);
                json userJson = checkpanic userString.fromJsonString();
                json userBodyJson = checkpanic userJson.body;
                UserProfile|error userProfile = userBodyJson.cloneWithType(UserProfile);
                return userProfile;
            } else {
                return error("User not found!");
            }
        }

        if (checkUserResult is error) {
            return checkUserResult;
        }

        self.conn.stop();

        return error("Redis connectin error!");
    }

    public function updateProfile(string login, UserProfile body) returns UserProfile|error {

        int|error checkUserResult = self.conn->exists([login]);

        if (checkUserResult is int) {
            if (checkUserResult == 1) {
                string userString = checkpanic self.conn->get(login);
                json userJson = checkpanic userString.fromJsonString();
                json Login = checkpanic userJson.login;
                json Passwod = checkpanic userJson.password;

                json newUserJson = {
                    login: Login,
                    password: Passwod,
                    body: {
                        firstName: body.firstName,
                        lastName: body.lastName,
                        age: body.age,
                        about: body.about
                    }
                };

                string|error updateUserResult = self.conn->set(login, newUserJson.toString());

                if (updateUserResult is string) {
                    return body;
                }

                if (updateUserResult is error) {
                    return updateUserResult;
                }

            } else {
                return error("User does not exist!");
            }
        }

        if (checkUserResult is error) {
            return checkUserResult;
        }

        self.conn.stop();

        return error("Redis connection errror!");
    }
}

listener http:Listener profileEp = new (9080, config = {secureSocket: {keyStore: {
            path: httpsP12Path,
            password: httpsP12Password
        }}});

@docker:Config {
    name: "hw5-profile-service",
    tag: "v1.5-x86_64",
    registry: "index.docker.io/$env{DOCKER_USER}",
    buildImage: true,
    push: true,
    username: "$env{DOCKER_USER}",
    password: "$env{DOCKER_PASS}"
}
service on profileEp {

    resource function get .(http:Caller caller, http:Request req) {

        Profile|error profile = new;

        string|error userId = req.getHeader("X-User-Id");

        if (userId is string) {

            if (profile is Profile) {
                UserProfile|error userProfile = profile.getProfile(userId);

                if (userProfile is UserProfile) {
                    http:Response response = new;
                    json userProfileJson = checkpanic userProfile.cloneWithType(json);
                    json jsonResBody = {"profile": userProfileJson};
                    response.setJsonPayload(<@untainted>jsonResBody);
                    checkpanic caller->respond(<@untainted>response);
                } else {
                    http:Response response = new;
                    response.statusCode = http:STATUS_NOT_FOUND;
                    json jsonResBody = {"error": userProfile.message()};
                    response.setJsonPayload(<@untainted>jsonResBody);
                    checkpanic caller->respond(<@untainted>response);
                }
            }

            if (profile is error) {
                http:Response response = new;
                response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                json jsonResBody = {"error": profile.message()};
                response.setJsonPayload(<@untainted>jsonResBody);
                checkpanic caller->respond(<@untainted>response);
            }

        } else {
            http:Response response = new;
            response.statusCode = http:STATUS_BAD_REQUEST;
            json jsonResBody = {"error": "Header X-User-Id not provided!"};
            response.setJsonPayload(<@untainted>jsonResBody);
            checkpanic caller->respond(<@untainted>response);
        }

        http:Response response = new;
        response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
        checkpanic caller->respond(<@untainted>response);
    }

    resource function put .(http:Caller caller, http:Request req, @http:Payload {} UserProfile userBody) {

        Profile|error profile = new;

        string|error userId = req.getHeader("X-User-Id");

        if (userId is string) {

            if (profile is Profile) {
                UserProfile|error updateProfile = profile.updateProfile(userId, userBody);

                if (updateProfile is UserProfile) {
                    http:Response response = new;
                    json userProfileJson = checkpanic updateProfile.cloneWithType(json);
                    json jsonResBody = {"updatedProfile": userProfileJson};
                    response.statusCode = http:STATUS_CREATED;
                    response.setJsonPayload(<@untainted>jsonResBody);
                    checkpanic caller->respond(<@untainted>response);
                } else {
                    http:Response response = new;
                    response.statusCode = http:STATUS_NOT_FOUND;
                    json jsonResBody = {"error": updateProfile.message()};
                    response.setJsonPayload(<@untainted>jsonResBody);
                    checkpanic caller->respond(<@untainted>response);
                }
            }

            if (profile is error) {
                http:Response response = new;
                response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                json jsonResBody = {"error": profile.message()};
                response.setJsonPayload(<@untainted>jsonResBody);
                checkpanic caller->respond(<@untainted>response);
            }

        } else {
            http:Response response = new;
            response.statusCode = http:STATUS_BAD_REQUEST;
            json jsonResBody = {"error": "Header X-User-Id not provided!"};
            response.setJsonPayload(<@untainted>jsonResBody);
            checkpanic caller->respond(<@untainted>response);
        }

        http:Response response = new;
        response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
        checkpanic caller->respond(<@untainted>response);
    }
}
