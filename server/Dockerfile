FROM golang:1.26-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /asutp-server ./cmd/server/

FROM alpine:3.19
RUN apk --no-cache add ca-certificates tzdata
ENV TZ=Europe/Moscow
WORKDIR /app
COPY --from=builder /asutp-server .
COPY .env .env
EXPOSE 8080
CMD ["./asutp-server"]
