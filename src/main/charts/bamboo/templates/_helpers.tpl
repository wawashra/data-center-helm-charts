{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "bamboo.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "bamboo.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "bamboo.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create default value for ingress port
*/}}
{{- define "bamboo.ingressPort" -}}
{{ default (ternary "443" "80" .Values.ingress.https) .Values.ingress.port -}}
{{- end }}

{{/*
Create default value for ingress path
*/}}
{{- define "bamboo.ingressPath" -}}
{{- if .Values.ingress.path -}}
{{- .Values.ingress.path -}}
{{- else -}}
{{ default ( "/" ) .Values.bamboo.service.contextPath -}}
{{- end }}
{{- end }}

{{/*
The name of the service account to be used.
If the name is defined in the chart values, then use that,
else if we're creating a new service account then use the name of the Helm release,
else just use the "default" service account.
*/}}
{{- define "bamboo.serviceAccountName" -}}
{{- if .Values.serviceAccount.name -}}
{{- .Values.serviceAccount.name -}}
{{- else -}}
{{- if .Values.serviceAccount.create -}}
{{- include "bamboo.fullname" . -}}
{{- else -}}
default
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Common labels
*/}}
{{- define "bamboo.labels" -}}
helm.sh/chart: {{ include "bamboo.chart" . }}
{{ include "bamboo.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{ with .Values.additionalLabels }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "bamboo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "bamboo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
The command that should be run by the nfs-fixer init container to correct the permissions of the shared-home root directory.
*/}}
{{- define "sharedHome.permissionFix.command" -}}
{{- if .Values.volumes.sharedHome.nfsPermissionFixer.command }}
{{ .Values.volumes.sharedHome.nfsPermissionFixer.command }}
{{- else }}
{{- printf "(chgrp %s %s; chmod g+w %s)" .Values.bamboo.securityContext.gid .Values.volumes.sharedHome.nfsPermissionFixer.mountPath .Values.volumes.sharedHome.nfsPermissionFixer.mountPath }}
{{- end }}
{{- end }}

{{/*
The command that should be run to start the fluentd service
*/}}
{{- define "fluentd.start.command" -}}
{{- if .Values.fluentd.command }}
{{ .Values.fluentd.command }}
{{- else }}
{{- print "exec fluentd -c /fluentd/etc/fluent.conf -v" }}
{{- end }}
{{- end }}

{{- define "bamboo.image" -}}
{{- if .Values.image.registry -}}
{{ .Values.image.registry}}/{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}
{{- else -}}
{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}
{{- end }}
{{- end }}

{{/*
Defines the volume mounts used by the Bamboo container.
Note that the local-home volume is mounted twice, once for the local-home directory itself, and again
on Tomcat's logs directory. THis ensures that Tomcat+Bamboo logs get captured in the same volume.
*/}}
{{ define "bamboo.volumeMounts" }}
- name: local-home
  mountPath: {{ .Values.volumes.localHome.mountPath | quote }}
- name: local-home
  mountPath: {{ .Values.bamboo.accessLog.mountPath | quote }}
  subPath: {{ .Values.bamboo.accessLog.localHomeSubPath | quote }}
- name: shared-home
  mountPath: {{ .Values.volumes.sharedHome.mountPath | quote }}
  {{- if .Values.volumes.sharedHome.subPath }}
  subPath: {{ .Values.volumes.sharedHome.subPath | quote }}
  {{- end }}
{{- end }}

