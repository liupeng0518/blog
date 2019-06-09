---
title: 博客搬家——从 Hexo 迁移到 Hugo
date: 2019-06-04T21:45:00+08:00
categories:
    - Linux
tags:
    - Hugo
    - Caddy
---

久违的再次迁移博客，这次是由 Hexo 迁移到 Hugo，对于 Hexo 其实也没并没有觉得不好用，当然，可能还是我~~懒癌~~写的博客篇数太少的缘故。

Github 开启了免费私有仓库之后，自建 Git 仓库的需求消失了，阿里云服务器唯一存在的意义就只有博客了。这次除了用 Hugo 代替 Hexo 之外，还会使用 Caddy 来替换 Nginx，顺便完善一下之前一直有计划但是没动手实现的自动更新。

<!--more-->

## 目标

首先是确定要完成的目标：

* 使用 Hugo 替换 Hexo 
* 使用 Caddy 替换 Nginx
* 通过 Caddy Git 插件自动更新
* 使用 Docker 编排部署

## Hugo

Hexo 和 Hugo 都是通过 Markdown 来生成静态文件，博客数据这块迁移没有什么难点，考虑到博客篇数很少，手动修改格式来适配 Hugo 即可，顺便检查一下文章，删掉一些~~年轻时的黑历史~~不太重要的文章。

