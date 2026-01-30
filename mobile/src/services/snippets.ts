import api from './api';
import {
  PatternCategory,
  Snippet,
  ExecuteCodeResponse,
  HintResponse,
  UserProgress,
} from '../types';

export const snippetService = {
  /**
   * Get all pattern categories
   */
  async getPatterns(): Promise<PatternCategory[]> {
    const { data } = await api.get<PatternCategory[]>('/patterns');
    return data;
  },

  /**
   * Get snippets for a specific pattern
   */
  async getSnippetsByPattern(
    patternId: number,
    difficulty?: 'Beginner' | 'Medium' | 'Hard'
  ): Promise<Snippet[]> {
    const { data } = await api.get<Snippet[]>(`/patterns/${patternId}/snippets`, {
      params: difficulty ? { difficulty } : {},
    });
    return data;
  },

  /**
   * Get a specific snippet by ID
   */
  async getSnippet(snippetId: string): Promise<Snippet> {
    const { data } = await api.get<Snippet>(`/snippets/${snippetId}`);
    return data;
  },

  /**
   * Execute code against test cases (doesn't save)
   */
  async executeCode(
    snippetId: string,
    code: string,
    language: string
  ): Promise<ExecuteCodeResponse> {
    const { data } = await api.post<ExecuteCodeResponse>(
      `/snippets/${snippetId}/execute`,
      { code, language }
    );
    return data;
  },

  /**
   * Submit solution (executes and saves attempt)
   */
  async submitSolution(
    snippetId: string,
    code: string,
    language: string
  ): Promise<ExecuteCodeResponse> {
    const { data } = await api.post<ExecuteCodeResponse>(
      `/snippets/${snippetId}/submit`,
      { code, language }
    );
    return data;
  },

  /**
   * Get a hint for a snippet (tier 1-3)
   */
  async getHint(snippetId: string, tier: 1 | 2 | 3): Promise<HintResponse> {
    const { data } = await api.post<HintResponse>(
      `/snippets/${snippetId}/hints/${tier}`
    );
    return data;
  },

  /**
   * Get user's overall progress
   */
  async getUserProgress(): Promise<UserProgress> {
    const { data } = await api.get<UserProgress>('/users/progress');
    return data;
  },
};
