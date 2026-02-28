FROM golang:1.22-alpine AS build
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o service-go .

FROM alpine:3.19
WORKDIR /app
COPY --from=build /app/service-go .
EXPOSE 11003
ENTRYPOINT ["./service-go"]