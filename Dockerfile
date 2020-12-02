# Base from https://github.com/openresty/docker-openresty

FROM alpine:latest

MAINTAINER Natan <natan@mokyun.net>

RUN adduser -D www-data

# ENV FOR RESTY FIX FOR RUN OPM
ENV PATH="/usr/local/openresty/bin:${PATH}"

# Docker Build Arguments
ARG RESTY_VERSION="1.19.3.1"
ARG RESTY_OPENSSL_VERSION="1.1.1g"
ARG RESTY_OPENSSL_PATCH_VERSION="1.1.1f"
ARG RESTY_OPENSSL_URL_BASE="https://www.openssl.org/source"
ARG RESTY_PCRE_VERSION="8.44"
ARG RESTY_J="1"
ARG NAXSI_VERSION="1.3"
ARG LUAROCKS_VERSION="3.4.0"
ARG RESTY_CONFIG_OPTIONS="\
    --with-compat \
    --with-file-aio \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_geoip_module=dynamic \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_image_filter_module=dynamic \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-http_xslt_module=dynamic \
    --with-ipv6 \
    --with-mail \
    --with-mail_ssl_module \
    --with-md5-asm \
    --with-pcre-jit \
    --with-sha1-asm \
    --with-stream \
    --with-stream_ssl_module \
    --with-threads \
    "
ARG TENGINE_MODULES="\
    --add-module=/tmp/tengine/modules/ngx_http_concat_module/ \
    --add-module=/tmp/tengine/modules/ngx_http_trim_filter_module/ \
    --add-module=/tmp/tengine/modules/ngx_http_footer_filter_module/ \
    --add-module=/tmp/tengine/modules/ngx_http_slice_module/ \
    "

ARG EXTRA_MODULES="\
    --add-module=/tmp/ngx_brotli/ \
    --add-module=/tmp/ngx_security_headers/ \
    "

# These are not intended to be user-specified
ARG _RESTY_CONFIG_DEPS="--with-pcre \
    --with-cc-opt='-DNGX_LUA_ABORT_AT_PANIC -I/usr/local/openresty/pcre/include -I/usr/local/openresty/openssl/include' \
    --with-ld-opt='-L/usr/local/openresty/pcre/lib -L/usr/local/openresty/openssl/lib -Wl,-rpath,/usr/local/openresty/pcre/lib:/usr/local/openresty/openssl/lib' \
    "

# 1) Install apk dependencies
# 2) Download and untar OpenSSL, PCRE, NAXSI, Brotli, Tengine Modules and OpenResty
# 3) Build OpenResty with Naxsi, Brotli and Tengine Modules
# 4) Install Luarocks and Openresty modules
# 5) Cleanup

