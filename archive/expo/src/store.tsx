import React, { createContext, useContext, useRef, useState } from 'react';
import { Job, SavedAnswer, Scenario, validateQuestion } from './domain';
import { mockService } from './services/mock';

function useAppState() {
  const [signedIn, setSignedIn] = useState(false);
  const [jobs, setJobs] = useState<Job[]>([]);
  const [saved, setSaved] = useState<SavedAnswer[]>([]);
  const [scenario, setScenario] = useState<Scenario>('grounded');
  const busy = useRef(false);
  const epoch = useRef(0);
  const serial = useRef(0);
  function submit(question: string, fish: string) {
    const error = validateQuestion(question);
    if (error) throw new Error(error);
    if (busy.current) throw new Error('已有一筆示範問答處理中，請先查看紀錄。');
    busy.current = true;
    const version = epoch.current;
    const job: Job = { id: `demo-${Date.now()}-${++serial.current}`, question: question.trim(), species: fish, at: new Date().toISOString(), state: 'RUNNING' };
    setJobs(previous => [job, ...previous]);
    void mockService.complete(job, scenario).then(answer => {
      if (version === epoch.current) setJobs(previous => previous.map(j => j.id === job.id ? { ...j, state: 'DONE', answer } : j));
    }).catch((reason: unknown) => {
      if (version === epoch.current) setJobs(previous => previous.map(j => j.id === job.id ? { ...j, state: 'FAILED', error: reason instanceof Error ? reason.message : '問答未完成。' } : j));
    }).finally(() => { if (version === epoch.current) busy.current = false; });
    return job.id;
  }
  function save(job: Job) {
    if (!job.answer?.sources.length) return;
    setSaved(previous => previous.some(s => s.id === job.id) ? previous : [{ id: job.id, job: JSON.parse(JSON.stringify(job)) as Job, note: '' }, ...previous]);
  }
  function clear() { epoch.current++; busy.current = false; setJobs([]); setSaved([]); }
  function logout() { clear(); setSignedIn(false); }
  return { signedIn, login: () => setSignedIn(true), logout, jobs, saved, scenario, setScenario, submit, save, clear,
    updateNote: (id: string, note: string) => setSaved(p => p.map(s => s.id === id ? { ...s, note } : s)),
    removeSaved: (id: string) => setSaved(p => p.filter(s => s.id !== id)),
  };
}
const AppContext = createContext<ReturnType<typeof useAppState> | null>(null);
export function AppProvider({ children }: { children: React.ReactNode }) { const value = useAppState(); return <AppContext.Provider value={value}>{children}</AppContext.Provider>; }
export function useApp() { const state = useContext(AppContext); if (!state) throw new Error('AppProvider is required'); return state; }
