import { create } from 'zustand';
import { authService } from '../services/auth';
import { User } from '../types';

interface AuthState {
  user: User | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  error: string | null;
  
  // Actions
  login: (email: string, password: string) => Promise<void>;
  signup: (email: string, password: string, displayName: string) => Promise<void>;
  logout: () => Promise<void>;
  checkAuth: () => Promise<void>;
  clearError: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  isLoading: true,
  isAuthenticated: false,
  error: null,

  login: async (email: string, password: string) => {
    try {
      set({ isLoading: true, error: null });
      const user = await authService.login(email, password);
      set({ user, isAuthenticated: true, isLoading: false });
    } catch (error: any) {
      const errorMessage = error.response?.data?.error || 'Login failed';
      set({ error: errorMessage, isLoading: false, isAuthenticated: false });
      throw error;
    }
  },

  signup: async (email: string, password: string, displayName: string) => {
    try {
      set({ isLoading: true, error: null });
      const user = await authService.signup(email, password, displayName);
      set({ user, isAuthenticated: true, isLoading: false });
    } catch (error: any) {
      const errorMessage = error.response?.data?.error || 'Signup failed';
      set({ error: errorMessage, isLoading: false, isAuthenticated: false });
      throw error;
    }
  },

  logout: async () => {
    try {
      set({ isLoading: true });
      await authService.logout();
      set({ user: null, isAuthenticated: false, isLoading: false, error: null });
    } catch (error: any) {
      // Clear state even if logout API fails
      set({ user: null, isAuthenticated: false, isLoading: false, error: null });
    }
  },

  checkAuth: async () => {
    try {
      set({ isLoading: true });
      
      // First check if we have a token
      const isAuth = await authService.isAuthenticated();
      
      if (!isAuth) {
        set({ user: null, isAuthenticated: false, isLoading: false });
        return;
      }

      // Try to get fresh user data
      try {
        const user = await authService.getProfile();
        set({ user, isAuthenticated: true, isLoading: false });
      } catch (error) {
        // If API fails, try to use stored data
        const storedUser = await authService.getStoredUser();
        if (storedUser) {
          set({ user: storedUser, isAuthenticated: true, isLoading: false });
        } else {
          set({ user: null, isAuthenticated: false, isLoading: false });
        }
      }
    } catch (error) {
      set({ user: null, isAuthenticated: false, isLoading: false });
    }
  },

  clearError: () => set({ error: null }),
}));
