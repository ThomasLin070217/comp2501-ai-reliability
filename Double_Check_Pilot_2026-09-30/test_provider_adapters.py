import unittest
import pilot
from review_and_report import unwrap


class AdapterTests(unittest.TestCase):
    def test_anthropic_preserves_content_and_counts_separate_cache_buckets(self):
        blocks = [{'type':'text','text':'{"answer":"A","abstain":false}'}]
        result = pilot.parse_response({'content':blocks,'stop_reason':'end_turn','model':'test',
            'usage':{'input_tokens':5,'cache_read_input_tokens':10,'cache_creation_input_tokens':2,'output_tokens':3}}, 'anthropic')
        self.assertEqual(result['status'],'ok')
        self.assertEqual(result['assistant_message']['content'],blocks)
        self.assertEqual(result['usage']['total_tokens'],20)

    def test_truncated_native_response_stays_incomplete(self):
        result = pilot.parse_response({'content':[{'type':'text','text':'partial'}],
            'stop_reason':'max_tokens','usage':{}}, 'anthropic')
        self.assertEqual(result['status'],'incomplete')

    def test_anthropic_system_separate_and_nonstream_explicit(self):
        result = pilot.make_payload({'model':'test','protocol':'anthropic',
            'generation':{'stream':False,'max_tokens':32}},
            [{'role':'system','content':'test'},{'role':'user','content':'Q'}])
        self.assertEqual(result['system'],'test')
        self.assertFalse(result['stream'])
        self.assertEqual([m['role'] for m in result['messages']],['user'])

    def test_fence_normalization_never_extracts_embedded_answer(self):
        payload = '{"answer":"A","abstain":false}'
        self.assertEqual(unwrap('```json\n'+payload+'\n```'), payload)
        mixed = 'Actually not A.\n```json\n'+payload+'\n```'
        self.assertEqual(unwrap(mixed),mixed)


if __name__=='__main__':
    unittest.main()
