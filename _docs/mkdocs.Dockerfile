FROM  python:3.10-alpine

RUN apk add --no-cache build-base \
                       libffi-dev \
                       py3-pip \
                       py3-cffi \
                       py3-brotli \
                       gcc \
                       musl-dev \
                       python3-dev \
                       pango \
                       zlib-dev \
                       jpeg-dev \
                       libjpeg-turbo-dev
RUN pip3 install WeasyPrint==52.5
RUN pip3 install mkdocs \
                 mkdocs-with-pdf \
                 mkdocs-macros-plugin \
                 mkdocs-pdf-export-plugin \
                 mkdocs-material \
                 mkdocs-print-site-plugin \
                 html5lib \
                 requests \
                 htmlark \
                 jinja2 \
                 python-hcl2 pyyaml \
                 jsonschema
RUN apk add --no-cache chromium --repository=http://dl-cdn.alpinelinux.org/alpine/v3.14/main
