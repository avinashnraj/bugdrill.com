-- Sample snippets seed data
-- Run this directly against your database

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
    'Beginner',
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
),
(
    2,
    'Maximum Sum Subarray',
    'Find the maximum sum of any contiguous subarray of size k.',
    'Beginner',
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
),
(
    3,
    'Detect Cycle in Linked List',
    'Given head of a linked list, determine if it has a cycle.',
    'Medium',
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
),
(
    4,
    'Search in Rotated Sorted Array',
    'Search for a target value in a rotated sorted array. Return its index or -1 if not found.',
    'Medium',
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
),
(
    5,
    'Maximum Depth of Binary Tree',
    'Find the maximum depth (height) of a binary tree.',
    'Beginner',
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
),
(
    6,
    'Binary Tree Level Order Traversal',
    'Return the level order traversal of a binary tree (values of nodes level by level).',
    'Medium',
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
),
(
    7,
    'Climbing Stairs',
    'You are climbing a staircase with n steps. You can climb 1 or 2 steps at a time. How many distinct ways can you climb to the top?',
    'Beginner',
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
),
(
    8,
    'Generate Parentheses',
    'Generate all combinations of well-formed parentheses for n pairs.',
    'Medium',
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
)
ON CONFLICT DO NOTHING;
