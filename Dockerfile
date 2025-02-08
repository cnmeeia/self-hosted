ARG ALPINE_VER="3.21"
ARG GOLANG_VER="1.23-alpine3.21"
ARG NODE_VER="23-alpine3.20"
ARG S6_OVERLAY_VER="3.2.0.2"
ARG S6_VERBOSITY=1

ARG TORRENT_STORE_COMMIT="v1.0.0"
ARG MAGNET2TORRENT_COMMIT="cde603025e110f4d92ab423afa12b3cd5838911a"
ARG EXTERNAL_PROXY_COMMIT="20fdbe4100622834a4d7ae3c055d54d6cf5718b7"
ARG TORRENT_WEB_SEEDER_COMMIT="3d3696b2b629992bce08e2139d42894655f47ad8"
ARG TORRENT_WEB_SEEDER_CLEANER_COMMIT="2ad8ec021c602dd26b7989bb70301c19d5b5ffce"
ARG CONTENT_TRANSCODER_COMMIT="1c3fd7ece90a6512d30fd6806feb6d23e2acec9f"
ARG TORRENT_ARCHIVER_COMMIT="6234b47f92e5be5cf21d59d113e7811113e64442"
ARG SRT2VTT_COMMIT="v1.0.0"
ARG TORRENT_HTTP_PROXY_COMMIT="fa0cbd2f587fa39286ec96900ad3f487b8f9a44e"
ARG REST_API_COMMIT="846cb50a4476d6d124cec133c0abc3924c20f479"
ARG WEB_UI_COMMIT="v2.0.1"
ARG NGINX_VERSION="1.26.2"
ARG VOD_MODULE_COMMIT="26f06877b0f2a2336e59cda93a3de18d7b23a3e2"
ARG SECURE_TOKEN_MODULE_COMMIT="24f7b99d9b665e11c92e585d6645ed6f45f7d310"

FROM golang:$GOLANG_VER AS build-app

RUN apk add --no-cache build-base git
RUN git config --global http.version HTTP/1.1

WORKDIR /app
RUN mkdir "src" && mkdir "bin"

FROM build-app AS build-torrent-store

ARG TORRENT_STORE_COMMIT

ENV CGO_ENABLED=0 GOOS=linux

RUN echo $TORRENT_STORE_COMMIT > /app/bin/torrent-store.commit && \
    git clone https://github.com/webtor-io/torrent-store /app/src/torrent-store && \
    cd /app/src/torrent-store && \
    git checkout $TORRENT_STORE_COMMIT && \
    go build \
    -ldflags '-w -s -X google.golang.org/protobuf/reflect/protoregistry.conflictPolicy=ignore' \
    -a -installsuffix cgo -o /app/bin/torrent-store

FROM build-app AS build-magnet2torrent

ARG MAGNET2TORRENT_COMMIT

ENV CGO_ENABLED=0 GOOS=linux

RUN echo $MAGNET2TORRENT_COMMIT > /app/bin/magnet2torrent.commit && \
    git clone https://github.com/webtor-io/magnet2torrent /app/src/magnet2torrent && \
    cd /app/src/magnet2torrent/server && \
    git checkout $MAGNET2TORRENT_COMMIT && \
    go build \
    -ldflags '-w -s -X google.golang.org/protobuf/reflect/protoregistry.conflictPolicy=ignore' \
    -a -installsuffix cgo -o /app/bin/magnet2torrent

FROM build-app AS build-external-proxy

ARG EXTERNAL_PROXY_COMMIT

ENV CGO_ENABLED=0 GOOS=linux

RUN echo $EXTERNAL_PROXY_COMMIT > /app/bin/external-proxy.commit && \
    git clone https://github.com/webtor-io/external-proxy /app/src/external-proxy && \
    cd /app/src/external-proxy && \
    git checkout $EXTERNAL_PROXY_COMMIT && \
    go build \
    -ldflags '-w -s' \
    -a -installsuffix cgo -o /app/bin/external-proxy

FROM build-app AS build-torrent-web-seeder

