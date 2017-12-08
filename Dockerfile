FROM node:6.12.1-alpine
ARG HEXO_CLI_VER=1.0.4
ARG THEME_NEXT_VER=v5.1.3
ARG NPM_REGISTRY=https://registry.npm.taobao.org

RUN echo "http://mirrors.aliyun.com/alpine/v3.4/main/" > /etc/apk/repositories && \
    apk add --no-cache git && \
    npm install hexo-cli@$HEXO_CLI_VER -g --registry=$NPM_REGISTRY && \
    hexo init hexo && \
    npm --prefix /hexo install --registry=$NPM_REGISTRY && \
    git clone --branch $THEME_NEXT_VER --depth=1 https://github.com/iissnan/hexo-theme-next blog/themes/next

WORKDIR /hexo
CMD ["hexo","g"]