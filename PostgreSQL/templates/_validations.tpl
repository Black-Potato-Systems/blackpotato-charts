# template validations
{{- /* Validation: Ensure pgBackRest client present if WAL archiving is enabled */ -}}
{{- if and .Values.pgbackrest.enabled .Values.pgbackrest.walArchiving.enabled (not .Values.pgbackrest.client.present) -}}
{{- fail "pgBackRest WAL archiving requires the pgBackRest client binary in the PostgreSQL Pod. Set .Values.pgbackrest.client.present=true (and ensure the binary exists) or disable .Values.pgbackrest.walArchiving.enabled." -}}
{{- end -}}