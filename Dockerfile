FROM nginx:alpine

ENV EDGE_REGION=Bilbao

COPY html/ /usr/share/nginx/html/
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template

RUN chmod -R a+rX /usr/share/nginx/html \
    && chmod a+r /etc/nginx/templates/default.conf.template

EXPOSE 80
