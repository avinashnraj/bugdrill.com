import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
} from 'react-native';
import { useSnippetStore } from '../stores/snippetStore';
import { Snippet } from '../types';

export default function PracticeScreen({ route, navigation }: any) {
  const { patternId, patternName } = route.params;
  const { currentSnippets, isLoading, fetchSnippetsByPattern } = useSnippetStore();
  const [selectedDifficulty, setSelectedDifficulty] = useState<string | undefined>();

  useEffect(() => {
    loadSnippets();
  }, [patternId, selectedDifficulty]);

  const loadSnippets = async () => {
    try {
      await fetchSnippetsByPattern(patternId, selectedDifficulty);
    } catch (error) {
      console.error('Failed to load snippets:', error);
    }
  };

  const getDifficultyColor = (difficulty: string) => {
    switch (difficulty) {
      case 'Beginner':
        return '#4caf50';
      case 'Medium':
        return '#ff9800';
      case 'Hard':
        return '#f44336';
      default:
        return '#666';
    }
  };

  const renderSnippet = ({ item }: { item: Snippet }) => (
    <TouchableOpacity
      style={styles.snippetCard}
      onPress={() => navigation.navigate('SnippetDetail', { snippetId: item.id })}
    >
      <View style={styles.snippetHeader}>
        <Text style={styles.snippetTitle}>{item.title}</Text>
        <View
          style={[
            styles.difficultyBadge,
            { backgroundColor: getDifficultyColor(item.difficulty) },
          ]}
        >
          <Text style={styles.difficultyText}>{item.difficulty}</Text>
        </View>
      </View>
      <Text style={styles.snippetDescription} numberOfLines={2}>
        {item.description}
      </Text>
      <Text style={styles.bugType}>Bug Type: {item.bug_type}</Text>
    </TouchableOpacity>
  );

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>{patternName}</Text>
        
        <View style={styles.filterRow}>
          <TouchableOpacity
            style={[styles.filterButton, !selectedDifficulty && styles.filterButtonActive]}
            onPress={() => setSelectedDifficulty(undefined)}
          >
            <Text style={[styles.filterText, !selectedDifficulty && styles.filterTextActive]}>
              All
            </Text>
          </TouchableOpacity>
          
          <TouchableOpacity
            style={[styles.filterButton, selectedDifficulty === 'Beginner' && styles.filterButtonActive]}
            onPress={() => setSelectedDifficulty('Beginner')}
          >
            <Text style={[styles.filterText, selectedDifficulty === 'Beginner' && styles.filterTextActive]}>
              Beginner
            </Text>
          </TouchableOpacity>
          
          <TouchableOpacity
            style={[styles.filterButton, selectedDifficulty === 'Medium' && styles.filterButtonActive]}
            onPress={() => setSelectedDifficulty('Medium')}
          >
            <Text style={[styles.filterText, selectedDifficulty === 'Medium' && styles.filterTextActive]}>
              Medium
            </Text>
          </TouchableOpacity>
          
          <TouchableOpacity
            style={[styles.filterButton, selectedDifficulty === 'Hard' && styles.filterButtonActive]}
            onPress={() => setSelectedDifficulty('Hard')}
          >
            <Text style={[styles.filterText, selectedDifficulty === 'Hard' && styles.filterTextActive]}>
              Hard
            </Text>
          </TouchableOpacity>
        </View>
      </View>

      {isLoading ? (
        <View style={styles.centered}>
          <ActivityIndicator size="large" color="#000" />
        </View>
      ) : currentSnippets.length === 0 ? (
        <View style={styles.centered}>
          <Text style={styles.emptyText}>No snippets found</Text>
        </View>
      ) : (
        <FlatList
          data={currentSnippets}
          renderItem={renderSnippet}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.list}
        />
      )}
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
  header: {
    padding: 20,
    paddingTop: 60,
    backgroundColor: '#f9f9f9',
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#000',
    marginBottom: 16,
  },
  filterRow: {
    flexDirection: 'row',
    gap: 8,
  },
  filterButton: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: '#e0e0e0',
  },
  filterButtonActive: {
    backgroundColor: '#000',
  },
  filterText: {
    fontSize: 14,
    color: '#666',
    fontWeight: '500',
  },
  filterTextActive: {
    color: '#fff',
  },
  list: {
    padding: 16,
  },
  snippetCard: {
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
  },
  snippetHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 8,
  },
  snippetTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#000',
    flex: 1,
    marginRight: 8,
  },
  difficultyBadge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 4,
  },
  difficultyText: {
    fontSize: 12,
    color: '#fff',
    fontWeight: '600',
  },
  snippetDescription: {
    fontSize: 14,
    color: '#666',
    marginBottom: 8,
    lineHeight: 20,
  },
  bugType: {
    fontSize: 12,
    color: '#999',
    fontStyle: 'italic',
  },
  emptyText: {
    fontSize: 16,
    color: '#999',
  },
});
