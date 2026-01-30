# bugdrill Mobile App

React Native mobile application for bugdrill - Learn coding patterns by fixing bugs.

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- npm or yarn
- iOS Simulator (Mac) or Android Studio (for emulators)
- Expo Go app on your phone (for physical device testing)

### Installation

```bash
cd mobile
npm install
```

### Running the App

**Start the development server:**
```bash
npm start
```

**Run on iOS Simulator (Mac only):**
```bash
npm run ios
```

**Run on Android Emulator:**
```bash
npm run android
```

**Run on your physical device:**
1. Install Expo Go from App Store (iOS) or Play Store (Android)
2. Scan the QR code from the terminal

## 📁 Project Structure

```
mobile/
├── src/
│   ├── services/        # API integration
│   │   ├── api.ts       # Axios config with interceptors
│   │   ├── auth.ts      # Authentication API calls
│   │   └── snippets.ts  # Snippet API calls
│   │
│   ├── stores/          # State management (Zustand)
│   │   ├── authStore.ts      # User auth state
│   │   └── snippetStore.ts   # Snippets and patterns state
│   │
│   ├── screens/         # App screens
│   │   ├── LoginScreen.tsx
│   │   ├── SignupScreen.tsx
│   │   ├── PatternsScreen.tsx
│   │   ├── PracticeScreen.tsx
│   │   ├── SnippetDetailScreen.tsx
│   │   └── ProfileScreen.tsx
│   │
│   ├── components/      # Reusable UI components
│   │
│   ├── types/           # TypeScript definitions
│   │   └── index.ts     # API response types
│   │
│   └── constants/
│       └── config.ts    # App configuration
│
├── App.tsx              # Main app entry with navigation
└── package.json
```

## 🔧 Configuration

### API Endpoint

Edit [`src/constants/config.ts`](src/constants/config.ts):

```typescript
export const API_CONFIG = {
  BASE_URL: __DEV__ 
    ? 'http://localhost:8080/api/v1'  // For development
    : 'https://api.bugdrill.com/api/v1',  // For production
};
```

**For physical devices testing with local backend:**
- Find your computer's local IP: `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
- Update BASE_URL to: `http://YOUR_IP:8080/api/v1`

## 🏗️ Architecture

### State Management
Uses **Zustand** for lightweight state management:
- `authStore`: User authentication, login/signup/logout
- `snippetStore`: Patterns, snippets, progress

### API Integration
- **Axios** with request/response interceptors
- Automatic JWT token injection
- Token refresh on 401 errors
- Error handling

### Navigation
- **React Navigation** (Stack + Bottom Tabs)
- Auth flow vs Main app flow
- Deep linking support (future)

## 📱 User Flow

1. **Authentication**
   - User lands on Login screen
   - Can switch to Signup
   - Tokens stored in AsyncStorage

2. **Main App**
   - Bottom tabs: Patterns, Profile
   - Browse coding patterns
   - Select pattern → view snippets
   - Select snippet → fix bug

3. **Debugging**
   - View buggy code
   - Edit code in editor
   - Run tests
   - Get hints (3 levels)
   - Submit solution

## 🔐 Authentication Flow

```
Login/Signup
    ↓
Save tokens (AsyncStorage)
    ↓
API calls include Bearer token
    ↓
If 401 → Try refresh token
    ↓
If refresh fails → Logout
```

## 🛠️ Available Scripts

- `npm start` - Start Expo dev server
- `npm run ios` - Run on iOS simulator
- `npm run android` - Run on Android emulator
- `npm run web` - Run in web browser (limited features)

## 📦 Key Dependencies

- **expo** - React Native framework
- **react-navigation** - Navigation
- **zustand** - State management
- **axios** - HTTP client
- **@react-native-async-storage** - Local storage

## 🚧 Upcoming Features

- [ ] Better code editor with syntax highlighting
- [ ] Offline support
- [ ] Push notifications
- [ ] Social features (leaderboards)
- [ ] Dark mode

## 📝 Notes

- The app is optimized for mobile devices
- Code editor is a basic TextInput (will be enhanced)
- All API types match backend exactly
- Error handling is basic (will be improved)

## 🐛 Troubleshooting

**Metro bundler issues:**
```bash
npm start -- --reset-cache
```

**Can't connect to backend:**
- Check backend is running: `http://localhost:8080/health`
- For physical devices, use your computer's IP instead of localhost
- Check firewall settings

**Type errors:**
- Restart TypeScript server in VS Code
- Delete `node_modules` and reinstall

## 📚 Learn More

- [Expo Documentation](https://docs.expo.dev/)
- [React Navigation](https://reactnavigation.org/)
- [Zustand](https://github.com/pmndrs/zustand)

---

**Ready to build?** Start the backend first, then run `npm start`!
