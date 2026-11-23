"""Mobile adapter for the existing RAG Service; no shared backend key leaves it."""
from __future__ import annotations
import hashlib, hmac, json, logging, re, secrets, sqlite3, threading, time, uuid
from collections import deque
from contextlib import contextmanager
from urllib.parse import urlsplit

class MobileError(Exception):
    def __init__(self, status, code, message, retryable=False):
        self.status, self.code, self.message, self.retryable = status, code, message, retryable

class MobileGateway:
    def __init__(self, service, access_code, database, session_seconds=86400):
        if not access_code: raise ValueError('Workspace access code must be configured server-side')
        self.service, self.access_code, self.database = service, access_code, str(database)
        self.session_seconds = session_seconds
        self.lock = threading.RLock()
        self.failures = deque(maxlen=20)
        with self.db() as con:
            con.executescript('''CREATE TABLE IF NOT EXISTS sessions (
                token_hash TEXT PRIMARY KEY, expires REAL NOT NULL);
                CREATE TABLE IF NOT EXISTS requests (
                owner TEXT NOT NULL, request_id TEXT NOT NULL, backend_id TEXT NOT NULL UNIQUE,
                payload_digest TEXT NOT NULL, created REAL NOT NULL,
                PRIMARY KEY(owner,request_id));''')

    @contextmanager
    def db(self):
        con = sqlite3.connect(self.database, timeout=15)
        con.row_factory = sqlite3.Row
        try:
            with con: yield con
        finally: con.close()

    def info(self):
        return {'service':'marine-mobile-gateway','api_version':1,'model_id':'M2',
                'model_digest':self.service.model_settings['M2']['digest'],
                'corpus_version':self.service.active['version'], 'workspace_mode':'shared_research_workspace'}

    def login(self, body):
        if set(body) != {'access_code'} or not isinstance(body['access_code'], str) or len(body['access_code']) > 128:
            raise MobileError(400,'INVALID_INPUT','請輸入有效的工作區存取碼。')
        with self.lock:
            now = time.monotonic()
            while self.failures and now-self.failures[0] > 60: self.failures.popleft()
            if len(self.failures) >= 8: raise MobileError(429,'LOGIN_RATE_LIMIT','登入嘗試過於頻繁，請稍後再試。',True)
            if not hmac.compare_digest(body['access_code'].encode(), self.access_code.encode()):
                self.failures.append(now)
                raise MobileError(401,'INVALID_ACCESS_CODE','工作區存取碼不正確。')
            token = secrets.token_urlsafe(32)
            expiry = time.time()+self.session_seconds
            with self.db() as con:
                con.execute('DELETE FROM requests WHERE owner IN (SELECT token_hash FROM sessions WHERE expires<=?)',(time.time(),))
                con.execute('DELETE FROM sessions WHERE expires<=?',(time.time(),))
                con.execute('INSERT INTO sessions VALUES (?,?)',(hashlib.sha256(token.encode()).hexdigest(),expiry))
            return self.info() | {'session_token':token,'expires_at':expiry}

    def owner(self, authorization):
        if not authorization.startswith('Bearer ') or len(authorization)>160:
            raise MobileError(401,'SESSION_EXPIRED','連線已到期，請重新登入工作區。')
        key = hashlib.sha256(authorization[7:].encode()).hexdigest()
        with self.db() as con: row = con.execute('SELECT expires FROM sessions WHERE token_hash=?',(key,)).fetchone()
        if not row or row['expires']<=time.time(): raise MobileError(401,'SESSION_EXPIRED','連線已到期，請重新登入工作區。')
        return key

    def logout(self, owner):
        with self.db() as con:
            con.execute('DELETE FROM sessions WHERE token_hash=?',(owner,))
            con.execute('DELETE FROM requests WHERE owner=?',(owner,))

    def start(self, owner, body):
        if set(body)-{'request_id','question','selected_species'} or not isinstance(body.get('question'),str):
            raise MobileError(400,'INVALID_INPUT','請確認問題內容與必填欄位。')
        request_id=body.get('request_id')
        try:
            if not isinstance(request_id,str): raise ValueError()
            uuid.UUID(request_id)
        except ValueError: raise MobileError(400,'INVALID_REQUEST_ID','請求識別碼無效。') from None
        canonical={'question':body['question'],'selected_species':body.get('selected_species','全部魚種')}
        # Existing validation is reused, but the client can never choose a model or context.
        try: self.service.validate_question(canonical | {'model_id':'M2','request_id':request_id})
        except (ValueError,TypeError,KeyError): raise MobileError(400,'INVALID_INPUT','請輸入 2,000 字以內的有效問題與魚種。') from None
        digest=hashlib.sha256(json.dumps(canonical,sort_keys=True,ensure_ascii=False).encode()).hexdigest()
        with self.lock:
            with self.db() as con:
                old=con.execute('SELECT * FROM requests WHERE owner=? AND request_id=?',(owner,request_id)).fetchone()
                if old:
                    if old['payload_digest']!=digest: raise MobileError(409,'REQUEST_CONFLICT','同一請求識別碼不能變更問題內容。')
                    backend_id=old['backend_id']
                else:
                    count=con.execute('SELECT count(*) FROM requests WHERE owner=? AND created>?',(owner,time.time()-60)).fetchone()[0]
                    if count>=10: raise MobileError(429,'RATE_LIMIT','提問過於頻繁，請稍後再試。',True)
                    # A separate server UUID prevents collision with legacy or other-session jobs.
                    backend_id=str(uuid.uuid4())
                    con.execute('INSERT INTO requests VALUES (?,?,?,?,?)',(owner,request_id,backend_id,digest,time.time()))
            try: result=self.service.start_job(canonical | {'model_id':'M2','request_id':backend_id})
            except BlockingIOError: raise MobileError(429,'SERVICE_BUSY','目前有問答進行中，這個問題尚未排入處理，請稍後重試。',True) from None
        return self.job_result(request_id,result)

    def get_job(self, owner, request_id):
        with self.db() as con: row=con.execute('SELECT backend_id FROM requests WHERE owner=? AND request_id=?',(owner,request_id)).fetchone()
        if not row: raise MobileError(404,'JOB_NOT_FOUND','找不到這筆工作區連線的問答請求。')
        job=self.service.job(row['backend_id'])
        if not job: raise MobileError(404,'JOB_NOT_FOUND','問題尚未開始處理，可使用原請求識別碼重新送出。',True)
        return self.job_result(request_id,job)

    def job_result(self, request_id, job):
        status=job.get('status')
        if status not in ('RUNNING','DONE','FAILED'): raise MobileError(503,'INVALID_UPSTREAM','問答服務回傳了未知狀態。',True)
        result={'request_id':request_id,'status':status}
        if status=='DONE': result['record']=self.safe_record(job['record'])
        if status=='FAILED': result['error']={'code':'JOB_FAILED','message':'本次問答未完成，請建立新的提問嘗試。','retryable':False}
        return result

    def safe_record(self, record):
        expected=self.service.model_settings['M2']['digest']
        if record.get('model_id')!='M2' or record.get('model_digest')!=expected:
            raise MobileError(503,'MODEL_IDENTITY_MISMATCH','回答模型身分未通過核對，暫不顯示。')
        raw=record.get('result',{})
        status=raw.get('answer_status')
        allowed=('ANSWERED_GROUNDED','ANSWERED_PARTIAL','INSUFFICIENT_EVIDENCE','VALIDATION_FAILED')
        if status not in allowed: status='VALIDATION_FAILED'
        text=raw.get('final_answer')
        if not isinstance(text,str) or not text.strip(): status='VALIDATION_FAILED'
        if status=='VALIDATION_FAILED': text='本次回答尚未通過檢查，暫不顯示內容。請補充條件後重新提問。'
        evidence=[]
        if status in ('ANSWERED_GROUNDED','ANSWERED_PARTIAL'):
            cited=set(raw.get('supporting_chunk_ids',[]))
            checks=raw.get('validation_status',{}).get('exact_quote_checks',[])
            for context in record.get('question_payload',{}).get('top5',[]):
                if context.get('chunk_id') not in cited: continue
                source=self.service.sources.get(context.get('source_id'),{})
                quotes=[x.get('quote','') for x in checks if x.get('chunk_id')==context['chunk_id'] and x.get('quote_verified') is True]
                quote='\n\n'.join(q for q in quotes if isinstance(q,str) and q) or context.get('source_quote','')
                locator=context.get('exact_locator') or '來源尚未提供頁碼或章節定位'
                if not isinstance(locator,str): locator=json.dumps(locator,ensure_ascii=False)
                locator=re.sub(r'(?:[A-Za-z]:[\\/]|file://)[^\n]*','[本機路徑不公開]',locator)[:1000]
                evidence.append({'chunk_id':context['chunk_id'],'source_id':context.get('source_id'),
                    'title':source.get('title') or context.get('source_id') or '來源名稱待補',
                    'publisher':source.get('publisher'),'version':context.get('source_version'),
                    'locator':locator,'quote':str(quote)[:16000]})
        missing=raw.get('missing_information',[])
        return {'attempt_id':record.get('attempt_id'),'question':record.get('question') or record.get('question_payload',{}).get('question'),
                'model_id':'M2','model_digest':expected,'corpus_version':self.service.active['version'],
                'answer_status':status,'answer_origin':raw.get('answer_origin'), 'final_answer':text,
                'missing_information':[v for v in missing if isinstance(v,str)] if isinstance(missing,list) else [],'evidence':evidence}

    def handle(self, handler):
        route=urlsplit(handler.path).path
        try:
            if handler.headers.get('Origin'): raise MobileError(403,'ORIGIN_NOT_ALLOWED','請使用已授權的手機 App 連線。')
            body={}
            if handler.command=='POST':
                if handler.headers.get('Transfer-Encoding') or len(handler.headers.get_all('Content-Length',[]))!=1:
                    raise MobileError(400,'INVALID_INPUT','請求格式無效。')
                if handler.headers.get('Content-Type','').split(';')[0].strip().lower()!='application/json':
                    raise MobileError(415,'INVALID_INPUT','請以 JSON 傳送資料。')
                length=int(handler.headers.get('Content-Length','0'))
                if length<2 or length>16384: raise MobileError(413,'INVALID_INPUT','資料大小超出限制。')
                body=json.loads(handler.rfile.read(length))
                if not isinstance(body,dict): raise MobileError(400,'INVALID_INPUT','資料格式無效。')
            if route=='/app/v1/session' and handler.command=='POST': return handler.send_json(200,self.login(body))
            owner=self.owner(handler.headers.get('Authorization',''))
            if route=='/app/v1/session' and handler.command=='DELETE':
                self.logout(owner); return handler.send_json(200,{'logged_out':True})
            if route=='/app/v1/status' and handler.command=='GET': return handler.send_json(200,self.info())
            if route=='/app/v1/jobs' and handler.command=='POST':
                result=self.start(owner,body); return handler.send_json(200 if result['status']=='DONE' else 202,result)
            if route.startswith('/app/v1/jobs/') and handler.command=='GET': return handler.send_json(200,self.get_job(owner,route[len('/app/v1/jobs/'):]))
            raise MobileError(404,'NOT_FOUND','找不到這個 App 服務。')
        except MobileError as error:
            return handler.send_json(error.status,{'error':{'code':error.code,'message':error.message,'retryable':error.retryable}})
        except (ValueError,TypeError,KeyError):
            return handler.send_json(400,{'error':{'code':'INVALID_INPUT','message':'請確認問題與必填欄位。','retryable':False}})
        except Exception:
            logging.exception('Mobile request failed; no request body or authorization logged')
            return handler.send_json(503,{'error':{'code':'SERVICE_UNAVAILABLE','message':'知識服務暫時無法完成請求，請稍後再試。','retryable':True}})
