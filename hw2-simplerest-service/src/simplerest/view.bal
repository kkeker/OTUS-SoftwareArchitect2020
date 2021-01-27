import ballerina/http;
import ballerina/docker;
import ballerina/openapi;

@docker:Config {
    name: "hw2-simplerest",
    tag: "v2.0-x86_64",
    registry: "index.docker.io/$env{DOCKER_USER}",
    buildImage: true,
    push: true,
    cmd: "CMD java -jar simplerest.jar --db.dbUser=$DB_USER --db.dbPass=$DB_PASS --db.dbHost=$DB_HOST --db.dbName=$DB_NAME",
    username: "$env{DOCKER_USER}",
    password: "$env{DOCKER_PASS}"
}

@docker:Expose {}
listener http:Listener usersEndpoint = new (8000);

@openapi:ServiceInfo {
    contract: "resources/otus55-users-1.0.0-resolved.yaml",
    tags: []
}
@http:ServiceConfig {
    basePath: "/api/v1/"
}

service users on usersEndpoint {

    function __init() {
        _ = createBaseInNotExist(baseName);
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/user",
        body: "body"
    }
    resource function createUser(http:Caller caller, http:Request req, User body) returns @tainted error? {
        http:Response response = new;
        record {} create = createUser(<@untainted>body);
        json jsonResBody = check json.constructFrom(create);
        response.setJsonPayload(<@untainted>jsonResBody);
        check caller->respond(response);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/user/{userId}"
    }
    resource function findUserById(http:Caller caller, http:Request req, int userId) returns @tainted error? {
        http:Response response = new;
        record {} get = findUser(<@untainted>userId);
        json jsonResBody = check json.constructFrom(get);
        response.setJsonPayload(<@untainted>jsonResBody);
        check caller->respond(response);
    }

    @http:ResourceConfig {
        methods: ["PUT"],
        path: "/user/{userId}",
        body: "body"
    }
    resource function updateUser(http:Caller caller, http:Request req, int userId, User body) returns @tainted error? {
        http:Response response = new;
        body.id = userId;
        record {} update = updateUser(<@untainted>body);
        json jsonResBody = check json.constructFrom(update);
        response.setJsonPayload(<@untainted>jsonResBody);
        check caller->respond(response);
    }

    @http:ResourceConfig {
        methods: ["DELETE"],
        path: "/user/{userId}"
    }
    resource function deleteUser(http:Caller caller, http:Request req, int userId) returns @tainted error? {
        http:Response response = new;
        Error delete = deleteUser(<@untainted>userId);
        json jsonResBody = check json.constructFrom(delete);
        response.setJsonPayload(<@untainted>jsonResBody);
        check caller->respond(response);
    }
}
