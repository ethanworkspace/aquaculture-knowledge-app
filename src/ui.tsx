import React from 'react';
import { Image, ImageSourcePropType, KeyboardAvoidingView, Platform, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
export const art = {
  fish: require('../assets/website/aquaculture_fish_favicon_v1.png'),
  chat: require('../assets/website/watercolor_chat.png'),
  book: require('../assets/website/watercolor_knowledge.png'),
  history: require('../assets/website/watercolor_history.png'),
  ocean: require('../assets/website/ocean_watercolor_chibi_background.png'),
};
export function Artwork({ source, size = 42 }: { source: ImageSourcePropType; size?: number }) { return <Image source={source} style={{ width: size, height: size }} resizeMode="contain" accessible={false} />; }
export function Screen({ children }: { children: React.ReactNode }) {
  return <View style={styles.background}><Image source={art.ocean} style={styles.oceanTop} accessible={false} /><Image source={art.ocean} style={styles.oceanBottom} accessible={false} /><SafeAreaView style={styles.safe} edges={['left', 'right', 'bottom']}><KeyboardAvoidingView style={styles.safe} behavior={Platform.OS === 'ios' ? 'padding' : undefined}><ScrollView contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled"><Text style={styles.demo}>開發示範 · 未連接正式服務</Text>{children}</ScrollView></KeyboardAvoidingView></SafeAreaView></View>;
}
export function Title({ children }: { children: React.ReactNode }) { return <Text accessibilityRole="header" style={styles.title}>{children}</Text>; }
export function Body({ children }: { children: React.ReactNode }) { return <Text style={styles.body}>{children}</Text>; }
export function Card({ children }: { children: React.ReactNode }) { return <View style={styles.card}>{children}</View>; }
export function Action({ label, onPress, secondary = false, disabled = false }: { label: string; onPress: () => void; secondary?: boolean; disabled?: boolean }) { return <Pressable accessibilityRole="button" accessibilityState={{ disabled }} disabled={disabled} onPress={onPress} style={({ pressed }) => [styles.button, secondary && styles.secondary, (pressed || disabled) && styles.pressed]}><Text style={[styles.buttonText, secondary && styles.secondaryText]}>{label}</Text></Pressable>; }
export const styles = StyleSheet.create({
  background: { flex: 1, backgroundColor: '#dfEFFB', overflow: 'hidden' },
  oceanTop: { position: 'absolute', width: 800, height: 450, right: 0, top: 0, opacity: .6 },
  oceanBottom: { position: 'absolute', width: 800, height: 450, left: 0, bottom: 0, opacity: .65 },
  safe: { flex: 1 }, content: { padding: 22, gap: 18, width: '100%', maxWidth: 560, alignSelf: 'center', paddingBottom: 40 },
  demo: { color: '#466b84', fontSize: 12, textAlign: 'center' }, title: { fontSize: 26, fontWeight: '700', color: '#24445a', lineHeight: 38 },
  body: { color: '#3d5f76', fontSize: 16, lineHeight: 27 }, card: { backgroundColor: 'rgba(242,249,255,0.93)', borderColor: '#bfd8e9', borderWidth: 1, borderRadius: 18, padding: 18, gap: 12 },
  button: { minHeight: 48, backgroundColor: '#518bb1', borderRadius: 12, padding: 13, alignItems: 'center', justifyContent: 'center' },
  buttonText: { color: '#fff', fontSize: 16, fontWeight: '600' }, secondary: { borderWidth: 1, borderColor: '#accce3', backgroundColor: '#edf7ff' }, secondaryText: { color: '#345e7b' }, pressed: { opacity: .55 },
  input: { borderWidth: 1, borderColor: '#afcbdf', borderRadius: 12, backgroundColor: '#f6fbff', color: '#24445a', padding: 14, fontSize: 16, minHeight: 50 },
  textarea: { minHeight: 145, textAlignVertical: 'top' }, label: { fontSize: 16, fontWeight: '600', color: '#24445a' },
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 }, chip: { borderWidth: 1, borderColor: '#abcde4', borderRadius: 12, backgroundColor: '#edf7fe', paddingHorizontal: 13, paddingVertical: 10, minHeight: 44 }, selected: { backgroundColor: '#c4e1f5', borderColor: '#518bb1' },
  grid: { flexDirection: 'row', flexWrap: 'wrap', gap: 10 }, tile: { width: '30%', minHeight: 92, backgroundColor: '#e8f5fe', borderRadius: 15, borderWidth: 1, borderColor: '#bfd8e9', justifyContent: 'center', alignItems: 'center', gap: 4 },
  row: { minHeight: 58, paddingVertical: 14, borderBottomWidth: 1, borderBottomColor: '#c9deec', flexDirection: 'row', gap: 12, alignItems: 'center' }, small: { fontSize: 13, color: '#526e81', lineHeight: 22 }, error: { fontSize: 16, color: '#943e36', lineHeight: 26 },
});
