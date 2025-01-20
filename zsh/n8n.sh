function find_cluster() {
  username=$1
  curl -s --header "x-api-key: $N8N_CLOUD_DASHBOARD_ADMIN_API_TOKEN" "$N8N_CLOUD_DASHBOARD_ADMIN_API_URL/internal/manage/account/$username?user=$(whoami)" | jq -r '.account.instance.cluster'
}

function list_backups() {
  username=$(_n8n_username "$1")
  podname=$(_n8n_podname "$username")
  kubectl exec -it "$podname" -c backup-cron -n "$username" -- n8n-backup.py list
}

function check_prune_count() {
  username=$(_n8n_username "$1")
  podname=$(_n8n_podname "$username")
  kubectl exec -it "$podname" -c n8n -n "$username" -- env | grep EXECUTIONS_DATA_PRUNE_MAX_COUNT
}

function check_data_age() {
  username=$(_n8n_username "$1")
  podname=$(_n8n_podname "$username")
  kubectl exec -it "$podname" -c n8n -n "$username" -- env | grep EXECUTIONS_DATA_MAX_AGE
}

function check_wal_mode() {
  username=$(_n8n_username "$1")
  podname=$(_n8n_podname "$username")
  kubectl describe configmap "$username"-n8n -n "$username" | grep DB_SQLITE_ENABLE_WAL -A 2
}

function n8n_version() {
  username=$(_n8n_username "$1")
  kubectl describe deploy -n "$username" | grep Image | grep '/n8n:' | cut -d ":" -f3
}

function bsh-cmd() {
  username=$(_n8n_username)
  podname=$(_n8n_podname "$username")
  kubectl exec -it -c backup-cron -n "$username" "$podname" -- "$@"
}

function instance_stats() {
  echo -e "\033[1;4muser\033[0m"
  _kubectl_namespace
  echo ""
  echo ""
  echo -e "\033[1;4mversion\033[0m"
  n8n_version
  echo ""
  echo -e "\033[1;4mpods\033[0m"
  kubectl get pods
  echo ""
  echo -e "\033[1;4mdisks\033[0m"
  kubectl get pvc --no-headers
  echo ""
  echo -e "\033[1;4mdatabase size\033[0m"
  bsh-cmd du -sh database.sqlite
  echo ""
  echo -e "\033[1;4m/binaryData dir size\033[0m"
  bsh-cmd du -sh binaryData/
  echo ""
  echo -e "\033[1;4mlimits from $(date "+%Y-%m")\033[0m"
  bsh-cmd cat $(date "+%Y-%-m")_limits.json
  echo ""
  echo ""
  echo -e "\033[1;4mactive workflow count\033[0m"
  bsh-cmd sqlite3 database.sqlite "select active, count(1) from workflow_entity group by active;"
  echo ""
  echo -e "\033[1;4mprune max count\033[0m"
  check_prune_count
  echo ""
  echo -e "\033[1;4mprune max age\033[0m"
  check_data_age
  echo ""
  echo -e "\033[1;4mlast 5 backups\033[0m"
  bsh-cmd n8n-backup.py list | tail -n5
  echo ""
  echo -e "\033[1;4msample update command\033[0m"
  echo "/cloudbot update-instance-version $(_kubectl_namespace) 1.15.2"
  echo ""
}

function watch_pods() {
  username=$(_n8n_username "$1")
  watch -n2 "kubectl get pods -n $username"
}

function _n8n_username() {
  username=${1:-$(_kubectl_namespace)}

  if [[ -z "$username" ]]; then
    username=$(_kubectl_namespace)
  fi

  echo "$username"
}

function _n8n_podname() {
  username=$1
  kubectl get pods -n "$username" | grep '\-n8n\-' | awk '{print $1}'
}

# get active namespace in current context
function _kubectl_namespace() {
  kubectl config view --minify -o jsonpath='{..namespace}'
}

# pod's live state
n8n_cloud_pod_runtime() {
  kubectl describe pod $(n8n.cloud.pod.name)
}

# pod's desired state + live state
n8n_cloud_pod_manifest() {
  kubectl get pod $(n8n.cloud.pod.name) -o yaml
}

# pod's deployment (template used to create and manage pods)
n8n_cloud_pod_deploy() {
  kubectl get deploy -o yaml
}

export_cloud_workflows() {
  kubectl exec -it $(n8n.cloud.pod.name) -c n8n -- n8n export:workflow --pretty --all | tail -n+2 > workflows-$(date +%F).json && echo "workflows-$(date +%F).json"
}

function access_pod() {
  username=$(_n8n_username "$1")
  podname=$(_n8n_podname "$username")
  kubectl exec -it "$podname" -c backup-cron -n "$username" -- bash
}

function count_queue() {
  username=$(_n8n_username "$1")
  podname=$(_n8n_podname "$username")
  kubectl exec -it "$podname" -c backup-cron -n "$username" -- sqlite3 database.sqlite "select count(*) from execution_entity where status = 'new';"
}

function clear_queue() {
  username=$(_n8n_username "$1")
  podname=$(_n8n_podname "$username")
  kubectl exec -it "$podname" -c backup-cron -n "$username" -- sqlite3 database.sqlite "delete from execution_entity where status = 'new';"
}

function switch_namespace() {
  username=$1
  cluster=$(find_cluster "$username")
  kubectl config use-context "$cluster"
  kubectl config set-context --current --namespace="$username"
}

alias n8n.cloud.ns=switch_namespace
alias n8n.cloud.backups=list_backups
alias n8n.cloud.prune.max_age=check_data_age
alias n8n.cloud.prune.max_count=check_prune_count
alias n8n.cloud.wal_mode=check_wal_mode
alias n8n.cloud.find_cluster=find_cluster
alias n8n.cloud.stats=instance_stats
alias n8n.cloud.version=n8n_version
alias n8n.cloud.watch_pods=watch_pods
alias n8n.cloud.pod.access=access_pod
alias n8n.cloud.pod.name=_n8n_podname
alias n8n.cloud.pod.runtime=n8n_cloud_pod_runtime
alias n8n.cloud.pod.manifest=n8n_cloud_pod_manifest
alias n8n.cloud.pod.deploy=n8n_cloud_pod_deploy
alias n8n.cloud.export_workflows=export_cloud_workflows
alias n8n.cloud.export_workflows=export_cloud_workflows
alias n8n.cloud.count_queue=count_queue
alias n8n.cloud.clear_queue=clear_queue

compctl -k "(cloud.ns cloud.backups cloud.prune.max_age cloud.prune.max_count cloud.wal_mode cloud.find_cluster cloud.stats cloud.version cloud.watch_pods cloud.pod.name cloud.pod.runtime cloud.pod.manifest cloud.pod.deploy cloud.export_workflows cloud.pod.access cloud.count_queue cloud.clear_queue)" n8n.
