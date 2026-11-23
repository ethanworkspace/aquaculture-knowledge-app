import json, tempfile, unittest, uuid
from pathlib import Path
from mobile_gateway import MobileGateway, MobileError

class FakeService:
    model_settings={'M2':{'digest':'test-m2-digest'}}
    active={'version':'test-corpus'}
    sources={'s1':{'title':'Source title','publisher':'Publisher'}}
    def __init__(self): self.jobs={}; self.calls=[]; self.busy=False
    def validate_question(self, body):
        if not body['question'].strip() or len(body['question'])>2000: raise ValueError()
    def start_job(self, body):
        if self.busy: raise BlockingIOError()
        self.calls.append(body)
        record={'model_id':'M2','model_digest':'test-m2-digest','question':body['question'],
            'result':{'answer_status':'ANSWERED_GROUNDED','answer_origin':'MODEL_GENERATED','final_answer':'Guarded answer','raw_model_answer':'PRIVATE_RAW',
                      'supporting_chunk_ids':['c1'],'missing_information':[]},
            'question_payload':{'top5':[{'chunk_id':'c1','source_id':'s1','source_quote':'Actual evidence','exact_locator':'page 1'}]}}
        self.jobs[body['request_id']]={'status':'DONE','record':record}
        return self.jobs[body['request_id']]
    def job(self, request_id): return self.jobs.get(request_id)

class GatewayTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        self.service=FakeService();self.path=Path(self.temp.name)/'mobile.sqlite3'
        self.gateway=MobileGateway(self.service,'test-workspace-code',self.path)
        self.session=self.gateway.login({'access_code':'test-workspace-code'})
        self.owner=self.gateway.owner('Bearer '+self.session['session_token'])
    def body(self): return {'request_id':str(uuid.uuid4()),'question':'Valid question','selected_species':'虱目魚'}
    def test_tokens_hashed_and_revoked(self):
        self.assertNotIn(self.session['session_token'].encode(),self.path.read_bytes())
        self.gateway.logout(self.owner)
        with self.assertRaises(MobileError):self.gateway.owner('Bearer '+self.session['session_token'])
    def test_login_wrong_code_rate_limited(self):
        for _ in range(8):
            with self.assertRaises(MobileError) as error:self.gateway.login({'access_code':'wrong'})
            self.assertEqual(error.exception.status,401)
        with self.assertRaises(MobileError) as error:self.gateway.login({'access_code':'wrong'})
        self.assertEqual(error.exception.status,429)
    def test_fixed_model_and_no_raw_output(self):
        result=self.gateway.start(self.owner,self.body())
        self.assertEqual(self.service.calls[-1]['model_id'],'M2')
        self.assertNotIn('PRIVATE_RAW',json.dumps(result))
        self.assertEqual(result['record']['evidence'][0]['title'],'Source title')
        with self.assertRaises(MobileError):self.gateway.start(self.owner,self.body()|{'model_id':'M4'})
    def test_identity_and_blocked_answers_fail_closed(self):
        result=self.gateway.start(self.owner,self.body())
        backend=next(iter(self.service.jobs.values()))['record']
        backend['result'].update(answer_status='VALIDATION_FAILED',final_answer='BLOCKED')
        answer=self.gateway.safe_record(backend)
        self.assertEqual(answer['evidence'],[]);self.assertNotIn('BLOCKED',json.dumps(answer))
        backend['model_digest']='wrong'
        with self.assertRaises(MobileError):self.gateway.safe_record(backend)
    def test_sessions_cannot_read_each_others_or_legacy_jobs(self):
        body=self.body();self.gateway.start(self.owner,body)
        second=self.gateway.login({'access_code':'test-workspace-code'})
        owner2=self.gateway.owner('Bearer '+second['session_token'])
        with self.assertRaises(MobileError) as error:self.gateway.get_job(owner2,body['request_id'])
        self.assertEqual(error.exception.status,404)
        self.assertNotEqual(self.service.calls[-1]['request_id'],body['request_id'])
    def test_stable_uuid_retries_and_payload_conflict(self):
        body=self.body();first=self.gateway.start(self.owner,body)
        again=self.gateway.start(self.owner,body)
        self.assertEqual(first,again)
        self.assertEqual(self.service.calls[0]['request_id'],self.service.calls[1]['request_id'])
        with self.assertRaises(MobileError) as error:self.gateway.start(self.owner,body|{'question':'Changed'})
        self.assertEqual(error.exception.status,409)
    def test_busy_claim_can_be_resubmitted_and_restarts_preserve_sessions(self):
        body=self.body();self.service.busy=True
        with self.assertRaises(MobileError) as error:self.gateway.start(self.owner,body)
        self.assertEqual(error.exception.code,'SERVICE_BUSY')
        self.service.busy=False;self.gateway.start(self.owner,body)
        restarted=MobileGateway(self.service,'test-workspace-code',self.path)
        self.assertEqual(restarted.owner('Bearer '+self.session['session_token']),self.owner)

if __name__=='__main__': unittest.main()
