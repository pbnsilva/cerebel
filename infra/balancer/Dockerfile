FROM nginx:1.11-alpine
ADD snippets /etc/nginx/snippets
ADD gzip.conf /etc/nginx/conf.d/
ADD default.conf /etc/nginx/conf.d/
ADD .well-known /var/www/.well-known
