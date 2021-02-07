{{/*
Set UUIDv4 for CouchDB
*/}}
{{- define "couchdb.uuid" -}}
{{- uuidv4 -}}
{{- end -}}

{{/*
Generate CouchDB URI
*/}}
{{- define "couchdb.myuri" -}}
{{- printf "http://%s:5984" ( include "couchdb.mysvc" . ) -}}
{{- end -}}

{{/*
Generate CouchDB Service Address
*/}}
{{- define "couchdb.mysvc" -}}
{{- printf "%s-couchdb" ( include "couchdb.svcname" . | trimSuffix .Chart.Name | trimSuffix "-" ) -}}
{{- end -}}

{{/*
Generate CouchDB Monitoring Pass
*/}}
{{- define "couchdb.monpass" -}}
{{- uuidv4 -}}
{{- end -}}

{{/*
Set URI for CouchDB Exporter
*/}}
{{- define "couchdb.uri" -}}
{{- include "couchdb.myuri" . -}}
{{- end -}}

{{/*
Set Password for CouchDB Exporter
*/}}
{{- define "couchdb.password" -}}
{{- include "couchdb.monpass" . -}}
{{- end -}}
