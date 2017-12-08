#! /bin/sh

export HEXO_WWW_PATH=/data/hexo

if [ -z "$(docker --version)" ]; then
    echo "Docker not installed."
    exit 1
fi

if [ ${HEXO_WWW_PATH} ] && [ -d ${HEXO_WWW_PATH} ]; then
    docker run --rm -v $(pwd):/blog -v \
    $(pwd)/hexo_config.yml:/hexo/_config.yml \
    -v $(pwd)/theme_next_config.yml:/hexo/themes/next/_config.yml \
    -v ${HEXO_WWW_PATH}:/wwwroot \
    hexo
else
    echo "HEXO_WWW_PATH not set or not exist."
    exit 1
fi
