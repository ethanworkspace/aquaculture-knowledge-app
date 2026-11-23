import type { Answer, Job, Scenario } from '../domain';

export interface QuestionService {
  complete(job: Job, scenario: Scenario): Promise<Answer>;
}
export const mockService: QuestionService = {
  async complete(_job, scenario) {
    await new Promise(resolve => setTimeout(resolve, 1000));
    if (scenario === 'offline') throw new Error('暫時連不上知識服務。此為離線示範，問題尚未送出。');
    if (scenario === 'busy') throw new Error('目前有其他問答進行中，問題尚未加入排程，請稍後再試。');
    if (scenario === 'failed') throw new Error('這次問答未完成，請建立新的嘗試。');
    const sources = [{ id: 'demo-source', title: '示範文件名稱（非真實來源）', quote: '這裡顯示引用原文摘錄。此段為版型占位，不能作為養殖依據。', locator: '頁碼與章節位置占位' }];
    if (scenario === 'invalid') return { status: 'VALIDATION_FAILED', text: '本次輸出未通過驗證，暫不顯示回答。', sources: [], missing: [] };
    if (scenario === 'insufficient') return { status: 'INSUFFICIENT_EVIDENCE', text: '目前沒有足夠證據回答。請補充魚種、環境與觀察紀錄。', sources: [], missing: ['具體養殖條件', '觀察時間與紀錄'] };
    return { status: scenario === 'partial' ? 'ANSWERED_PARTIAL' : 'ANSWERED_GROUNDED', text: '這裡將呈現由現有問答引擎產生、經引用檢查後的回答。此為設計占位，未呼叫模型，也未提供實際養殖建議。', sources, missing: scenario === 'partial' ? ['實際養殖環境與觀察紀錄'] : [] };
  },
};
