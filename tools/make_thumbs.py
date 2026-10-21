#!/usr/bin/env python3
"""Pre-generate web copies of every photo in web/data/images:
     web/data/thumbs/480/<name>.jpg   long side 480 px  (strip, cards, pins, hover preview)
     web/data/thumbs/1600/<name>.jpg  long side 1600 px (photo viewer)
Aspect ratio kept, camera rotation applied, EXIF/GPS removed. Existing up-to-date files are skipped.
Usage: python3 tools/make_thumbs.py [-j N]
"""
import os, sys, argparse
from multiprocessing import Pool
from PIL import Image, ImageOps, ImageFile
ImageFile.LOAD_TRUNCATED_IMAGES = True   # a few originals are cut off: use what is there

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'web', 'data')
SRC = os.path.join(ROOT, 'images')
OUT = os.path.join(ROOT, 'thumbs')
SIZES = {480: 80, 1600: 82}   # long side -> JPEG quality
Image.MAX_IMAGE_PIXELS = None

def work(name):
    src = os.path.join(SRC, name)
    base = os.path.splitext(name)[0]
    todo = {s: os.path.join(OUT, str(s), base + '.jpg') for s in SIZES}
    smtime = os.path.getmtime(src)
    todo = {s: p for s, p in todo.items() if not (os.path.exists(p) and os.path.getmtime(p) >= smtime)}
    if not todo:
        return ('skip', name)
    try:
        im = Image.open(src)
        im.draft('RGB', (max(todo) * 2, max(todo) * 2))      # fast decode at reduced size
        im = ImageOps.exif_transpose(im).convert('RGB')
        for s in sorted(todo, reverse=True):
            c = im.copy(); c.thumbnail((s, s), Image.LANCZOS)
            tmp = todo[s] + '.tmp'
            c.save(tmp, 'JPEG', quality=SIZES[s], optimize=True, progressive=True)   # no EXIF is written
            os.replace(tmp, todo[s])
        return ('ok', name)
    except Exception as e:
        return ('fail', '%s: %s' % (name, e))

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('-j', type=int, default=max(1, (os.cpu_count() or 2) - 1)); a = ap.parse_args()
    for s in SIZES: os.makedirs(os.path.join(OUT, str(s)), exist_ok=True)
    names = sorted(n for n in os.listdir(SRC) if n.lower().endswith(('.jpg', '.jpeg', '.png')))
    counts = {'ok': 0, 'skip': 0, 'fail': 0}
    with Pool(a.j) as p:
        for i, (st, msg) in enumerate(p.imap_unordered(work, names, chunksize=8), 1):
            counts[st] += 1
            if st == 'fail': print('FAILED', msg, file=sys.stderr)
            if i % 250 == 0: print('%d/%d %s' % (i, len(names), counts), flush=True)
    print('done', counts)

if __name__ == '__main__':
    main()
