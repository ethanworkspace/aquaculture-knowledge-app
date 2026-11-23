import { router } from 'expo-router';
import { Pressable, Text, View } from 'react-native';
import { questions, species } from '../../domain';
import { Action, art, Artwork, Body, Card, Screen, styles, Title } from '../../ui';
export default function Home() {
  return <Screen><Body>你好，養殖夥伴</Body><Title>今天想了解什麼？</Title><Card><Artwork source={art.chat} size={72} /><Title>從一個問題開始。</Title><Body>找到有來源的知識，留下自己的觀察。</Body><Action label="開始提問" onPress={() => router.push('/(tabs)/ask')} /></Card><Text style={styles.label}>從養殖魚種出發</Text><View style={styles.grid}>{species.map(fish => <Pressable accessibilityRole="button" accessibilityLabel={fish} key={fish} style={styles.tile} onPress={() => router.push({ pathname: '/(tabs)/ask', params: { fish, seed: String(Date.now()) } })}><Artwork source={art.fish} /><Text style={styles.body}>{fish}</Text></Pressable>)}</View><Card><Text style={styles.label}>常見問題 · 畫面示例</Text>{questions.slice(0, 2).map(q => <Pressable accessibilityRole="button" key={q.text} style={styles.row} onPress={() => router.push({ pathname: '/(tabs)/ask', params: { question: q.text, fish: q.species, seed: String(Date.now()) } })}><Artwork source={art.chat} size={34} /><View style={{ flex: 1 }}><Text style={styles.body}>{q.text}</Text><Text style={styles.small}>{q.topic}</Text></View></Pressable>)}</Card></Screen>;
}
