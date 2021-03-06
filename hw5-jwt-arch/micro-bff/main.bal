import ballerina/http;
import ballerina/jwt;
import ballerina/docker;

configurable string jwtIssuer = "ballerina";
configurable string jwtAudience = ?;
configurable string jwtP12Path = ?;
configurable string jwtP12Password = ?;
configurable string jwtKeyAlias = ?;
configurable int jwtClockSkewInSeconds = 60;
configurable string httpsP12Path = ?;
configurable string httpsP12Password = ?;
configurable string profileBackendUrl = "http://localhost";
configurable int httpBackEndTimeout = 10000;

listener http:Listener securedEP = new (9090, config = {secureSocket: {keyStore: {
            path: httpsP12Path,
            password: httpsP12Password
        }}});

function jwtAuth(http:Request req) returns jwt:Payload|jwt:Error|error {
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

    string|error bearerToken = req.getHeader("Authorization");

    if (bearerToken is string) {
        return jwt:validate(bearerToken.substring(7), config);
    }

    return error("Problem with Authorization Header");
}

http:ClientConfiguration clientEPConfig = {
    timeoutInMillis: httpBackEndTimeout,
    secureSocket: {disable: true}
};

http:Client profileEndpoint = check new (profileBackendUrl, clientEPConfig);

@docker:Config {
    name: "hw5-micro-bff",
    tag: "v1.1-x86_64",
    registry: "index.docker.io/$env{DOCKER_USER}",
    buildImage: true,
    push: true,
    username: "$env{DOCKER_USER}",
    password: "$env{DOCKER_PASS}"
}
service on securedEP {
    resource function 'default profile(http:Caller caller, http:Request req) {
        jwt:Payload|jwt:Error|error auth = jwtAuth(req);

        if (auth is jwt:Error) {
            http:Response response = new;
            response.statusCode = http:STATUS_UNAUTHORIZED;
            json jsonResBody = {"error": auth.message()};
            response.setJsonPayload(<@untainted>jsonResBody);
            checkpanic caller->respond(<@untainted>response);
        }

        if (auth is jwt:Payload) {

            string? sub = auth?.sub;

            if (sub is string) {

                req.setHeader("X-User-Id", sub);

                var httpReq = profileEndpoint->forward("/", req);

                if (httpReq is http:Response) {
                    checkpanic caller->respond(httpReq);
                }

                if (httpReq is error) {
                    http:Response response = new;
                    response.statusCode = http:STATUS_SERVICE_UNAVAILABLE;
                    json jsonResBody = {"error": httpReq.message()};
                    response.setJsonPayload(<@untainted>jsonResBody);
                    checkpanic caller->respond(<@untainted>response);
                }
                
                http:Response response = new;
                response.statusCode = http:STATUS_SERVICE_UNAVAILABLE;
                checkpanic caller->respond(<@untainted>response);

            } else {
                http:Response response = new;
                response.statusCode = http:STATUS_FORBIDDEN;
                json jsonResBody = {"error": "Problem with sub field in JwtToken"};
                response.setJsonPayload(<@untainted>jsonResBody);
                checkpanic caller->respond(<@untainted>response);
            }
        }

        if (auth is error) {
            http:Response response = new;
            response.statusCode = http:STATUS_UNAUTHORIZED;
            json jsonResBody = {"error": auth.message()};
            response.setJsonPayload(<@untainted>jsonResBody);
            checkpanic caller->respond(<@untainted>response);
        }

        http:Response response = new;
        response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
        checkpanic caller->respond(<@untainted>response);
    }
}
