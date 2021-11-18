my_secret_hash=$(kubectl -n my-namespace get secret my-secrets -o yaml | shasum -a 256)
kubectl -n my-namespace patch deployment my-app \
-p "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"configHash\":\"${my_secret_hash}\"}}}}}"
