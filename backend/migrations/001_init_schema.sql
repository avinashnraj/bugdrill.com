-- Create UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    display_name VARCHAR(100),
    oauth_provider VARCHAR(20),
    oauth_id VARCHAR(255),
    role VARCHAR(20) DEFAULT 'user',
    created_at TIMESTAMP DEFAULT NOW(),
    last_login_at TIMESTAMP,
    is_trial BOOLEAN DEFAULT FALSE,
    trial_snippets_remaining INT DEFAULT 5,
    CONSTRAINT check_role CHECK (role IN ('user', 'admin'))
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_oauth ON users(oauth_provider, oauth_id);

-- Pattern categories
CREATE TABLE IF NOT EXISTS pattern_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    icon_url VARCHAR(255),
    order_index INT DEFAULT 0
);

-- Snippets table
CREATE TABLE IF NOT EXISTS snippets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pattern_id INT REFERENCES pattern_categories(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    difficulty VARCHAR(20) NOT NULL,
    language VARCHAR(20) NOT NULL,
    
    correct_code TEXT NOT NULL,
    buggy_code TEXT NOT NULL,
    bug_type VARCHAR(50),
    bug_explanation TEXT,
    
    test_cases JSONB NOT NULL,
    
    hint_1 TEXT,
    hint_2 TEXT,
    hint_3 TEXT,
    
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT check_difficulty CHECK (difficulty IN ('beginner', 'medium', 'hard')),
    CONSTRAINT check_status CHECK (status IN ('active', 'pending_review', 'archived'))
);

CREATE INDEX idx_snippets_pattern ON snippets(pattern_id);
CREATE INDEX idx_snippets_difficulty ON snippets(difficulty);
CREATE INDEX idx_snippets_status ON snippets(status);

-- User snippet attempts
CREATE TABLE IF NOT EXISTS user_snippet_attempts (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    snippet_id UUID REFERENCES snippets(id) ON DELETE CASCADE,
    
    submitted_code TEXT NOT NULL,
    is_correct BOOLEAN NOT NULL,
    execution_time_ms INT,
    test_cases_passed INT,
    test_cases_total INT,
    
    hints_used INT DEFAULT 0,
    attempt_number INT DEFAULT 1,
    
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_attempts_user ON user_snippet_attempts(user_id);
CREATE INDEX idx_attempts_snippet ON user_snippet_attempts(snippet_id);
CREATE INDEX idx_attempts_correct ON user_snippet_attempts(is_correct);

-- User pattern progress (aggregated stats)
CREATE TABLE IF NOT EXISTS user_pattern_progress (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    pattern_id INT REFERENCES pattern_categories(id) ON DELETE CASCADE,
    
    snippets_attempted INT DEFAULT 0,
    snippets_solved INT DEFAULT 0,
    total_attempts INT DEFAULT 0,
    avg_attempts_per_solve DECIMAL(4,2),
    
    last_practiced_at TIMESTAMP,
    next_review_at TIMESTAMP,
    mastery_level INT DEFAULT 0,
    
    PRIMARY KEY (user_id, pattern_id)
);

-- Seed some pattern categories
INSERT INTO pattern_categories (name, slug, description, order_index) VALUES
    ('Two Pointers', 'two-pointers', 'Master the two-pointer technique for array and string problems', 1),
    ('Sliding Window', 'sliding-window', 'Learn to solve subarray/substring problems efficiently', 2),
    ('Fast & Slow Pointers', 'fast-slow-pointers', 'Detect cycles and find middle elements in linked lists', 3),
    ('Binary Search', 'binary-search', 'Efficient searching in sorted arrays and search spaces', 4),
    ('Depth-First Search', 'dfs', 'Tree and graph traversal using DFS', 5),
    ('Breadth-First Search', 'bfs', 'Level-order traversal and shortest path problems', 6),
    ('Dynamic Programming', 'dynamic-programming', 'Optimize recursive solutions with memoization', 7),
    ('Backtracking', 'backtracking', 'Explore all possible solutions systematically', 8)
ON CONFLICT (slug) DO NOTHING;

-- Create an admin user (password: admin123)
-- Password hash for "admin123" using bcrypt cost 10
INSERT INTO users (email, password_hash, display_name, role, is_trial) VALUES
    ('admin@bugdrill.com', '$2a$10$5z8h4F3q1xY.vN6QjXXXXu7ZWJz8zQ8KqP5L3hR2qWx1y.z3xX0yK', 'Admin User', 'admin', FALSE)
ON CONFLICT (email) DO NOTHING;
