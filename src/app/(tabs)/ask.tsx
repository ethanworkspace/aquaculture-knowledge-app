import { router, useLocalSearchParams } from 'expo-router';
import { useState } from 'react';
import { Pressable, Text, TextInput, View } from 'react-native';
import { species } from '../../domain';
import { useApp } from '../../store';
import { Action, Body, Screen, styles, Title } from '../../ui';
export default function Ask() {
  const params = useLocalSearchParams<{ question?: string; fish?: string; seed?: string }>();
  return <AskForm key={params.seed || 'initial'} initialQuestion={params.question || ''} initialFish={params.fish || '全部魚種'} />;
}
function AskForm({ initialQuestion, initialFish }: { initialQuestion: string; initialFish: string }) {
  const [question, setQuestion] = useState(initialQuestion); const [fish, setFish] = useState(initialFish); const [error, setError] = useState('');
  const app = useApp();
  return <Screen><Title>今天想問什麼？</Title><Body>補充魚種與觀察情況，讓問題更完整。</Body><Text style={styles.label}>養殖魚種</Text><View style={styles.chips}>{['全部魚種', ...species].map(f => <Pressable accessibilityRole="button" accessibilityState={{ selected: f === fish }} style={[styles.chip, fish === f && styles.selected]} key={f} onPress={() => setFish(f)}><Text style={styles.body}>{f}</Text></Pressable>)}</View><Text style={styles.label}>你的問題</Text><TextInput accessibilityLabel="你的問題" style={[styles.input, styles.textarea]} value={question} onChangeText={setQuestion} multiline maxLength={2000} placeholder="例如：虱目魚遇到寒流，應先確認哪些資料？" placeholderTextColor="#617e92" /><Text style={styles.small}>最多 2,000 字 · 預設 M2 · 開發示範</Text>{error ? <Text accessibilityRole="alert" style={styles.error}>{error}</Text> : null}<Action label="送出問題" onPress={() => { try { const id = app.submit(question, fish); setError(''); router.push({ pathname: '/answer/[id]', params: { id } }); } catch (e) { setError(e instanceof Error ? e.message : '無法送出問題'); } }} /><Body>目前不會呼叫正式模型。測試情境可在「我的」切換。</Body></Screen>;
}
