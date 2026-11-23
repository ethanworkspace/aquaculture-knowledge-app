import { router } from 'expo-router';
import { useState } from 'react';
import { Pressable, Text, View } from 'react-native';
import { Scenario } from '../../domain';
import { useApp } from '../../store';
import { Action, Body, Card, Screen, styles, Title } from '../../ui';
const cases: [Scenario, string][] = [['grounded', '有據回答'], ['partial', '部分資訊'], ['insufficient', '證據不足'], ['invalid', '驗證未通過'], ['offline', '離線'], ['busy', '忙碌'], ['failed', '任務失敗']];
export default function Me() {
  const app = useApp(); const [confirm, setConfirm] = useState(false); const [message, setMessage] = useState('');
  return <Screen><Title>示範養殖夥伴</Title><Card><Body>你的個人知識工作區。正式帳號隔離與雲端保存尚未接入。</Body><Action secondary label={`問答紀錄 · ${app.jobs.length} 筆`} onPress={() => router.push('/history')} /><Body>服務狀態：示範模式，未連接正式服務。</Body></Card><Text style={styles.label}>開發用問答情境</Text><View style={styles.chips}>{cases.map(([key, label]) => <Pressable accessibilityRole="button" accessibilityState={{ selected: key === app.scenario }} key={key} style={[styles.chip, key === app.scenario && styles.selected]} onPress={() => app.setScenario(key)}><Text style={styles.body}>{label}</Text></Pressable>)}</View><Action secondary label={confirm ? '確認清除本次示範資料' : '清除示範資料'} onPress={() => { if (!confirm) { setConfirm(true); return; } app.clear(); setConfirm(false); setMessage('已清除示範紀錄、收藏與筆記。'); }} />{confirm ? <Action secondary label="取消清除" onPress={() => setConfirm(false)} /> : null}{message ? <Body>{message}</Body> : null}<Action secondary label="登出示範帳號" onPress={() => { app.logout(); router.replace('/'); }} /></Screen>;
}
