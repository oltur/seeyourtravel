# SeeYourTravel: ASP.NET Web Forms on Mono (XSP4) + SQL Server 2022, in Docker.
#   make up       build/create everything as needed, start it, wait until ready
#   make down     stop containers (data kept)
#   make restart  restart web (needed after editing files: Mono caches static file sizes)
#   make logs     follow web logs
#   make status   show containers and HTTP check
#   make clean    remove containers, network, DB volume and image (db/ source files are untouched)
#   make thumbs   (re)generate the web copies of all photos in web/data/thumbs (new uploads get theirs automatically)
#   make tunnel   start the Cloudflare tunnel (needs CF_TUNNEL_TOKEN in .env; `make up` starts it automatically when set)
#   make tunnel-logs / tunnel-down

-include .env
export

PORT      ?= 8088
CLOUDFLARED_IMAGE ?= cloudflare/cloudflared:latest
# SQL Server sa password: SYT_SA_PASSWORD from .env
SA_PW     ?= $(SYT_SA_PASSWORD)
# app DB password: taken from web/Web.config (not committed; copy web/Web.config.example and set the password)
APP_PW    ?= $(shell sed -n 's/.*LOCAL.SEEYOURTRAVEL.com;.*Password=\([^;"&]*\).*/\1/p' web/Web.config | head -1)
SQL_IMAGE ?= mcr.microsoft.com/mssql/server:2022-latest
SQLCMD     = docker exec syt-sql /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P '$(SA_PW)'


.PHONY: thumbs up down restart logs status clean network image db-volume sql web wait-sql attach-db tunnel tunnel-logs tunnel-down

up: network image sql attach-db web
	@if [ -n "$(CF_TUNNEL_TOKEN)" ]; then $(MAKE) --no-print-directory tunnel; else echo "(no CF_TUNNEL_TOKEN in .env: not published to the internet)"; fi
	@echo "SeeYourTravel is running: http://localhost:$(PORT)/"

network:
	@docker network inspect syt >/dev/null 2>&1 || docker network create syt >/dev/null

image:
	@docker image inspect syt-web >/dev/null 2>&1 || docker compose build web

db-volume:
	@docker volume inspect sytdb >/dev/null 2>&1 || { \
	  docker volume create sytdb >/dev/null && \
	  docker run --rm -v sytdb:/var/opt/mssql/data -v "$(CURDIR)/db:/src:ro" --user root $(SQL_IMAGE) \
	    bash -c 'cp /src/seeyourtravel.mdf /src/seeyourtravel_log.ldf /var/opt/mssql/data/ && chown -R mssql /var/opt/mssql/data'; }

sql: network db-volume
	@docker compose up -d sql
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
	@docker compose up -d web
	@echo -n "Waiting for web"; \
	for i in $$(seq 1 30); do [ "$$(curl -s -o /dev/null -w '%{http_code}' http://localhost:$(PORT)/index.aspx)" = 200 ] && { echo " ok"; exit 0; }; echo -n .; sleep 2; done; \
	echo " timed out (see: make logs)"; exit 1

# Cloudflare terminates HTTPS and talks to the app over the private docker network: no ports are opened to the internet.
# In Cloudflare Zero Trust: Tunnels -> your tunnel -> Public hostname: seeyourtravel.app -> Service HTTP -> syt-web:8080
tunnel: network
	@[ -n "$(CF_TUNNEL_TOKEN)" ] || { echo "Set CF_TUNNEL_TOKEN in .env (see .env.example)"; exit 1; }
	@docker rm -f syt-tunnel >/dev/null 2>&1 || true
	@docker run -d --name syt-tunnel --network syt --restart unless-stopped $(CLOUDFLARED_IMAGE) \
	  tunnel --no-autoupdate run --token "$(CF_TUNNEL_TOKEN)" >/dev/null
	@echo "Cloudflare tunnel started (make tunnel-logs to check)"

tunnel-logs:
	docker logs -f --tail 30 syt-tunnel

tunnel-down:
	-docker rm -f syt-tunnel

thumbs:
	python3 tools/make_thumbs.py

down:
	-docker compose stop
	-docker stop syt-tunnel

restart:
	docker compose restart web

logs:
	docker logs -f --tail 50 syt-web

status:
	@docker ps -a --filter name=syt- --format '{{.Names}}\t{{.Status}}\t{{.Ports}}'
	@curl -s -o /dev/null -w 'HTTP %{http_code}\n' http://localhost:$(PORT)/index.aspx || true

clean:
	-docker rm -f syt-web syt-sql syt-tunnel
	-docker network rm syt
	-docker volume rm sytdb
	-docker rmi syt-web
