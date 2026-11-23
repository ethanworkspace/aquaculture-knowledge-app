import { router } from 'expo-router';
import { useState } from 'react';
import { Pressable, Text, TextInput, View } from 'react-native';
import { species } from '../../domain';
import { useApp } from '../../store';
import { Body, Card, Screen, styles, Title } from '../../ui';
export default function SavedScreen() {
  const { saved } = useApp(); const [query, setQuery] = useState(''); const [fish, setFish] = useState('全部魚種');
  const filtered = saved.filter(s => (fish === '全部魚種' || s.job.species === fish) && `${s.job.question} ${s.note}`.includes(query.trim()));
  return <Screen><Title>留下有用的知識</Title><Body>原回答與個人筆記分開保存。</Body><TextInput accessibilityLabel="搜尋收藏" placeholder="搜尋問題或個人筆記" placeholderTextColor="#617e92" style={styles.input} value={query} onChangeText={setQuery} /><View style={styles.chips}>{['全部魚種', ...species].map(f => <Pressable accessibilityRole="button" accessibilityState={{ selected: fish === f }} key={f} style={[styles.chip, fish === f && styles.selected]} onPress={() => setFish(f)}><Text style={styles.body}>{f}</Text></Pressable>)}</View>{filtered.length ? filtered.map(s => <Pressable accessibilityRole="button" accessibilityLabel={s.job.question} key={s.id} onPress={() => router.push({ pathname: '/saved/[id]', params: { id: s.id } })}><Card><Text style={styles.small}>{s.job.species} · 示範收藏</Text><Text style={styles.label}>{s.job.question}</Text><Body>{s.note || '還沒有個人筆記，點選後新增。'}</Body></Card></Pressable>) : <Card><Body>{saved.length ? '沒有符合條件的收藏。' : '還沒有收藏。先完成一次問答，再收藏有引用來源的回答。'}</Body></Card>}</Screen>;
}
