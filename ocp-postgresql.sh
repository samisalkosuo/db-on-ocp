#!/bin/bash


function help
{
    echo "PostgreSQL install/uninstall script."
    echo ""
    echo "Usage: $0 install [<cmd-options>]"
    echo ""
    echo "Commands:"
    echo ""
    echo "  help                   - This help."
    echo "  install <NAMESPACE>    - Install PostgreSQL to given namespace."
    echo "  uninstall <NAMESPACE>  - Uninstall PostgreSQL from given namespace."
    echo ""
    exit 1
}

function error
{
    echo "ERROR: $1"
    exit 1
}

if [[ "$1" == "" ]]; then
    #echo "No commands."
    help
fi

YAMLDIR=postgresql
function installPostgreSQL
{
  local NAMESPACE=$1

  if [ "$NAMESPACE" = "" ]; then
      error "Namespace not given."
  fi

  #create new namespace
  namespaceOperation apply $NAMESPACE

  #change to project
  oc project $NAMESPACE

  #add anyuid to default service account
  oc adm policy add-scc-to-user anyuid -z default

  #create secret
  oc apply -f $YAMLDIR/secret.yaml

  #create postgres configmap
  oc apply -f $YAMLDIR/postgres-config-map.yaml

  #create service
  oc apply -f $YAMLDIR/service.yaml

  #create persistentvolumeclaim
  oc apply -f $YAMLDIR/pvc.yaml

  #create statefulset
  oc apply -f $YAMLDIR/statefulset.yaml

}

function uninstallPostgreSQL
{
  local NAMESPACE=$1

  if [ "$NAMESPACE" = "" ]; then
      error "Namespace not given."
  fi

  #change to project
  oc project $NAMESPACE

  #delete statefulset
  oc delete -f $YAMLDIR/statefulset.yaml

  #delete persistentvolumeclaim
  oc delete -f $YAMLDIR/pvc.yaml

  #delete  namespace
  namespaceOperation delete $NAMESPACE

}

function namespaceOperation
{
    local OPERATION=$1
    local NAMESPACE=$2
    cat << EOF | oc $OPERATION -f -
apiVersion: v1
kind: Namespace
metadata:
  name: $NAMESPACE
spec:
  finalizers:
  - kubernetes
EOF

}

#call functions
#note 'shift' command moves ARGS to the left 

case "$1" in
    install)
      shift
      installPostgreSQL $1
    ;;
    uninstall)
      shift
      uninstallPostgreSQL $1
    ;;    
    help)
        help
    ;;
    *)
        help
    ;;
esac


