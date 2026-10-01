"""Reproduce all published main results offline; never calls model APIs."""
import argparse
import os
from pathlib import Path
import subprocess
import sys


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--out',required=True,type=Path,help='A new output directory; existing nonempty directories are refused.')
    p.add_argument('--plots',action='store_true',help='Requires Matplotlib; creates PNG, SVG and standalone HTML.')
    a=p.parse_args();out=a.out.resolve();root=Path(__file__).resolve().parent
    if out.exists() and any(out.iterdir()):raise ValueError('Use a new empty output directory')
    out.mkdir(parents=True,exist_ok=True)
    q=root/'data/main_questions.jsonl';m=root/'data/main_frozen/materials.json';ad=root/'data/main_adjudications.json'
    collection=out/'collection';raw=collection/'responses.jsonl';filtered=out/'analysis_responses.jsonl'
    def run(name,*args):
        subprocess.run([sys.executable,str(root/name),*map(str,args)],check=True,env={**os.environ,'MPLCONFIGDIR':os.environ.get('MPLCONFIGDIR','/tmp/comp2501-matplotlib')})
    run('assemble_receivers.py','--run',root/'runs/main_receivers',
        '--recovery',root/'runs/main_transport_recovery_01','--recovery',root/'runs/main_transport_recovery_02',
        '--questions',q,'--materials',m,'--continuation-amendment',root/'protocol/morning-continuation.json','--out',collection)
    run('quality_analyze.py','--questions',q,'--responses',raw,'--adjudications',ad,'--out',out)
    run('supplement.py','--responses',filtered,'--grades',out/'grades.json','--out',out/'supplementary.json')
    run('sensitivity.py','--questions',q,'--responses',raw,'--adjudications',ad,
        '--caveats',root/'data/main_preanalysis_caveats.json','--out',out/'sensitivity.json')
    run('usage_ledger.py','--out',out/'usage-ledger.json')
    run('report_tables.py','--summary',out/'summary.json','--supplement',out/'supplementary.json',
        '--sensitivity',out/'sensitivity.json','--usage',out/'usage-ledger.json','--out',out/'statistics.md')
    run('export_receiver_cases.py','--questions',q,'--responses',filtered,'--grades',out/'grades.json','--materials',m,'--out',out/'cases')
    run('export_error_bank.py','--questions',q,'--responses',filtered,'--grades',out/'grades.json','--out',out/'error_bank')
    if a.plots:run('render_results.py','--summary',out/'summary.json','--questions',q,'--responses',filtered,'--materials',m,'--out',out)
    print('Offline reproduction complete: '+str(out))


if __name__=='__main__':main()
