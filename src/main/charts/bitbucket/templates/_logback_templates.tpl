{{- define "bitbucket.logback.initContainer" -}}
{{ if .Values.bitbucket.logging.customLogbackConfig }}
- name: copy-logback-config
  image: alpine
  volumeMounts:
    - name: logback-config
      mountPath: /logback-config
    - name: local-home
      mountPath: /local-home
  command: ["sh", "-c", "cp /logback-config/logback.xml /local-home && ls -l /local-home && cat /local-home/logback.xml"]
{{ end }}
{{ end }}

{{- define "bitbucket.logback.configVolume" }}
{{ if .Values.bitbucket.logging.customLogbackConfig }}
- name: logback-config
  configMap:
    name: {{ include "bitbucket.fullname" . }}-logback-config
{{ end }}
{{ end }}