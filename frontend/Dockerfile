FROM nginx:stable-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY dist/frontend/browser/ /usr/share/nginx/html/
EXPOSE 80
