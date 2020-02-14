.PHONY: all build clean clean-package compress dev docs generate generate-k8s generate-provider mocks package release test tools vendor

commands = api atom build docs router

binaries = $(addprefix $(GOPATH)/bin/, $(commands))
sources  = $(shell find . -name '*.go')

all: build

build: $(binaries)

clean: clean-package

clean-package:
	find . -name '*-packr.go' -delete

compress: $(binaries)
	upx-ucl -1 $^

dev:
	test -n "$(RACK)" # RACK
	docker build --target development -t convox/convox:master .
	docker push convox/convox:master
	kubectl rollout restart deployment/api -n $(RACK)-system
	kubectl rollout restart deployment/atom -n $(RACK)-system
	kubectl rollout restart deployment/router -n $(RACK)-system
	kubectl rollout status deployment/api -n $(RACK)-system
	kubectl rollout status deployment/atom -n $(RACK)-system
	kubectl rollout status deployment/router -n $(RACK)-system

docs:
	test -n "$(VERSION)" # VERSION
	aws s3 sync docs/ s3://convox-docs/$(VERSION) --delete

generate: generate-provider generate-k8s

generate-k8s:
	make -C pkg/atom generate
	make -C provider/k8s generate

generate-provider:
	go run cmd/generate/main.go controllers > pkg/api/controllers.go
	go run cmd/generate/main.go routes > pkg/api/routes.go
	go run cmd/generate/main.go sdk > sdk/methods.go

mocks: generate-provider
	make -C pkg/atom mocks
	make -C pkg/structs mocks
	go run vendor/github.com/vektra/mockery/cmd/mockery/mockery.go -case underscore -dir pkg/start -outpkg sdk -output pkg/mock/start -name Interface
	go run vendor/github.com/vektra/mockery/cmd/mockery/mockery.go -case underscore -dir sdk -outpkg sdk -output pkg/mock/sdk -name Interface
	go run vendor/github.com/vektra/mockery/cmd/mockery/mockery.go -case underscore -dir vendor/github.com/convox/stdcli -outpkg stdcli -output pkg/mock/stdcli -name Executor

package:
	$(GOPATH)/bin/packr

release:
	test -n "$(VERSION)" # VERSION
	git tag $(VERSION) -m $(VERSION)
	git push origin refs/tags/$(VERSION)

test:
	env TEST=true go test -covermode atomic -coverprofile coverage.txt -mod=vendor ./...

tools:
	go install -mod=vendor ./vendor/github.com/karalabe/xgo

vendor:
	go mod vendor
	go mod tidy
	go run vendor/github.com/goware/modvendor/main.go -copy="**/*.c **/*.h" -v

$(binaries): $(GOPATH)/bin/%: $(sources)
	go install -mod=vendor --ldflags="-s -w" ./cmd/$*
