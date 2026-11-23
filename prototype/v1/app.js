'use strict';
// Design-only data. No fetch, API credentials, or persistent account storage.
const $ = id => document.getElementById(id);
const escapeHTML = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const paths = {
 home:'M3 10 12 3l9 7v10H15v-6H9v6H3Z',
 chat:'M4 4h16v12H9l-5 5Z',
 book:'M6 3h12v18l-6-4-6 4Z',
 user:'M16 7a4 4 0 1 1-8 0 4 4 0 0 1 8 0ZM4 21v-2a8 8 0 0 1 16 0v2',
 back:'m15 5-7 7 7 7',
 chevron:'m9 6 6 6-6 6',
 fish:'M4 12c4-8 10-8 14 0-4 8-10 8-14 0Zm0 0-3-4v8l3-4M14 11h.01M9 6l3-3 2 4',
 source:'M5 3h10l4 4v14H5ZM14 3v5h5M8 12h8M8 16h6',
 clock:'M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0ZM12 7v5l3 2',
 check:'m5 12 4 4L19 6',
 alert:'M12 3 2 21h20ZM12 9v5M12 17h.01',
 wave:'M2 9c3-4 5 4 8 0s5 4 8 0 4 0 4 0M2 15c3-4 5 4 8 0s5 4 8 0 4 0 4 0',
 logout:'M9 3H3v18h6M13 7l5 5-5 5M8 12h13',
 trash:'M3 6h18M9 6V3h6v3M5 6l1 15h12l1-15M10 10v7M14 10v7'
};
const websiteIcons = {home:'aquaculture_fish_favicon_v1.png',fish:'aquaculture_fish_favicon_v1.png',chat:'watercolor_chat.png',book:'watercolor_knowledge.png',source:'watercolor_knowledge.png',clock:'watercolor_history.png',user:'watercolor_history.png',wave:'aquaculture_fish_favicon_v1.png'};
function icon(name){if(websiteIcons[name])return `<img class="website-icon" src="assets/${websiteIcons[name]}" alt="" aria-hidden="true">`;return `<svg viewBox="0 0 24 24" aria-hidden="true"><path d="${paths[name] || paths.source}"/></svg>`;}
const fish = ['虱目魚','吳郭魚','石斑魚','鱸魚','烏魚','鰻魚'];
const questions = [
 {text:'虱目魚遇到寒流，應先確認哪些資料？',species:'虱目魚',topic:'氣候防寒'},
 {text:'吳郭魚水質管理要記錄哪些資訊？',species:'吳郭魚',topic:'水質環境'},
 {text:'石斑魚攝食減少，提問時要補充什麼？',species:'石斑魚',topic:'養殖管理'},
 {text:'鱸魚養殖資料應如何查找來源？',species:'鱸魚',topic:'魚種認識'},
 {text:'烏魚養殖問題如何描述得更完整？',species:'烏魚',topic:'養殖管理'},
 {text:'鰻魚養殖環境要提供哪些觀察紀錄？',species:'鰻魚',topic:'水質環境'}
];
const labels = {home:'養殖知識',ask:'知識問答',waiting:'正在處理',answer:'回答詳情',source:'引用來源',saved:'我的收藏',note:'收藏詳情',history:'問答紀錄',me:'我的',login:'歡迎使用養殖漁業知識平台',status:'服務狀態'};
const scenarios = {
 grounded:{label:'有據回答',heading:'先把問題的背景整理清楚',body:'這裡將呈現經問答引擎與引用檢查後的回答。每個可查核的重點，應能對應到下方來源。',extra:'此為回答版型占位，沒有提供實際養殖建議，也未經真實來源支持。',source:true},
 partial:{label:'部分資訊',heading:'目前只能提供部分資訊',body:'這裡將呈現現有來源可支持的部分，其餘資訊缺口會另外列出。',extra:'尚需補充：實際養殖條件、觀察時間及相關紀錄。以上為狀態示範。',source:true},
 insufficient:{label:'證據不足',heading:'目前沒有足夠證據回答',body:'現有資料不足以支持完整回答。你可以補充魚種、養殖環境與觀察紀錄，再建立新問題。',extra:'此為證據不足的示範狀態。',source:false},
 invalid:{label:'回答待核對',heading:'本次回答未通過驗證',body:'本次輸出尚未通過檢查，暫不顯示回答內容。請補充具體條件後重新提問。',extra:'被攔截的模型原文不會作為備用答案顯示。',source:false},
 offline:{label:'服務離線',heading:'暫時連不上知識服務',body:'請確認網路連線，稍後再試。你輸入的問題會留在目前畫面。',extra:'示範狀態，不代表現有後端即時連線情況。',source:false,error:true},
 busy:{label:'服務忙碌',heading:'目前有其他問答進行中',body:'這個問題尚未加入排程，請稍後再試。目前無法提供等待順位或完成時間。',extra:'目前尚未提供排隊功能，請稍後重新嘗試。',source:false,error:true},
 failed:{label:'任務失敗',heading:'這次問答未能完成',body:'你可以建立新的嘗試。正式串接時會保留原失敗任務，並以新請求識別碼重試。',extra:'此為失敗狀態示範，不會呼叫模型。',source:false,error:true}
};
let serial = 1;
const state = {page:'login',logged:false,stack:[],species:'全部魚種',draft:'',scenario:'grounded',current:null,history:[],saved:[],selectedNote:null,query:'',filter:'全部魚種',timer:null};
let toastTimer;
function toast(message){$('toast').textContent=message;$('toast').hidden=false;clearTimeout(toastTimer);toastTimer=setTimeout(()=>$('toast').hidden=true,2600);}
function chip(text,type=''){return `<span class="chip ${type}">${escapeHTML(text)}</span>`;}
function button(text,action,kind='primary'){return `<button class="${kind}" data-action="${action}">${text}</button>`;}
function row(title,subtitle,action,ico='source'){return `<button class="row" data-action="${action}">${icon(ico)}<span class="row-main">${escapeHTML(title)}${subtitle?`<small>${escapeHTML(subtitle)}</small>`:''}</span>${icon('chevron')}</button>`;}
function currentDemo(){return {id:'preview',question:state.draft.trim()||questions[0].text,species:state.species==='全部魚種'?'虱目魚':state.species,scenario:state.scenario,at:'畫面示範'};}
function go(page,remember=true){
 if(remember && page!==state.page)state.stack.push(state.page);
 state.page=page;render();
}
function render(){
 const page=state.page;
 $('page-title').textContent=labels[page]||'養殖漁業知識平台';
 $('back').innerHTML=icon(['home','login'].includes(page)?'wave':'back');
 $('back').disabled=['home','login'].includes(page);
 $('back').setAttribute('aria-label',['home','login'].includes(page)?'養殖漁業知識平台':'返回上一頁');
 $('jump').value=['waiting','note','status'].includes(page)?(page==='waiting'?'ask':page==='note'?'saved':'me'):page;
 $('bottom-nav').hidden=page==='login';
 const active={answer:'ask',waiting:'ask',source:'ask',note:'saved',history:'me',status:'me'}[page]||page;
 $('bottom-nav').innerHTML=[['home','home','首頁'],['ask','chat','問答'],['saved','book','收藏'],['me','user','我的']].map(([p,i,l])=>`<button data-page="${p}" class="${active===p?'active':''}" ${active===p?'aria-current="page"':''}>${icon(i)}<span>${l}</span></button>`).join('');
 $('screen').innerHTML=views[page]();
}
const views = {
 login:()=>`<div class="login-symbol"><img class="login-brand" src="assets/aquaculture_fish_favicon_v1.png" alt="養殖漁業知識平台"></div><div class="center"><h2>養殖漁業知識平台</h2><p class="sub">讓每一次知識累積，<br>都找得到來源與自己的筆記。</p></div><div class="panel"><h3>體驗你的養殖知識工作區</h3><p class="sub small-gap">先試試提問、閱讀來源與收藏流程。此原型不收集真實帳號密碼。</p></div>${button('進入示範帳號','login')}<p class="legal">正式版將提供登入、註冊及密碼重設。<br>目前示範資料只保留在此分頁。</p>`,
 home:()=>`<div><p class="greeting">你好，養殖夥伴</p><h2>今天想了解什麼？</h2></div><div class="hero"><img class="hero-fish" src="assets/watercolor_chat.png" alt=""><span class="meta">你的養殖知識助手</span><h2>從一個問題開始，<br>找到有來源的知識。</h2>${button('開始提問','ask')}</div><section><div class="section-head"><h3>從養殖魚種出發</h3><span class="count">六類魚種</span></div><div class="species-grid">${fish.map((f,i)=>`<button class="species" data-fish="${i}">${icon('fish')}<span>${f}</span></button>`).join('')}</div></section><section><div class="section-head"><h3>常見問題</h3><span class="count">畫面示例</span></div><div class="list">${questions.slice(0,2).map((q,i)=>row(q.text,q.topic,`question:${i}`,'chat')).join('')}</div></section>${state.history.length?row('最近一次提問',state.history.at(-1).question,'history','clock'):''}`,
 ask:()=>`<div><h2>今天想問什麼？</h2><p class="sub small-gap">補充魚種與觀察情況，讓問題更完整。</p></div><form id="ask-form"><div class="field"><label for="species">養殖魚種</label><select id="species">${['全部魚種',...fish].map(f=>`<option ${state.species===f?'selected':''}>${f}</option>`).join('')}</select></div><div class="field"><label for="question">你想了解什麼？</label><textarea id="question" maxlength="2000" placeholder="例如：虱目魚遇到寒流，應先確認哪些資料？" required>${escapeHTML(state.draft)}</textarea><small>最多 2,000 字 · 不需填寫個人聯絡資料</small></div><p id="ask-error" role="alert" hidden></p><button type="submit" class="primary" style="margin-top:20px">送出問題</button></form><p class="prototype-label">示範模式：送出後將顯示「${scenarios[state.scenario].label}」情境，不會呼叫模型。</p><section><h3>也可以從這些問題開始</h3><div class="list small-gap">${questions.filter(q=>state.species==='全部魚種'||q.species===state.species).slice(0,3).map(q=>row(q.text,q.topic,`question:${questions.indexOf(q)}`,'chat')).join('')}</div></section>`,
 waiting:()=>`<div class="center"><div class="waiting-ring" aria-hidden="true"></div><h2>正在處理你的問題</h2><p class="sub">正式版會查詢同一筆任務，<br>你可以離開畫面，稍後回來查看。</p></div><div class="panel"><span class="chip">本地模擬等待</span><p class="small-gap">${escapeHTML(state.current?.question||state.draft)}</p></div><p class="sub">目前不提供進度百分比或完成時間預估。</p>${button('返回首頁，稍後查看','home','secondary')}`,
 answer:()=>{
  const record=state.current||currentDemo(), s=scenarios[record.scenario];
  if(s.error)return `<div class="center"><div class="status-icon">${icon('alert')}</div>${chip(s.label,'warn')}<h2 style="margin-top:16px">${s.heading}</h2><p class="sub">${s.body}</p></div><div class="panel">${escapeHTML(record.question)}</div>${button('返回問題並重試','retry')}${button('返回首頁','home','secondary')}<p class="meta">${s.extra}</p>`;
  const saved=state.saved.some(n=>n.answer.id===record.id);
  return `<div>${chip(record.species)} <span class="meta">M2 · 示範回答</span><h2 style="margin-top:12px;font-size:1.3rem">${escapeHTML(record.question)}</h2></div><div class="section-head"><h3>給你的回答</h3>${chip(s.label,record.scenario==='grounded'?'':'warn')}</div><div class="panel answer-text"><h3>${s.heading}</h3><p class="small-gap">${s.body}</p><p class="sub">${s.extra}</p></div>${s.source?row('查看引用來源','示範來源 · 1 段占位','source','source'):'<p class="sub">本次沒有可顯示的引用來源。</p>'}<p class="prototype-label">畫面占位，非真實模型輸出。正式版只顯示經檢查可提供的回答內容。</p>${s.source?button(saved?'已收藏 · 查看筆記':'收藏這則回答',saved?'open-saved':'save'):''}${button('補充資訊，重新提問','retry','secondary')}<button class="link-button" data-action="feedback">回報這則回答</button>`;
 },
 source:()=>`<div><span class="chip">引用來源 · 畫面占位</span><h2 style="margin-top:12px">每個重點，都能追溯。</h2><p class="sub small-gap">正式版只顯示本次回答實際引用的來源。</p></div><div class="panel"><h3>示範文件名稱</h3><p class="meta small-gap">出版單位占位 · 來源版本占位</p><p class="meta">頁碼／章節定位將由實際資料提供</p><p class="quote" style="margin-top:18px">這裡顯示回答所引用的原文摘錄。此段是介面占位，不對應真實文件，也不能作為養殖依據。</p></div><p class="sub">如有已核准展示的原文圖片或表格，會出現在對應來源下方；缺少頁碼時不自行補造。</p>${button('返回回答','answer','secondary')}`,
 saved:()=>`<div><h2>留下有用的知識</h2><p class="sub small-gap">回答與你的筆記，分開保存。</p></div><div class="field"><label for="saved-search" class="sr-only">搜尋收藏</label><input id="saved-search" placeholder="搜尋問題或個人筆記" value="${escapeHTML(state.query)}"></div><div class="field"><label for="saved-filter">依魚種篩選</label><select id="saved-filter">${['全部魚種',...fish].map(f=>`<option ${state.filter===f?'selected':''}>${f}</option>`).join('')}</select></div><div id="saved-list">${savedList()}</div>`,
 note:()=>{
  const note=state.saved.find(n=>n.id===state.selectedNote);
  if(!note)return `<div class="empty">這則收藏已移除。</div>${button('返回收藏','saved','secondary')}`;
  return `<div>${chip(note.answer.species)}<h2 style="margin-top:12px;font-size:1.3rem">${escapeHTML(note.answer.question)}</h2></div><div class="panel"><h3>原回答快照</h3><p class="sub small-gap">${scenarios[note.answer.scenario].body}</p><p class="meta small-gap">示範內容 · 不受個人筆記編輯影響</p><button class="link-button" data-action="note-answer">查看回答與來源</button></div><form id="note-form"><div class="field"><label for="personal-note">我的筆記</label><textarea id="personal-note" maxlength="8000" placeholder="記下自己的觀察或待查事項…">${escapeHTML(note.note)}</textarea><small>個人筆記不會成為知識庫證據。</small></div><button class="primary" style="margin-top:16px">儲存筆記</button></form>${button('取消收藏','remove','secondary')}`;
 },
 history:()=>`<div><h2>回顧每一次提問</h2><p class="sub small-gap">目前分頁的示範紀錄，共 ${state.history.length} 筆。</p></div><div class="list">${state.history.length?state.history.slice().reverse().map(r=>row(r.question,`${r.at} · ${scenarios[r.scenario].label}`,`record:${r.id}`,'clock')).join(''):'<div class="empty">還沒有問答紀錄。<br>從你的第一個問題開始。</div>'}</div>${button('開始提問','ask','secondary')}`,
 me:()=>`<div class="panel"><h2>示範養殖夥伴</h2><p class="sub small-gap">個人工作區 · 原型體驗帳號</p></div><div class="list">${row('問答紀錄',`${state.history.length} 筆示範提問`,'history','clock')}${row('我的收藏',`${state.saved.length} 則知識與筆記`,'saved','book')}${row('服務狀態','目前為原型示範模式','status','wave')}${row('清除示範資料','只影響目前分頁','clear','trash')}${row('登出示範帳號','','logout','logout')}</div><p class="meta">養殖漁業知識平台 · 第一版畫面原型<br>尚未實作真實登入、帳號刪除與雲端資料保存。</p>`,
 status:()=>`<div class="status-icon">${icon('wave')}</div><div class="center"><h2>目前為示範模式</h2><p class="sub">原型未連接知識服務，<br>此處不代表正式後端的健康狀態。</p></div><div class="list">${row('知識庫','預定沿用 v6；目前未載入','noop','source')}${row('回答模型','正式版預設 M2；目前未呼叫','noop','chat')}</div><p class="sub">正式版會區分網路、服務入口、問答引擎及推論可用性。</p>${button('返回我的','me','secondary')}`
};
function savedList(){
 const needle=state.query.trim().toLocaleLowerCase();
 const filtered=state.saved.filter(n=>(state.filter==='全部魚種'||n.answer.species===state.filter)&&`${n.answer.question} ${n.note}`.toLocaleLowerCase().includes(needle));
 if(!filtered.length)return `<div class="empty">${state.saved.length?'找不到符合條件的收藏。':'還沒有收藏。<br>在回答頁收藏一則知識，就能加入筆記。'}</div>`;
 return filtered.map(n=>`<button class="saved-card" data-action="note:${n.id}">${chip(n.answer.species)}<h3>${escapeHTML(n.answer.question)}</h3><p class="sub">${escapeHTML(n.note||'還沒有個人筆記，點選後新增。')}</p><small>示範回答 · 個人收藏</small></button>`).join('');
}
function submitQuestion(){
 state.draft=$('question').value;state.species=$('species').value;
 if(!state.draft.trim()){$('ask-error').textContent='請先輸入問題。';$('ask-error').hidden=false;return;}
 if(state.timer){toast('已有一筆模擬任務處理中，請稍候。');return;}
 const record={...currentDemo(),id:`demo-${serial++}`,at:new Date().toLocaleTimeString('zh-TW',{hour:'2-digit',minute:'2-digit',hour12:false})};
 state.current=record;go('waiting');
 state.timer=setTimeout(()=>{
  state.timer=null;state.history.push(record);
  if(state.page==='waiting'){state.current=record;go('answer',false);}else toast('示範問答已完成，可從問答紀錄查看。');
 },1500);
}
function showDialog(html){$('dialog-content').innerHTML=html;$('dialog').showModal();}
function action(a){
 if(['home','ask','answer','source','saved','history','me','status'].includes(a)){go(a);return;}
 if(a==='login'){state.logged=true;state.stack=[];go('home',false);return;}
 if(a.startsWith('question:')){const q=questions[Number(a.split(':')[1])];state.draft=q.text;state.species=q.species;go('ask');return;}
 if(a.startsWith('record:')){state.current=state.history.find(r=>r.id===a.slice(7));go('answer');return;}
 if(a==='retry'){const r=state.current;state.draft=r?.question||state.draft;state.species=r?.species||state.species;go('ask');return;}
 if(a==='save'){
  const answer=state.current||currentDemo();
  let note=state.saved.find(n=>n.answer.id===answer.id);
  if(!note){note={id:`note-${serial++}`,answer:{...answer},note:''};state.saved.push(note);}
  state.selectedNote=note.id;toast('已加入示範收藏');go('note');return;
 }
 if(a==='open-saved'){state.selectedNote=state.saved.find(n=>n.answer.id===(state.current||currentDemo()).id)?.id;go('note');return;}
 if(a.startsWith('note:')){state.selectedNote=a.slice(5);go('note');return;}
 if(a==='note-answer'){state.current={...state.saved.find(n=>n.id===state.selectedNote).answer};go('answer');return;}
 if(a==='remove'){showDialog(`<h3>取消這則收藏？</h3><p>示範收藏與個人筆記會移除，問答紀錄仍會保留。</p><div class="button-row">${button('保留','close','secondary')}${button('取消收藏','confirm-remove','danger')}</div>`);return;}
 if(a==='confirm-remove'){state.saved=state.saved.filter(n=>n.id!==state.selectedNote);$('dialog').close();state.selectedNote=null;state.stack=[];go('saved',false);toast('已取消示範收藏');return;}
 if(a==='feedback'){showDialog(`<h3>回報這則回答</h3><p>示範回報只顯示確認訊息，不會傳送資料。</p><form id="feedback-form"><div class="field"><label for="reason">回報原因</label><select id="reason"><option>沒有解決問題</option><option>來源有疑問</option><option>其他</option></select></div><div class="field"><label for="feedback-note">補充說明（選填）</label><textarea id="feedback-note" maxlength="1000"></textarea></div><div class="button-row">${button('取消','close','secondary')}<button class="primary" type="submit">模擬送出</button></div></form>`);return;}
 if(a==='clear'){showDialog(`<h3>清除示範資料？</h3><p>清除目前分頁的收藏、筆記與問答紀錄，不影響正式研究資料。</p><div class="button-row">${button('取消','close','secondary')}${button('清除','confirm-clear','danger')}</div>`);return;}
 if(a==='confirm-clear'){clearTimeout(state.timer);state.timer=null;Object.assign(state,{history:[],saved:[],current:null,selectedNote:null,draft:'',query:'',filter:'全部魚種',stack:[]});$('dialog').close();go('me',false);toast('已清除目前分頁的示範資料');return;}
 if(a==='logout'){clearTimeout(state.timer);state.timer=null;state.logged=false;state.stack=[];go('login',false);toast('已登出示範帳號；資料仍保留在此分頁');return;}
 if(a==='close')$('dialog').close();
}
document.addEventListener('click',event=>{
 const button=event.target.closest('button');if(!button)return;
 if(button.id==='back'){let page=state.stack.pop()||'home';if(page==='waiting'&&!state.timer)page='answer';go(page,false);return;}
 if(button.dataset.page){if(state.page==='ask'&&$('question')){state.draft=$('question').value;state.species=$('species').value;}go(button.dataset.page);return;}
 if(button.dataset.fish!==undefined){state.species=fish[Number(button.dataset.fish)];go('ask');return;}
 if(button.dataset.action){event.preventDefault();action(button.dataset.action);}
});
document.addEventListener('submit',event=>{
 event.preventDefault();
 if(event.target.id==='ask-form')submitQuestion();
 if(event.target.id==='note-form'){const note=state.saved.find(n=>n.id===state.selectedNote);note.note=$('personal-note').value;toast('已儲存示範筆記');}
 if(event.target.id==='feedback-form'){$('dialog').close();toast('已完成回報操作示範，未傳送資料');}
});
document.addEventListener('input',event=>{
 if(event.target.id==='question')state.draft=event.target.value;
 if(event.target.id==='saved-search'){state.query=event.target.value;$('saved-list').innerHTML=savedList();}
});
document.addEventListener('change',event=>{
 if(event.target.id==='species'){state.species=event.target.value;render();}
 if(event.target.id==='saved-filter'){state.filter=event.target.value;$('saved-list').innerHTML=savedList();}
 if(event.target.id==='jump'){
  // Design navigation may open any screen without a real login.
  if(event.target.value==='answer'||event.target.value==='source')state.current=currentDemo();
  go(event.target.value);
 }
 if(event.target.id==='scenario'){
  state.scenario=event.target.value;
  if(state.page==='answer'||state.page==='source'){state.current=currentDemo();if(state.page==='source')state.page='answer';render();}
  else if(state.page==='ask')render();
 }
});
render();
