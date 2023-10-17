SHELL:=/usr/bin/env bash
VERSION:=$(shell ./.version.sh)

default: help
.PHONY: help  # via https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## Print help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: all
all: package

.PHONY: clean
clean: ## Remove all build outputs
	rm -rf .pkg
	rm -rf out

.PHONY: build
build: ## Build the dockerhub binary
	mkdir -p out
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -o ./out/dockerhub-amd64 main.go
	CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build -o ./out/dockerhub-arm64 main.go
	lipo -create -output ./out/dockerhub ./out/dockerhub-amd64 ./out/dockerhub-arm64

.PHONY: package
package: ## Package the workflow for distribution
	rm -rf ./.pkg
	mkdir -p ./.pkg/bin
	cp -v ./out/dockerhub ./.pkg/bin/dockerhub
	ln ./images/hub.png ./.pkg/FEBEA35B-0996-4DFB-9F9A-4049E7F5D678.png
	ln ./images/hub.png ./.pkg/hub.png
	ln ./images/hub.png ./.pkg/icon.png
	ln ./images/verified.png ./.pkg/verified.png
	ln ./images/not-verified.png ./.pkg/not-verified.png
	cp -v ./workflow/info.plist ./.pkg/info.plist
	sed -i '' -e 's/__WORKFLOW_VERSION__/${VERSION}/g' ./.pkg/info.plist
	mkdir -p ./out
	cd ./.pkg && zip -r workflow.zip * && mv -v workflow.zip ../out/docker-hub-${VERSION}.alfredworkflow

.PHONY: lint
lint: ## Lint all source files in this repository (requires nektos/act: https://nektosact.com)
	act --artifact-server-path /tmp/artifacts -j lint

.PHONY: update-lint
update-lint: ## Pull updated images supporting the lint target (may fetch >10 GB!)
	docker pull catthehacker/ubuntu:full-latest
