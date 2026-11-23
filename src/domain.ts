export const species = ['虱目魚', '吳郭魚', '石斑魚', '鱸魚', '烏魚', '鰻魚'] as const;
export type Species = (typeof species)[number];
export type Scenario = 'grounded' | 'partial' | 'insufficient' | 'invalid' | 'offline' | 'busy' | 'failed';
export type AnswerStatus = 'ANSWERED_GROUNDED' | 'ANSWERED_PARTIAL' | 'INSUFFICIENT_EVIDENCE' | 'VALIDATION_FAILED';
export interface Source { id: string; title: string; quote: string; locator: string; }
export interface Answer { status: AnswerStatus; text: string; sources: Source[]; missing: string[]; }
export interface Job { id: string; question: string; species: string; at: string; state: 'RUNNING' | 'DONE' | 'FAILED'; answer?: Answer; error?: string; }
export interface SavedAnswer { id: string; job: Job; note: string; }
export const questions = [
  { text: '虱目魚遇到寒流，應先確認哪些資料？', species: '虱目魚', topic: '氣候防寒' },
  { text: '吳郭魚水質管理要記錄哪些資訊？', species: '吳郭魚', topic: '水質環境' },
  { text: '石斑魚攝食減少，提問時要補充什麼？', species: '石斑魚', topic: '養殖管理' },
  { text: '鱸魚養殖資料應如何查找來源？', species: '鱸魚', topic: '魚種認識' },
  { text: '烏魚養殖問題如何描述得更完整？', species: '烏魚', topic: '養殖管理' },
  { text: '鰻魚養殖環境要提供哪些觀察紀錄？', species: '鰻魚', topic: '水質環境' },
];
export const statusLabels: Record<AnswerStatus, string> = {
  ANSWERED_GROUNDED: '有據回答', ANSWERED_PARTIAL: '部分資訊', INSUFFICIENT_EVIDENCE: '證據不足', VALIDATION_FAILED: '回答待核對',
};
export function validateQuestion(question: string): string | undefined {
  if (!question.trim()) return '請先輸入問題。';
  if (Array.from(question).length > 2000 || question.includes('\0')) return '請輸入 2,000 字以內的有效問題。';
}
// Only the guarded final answer may reach the UI. Never fall back to raw output.
export function presentAnswer(result: { answer_status?: string; final_answer?: string; raw_model_answer?: string }): Pick<Answer, 'status' | 'text'> {
  const status = result.answer_status;
  if (!status || !Object.hasOwn(statusLabels, status) || status === 'VALIDATION_FAILED') {
    return { status: 'VALIDATION_FAILED', text: '本次回答未通過檢查，暫不顯示內容。請補充條件後重新提問。' };
  }
  if (!result.final_answer?.trim()) return { status: 'VALIDATION_FAILED', text: '本次未取得可顯示的回答。' };
  return { status: status as AnswerStatus, text: result.final_answer };
}
