# Openresty 1.19.3.1 with Naxsi WAF

A Docker base image for Openresty with Naxsi WAF, this also includes some useful modules for CDN environment. Enjoy !

**Please, input your configuration files directly in */usr/local/openresty/nginx/conf* folder or the Openresty will not start!**

*All modules link's below point to their docs, usage or configuration example*

### Versions and stuff
* **Openresty version:** 1.19.3.1
* **Naxsi WAF version:** 1.3
* **OpenSSL version:** 1.1.1g
* **PCRE version:** 8.44
* **LuaRocks version:** 3.4.0

### Openresty modules
* [Naxsi WAF](https://github.com/nbs-system/naxsi/wiki)
* [lua-utility](https://github.com/xiedacon/lua-utility#usage)
* [lua-resty-aes](https://github.com/c64bob/lua-resty-aes#synopsis)
* [lua-resty-cors](https://github.com/detailyang/lua-resty-cors#usage)
* [lua-resty-http](https://github.com/ledgetech/lua-resty-http#synopsis)
* [lua-resty-limit-traffic](https://github.com/openresty/lua-resty-limit-traffic#synopsis)
* [lua-resty-maxminddb](https://github.com/anjia0532/lua-resty-maxminddb#synopsis)
* [lua-resty-string](https://github.com/openresty/lua-resty-string#synopsis)

### Tengine modules
* [ngx_http_concat_module](https://tengine.taobao.org/document/http_concat.html)
* [ngx_http_trim_filter_module](https://tengine.taobao.org/document/http_trim_filter.html)
* [ngx_http_footer_filter_module](https://tengine.taobao.org/document/http_footer_filter.html)
* [ngx_http_slice_module](https://tengine.taobao.org/document/http_slice.html)

### Google modules
* [ngx_brotli](https://github.com/google/ngx_brotli#configuration-directives)
* [ngx_security_headers](https://github.com/GetPageSpeed/ngx_security_headers#configuration-directives)

### LuaRocks modules
* [lua-resty-auto-ssl](https://github.com/auto-ssl/lua-resty-auto-ssl#configuration)
