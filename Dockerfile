FROM node:6.12.0-alpine
ARG HEXO_CLI_VER=1.0.4
ARG THEME_NEXT_VER=v5.1.3
ARG NPM_REGISTRY=https://registry.npm.taobao.org

RUN apk add --no-cache git && \
    npm install hexo-cli@$HEXO_CLI_VER -g --registry=$NPM_REGISTRY && \
    hexo init blog && \
    npm --prefix /blog install --registry=$NPM_REGISTRY && \
    git clone --branch $THEME_NEXT_VER --depth=1 https://github.com/iissnan/hexo-theme-next blog/themes/next

WORKDIR /blog
CMD ["hexo","g"]