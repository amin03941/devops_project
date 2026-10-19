#!/bin/sh
set -eu

export KUBECONFIG=/var/lib/jenkins/.kube/config

docker stop sonarqube
docker start minikube

ready=false
for attempt in $(seq 1 60); do
    if kubectl --request-timeout=5s -n gestion-projets \
        get deployment mysql >/dev/null 2>&1
    then
        ready=true
        break
    fi
    sleep 3
done
[ "$ready" = true ] || {
    echo "API Kubernetes indisponible."
    exit 1
}

manifest="$(mktemp)"
trap 'rm -f "$manifest"' EXIT

python3 > "$manifest" <<'PY'
import os
from pathlib import Path

text = Path("k8s/application.yaml").read_text()
tag = "ci-" + str(int(os.environ["BUILD_NUMBER"]))

for component in ("backend", "frontend"):
    old = f"mohamedaminkharrat/gestion-{component}:ci-2"
    if text.count(old) != 1:
        raise SystemExit(f"Image attendue introuvable : {old}")
    text = text.replace(
        old, f"mohamedaminkharrat/gestion-{component}:{tag}"
    )

print(text)
PY

kubectl apply -f "$manifest"

for component in mysql backend frontend; do
    kubectl -n gestion-projets rollout status \
        "deployment/$component" --timeout=600s
done

kubectl -n gestion-projets get pods
kubectl -n gestion-projets get deployments \
    -o 'custom-columns=NAME:.metadata.name,IMAGE:.spec.template.spec.containers[*].image'
