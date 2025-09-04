#
# Dockerfile for nginx-with-subs_filter
#

FROM nginx:alpine-slim as builder

RUN set -ex \
  && apk add --no-cache --virtual .build-deps \
     gcc \
     libc-dev \
     make \
     openssl-dev \
     pcre2-dev \
     zlib-dev \
     linux-headers \
     libxslt-dev \
     gd-dev \
     geoip-dev \
     libedit-dev \
     bash \
     alpine-sdk \
     findutils \
     curl

RUN set -ex \
  && cd /tmp \
  && export NGINX_VERSION=$(nginx -v 2>&1 | sed 's/nginx version: nginx\///') \
  && wget -O nginx.tar.gz "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" \
  && mkdir -p /usr/src/nginx \
  && tar -xf nginx.tar.gz -C /usr/src/nginx --strip-components=1

WORKDIR /usr/src

RUN set -ex \
  && git clone --depth 1 https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git

WORKDIR /usr/src/nginx

RUN set -ex \
  && export CONFARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') \
  && eval ./configure --with-compat $CONFARGS --add-dynamic-module=/usr/src/ngx_http_substitutions_filter_module \
  && make && make install

FROM nginx:alpine
COPY --from=builder /usr/lib/nginx/modules/ngx_http_subs_filter_module.so /usr/lib/nginx/modules/ngx_http_subs_filter_module.so

RUN set -ex \
  && sed -i '1iload_module /usr/lib/nginx/modules/ngx_http_subs_filter_module.so;' /etc/nginx/nginx.conf
