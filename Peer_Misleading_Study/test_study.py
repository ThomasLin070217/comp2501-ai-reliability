import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import study
import analyze
import freeze_materials
from collect import date_parts

Q={'question_id':'TEST','question':'In what year was the fictional event held?', 'gold':'2010','gold_parts':[2010],
   'false_target':'2011','false_parts':[2011],'source_urls':['SECRET_EVIDENCE'],'pairing_direction':0,'split':'dev'}


class StudyTests(unittest.TestCase):
    def test_date_equivalence_and_strictness(self):
        self.assertEqual(date_parts('18th of April, 1954'),(1954,4,18))
        self.assertEqual(date_parts('1954-04-18'),(1954,4,18))
        self.assertIsNone(date_parts('1954 or 1955'))
        self.assertIsNone(date_parts('Not 1954'))
        self.assertIsNone(date_parts('February 30, 1954'))

    def test_grade_distinguishes_error_abstention_and_pending(self):
        self.assertEqual(study.grade('{"answer":"2010","abstain":false}',Q)[0],'correct')
        self.assertEqual(study.grade('{"answer":"2011","abstain":false}',Q),('incorrect','date_differs',True))
        self.assertEqual(study.grade('{"answer":"","abstain":true}',Q)[0],'abstain')
        self.assertEqual(study.grade('{"answer":"2010 or 2011","abstain":false}',Q)[0],'pending')
        self.assertEqual(study.grade('{"answer":"2010","abstain":true}',Q)[0],'pending')

    def test_branches_are_isolated_and_pair_materials(self):
        m={'answer':'2011','explanation':'The suggestion explanation.'}
        a=study.receiver_messages(Q,'C2','INITIAL',m)
        b=study.receiver_messages(Q,'C3','INITIAL',m)
        self.assertEqual(a[:3],b[:3])
        self.assertEqual(a[-1]['content'].split('\n\n')[0],b[-1]['content'].split('\n\n')[0])
        self.assertNotIn('SECRET_EVIDENCE',json.dumps(a))
        self.assertNotIn('2010',json.dumps(a))
        self.assertNotIn('explanation.',study.receiver_messages(Q,'C1','INITIAL',m)[-1]['content'])
        self.assertEqual(len(study.receiver_messages(Q)),2)
        self.assertEqual(len(a),4)

    def test_balanced_pairings_never_self(self):
        pairs={(p,study.generator_for(p,d)) for p in study.MODELS for d in [0,1]}
        self.assertEqual(len(pairs),6)
        self.assertTrue(all(a!=b for a,b in pairs))

    def test_provider_failures_not_scored(self):
        d={'choices':[{'message':{'content':'{"answer":"2010","abstain":false}'},'finish_reason':'length'}],'usage':{}}
        self.assertEqual(study.parse_response(d,'openai')['status'],'incomplete')

    def test_frozen_manifest_rejects_changes(self):
        with tempfile.TemporaryDirectory() as td:
            out=Path(td);study.frozen_manifest(out,{'q':1})
            with self.assertRaises(ValueError):study.frozen_manifest(out,{'q':2})

    def test_unresolved_attempt_never_automatically_resubmitted(self):
        with tempfile.TemporaryDirectory() as td:
            out=Path(td);(out/'attempts.jsonl').write_text('{"task_id":"inflight"}\n')
            with self.assertRaises(ValueError):study.Runner({},out,100,100,9999999999)

    def test_budget_guard_halts_before_network(self):
        with tempfile.TemporaryDirectory() as td:
            config={'generation':{'max_tokens':768},'model':'example','protocol':'openai','cost_guard_cny_per_million':{'input':20,'output':50}}
            runner=study.Runner({'deepseek':config},Path(td),0,100,9999999999)
            with patch('urllib.request.build_opener') as network:
                with self.assertRaises(RuntimeError):runner.call('deepseek','x',[],{})
                network.assert_not_called()

    def test_material_receipt_protects_against_mutation(self):
        q={**Q,'source_review':'Reviewed'}
        material={f'TEST:{p}:{t}':{'answer':'2010' if t=='correct' else '2011',
                   'explanation':'This is a plausible contextual argument for the date in question. '*4}
                  for p in study.MODELS for t in ['correct','wrong']}
        receipt={'status':'frozen','reviewer':'Codex','questions_sha256':study.digest([q]),'materials_sha256':study.digest(material)}
        freeze_materials.validate([q],material,receipt)
        material['TEST:kimi:wrong']['answer']='2010'
        with self.assertRaises(ValueError):freeze_materials.validate([q],material,receipt)

    def test_selection_is_first_valid_not_last_or_longest(self):
        q={**Q,'source_review':'Reviewed'};rs=[]
        for p in study.MODELS:
            for t in ['correct','wrong']:
                for a in [0,1]:
                    rs.append({'task_id':f'TEST:{p}:{t}:a{a}','attempt':a,'status':'ok','text':json.dumps({
                        'answer':'2010' if t=='correct' else '2011','explanation':('First ' if a==0 else 'Second ')*40})})
        materials,audit,missing=freeze_materials.propose([q],rs,{})
        self.assertFalse(missing)
        self.assertTrue(all(m['explanation'].startswith('First') for m in materials.values()))

    def test_analysis_counts_correction_and_harm_with_correct_denominators(self):
        rs=[]
        for qid,initial in [('A','2010'),('B','2008')]:
            for c in ['baseline']+study.CONDITIONS:
                answer=initial if c in ['baseline','C0'] else '2011' if c in ['C1','C2'] else '2010'
                rs.append({'kind':'receiver','question_id':qid,'task_id':qid+':'+c,'provider':'deepseek','generator':'kimi',
                           'repeat':0,'condition':c,'status':'ok','text':json.dumps({'answer':answer,'abstain':False}),
                           'latency_seconds':1,'model_returned':'test'})
        result,_,_=analyze.analyze([{**Q,'question_id':q} for q in ['A','B']],rs)
        table=result['tables']['pooled']
        self.assertEqual(table['baseline']['accuracy_pct'],50)
        self.assertEqual(table['C2']['harm_pct'],100)
        self.assertEqual(table['C3']['harm_pct'],0)
        self.assertEqual(table['C4']['repair_pct'],100)
        self.assertEqual(result['effects']['pooled']['RQ2_C3_minus_C2_harm']['difference_pp'],-100)

    def test_no_denominator_returns_null_not_zero_effect(self):
        result=analyze.bootstrap({'A':[{'baseline':'incorrect','C1':'incorrect','C2':'incorrect'}]},'C1','C2',iterations=10)
        self.assertIsNone(result['difference_pp'])
        self.assertIsNone(result['ci95_pp'])

    def test_degenerate_bootstrap_does_not_claim_zero_uncertainty(self):
        result=analyze.bootstrap({'A':[{'baseline':'correct','C1':'correct','C2':'correct'}]},'C1','C2',iterations=10)
        self.assertEqual(result['difference_pp'],0)
        self.assertIsNone(result['ci95_pp'])
        self.assertIn('degenerate',result['bootstrap_status'])

    def test_invalid_unicode_material_is_rejected_without_rewriting(self):
        text=json.dumps({'answer':'2010','explanation':('Context '*40)+'\udcb9'})
        record={'task_id':'TEST:kimi:correct:a0','attempt':0,'status':'ok','text':text}
        materials,audit,missing=freeze_materials.propose([Q],[record],{})
        self.assertEqual(materials,{})
        self.assertIn('invalid_unicode_in_decoded_material',audit[0]['errors'])


if __name__=='__main__':unittest.main()
