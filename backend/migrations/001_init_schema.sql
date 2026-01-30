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

-- Sample snippets for Two Pointers pattern
INSERT INTO snippets (pattern_id, title, description, difficulty, language, correct_code, buggy_code, bug_type, bug_explanation, test_cases, hint_1, hint_2, hint_3, status) VALUES
(
    1,
    'Valid Palindrome',
    'Given a string s, return true if it is a palindrome, false otherwise. A palindrome reads the same forward and backward.',
    'beginner',
    'python',
    'def isPalindrome(s: str) -> bool:
    left, right = 0, len(s) - 1
    while left < right:
        if s[left] != s[right]:
            return False
        left += 1
        right -= 1
    return True',
    'def isPalindrome(s: str) -> bool:
    left, right = 0, len(s) - 1
    while left <= right:
        if s[left] != s[right]:
            return False
        left += 1
        right -= 1
    return True',
    'Off-by-one error',
    'The condition should be left < right, not left <= right. When left equals right, we are at the middle character and do not need to compare it with itself.',
    '[{"input": {"s": "racecar"}, "expected": true}, {"input": {"s": "hello"}, "expected": false}, {"input": {"s": "a"}, "expected": true}]',
    'Think about what happens when the two pointers meet in the middle',
    'When left == right, you are comparing the same character with itself',
    'The loop should stop when left < right, not when left <= right',
    'active'
),
(
    1,
    'Two Sum Sorted',
    'Given a sorted array of integers and a target, find two numbers that add up to the target. Return their indices.',
    'beginner',
    'python',
    'def twoSum(nums: list[int], target: int) -> list[int]:
    left, right = 0, len(nums) - 1
    while left < right:
        current_sum = nums[left] + nums[right]
        if current_sum == target:
            return [left, right]
        elif current_sum < target:
            left += 1
        else:
            right -= 1
    return [-1, -1]',
    'def twoSum(nums: list[int], target: int) -> list[int]:
    left, right = 0, len(nums) - 1
    while left < right:
        current_sum = nums[left] + nums[right]
        if current_sum == target:
            return [left, right]
        elif current_sum > target:
            left += 1
        else:
            right -= 1
    return [-1, -1]',
    'Logic error',
    'When current_sum is greater than target, we should move the right pointer left (to decrease the sum), not move the left pointer right. The condition is reversed.',
    '[{"input": {"nums": [1, 2, 3, 4, 5], "target": 9}, "expected": [3, 4]}, {"input": {"nums": [2, 7, 11, 15], "target": 9}, "expected": [0, 1]}]',
    'When the sum is too large, which pointer should you move to make it smaller?',
    'The array is sorted. Moving right pointer left gives a smaller value.',
    'The conditions for moving left and right pointers are swapped.',
    'active'
);

-- Sample snippets for Sliding Window pattern
INSERT INTO snippets (pattern_id, title, description, difficulty, language, correct_code, buggy_code, bug_type, bug_explanation, test_cases, hint_1, hint_2, hint_3, status) VALUES
(
    2,
    'Maximum Sum Subarray',
    'Find the maximum sum of any contiguous subarray of size k.',
    'beginner',
    'python',
    'def maxSumSubarray(nums: list[int], k: int) -> int:
    window_sum = sum(nums[:k])
    max_sum = window_sum
    for i in range(k, len(nums)):
        window_sum = window_sum - nums[i - k] + nums[i]
        max_sum = max(max_sum, window_sum)
    return max_sum',
    'def maxSumSubarray(nums: list[int], k: int) -> int:
    window_sum = sum(nums[:k])
    max_sum = window_sum
    for i in range(k, len(nums)):
        window_sum = window_sum + nums[i]
        max_sum = max(max_sum, window_sum)
    return max_sum',
    'Missing removal',
    'The sliding window must remove the leftmost element before adding the new element. Only adding nums[i] causes the window to grow instead of slide.',
    '[{"input": {"nums": [2, 1, 5, 1, 3, 2], "k": 3}, "expected": 9}, {"input": {"nums": [1, 4, 2, 10, 23, 3, 1, 0, 20], "k": 4}, "expected": 39}]',
    'What should happen to the leftmost element when the window slides right?',
    'A sliding window of size k should remove one element and add one element',
    'You need to subtract nums[i-k] before adding nums[i]',
    'active'
);

