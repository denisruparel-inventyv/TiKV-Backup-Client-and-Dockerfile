FROM golang:1.23-alpine

# Alpine has almost nothing installed: bash, git, make, tar (for kubectl cp), curl, openssl, jq, nano
RUN apk add --no-cache bash git make tar curl openssl jq nano ca-certificates

# BR_REF can be a tag, a commit SHA or a branch.
# Tested commit (2026-11-05): a1a3f885bddf3a2774bea0d8adf9f0797c904dfd
ARG BR_REF=br-v1.1.0
ARG CFSSL_VERSION=v1.6.5

# One RUN, so the cleanup at the end really shrinks the image (cleanup in a later layer would not)
RUN GOBIN=/usr/local/bin go install github.com/cloudflare/cfssl/cmd/cfssl@${CFSSL_VERSION} \
 && GOBIN=/usr/local/bin go install github.com/cloudflare/cfssl/cmd/cfssljson@${CFSSL_VERSION} \
 && git clone https://github.com/tikv/migration.git /opt/migration \
 && cd /opt/migration && git checkout ${BR_REF} \
 && cd br \
 && CGO_ENABLED=0 go build -tags codes \
      -ldflags "-X github.com/tikv/migration/br/pkg/version/build.ReleaseVersion=br-v1.1.0" \
      -o /usr/local/bin/tikv-br cmd/br/*.go \
 && cfssl version && tikv-br --version \
 && cd / \
 && rm -rf /opt/migration \
 && go clean -cache -modcache

WORKDIR /data
CMD ["sleep", "infinity"]
