PROJECT := doorman-1200
CLUSTER := ruby-sample-app-cluster
DOCKER_S2I_IMAGE := centos/ruby-24-centos7
APP := ruby-sample-app
APP_ENV := production
CHART := http://web-deployer-charts.storage.googleapis.com/web-app-0.1.0.tgz
IMAGE_REPO := gcr.io/$(PROJECT)/$(APP)
VERSIONED_IMAGE_REPO := $(IMAGE_REPO):$(VERSION)

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

publish: gcloud/get-cluster-creds s2i/build-image gcloud/push-image

infra: gcloud/create-cluster helm/init

deploy: gcloud/get-cluster-creds helm/deploy

helm/init:
	helm init

helm/deploy:
	helm init --client-only
	helm upgrade $(APP)-$(APP_ENV) $(CHART) \
		--install \
		--set image.repository=$(IMAGE_REPO) \
		--set image.tag=$(VERSION) \
		--set ingress.hosts={$(APP)-$(APP_ENV).local}

gcloud/create-cluster:
	gcloud container clusters create $(CLUSTER)

gcloud/get-cluster-creds:
	gcloud container clusters get-credentials --project $(PROJECT) --zone europe-west2-a $(CLUSTER)

gcloud/push-image:
	gcloud docker -- push $(VERSIONED_IMAGE_REPO)

s2i/build-image:
	s2i build . $(DOCKER_S2I_IMAGE) $(VERSIONED_IMAGE_REPO)