-- Sample snippets for Fast & Slow Pointers
INSERT INTO snippets (pattern_id, title, description, difficulty, language, correct_code, buggy_code, bug_type, bug_explanation, test_cases, hint_1, hint_2, hint_3, status) VALUES
(
    3,
    'Detect Cycle in Linked List',
    'Given head of a linked list, determine if it has a cycle.',
    'medium',
    'python',
    'def hasCycle(head) -> bool:
    if not head:
        return False
    slow = head
    fast = head
    while fast and fast.next:
        slow = slow.next
        fast = fast.next.next
        if slow == fast:
            return True
    return False',
    'def hasCycle(head) -> bool:
    if not head:
        return False
    slow = head
    fast = head.next
    while fast and fast.next:
        slow = slow.next
        fast = fast.next.next
        if slow == fast:
            return True
    return False',
    'Initialization error',
    'Starting fast at head.next causes the algorithm to miss detecting a cycle if it starts at the head node. Both pointers should start at head.',
    '[{"input": {"head": [3,2,0,-4], "pos": 1}, "expected": true}, {"input": {"head": [1], "pos": -1}, "expected": false}]',
    'Where should both pointers start to ensure they meet if there is a cycle?',
    'If fast starts ahead, they might never meet even with a cycle',
    'Initialize both slow and fast at head, not fast at head.next',
    'active'
);

-- Sample snippets for Binary Search
INSERT INTO snippets (pattern_id, title, description, difficulty, language, correct_code, buggy_code, bug_type, bug_explanation, test_cases, hint_1, hint_2, hint_3, status) VALUES
(
    4,
    'Search in Rotated Sorted Array',
    'Search for a target value in a rotated sorted array. Return its index or -1 if not found.',
    'medium',
    'python',
    'def search(nums: list[int], target: int) -> int:
    left, right = 0, len(nums) - 1
    while left <= right:
        mid = (left + right) // 2
        if nums[mid] == target:
            return mid
        if nums[left] <= nums[mid]:
            if nums[left] <= target < nums[mid]:
                right = mid - 1
            else:
                left = mid + 1
        else:
            if nums[mid] < target <= nums[right]:
                left = mid + 1
            else:
                right = mid - 1
    return -1',
    'def search(nums: list[int], target: int) -> int:
    left, right = 0, len(nums) - 1
    while left <= right:
        mid = (left + right) // 2
        if nums[mid] == target:
            return mid
        if nums[left] < nums[mid]:
            if nums[left] <= target < nums[mid]:
                right = mid - 1
            else:
                left = mid + 1
        else:
            if nums[mid] < target <= nums[right]:
                left = mid + 1
            else:
                right = mid - 1
    return -1',
    'Boundary condition',
    'The condition should be nums[left] <= nums[mid] not nums[left] < nums[mid]. When left equals mid, we need to handle this case correctly.',
    '[{"input": {"nums": [4,5,6,7,0,1,2], "target": 0}, "expected": 4}, {"input": {"nums": [4,5,6,7,0,1,2], "target": 3}, "expected": -1}]',
    'What happens when left == mid in the array [2,1]?',
    'The boundary check needs to include equality',
    'Change nums[left] < nums[mid] to nums[left] <= nums[mid]',
    'active'
);

-- Sample snippets for DFS
INSERT INTO snippets (pattern_id, title, description, difficulty, language, correct_code, buggy_code, bug_type, bug_explanation, test_cases, hint_1, hint_2, hint_3, status) VALUES
(
    5,
    'Maximum Depth of Binary Tree',
    'Find the maximum depth (height) of a binary tree.',
    'beginner',
    'python',
    'def maxDepth(root) -> int:
    if not root:
        return 0
    left_depth = maxDepth(root.left)
    right_depth = maxDepth(root.right)
    return max(left_depth, right_depth) + 1',
    'def maxDepth(root) -> int:
    if not root:
        return 0
    left_depth = maxDepth(root.left)
    right_depth = maxDepth(root.right)
    return max(left_depth, right_depth)',
    'Missing increment',
    'The current node adds 1 to the depth. Forgetting to add 1 means you are not counting the current level.',
    '[{"input": {"root": [3,9,20,null,null,15,7]}, "expected": 3}, {"input": {"root": [1,null,2]}, "expected": 2}]',
    'Does the current node count toward the depth?',
    'Each level adds 1 to the depth',
    'You need to add 1 to account for the current node',
    'active'
);

