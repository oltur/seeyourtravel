#!/usr/bin/env python3
"""Apply a curated improvement to one track (file in web/tracks, files in web/tracks/content, the Track row in the database).
  python3 tools/track_apply.py <spec.json>
spec: {id, name?, category?, public?, travelWith?, startName?, endName?, description (HTML), notes: [{lat,lng,text}], image: {title: "File:...", credit: "..."},
       audio: "path.mp3", audioVolume?, register?: true (insert a Track row for a file that has none)}"""
import json, math, os, re, subprocess, sys, time, urllib.parse, urllib.request
UA = {'User-Agent': 'seeyourtravel-curator/1.0 (info@seeyourtravel.app)'}
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'web')
ADMIN = 'C9F148F7-923A-46B0-8B7C-BD4B54D90886'

def sql(q):
    r = subprocess.run(['docker', 'exec', 'syt-sql', '/opt/mssql-tools18/bin/sqlcmd', '-C', '-S', 'localhost', '-U', 'sa', '-P', 'CHANGE_ME', '-d', 'SeeYourTravel', '-W', '-h', '-1', '-Q', 'set nocount on; ' + q], capture_output=True, text=True)
    if r.returncode or 'Msg ' in r.stdout: raise SystemExit('SQL failed: ' + r.stdout + r.stderr)
    return r.stdout.strip()

def q(s): return "N'" + s.replace("'", "''") + "'"

def hav(a, b):
    k = math.pi / 180
    x = math.sin((b[0]-a[0])*k/2)**2 + math.cos(a[0]*k)*math.cos(b[0]*k)*math.sin((b[1]-a[1])*k/2)**2
    return 2*6371*math.asin(math.sqrt(x))

