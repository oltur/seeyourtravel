# SeeYourTravel: ASP.NET Web Forms on Mono (XSP4) + SQL Server 2022, in Docker.
#   make up       build/create everything as needed, start it, wait until ready
#   make down     stop containers (data kept)
#   make restart  restart web (needed after editing files: Mono caches static file sizes)
#   make logs     follow web logs
#   make status   show containers and HTTP check
#   make clean    remove containers, network, DB volume and image (db/ source files are untouched)

PORT      ?= 8088
SA_PW     ?= CHANGE_ME
# app DB password: taken from web/Web.config (not committed; copy web/Web.config.example and set the password)
APP_PW    ?= $(shell sed -n 's/.*LOCAL.SEEYOURTRAVEL.com;.*Password=\([^;"&]*\).*/\1/p' web/Web.config | head -1)
SQL_IMAGE ?= mcr.microsoft.com/mssql/server:2022-latest
SQLCMD     = docker exec syt-sql /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P '$(SA_PW)'

.PHONY: up down restart logs status clean network image db-volume sql web wait-sql attach-db

up: network image sql attach-db web
	@echo "SeeYourTravel is running: http://localhost:$(PORT)/"

network:
	@docker network inspect syt >/dev/null 2>&1 || docker network create syt >/dev/null

image:
	@docker image inspect syt-web >/dev/null 2>&1 || docker build -t syt-web -f Dockerfile.web .

db-volume:
	@docker volume inspect sytdb >/dev/null 2>&1 || { \
	  docker volume create sytdb >/dev/null && \
	  docker run --rm -v sytdb:/var/opt/mssql/data -v "$(CURDIR)/db:/src:ro" --user root $(SQL_IMAGE) \
	    bash -c 'cp /src/seeyourtravel.mdf /src/seeyourtravel_log.ldf /var/opt/mssql/data/ && chown -R mssql /var/opt/mssql/data'; }

sql: network db-volume
	@if docker inspect syt-sql >/dev/null 2>&1; then docker start syt-sql >/dev/null; else \
	  docker run -d --name syt-sql --network syt --network-alias LOCAL.SEEYOURTRAVEL.com \
	    -e ACCEPT_EULA=Y -e 'MSSQL_SA_PASSWORD=$(SA_PW)' -v sytdb:/var/opt/mssql/data $(SQL_IMAGE) >/dev/null; fi
	@$(MAKE) --no-print-directory wait-sql

wait-sql:
	@echo -n "Waiting for SQL Server"; \
	for i in $$(seq 1 60); do $(SQLCMD) -Q "select 1" >/dev/null 2>&1 && { echo " ok"; exit 0; }; echo -n .; sleep 2; done; \
	echo " timed out"; exit 1

# Attach the DB and create the app login on first run only.
attach-db:
	@if [ -z "$$($(SQLCMD) -h -1 -W -Q "set nocount on; select name from sys.databases where name='SeeYourTravel'" | tr -d '\r\n ')" ]; then \
	  echo "Attaching SeeYourTravel database"; \
	  $(SQLCMD) -Q "CREATE DATABASE SeeYourTravel ON (FILENAME='/var/opt/mssql/data/seeyourtravel.mdf'),(FILENAME='/var/opt/mssql/data/seeyourtravel_log.ldf') FOR ATTACH"; \
	fi
	@$(SQLCMD) -Q "IF SUSER_ID('SeeYourTravel') IS NULL CREATE LOGIN SeeYourTravel WITH PASSWORD='$(APP_PW)', CHECK_POLICY=OFF; ALTER AUTHORIZATION ON DATABASE::SeeYourTravel TO SeeYourTravel;" >/dev/null

web: network image
	@if docker inspect syt-web >/dev/null 2>&1; then docker start syt-web >/dev/null; else \
	  docker run -d --name syt-web --network syt -p $(PORT):8080 -v "$(CURDIR)/web:/app" syt-web >/dev/null; fi
	@echo -n "Waiting for web"; \
	for i in $$(seq 1 30); do [ "$$(curl -s -o /dev/null -w '%{http_code}' http://localhost:$(PORT)/index.aspx)" = 200 ] && { echo " ok"; exit 0; }; echo -n .; sleep 2; done; \
	echo " timed out (see: make logs)"; exit 1

down:
	-docker stop syt-web syt-sql

restart:
	docker restart syt-web

logs:
	docker logs -f --tail 50 syt-web

status:
	@docker ps -a --filter name=syt- --format '{{.Names}}\t{{.Status}}\t{{.Ports}}'
	@curl -s -o /dev/null -w 'HTTP %{http_code}\n' http://localhost:$(PORT)/index.aspx || true

clean:
	-docker rm -f syt-web syt-sql
	-docker network rm syt
	-docker volume rm sytdb
	-docker rmi syt-web
