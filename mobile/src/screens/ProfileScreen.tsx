import React, { useEffect } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  ActivityIndicator,
} from 'react-native';
import { useAuthStore } from '../stores/authStore';
import { useSnippetStore } from '../stores/snippetStore';

export default function ProfileScreen({ navigation }: any) {
  const { user, logout, isLoading: authLoading } = useAuthStore();
  const { userProgress, fetchUserProgress, isLoading: progressLoading } = useSnippetStore();

  useEffect(() => {
    loadProgress();
  }, []);

  const loadProgress = async () => {
    try {
      await fetchUserProgress();
    } catch (error) {
      console.error('Failed to load progress:', error);
    }
  };

  const handleLogout = async () => {
    try {
      await logout();
    } catch (error) {
      console.error('Logout error:', error);
    }
  };

  if (!user) {
    return null;
  }

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.displayName}>{user.display_name}</Text>
        <Text style={styles.email}>{user.email}</Text>
        {user.is_trial && (
          <View style={styles.trialBadge}>
            <Text style={styles.trialText}>
              Trial: {user.trial_snippets_remaining} snippets remaining
            </Text>
          </View>
        )}
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Progress</Text>
        
        {progressLoading ? (
          <ActivityIndicator color="#000" />
        ) : userProgress ? (
          <View style={styles.statsGrid}>
            <View style={styles.statCard}>
              <Text style={styles.statValue}>{userProgress.total_snippets_attempted}</Text>
              <Text style={styles.statLabel}>Attempted</Text>
            </View>
            <View style={styles.statCard}>
              <Text style={styles.statValue}>{userProgress.total_snippets_solved}</Text>
              <Text style={styles.statLabel}>Solved</Text>
            </View>
            <View style={styles.statCard}>
              <Text style={styles.statValue}>
                {userProgress.total_snippets_attempted > 0
                  ? Math.round((userProgress.total_snippets_solved / userProgress.total_snippets_attempted) * 100)
                  : 0}%
              </Text>
              <Text style={styles.statLabel}>Success Rate</Text>
            </View>
          </View>
        ) : (
          <Text style={styles.emptyText}>No progress yet. Start practicing!</Text>
        )}
      </View>

      {userProgress && userProgress.patterns && userProgress.patterns.length > 0 && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Pattern Progress</Text>
          {userProgress.patterns.map((pattern) => (
            <View key={pattern.pattern_id} style={styles.patternProgressCard}>
              <Text style={styles.patternName}>{pattern.pattern_name}</Text>
              <Text style={styles.patternStats}>
                {pattern.solved}/{pattern.attempted} solved
              </Text>
            </View>
          ))}
        </View>
      )}

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Account</Text>
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Role:</Text>
          <Text style={styles.infoValue}>{user.role}</Text>
        </View>
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Member since:</Text>
          <Text style={styles.infoValue}>
            {new Date(user.created_at).toLocaleDateString()}
          </Text>
        </View>
      </View>

      <TouchableOpacity
        style={styles.logoutButton}
        onPress={handleLogout}
        disabled={authLoading}
      >
        {authLoading ? (
          <ActivityIndicator color="#fff" />
        ) : (
          <Text style={styles.logoutButtonText}>Logout</Text>
        )}
      </TouchableOpacity>

      <View style={styles.footer}>
        <Text style={styles.footerText}>bugdrill v1.0.0</Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  header: {
    padding: 24,
    paddingTop: 60,
    backgroundColor: '#f9f9f9',
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
    alignItems: 'center',
  },
  displayName: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#000',
    marginBottom: 4,
  },
  email: {
    fontSize: 16,
    color: '#666',
    marginBottom: 12,
  },
  trialBadge: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    backgroundColor: '#fff3cd',
    borderRadius: 4,
  },
  trialText: {
    fontSize: 12,
    color: '#856404',
    fontWeight: '600',
  },
  section: {
    padding: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: '600',
    color: '#000',
    marginBottom: 16,
  },
  statsGrid: {
    flexDirection: 'row',
    gap: 12,
  },
  statCard: {
    flex: 1,
    backgroundColor: '#f9f9f9',
    padding: 16,
    borderRadius: 8,
    alignItems: 'center',
  },
  statValue: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#000',
    marginBottom: 4,
  },
  statLabel: {
    fontSize: 12,
    color: '#666',
  },
  emptyText: {
    fontSize: 14,
    color: '#999',
    textAlign: 'center',
    padding: 20,
  },
  patternProgressCard: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  patternName: {
    fontSize: 16,
    fontWeight: '500',
    color: '#000',
  },
  patternStats: {
    fontSize: 14,
    color: '#666',
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 8,
  },
  infoLabel: {
    fontSize: 14,
    color: '#666',
  },
  infoValue: {
    fontSize: 14,
    color: '#000',
    fontWeight: '500',
  },
  logoutButton: {
    margin: 20,
    height: 48,
    backgroundColor: '#f44336',
    borderRadius: 8,
    justifyContent: 'center',
    alignItems: 'center',
  },
  logoutButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  footer: {
    padding: 20,
    alignItems: 'center',
  },
  footerText: {
    fontSize: 12,
    color: '#999',
  },
});
