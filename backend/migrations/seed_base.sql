-- Base seed data (required for app to function)

-- Seed pattern categories
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
