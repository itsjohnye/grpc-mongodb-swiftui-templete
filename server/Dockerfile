FROM golang:alpine

# enviroment variables
ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64

# move to dir：/build
WORKDIR /build

# copy files into the container
COPY . .

# build as a go application
RUN go build -o app .

# move it into /dist dir (dist=distribution)
WORKDIR /dist
# copy the app to /dist
RUN cp /build/app .

# expose port 50051
EXPOSE 50051

# start the container
CMD ["/dist/app"]
