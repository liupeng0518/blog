ARG hugo_version="0.55.6"
FROM alpine:latest as builder

ARG plugins="http.cache,http.cors,http.expires,http.realip,http.git,http.minify"

RUN apk add --no-cache curl bash gnupg

RUN curl https://getcaddy.com | bash -s personal ${plugins}

RUN curl -L https://github.com/gohugoio/hugo/releases/download/v${hugo_version}/hugo_${hugo_version}_Linux-64bit.tar.gz | tar xz -C /usr/local/bin/

FROM alpine:latest

RUN apk add --no-cache openssh-client ca-certificates git

COPY --from=builder ["/usr/local/bin/caddy","/usr/local/bin/hugo","/usr/local/bin/"]

ENV CADDY_DOMAIN="localhost" \
    CADDY_TLS_EMAIL="root@example.com" \
    CADDY_GIT_REPO="https://github.com/example" \
    CADDY_GIT_BRANCH="master" \
    CADDY_GIT_HOOK="/webhook" \
    CADDY_GIT_HOOK_SECRET="secret"

WORKDIR /root

COPY --chown=root:root ["docker-entrypoint.sh","/usr/local/bin/"]
COPY --chown=root:root ["Caddyfile","/etc/caddy/"]

RUN chmod +x /usr/local/bin/docker-entrypoint.sh && \
    mkdir -p "caddy/etc" \ 
    "caddy/www" \
    "caddy/logs" \
    "caddy/assets" \
    "caddy/repo"

VOLUME ["/root/caddy"]

EXPOSE 80 443

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["caddy","-agree","-conf","/etc/caddy/Caddyfile"]