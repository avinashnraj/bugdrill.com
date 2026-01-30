Feature: User Authentication and Signup Flow
  As a new user
  I want to sign up and access the API
  So that I can start practicing coding patterns

  Background:
    Given the API is healthy and running

  Scenario: Successful user signup and login
    When I signup with email "test@example.com" and password "SecurePass123!"
    Then the signup should be successful
    And I should receive an access token
    And I should receive a refresh token
    
    When I login with email "test@example.com" and password "SecurePass123!"
    Then the login should be successful
    And I should receive an access token
    
    When I request my profile with the access token
    Then I should see my profile information
    And my email should be "test@example.com"

  Scenario: Access protected endpoint with valid token
    Given I have a valid user account "user@test.com" with password "Pass123!"
    When I list all coding patterns
    Then I should see at least 8 patterns
    And the patterns should include "Two Pointers"
    And the patterns should include "Sliding Window"

  Scenario: Cannot access protected endpoint without token
    When I try to list patterns without authentication
    Then I should receive a 401 unauthorized error

  Scenario: Token refresh workflow
    Given I have logged in as "refresh@test.com" with password "Pass123!"
    When I use my refresh token to get a new access token
    Then I should receive a new access token
    And the new token should be different from the old token
