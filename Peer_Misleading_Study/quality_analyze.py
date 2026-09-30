"""Post-freeze output-quality handling, explicitly separate from frozen analysis.

Preserves an unfiltered diagnostic result; only complete scoreable cells enter
the reported paired analysis. Never changes or retries a model response.
"""
import argparse
import json
from pathlib import Path
from analyze import analyze
from study import CONDITIONS, read_jsonl, grade, digest
from collect import write_json


def filter_quality(questions, records, adjudications):
    qs = {q['question_id']: q for q in questions}
    failures = []
    excluded = set()
    for r in records:
        key = digest({'question_id': r['question_id'], 'text': r.get('text')})
        decision = adjudications.get(key, {})
        status, _, _ = grade(r.get('text'), qs[r['question_id']])
        if r['status'] != 'ok':
            raise ValueError('Transport failure needs a separate documented decision')
        if decision.get('output_quality') == 'unscorable_output':
            if status != 'pending' or decision['status'] != 'pending':
                raise ValueError('Only explicitly reviewed unscorable pending outputs can be filtered')
            cell = (r['question_id'], r['provider'], r['repeat'])
            excluded.add(cell)
            failures.append({'task_id': r['task_id'], 'review_id': key,
                             'reason': decision['reason'], 'text': r['text']})
        elif status == 'pending' and decision.get('status', 'pending') == 'pending':
            raise ValueError('Unreviewed pending output: ' + key)
    filtered = [r for r in records if (r['question_id'], r['provider'], r['repeat']) not in excluded]
    excluded_records = [r for r in records if (r['question_id'], r['provider'], r['repeat']) in excluded]
    for cell in excluded:
        conditions = [r['condition'] for r in excluded_records
                      if (r['question_id'], r['provider'], r['repeat']) == cell]
        if sorted(conditions) != sorted(['baseline'] + CONDITIONS):
            raise ValueError('Quality exclusion requires a complete seven-response cell')
    audit = {'rule': 'Exclude all seven responses of a cell containing an explicitly reviewed unscorable output.',
             'post_freeze_amendment': 'protocol/output-quality-amendment.md',
             'raw_responses': len(records), 'analysis_responses': len(filtered),
             'raw_records_sha256': digest(records), 'analysis_records_sha256': digest(filtered),
             'unscorable_outputs': failures, 'excluded_cells': [list(c) for c in sorted(excluded)],
             'excluded_task_ids': [r['task_id'] for r in excluded_records],
             'raw_data_deleted': False, 'responses_retried': False}
    return filtered, audit


def save_analysis(out, questions, records, adjudications):
    out.mkdir(parents=True, exist_ok=True)
    summary, grades, queue = analyze(questions, records, adjudications)
    for name, value in [('summary', summary), ('grades', grades), ('blinded_format_review', queue)]:
        write_json(out/(name + '.json'), value)
    return summary


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--questions', type=Path, required=True)
    p.add_argument('--responses', type=Path, required=True)
    p.add_argument('--adjudications', type=Path, required=True)
    p.add_argument('--out', type=Path, required=True)
    a = p.parse_args()
    qs, rs = read_jsonl(a.questions), read_jsonl(a.responses)
    ad = json.loads(a.adjudications.read_text())
    filtered, audit = filter_quality(qs, rs, ad)
    save_analysis(a.out/'unfiltered_diagnostic', qs, rs, ad)
    summary = save_analysis(a.out, qs, filtered, ad)
    if summary['unresolved_grades'] or summary['incomplete_cells']:
        raise ValueError('Filtered analysis still has unresolved or incomplete cells')
    summary['output_quality'] = audit
    write_json(a.out/'summary.json', summary)
    write_json(a.out/'output_quality.json', audit)
    # Disposable derivative for downstream CLI tools; complete raw data remains in runs/.
    (a.out/'analysis_responses.jsonl').write_text(''.join(json.dumps(r, ensure_ascii=False)+'\n' for r in filtered))
    print(json.dumps({'raw_responses': len(rs), 'analysis_responses': len(filtered),
                      'complete_cells': summary['complete_cells'],
                      'unscorable_outputs': len(audit['unscorable_outputs'])}))


if __name__ == '__main__':
    main()
