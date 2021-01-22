# Homework project for the course OTUS: [Software Architect](https://otus.ru/lessons/arhitektor-po/) 2020

## Тема: Основы работы с Kubernetes (часть 2) ##

### Домашнее задание: ###

Основы работы с Kubernetes (часть 2)
Создать минимальный сервис, который
1) отвечает на порту 8000
2) имеет http-метод
   GET /health/
   RESPONSE: {"status": "OK"}

Cобрать локально образ приложения в докер.
Запушить образ в dockerhub

Написать манифесты для деплоя в k8s для этого сервиса.

Манифесты должны описывать сущности Deployment, Service, Ingress.
В Deployment могут быть указаны Liveness, Readiness пробы.
Количество реплик должно быть не меньше 2. Image контейнера должен быть указан с Dockerhub.

В Ingress-е должно быть правило, которое форвардит все запросы с /otusapp/{student name}/* на сервис с rewrite-ом пути. Где {student name} - это имя студента.

Хост в ингрессе должен быть arch.homework. В итоге после применения манифестов GET запрос на http://arch.homework/otusapp/{student name}/health должен отдавать {“status”: “OK”}.

На выходе предоставить
0) ссылку на github c манифестами. Манифесты должны лежать в одной директории, так чтобы можно было их все применить одной командой kubectl apply -f .
1) url, по которому можно будет получить ответ от сервиса (либо тест в postmanе).


### Примечания к решению: ###

Был использован стек [Ballerina.io](https://ballerina.io/) имеющий интеграцию с [Docker](https://ballerina.io/learn/deployment/docker/) и [Kubernetes](https://ballerina.io/learn/deployment/kubernetes/).
Описание конфигурации Kubernetes начинается в коде приложения `./hw1-healthcheck-service/src/healthcheck/main.bal` в соответствии с [документацией](https://github.com/ballerina-platform/module-ballerina-kubernetes).
Манифест конфигурации Docker сгенерирован автоматически и находится в директории  `./hw1-healthcheck-service/target/docker/healthcheck`.
Манифесты конфигурации Kubernetes сгенерированы автоматически и находятся в директории `./hw1-healthcheck-service/target/kubernetes/healthcheck`.
Ссылка на [публичную коллекцию Postman](https://www.getpostman.com/collections/a57a15611e86c9adf190).

**Build & Deploy для Ballerina v1.2.x:**
1. `export DOCKER_USER={LOGIN_DOCKERHUB} && export DOCKER_PASS={PASSWORD_DOCKERHUB} && ballerina build -a`
2. `kubectl apply -f ./hw1-healthcheck-service/target/kubernetes/healthcheck`

**Примечание к module-ballerina-kubernetes:**
Ballerina до перехода на версию [Swan Lake](https://ballerina.io/downloads/), находящуюся на стадии Preview, использует устаревший плагин kubernetes.
Создаются HelmChart v2 вместо v3 и используется старая спецификация генерации манифестов Ingress.
В новой спецификации манифест Ingress выглядел бы так:
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
    name: hw1-halthcheck-ingress
    annotations:
        kubernetes.io/ingress.class: nginx
        nginx.ingress.kubernetes.io/rewrite-target: /health
        nginx.ingress.kubernetes.io/ssl-passthrough: false
spec:
    rules:
        - host: arch.homework
          http:
            paths:
                - path: /otusapp/kkeker/health
                  pathType: Prefix
                  backend:
                    service:
                        name: hw1-halthcheck-service
                        port:
                            number: 8000
```