def main():
    spec = json.load(open(sys.argv[1], encoding='utf-8'))
    tid = spec['id']; path = os.path.join(ROOT, 'tracks', tid + '.js')
    d = json.load(open(path, encoding='utf-8-sig'))
    backup = '/tmp/claude-1000/track-backups'; os.makedirs(backup, exist_ok=True)
    if not os.path.exists(os.path.join(backup, tid + '.js')): open(os.path.join(backup, tid + '.js'), 'w', encoding='utf-8').write(open(path, encoding='utf-8-sig').read())
    for k in ('name', 'category', 'travelWith', 'icon', 'startName', 'endName', 'copyright', 'audioVolume'):
        if k in spec: d[k] = spec[k]
    if 'public' in spec: d['isPublic'] = 'Yes' if spec['public'] else 'No'
    for k in ('useFlickrImages', 'useSYTImagesTrack', 'useGooglePlaces', 'useSYTPlaces', 'stepsToRedraw', 'stepsToShowPhoto'): d.pop(k, None)
    content = os.path.join(ROOT, 'tracks', 'content')
    # picture
    if 'image' in spec:
        title = spec['image']['title']
        u = 'https://commons.wikimedia.org/w/api.php?' + urllib.parse.urlencode({'action': 'query', 'titles': title, 'prop': 'imageinfo', 'iiprop': 'url|extmetadata', 'iiurlwidth': 1280, 'format': 'json'})
        ii = list(json.load(urllib.request.urlopen(urllib.request.Request(u, headers=UA)))['query']['pages'].values())[0]['imageinfo'][0]
        m = ii['extmetadata']; lic = m['LicenseShortName']['value']
        author = re.sub(r'<[^>]+>', '', m.get('Artist', {}).get('value', '')).strip()
        for attempt in range(4):
            try: data = urllib.request.urlopen(urllib.request.Request(ii['thumburl'], headers=UA), timeout=60).read(); break
            except Exception as e:
                if attempt == 3: raise
                time.sleep(3)
        open(os.path.join(content, tid + '.jpg'), 'wb').write(data)
        d['trackImage'] = tid + '.jpg'
        spec['credit'] = 'Picture: %s, %s, <a href="%s" target="_blank" rel="noopener">Wikimedia Commons</a>, %s.' % (spec['image'].get('caption', title[5:].rsplit('.', 1)[0]), author, ii['descriptionurl'], lic)
    # audio
    if 'audio' in spec:
        open(os.path.join(content, tid + '.mp3'), 'wb').write(open(spec['audio'], 'rb').read()); d['audioSrc'] = tid + '.mp3'
    # description
    if 'description' in spec:
        html = spec['description'].strip()
        if spec.get('credit'): html += '\n<p><small>' + spec['credit'] + '</small></p>'
        if spec.get('audio_credit'): html += '\n<p><small>' + spec['audio_credit'] + '</small></p>'
        if spec.get('keep_old') and d.get('textToRead'):   # the track's earlier text stays below the new one
            raw = open(os.path.join(content, d['textToRead']), 'rb').read()
            for enc in ('utf-16', 'utf-8-sig', 'cp1252'):
                try: old = raw.decode(enc); break
                except Exception: old = None
            if old and old.strip() and d['textToRead'] != tid + '.txt': html += '\n<hr>\n<h4>' + spec.get('keep_old_title', 'Earlier text') + '</h4>\n' + old.replace('\r\n', '\n')
        open(os.path.join(content, tid + '.txt'), 'w', encoding='utf-8').write(html)
        d['textToRead'] = tid + '.txt'
    # notes on points
    pts = d.get('trackData', [])
    for i, p in enumerate(pts):   # longitudes outside -180..180 (a map that was dragged round the world) are brought back
        if isinstance(p, dict) and abs(p['lng']) > 180: p['lng'] = round(p['lng'] - 360 * round(p['lng'] / 360), 6)
        elif isinstance(p, list) and abs(p[1]) > 180: p[1] = round(p[1] - 360 * round(p[1] / 360), 6)
    def ll(p): return (p['lat'], p['lng']) if isinstance(p, dict) else (p[0], p[1])
    if spec.get('clear_notes'):
        for i, p in enumerate(pts):
            if isinstance(p, dict): p['syt_text'] = ''
            elif len(p) > 2: pts[i] = list(p[:2])
    for n in spec.get('notes', []):
        i = min(range(len(pts)), key=lambda j: hav(ll(pts[j]), (n['lat'], n['lng'])))
        if hav(ll(pts[i]), (n['lat'], n['lng'])) > n.get('maxkm', 8): print('  note too far from the route, skipped:', n['text'][:40]); continue
        if isinstance(pts[i], dict): pts[i]['syt_text'] = n['text']
        else: pts[i] = (list(pts[i][:2]) + [n['text']])
    order = ['name', 'isPublic', 'travelWith', 'startName', 'endName', 'copyright', 'defaultScale', 'photoLocationTolerancy', 'numOfPhotos', 'velocityMetersPerSec', 'icon', 'trackImage', 'audioSrc', 'audioVolume', 'textToRead', 'trackGpx', 'trackData', 'category']
    keys = [k for k in order if k in d] + [k for k in d if k not in order]
    out = '{\n' + '\n,'.join('"%s":%s' % (k, json.dumps(d[k], ensure_ascii=False, separators=(',', ':'))) for k in keys) + '\n}'
    json.loads(out)
    open(path, 'w', encoding='utf-8').write(out)
    # database
    row = sql("select count(*) from Track where FileName=%s" % q(tid)).strip()
    if row == '0':
        if not spec.get('register'): print('  (no Track row; set "register": true to add one)')
        else:
            first = ll(pts[0]) if pts else None
            loc = "'[ %s, %s, \"\" ]'" % first if first else "''"
            sql("insert into Track (TrackID,FileName,IsPublic,Description,Category,ImageUrl,Created,CreatedBy,Location) values (NEWID(),%s,%d,%s,%s,%s,GETDATE(),%s,%s)" % (
                q(tid), 1 if d.get('isPublic') != 'No' else 0, q(d.get('name', '')), q(d.get('category', 'Other')), q(d.get('trackImage', '')), q(ADMIN), loc))
            sql("insert into TrackUser (TrackUserID,TrackID,UserID) select NEWID(),TrackID,%s from Track where FileName=%s" % (q(ADMIN), q(tid)))
            print('  registered in the database')
    sets = ["Description=%s" % q(d.get('name', '')), "Category=%s" % q(d.get('category', 'Other')), "ImageUrl=%s" % q(d.get('trackImage', ''))]
    if 'public' in spec: sets.append('IsPublic=%d' % (1 if spec['public'] else 0))
    sql("update Track set %s where FileName=%s" % (', '.join(sets), q(tid)))
    print('applied:', tid, '|', d.get('name'), '|', d.get('category'), '| image' if d.get('trackImage') else '', '| text' if d.get('textToRead') else '', '| audio' if d.get('audioSrc') else '')

main()
