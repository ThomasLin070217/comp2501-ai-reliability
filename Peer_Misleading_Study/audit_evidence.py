"""Fetch benchmark evidence for researcher review; never sends evidence to models.

Full pages stay in a private temporary cache. Public audit contains URLs, hashes,
status and answer-token presence, which is NOT sufficient factual verification.
"""
import concurrent.futures as cf
import hashlib
import json
from pathlib import Path
import re
import sys
import time
import requests
from bs4 import BeautifulSoup

ROOT=Path(__file__).resolve().parent
CACHE=Path('/private/tmp/comp2501_evidence_cache')
CACHE.mkdir(exist_ok=True)


def fetch(url):
    key=hashlib.sha256(url.encode()).hexdigest()
    cache=CACHE/(key+'.json')
    if cache.exists(): return json.loads(cache.read_text())
    result={'url':url,'accessed_at':time.time(),'cache_key':key}
    try:
        resp=requests.get(url,timeout=20,headers={'User-Agent':'Mozilla/5.0 (academic source verification)'})
        result.update(http_status=resp.status_code,final_url=resp.url,sha256=hashlib.sha256(resp.content).hexdigest())
        if resp.status_code==200:
            if 'application/pdf' in resp.headers.get('content-type','') or resp.content.startswith(b'%PDF'):
                import io
                from pypdf import PdfReader
                reader=PdfReader(io.BytesIO(resp.content))
                text=' '.join(p.extract_text() or '' for p in reader.pages)
            else:
                soup=BeautifulSoup(resp.text,'html.parser')
                for node in soup(['script','style','nav','header','footer']): node.decompose()
                text=soup.get_text(' ',strip=True)
            result['text']=re.sub(r'\s+',' ',text)
    except Exception as exc:
        result['error_type']=type(exc).__name__
    cache.write_text(json.dumps(result,ensure_ascii=False))
    return result


def main():
    questions=[json.loads(s) for s in (ROOT/'data/candidates.jsonl').read_text().splitlines()]
    n=int(sys.argv[1]) if len(sys.argv)>1 else 24
    urls=list(dict.fromkeys(url for q in questions[:n] for url in q['source_urls']))
    results={}
    with cf.ThreadPoolExecutor(max_workers=12) as pool:
        futures={pool.submit(fetch,u):u for u in urls}
        for i,f in enumerate(cf.as_completed(futures),1):
            result=f.result();results[futures[f]]=result
            if i%25==0:print('evidence fetch',i,'/',len(urls),flush=True)
    audit=[]
    for q in questions[:n]:
        sources=[]
        for u in q['source_urls']:
            r=results[u];text=r.get('text','')
            sources.append({k:v for k,v in r.items() if k!='text'}|{'gold_year_present':str(q['gold_parts'][0]) in text,'text_characters':len(text)})
        audit.append({'question_id':q['question_id'],'sources':sources,'verification_status':'awaiting_semantic_source_review'})
    (ROOT/'data/evidence_fetch_audit.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2)+'\n')
    print('Audited',len(audit),'questions;',sum(any(s['gold_year_present'] for s in a['sources']) for a in audit),'with gold year in accessible source')


if __name__=='__main__':main()
