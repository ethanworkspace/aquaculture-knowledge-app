import { useLocalSearchParams } from 'expo-router';
import { useApp } from '../../store';
import { Body, Card, Screen, Title } from '../../ui';
export default function SourceScreen() {
  const { id } = useLocalSearchParams<{ id: string }>(); const app = useApp();
  const job = app.signedIn ? app.jobs.find(j => j.id === id) || app.saved.find(s => s.id === id)?.job : undefined;
  return <Screen><Title>每個重點，都能追溯。</Title><Body>目前為來源畫面占位，不代表真實文件或養殖依據。</Body>{job?.answer?.sources.length ? job.answer.sources.map(s => <Card key={s.id}><Title>{s.title}</Title><Body>{s.locator}</Body><Body>{s.quote}</Body></Card>) : <Body>沒有可提供的來源。正式版不會虛構頁碼或文件名稱。</Body>}</Screen>;
}
