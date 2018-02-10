PROJECT := doorman-1200
CLUSTER := cluster-2
DOCKER_S2I_IMAGE := centos/ruby-24-centos7
APP := ruby-sample-app
REGISTRY_URL := gcr.io/$(PROJECT)/$(APP):$(VERSION)

start:
	docker-compose build
	docker-compose up -d

stop:
	docker-compose stop

restart: stop start

clean:
	docker-compose down -v

shell:
	docker-compose run --rm --service-ports web

release: release/create-git-tag release/build-image release/push-image deploy

release/create-git-tag:
	git diff --exit-code && $(error You must commit files first)
	git diff-index --quiet --cached HEAD && $(error You must commit files first)
	git tag $(VERSION)
	git push origin $(VERSION)

release/build-image:
	s2i build . $(DOCKER_S2I_IMAGE) $(REGISTRY_URL)

release/push-image:
	gcloud docker -- push $(REGISTRY_URL)

deploy: deploy/get-cluster-creds deploy/set-image

deploy/set-image:
	kubectl set image deployment/$(APP) $(APP)=$(REGISTRY_URL)

deploy/get-cluster-creds:
	gcloud container clusters get-credentials $(CLUSTER)

deploy/create-cluster:
	gcloud container clusters create $(CLUSTER)

deploy_from_scratch: deploy/create-cluster deploy/build-image deploy/push-image
	kubectl run $(APP) --image=$(REGISTRY_URL) --port 8080 --replicas=3
	kubectl expose deployment $(APP) --type=LoadBalancer --port 80 --target-port 8080