ARG TORRENT_WEB_SEEDER_COMMIT

ENV CGO_LDFLAGS="-static" GOOS=linux

RUN echo $TORRENT_WEB_SEEDER_COMMIT > /app/bin/torrent-web-seeder.commit && \
    git clone https://github.com/webtor-io/torrent-web-seeder /app/src/torrent-web-seeder && \
    cd /app/src/torrent-web-seeder/server && \
    git checkout $TORRENT_WEB_SEEDER_COMMIT && \
    go build \
    -ldflags '-w -s' \
    -a -installsuffix cgo -o /app/bin/torrent-web-seeder

FROM build-app AS build-torrent-web-seeder-cleaner

ARG TORRENT_WEB_SEEDER_CLEANER_COMMIT

ENV CGO_ENABLED=0 GOOS=linux

RUN echo $TORRENT_WEB_SEEDER_CLEANER_COMMIT > /app/bin/torrent-web-seeder-cleaner.commit && \
    git clone https://github.com/webtor-io/torrent-web-seeder-cleaner /app/src/torrent-web-seeder-cleaner && \
    cd /app/src/torrent-web-seeder-cleaner && \
    git checkout $TORRENT_WEB_SEEDER_CLEANER_COMMIT && \
    go build \
    -ldflags '-w -s' \
    -a -installsuffix cgo -o /app/bin/torrent-web-seeder-cleaner

FROM build-app AS build-content-transcoder

ARG CONTENT_TRANSCODER_COMMIT

ENV CGO_ENABLED=0 GOOS=linux

RUN echo $CONTENT_TRANSCODER_COMMIT > /app/bin/content-transcoder.commit && \
    git clone https://github.com/webtor-io/content-transcoder /app/src/content-transcoder && \
    cd /app/src/content-transcoder && \
    git checkout $CONTENT_TRANSCODER_COMMIT && \
    go build \
    -ldflags '-w -s' \
    -a -installsuffix cgo -o /app/bin/content-transcoder

FROM build-app AS build-torrent-archiver

ARG TORRENT_ARCHIVER_COMMIT

ENV CGO_ENABLED=0 GOOS=linux

RUN echo $TORRENT_ARCHIVER_COMMIT > /app/bin/torrent-archiver.commit && \
    git clone https://github.com/webtor-io/torrent-archiver /app/src/torrent-archiver && \
    cd /app/src/torrent-archiver && \
    git checkout $TORRENT_ARCHIVER_COMMIT && \
    go build \
    -ldflags '-w -s' \
    -a -installsuffix cgo -o /app/bin/torrent-archiver

FROM build-app AS build-srt2vtt

ARG SRT2VTT_COMMIT

ENV GOOS=linux CGO_LDFLAGS="-static" CGO_ENABLED=1

RUN echo $SRT2VTT_COMMIT > /app/bin/srt2vtt.commit && \
    git clone https://github.com/webtor-io/srt2vtt /app/src/srt2vtt && \
    cd /app/src/srt2vtt && \
    git checkout $SRT2VTT_COMMIT && \
    go build \
    -ldflags '-w -s' \
    -a -installsuffix cgo -o /app/bin/srt2vtt

FROM build-app AS build-torrent-http-proxy

ARG TORRENT_HTTP_PROXY_COMMIT

ENV CGO_ENABLED=0 GOOS=linux

RUN echo $TORRENT_HTTP_PROXY_COMMIT > /app/bin/torrent-http-proxy.commit && \
    git clone https://github.com/webtor-io/torrent-http-proxy /app/src/torrent-http-proxy && \
    cd /app/src/torrent-http-proxy && \
    git checkout $TORRENT_HTTP_PROXY_COMMIT && \
    go build \
    -ldflags '-w -s' \
    -a -installsuffix cgo -o /app/bin/torrent-http-proxy

FROM build-app AS build-rest-api

ARG REST_API_COMMIT

ENV CGO_ENABLED=0 GOOS=linux

