FROM golang:1.14.2 as builder
WORKDIR /go/src/cerebel
COPY tmp/go.mod go.mod
COPY tmp/go.sum go.sum
COPY tmp/shared shared/
COPY tmp/jobs jobs/
WORKDIR /go/src/cerebel/jobs/searchteasers
RUN CGO_ENABLED=1 GOOS=linux go build -o bin/searchteasers .

FROM golang:1.14.2
COPY --from=builder /go/src/cerebel/jobs/searchteasers/bin/searchteasers .
ENTRYPOINT ["./searchteasers"]
