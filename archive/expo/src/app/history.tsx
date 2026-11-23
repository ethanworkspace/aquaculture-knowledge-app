import { router } from 'expo-router';
import { Pressable, Text } from 'react-native';
import { useApp } from '../store';
import { Body, Card, Screen, styles, Title } from '../ui';
export default function History() {
  const app = useApp(); const jobs = app.signedIn ? app.jobs : [];
  return <Screen><Title>回顧每一次提問</Title><Body>本次使用期間共 {jobs.length} 筆示範紀錄。</Body>{jobs.length ? jobs.map(j => <Pressable accessibilityRole="button" accessibilityLabel={j.question} key={j.id} onPress={() => router.push({ pathname: '/answer/[id]', params: { id: j.id } })}><Card><Text style={styles.small}>{new Date(j.at).toLocaleString('zh-TW')} · {j.state === 'RUNNING' ? '處理中' : j.state === 'FAILED' ? '未完成' : '已完成'}</Text><Body>{j.question}</Body></Card></Pressable>) : <Body>從你的第一個問題開始。</Body>}</Screen>;
}
