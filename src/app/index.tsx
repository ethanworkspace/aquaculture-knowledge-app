import { Redirect, router } from 'expo-router';
import { View } from 'react-native';
import { useApp } from '../store';
import { Action, art, Artwork, Body, Card, Screen, Title } from '../ui';
export default function Login() {
  const app = useApp();
  if (app.signedIn) return <Redirect href="/(tabs)" />;
  return <Screen><View style={{ alignItems: 'center', marginTop: 35 }}><Artwork source={art.fish} size={112} /></View><Title>養殖漁業知識平台</Title><Body>把問答、引用來源與自己的筆記，帶到每一次養殖觀察中。</Body><Card><Body>目前提供開發示範，所有回答與來源均為占位資料。此版本不收集真實帳號密碼。</Body></Card><Action label="進入示範帳號" onPress={() => { app.login(); router.replace('/(tabs)'); }} /><Body>示範資料只保留在本次使用期間。正式登入與同步服務將於後續接入。</Body></Screen>;
}
