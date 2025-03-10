FROM golang:1.24.1 AS build

WORKDIR /app

COPY go.mod go.sum ./

RUN go mod download

COPY . .

RUN mkdir -p /dist

RUN CGO_ENABLED=0 GOOS=linux go build -o /dist/main cmd/api/main.go

FROM ubuntu:24.04

COPY --from=build /dist/main /usr/local/bin/main

EXPOSE 8000

ENTRYPOINT ["/usr/local/bin/main"]
