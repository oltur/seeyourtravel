#!/usr/bin/env python3
"""Adds the photos that are not in the search index yet. One 512-number vector per photo, made from the 480 px copy.
Usage (inside the syt-clip image): python index.py <thumbs dir> <index dir> [batch]
Writes <index dir>/names.txt (one file name without extension per line) and vectors.npy (float16, one unit-length row per name)."""
import os, sys, time
import numpy as np
from PIL import Image, ImageFile
from sentence_transformers import SentenceTransformer
ImageFile.LOAD_TRUNCATED_IMAGES = True

thumbs, out = sys.argv[1], sys.argv[2]
batch = int(sys.argv[3]) if len(sys.argv) > 3 else 64
nf, vf = os.path.join(out, 'names.txt'), os.path.join(out, 'vectors.npy')
have = [l.strip() for l in open(nf, encoding='utf-8')] if os.path.exists(nf) else []
vec = np.load(vf) if have and os.path.exists(vf) else np.zeros((0, 512), np.float16)
if len(have) != len(vec):
    have, vec = [], np.zeros((0, 512), np.float16)
present = {f[:-4] for f in os.listdir(thumbs) if f.lower().endswith('.jpg')}
keep = [i for i, n in enumerate(have) if n in present]          # photos deleted from the site leave the index
have, vec = [have[i] for i in keep], vec[keep]
known = set(have)
todo = sorted(present - known)
print('indexed', len(have), 'new', len(todo), flush=True)
if not todo:
    sys.exit(0)
model = SentenceTransformer('clip-ViT-B-32')
new_names, new_vecs, t0 = [], [], time.time()

def load(n):
    try:
        im = Image.open(os.path.join(thumbs, n + '.jpg')); im.load(); return im.convert('RGB')
    except Exception:
        return None

def save():
    names = have + new_names
    v = np.concatenate([vec] + new_vecs) if new_vecs else vec
    os.makedirs(out, exist_ok=True)
    np.save(vf + '.tmp.npy', v.astype(np.float16)); os.replace(vf + '.tmp.npy', vf)
    open(nf + '.tmp', 'w', encoding='utf-8').write('\n'.join(names) + '\n'); os.replace(nf + '.tmp', nf)

for k in range(0, len(todo), batch):
    chunk = todo[k:k + batch]; ims = [(n, load(n)) for n in chunk]; ims = [(n, im) for n, im in ims if im is not None]
    if ims:
        e = model.encode([im for _, im in ims], batch_size=batch, convert_to_numpy=True, normalize_embeddings=True)
        new_names += [n for n, _ in ims]; new_vecs.append(e.astype(np.float16))
    if (k // batch) % 20 == 19:
        save(); print(k + len(chunk), '/', len(todo), round((k + len(chunk)) / (time.time() - t0), 1), 'img/s', flush=True)
save(); print('done', len(have) + len(new_names), flush=True)
