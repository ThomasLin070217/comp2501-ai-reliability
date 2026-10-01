import copy
import unittest
from assemble_receivers import replace_failure
from study import digest


class RecoveryTests(unittest.TestCase):
    def test_only_identical_failed_request_can_be_recovered(self):
        failed={'task_id':'q:m:r0:C4','provider':'m','question_id':'q','condition':'C4','repeat':0,
                'generator':'other','request':{'messages':['frozen']},'request_sha256':'same',
                'status':'error','timestamp':'2026-09-30T18:00:00+00:00'}
        success=copy.deepcopy(failed);success.update(status='ok',text='returned answer',timestamp='2026-09-30T18:01:00+00:00')
        receipt={'original_failure_sha256':digest(failed)}
        self.assertEqual(replace_failure(failed,success,receipt),success)
        changed=copy.deepcopy(success);changed['request']['messages']=['changed']
        with self.assertRaises(ValueError):replace_failure(failed,changed,receipt)
        answered=copy.deepcopy(failed);answered.update(status='ok',text='wrong answer')
        with self.assertRaises(ValueError):replace_failure(answered,success,{'original_failure_sha256':digest(answered)})
        self.assertEqual(failed['status'],'error')


if __name__=='__main__':unittest.main()

class ContinuationTests(unittest.TestCase):
    def test_prefix_and_budget_cannot_change(self):
        from continue_receivers import validate_prefix
        records=[{'task_id':'q:m:r0:baseline','text':'old answer'}]
        manifest={'budget_guard_cny':100}
        amendment={'existing_response_count':1,'existing_responses_sha256':digest(records),
                   'original_manifest_sha256':digest(manifest),'expected_unique_tasks':7,
                   'max_new_unique_calls':6,'budget_guard_cny':100}
        validate_prefix(records,manifest,amendment)
        validate_prefix(records+[{'task_id':'q:m:r0:C0','text':'new answer'}],manifest,amendment)
        changed=copy.deepcopy(records);changed[0]['text']='replacement'
        with self.assertRaises(ValueError):validate_prefix(changed,manifest,amendment)
        changed_amendment={**amendment,'budget_guard_cny':200}
        with self.assertRaises(ValueError):validate_prefix(records,manifest,changed_amendment)
