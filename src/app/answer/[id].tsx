import { router, useLocalSearchParams } from 'expo-router';
import { ActivityIndicator, Text } from 'react-native';
import { useState } from 'react';
import { statusLabels } from '../../domain';
import { useApp } from '../../store';
import { Action, Body, Card, Screen, styles, Title } from '../../ui';
export default function AnswerScreen() {
  const { id } = useLocalSearchParams<{ id: string }>(); const app = useApp(); const [reported, setReported] = useState(false);
  const job = app.jobs.find(j => j.id === id) || app.saved.find(s => s.id === id)?.job;
  if (!app.signedIn) return <Screen><Body>請先進入示範帳號。</Body><Action label="返回登入" onPress={() => router.replace('/')} /></Screen>;
  if (!job) return <Screen><Body>找不到這筆示範紀錄。重新啟動後資料會重設。</Body><Action label="返回首頁" onPress={() => router.replace('/(tabs)')} /></Screen>;
  const saved = app.saved.some(s => s.id === id);
  return <Screen><Text style={styles.small}>{job.species} · M2 · 示範資料</Text><Title>{job.question}</Title>{job.state === 'RUNNING' ? <Card><ActivityIndicator size="large" color="#518bb1" /><Body>正在模擬處理。你可以離開，稍後從問答紀錄查看。本畫面不提供完成時間預估。</Body></Card> : job.state === 'FAILED' ? <Card><Text style={styles.error}>{job.error}</Text></Card> : job.answer ? <><Text style={styles.label}>{statusLabels[job.answer.status]}</Text><Card><Body>{job.answer.text}</Body></Card>{job.answer.missing.map(m => <Body key={m}>尚需補充：{m}</Body>)}{job.answer.sources.length ? <><Action secondary label="查看引用來源（示範）" onPress={() => router.push({ pathname: '/source/[id]', params: { id } })} /><Action label={saved ? '已收藏 · 查看個人筆記' : '收藏這則回答'} onPress={() => { app.save(job); router.push({ pathname: '/saved/[id]', params: { id } }); }} /></> : <Body>本次沒有可顯示的引用來源。</Body>}<Action secondary label={reported ? '已完成回報操作示範，未傳送資料' : '模擬回報回答有疑問'} disabled={reported} onPress={() => setReported(true)} /></> : null}<Action secondary label="補充條件，重新提問" onPress={() => router.push({ pathname: '/(tabs)/ask', params: { question: job.question, fish: job.species, seed: String(Date.now()) } })} /></Screen>;
}
