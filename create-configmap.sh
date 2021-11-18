# From literals
kubectl create configmap name-of-config -n my-namespace \
 --from-literal=API_BASE_URL=${API_BASE_URL} \
 --from-literal=DB_HOST=${DB_HOST} \
 --from-literal=DB_PORT=${DB_PORT} \
 -o yaml --dry-run | kubectl apply -f -

# From files
kubectl create configmap name-of-conf -n my-namespace \
 --from-file=path_to_conf/filename.conf -o yaml --dry-run | kubectl apply -f -
