import assert from 'node:assert/strict';
import test from 'node:test';
import { presentAnswer, validateQuestion } from '../src/domain.ts';
test('never reveals raw text when validation fails', () => {
  const answer = presentAnswer({ answer_status: 'VALIDATION_FAILED', final_answer: 'blocked generated text', raw_model_answer: 'secret raw advice' });
  assert.equal(answer.status, 'VALIDATION_FAILED'); assert.ok(!answer.text.includes('blocked')); assert.ok(!answer.text.includes('secret'));
});
test('unknown status and empty guarded text fail closed', () => {
  assert.equal(presentAnswer({ answer_status: 'NEW_STATUS', final_answer: 'unreviewed' }).status, 'VALIDATION_FAILED');
  assert.equal(presentAnswer({ answer_status: 'ANSWERED_GROUNDED', raw_model_answer: 'must not leak' }).status, 'VALIDATION_FAILED');
});
test('valid grounded answer uses only final text', () => {
  assert.deepEqual(presentAnswer({ answer_status: 'ANSWERED_GROUNDED', final_answer: 'guarded answer', raw_model_answer: 'raw' }), { status: 'ANSWERED_GROUNDED', text: 'guarded answer' });
});
test('question validation rejects blank, NUL and oversized input', () => {
  assert.ok(validateQuestion('   ')); assert.ok(validateQuestion('question\0'));
  assert.ok(validateQuestion('魚'.repeat(2001))); assert.equal(validateQuestion('魚'.repeat(2000)), undefined);
});
