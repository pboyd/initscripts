GO=go

all: linode.sh aws-debian.sh

bin/gen: gen/template.go gen/main.go
	mkdir -p bin && \
		cd gen && \
		$(GO) build -o ../bin/gen

linode.sh: bin/gen
	./bin/gen \
		--param-type=linode-udf \
		--authorized-keys-path='$$HOME/.ssh/authorized_keys' \
		--copy-root-password \
		--ufw \
		>$@

aws-debian.sh: bin/gen
	./bin/gen \
		--remove-user admin \
		--authorized-keys-path=/home/admin/.ssh/authorized_keys \
		--wireguard-output stdout \
		--nat \
		>$@
