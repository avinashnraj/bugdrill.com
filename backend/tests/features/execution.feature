Feature: Code Execution
  As a user
  I want to execute code snippets
  So that I can test my bug fixes

  Background:
    Given the API is healthy and running
    And I have a valid user account "coder@test.com" with password "Pass123!"
    And I have seeded the sample snippets

  Scenario: Execute buggy code and get failure
    When I get the first snippet for pattern 1
    And I execute the buggy code for that snippet
    Then the execution should complete
    And the execution should not be correct
    And I should see execution output

  Scenario: Execute correct code and get success
    When I get the first snippet for pattern 1
    And I execute the correct code for that snippet
    Then the execution should complete
    And the execution should be correct
    And I should see execution output
    And the test should have passed

  Scenario: Execute code with syntax error
    When I get the first snippet for pattern 1
    And I execute invalid Python code
    Then the execution should complete
    And the execution should not be correct
    And I should see an error in stderr
