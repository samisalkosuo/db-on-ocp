#!/bin/bash


function help
{
    echo "MongoDB install/uninstall script."
    echo ""
    echo "Usage: $0 install [<cmd-options>]"
    echo ""
    echo "Commands:"
    echo ""
    echo "  help                   - This help."
    echo "  install <NAMESPACE>    - Install MongoDB to given namespace."
    echo "  uninstall <NAMESPACE>  - Uninstall MongoDB from given namespace."
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

YAMLDIR=mongodb

function installMongoDB
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

    oc apply -f $YAMLDIR/pvc.yaml

    oc apply -f $YAMLDIR/secret.yaml

    oc apply -f $YAMLDIR/service.yaml

    oc apply -f $YAMLDIR/statefulset.yaml

}

function uninstallMongoDB
{
    local NAMESPACE=$1
    if [ "$NAMESPACE" = "" ]; then
      error "Namespace not given."
    fi

    oc delete -f $YAMLDIR/statefulset.yaml

    oc delete -f $YAMLDIR/pvc.yaml

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
      installMongoDB $1
    ;;
    uninstall)
      shift
      uninstallMongoDB $1
    ;;    
    help)
        help
    ;;
    *)
        help
    ;;
esac



