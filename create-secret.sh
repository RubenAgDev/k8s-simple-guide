kubectl create secret generic name-of-secret -n my-namespace \
 --from-literal=token=${TOKEN} \
 --from-file=key.json=path_to_key/filename.json -o yaml --dry-run | kubectl apply -f -