RUN \
    apk add --no-cache --virtual .build-deps \
        gd \
        build-base \
        gd-dev \
        geoip-dev \
        libxslt-dev \
        linux-headers \
        outils-md5 \
        perl-dev \
        readline-dev \
        zlib-dev \
        git \
        unzip \
        make \
        lua5.1-dev \
    && apk add --no-cache \
        curl \
        geoip \
        libgcc \
        libxslt \
        zlib \
        libstdc++ \
        bash \
        pcre-dev \
        gcc \
        libc-dev \
        openssl \
        imagemagick \
        imagemagick-dev \
        libmaxminddb-dev \
    && cd /tmp \
    && curl -fSL "${RESTY_OPENSSL_URL_BASE}/openssl-${RESTY_OPENSSL_VERSION}.tar.gz" -o openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
    && tar xzf openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
    && cd openssl-${RESTY_OPENSSL_VERSION} \
    && if [ $(echo ${RESTY_OPENSSL_VERSION} | cut -c 1-5) = "1.1.1" ] ; then \
    echo 'patching OpenSSL 1.1.1 for OpenResty' \
    && curl -s https://raw.githubusercontent.com/openresty/openresty/master/patches/openssl-${RESTY_OPENSSL_PATCH_VERSION}-sess_set_get_cb_yield.patch | patch -p1 ; \
    fi \
    && if [ $(echo ${RESTY_OPENSSL_VERSION} | cut -c 1-5) = "1.1.0" ] ; then \
    echo 'patching OpenSSL 1.1.0 for OpenResty' \
    && curl -s https://raw.githubusercontent.com/openresty/openresty/ed328977028c3ec3033bc25873ee360056e247cd/patches/openssl-1.1.0j-parallel_build_fix.patch | patch -p1 \
    && curl -s https://raw.githubusercontent.com/openresty/openresty/master/patches/openssl-${RESTY_OPENSSL_PATCH_VERSION}-sess_set_get_cb_yield.patch | patch -p1 ; \
    fi \
    && ./config \
    no-threads shared zlib -g \
    enable-ssl3 enable-ssl3-method \
    --prefix=/usr/local/openresty/openssl \
    --libdir=lib \
    -Wl,-rpath,/usr/local/openresty/openssl/lib \
    && make -j${RESTY_J} \
    && make -j${RESTY_J} install_sw \
    && cd /tmp \
    && curl -fSLk https://ftp.pcre.org/pub/pcre/pcre-${RESTY_PCRE_VERSION}.tar.gz -o pcre-${RESTY_PCRE_VERSION}.tar.gz \
    && tar xzf pcre-${RESTY_PCRE_VERSION}.tar.gz \
    && cd pcre-${RESTY_PCRE_VERSION} \
    && ./configure \
    --prefix=/usr/local/openresty/pcre \
    --disable-cpp \
    --enable-jit \
    --enable-utf \
    --enable-unicode-properties \
    && make -j${RESTY_J} \
    && make -j${RESTY_J} install \
    && cd /tmp \
    && curl -fSLk https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz -o openresty-${RESTY_VERSION}.tar.gz \
    && tar xzf openresty-${RESTY_VERSION}.tar.gz \
    && curl -fSLk https://luarocks.org/releases/luarocks-${LUAROCKS_VERSION}.tar.gz -o luarocks-${LUAROCKS_VERSION}.tar.gz \
    && tar xzf luarocks-${LUAROCKS_VERSION}.tar.gz \
    && cd /tmp/luarocks-${LUAROCKS_VERSION} \
    && ./configure \
    && make bootstrap \
    && cd /tmp \
    && git clone --single-branch --branch master https://github.com/alibaba/tengine.git --recursive \
    && curl -fSLk https://github.com/nbs-system/naxsi/archive/$NAXSI_VERSION.tar.gz -o naxsi_$NAXSI_VERSION.tar.gz \
    && tar vxf naxsi_$NAXSI_VERSION.tar.gz \
    && git clone --single-branch --branch master https://github.com/GetPageSpeed/ngx_security_headers.git --recursive \
    && git clone --single-branch --branch master https://github.com/google/ngx_brotli.git --recursive \
    && cd /tmp/openresty-${RESTY_VERSION} \
    && eval ./configure -j${RESTY_J} ${_RESTY_CONFIG_DEPS} ${RESTY_CONFIG_OPTIONS} ${TENGINE_MODULES} ${EXTRA_MODULES} --add-dynamic-module=/tmp/naxsi-$NAXSI_VERSION/naxsi_src/ \
    && make -j${RESTY_J} \
    && make -j${RESTY_J} install \
    && ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log \
    && ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log

# Luarocks Modules
RUN luarocks install lua-resty-auto-ssl

# Openresty Modules
RUN \
    opm get \
        xiedacon/lua-utility \
        c64bob/lua-resty-aes \
        detailyang/lua-resty-cors \
        ledgetech/lua-resty-http \
        openresty/lua-resty-limit-traffic \
        anjia0532/lua-resty-maxminddb \
        openresty/lua-resty-string \
        openresty/lua-resty-redis

# Cleanup
RUN \
    cd /tmp \
    && rm -rf \
    openssl-${RESTY_OPENSSL_VERSION} \
    openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
    openresty-${RESTY_VERSION}.tar.gz openresty-${RESTY_VERSION} \
    pcre-${RESTY_PCRE_VERSION}.tar.gz pcre-${RESTY_PCRE_VERSION} \
    luarocks-${LUAROCKS_VERSION}.tar.gz luarocks-${LUAROCKS_VERSION} \
    tengine \
    && apk del .build-deps

# Download Naxsi rules and GeoIP databases
RUN \
    curl -fSLk \
    https://raw.githubusercontent.com/nbs-system/naxsi/master/naxsi_config/naxsi_core.rules -o naxsi_core.rules \
    && mv naxsi_core.rules /usr/local/openresty/nginx/conf/naxsi_core.rules \
    && curl -fSLk \
    https://trash-can.mokyun.net/GeoLite2-City_20191224.tar.gz -o GeoLite2-City.tar.gz \
    && tar xzf GeoLite2-City.tar.gz \
    && mv GeoLite2-City*/GeoLite2-City.mmdb /usr/local/openresty/nginx/conf/GeoLite2-City.mmdb

ENTRYPOINT ["/usr/local/openresty/bin/openresty", "-c", "/usr/local/openresty/nginx/conf/nginx.conf" , "-g", "daemon off;"]

# Use SIGQUIT instead of default SIGTERM to cleanly drain requests
# See https://github.com/openresty/docker-openresty/blob/master/README.md#tips--pitfalls
STOPSIGNAL SIGQUIT
