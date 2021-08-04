help: HELP_SCRIPT = \
	if (/^([a-zA-Z0-9-\.\/]+).*?: description\s*=\s*(.+)/) { \
		printf "\033[34m%-40s\033[0m %s\n", $$1, $$2 \
	} elsif(/^\#\#\#\s*(.+)/) { \
		printf "\033[33m>> %s\033[0m\n", $$1 \
	}

.PHONY: help
help:
	@perl -ne '$(HELP_SCRIPT)' $(MAKEFILE_LIST)

.PHONY: setup/darwin
setup/darwin: description = Install protobuf tooling for macOS
setup/darwin:
	# Protocol compiler
	brew install protobuf@3.11.4

	# Go plugin used by the protocol compiler
	go get -u github.com/golang/protobuf/protoc-gen-go

.PHONY: setup/linux
setup/linux: description = Install protobuf tooling for linux
setup/linux:
	# Protocol compiler
	PROTOC_ZIP=protoc-3.10.1-linux-x86_64.zip
	curl -OL https://github.com/protocolbuffers/protobuf/releases/download/v3.10.1/$PROTOC_ZIP
	sudo unzip -o $PROTOC_ZIP -d /usr/local bin/protoc
	sudo unzip -o $PROTOC_ZIP -d /usr/local 'include/*'
	rm -f $PROTOC_ZIP

	# Go plugin used by the protocol compiler
	go get -u github.com/golang/protobuf/protoc-gen-go

.PHONY: generate/go
generate/go: description = Compile protobuf schemas for Go
generate/go: clean-go
generate/go:
	mkdir -p build/go/protos
	mkdir -p build/go/protos/common
	mkdir -p build/go/protos/records
	mkdir -p build/go/protos/events
	mkdir -p build/go/protos/services

	docker run --rm -w $(PWD) -v $(PWD):$(PWD) -w${PWD} jaegertracing/protobuf:0.2.0 \
	--proto_path=./protos \
	--proto_path=./protos/common \
	--proto_path=./protos/records \
	--proto_path=./protos/events \
	--proto_path=./protos/services \
	--go_out=plugins=grpc:build/go/protos \
	--go_opt=paths=source_relative \
	protos/services/*.proto


	docker run --rm -w $(PWD) -v $(PWD):$(PWD) -w${PWD} jaegertracing/protobuf:0.2.0 \
	--proto_path=./protos/common \
	--go_out=plugins=grpc:build/go/protos/common \
	--go_opt=paths=source_relative \
	protos/common/*.proto

	docker run --rm -w $(PWD) -v $(PWD):$(PWD) -w${PWD} jaegertracing/protobuf:0.2.0 \
	--proto_path=./protos/records \
	--go_out=plugins=grpc:build/go/protos/records \
	--go_opt=paths=source_relative \
	protos/records/*.proto

	docker run --rm -w $(PWD) -v $(PWD):$(PWD) -w${PWD} jaegertracing/protobuf:0.2.0 \
	--proto_path=./protos/events \
	--go_out=plugins=grpc:build/go/protos/events \
	--go_opt=paths=source_relative \
	protos/events/*.proto

	docker run --rm -w $(PWD) -v $(PWD):$(PWD) -w${PWD} jaegertracing/protobuf:0.2.0 \
	--proto_path=./protos \
	--go_out=plugins=grpc:build/go/protos \
	--go_opt=paths=source_relative \
	protos/records/*.proto


.PHONY: clean-go
clean: description = Remove all go build artifacts
clean:
	rm -rf ./build/go/*