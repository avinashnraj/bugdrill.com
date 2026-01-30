import React, { useEffect } from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
} from 'react-native';
import { useSnippetStore } from '../stores/snippetStore';
import { PatternCategory } from '../types';

export default function PatternsScreen({ navigation }: any) {
  const { patterns, isLoading, fetchPatterns } = useSnippetStore();

  useEffect(() => {
    loadPatterns();
  }, []);

  const loadPatterns = async () => {
    try {
      await fetchPatterns();
    } catch (error) {
      console.error('Failed to load patterns:', error);
    }
  };

  const renderPattern = ({ item }: { item: PatternCategory }) => (
    <TouchableOpacity
      style={styles.patternCard}
      onPress={() => navigation.navigate('Practice', { patternId: item.id, patternName: item.name })}
    >
      <View style={styles.patternHeader}>
        <Text style={styles.patternName}>{item.name}</Text>
        <Text style={styles.arrow}>→</Text>
      </View>
      <Text style={styles.patternDescription}>{item.description}</Text>
    </TouchableOpacity>
  );

  if (isLoading && patterns.length === 0) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color="#000" />
        <Text style={styles.loadingText}>Loading patterns...</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Coding Patterns</Text>
        <Text style={styles.subtitle}>Master patterns by fixing bugs</Text>
      </View>

      <FlatList
        data={patterns}
        renderItem={renderPattern}
        keyExtractor={(item) => item.id.toString()}
        contentContainerStyle={styles.list}
        refreshing={isLoading}
        onRefresh={loadPatterns}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 12,
    color: '#666',
    fontSize: 14,
  },
  header: {
    padding: 24,
    paddingTop: 60,
    backgroundColor: '#f9f9f9',
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#000',
    marginBottom: 4,
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
  },
  list: {
    padding: 16,
    gap: 12,
  },
  patternCard: {
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 12,
    padding: 20,
    marginBottom: 12,
  },
  patternHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  patternName: {
    fontSize: 20,
    fontWeight: '600',
    color: '#000',
  },
  arrow: {
    fontSize: 24,
    color: '#666',
  },
  patternDescription: {
    fontSize: 14,
    color: '#666',
    lineHeight: 20,
  },
});