{{/*
Defining additional init containers here instead of in values.yaml to allow template overrides
*/}}
{{- define "bamboo.additionalInitContainers" -}}
{{- with .Values.additionalInitContainers }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
Defining additional containers here instead of in values.yaml to allow template overrides
*/}}
{{- define "bamboo.additionalContainers" -}}
{{- with .Values.additionalContainers }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
Defining additional volume mounts here instead of in values.yaml to allow template overrides
*/}}
{{- define "bamboo.additionalVolumeMounts" -}}
{{- with .Values.bamboo.additionalVolumeMounts }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
Defining additional environment variables here instead of in values.yaml to allow template overrides
*/}}
{{- define "bamboo.additionalEnvironmentVariables" -}}
{{- with .Values.bamboo.additionalEnvironmentVariables }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
For each additional library declared, generate a volume mount that injects that library into the Bamboo lib directory
*/}}
{{- define "bamboo.additionalLibraries" -}}
{{- range .Values.bamboo.additionalLibraries }}
- name: {{ .volumeName }}
  mountPath: "/opt/atlassian/bamboo/lib/{{ .fileName }}"
  {{- if .subDirectory }}
  subPath: {{ printf "%s/%s" .subDirectory .fileName | quote }}
  {{- else }}
  subPath: {{ .fileName | quote }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
For each additional plugin declared, generate a volume mount that injects that library into the Bamboo plugins directory
*/}}
{{- define "bamboo.additionalBundledPlugins" -}}
{{- range .Values.bamboo.additionalBundledPlugins }}
- name: {{ .volumeName }}
  mountPath: "/opt/atlassian/bamboo/atlassian-bamboo/WEB-INF/atlassian-bundled-plugins/{{ .fileName }}"
  {{- if .subDirectory }}
  subPath: {{ printf "%s/%s" .subDirectory .fileName | quote }}
  {{- else }}
  subPath: {{ .fileName | quote }}
  {{- end }}
{{- end }}
{{- end }}

{{- define "bamboo.volumes" -}}
{{ if not .Values.volumes.localHome.persistentVolumeClaim.create }}
{{ include "bamboo.volumes.localHome" . }}
{{- end }}
{{ include "bamboo.volumes.sharedHome" . }}
{{- with .Values.volumes.additional }}
{{- toYaml . | nindent 0 }}
{{- end }}
{{- end }}

{{- define "bamboo.volumes.localHome" -}}
{{- if not .Values.volumes.localHome.persistentVolumeClaim.create }}
- name: local-home
{{ if .Values.volumes.localHome.customVolume }}
{{- toYaml .Values.volumes.localHome.customVolume | nindent 2 }}
{{ else }}
  emptyDir: {}
{{- end }}
{{- end }}
{{- end }}

{{- define "bamboo.volumes.sharedHome" -}}
- name: shared-home
{{- if .Values.volumes.sharedHome.persistentVolumeClaim.create }}
  persistentVolumeClaim:
    claimName: {{ include "bamboo.fullname" . }}-shared-home
{{ else }}
{{ if .Values.volumes.sharedHome.customVolume }}
{{- toYaml .Values.volumes.sharedHome.customVolume | nindent 2 }}
{{ else }}
  emptyDir: {}
{{- end }}
{{- end }}
{{- end }}

{{- define "bamboo.volumeClaimTemplates" -}}
{{ if .Values.volumes.localHome.persistentVolumeClaim.create }}
volumeClaimTemplates:
- metadata:
    name: local-home
  spec:
    accessModes: [ "ReadWriteOnce" ]
    {{- if .Values.volumes.localHome.persistentVolumeClaim.storageClassName }}
    storageClassName: {{ .Values.volumes.localHome.persistentVolumeClaim.storageClassName | quote }}
    {{- end }}
    {{- with .Values.volumes.localHome.persistentVolumeClaim.resources }}
    resources:
      {{- toYaml . | nindent 6 }}
    {{- end }}
{{- end }}
{{- end }}

{{- define "bamboo.databaseEnvVars" -}}
{{ with .Values.database.type }}
- name: ATL_DB_TYPE
  value: {{ . | quote }}
{{ end }}
{{ with .Values.database.url }}
- name: ATL_JDBC_URL
  value: {{ . | quote }}
{{ end }}
{{ with .Values.database.credentials.secretName }}
- name: ATL_JDBC_USER
  valueFrom:
    secretKeyRef:
      name: {{ . }}
      key: {{ $.Values.database.credentials.usernameSecretKey }}
{{/* TODO: The password cannot be pre-filled. See https://bitbucket.org/dchevell/docker-atlassian-bamboo/src/master/. Keeping for now as this may come later*/}}
- name: ATL_JDBC_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ . }}
      key: {{ $.Values.database.credentials.passwordSecretKey }}
{{ end }}
{{ end }}

{{/* TODO: This probably isnt needed with the current active-passive Bamboo architecture "clustering" does not work as we know it i.e. active-active*/}}
{{- define "bamboo.clusteringEnvVars" -}}
{{ if .Values.bamboo.clustering.enabled }}
- name: CLUSTERED
  value: "true"
- name: BAMBOO_NODE_ID
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
{{ end }}
{{ end }}

{{- define "bamboo.sysprop.fluentdAppender" -}}
-Datlassian.logging.cloud.enabled={{.Values.fluentd.enabled}}
{{- end }}
