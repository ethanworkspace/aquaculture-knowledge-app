import { Redirect, Tabs } from 'expo-router';
import { useApp } from '../../store';
import { art, Artwork } from '../../ui';
export default function TabLayout() {
  const { signedIn } = useApp();
  if (!signedIn) return <Redirect href="/" />;
  return <Tabs screenOptions={{ headerStyle: { backgroundColor: '#e4f2fc' }, headerTintColor: '#24445a', tabBarActiveTintColor: '#345f7d', tabBarStyle: { backgroundColor: '#e1f1fc' }, tabBarItemStyle: { paddingVertical: 4 } }}><Tabs.Screen name="index" options={{ title: '首頁', headerTitle: '養殖漁業知識平台', tabBarIcon: () => <Artwork source={art.fish} size={30} /> }} /><Tabs.Screen name="ask" options={{ title: '問答', headerTitle: '知識問答', tabBarIcon: () => <Artwork source={art.chat} size={30} /> }} /><Tabs.Screen name="saved" options={{ title: '收藏', headerTitle: '我的收藏', tabBarIcon: () => <Artwork source={art.book} size={30} /> }} /><Tabs.Screen name="me" options={{ title: '我的', tabBarIcon: () => <Artwork source={art.history} size={30} /> }} /></Tabs>;
}
