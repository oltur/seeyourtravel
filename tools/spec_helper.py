import json, glob
def facts(key):
    for f in glob.glob('/tmp/claude-1000/facts/%s*.json' % key): return json.load(open(f))
def at(fx, km):
    """coordinates of the stop nearest to km"""
    p = min(fx['places'], key=lambda p: abs(p['km'] - km)); return {'lat': p['lat'], 'lng': p['lng']}
def note(fx, km, text):
    d = at(fx, km); d['text'] = text; return d
