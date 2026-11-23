import json
import tempfile
import threading
import unittest
from pathlib import Path

from serving_runtime import ServingRuntime, LengthBucketReranker


class Retriever:
    manifest = {'version': 'v6-test'}
    sha = 'verified-corpus-sha'
    def __init__(self): self.calls = 0
    def retrieve(self, question, species, limit=5):
        self.calls += 1
        self.rerank(question, [])
        return {'top5': [{'chunk_id': species, 'source_quote': 'PRIVATE_SOURCE'}]}
    def rerank(self, question, rows): return [1]


class Runtime:
    policy_version = 'policy-v1'
    def __init__(self): self.unified = Retriever(); self.calls = 0
    def call(self, record, model):
        self.calls += 1
        return {'model_id': model, 'model_digest': 'verified-m2', 'result': 'PRIVATE_ANSWER'}
    def ask(self, question, species):
        result = self.unified.retrieve(question, species)
        return self.call(result, 'M2')


class ServingTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(); self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name) / 'timings.jsonl'
        self.serving = ServingRuntime(self.path, cache_entries=2, configure=lambda: None)
        self.addCleanup(self.serving.close)
        self.runtime = self.serving.attach(Runtime())

    def test_exact_cache_reuses_retrieval_but_always_generates(self):
        for request_id in ['id-1', 'id-2']:
            self.serving.measure(request_id, lambda: self.runtime.ask('PRIVATE_QUESTION', '虱目魚'))
        self.assertEqual(self.runtime.unified.calls, 1)
        self.assertEqual(self.runtime.calls, 2)
        rows = [json.loads(x) for x in self.path.read_text().splitlines()]
        self.assertFalse(rows[0]['retrieval_cache_hit']); self.assertTrue(rows[1]['retrieval_cache_hit'])
        self.assertNotIn('PRIVATE_', self.path.read_text())

    def test_cached_contexts_are_copied_and_keys_include_species_and_limit(self):
        first = self.runtime.unified.retrieve('Q', '虱目魚')
        first['top5'][0]['source_quote'] = 'MUTATED'
        self.assertEqual(self.runtime.unified.retrieve('Q', '虱目魚')['top5'][0]['source_quote'], 'PRIVATE_SOURCE')
        self.runtime.unified.retrieve('Q', '吳郭魚')
        self.runtime.unified.retrieve('Q', '吳郭魚', 3)
        self.assertEqual(self.runtime.unified.calls, 3)

    def test_lru_evicts_and_runtime_identity_separates_corpus_versions(self):
        for question in ['one', 'two', 'three', 'one']:
            self.runtime.unified.retrieve(question, '魚')
        self.assertEqual(self.runtime.unified.calls, 4)
        other = Runtime(); other.unified.sha = 'new-corpus-sha'
        self.serving.attach(other).unified.retrieve('one', '魚')
        self.assertEqual(other.unified.calls, 1)

    def test_persistent_worker_preload_and_requests_share_a_thread(self):
        seen = []
        self.serving.preload(lambda: seen.append(threading.get_ident())).result()
        self.serving.submit(lambda: seen.append(threading.get_ident())).result()
        self.serving.submit(lambda: seen.append(threading.get_ident())).result()
        self.assertEqual(len(set(seen)), 1)
        self.assertTrue(self.serving.ready)
        row=json.loads(self.path.read_text().splitlines()[-1])
        self.assertEqual(row['event'], 'startup_preload')
        self.assertTrue(row['ready'])

    def test_failed_retrieval_is_not_cached(self):
        calls = []
        runtime = Runtime()
        def fail(*args): calls.append(1); raise ValueError('source unavailable')
        runtime.unified.retrieve = fail
        self.serving.attach(runtime)
        for _ in range(2):
            with self.assertRaises(ValueError): runtime.unified.retrieve('Q', '魚')
        self.assertEqual(len(calls), 2)

    def test_length_buckets_preserve_every_candidate_and_restore_score_order(self):
        class Inner:
            max_length = 512
            def tokenizer(self, passages, **kwargs): return {'input_ids': [list(p) for p in passages]}
            def score_pairs(self, query, passages):
                self.received = passages
                return [float(len(p)) for p in passages]
        inner = Inner(); reranker = LengthBucketReranker(inner)
        passages = ['longest', 'a', 'three', 'b']
        self.assertEqual(reranker.score_pairs('Q', passages), [7., 1., 5., 1.])
        self.assertEqual(inner.received, ['a', 'b', 'three', 'longest'])
        self.assertEqual(passages, ['longest', 'a', 'three', 'b'])


if __name__ == '__main__': unittest.main()
