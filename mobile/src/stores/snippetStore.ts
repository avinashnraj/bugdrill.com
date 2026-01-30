import { create } from 'zustand';
import { snippetService } from '../services/snippets';
import { PatternCategory, Snippet, UserProgress } from '../types';

interface SnippetState {
  patterns: PatternCategory[];
  currentSnippets: Snippet[];
  currentSnippet: Snippet | null;
  userProgress: UserProgress | null;
  isLoading: boolean;
  error: string | null;

  // Actions
  fetchPatterns: () => Promise<void>;
  fetchSnippetsByPattern: (patternId: number, difficulty?: string) => Promise<void>;
  fetchSnippet: (snippetId: string) => Promise<void>;
  fetchUserProgress: () => Promise<void>;
  clearError: () => void;
}

export const useSnippetStore = create<SnippetState>((set) => ({
  patterns: [],
  currentSnippets: [],
  currentSnippet: null,
  userProgress: null,
  isLoading: false,
  error: null,

  fetchPatterns: async () => {
    try {
      set({ isLoading: true, error: null });
      const patterns = await snippetService.getPatterns();
      set({ patterns, isLoading: false });
    } catch (error: any) {
      const errorMessage = error.response?.data?.error || 'Failed to load patterns';
      set({ error: errorMessage, isLoading: false });
      throw error;
    }
  },

  fetchSnippetsByPattern: async (patternId: number, difficulty?: string) => {
    try {
      set({ isLoading: true, error: null });
      const snippets = await snippetService.getSnippetsByPattern(
        patternId,
        difficulty as any
      );
      set({ currentSnippets: snippets, isLoading: false });
    } catch (error: any) {
      const errorMessage = error.response?.data?.error || 'Failed to load snippets';
      set({ error: errorMessage, isLoading: false });
      throw error;
    }
  },

  fetchSnippet: async (snippetId: string) => {
    try {
      set({ isLoading: true, error: null });
      const snippet = await snippetService.getSnippet(snippetId);
      set({ currentSnippet: snippet, isLoading: false });
    } catch (error: any) {
      const errorMessage = error.response?.data?.error || 'Failed to load snippet';
      set({ error: errorMessage, isLoading: false });
      throw error;
    }
  },

  fetchUserProgress: async () => {
    try {
      set({ isLoading: true, error: null });
      const progress = await snippetService.getUserProgress();
      set({ userProgress: progress, isLoading: false });
    } catch (error: any) {
      const errorMessage = error.response?.data?.error || 'Failed to load progress';
      set({ error: errorMessage, isLoading: false });
      throw error;
    }
  },

  clearError: () => set({ error: null }),
}));
