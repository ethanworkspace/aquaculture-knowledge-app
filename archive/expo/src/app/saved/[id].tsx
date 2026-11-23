import { router, useLocalSearchParams } from 'expo-router';
import { useState } from 'react';
import { Text, TextInput } from 'react-native';
import { useApp } from '../../store';
import { Action, Body, Card, Screen, styles, Title } from '../../ui';
export default function NoteScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  return <NoteForm key={id} />;
}
function NoteForm() {
  const { id } = useLocalSearchParams<{ id: string }>(); const app = useApp(); const item = app.signedIn ? app.saved.find(s => s.id === id) : undefined;
  const [note, setNote] = useState(item?.note || ''); const [message, setMessage] = useState(''); const [confirm, setConfirm] = useState(false);
  if (!item) return <Screen><Body>這則收藏不存在或已移除。</Body></Screen>;
  return <Screen><Title>{item.job.question}</Title><Card><Text style={styles.label}>原回答快照 · 示範</Text><Body>{item.job.answer?.text}</Body><Action secondary label="查看回答與來源" onPress={() => router.push({ pathname: '/answer/[id]', params: { id } })} /></Card><Text style={styles.label}>我的筆記</Text><TextInput accessibilityLabel="我的筆記" multiline maxLength={8000} style={[styles.input, styles.textarea]} value={note} onChangeText={setNote} placeholder="記下自己的觀察與待查事項" placeholderTextColor="#617e92" /><Body>個人筆記不會改寫原回答，也不會成為知識庫證據。</Body><Action label="儲存示範筆記" onPress={() => { app.updateNote(id, note); setMessage('已儲存到本次使用期間。'); }} />{message ? <Body>{message}</Body> : null}<Action secondary label={confirm ? '確認取消收藏與筆記' : '取消收藏'} onPress={() => { if (!confirm) { setConfirm(true); return; } app.removeSaved(id); router.replace('/(tabs)/saved'); }} />{confirm ? <Action secondary label="保留收藏" onPress={() => setConfirm(false)} /> : null}</Screen>;
}
