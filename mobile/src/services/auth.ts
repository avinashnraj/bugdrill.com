import AsyncStorage from '@react-native-async-storage/async-storage';
import api from './api';
import { AuthResponse, User } from '../types';
import { STORAGE_KEYS } from '../constants/config';

export const authService = {
  /**
   * Sign up a new user
   */
  async signup(email: string, password: string, displayName: string): Promise<User> {
    const { data } = await api.post<AuthResponse>('/auth/signup', {
      email,
      password,
      display_name: displayName,
    });

    // Store tokens and user data
    await AsyncStorage.multiSet([
      [STORAGE_KEYS.ACCESS_TOKEN, data.access_token],
      [STORAGE_KEYS.REFRESH_TOKEN, data.refresh_token],
      [STORAGE_KEYS.USER_DATA, JSON.stringify(data.user)],
    ]);

    return data.user;
  },

  /**
   * Login existing user
   */
  async login(email: string, password: string): Promise<User> {
    const { data } = await api.post<AuthResponse>('/auth/login', {
      email,
      password,
    });

    // Store tokens and user data
    await AsyncStorage.multiSet([
      [STORAGE_KEYS.ACCESS_TOKEN, data.access_token],
      [STORAGE_KEYS.REFRESH_TOKEN, data.refresh_token],
      [STORAGE_KEYS.USER_DATA, JSON.stringify(data.user)],
    ]);

    return data.user;
  },

  /**
   * Get current user profile
   */
  async getProfile(): Promise<User> {
    const { data } = await api.get<User>('/auth/me');
    
    // Update stored user data
    await AsyncStorage.setItem(STORAGE_KEYS.USER_DATA, JSON.stringify(data));
    
    return data;
  },

  /**
   * Refresh access token
   */
  async refreshToken(refreshToken: string): Promise<string> {
    const { data } = await api.post<{ access_token: string }>('/auth/refresh', {
      refresh_token: refreshToken,
    });

    await AsyncStorage.setItem(STORAGE_KEYS.ACCESS_TOKEN, data.access_token);
    
    return data.access_token;
  },

  /**
   * Logout user
   */
  async logout(): Promise<void> {
    try {
      await api.post('/auth/logout');
    } catch (error) {
      // Continue with logout even if API call fails
      console.error('Logout API error:', error);
    } finally {
      // Clear all stored data
      await AsyncStorage.multiRemove([
        STORAGE_KEYS.ACCESS_TOKEN,
        STORAGE_KEYS.REFRESH_TOKEN,
        STORAGE_KEYS.USER_DATA,
      ]);
    }
  },

  /**
   * Check if user is authenticated (has valid token)
   */
  async isAuthenticated(): Promise<boolean> {
    const token = await AsyncStorage.getItem(STORAGE_KEYS.ACCESS_TOKEN);
    return !!token;
  },

  /**
   * Get stored user data without API call
   */
  async getStoredUser(): Promise<User | null> {
    const userData = await AsyncStorage.getItem(STORAGE_KEYS.USER_DATA);
    return userData ? JSON.parse(userData) : null;
  },
};
