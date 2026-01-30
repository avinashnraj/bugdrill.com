import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  Alert,
  Platform,
} from 'react-native';
import { useSnippetStore } from '../stores/snippetStore';
import { snippetService } from '../services/snippets';
import { ExecuteCodeResponse } from '../types';

export default function SnippetDetailScreen({ route }: any) {
  const { snippetId } = route.params;
  const { currentSnippet, isLoading, fetchSnippet } = useSnippetStore();
  const [code, setCode] = useState('');
  const [isExecuting, setIsExecuting] = useState(false);
  const [executionResult, setExecutionResult] = useState<ExecuteCodeResponse | null>(null);
  const [hintsRevealed, setHintsRevealed] = useState<number>(0);

  useEffect(() => {
    loadSnippet();
  }, [snippetId]);

  useEffect(() => {
    if (currentSnippet) {
      setCode(currentSnippet.buggy_code);
    }
  }, [currentSnippet]);

  const loadSnippet = async () => {
    try {
      await fetchSnippet(snippetId);
    } catch (error) {
      Alert.alert('Error', 'Failed to load snippet');
    }
  };

  const handleRunCode = async () => {
    if (!currentSnippet) return;

    setIsExecuting(true);
    try {
      const result = await snippetService.executeCode(
        snippetId,
        code,
        currentSnippet.language
      );
      setExecutionResult(result);
    } catch (error) {
      Alert.alert('Error', 'Failed to execute code');
    } finally {
      setIsExecuting(false);
    }
  };

  const handleSubmit = async () => {
    if (!currentSnippet) return;

    setIsExecuting(true);
    try {
      const result = await snippetService.submitSolution(
        snippetId,
        code,
        currentSnippet.language
      );
      setExecutionResult(result);

      if (result.is_correct) {
        Alert.alert('🎉 Success!', 'Your solution is correct!');
      } else {
        Alert.alert('Try Again', 'Your solution has some issues. Check the test results.');
      }
    } catch (error) {
      Alert.alert('Error', 'Failed to submit solution');
    } finally {
      setIsExecuting(false);
    }
  };

  const handleGetHint = async () => {
    if (!currentSnippet || hintsRevealed >= 3) return;

    const nextTier = (hintsRevealed + 1) as 1 | 2 | 3;
    try {
      const { hint } = await snippetService.getHint(snippetId, nextTier);
      setHintsRevealed(nextTier);
      Alert.alert(`Hint ${nextTier}`, hint);
    } catch (error) {
      Alert.alert('Error', 'Failed to get hint');
    }
  };

  if (isLoading || !currentSnippet) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color="#000" />
      </View>
    );
  }

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>{currentSnippet.title}</Text>
        <View style={styles.badgeRow}>
          <View style={styles.badge}>
            <Text style={styles.badgeText}>{currentSnippet.difficulty}</Text>
          </View>
          <View style={styles.badge}>
            <Text style={styles.badgeText}>{currentSnippet.language}</Text>
          </View>
        </View>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Problem Description</Text>
        <Text style={styles.description}>{currentSnippet.description}</Text>
      </View>

      <View style={styles.section}>
        <View style={styles.sectionHeader}>
          <Text style={styles.sectionTitle}>Buggy Code</Text>
          <TouchableOpacity
            style={styles.hintButton}
            onPress={handleGetHint}
            disabled={hintsRevealed >= 3}
          >
            <Text style={styles.hintButtonText}>
              💡 Hint ({hintsRevealed}/3)
            </Text>
          </TouchableOpacity>
        </View>
        
        <TextInput
          style={styles.codeEditor}
          value={code}
          onChangeText={setCode}
          multiline
          textAlignVertical="top"
          autoCapitalize="none"
          autoCorrect={false}
          spellCheck={false}
        />
      </View>

      <View style={styles.buttonRow}>
        <TouchableOpacity
          style={[styles.runButton, isExecuting && styles.buttonDisabled]}
          onPress={handleRunCode}
          disabled={isExecuting}
        >
          <Text style={styles.buttonText}>▶ Run</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.submitButton, isExecuting && styles.buttonDisabled]}
          onPress={handleSubmit}
          disabled={isExecuting}
        >
          <Text style={styles.buttonText}>✓ Submit</Text>
        </TouchableOpacity>
      </View>

      {executionResult && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Test Results</Text>
          <View
            style={[
              styles.resultCard,
              { backgroundColor: executionResult.is_correct ? '#e8f5e9' : '#ffebee' },
            ]}
          >
            <Text style={styles.resultHeader}>
              {executionResult.is_correct ? '✓ All tests passed!' : '✗ Some tests failed'}
            </Text>
            <Text style={styles.resultTime}>
              Execution time: {executionResult.total_time_ms}ms
            </Text>

            {executionResult.test_results.map((test, index) => (
              <View key={index} style={styles.testCase}>
                <Text style={styles.testCaseHeader}>
                  Test Case {test.test_case}: {test.passed ? '✓' : '✗'}
                </Text>
                <Text style={styles.testDetail}>Expected: {JSON.stringify(test.expected)}</Text>
                <Text style={styles.testDetail}>Got: {JSON.stringify(test.actual)}</Text>
              </View>
            ))}

            {executionResult.stdout && (
              <View style={styles.output}>
                <Text style={styles.outputTitle}>Output:</Text>
                <Text style={styles.outputText}>{executionResult.stdout}</Text>
              </View>
            )}

            {executionResult.stderr && (
              <View style={styles.output}>
                <Text style={styles.outputTitle}>Errors:</Text>
                <Text style={styles.errorText}>{executionResult.stderr}</Text>
              </View>
            )}
          </View>
        </View>
      )}
    </ScrollView>
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
    fontSize: 24,
    fontWeight: 'bold',
    color: '#000',
    marginBottom: 12,
  },
  badgeRow: {
    flexDirection: 'row',
    gap: 8,
  },
  badge: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    backgroundColor: '#e0e0e0',
    borderRadius: 4,
  },
  badgeText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#666',
  },
  section: {
    padding: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#000',
    marginBottom: 12,
  },
  description: {
    fontSize: 14,
    color: '#666',
    lineHeight: 22,
  },
  hintButton: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    backgroundColor: '#fff3cd',
    borderRadius: 4,
  },
  hintButtonText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#856404',
  },
  codeEditor: {
    minHeight: 300,
    backgroundColor: '#f5f5f5',
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    padding: 12,
    fontSize: 14,
    lineHeight: 20,
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
  },
  buttonRow: {
    flexDirection: 'row',
    padding: 20,
    gap: 12,
  },
  runButton: {
    flex: 1,
    height: 48,
    backgroundColor: '#2196f3',
    borderRadius: 8,
    justifyContent: 'center',
    alignItems: 'center',
  },
  submitButton: {
    flex: 1,
    height: 48,
    backgroundColor: '#4caf50',
    borderRadius: 8,
    justifyContent: 'center',
    alignItems: 'center',
  },
  buttonDisabled: {
    backgroundColor: '#999',
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  resultCard: {
    padding: 16,
    borderRadius: 8,
  },
  resultHeader: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 8,
  },
  resultTime: {
    fontSize: 14,
    color: '#666',
    marginBottom: 16,
  },
  testCase: {
    marginBottom: 12,
    paddingBottom: 12,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(0,0,0,0.1)',
  },
  testCaseHeader: {
    fontSize: 14,
    fontWeight: '600',
    marginBottom: 4,
  },
  testDetail: {
    fontSize: 12,
    color: '#666',
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
  },
  output: {
    marginTop: 12,
  },
  outputTitle: {
    fontSize: 14,
    fontWeight: '600',
    marginBottom: 4,
  },
  outputText: {
    fontSize: 12,
    color: '#666',
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
  },
  errorText: {
    fontSize: 12,
    color: '#d32f2f',
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
  },
});
