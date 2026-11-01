#!/bin/bash
# Finds the faces in photos the scan has not seen yet and adds them (and the people they belong to) to the database.
#   tools/faces_scan.sh            new photos only
# Needs the syt-face image (docker build -t syt-face tools/faces/) and the SQL Server container syt-sql.
# The scan is slow (about 5 photos a second) and uses about 3 GB of memory: Docker Desktop's VM is small, so WORKERS stays low.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
set -a; . "$REPO/.env"; set +a
# whatever happens below (also when there are no new faces), the photo search index is brought up to date at the end; its failure does not fail this scan
trap '"$REPO/tools/clip_scan.sh" || echo "clip scan failed"' EXIT
W="${FACES_WORK:-$HOME/work-faces}"; WORKERS="${WORKERS:-5}"
mkdir -p "$W" "$W/models"
SQL=(docker exec syt-sql /opt/mssql-tools18/bin/sqlcmd -C -I -S localhost -U sa -P "$SYT_SA_PASSWORD" -d SeeYourTravel -h -1 -W)
"${SQL[@]}" -Q "SET NOCOUNT ON; SELECT LOWER(FileName)+CHAR(9)+CAST(ImageID AS varchar(36)) FROM Image" | tr -d '\r' > "$W/images.tsv"
"${SQL[@]}" -Q "SET NOCOUNT ON; SELECT CAST(ImageID AS varchar(36)) FROM FaceScan" | tr -d '\r' > "$W/existing.tsv"
"${SQL[@]}" -w 8000 -Q "SET NOCOUNT ON; SELECT CAST(PersonID AS varchar(36))+CHAR(9)+CONVERT(varchar(2100),Embedding,2) FROM Face WHERE PersonID IS NOT NULL AND Embedding IS NOT NULL" | tr -d "\r" > "$W/people.tsv"
python3 - "$W" <<'P'
import sys
w = sys.argv[1]
done = {l.strip().upper() for l in open(w + '/existing.tsv') if l.strip()}
rows = [l.split('\t') for l in open(w + '/images.tsv') if '\t' in l]
open(w + '/todo.txt', 'w').write(''.join(r[0] + '\n' for r in rows if r[1].strip().upper() not in done))
P
N=$(wc -l < "$W/todo.txt"); echo "photos to scan: $N"; [ "$N" -gt 0 ] || exit 0
rm -f "$W/faces_new.jsonl"
docker run --rm --cpus 6 --memory 3000m -v "$W":/w -v "$W/models":/root/.insightface -v "$REPO/web/data/thumbs":/thumbs:ro -v "$REPO/tools":/t:ro -w /w syt-face python /t/faces/scan.py todo.txt faces_new.jsonl "$WORKERS" | grep -v Warn | tail -1
rm -rf "$W/out"
docker run --rm -v "$W":/w -v "$REPO/tools":/t:ro -w /w syt-face python /t/faces_import.py images.tsv faces_new.jsonl out --existing existing.tsv --people people.tsv
docker exec syt-sql rm -rf /tmp/faces_out 2>/dev/null || true
docker cp "$W/out" syt-sql:/tmp/faces_out
for f in $(cd "$W/out" && ls *.sql | sort); do "${SQL[@]}" -b -i "/tmp/faces_out/$f" > /dev/null; done
docker exec -u 0 syt-sql rm -rf /tmp/faces_out
echo "faces added"