我选择使用 [Beautiful Hugo - A port of Beautiful Jekyll Theme](https://github.com/halogenica/beautifulhugo)，根据 Hugo 官网的 Quick Start 走遇到第一个坑。

### 路径问题

官网 Quick Start 中是将 md 文件存放到 `content/posts` 路径，但是 Beautiful Hugo 找寻的路径是 `content/post`。一般来说是可以通过 `.Site.Params.mainSections` 变量配置该路径的，不过 Beautiful Hugo 使用了硬编码来配置路径。

```html
<div class="posts-list">
          {{ $pag := .Paginate (where .Data.Pages "Type" "post") }}
```

好在已经有人提交 [PR#241](https://github.com/halogenica/beautifulhugo/pull/241) 来修复这个问题，不过在合并之前只能先用 `content/post` 路径。

### 放置备案号

国内要求将备案号放在页面中，虽然 Beautiful Hugo 支持国际化多语言，但是这个中国本地化特色需求没有支持。修改 `themes/beautifulhugo/layouts/partials/foot.html` 可以解决问题，不过这种侵入式的修改不太优雅。

注：可以复制 `themes/beautifulhugo/layouts/partials/foot.html` 到根目录 `layouts/partials/foot.html`，再进行修改。 

打开 `themes/beautifulhugo/laouts/partials/footer.html` 可以看到，Beautiful Hugo 在生成 poweredBy 内容时使用了 i18n 的方式。

```html
<p class="credits theme-by text-muted">
  {{ i18n "poweredBy" . | safeHTML }}
  {{ with .Site.Params.commit }}&nbsp;&bull;&nbsp;[<a href="{{.}}{{ getenv "GIT_COMMIT_SHA" }}">{{ getenv "GIT_COMMIT_SHA_SHORT" }}</a>]{{ end }}
</p>
```

在 `themes/beautifulhugo/i18n/zh-CN.yaml` 中可以查看到 poweredBy 最终渲染的内容，可以利用这个来实现在 poweredBy 后添加备案号。

```yaml
# Footer
- id: poweredBy # Accepts HTML
  translation: '由 <a href="http://gohugo.io">Hugo v{{ .Site.Hugo.Version }}</a> 强力驱动 &nbsp;&bull;&nbsp; 主题 <a href="https://github.com/halogenica/beautifulhugo">Beautiful Hugo</a> 移植自 <a href="http://deanattali.com/beautiful-jekyll/">Beautiful Jekyll</a>'
```

在项目根目录创建 `i18n/zh-CN.yaml`，并添加以下内容。

```yaml
# Footer
- id: poweredBy # Accepts HTML
  translation: '由 <a href="http://gohugo.io">Hugo v{{ .Site.Hugo.Version }}</a> 强力驱动 &nbsp;&bull;&nbsp; 主题 <a href="https://github.com/halogenica/beautifulhugo">Beautiful Hugo</a> 移植自 <a href="http://deanattali.com/beautiful-jekyll/">Beautiful Jekyll</a> &nbsp;&bull;&nbsp; <a target="_blank" href="http://www.beian.miit.gov.cn/">{{ .Site.Params.beian }}</a>'
```

然后就可以在 `config.toml` 中配置备案号了,并且只有当语言为中文时才会显示。

```toml
DefaultContentLanguage = "zh-cn"
[Params]
    beian = "鄂ICP备15001586号"
```

## Caddy

Caddy 和 Hugo 一样都是 golang 开发的，从个人角度看，最大的优势是单个二进制文件部署，自动完成 HTTPS、HTTP/2 配置，简单好用说的就是它了。Caddy 并没有提供官方的 Docker 镜像，而且由于 Caddy Plugin 存在，必须自定义构建 Docker 镜像，同时还需要在镜像中加入 Hugo 运行环境。

### 构建 Caddy 镜像

在项目根目录下创建 docker 文件夹，然后创建构建镜像需要的 `Dockerfile` `Caddyfile` `docker-entrypoint.sh` 文件。

* Dockerfile

```Dockerfile
FROM alpine:latest as builder
ARG hugo_version="0.55.6"
ARG plugins="http.cache,http.cors,http.expires,http.realip,http.git"

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
    CADDY_GIT_HOOK_TYPE="github" \
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
```

* Caddyfile

Caddy 的配置文件支持变量，所以通过环境变量来配置主要的 Caddyfile，然后使用 import 的方式导入其他配置。

注意：Caddyfile 中变量语法为 `{$ENV_VAR}`。

```Caddyfile
{$CADDY_DOMAIN} {
    log {$CADDY_LOG_ROOT}/{$CADDY_DOMAIN}/access.log
    root {$CADDY_WWW_ROOT}/{$CADDY_DOMAIN}
    gzip
    tls {$CADDY_TLS_EMAIL}
    git {
        repo {$CADDY_GIT_REPO}
        branch {$CADDY_GIT_BRANCH}
        path {$CADDY_REPO_ROOT}/{$CADDY_DOMAIN}
        clone_args --depth=1
        hook {$CADDY_GIT_HOOK} {$CADDY_GIT_HOOK_SECRET}
        hook_type {$CADDY_GIT_HOOK_TYPE}
        then git submodule init
        then git submodule update
        then hugo --destination={$CADDY_WWW_ROOT}/{$CADDY_DOMAIN}
    }
}

import /root/caddy/etc/*.Caddyfile
```

* docker-entrypoint.sh

CADDYPATH 默认 `${HOME}/.caddy` 路径，用于保存生成的证书资源文件。

```bash
#!/usr/bin/env sh
set -e

export CADDY_ROOT=/root/caddy
export CADDYPATH=${CADDY_ROOT}/assets
export CADDY_WWW_ROOT=${CADDY_ROOT}/www
export CADDY_LOG_ROOT=${CADDY_ROOT}/logs

mkdir -p ${CADDY_WWW_ROOT}/${CADDY_DOMAIN} ${CADDY_LOG_ROOT}/${CADDY_DOMAIN}

exec "$@"
```

### 编写编排文件

在项目根目录下创建 `docker-compose.yaml` 与 `.env` 文件，如果路径不同，编排文件中相关项目也需要变化。

* docker-compose.yaml

```yaml
version: "3.7"
services:
  caddy:
    build:
      context: docker
    restart: unless-stopped
    env_file: .env
    volumes:
      - type: bind
        source: ${CADDY_ROOT}
        target: /root/caddy
    networks: 
      - caddy-network
    ports:
      - target: 80
        published: 80
        protocol: tcp
        mode: host
      - target: 443
        published: 443
        protocol: tcp
        mode: host

networks: 
  caddy-network:
    name: caddy-network
```

* .env

在 .env 中还可以使用 `HUGO_TITLE` `HUGO_BASEURL` 变量对 Hugo 进行配置。

```shell
CADDY_ROOT=/local_caddy_root_path
CADDY_DOMAIN=blog.example.com
CADDY_TLS_EMAIL=admin@exmaple.com
CADDY_GIT_REPO=https://github.com/example/blog.git
CADDY_GIT_BRANCH=master
CADDY_GIT_HOOK=/webhook
CADDY_GIT_HOOK_SECRET=your_hook_secret
HUGO_TITLE=Your Hugo Title
HUGO_BASEURL=https://blog.example.com
```

## 其他

在 Github 上添加好 WebHook 之后就完成所有内容了，每当 Push 后都会自动更新博客。

根据需要可以调整 Caddyfile 的配置，如果还要安装其他 Caddy Plugin 可以在 docker-compose.yaml 中添加 build args 的方式定义 plugin，重新构建镜像。

```yaml
version: "3.7"
services:
  caddy:
    build:
      context: docker
      args:
        plugins: "http.cache,http.cors,http.expires,http.realip,http.git"
        hugo_version: "0.55.6"
```

### External Network

如果除了博客之外还有其他服务也需要通过 Caddy 来代理，可以在编排文件中使用 External Network 的方式。

* docker-compose.yaml

```yaml
version: "3.7"
services:
 py4s:
  image: gitea/gitea:latest
  container_name: gitea
  restart: unless-stopped
  expose:
    - "3000"
  ports:
    - target: 22
      published: 10022
      protocol: tcp
      mode: host
  volumes:
    - ./gitea/data:/data
  networks:
    - caddy-network

networks:
  caddy-network:
    external: true
```

* gitea.Caddyfile

在本地 CADDY_ROOT 中添加 `etc/gitea.Caddyfile`。

```
py4s.example.com {
  proxy / gitea:3000
}
```