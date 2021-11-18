kubectl autoscale deployment app \
 --min=1 --max=5 -n my-namespace --cpu-percent=80 --save-config
