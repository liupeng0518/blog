#! /bin/sh
export HEXO_WWW_PATH=/data/hexo
docker run --rm -v $(pwd):/blog -v $(pwd)/hexo_config.yml:/hexo/_configy.yml -v $(pwd)/theme_next_config.yml:/hexo/themes/next/_config.yml -v ${HEXO_WWW_PATH}:/wwwroot hexo