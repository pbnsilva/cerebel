FROM golang:1.9 as builder
WORKDIR /go/src/github.com/petard/cerebel
COPY tmp/Gopkg.toml .
COPY tmp/shared shared/
COPY tmp/services services/
RUN curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
RUN dep ensure
WORKDIR /go/src/github.com/petard/cerebel/services/backend
RUN CGO_ENABLED=1 GOOS=linux go build -o bin/backend .

FROM golang:1.9
COPY --from=builder /go/src/github.com/petard/cerebel/services/backend/bin/backend .
ENTRYPOINT ["./backend"]
