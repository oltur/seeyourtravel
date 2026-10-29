#!/bin/bash
# Backup of the SeeYourTravel database to db/backups (the last 14 are kept), verified after writing.
# The SQL Server password is read from .env (SYT_SA_PASSWORD, git-ignored).
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
set -a; . "$REPO/.env"; set +a
DIR="$REPO/db/backups"; KEEP=14
mkdir -p "$DIR"
NAME="SeeYourTravel-$(date +%Y%m%d-%H%M).bak"
SQL=(docker exec syt-sql /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P "$SYT_SA_PASSWORD" -b)
docker exec syt-sql mkdir -p /var/opt/mssql/backup
"${SQL[@]}" -Q "BACKUP DATABASE SeeYourTravel TO DISK='/var/opt/mssql/backup/$NAME' WITH COMPRESSION, INIT, CHECKSUM" >/dev/null
"${SQL[@]}" -Q "RESTORE VERIFYONLY FROM DISK='/var/opt/mssql/backup/$NAME' WITH CHECKSUM" >/dev/null
docker cp "syt-sql:/var/opt/mssql/backup/$NAME" "$DIR/$NAME"
docker exec syt-sql rm -f "/var/opt/mssql/backup/$NAME"
ls -1t "$DIR"/SeeYourTravel-2*.bak 2>/dev/null | tail -n +$((KEEP + 1)) | xargs -r rm -f
echo "backup ok: $NAME ($(du -h "$DIR/$NAME" | cut -f1)), $(ls -1 "$DIR"/SeeYourTravel-2*.bak | wc -l) kept"
