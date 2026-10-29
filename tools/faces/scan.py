"""Face scan: reads /thumbs/1600/*.jpg, writes one JSON line per photo with its faces (normalised box, score, 512-d embedding)."""
import sys, os, json, base64, numpy as np, cv2
from multiprocessing import Pool
os.environ['OMP_NUM_THREADS'] = '1'; cv2.setNumThreads(1)
app = None
def init():
    global app
    import onnxruntime as ort
    _init = ort.InferenceSession.__init__
    def _one(self, path, sess_options=None, *a, **kw):   # one thread per worker: 20 workers x all cores made everything crawl
        so = sess_options or ort.SessionOptions()
        so.intra_op_num_threads = 1; so.inter_op_num_threads = 1; so.enable_cpu_mem_arena = False; so.enable_mem_pattern = False
        _init(self, path, sess_options=so, *a, **kw)
    ort.InferenceSession.__init__ = _one
    from insightface.app import FaceAnalysis
    app = FaceAnalysis(name='buffalo_l', providers=['CPUExecutionProvider'], allowed_modules=['detection', 'recognition'])
    app.prepare(ctx_id=-1, det_size=(960, 960), det_thresh=0.5)
def work(fn):
    try:
        img = cv2.imread('/thumbs/1600/' + fn)
        if img is None: return {'f': fn, 'err': 'unreadable'}
        h, w = img.shape[:2]
        out = []
        for fc in app.get(img):
            x1, y1, x2, y2 = fc.bbox
            e = fc.normed_embedding.astype(np.float16)
            out.append({'x': round(float(max(0, x1)) / w, 4), 'y': round(float(max(0, y1)) / h, 4), 'w': round(float(min(w, x2) - max(0, x1)) / w, 4), 'h': round(float(min(h, y2) - max(0, y1)) / h, 4),
                        's': round(float(fc.det_score), 3), 'e': base64.b64encode(e.tobytes()).decode()})
        return {'f': fn, 'faces': out}
    except Exception as ex:
        return {'f': fn, 'err': str(ex)[:100]}
if __name__ == '__main__':
    lst, outp, procs = sys.argv[1], sys.argv[2], int(sys.argv[3])
    names = [l.strip() for l in open(lst) if l.strip()]
    done = set()
    if os.path.exists(outp):
        for l in open(outp):
            try: done.add(json.loads(l)['f'])
            except Exception: pass
    names = [n for n in names if n not in done]
    print('to do', len(names), flush=True)
    with Pool(procs, initializer=init) as p, open(outp, 'a') as o:
        for i, r in enumerate(p.imap_unordered(work, names, chunksize=4)):
            o.write(json.dumps(r) + '\n')
            if i % 200 == 0: o.flush(); print(i, flush=True)
