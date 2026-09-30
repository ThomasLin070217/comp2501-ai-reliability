"""Offline contract tests. Synthetic fixture responses are NOT experiment results."""
import contextlib
import io
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import pilot

Q = {'pilot_id':'T01','question':'Which fictional city is specified in this test?',
     'correct_answer':'GoldCity','accepted_answers':['GoldCity'],
     'incorrect_answer':'WrongCity','incorrect_answer_aliases':['WrongCity'],
     'evidence_urls':['https://evidence.invalid/secret-gold']}
C = {'model':'test-only','api_key_env':'PILOT_TEST_KEY','base_url':'https://example.invalid/v1',
     'generation':{'max_completion_tokens':50},'order_seed':2501}


class Contracts(unittest.TestCase):
    def test_gold_and_evidence_not_sent(self):
        prior={'baseline':'BASE_RESPONSE','fresh':'FRESH_RESPONSE'}
        for stage in pilot.STAGES:
            payload=json.dumps(pilot.messages(Q,stage,prior))
            self.assertNotIn('GoldCity',payload)
            self.assertNotIn('secret-gold',payload)
            self.assertEqual('WrongCity' in payload,stage.endswith('_wrong'))

    def test_fresh_is_isolated_and_branches_share_baseline(self):
        prior={'baseline':'BASE_RESPONSE','fresh':'FRESH_RESPONSE'}
        self.assertEqual(pilot.messages(Q,'fresh',prior),pilot.messages(Q,'baseline',{}))
        for stage in pilot.FINAL[1:]:
            msg=pilot.messages(Q,stage,prior)
            self.assertEqual(msg[2],{'role':'assistant','content':'BASE_RESPONSE'})
            self.assertEqual('FRESH_RESPONSE' in json.dumps(msg),stage.startswith('independent_'))

    def test_plan_dependencies_and_reproducibility(self):
        qs=[dict(Q,pilot_id=f'T{i}') for i in range(30)]
        tasks=pilot.plan(qs,2501)
        self.assertEqual(tasks,pilot.plan(qs,2501))
        self.assertEqual(len(tasks),180)
        done=set()
        for task in tasks:
            self.assertTrue(set(task['depends_on'])<=done)
            self.assertNotIn(task['task_id'],done)
            done.add(task['task_id'])

    def test_grading_does_not_reward_negation_or_guess_lists(self):
        for answer in ['Not GoldCity','GoldCity or WrongCity','GoldCity is false','OtherCity']:
            self.assertEqual(pilot.auto_grade(json.dumps({'answer':answer,'abstain':False}),Q)[0],'pending')
        self.assertEqual(pilot.auto_grade('{"answer":"GoldCity", "abstain":false}',Q)[0],'correct')
        self.assertEqual(pilot.auto_grade('{"answer":"WrongCity", "abstain":false}',Q)[0],'incorrect')
        self.assertEqual(pilot.auto_grade('{"answer":"", "abstain":true}',Q)[0],'abstain')
        self.assertEqual(pilot.auto_grade('{"answer":"GoldCity", "abstain":true}',Q)[0],'pending')

    def test_empty_data_does_not_report_zero_accuracy(self):
        with tempfile.TemporaryDirectory() as d,contextlib.redirect_stdout(io.StringIO()):
            pilot.summarize([Q],Path(d))
            report=json.loads((Path(d)/'summary.json').read_text())
            self.assertEqual(report['status'],'no_model_data')
            self.assertIsNone(report['conditions']['baseline']['accuracy'])
            self.assertIsNone(report['reported_tokens']['total_tokens'])

    def test_resume_and_no_secret_in_logs(self):
        calls=[]
        def fake_api(config,payload):
            calls.append(payload)
            return {'model':'test-only','choices':[{'message':{'content':'{"answer":"GoldCity","abstain":false}'},'finish_reason':'stop'}],
                    'usage':{'prompt_tokens':10,'completion_tokens':10,'total_tokens':20}},0.1
        with tempfile.TemporaryDirectory() as d,patch.dict(os.environ,{'PILOT_TEST_KEY':'DO_NOT_LOG_ME'}),patch.object(pilot,'call_api',fake_api),contextlib.redirect_stdout(io.StringIO()):
            output=Path(d)
            tasks=pilot.plan([Q],2501)
            self.assertEqual(pilot.execute(C,[Q],tasks,output,2),2)
            self.assertEqual(pilot.execute(C,[Q],tasks,output,99),4)
            self.assertEqual(pilot.execute(C,[Q],tasks,output,99),0)
            self.assertEqual(len(calls),6)
            self.assertTrue(all('DO_NOT_LOG_ME' not in p.read_text() for p in output.iterdir()))
            with self.assertRaises(ValueError):
                pilot.execute(dict(C,model='other'),[Q],tasks,output,1)
            pilot.summarize([Q],output)
            report=json.loads((output/'summary.json').read_text())
            self.assertEqual(report['status'],'complete')
            self.assertEqual(report['reported_tokens']['total_tokens'],120)

    def test_unresolved_attempt_not_silently_resubmitted(self):
        with tempfile.TemporaryDirectory() as d,patch.dict(os.environ,{'PILOT_TEST_KEY':'TEST'}):
            output=Path(d)
            pilot.write_jsonl(output/'attempts.jsonl',[{'task_id':'T01:baseline','event':'started'}])
            with patch.object(pilot,'call_api') as api:
                with self.assertRaises(ValueError):
                    pilot.execute(C,[Q],pilot.plan([Q],2501),output,6)
                api.assert_not_called()

    def test_failed_calls_stop_and_never_count_as_wrong(self):
        with tempfile.TemporaryDirectory() as d,patch.dict(os.environ,{'PILOT_TEST_KEY':'TEST'}),patch.object(pilot,'call_api',side_effect=TimeoutError),contextlib.redirect_stdout(io.StringIO()):
            output=Path(d)
            with self.assertRaises(RuntimeError):
                pilot.execute(C,[Q],pilot.plan([Q],2501),output,6)
            self.assertEqual(len(pilot.read_jsonl(output/'responses.jsonl')),1)
            pilot.summarize([Q],output)
            report=json.loads((output/'summary.json').read_text())
            self.assertEqual(report['conditions']['baseline']['incorrect'],0)
            self.assertIsNone(report['conditions']['baseline']['accuracy'])

    def test_transition_denominators_keep_abstention_separate(self):
        qs=[dict(Q,pilot_id=f'T{i}') for i in range(4)]
        baseline=['GoldCity','GoldCity','WrongCity','']
        revised=['WrongCity','','GoldCity','GoldCity']
        rows=[]
        for i,q in enumerate(qs):
            for stage,answer in [('baseline',baseline[i]),('review_wrong',revised[i])]:
                rows.append(dict(task_id=q['pilot_id']+':'+stage,pilot_id=q['pilot_id'],stage=stage,status='ok',
                                 text=json.dumps({'answer':answer,'abstain':not bool(answer)})))
        with tempfile.TemporaryDirectory() as d,contextlib.redirect_stdout(io.StringIO()):
            output=Path(d)
            pilot.write_jsonl(output/'responses.jsonl',rows)
            pilot.summarize(qs,output)
            report=json.loads((output/'summary.json').read_text())
            wrong=report['conditions']['review_wrong']
            self.assertEqual(wrong['accuracy'],0.5)
            self.assertEqual(wrong['damage_rate'],0.5)
            self.assertEqual(wrong['correction_rate'],1.0)
            self.assertEqual(wrong['correct_to_abstain'],1)
            self.assertIsNone(report['reported_tokens']['total_tokens'])


if __name__=='__main__':
    unittest.main()
