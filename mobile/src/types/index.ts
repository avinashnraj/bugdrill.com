// Type definitions matching backend API responses

export interface User {
  id: string;
  email: string;
  display_name: string;
  role: string;
  is_trial: boolean;
  trial_snippets_remaining: number;
  created_at: string;
  last_login_at?: string;
}

export interface AuthResponse {
  access_token: string;
  refresh_token: string;
  user: User;
}

export interface PatternCategory {
  id: number;
  name: string;
  slug: string;
  description: string;
  icon_url?: string;
  order_index: number;
}

export interface TestCase {
  input: Record<string, any>;
  expected: any;
}

export interface Snippet {
  id: string;
  pattern_id: number;
  title: string;
  description: string;
  difficulty: 'Beginner' | 'Medium' | 'Hard';
  language: string;
  buggy_code: string;
  bug_type: string;
  bug_explanation: string;
  test_cases: TestCase[];
  hint_1: string;
  hint_2: string;
  hint_3: string;
  created_at: string;
  updated_at: string;
}

export interface TestResult {
  test_case: number;
  input: any;
  expected: any;
  actual: any;
  passed: boolean;
  execution_time_ms: number;
}

export interface ExecuteCodeResponse {
  execution_id: string;
  status: string;
  is_correct: boolean;
  test_results: TestResult[];
  total_time_ms: number;
  stdout: string;
  stderr: string;
}

export interface HintResponse {
  hint: string;
  tier: string;
}

export interface UserProgress {
  total_snippets_attempted: number;
  total_snippets_solved: number;
  patterns: Array<{
    pattern_id: number;
    pattern_name: string;
    attempted: number;
    solved: number;
  }>;
}
