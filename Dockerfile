FROM golang:1.18 as build

WORKDIR /go/src/app
ADD . .

RUN go build -o /go/bin/app main.go

FROM gcr.io/distroless/base-debian10
COPY --from=build /go/bin/app /
ENTRYPOINT ["/app"]
