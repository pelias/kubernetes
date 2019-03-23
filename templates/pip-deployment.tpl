{{- if (or (.Values.pipEnabled) (.Values.pip.enabled)) }}
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: pelias-pip
spec:
  replicas: {{ .Values.pip.replicas }}
  minReadySeconds: 60
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: {{ .Values.pip.maxUnavailable }}
  template:
    metadata:
      labels:
        app: pelias-pip
    spec:
      initContainers:
        - name: wof-download
          image: pelias/pip-service:{{ .Values.pip.dockerTag }}
          command: ["./bin/download", "--admin-only"]
          volumeMounts:
            - name: config-volume
              mountPath: /etc/config
            - name: data-volume
              mountPath: /data
          env:
            - name: PELIAS_CONFIG
              value: "/etc/config/pelias.json"
          resources:
            limits:
              memory: 3Gi
              cpu: 4
            requests:
              memory: 1Gi
              cpu: 0.1
      containers:
        - name: pelias-pip
          image: pelias/pip-service:{{ .Values.pip.dockerTag }}
          volumeMounts:
            - name: config-volume
              mountPath: /etc/config
            - name: data-volume
              mountPath: /data
          env:
            - name: PELIAS_CONFIG
              value: "/etc/config/pelias.json"
          resources:
            limits:
              memory: 10Gi
              cpu: 3
            requests:
              memory: 5Gi
              cpu: 0.1
          readinessProbe:
            httpGet:
              path: /12/12
              port: 3102
            initialDelaySeconds: 120 #PIP service takes a long time to start up
      volumes:
        - name: config-volume
          configMap:
            name: pelias-json-configmap
            items:
              - key: pelias.json
                path: pelias.json
        - name: data-volume
          {{- if .Values.pip.pvc.create }}
          persistentVolumeClaim:
            claimName: {{ .Values.pip.pvc.name }}
          {{- else }}
          emptyDir: {}
          {{- end }}
{{- end -}}
