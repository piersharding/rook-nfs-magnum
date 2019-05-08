
.PHONY: k8s all apply operator clean ls podlogs help
.DEFAULT_GOAL := help

k8s: ## Which kubernetes are we connected to
	@echo "Kubernetes cluster-info:"
	@kubectl cluster-info
	@echo ""
	@echo "kubectl version:"
	@kubectl version

clean: ## clean everything except the Namespace and the Cinder StorageClass
	kubectl delete -f busybox-rc.yaml || true
	kubectl delete -f complete-web-example.yaml || true
	kubectl delete -f rook-nfs-sc-example.yaml || true
	kubectl delete -f rook-nfs-example.yaml || true
	kubectl delete -f operator.yaml || true

cindersc:  ## Create the Cinder StorageClass
	kubectl get sc standard ||  kubectl apply -f cinder-storageclass.yaml

rmcindersc:  ## Delete the Cinder StorageClass
	kubectl delete -f cinder-storageclass.yaml

all: operator apply ## Deploy everything

operator: ## deploy Rook NFS Operator
	kubectl apply -f operator.yaml
	sleep 5

apply: cindersc ## Deploy complete Rook NFS example
	sleep 5
	kubectl apply -f rook-nfs-example.yaml
	sleep 10
	kubectl apply -f rook-nfs-sc-example.yaml
	sleep 10
	kubectl apply -f complete-web-example.yaml
	kubectl apply -f busybox-rc.yaml

poddescribe: ## describe Pods
	@for i in `kubectl get pods -l app=nfs-demo -o=name`; \
	do echo "---------------------------------------------------"; \
	echo "Describe for $${i}"; \
	echo kubectl describe $${i}; \
	echo "---------------------------------------------------"; \
	kubectl describe $${i}; \
	echo "---------------------------------------------------"; \
	echo ""; echo ""; echo ""; \
	done

podlogs: ## show POD logs
	@for i in `kubectl get pods -l app=nfs-demo -o=name`; \
	do \
	echo "---------------------------------------------------"; \
	echo "Logs for $${i}"; \
	echo kubectl logs $${i}; \
	echo kubectl get $${i} -o jsonpath="{.spec.initContainers[*].name}"; \
	echo "---------------------------------------------------"; \
	for j in `kubectl get $${i} -o jsonpath="{.spec.initContainers[*].name}"`; do \
	RES=`kubectl logs $${i} -c $${j} 2>/dev/null`; \
	echo "initContainer: $${j}"; echo "$${RES}"; \
	echo "---------------------------------------------------";\
	done; \
	echo "Main Pod logs for $${i}"; \
	echo "---------------------------------------------------"; \
	for j in `kubectl get $${i} -o jsonpath="{.spec.containers[*].name}"`; do \
	RES=`kubectl logs $${i} -c $${j} 2>/dev/null`; \
	echo "Container: $${j}"; echo "$${RES}"; \
	echo "---------------------------------------------------";\
	done; \
	echo "---------------------------------------------------"; \
	echo ""; echo ""; echo ""; \
	done

help:   ## show this help.
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
