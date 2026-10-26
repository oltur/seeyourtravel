#!/usr/bin/env python3
"""Facts for writing a track's description: route numbers, places along it (OpenStreetMap), what Wikipedia says about them,
and freely licensed Wikimedia Commons pictures near it (as a numbered contact sheet to choose from).
  python3 tools/track_facts.py <track id or file name>  [--no-images]
Output: /tmp/claude-1000/facts/<id>.json (+ a contact sheet in /tmp/claude-1000/sheets)."""
import json, math, os, re, sys, time, urllib.parse, urllib.request
UA = {'User-Agent': 'seeyourtravel-curator/1.0 (info@seeyourtravel.app)'}
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'web')
CACHE = '/tmp/claude-1000/cache/net.json'
cache = json.load(open(CACHE)) if os.path.exists(CACHE) else {}
last = [0.0]

def get(url, pause=0.0):
    if url in cache: return cache[url]
    wait = pause - (time.time() - last[0])
    if wait > 0: time.sleep(wait)
    for attempt in range(3):
        try:
            data = json.load(urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=40))
            break
        except Exception as e:
            data = None; time.sleep(2)
    last[0] = time.time()
    if data is not None:
        cache[url] = data
        json.dump(cache, open(CACHE, 'w'))
    return data

def hav(a, b):
    q = math.pi / 180
    x = math.sin((b[0]-a[0])*q/2)**2 + math.cos(a[0]*q)*math.cos(b[0]*q)*math.sin((b[1]-a[1])*q/2)**2
    return 2*6371*math.asin(math.sqrt(x))

