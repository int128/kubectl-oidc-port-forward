TARGET := kubectl-auth_proxy
CIRCLE_TAG ?= HEAD
LDFLAGS := -X main.version=$(CIRCLE_TAG)

.PHONY: check run release clean

all: $(TARGET)

check:
	golangci-lint run
	go test -v -race -cover -coverprofile=coverage.out ./...

$(TARGET): $(wildcard *.go)
	go build -o $@ -ldflags "$(LDFLAGS)"

run: $(TARGET)
	PATH=.:$(PATH) kubectl auth-proxy --help

dist:
	VERSION=$(CIRCLE_TAG) goxzst -d dist/gh/ -o "$(TARGET)" -t "kubectl-auth-proxy.rb auth-proxy.yaml" -- -ldflags "$(LDFLAGS)"
	mv dist/gh/kubectl-auth-proxy.rb dist/

release: dist
	ghr -u "$(CIRCLE_PROJECT_USERNAME)" -r "$(CIRCLE_PROJECT_REPONAME)" "$(CIRCLE_TAG)" dist/gh/
	ghcp -u "$(CIRCLE_PROJECT_USERNAME)" -r "homebrew-$(CIRCLE_PROJECT_REPONAME)" -m "$(CIRCLE_TAG)" -C dist/ kubectl-auth-proxy.rb

clean:
	-rm $(TARGET)
	-rm -r dist/
