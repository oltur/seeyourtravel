#!/usr/bin/env python3
"""
Face import: turns the scan result (faces.jsonl from the syt-face scan) into rows for the Face and Person tables (db/faces.sql).
Runs inside the syt-face image (numpy). Two steps, so nothing here needs a database driver:
  1. on the host:  list the photos     sqlcmd ... "SELECT LOWER(FileName)+CHAR(9)+CAST(ImageID AS varchar(36)) FROM Image" > images.tsv
  2. in the image: python3 faces_import.py images.tsv faces.jsonl OUTDIR [--existing existing.tsv]
     writes OUTDIR/NN.sql (batches; run them with sqlcmd -I)
Photos that were scanned before are skipped (existing.tsv: the ImageIDs in table FaceScan, one per line), so the script can be run again for new photos.
Faces are grouped into people by comparing the 512-d embeddings (cosine similarity): a leader pass, then re-assigning to the nearest group and merging groups that are nearly the same person.
Groups of fewer than 3 faces stay unnamed and ungrouped - they can be assigned by hand in My photos > People.
"""
import sys, os, json, base64, uuid
import numpy as np

ASSIGN, MERGE, MIN_GROUP = 0.42, 0.62, 3
MIN_SIZE, MIN_SCORE = 0.025, 0.6        # smaller / unsure faces are stored but not grouped automatically


