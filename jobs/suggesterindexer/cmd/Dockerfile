FROM golang:1.8 as builder
WORKDIR /go/src/github.com/petard/cerebel
COPY tmp/Gopkg.toml .
COPY tmp/jobs jobs/
COPY tmp/shared shared/
RUN curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
RUN dep ensure
WORKDIR /go/src/github.com/petard/cerebel/jobs/suggesterindexer/cmd
RUN CGO_ENABLED=1 GOOS=linux go build -o bin/suggesterindexer .

FROM golang:1.8
COPY --from=builder /go/src/github.com/petard/cerebel/jobs/suggesterindexer/cmd/bin/suggesterindexer .
ENTRYPOINT ["./suggesterindexer"]