-- Sample snippets for BFS
INSERT INTO snippets (pattern_id, title, description, difficulty, language, correct_code, buggy_code, bug_type, bug_explanation, test_cases, hint_1, hint_2, hint_3, status) VALUES
(
    6,
    'Binary Tree Level Order Traversal',
    'Return the level order traversal of a binary tree (values of nodes level by level).',
    'medium',
    'python',
    'from collections import deque

def levelOrder(root):
    if not root:
        return []
    result = []
    queue = deque([root])
    while queue:
        level_size = len(queue)
        level = []
        for _ in range(level_size):
            node = queue.popleft()
            level.append(node.val)
            if node.left:
                queue.append(node.left)
            if node.right:
                queue.append(node.right)
        result.append(level)
    return result',
    'from collections import deque

def levelOrder(root):
    if not root:
        return []
    result = []
    queue = deque([root])
    while queue:
        level = []
        for node in queue:
            level.append(node.val)
            if node.left:
                queue.append(node.left)
            if node.right:
                queue.append(node.right)
        result.append(level)
    return result',
    'Infinite loop',
    'Iterating over queue while simultaneously adding to it causes an infinite loop. You must capture the current level size first.',
    '[{"input": {"root": [3,9,20,null,null,15,7]}, "expected": [[3],[9,20],[15,7]]}]',
    'What happens when you iterate over a collection while adding to it?',
    'Store the current level size before processing',
    'Use level_size = len(queue) and iterate range(level_size)',
    'active'
);

-- Sample snippets for Dynamic Programming
INSERT INTO snippets (pattern_id, title, description, difficulty, language, correct_code, buggy_code, bug_type, bug_explanation, test_cases, hint_1, hint_2, hint_3, status) VALUES
(
    7,
    'Climbing Stairs',
    'You are climbing a staircase with n steps. You can climb 1 or 2 steps at a time. How many distinct ways can you climb to the top?',
    'beginner',
    'python',
    'def climbStairs(n: int) -> int:
    if n <= 2:
        return n
    dp = [0] * (n + 1)
    dp[1] = 1
    dp[2] = 2
    for i in range(3, n + 1):
        dp[i] = dp[i - 1] + dp[i - 2]
    return dp[n]',
    'def climbStairs(n: int) -> int:
    if n <= 2:
        return n
    dp = [0] * n
    dp[1] = 1
    dp[2] = 2
    for i in range(3, n + 1):
        dp[i] = dp[i - 1] + dp[i - 2]
    return dp[n]',
    'Array size error',
    'The dp array has size n but we are accessing dp[n], which is out of bounds. Array should be size n+1.',
    '[{"input": {"n": 5}, "expected": 8}, {"input": {"n": 3}, "expected": 3}]',
    'What index are you trying to access at the end?',
    'If you access dp[n], the array needs to have at least n+1 elements',
    'Change array size from n to n+1',
    'active'
);

-- Sample snippets for Backtracking
INSERT INTO snippets (pattern_id, title, description, difficulty, language, correct_code, buggy_code, bug_type, bug_explanation, test_cases, hint_1, hint_2, hint_3, status) VALUES
(
    8,
    'Generate Parentheses',
    'Generate all combinations of well-formed parentheses for n pairs.',
    'medium',
    'python',
    'def generateParenthesis(n: int) -> list[str]:
    result = []
    def backtrack(current, open_count, close_count):
        if len(current) == 2 * n:
            result.append(current)
            return
        if open_count < n:
            backtrack(current + "(", open_count + 1, close_count)
        if close_count < open_count:
            backtrack(current + ")", open_count, close_count + 1)
    backtrack("", 0, 0)
    return result',
    'def generateParenthesis(n: int) -> list[str]:
    result = []
    def backtrack(current, open_count, close_count):
        if len(current) == 2 * n:
            result.append(current)
            return
        if open_count < n:
            backtrack(current + "(", open_count + 1, close_count)
        if close_count < n:
            backtrack(current + ")", open_count, close_count + 1)
    backtrack("", 0, 0)
    return result',
    'Invalid constraint',
    'The condition for adding a closing parenthesis should be close_count < open_count, not close_count < n. This ensures we only add ) when there is a matching ( available.',
    '[{"input": {"n": 3}, "expected": ["((()))","(()())","(())()","()(())","()()()"]}, {"input": {"n": 1}, "expected": ["()"]}]',
    'When can you safely add a closing parenthesis?',
    'You can only add ) when there are more ( than ) so far',
    'Change close_count < n to close_count < open_count',
    'active'
);