def main():
    images_tsv, scan, outdir = sys.argv[1:4]
    existing = set()
    if '--existing' in sys.argv:
        existing = {l.strip().upper() for l in open(sys.argv[sys.argv.index('--existing') + 1]) if l.strip()}   # photos already scanned (table FaceScan)
    ids = {}
    for l in open(images_tsv):
        p = l.strip().split('\t')
        if len(p) == 2: ids[p[0]] = p[1].upper()
    scanned = []   # every photo of this scan, with or without faces
    faces = []   # (face guid, image id, x, y, w, h, score, embedding)
    for l in open(scan):
        r = json.loads(l)
        if 'faces' not in r: continue
        iid = ids.get(r['f'].lower().replace('.jpg', '') + '.jpg')
        if not iid or iid in existing: continue
        scanned.append(iid)
        for f in r['faces']:
            e = np.frombuffer(base64.b64decode(f['e']), dtype=np.float16).astype(np.float32)
            faces.append((str(uuid.uuid4()).upper(), iid, f['x'], f['y'], f['w'], f['h'], f['s'], e))
    print('photos scanned:', len(scanned), 'faces to import:', len(faces))
    os.makedirs(outdir, exist_ok=True)
    for b in range(0, len(scanned), 800):
        open(os.path.join(outdir, '99_scanned_%03d.sql' % (b // 800)), 'w').write('SET NOCOUNT ON;\nINSERT INTO FaceScan(ImageID) VALUES\n' + ',\n'.join("('%s')" % i for i in scanned[b:b + 800]) + ';\n')
    if not faces: return
    E = np.stack([f[7] for f in faces]); E /= np.maximum(np.linalg.norm(E, axis=1, keepdims=True), 1e-6)
    size = np.array([max(f[4], f[5]) for f in faces]); score = np.array([f[6] for f in faces])
    good = np.where((size >= MIN_SIZE) & (score >= MIN_SCORE))[0]
    order = good[np.argsort(-(score[good] * size[good]))]          # best faces first: they seed the groups
    # people that already exist (persons.tsv: PersonID<TAB>embedding as hex, one line per face with a person): new faces join them first
    known = {}
    if '--people' in sys.argv:
        acc = {}
        for l in open(sys.argv[sys.argv.index('--people') + 1]):
            p = l.strip().split('\t')
            if len(p) == 2 and len(p[1]) == 2048:
                v = np.frombuffer(bytes.fromhex(p[1]), dtype=np.float16).astype(np.float32); acc.setdefault(p[0].upper(), []).append(v / max(np.linalg.norm(v), 1e-6))
        for k, v in acc.items():
            m = np.mean(v, axis=0); known[k] = m / np.linalg.norm(m)
    pre = np.full(len(faces), -1)
    kn_ids = list(known)
    if kn_ids:
        K = np.stack([known[k] for k in kn_ids]); sk = E[good] @ K.T
        hit = sk.max(1) >= ASSIGN + 0.03
        pre[good[hit]] = sk.argmax(1)[hit]
        print('faces added to existing people:', int(hit.sum()))
        order = np.array([i for i in order if pre[i] < 0], dtype=int)
    cent = []                                                       # unit vectors
    for i in order:
        if cent:
            s = np.stack(cent) @ E[i]; j = int(s.argmax())
            if s[j] >= ASSIGN:
                c = cent[j] * 0.9 + E[i] * 0.1; cent[j] = c / np.linalg.norm(c); continue
        cent.append(E[i].copy())
    rest = np.array([i for i in good if pre[i] < 0], dtype=int)
    for _ in range(3 if cent else 0):                               # re-assign everything, recompute, merge near-identical groups
        C = np.stack(cent); lab = np.full(len(faces), -1)
        sims = E[rest] @ C.T; best = sims.argmax(1); ok = sims.max(1) >= ASSIGN
        lab[rest[ok]] = best[ok]
        new = []
        for j in range(len(C)):
            m = E[lab == j]
            if len(m): c = m.mean(0); new.append(c / np.linalg.norm(c))
        cent = new
        C = np.stack(cent); S = C @ C.T; np.fill_diagonal(S, 0)
        keep = list(range(len(cent))); merged = {}
        for a in range(len(cent)):
            for b in range(a + 1, len(cent)):
                if S[a, b] >= MERGE and a in keep and b in keep: keep.remove(b); merged[b] = a
        cent = [cent[k] for k in keep]
    if not cent: cent = [np.zeros(E.shape[1], dtype=np.float32)]
    C = np.stack(cent); lab = np.full(len(faces), -1)
    sims = E[rest] @ C.T; best = sims.argmax(1); ok = sims.max(1) >= ASSIGN
    lab[rest[ok]] = best[ok]
    counts = np.bincount(lab[lab >= 0], minlength=len(cent))
    person = {j: str(uuid.uuid4()).upper() for j in range(len(cent)) if counts[j] >= MIN_GROUP}
    print('groups:', len(cent), 'people kept (>= %d faces):' % MIN_GROUP, len(person), 'faces grouped:', int(sum(counts[j] for j in person)))
    n = 0
    lines = ['SET NOCOUNT ON; SET QUOTED_IDENTIFIER ON;', 'INSERT INTO Person(PersonID, Name) VALUES']
    lines += [',\n'.join("('%s', NULL)" % p for p in person.values()) + ';'] if person else []
    if person:
        open(os.path.join(outdir, '00_persons.sql'), 'w').write('\n'.join(lines) + '\n')
    for b in range(0, len(faces), 400):
        rows = []
        for k in range(b, min(b + 400, len(faces))):
            f = faces[k]; j = int(lab[k])
            pid = ("'%s'" % person[j]) if j in person else ("'%s'" % kn_ids[pre[k]] if pre[k] >= 0 else 'NULL')
            rows.append("('%s','%s',%s,%.4f,%.4f,%.4f,%.4f,%.3f,0x%s)" % (f[0], f[1], pid, f[2], f[3], f[4], f[5], f[6], f[7].astype(np.float16).tobytes().hex()))
        n += 1
        open(os.path.join(outdir, '%02d_faces.sql' % n), 'w').write('SET NOCOUNT ON; SET QUOTED_IDENTIFIER ON;\nINSERT INTO Face(FaceID,ImageID,PersonID,X,Y,W,H,Score,Embedding) VALUES\n' + ',\n'.join(rows) + ';\n')
    print('wrote', n + (1 if person else 0), 'files to', outdir)


main()
