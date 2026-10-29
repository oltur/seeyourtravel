#!/usr/bin/env python3
"""Add the Google Photos Takeout photos (GPS only, already resized and checked in /home/ot/work-gp) to the site.

Input (made by the scripts in /home/ot/work-gp):
  cand_ids.json     every candidate: group (A = my takeout, B = Olena's), owner, path, taken, lat, lng, people (names Google found)
  final_ids.json    candidates that are not on the site yet and not duplicates
  det_gp_*.jsonl    person detection (maxc = highest confidence)
  ocr_gp.jsonl, mid_stats.json   document detection (>= 40 words, or 20-39 words on pale low-colour pictures: left out)
  stage/out/<id>.jpg   the resized pictures

Owner: group A -> administrator, group B -> Friend Name (friend@example.org).
IsPublic = 0 when a person was found, Google named a person, or detection failed.
A log (guid, source, status) goes to legacy/takeout-import-<date>/manifest.tsv.

Usage: python3 tools/takeout_import.py [--dry-run]
"""
import os, sys, json, glob, uuid, shutil, argparse, datetime, subprocess

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
W = '/home/ot/work-gp/'
DEST = os.path.join(REPO, 'web', 'data', 'images')
OWNERS = {'admin': 'C9F148F7-923A-46B0-8B7C-BD4B54D90886', 'helen': '3D70C1C0-E191-4837-9FA7-3398C928EFAF'}
PERSON = 0.25


def sql_str(s):
    return "N'" + s.replace("'", "''") + "'"


def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--dry-run', action='store_true'); a = ap.parse_args()
    cand = {c['id']: c for c in json.load(open(W + 'cand_ids.json'))}
    det = {}
    for f in glob.glob(W + 'det_gp_*.jsonl'):
        for l in open(f):
            r = json.loads(l); det[r['id']] = r
    ocr = {}
    for l in open(W + 'ocr_gp.jsonl'):
        r = json.loads(l); ocr[r['f'][:-4]] = r
    mid = json.load(open(W + 'mid_stats.json'))
    items, skipped = [], 0
    for id in json.load(open(W + 'final_ids.json')):
        c, d, o = cand[id], det.get(id), ocr.get(id, {})
        if d is None or not os.path.exists(W + 'stage/out/%s.jpg' % id):
            skipped += 1; continue
        words = o.get('w', 0)
        m = mid.get(id + '.jpg')
        if words >= 40 or (20 <= words < 40 and m and m[0] > 150 and m[1] < 45):
            skipped += 1; continue                          # a document, not a place
        private = 'err' in d or d.get('maxc', 1) >= PERSON or bool(c['people'])
        items.append((uuid.uuid4(), id, c, private))
    print('photos:', len(items), 'left out (documents, missing):', skipped, 'private:', sum(1 for x in items if x[3]), 'public:', sum(1 for x in items if not x[3]))
    for g in ('admin', 'helen'):
        print(' owner', g, sum(1 for x in items if x[2]['owner'] == g))
    if a.dry_run:
        return
    out = os.path.join(REPO, 'legacy', 'takeout-import-' + datetime.date.today().isoformat())
    os.makedirs(out, exist_ok=True); os.makedirs(DEST, exist_ok=True)
    with open(os.path.join(out, 'manifest.tsv'), 'w', encoding='utf-8') as f:
        for g, id, c, p in items:
            shutil.copyfile(W + 'stage/out/%s.jpg' % id, os.path.join(DEST, '%s.jpg' % g))
            f.write('\t'.join([str(g) + '.jpg', c['g'], c['path'], 'private' if p else 'public']) + '\n')
    lines = ['SET NOCOUNT ON;', 'SET QUOTED_IDENTIFIER ON;', 'BEGIN TRAN;']
    for k in range(0, len(items), 500):
        vi, vu = [], []
        for g, id, c, p in items[k:k + 500]:
            gid = str(g).upper()
            when = datetime.datetime.utcfromtimestamp(c['taken']).strftime('%Y-%m-%d %H:%M:%S') if c['taken'] > 0 else datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            vi.append("('%s',N'%s.jpg',%d,%r,%r,%s,'%s')" % (gid, str(g), 0 if p else 1, c['lat'], c['lng'], sql_str(os.path.basename(c['path'])), when))
            vu.append("(NEWID(),'%s','%s')" % (gid, OWNERS[c['owner']]))
        lines.append('INSERT INTO Image(ImageID,FileName,IsPublic,Lat,Lng,Description,Created) VALUES')
        lines.append(',\n'.join(vi) + ';')
        lines.append('INSERT INTO ImageUser(ImageUserID,ImageID,UserID) VALUES')
        lines.append(',\n'.join(vu) + ';')
    lines.append('COMMIT;')
    sqlp = os.path.join(out, 'insert.sql')
    open(sqlp, 'w', encoding='utf-8').write('\n'.join(lines))
    r = subprocess.run(['docker', 'exec', '-i', 'syt-sql', '/opt/mssql-tools18/bin/sqlcmd', '-C', '-I', '-S', 'localhost', '-U', 'sa',
                        '-P', 'CHANGE_ME', '-d', 'SeeYourTravel', '-b'], input=open(sqlp, 'rb').read(), capture_output=True)
    print('sql exit', r.returncode, r.stdout.decode()[-300:], r.stderr.decode()[-300:])
    if r.returncode != 0:
        sys.exit(1)
    print('inserted', len(items), 'rows; log in', out)


if __name__ == '__main__':
    main()
