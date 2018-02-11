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

release:
	git diff --exit-code
	git diff-index --quiet --cached HEAD
	git tag $(VERSION)
	git push origin master $(VERSION)

deploy: deploy/build-image deploy/push-image deploy/set-default-project deploy/get-cluster-creds deploy/set-image

deploy/build-image:
	s2i build . $(DOCKER_S2I_IMAGE) $(REGISTRY_URL)

deploy/push-image:
	gcloud docker -- push $(REGISTRY_URL)

deploy/set-image:
	kubectl set image deployment/$(APP) $(APP)=$(REGISTRY_URL)

deploy/set-default-project:
	gcloud config set project $(PROJECT)

deploy/get-cluster-creds:
	gcloud container clusters get-credentials --zone europe-west2 $(CLUSTER)

deploy/create-cluster:
	gcloud container clusters create $(CLUSTER)

deploy_from_scratch: deploy/set-default-project deploy/create-cluster deploy/build-image deploy/push-image
	kubectl run $(APP) --image=$(REGISTRY_URL) --port 8080 --replicas=3
	kubectl expose deployment $(APP) --type=LoadBalancer --port 80 --target-port 8080
