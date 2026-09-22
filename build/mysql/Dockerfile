FROM mysql:8.0

# 1. 커스텀 설정 파일 복사
COPY my.cnf /etc/mysql/conf.d/my.cnf

# 2. 컨테이너 최초 실행 시 자동 실행될 SQL 스크립트 복사
COPY init.sql /docker-entrypoint-initdb.d/init.sql

EXPOSE 3306