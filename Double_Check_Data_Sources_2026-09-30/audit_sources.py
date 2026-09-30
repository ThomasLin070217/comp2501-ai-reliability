"""Audit downloaded public question banks; does not call any model API."""
import collections
import csv
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / 'raw'


def norm(text):
    return re.sub(r'\s+', ' ', text).strip().casefold()


def csv_rows(name):
    with (RAW / name).open(encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(f))


def write_jsonl(name, rows):
    (ROOT / name).write_text(''.join(json.dumps(r, ensure_ascii=False) + '\n' for r in rows), encoding='utf-8')


records = [json.loads(line) for line in (RAW / 'sycophancy_answer.jsonl').read_text().splitlines() if line.strip()]
groups = collections.defaultdict(list)
for line_number, record in enumerate(records, 1):
    b = record['base']
    groups[(b['dataset'], norm(b['question']))].append((line_number, record))

registry = []
for (dataset, question_key), group in groups.items():
    base = group[0][1]['base']
    flags = []
    if len(group) > 4:
        flags.append('duplicate_question_beyond_four_prompt_conditions')
    if norm(base['incorrect_answer']) in {norm(a) for a in base.get('answer', [])}:
        flags.append('incorrect_answer_also_in_source_answer_aliases')
    if len({x['base']['correct_answer'] for _, x in group}) > 1:
        flags.append('conflicting_gold_answers')
    registry.append({
        'question_id': 'syco_' + hashlib.sha256((dataset + '\n' + question_key).encode()).hexdigest()[:16],
        'source_dataset': dataset,
        'question': base['question'],
        'source_correct_answer': base['correct_answer'],
        'source_incorrect_answer': base['incorrect_answer'],
        'source_base': base,
        'raw_file': 'raw/sycophancy_answer.jsonl',
        'raw_line_numbers': [n for n, _ in group],
        'prompt_variants': sorted({x['metadata']['prompt_template'] for _, x in group}),
        'quality_flags': flags,
        'review_status': 'not_manually_verified',
    })

trivia = [r for r in registry if r['source_dataset'] == 'trivia_qa']
verified = csv_rows('simpleqa_verified.csv')
truthful = csv_rows('truthfulqa.csv')
filtered_verified = [dict(r, review_status='not_manually_verified', incorrect_answer_status='not_created') for r in verified
                     if r['multi_step'] == 'False' and r['requires_reasoning'] == 'False' and r['answer_type'] != 'Number']
truthful_questions = {norm(r['Question']) for r in truthful}
sure = [json.loads(line) for line in (RAW / 'sycophancy_are_you_sure.jsonl').read_text().splitlines() if line.strip()]

audit = {
    'snapshot_date': '2026-09-30',
    'deduplication_rule': 'source dataset plus question text after whitespace normalization and casefold; semantic duplicates not resolved',
    'sycophancy_answer': {
        'raw_prompt_rows': len(records),
        'deduplicated_source_questions': len(registry),
        'source_breakdown': dict(collections.Counter(r['source_dataset'] for r in registry)),
        'flags': dict(collections.Counter(f for r in registry for f in r['quality_flags'])),
        'all_gold_and_wrong_nonempty': all(r['source_correct_answer'] and r['source_incorrect_answer'] for r in registry),
        'trivia_questions_without_alias_conflict': sum('incorrect_answer_also_in_source_answer_aliases' not in r['quality_flags'] for r in trivia),
        'exact_normalized_question_overlap_with_current_truthfulqa': sum(norm(r['question']) in truthful_questions for r in registry),
    },
    'sycophancy_are_you_sure': {
        'raw_prompt_rows': len(sure),
        'unique_question_texts_across_formats': len({norm(r['base']['question']) for r in sure}),
        'note': 'Includes math and duplicated questions across formats. Files provide prompts and source labels, not newly measured model outcomes.',
    },
    'truthfulqa': {
        'rows': len(truthful),
        'missing_source_cells': sum(not r['Source'].strip() for r in truthful),
        'categories': dict(collections.Counter(r['Category'] for r in truthful)),
        'note': 'Current root CSV has 790 rows. Older SycophancyEval uses 817 TruthfulQA questions. Versions are not interchangeable.',
    },
    'simpleqa_verified': {
        'rows': len(verified),
        'topics': dict(collections.Counter(r['topic'] for r in verified)),
        'answer_types': dict(collections.Counter(r['answer_type'] for r in verified)),
        'metadata_filtered_candidates': len(filtered_verified),
        'filter': 'multi_step=False AND requires_reasoning=False AND answer_type!=Number; retains dates; not a manual relevance or quality check',
        'note': 'No wrong-answer field. Original index links to original SimpleQA; do not add counts as independent datasets.',
    },
    'simpleqa_original': {'rows': len(csv_rows('simpleqa_original.csv')), 'role': 'archive and optional expansion only'},
    'recommendation': {
        'primary_pool': 'SycophancyEval TriviaQA subset; manually validate sampled questions, canonical gold, and distractors before experiments',
        'replication_pool': 'SimpleQA Verified; construct and manually verify distractors before experiments',
        'pilot': 'Start with 30 reviewed questions; set final sample size after observing baseline accuracy, effect sizes and API cost',
        'experiment_status': 'No model calls or behavioral measurements have been performed',
    },
}
write_jsonl('sycophancy_questions_deduplicated.jsonl', registry)
write_jsonl('triviaqa_candidate_questions.jsonl', trivia)
write_jsonl('simpleqa_verified_candidate_questions.jsonl', filtered_verified)
(ROOT / 'source_audit.json').write_text(json.dumps(audit, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps(audit, ensure_ascii=False, indent=2))
