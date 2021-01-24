import ballerina/http;
import ballerina/kubernetes;

@kubernetes:Ingress {
    hostname: "arch.homework",
    name: "hw1-halthcheck-ingress",
    enableTLS: false,
    path: "/otusapp/(.*)/health",
    targetPath: "/health"
}
@kubernetes:Service {
    name: "hw1-halthcheck-service"
}
@kubernetes:Deployment {
    singleYAML: false,
    image: "$env{DOCKER_USER}/hw1-halthcheck:v2.1-x86_64",
    name: "hw1-halthcheck-deployment",
    buildImage: true,
    push: true,
    replicas: 2,
    livenessProbe: true,
    readinessProbe: true,
    updateStrategy: {
        strategyType: kubernetes:STRATEGY_ROLLING_UPDATE,
        maxUnavailable: 1,
        maxSurge: 1
    },
    username: "$env{DOCKER_USER}",
    password: "$env{DOCKER_PASS}"
}

listener http:Listener halthсheckEndpoint = new(8000);
@http:ServiceConfig {
    basePath: "/"
}
service healthCheck on halthсheckEndpoint {
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/health/"
    }
    resource function halthCheck(http:Caller caller, http:Request req) {
        http:Response res = new;
        json respondBody = {
            "status": "OK"
        };
        res.setJsonPayload(<@untainted>respondBody);
        var result = caller->respond(res);
    }
}