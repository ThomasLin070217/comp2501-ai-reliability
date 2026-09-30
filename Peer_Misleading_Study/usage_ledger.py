"""Account for every generation/development/formal API response, including failures."""
import argparse
from collections import Counter
import json
from pathlib import Path
import statistics
from study import MODELS, read_jsonl, timestamp
from collect import write_json


def aggregate(records):
    return {'calls':len(records),'statuses':dict(Counter(r['status'] for r in records)),
            'input_tokens':sum(r.get('input_tokens',0) for r in records),
            'output_tokens':sum(r.get('output_tokens',0) for r in records),
            'cost_guard_cny':sum(r.get('cost_upper_cny',0) for r in records),
            'median_latency_seconds':statistics.median(r['latency_seconds'] for r in records) if records else None,
            'returned_models':sorted({r.get('model_returned','unavailable') for r in records}),
            'first_request_utc':min((r['timestamp'] for r in records),default=None),
            'last_request_utc':max((r['timestamp'] for r in records),default=None)}


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--runs',type=Path,default=Path(__file__).resolve().parent/'runs')
    p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    stages={x.parent.name:read_jsonl(x) for x in sorted(a.runs.glob('*/responses.jsonl'))}
    records=[r for rs in stages.values() for r in rs]
    ledger={'created_at':timestamp(),'note':'Guard estimate, not invoice. HKU MiniMax price unknown; its zero monetary guard is not a free-price claim.',
            'guard_rates_cny_per_million':{'paid_input':20,'paid_output':50},
            'total':aggregate(records),'stages':{k:aggregate(v) for k,v in stages.items()},
            'providers':{p:aggregate([r for r in records if r['provider']==p]) for p in MODELS}}
    for provider in ledger['providers']:
        ledger['providers'][provider]['money_price_known']=provider!='minimax'
    a.out.parent.mkdir(parents=True,exist_ok=True);write_json(a.out,ledger)
    print(json.dumps({'calls':len(records),'cost_guard_cny':round(ledger['total']['cost_guard_cny'],4),
                      'hku_tokens':ledger['providers']['minimax']['input_tokens']+ledger['providers']['minimax']['output_tokens']}))

if __name__=='__main__':main()
