# k8s-simple-guide


### To store and manage sensitive information, use Secrets

For passwords, OAuth tokens, ssh keys, etc.

The following example shows how to create a secret from a literal (useful for OAuth tokens and passwords) and how to create a secret from a file (useful for credentials files):

```bash
kubectl create secret generic name-of-secret -n my-namespace \
 --from-literal=token=${TOKEN} \
 --from-file=key.json=path_to_key/filename.json -o yaml --dry-run | kubectl apply -f -
```

The above command can be used to create the Secret for the very first time, and to update it.
`${TOKEN}` can be an environment variable in the CD settings. name-of-secret, token, my-namespace, and key.json are all placeholders only.


### To store non-confidential data in key-value pairs, use ConfigMap

For plain environment variables like hostnames, ports, API base URLs, etc.

```bash
kubectl create configmap name-of-config -n my-namespace \
 --from-literal=API_BASE_URL=${API_BASE_URL} \
 --from-literal=DB_HOST=${DB_HOST} \
 --from-literal=DB_PORT=${DB_PORT} \
 -o yaml --dry-run | kubectl apply -f -
```

The above command can be used to create the `ConfigMap` from environment variables added to the CD system to update it.


### To store configurations of services, use ConfigMap

For Nginx conf files, etc.

```bash
kubectl create configmap name-of-conf -n my-namespace \
 --from-file=path_to_conf/filename.conf -o yaml --dry-run | kubectl apply -f -
```

The above command can be used to create the `ConfigMap` from a file in the source code and to update it upon code changes.


### If a service uses a volume, use StatefulSet to provide storage

For databases, cache services, message queues systems, etc.

A StatefulSet object allows `volumeClaimTemplates` to provide stable storage using `PersistentVolumes`:

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  labels:
    app: cache
  name: cache
  namespace: my-namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cache
  serviceName: "cache"
  template:
    metadata:
      labels:
        app: cache
    spec:
      containers:
      - image: redis:4-alpine
        name: cache
        ports:
        - containerPort: 6379
          name: cache
        volumeMounts:
        - mountPath: /data
          name: app-cache
  volumeClaimTemplates:
  - metadata:
      name: app-cache
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "standard"
      resources:
        requests:
          storage: 1Gi

```


## In all other cases, use a Deployment to deploy a set of containers

For the container of the application or API, web apps, workers, etc.

The following YAML file may be used to deploy a container that loads all the keys from a ConfigMap as environment variables and mounts a `Secret` file (i.e. some application credentials) to its file system.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: my-app
  name: my-app
  namespace: my-namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
      annotations:
        configHash: "" # The field we'll use to couple our ConfigMap and Deployment
    spec:
      containers:
      - image: my-app-image:dev
        name: my-app
        args:
        - sh
        - ./startup.sh
        ports:
        - containerPort: 8000
          name: my-app
        env:
        - name: SOME_SECRET
          valueFrom:
            secretKeyRef:
              key: someSecret
              name: my-secrets
        - name: APPLICATION_CREDENTIALS
          value: /var/secrets/key.json
        envFrom:
        - configMapRef:
            name: my-config
        volumeMounts:
        - name: some-cloud-key
          mountPath: /var/secrets
      volumes:
        - name: some-cloud-key
          secret:
            secretName: my-secrets
      restartPolicy: Always
```

If the deployment uses a `ConfigMap` or `Secret`, a compute hash of those settings can be stored as an annotation to patch the deployment upon config changes, for instance:

```bash
my_secret_hash=$(kubectl -n my-namespace get secret my-secrets -o yaml | shasum -a 256)

kubectl -n my-namespace patch deployment my-app \
-p "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"configHash\":\"${my_secret_hash}\"}}}}}"
```


### To let others access your Workload, expose it as a Service

Use `LoadBalancer` to expose your `Deployment` externally using a cloud provider's load balancer

For a public website, etc.

```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: my-app
  name: my-app
  namespace: my-namespace
spec:
  type: LoadBalancer
  ports:
  - name: "my-app-service"
    port: 8080
    targetPort: 8080
  selector:
    app: my-app
Use ClusterIP to expose it on a cluster-internal IP. The service will be reachable from within the cluster only
For workers, internal APIs, etc.
apiVersion: v1
kind: Service
metadata:
  labels:
    app: my-api
  name: my-api
  namespace: my-namespace
spec:
  type: ClusterIP
  ports:
  - name: "my-api-service"
    port: 8888
    targetPort: 8888
  selector:
    app: my-api
Use a Headless service to expose a StatefulSet within the cluster only
For databases, cache services, message queues systems, etc.
apiVersion: v1
kind: Service
metadata:
  labels:
    app: my-db
  name: my-db
  namespace: my-namespace
spec:
  ports:
  - port: 5432
    name: "my-db-service"
  clusterIP: None
  selector:
    app: my-db
```


### To autoscale the number of pods, create an autoscaler

Autoscale will automatically choose and set the number of pods that run in the cluster using the provided rules:

```bash
kubectl autoscale deployment app \
 --min=1 --max=5 -n my-namespace --cpu-percent=80 --save-config
```

The command will create an HPA with target CPU utilization set to 80% and the number of replicas between 1 and 5. The configuration of the current object will be saved in its annotation