def load(tid):
    d = json.load(open(os.path.join(ROOT, 'tracks', tid + '.js'), encoding='utf-8-sig'))
    pts = [(p['lat'], p['lng']) if isinstance(p, dict) else (p[0], p[1]) for p in d.get('trackData', [])]
    if not pts and d.get('trackGpx'):   # a track kept as a GPX file
        x = open(os.path.join(ROOT, 'tracks', 'content', d['trackGpx']), encoding='utf-8', errors='replace').read()
        pts = [(float(a), float(b)) for a, b in re.findall(r'<trkpt[^>]*lat="([-\d.]+)"[^>]*lon="([-\d.]+)"', x)]
        pts = pts[::max(1, len(pts) // 1500)]
    return d, pts

def main():
    tid = sys.argv[1]; images = '--no-images' not in sys.argv
    d, pts = load(tid)
    if not pts:
        print('no points (GPX or empty)'); return
    cum = [0.0]
    for i in range(1, len(pts)): cum.append(cum[-1] + hav(pts[i-1], pts[i]))
    total = cum[-1]
    # elevations
    idx = list(range(0, len(pts), max(1, len(pts)//90)))
    if idx[-1] != len(pts)-1: idx.append(len(pts)-1)
    el = []
    for k in range(0, len(idx), 100):
        ch = idx[k:k+100]
        u = 'https://api.open-meteo.com/v1/elevation?latitude=%s&longitude=%s' % (','.join('%.5f' % pts[i][0] for i in ch), ','.join('%.5f' % pts[i][1] for i in ch))
        r = get(u); el += (r or {}).get('elevation', [None]*len(ch))
    ev = [(i, e) for i, e in zip(idx, el) if e is not None]
    up = down = 0
    for a, b in zip(ev, ev[1:]):
        dd = b[1] - a[1]
        if dd > 0: up += dd
        else: down -= dd
    # stops: start, end and up to 8 between
    n = 1 if total < 3 else (3 if total < 15 else (5 if total < 60 else (7 if total < 250 else 10)))
    stops = sorted({0, len(pts)-1} | {min(range(len(pts)), key=lambda j: abs(cum[j] - total*k/(n+1))) for k in range(1, n+1)})
    places = []
    for i in stops:
        la, ln = pts[i]
        r = get('https://nominatim.openstreetmap.org/reverse?format=json&zoom=%d&lat=%.5f&lon=%.5f&accept-language=en' % (14 if total < 15 else 10, la, ln), pause=1.1) or {}
        a = r.get('address', {})
        name = a.get('city') or a.get('town') or a.get('village') or a.get('municipality') or a.get('suburb') or a.get('hamlet') or a.get('county') or ''
        elev = min(ev, key=lambda e: abs(e[0]-i))[1] if ev else None
        # Wikipedia articles near the stop
        rad = 1500 if total < 3 else (5000 if total < 60 else 9000)
        w = get('https://en.wikipedia.org/w/api.php?' + urllib.parse.urlencode({'action': 'query', 'generator': 'geosearch', 'ggscoord': '%.5f|%.5f' % (la, ln), 'ggsradius': rad, 'ggslimit': 12,
              'prop': 'extracts|pageimages', 'exintro': 1, 'explaintext': 1, 'exsentences': 3, 'piprop': 'thumbnail', 'pithumbsize': 100, 'format': 'json'})) or {}
        arts = []
        for p in (w.get('query', {}).get('pages', {}) or {}).values():
            ex = (p.get('extract') or '').strip().replace('\n', ' ')
            if len(ex) > 60: arts.append({'title': p['title'], 'text': ex[:420], 'img': 'thumbnail' in p, 'score': len(ex) + (150 if 'thumbnail' in p else 0)})
        arts.sort(key=lambda x: -x['score'])
        places.append({'i': i, 'km': round(cum[i], 1), 'lat': la, 'lng': ln, 'place': name, 'region': a.get('state') or a.get('county') or '', 'country': a.get('country', ''), 'elev': elev, 'wiki': arts[:3]})
    out = {'id': tid, 'name': d.get('name'), 'travelWith': d.get('travelWith'), 'points': len(pts), 'km': round(total, 1),
           'max_elev': max(e for _, e in ev) if ev else None, 'min_elev': min(e for _, e in ev) if ev else None, 'ascent': round(up), 'descent': round(down),
           'places': places, 'candidates': []}
    if images:
        cands = {}
        queries = []
        for k, v in enumerate(sys.argv):
            if v == '--img' and k + 1 < len(sys.argv): queries = [q.strip() for q in sys.argv[k+1].split(',') if q.strip()]
        def collect(r, near, cap=4):
            n = 0
            for pg in (r.get('query', {}).get('pages', {}) or {}).values():
                ii = (pg.get('imageinfo') or [{}])[0]; m = ii.get('extmetadata', {})
                lic = m.get('LicenseShortName', {}).get('value', '')
                if not re.match(r'(CC BY|CC0|Public domain|PD|CC-BY)', lic): continue
                if ii.get('mime') != 'image/jpeg' or ii.get('width', 0) < 1400 or ii.get('width', 0) < ii.get('height', 1) * 1.2: continue
                t = pg['title']
                if re.search(r'panoramio|map|logo|flag|coat|plan|diagram|scan|\.pdf', t, re.I): continue
                if t in cands: continue
                cands[t] = {'title': t, 'license': lic, 'author': re.sub(r'<[^>]+>', '', m.get('Artist', {}).get('value', ''))[:60], 'thumb': ii.get('thumburl'), 'url': ii.get('descriptionurl'), 'w': ii.get('width'), 'near': near}
                n += 1
                if n >= cap: break
        for q in queries:
            collect(get('https://commons.wikimedia.org/w/api.php?' + urllib.parse.urlencode({'action': 'query', 'generator': 'search', 'gsrsearch': q + ' filetype:bitmap', 'gsrnamespace': 6, 'gsrlimit': 12,
                'prop': 'imageinfo', 'iiprop': 'url|size|mime|extmetadata', 'iiurlwidth': 600, 'format': 'json'})) or {}, q)
        for p in ([] if queries else places[:8]):
            u = 'https://commons.wikimedia.org/w/api.php?' + urllib.parse.urlencode({'action': 'query', 'generator': 'geosearch', 'ggscoord': '%.5f|%.5f' % (p['lat'], p['lng']), 'ggsradius': 6000 if total >= 3 else 1500,
                'ggsnamespace': 6, 'ggslimit': 20, 'prop': 'imageinfo', 'iiprop': 'url|size|mime|extmetadata', 'iiurlwidth': 600, 'format': 'json'})
            collect(get(u) or {}, p['place'])
        cl = list(cands.values())[:16]
        out['candidates'] = cl
        if cl:
            from PIL import Image, ImageDraw
            W, H, cols = 300, 200, 4
            rows = (len(cl) + cols - 1) // cols
            sheet = Image.new('RGB', (W*cols, H*rows), 'white')
            for k, c in enumerate(cl):
                try:
                    import hashlib; fn = '/tmp/claude-1000/img/%s.jpg' % hashlib.md5(c['thumb'].encode()).hexdigest()[:12]
                    if not os.path.exists(fn):
                        urllib.request.urlretrieve(c['thumb'], fn) if False else open(fn, 'wb').write(urllib.request.urlopen(urllib.request.Request(c['thumb'], headers=UA), timeout=40).read())
                        time.sleep(0.4)
                    im = Image.open(fn).convert('RGB'); im.thumbnail((W, H))
                    sheet.paste(im, ((k % cols)*W, (k // cols)*H))
                    ImageDraw.Draw(sheet).text(((k % cols)*W + 6, (k // cols)*H + 4), str(k), fill='red')
                except Exception as e:
                    print('img fail', k, e)
            sheet.save('/tmp/claude-1000/sheets/%s.jpg' % re.sub(r'[^A-Za-z0-9-]', '', tid)[:30], quality=70)
    json.dump(out, open('/tmp/claude-1000/facts/%s.json' % tid, 'w'), ensure_ascii=False, indent=1)
    print('%s | %s | %s km | %s pts | elev %s..%s m, up %s down %s' % (tid, out['name'], out['km'], out['points'], out['min_elev'], out['max_elev'], out['ascent'], out['descent']))
    for p in places:
        print('  km %-6s %s, %s, %s | %s m' % (p['km'], p['place'], p['region'], p['country'], p['elev']))
        for a in p['wiki'][:(2 if '--brief' in sys.argv else 3)]: print('      -', a['title'], ':', a['text'][:(70 if '--brief' in sys.argv else 200)])
    for k, c in enumerate(out['candidates']): print('  IMG', k, c['title'][:70], '|', c['license'], '|', c['author'], '| near', c['near'])

main()
