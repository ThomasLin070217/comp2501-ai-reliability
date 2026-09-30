import json
from pathlib import Path
import unittest
from quality_analyze import filter_quality
from study import digest, read_jsonl


class QualityAnalysisTests(unittest.TestCase):
    def test_unscorable_output_excludes_entire_cell_without_mutating_raw(self):
        root = Path(__file__).resolve().parent
        qs = read_jsonl(root/'data/dev_retained_questions.jsonl')
        rs = read_jsonl(root/'runs/dev_receivers/responses.jsonl')
        ad = json.loads((root/'data/dev_adjudications.json').read_text())
        # A review response fails without a complete date; its six siblings must
        # not remain in paired comparisons with an implicitly favorable grade.
        r = next(r for r in rs if r['condition'] == 'C2')
        r['text'] = '{"answer": "Februar'
        key = digest({'question_id': r['question_id'], 'text': r['text']})
        with self.assertRaises(ValueError):
            filter_quality(qs, rs, ad)
        ad[key] = {'status': 'pending', 'output_quality': 'unscorable_output', 'reason': 'Test fixture'}
        before = digest(rs)
        filtered, audit = filter_quality(qs, rs, ad)
        self.assertEqual(len(filtered), len(rs)-7)
        self.assertEqual(len(audit['excluded_cells']), 1)
        self.assertEqual(len(audit['unscorable_outputs']), 1)
        self.assertEqual(digest(rs), before)
        self.assertFalse(any((x['question_id'], x['provider'], x['repeat']) ==
                             (r['question_id'], r['provider'], r['repeat']) for x in filtered))


if __name__ == '__main__':
    unittest.main()
