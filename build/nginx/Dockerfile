FROM nginx:alpine

# 1. 리버스 프록시 설정 파일 복사
COPY default.conf /etc/nginx/conf.d/default.conf

# 2. 정적 웹 파일(index.html, default.css, default.js) 복사
COPY html /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]