RUN echo $REST_API_COMMIT > /app/bin/rest-api.commit && \
    git clone https://github.com/webtor-io/rest-api /app/src/rest-api && \
    cd /app/src/rest-api && \
    git checkout $REST_API_COMMIT && \
    go build \
    -ldflags '-w -s' \
    -a -installsuffix cgo -o /app/bin/rest-api

FROM build-app AS build-web-ui

ARG WEB_UI_COMMIT

ENV CGO_ENABLED=0 GOOS=linux

RUN echo $WEB_UI_COMMIT > /app/bin/web-ui.commit && \
    git clone https://github.com/webtor-io/web-ui /app/src/web-ui && \
    cd /app/src/web-ui && \
    git checkout $WEB_UI_COMMIT && \
    go build \
    -ldflags '-w -s -X google.golang.org/protobuf/reflect/protoregistry.conflictPolicy=ignore' \
    -a -installsuffix cgo -o /app/bin/web-ui

FROM node:$NODE_VER AS build-web-ui-assets

WORKDIR /app

COPY --from=build-web-ui /app/src/web-ui .

RUN npm install

RUN npm run build

FROM alpine:$ALPINE_VER AS build-nginx-vod

ARG NGINX_VERSION
ARG VOD_MODULE_COMMIT
ARG SECURE_TOKEN_MODULE_COMMIT

RUN apk add --no-cache curl build-base openssl openssl-dev zlib-dev linux-headers pcre-dev && \
    mkdir nginx nginx-vod-module nginx-secure-token-module && \
    curl -sL https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz | tar -C /nginx --strip 1 -xz && \
    curl -sL https://github.com/kaltura/nginx-vod-module/archive/${VOD_MODULE_COMMIT}.tar.gz | tar -C /nginx-vod-module --strip 1 -xz && \
    curl -sL https://github.com/kaltura/nginx-secure-token-module/archive/${SECURE_TOKEN_MODULE_COMMIT}.tar.gz | tar -C /nginx-secure-token-module --strip 1 -xz

WORKDIR /nginx
RUN ./configure --prefix=/usr/local/nginx \
    --add-module=../nginx-vod-module \
    --add-module=../nginx-secure-token-module \
    --with-http_ssl_module \
    --with-file-aio \
    --with-threads \
    --with-cc-opt="-O3" && \
    make && make install && \
    rm -rf /nginx /nginx-vod-module /nginx-secure-token-module && \
    rm -rf /usr/local/nginx/html /usr/local/nginx/conf/*.default


FROM alpine:$ALPINE_VER AS base

ARG S6_OVERLAY_VER
ARG S6_VERBOSITY
ENV S6_VERBOSITY=$S6_VERBOSITY

ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VER}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VER}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz
RUN apk --no-cache add redis ffmpeg ca-certificates openssl pcre zlib envsubst uuidgen

WORKDIR /app

COPY --from=build-torrent-store /app/bin/* .
COPY --from=build-magnet2torrent /app/bin/* .
COPY --from=build-external-proxy /app/bin/* .
COPY --from=build-torrent-web-seeder /app/bin/* .
COPY --from=build-torrent-web-seeder-cleaner /app/bin/* .
COPY --from=build-content-transcoder /app/bin/* .
COPY --from=build-torrent-archiver /app/bin/* .
COPY --from=build-srt2vtt /app/bin/* .
COPY --from=build-torrent-http-proxy /app/bin/* .
COPY --from=build-rest-api /app/bin/* .
COPY --from=build-web-ui /app/bin/* .
COPY --from=build-web-ui /app/src/web-ui/templates /app/templates
COPY --from=build-web-ui /app/src/web-ui/pub /app/pub
COPY --from=build-web-ui-assets /app/assets/dist /app/assets/dist
COPY --from=build-nginx-vod /usr/local/nginx /usr/local/nginx

COPY etc/webtor /etc/webtor
COPY etc/nginx/conf /usr/local/nginx/conf
COPY s6-overlay /etc/s6-overlay

ENV DOMAIN=http://localhost:8080

EXPOSE 8080
# EXPOSE 8090 8091 8092 8093 8094 8095 8096 8097 8098

ENTRYPOINT ["/init"]
