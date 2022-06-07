# Basic Makefile for Golang project
# Includes GRPC Gateway, Protocol Buffers
SERVICE		?= $(shell basename `go list`)
VERSION		?= $(shell git describe --tags --always --dirty --match=v* 2> /dev/null || cat $(PWD)/.version 2> /dev/null || echo v0)
PACKAGE		?= $(shell go list)
PACKAGES	?= $(shell go list ./...)
FILES		?= $(shell find . -type f -name '*.go' -not -path "./vendor/*")

# Binaries
PROTOC		?= protoc

.PHONY: help clean fmt lint vet test test-cover generate-grpc build build-docker all

default: help

help:   ## show this help
	@echo 'usage: make [target] ...'
	@echo ''
	@echo 'targets:'
	@egrep '^(.+)\:\ .*##\ (.+)' ${MAKEFILE_LIST} | sed 's/:.*##/#/' | column -t -c 2 -s '#'

all:    ## clean, format, build and unit test
	make clean-all
	make fmt
	make build
	make test

install:    ## build and install go application executable
	go install -v ./...

env:    ## Print useful environment variables to stdout
	echo $(CURDIR)
	echo $(SERVICE)
	echo $(PACKAGE)
	echo $(VERSION)

clean:  ## go clean
	go clean

clean-all:  ## remove all generated artifacts and clean all build artifacts
	go clean -i ./...
	rm -fr rpc

tools:  ## fetch and install all required tools
	go get golang.org/x/tools/cmd/goimports
	go get github.com/golang/lint/golint
	go get github.com/golang/protobuf/protoc-gen-go
	go get github.com/mwitkow/go-proto-validators/protoc-gen-govalidators
	go get github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway
	go get github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger
	go get github.com/matryer/moq

fmt:    ## format the go source files
	go fmt ./...
	goimports -w $(FILES)

lint:   ## run go lint on the source files
	golint $(PACKAGES)

vet:    ## run go vet on the source files
	go vet ./...

tidy:
	make fmt
	make lint
	make vet

doc:    ## generate godocs and start a local documentation webserver on port 8085
	godoc -http=:8085 -index

update-dependencies:    ## update golang dependencies
	dep ensure

generate-grpc: compile-proto generate-grpcgw generate-swagger   ## generate grpc, grpc-gw files and swagger docs

compile-proto:  ## compile protobuf definitions into golang source
	cp -pR proto/ rpc/
	$(PROTOC) -Irpc/model  -I"vendor/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis" -I"$(GOPATH)/src" --go_out=plugins=grpc:rpc/model --govalidators_out=rpc/model rpc/model/*.proto
	$(PROTOC) -I/usr/local/include -Irpc -Irpc/model -I"vendor/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis/" -I"$(GOPATH)/src" --go_out=plugins=grpc:rpc --govalidators_out=rpc rpc/*.proto

generate-grpcgw:    ## generate grpc-gw reverse proxy code
	$(PROTOC) -I/usr/local/include -I. -Irpc -Irpc/model -I${GOPATH}/src -I"vendor/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis" --grpc-gateway_out=logtostderr=true:. rpc/*.proto

generate-mocks:     ## generate mock code
	go generate ./...

build: generate-grpc generate-mocks ## generate all grpc files and mocks and build the go code
	go build main.go

test: generate-grpc ## generate grpc code and run short tests
	go test -v ./... -short

test-it: generate-grpc generate-mocks   ## generate grpc code and mocks and run all tests
	go test -v ./...

test-bench: ## run benchmark tests
	go test -bench ./...

# Generate test coverage
test-cover:     ## Run test coverage and generate html report
	rm -fr coverage
	mkdir coverage
	go list -f '{{if gt (len .TestGoFiles) 0}}"go test -covermode count -coverprofile {{.Name}}.coverprofile -coverpkg ./... {{.ImportPath}}"{{end}}' ./... | xargs -I {} bash -c {}
	echo "mode: count" > coverage/cover.out
	grep -h -v "^mode:" *.coverprofile >> "coverage/cover.out"
	rm *.coverprofile
	go tool cover -html=coverage/cover.out -o=coverage/cover.html

test-all: test test-bench test-cover

binary: generate-grpc   ## Build Golang application binary with settings to enable it to run in a Docker scratch container.
	CGO_ENABLED=0 GOOS=linux go build  -ldflags '-s' -installsuffix cgo main.go
