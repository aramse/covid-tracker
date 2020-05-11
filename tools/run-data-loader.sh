[ "$#" -ne 1 ] && echo "need to pass 1 arg: environment name" && exit 1

ns="covid-tracker-$1"
source_job="data-loader"
job="data-loader-manual"

kubectl delete job -n $ns $job
kubectl create job -n $ns --from cronjob/$source_job $job
