PROJECT := doorman-1200
CLUSTER := cluster-2
DOCKER_S2I_IMAGE := centos/ruby-24-centos7
APP := ruby-sample-app
VERSION := v5
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

release: release/create-git-tag deploy

release/create-git-tag:
	git tag $(VERSION)
	git push origin $(VERSION)

deploy: deploy/get-cluster-creds deploy/build-image deploy/push-image deploy/set-image

deploy/build-image:
	s2i build . $(DOCKER_S2I_IMAGE) $(REGISTRY_URL)

deploy/push-image:
	gcloud docker -- push $(REGISTRY_URL)

deploy/set-image:
	kubectl set image deployment/$(APP) $(APP)=$(REGISTRY_URL)

deploy/get-cluster-creds:
	gcloud container clusters get-credentials $(CLUSTER)

deploy/create-cluster:
	gcloud container clusters create $(CLUSTER)

deploy_from_scratch: deploy/create-cluster deploy/build-image deploy/push-image
	kubectl run $(APP) --image=$(REGISTRY_URL) --port 8080 --replicas=3
	kubectl expose deployment $(APP) --type=LoadBalancer --port 80 --target-port 8080
