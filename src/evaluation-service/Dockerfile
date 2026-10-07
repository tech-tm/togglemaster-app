FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

FROM alpine:3.20
RUN apk --no-cache add ca-certificates tzdata curl jq
WORKDIR /root/
COPY --from=builder /app/main .
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

EXPOSE 8004
ENTRYPOINT ["/root/entrypoint.sh"]
CMD ["./main"]