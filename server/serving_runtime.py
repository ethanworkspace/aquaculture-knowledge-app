"""Serving-only scheduling, exact retrieval cache and private phase timings.

The frozen retriever, candidate count, model, precision and answer guard are reused.
There is no answer cache: every new request still invokes the selected generator.
"""
from __future__ import annotations

import copy
import json
import logging
import os
import threading
import time
from collections import OrderedDict
from concurrent.futures import ThreadPoolExecutor
from contextlib import contextmanager
from pathlib import Path


class LengthBucketReranker:
    """Reduce batch padding, then restore every score to its original position."""
    def __init__(self, inner):
        self.inner = inner

    def __getattr__(self, name):
        return getattr(self.inner, name)

    def score_pairs(self, query, passages):
        if not passages:
            return []
        tokens = self.inner.tokenizer(
            list(passages), add_special_tokens=False, padding=False,
            truncation=True, max_length=self.inner.max_length,
        )['input_ids']
        order = sorted(range(len(passages)), key=lambda i: (len(tokens[i]), i))
        scored = self.inner.score_pairs(query, [passages[i] for i in order])
        if len(scored) != len(passages):
            raise RuntimeError('Reranker score count differs from candidate count')
        restored = [0.0] * len(passages)
        for index, score in zip(order, scored):
            restored[index] = score
        return restored


class ServingRuntime:
    def __init__(self, metrics_file, *, cpu_threads=10, cache_entries=16, configure=None):
        if cpu_threads < 1 or not 0 <= cache_entries <= 128:
            raise ValueError('Invalid serving configuration')
        self.cpu_threads = min(cpu_threads, os.cpu_count() or 1)
        self.cache_entries = cache_entries
        self.metrics_file = Path(metrics_file)
        self.local = threading.local()
        self.cache = OrderedDict()
        self.cache_lock = threading.RLock()
        self.setup_lock = threading.Lock()
        self.write_lock = threading.Lock()
        self.torch_configured = False
        self.ready = False
        self.prepare_seconds = None
        self.started = time.perf_counter()
        self.configure = configure or self.configure_thread
        # Apply before the lazy import of PyTorch/NumPy; worker setup also applies
        # the intra-op setting explicitly on the persistent inference thread.
        if configure is None:
            os.environ['OMP_NUM_THREADS'] = str(self.cpu_threads)
            os.environ['MKL_NUM_THREADS'] = str(self.cpu_threads)
            os.environ['TOKENIZERS_PARALLELISM'] = 'false'
        self.executor = ThreadPoolExecutor(
            max_workers=1, thread_name_prefix='marine-inference', initializer=self.configure,
        )

    def configure_thread(self):
        if getattr(self.local, 'configured', False):
            return
        import torch
        with self.setup_lock:
            if not self.torch_configured:
                torch.set_num_interop_threads(1)
                self.torch_configured = True
        torch.set_num_threads(self.cpu_threads)
        self.local.configured = True

    def submit(self, fn, *args):
        return self.executor.submit(fn, *args)

    def preload(self, fn):
        def run():
            started = time.perf_counter()
            try:
                fn()
                self.ready = True
            except Exception:
                logging.exception('Serving preload failed; a later request can retry')
            finally:
                self.prepare_seconds = time.perf_counter() - started
                self.write_metrics({'event': 'startup_preload', 'ready': self.ready,
                    'prepare_seconds': self.prepare_seconds, 'startup_ready_seconds': time.perf_counter() - self.started,
                    'cpu_threads': self.cpu_threads})
                logging.info('Serving preparation completed: ready=%s seconds=%.3f', self.ready, self.prepare_seconds)
        return self.submit(run)

    @contextmanager
    def phase(self, name):
        started = time.perf_counter()
        try:
            yield
        finally:
            current = getattr(self.local, 'measurement', None)
            if current is not None:
                current[name] = current.get(name, 0.0) + time.perf_counter() - started

    def measure(self, request_id, fn):
        current = {'request_id': request_id, 'cpu_threads': self.cpu_threads, 'retrieval_cache_hit': False}
        self.local.measurement = current
        started = time.perf_counter()
        try:
            record = fn()
            current['completed'] = True
            current['model_id'] = record.get('model_id')
            current['model_digest'] = record.get('model_digest')
            return record
        finally:
            current['total_seconds'] = time.perf_counter() - started
            self.local.measurement = None
            # Only opaque request ID and numerical timings; never prompts,
            # questions, retrieved text, answer text, tokens or credentials.
            self.write_metrics(current)

    def write_metrics(self, record):
        try:
            self.metrics_file.parent.mkdir(parents=True, exist_ok=True)
            with self.write_lock, self.metrics_file.open('a', encoding='utf-8') as stream:
                stream.write(json.dumps(record, sort_keys=True) + '\n')
        except OSError:
            logging.warning('Could not persist serving timing summary')

    def attach(self, runtime):
        retriever = runtime.unified
        retrieve, rerank, generate = retriever.retrieve, retriever.rerank, runtime.call
        identity = (
            retriever.manifest['version'], retriever.sha,
            getattr(runtime, 'policy_version', ''),
            str(getattr(retriever, 'reranker_path', '')),
        )

        def cached_retrieve(question, species, limit=5):
            key = (*identity, question, species, limit)
            with self.phase('retrieval_seconds'):
                with self.cache_lock:
                    cached = self.cache.get(key)
                    if cached is not None:
                        self.cache.move_to_end(key)
                        current = getattr(self.local, 'measurement', None)
                        if current is not None:
                            current['retrieval_cache_hit'] = True
                        return copy.deepcopy(cached)
                result = retrieve(question, species, limit)
                if self.cache_entries:
                    with self.cache_lock:
                        self.cache[key] = copy.deepcopy(result)
                        self.cache.move_to_end(key)
                        while len(self.cache) > self.cache_entries:
                            self.cache.popitem(last=False)
                return result

        def timed_rerank(*args, **kwargs):
            with self.phase('rerank_seconds'):
                return rerank(*args, **kwargs)

        def timed_generate(*args, **kwargs):
            with self.phase('generation_and_validation_seconds'):
                return generate(*args, **kwargs)

        retriever.retrieve, retriever.rerank, runtime.call = cached_retrieve, timed_rerank, timed_generate
        return runtime

    @staticmethod
    def preload_models(runtime, generation_options):
        from src.evaluation.reranker_runtime import CrossEncoderRuntime
        from src.unified_rag_v4.common import embed
        import requests
        retriever = runtime.unified
        if retriever.reranker is None:
            retriever.reranker = CrossEncoderRuntime(
                retriever.reranker_path, device='cpu', max_length=512, batch_size=4,
            )
        if not isinstance(retriever.reranker, LengthBucketReranker):
            retriever.reranker = LengthBucketReranker(retriever.reranker)
        runtime.runtime.reranker = retriever.reranker
        embed(['養殖知識服務啟動'])
        identity = runtime.runtime.model_identity('M2')
        # Empty prompt is Ollama's documented model-load operation, not a
        # fabricated question or generated answer. Reuse the existing options.
        response = requests.post('http://127.0.0.1:11434/api/generate', json={
            'model': identity['tag'], 'prompt': '', 'stream': False,
            'keep_alive': '30m', 'options': dict(generation_options),
        }, timeout=(15, 120))
        response.raise_for_status()
        if response.json().get('done') is not True:
            raise RuntimeError('M2 preload did not complete')

    def close(self):
        self.executor.shutdown(wait=True)
