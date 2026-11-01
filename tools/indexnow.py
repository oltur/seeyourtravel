#!/usr/bin/env python3
"""Tells Bing, Yandex and the other IndexNow search engines which pages are new or changed (the public tracks and the main pages).
   python3 tools/indexnow.py            all URLs of https://seeyourtravel.app/sitemap.xml
   python3 tools/indexnow.py URL ...    only these URLs
The key is the name of the one .txt file in web/ whose content is the same 32 hex characters (it proves the site is yours)."""
import glob, json, os, re, sys, urllib.request

HOST = 'seeyourtravel.app'
web = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'web')
key = next((os.path.basename(f)[:-4] for f in glob.glob(os.path.join(web, '*.txt'))
            if re.fullmatch(r'[0-9a-f]{32}', os.path.basename(f)[:-4]) and open(f).read().strip() == os.path.basename(f)[:-4]), None)
if not key: sys.exit('no IndexNow key file in web/')
urls = sys.argv[1:]
if not urls:
    xml = urllib.request.urlopen('https://%s/sitemap.xml' % HOST, timeout=30).read().decode()
    urls = re.findall(r'<loc>([^<]+)</loc>', xml)
body = json.dumps({'host': HOST, 'key': key, 'keyLocation': 'https://%s/%s.txt' % (HOST, key), 'urlList': urls}).encode()
req = urllib.request.Request('https://api.indexnow.org/indexnow', body, {'Content-Type': 'application/json; charset=utf-8'})
print(len(urls), 'URLs ->', urllib.request.urlopen(req, timeout=30).status)
