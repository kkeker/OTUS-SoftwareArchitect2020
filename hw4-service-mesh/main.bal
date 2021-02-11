import ballerina/http;
import ballerina/docker;
import ballerinax/prometheus as _;
import ballerinax/jaeger as _;

configurable string ver = "v0";

@docker:Config {
    name: "hw4-whoiam",
    tag: "v1.2-x86_64",
    registry: "index.docker.io/$env{DOCKER_USER}",
    buildImage: true,
    push: true,
    username: "$env{DOCKER_USER}",
    password: "$env{DOCKER_PASS}"
}

service on new http:Listener(8000) {
    resource function get whoiam() returns @http:Payload {mediaType: "application/json"} json {
        return { "version": ver };
    }
}