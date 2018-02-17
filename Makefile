PROJECT := doorman-1200
CLUSTER := ruby-sample-app-cluster
DOCKER_S2I_IMAGE := centos/ruby-24-centos7
APP := ruby-sample-app
APP_ENV := production
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

publish: gcloud/set-default-project gcloud/get-cluster-creds s2i/build-image gcloud/push-image

infra: gcloud/set-default-project gcloud/create-cluster helm/init

deploy: gcloud/set-default-project gcloud/get-cluster-creds helm/deploy

helm/init:
	helm init

helm/deploy:
	helm init --client-only
	helm dep update charts/web-app
	helm upgrade $(APP)-$(APP_ENV) charts/web-app \
		--install \
		--set image.repository=$(IMAGE_REPO) \
		--set image.tag=$(VERSION) \
		--set ingress.hosts={$(APP)-$(APP_ENV).local}

gcloud/set-default-project:
	gcloud config set project $(PROJECT)

gcloud/create-cluster:
	gcloud container clusters create $(CLUSTER)

gcloud/get-cluster-creds:
	gcloud container clusters get-credentials --zone europe-west2-a $(CLUSTER)

gcloud/push-image:
	gcloud docker -- push $(VERSIONED_IMAGE_REPO)

s2i/build-image:
	s2i build . $(DOCKER_S2I_IMAGE) $(VERSIONED_IMAGE_REPO)

ci: .ci .ci/gcp-key.json .ci/google-cloud-sdk .ci/linux-386/helm
	sudo ln -s .ci/google-cloud-sdkbin/gcloud /usr/local/bin
	sudo ln -s .ci/google-cloud-sdkbin/kubectl /usr/local/bin
	sudo cp .ci/linux-386/helm /usr/local/bin
	gcloud auth activate-service-account --key-file .ci/gcp-key.json

.ci:
	mkdir -p .ci

.ci/gcp-key.json:
	echo ${GOOGLE_AUTH} > .ci/gcp-key.json

.ci/google-cloud-sdk:
	cd .ci && wget https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-189.0.0-linux-x86.tar.gz
	cd .ci && tar -xf google-cloud-sdk-189.0.0-linux-x86.tar.gz
	./.ci/google-cloud-sdk/install.sh -q --additional-components kubectl

.ci/linux-386/helm:
	cd .ci && wget https://kubernetes-helm.storage.googleapis.com/helm-v2.8.1-linux-386.tar.gz
	cd .ci && tar -xf helm-v2.8.1-linux-386.tar.gz
