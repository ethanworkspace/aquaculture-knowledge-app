import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { AppProvider } from '../store';
export default function RootLayout() {
  return <AppProvider><StatusBar style="dark" /><Stack screenOptions={{ headerStyle: { backgroundColor: '#e4f2fc' }, headerTintColor: '#24445a', contentStyle: { backgroundColor: '#dfEFFB' } }}><Stack.Screen name="index" options={{ headerShown: false }} /><Stack.Screen name="(tabs)" options={{ headerShown: false }} /><Stack.Screen name="answer/[id]" options={{ title: '回答詳情' }} /><Stack.Screen name="source/[id]" options={{ title: '引用來源' }} /><Stack.Screen name="saved/[id]" options={{ title: '收藏與個人筆記' }} /><Stack.Screen name="history" options={{ title: '問答紀錄' }} /></Stack></AppProvider>;
}
