# Homework project for the course OTUS: [Software Architect](https://otus.ru/lessons/arhitektor-po/) 2020

## Тема: Основы работы с Kubernetes (часть 3) ##

### Домашнее задание ###

Инфраструктурные паттерны
Сделать простейший RESTful CRUD по созданию, удалению, просмотру и обновлению пользователей.
Пример API - https://app.swaggerhub.com/apis/otus55/users/1.0.0

Добавить базу данных для приложения.
Базу данных установить helm-ом из одного из репозиториев чартов (желательно официальных).
Конфигурация приложения должна хранится в Configmaps.
Доступы к БД должны храниться в Secrets.
Первоначальные миграции должны быть оформлены в качестве Job-ы, если это требуется.
Ingress-ы должны также вести на url arch.homework/otusapp/{student-name}/* (как и в прошлом задании)

На выходе должны быть предоставлена
1) ссылка на директорию в github, где находится директория с манифестами кубернетеса
2) инструкция по запуску приложения.
- команда установки БД из helm, вместе с файлом values.yaml.
- команда применения первоначальных миграций
- команда kubectl apply -f, которая запускает в правильном порядке манифесты кубернетеса
3) Postman коллекция, в которой будут представлены примеры запросов к сервису на создание, получение, изменение и удаление пользователя. Важно: в postman коллекции использовать базовый url - arch.homework.


Задание со звездочкой:
+3 балла за шаблонизацию приложения в helm 3 чартах
+2 балла за использование официального helm чарта для БД и подключение его в чарт приложения в качестве зависимости.


### Примечания к решению: ###

Был использован стек [Ballerina.io](https://ballerina.io/) имеющий интеграцию с [Docker](https://ballerina.io/learn/deployment/docker/).
Описание конфигурации Docker начинается в коде приложения `./hw2-simplerest-service/src/simplerest/view.bal` в соответствии с [документацией](https://github.com/ballerina-platform/module-ballerina-docker).
Для работы с K8S Secrets и использования их как ENV в контейнере сделана подмена строки `CMD` в Dockerfile через конфигурацию в коде `./hw2-simplerest-service/src/simplerest/view.bal`.
Для выполнения задания (использования и ConfigMap, и Secret) использован антипаттерн безопасного хранения ключей безопасности и они продублированы как в Secret, так и в ConfigMap.
Для учебного примера их значения указаны в открытом виде в `values.yaml` для Helm, что конечно не пригодно для Production.
В данном случае приложение может использовать как конфигурационный файл из ConfigMap, так и переменные из Secret. Переменные имеют приоритет, но файл конфигурации монтируется в контейнер корректно.

В качестве базы данных использован стек [Apache CouchDB](https://couchdb.apache.org) из [официального Helm3](https://artifacthub.io/packages/helm/couchdb/couchdb).
Важным моментом является то, что в описании настроек Helm для CouchDB не указан параметр настройки DNS-имени (`dns.clusterDomainSuffix` это не он) для K8S-Service этого Deploy и поэтому нельзя использовать `helm install --generate-name` если Helm CouchDB используется как зависимость.
В этом случае адрес кластера базы данных будет динамическим и его нельзя будет определить заранее в сервисах-потребителях.

Helm 3 находятся в директории `./hw2-simplerest-service/helm/simplerest/`.
Манифесты, сгенерированные командой  `helm template --dependency-update --output-dir kubernetes --release-name hw2 ./hw2-simplerest-service/helm/simplerest/` находятся в директории `./hw2-simplerest-service/kubernetes/simplerest/`. По указанной выше причине, `--release-name hw2` должно быть строго `hw2`!

Ссылка на [публичную коллекцию Postman](https://www.getpostman.com/collections/a57a15611e86c9adf190).

**Build для Ballerina v1.2.x:**
1. `export DOCKER_USER={LOGIN_DOCKERHUB} && export DOCKER_PASS={PASSWORD_DOCKERHUB} && ballerina build -a`

**Deploy с использованием Helm 3**
1. `helm install --dependency-update hw2 ./hw2-simplerest-service/helm/simplerest/` По указанной выше причине, имя инсталляции должно быть строго `hw2`!
