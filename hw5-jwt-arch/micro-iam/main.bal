import ballerina/http;
import ballerina/jwt;
import ballerina/uuid;
import ballerinax/redis;
import ballerina/docker;

type Auth record {
    string login;
    string password;
};

type Token record {
    string currentJwt;
};

configurable string redisUri = "localhost:6379";
configurable string redisPassword = "";
configurable boolean redisConnectionPooling = true;
configurable boolean redisIsClusterConnection = false;
configurable boolean redisSsl = false;
configurable boolean redisStartTls = false;
configurable boolean redisVerifyPeer = false;
configurable int redisConnectionTimeout = 500;
configurable string jwtIssuer = "ballerina";
configurable string jwtAudience = ?;
configurable int jwtExpTimeInSeconds = 3600;
configurable string jwtP12Path = ?;
configurable string jwtP12Password = ?;
configurable string jwtKeyAlias = ?;
configurable string jwtKeyPassword = ?;
configurable int jwtClockSkewInSeconds = 60;
configurable string httpsP12Path = ?;
configurable string httpsP12Password = ?;

class IAM {
    public function authCheck(string login, string pass) returns boolean {
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

        int|error checkUserResult = conn->exists([login]);
        if (checkUserResult is int) {
            if (checkUserResult == 1) {
                string userString = checkpanic conn->get(login);
                json userJson = checkpanic userString.fromJsonString();
                return userJson.password == pass;
            }
        }

        conn.stop();

        return false;
    }

    public function createToken(string userName) returns string|jwt:Error {
        jwt:IssuerConfig issuerConfig = {
            username: userName,
            issuer: jwtIssuer,
            audience: jwtAudience,
            keyId: uuid:createType4AsString(),
            expTimeInSeconds: jwtExpTimeInSeconds,
            signatureConfig: {config: {
                    keyStore: {
                        path: jwtP12Path,
                        password: jwtP12Password
                    },
                    keyAlias: jwtKeyAlias,
                    keyPassword: jwtKeyPassword
                }}
        };

        return jwt:issue(issuerConfig);
    }

    public function validateToken(string token) returns jwt:Payload|jwt:Error {
        jwt:ValidatorConfig config = {
            issuer: jwtIssuer,
            audience: jwtAudience,
            clockSkewInSeconds: jwtClockSkewInSeconds,
            signatureConfig: {trustStoreConfig: {
                    certAlias: jwtKeyAlias,
                    trustStore: {
                        path: jwtP12Path,
                        password: jwtP12Password
                    }
                }}
        };

        return jwt:validate(token, config);
    }
}

listener http:Listener iamEp = new (9095, config = {secureSocket: {keyStore: {
            path: httpsP12Path,
            password: httpsP12Password
        }}});

@docker:Config {
    name: "hw5-micro-iam",
    tag: "v1.0-x86_64",
    registry: "index.docker.io/$env{DOCKER_USER}",
    buildImage: true,
    push: true,
    username: "$env{DOCKER_USER}",
    password: "$env{DOCKER_PASS}"
}
service on iamEp {
    resource function post createToken(http:Caller caller, http:Request req, @http:Payload {} Auth authData) {
        IAM iam = new;
        http:Response response = new;

        if (iam.authCheck(authData.login, authData.password)) {
            string|jwt:Error token = iam.createToken(authData.login);

            if (token is jwt:Error) {
                response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                string err = "Unable to create JWT: " + token.message();
                json jsonResBody = {"error": err};
                response.setJsonPayload(<@untainted>jsonResBody);
                checkpanic caller->respond(<@untainted>response);
            }

            if (token is string) {
                json jsonResBody = {"jwt": token};
                response.setJsonPayload(<@untainted>jsonResBody);
                checkpanic caller->respond(<@untainted>response);
            }

        } else {
            response.statusCode = http:STATUS_UNAUTHORIZED;
            json jsonResBody = {"error": "Wrong login or password."};
            response.setJsonPayload(<@untainted>jsonResBody);
            checkpanic caller->respond(<@untainted>response);
        }
    }

    resource function post refreshToken(http:Caller caller, http:Request req, @http:Payload {} Token tokenData) {
        IAM iam = new;

        jwt:Payload|jwt:Error validateResult = iam.validateToken(tokenData.currentJwt);

        if (validateResult is jwt:Error) {
            http:Response response = new;
            response.statusCode = http:STATUS_UNAUTHORIZED;
            json jsonResBody = {"error": validateResult.message()};
            response.setJsonPayload(<@untainted>jsonResBody);
            checkpanic caller->respond(<@untainted>response);
        }

        if (validateResult is jwt:Payload) {
            string? sub = validateResult?.sub;
            if (sub is string) {
                string|jwt:Error token = iam.createToken(sub);

                if (token is jwt:Error) {
                    http:Response response = new;
                    response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
                    string err = "Unable to create JWT: " + token.message();
                    json jsonResBody = {"error": err};
                    response.setJsonPayload(<@untainted>jsonResBody);
                    checkpanic caller->respond(<@untainted>response);
                }

                if (token is string) {
                    http:Response response = new;
                    json jsonResBody = {"newJwt": token};
                    response.setJsonPayload(<@untainted>jsonResBody);
                    checkpanic caller->respond(<@untainted>response);
                }

            } else {
                http:Response response = new;
                response.statusCode = http:STATUS_FORBIDDEN;
                json jsonResBody = {"error": "Problem with sub field in JwtToken"};
                response.setJsonPayload(<@untainted>jsonResBody);
                checkpanic caller->respond(<@untainted>response);
            }
        }

        http:Response response = new;
        response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
        checkpanic caller->respond(<@untainted>response);
    }
}
