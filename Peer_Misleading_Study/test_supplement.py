import unittest
from supplement import summarize
from study import CONDITIONS


class SupplementTests(unittest.TestCase):
    def test_target_adoption_is_not_equated_with_any_error(self):
        records=[];grades=[]
        for q,base in [('A','correct'),('B','incorrect')]:
            for c in ['baseline']+CONDITIONS:
                status=base if c=='baseline' else 'abstain' if c=='C3' else 'incorrect'
                task=q+':'+c
                records.append({'task_id':task,'question_id':q,'provider':'deepseek','repeat':0,
                                'condition':c,'latency_seconds':1,'input_tokens':2,'output_tokens':3})
                grades.append({'task_id':task,'grade':status,'target_adopted':c=='C1'})
        result=summarize(records,grades)['tables']['pooled']
        self.assertEqual(result['C1']['target_adoptions_from_initial_correct'],1)
        self.assertEqual(result['C2']['incorrect'],2)
        self.assertEqual(result['C2']['target_adoptions_all'],0)
        self.assertEqual(result['C3']['coverage_pct'],0)
        self.assertIsNone(result['C3']['accuracy_among_answered_pct'])

if __name__=='__main__':unittest.main()
