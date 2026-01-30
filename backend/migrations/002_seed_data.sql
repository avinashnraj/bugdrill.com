-- Seed data for pattern categories
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

-- Seed snippet for Two Pointers pattern - Two Sum
INSERT INTO snippets (pattern_id, title, description, difficulty, language, correct_code, buggy_code, bug_type, bug_explanation, test_cases, hint_1, hint_2, hint_3, status)
SELECT 1, 'Two Sum Sorted', 'Given a sorted array of integers and a target, find two numbers that add up to the target. Return their indices.', 'beginner', 'python',
$CORRECT$def twoSum(nums: list[int], target: int) -> list[int]:
    left, right = 0, len(nums) - 1
    while left < right:
        current_sum = nums[left] + nums[right]
        if current_sum == target:
            return [left, right]
        elif current_sum < target:
            left += 1
        else:
            right -= 1
    return [-1, -1]$CORRECT$,
$BUGGY$def twoSum(nums: list[int], target: int) -> list[int]:
    left, right = 0, len(nums) - 1
    while left < right:
        current_sum = nums[left] + nums[right]
        if current_sum == target:
            return [left, right]
        elif current_sum > target:
            left += 1
        else:
            right -= 1
    return [-1, -1]$BUGGY$,
'Logic error',
'When current_sum is greater than target, we should move the right pointer left (to decrease the sum), not move the left pointer right. The condition is reversed.',
'[{"input": {"nums": [1, 2, 3, 4, 5], "target": 9}, "expected": [3, 4]}, {"input": {"nums": [2, 7, 11, 15], "target": 9}, "expected": [0, 1]}]'::jsonb,
'When the sum is too large, which pointer should you move to make it smaller?',
'The array is sorted. Moving right pointer left gives a smaller value.',
'The conditions for moving left and right pointers are swapped.',
'active'
WHERE NOT EXISTS (SELECT 1 FROM snippets WHERE title = 'Two Sum Sorted' AND pattern_id = 1);

-- Seed snippet for Two Pointers pattern - Valid Palindrome
INSERT INTO snippets (pattern_id, title, description, difficulty, language, correct_code, buggy_code, bug_type, bug_explanation, test_cases, hint_1, hint_2, hint_3, status)
SELECT 1, 'Valid Palindrome', 'Given a string s, return true if it is a palindrome, false otherwise. A palindrome reads the same forward and backward.', 'beginner', 'python',
$CORRECT$def isPalindrome(s: str) -> bool:
    left, right = 0, len(s) - 1
    while left < right:
        if s[left] != s[right]:
            return False
        left += 1
        right -= 1
    return True$CORRECT$,
$BUGGY$def isPalindrome(s: str) -> bool:
    left, right = 0, len(s) - 1
    while left <= right:
        if s[left] != s[right]:
            return False
        left += 1
        right -= 1
    return True$BUGGY$,
'Off-by-one error',
'The condition should be left < right, not left <= right. When left == right, we are comparing the same character which is always true.',
'[{"input": {"s": "racecar"}, "expected": true}, {"input": {"s": "hello"}, "expected": false}]'::jsonb,
'Think about when to stop comparing characters.',
'What happens when the pointers meet at the same index?',
'The middle character does not need to be compared with itself.',
'active'
WHERE NOT EXISTS (SELECT 1 FROM snippets WHERE title = 'Valid Palindrome' AND pattern_id = 1);
