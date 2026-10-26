#!/usr/bin/env python3
"""Add photos from the library backup to the site (photos with GPS only).

Input (made by the scan scripts in /home/ot/work-pe):
  to_add.json     the photos to add: path inside the library, lat, lng, EXIF date ...
  det_new.jsonl   person detection per photo (same order as to_add.json); maxc = highest person confidence

For every photo:
  * a resized copy (2048 px, tags kept) is written to web/data/images/<guid>.jpg
  * an Image + ImageUser row is written (owner = the administrator)
  * IsPublic = 0 when a person was found (or detection failed), 1 otherwise
A tab separated log of what came from where is written to legacy/library-import-<date>/manifest.tsv.

Usage: python3 tools/library_import.py [--limit N] [--dry-run]
"""
import os, sys, json, uuid, argparse, datetime, subprocess
from multiprocessing import Pool
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from library_resize import resize_keep_tags

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
LIB = '/run/media/ot/oldssd/home/ot/Library-backup/'
WORK = '/home/ot/work-pe/'
DEST = os.path.join(REPO, 'web', 'data', 'images')
OWNER = 'C9F148F7-923A-46B0-8B7C-BD4B54D90886'     # administrator
PERSON = 0.25                                      # confidence from which a photo counts as "with people"


def one(a):
    guid, src = a
    dst = os.path.join(DEST, guid + '.jpg')
    try:
        w, h = resize_keep_tags(LIB + src, dst)
        return guid, (w, h, os.path.getsize(dst))
    except Exception as e:
        return guid, str(e)[:100]


def sql_str(s):
    return "N'" + s.replace("'", "''") + "'"


def created(c):
    d = c.get('dt')
    try:
        return datetime.datetime.strptime(d[:19], '%Y:%m:%d %H:%M:%S').strftime('%Y-%m-%d %H:%M:%S')
    except Exception:
        return datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--limit', type=int)
    ap.add_argument('--dry-run', action='store_true')
    ap.add_argument('--sql-only', action='store_true', help='files are already resized: rebuild the rows from the manifest')
    a = ap.parse_args()

    cand = json.load(open(WORK + 'to_add.json'))
    det = {}
    for l in open(WORK + 'det_new.jsonl', encoding='utf-8'):
        r = json.loads(l)
        det[r['i']] = r
    items = []
    for i, c in enumerate(cand):
        d = det.get(i)
        if d is None:
            continue                                     # not scanned: leave it out rather than guess
        private = 'err' in d or d.get('maxc', 1) >= PERSON
        items.append((uuid.uuid4(), c, private))
        if a.limit and len(items) >= a.limit:
            break
    print('photos:', len(items), 'private (people):', sum(1 for x in items if x[2]), 'public:', sum(1 for x in items if not x[2]))
    if a.dry_run:
        return

    out = os.path.join(REPO, 'legacy', 'library-import-' + datetime.date.today().isoformat())
    os.makedirs(out, exist_ok=True)
    if a.sql_only:
        byp = {c['p']: (c, p) for _, c, p in items}
        ok = []
        for l in open(os.path.join(out, 'manifest.tsv'), encoding='utf-8'):
            fn, path, h, st = l.rstrip('\n').split('\t')
            if path in byp and os.path.exists(os.path.join(DEST, fn)):
                ok.append((uuid.UUID(fn[:-4]), byp[path][0], byp[path][1]))
        print('rebuilt from manifest:', len(ok))
    else:
        os.makedirs(DEST, exist_ok=True)
        with Pool(14) as pool:
            res = dict(pool.imap_unordered(one, [(str(g), c['p']) for g, c, _ in items], chunksize=4))
        ok = [(g, c, p) for g, c, p in items if not isinstance(res[str(g)], str)]
        bad = [(g, c) for g, c, p in items if isinstance(res[str(g)], str)]
        print('resized:', len(ok), 'failed:', len(bad))
        for g, c in bad[:10]:
            print('  failed', c['p'], res[str(g)])
        with open(os.path.join(out, 'manifest.tsv'), 'w', encoding='utf-8') as f:
            for g, c, p in ok:
                f.write('\t'.join([str(g) + '.jpg', c['p'], c['h'], 'private' if p else 'public']) + '\n')

    lines = ['SET NOCOUNT ON;', 'SET QUOTED_IDENTIFIER ON;', 'BEGIN TRAN;']
    for k in range(0, len(ok), 500):
        part = ok[k:k + 500]
        vals_i, vals_u = [], []
        for g, c, p in part:
            gid = str(g).upper()
            base = os.path.basename(c['p'])
            vals_i.append("('%s',N'%s.jpg',%d,%r,%r,%s,'%s')" % (gid, str(g), 0 if p else 1, c['lat'], c['lng'], sql_str(base), created(c)))
            vals_u.append("(NEWID(),'%s','%s')" % (gid, OWNER))
        # one row per line: sqlcmd cannot take very long lines
        lines.append('INSERT INTO Image(ImageID,FileName,IsPublic,Lat,Lng,Description,Created) VALUES')
        lines.append(',\n'.join(vals_i) + ';')
        lines.append('INSERT INTO ImageUser(ImageUserID,ImageID,UserID) VALUES')
        lines.append(',\n'.join(vals_u) + ';')
    lines.append('COMMIT;')
    sqlp = os.path.join(out, 'insert.sql')
    open(sqlp, 'w', encoding='utf-8').write('\n'.join(lines))
    r = subprocess.run(['docker', 'exec', '-i', 'syt-sql', '/opt/mssql-tools18/bin/sqlcmd', '-C', '-I', '-S', 'localhost', '-U', 'sa',
                        '-P', 'CHANGE_ME', '-d', 'SeeYourTravel', '-b'], input=open(sqlp, 'rb').read(), capture_output=True)
    print('sql exit', r.returncode, r.stdout.decode()[-300:], r.stderr.decode()[-300:])
    if r.returncode != 0:
        sys.exit(1)
    print('inserted', len(ok), 'rows; log in', out)


if __name__ == '__main__':
    main()
