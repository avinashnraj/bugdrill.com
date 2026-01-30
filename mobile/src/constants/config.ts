// API Configuration
export const API_CONFIG = {
  // Change this to your backend URL
  // For local development: http://localhost:8080/api/v1
  // For production: https://api.bugdrill.com/api/v1
  BASE_URL: __DEV__ 
    ? 'http://localhost:8080/api/v1' 
    : 'https://api.bugdrill.com/api/v1',
  
  TIMEOUT: 10000, // 10 seconds
};

// App Configuration
export const APP_CONFIG = {
  APP_NAME: 'bugdrill',
  VERSION: '1.0.0',
  TRIAL_SNIPPETS_LIMIT: 5,
};

// Storage Keys
export const STORAGE_KEYS = {
  ACCESS_TOKEN: '@bugdrill:access_token',
  REFRESH_TOKEN: '@bugdrill:refresh_token',
  USER_DATA: '@bugdrill:user_data',
};
