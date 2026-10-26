#!/usr/bin/env python3
"""Resize one photo for the site and keep its tags (EXIF incl. GPS and date, ICC profile).

The camera rotation is applied to the pixels and the Orientation tag is reset to 1, so the picture is not rotated twice.
Long side is limited to MAX (never enlarged). Returns (width, height) or raises.
"""
from PIL import Image, ImageOps, ImageFile
ImageFile.LOAD_TRUNCATED_IMAGES = True
Image.MAX_IMAGE_PIXELS = None
MAX = 2048
QUALITY = 85

def resize_keep_tags(src, dst, max_side=MAX, quality=QUALITY):
    im = Image.open(src)
    exif = im.getexif()
    icc = im.info.get('icc_profile')
    im.draft('RGB', (max_side * 2, max_side * 2))        # fast decode at reduced size
    im = ImageOps.exif_transpose(im).convert('RGB')
    if max(im.size) / max(1, min(im.size)) > 2.5:           # panoramas keep more pixels, otherwise they become strips
        max_side *= 2
    im.thumbnail((max_side, max_side), Image.LANCZOS)
    w, h = im.size
    exif[0x0112] = 1                                      # Orientation: already applied
    try:
        sub = exif.get_ifd(0x8769)                        # Exif sub-IFD: pixel dimensions
        sub[0xA002], sub[0xA003] = w, h
    except Exception:
        pass
    kw = {'quality': quality, 'optimize': True, 'exif': exif.tobytes()}
    if icc:
        kw['icc_profile'] = icc
    tmp = dst + '.tmp'
    im.save(tmp, 'JPEG', **kw)
    import os
    os.replace(tmp, dst)
    return w, h
