# 🚀 bugdrill - Quick Start Guide

Get the full stack running in 5 minutes!

## Prerequisites

**Backend:**
- Go 1.21+
- Docker & Docker Compose
- Make

**Mobile:**
- Node.js 18+
- npm or yarn
- Expo Go app (for testing on phone)

## Step-by-Step Setup

### 1️⃣ Start the Backend

```bash
# Terminal 1
cd backend

# Start PostgreSQL and Redis
make docker-up

# Run the API server
make run
```

✅ Backend running at: http://localhost:8080

**Test it:**
```bash
curl http://localhost:8080/health
# Should return: {"status":"healthy","app":"bugdrill"}
```

### 2️⃣ Start the Mobile App

```bash
# Terminal 2
cd mobile

# Install dependencies (first time only)
npm install

# Start Expo dev server
npm start
```

### 3️⃣ Run on Device/Simulator

**Option A: iOS Simulator (Mac only)**
- Press `i` in the terminal
- Wait for simulator to launch

**Option B: Android Emulator**
- Start Android emulator first
- Press `a` in the terminal

**Option C: Your Phone** (Recommended for first test!)
- Install "Expo Go" app from store
- Scan the QR code in terminal

## 🎯 Test the Full Flow

1. **Sign up**
   - Open app → Tap "Sign up"
   - Enter: name, email, password
   - You're in! 🎉

2. **Browse patterns**
   - See list of coding patterns
   - Tap "Two Pointers" (or any pattern)

3. **Fix a bug**
   - Select a snippet
   - Edit the buggy code
   - Tap "Run" to test
   - Tap "Submit" when ready

4. **Get hints**
   - Stuck? Tap "💡 Hint"
   - Get 3 progressive hints

## 📱 Mobile App Features

✅ Login/Signup
✅ Browse patterns
✅ View snippets by difficulty
✅ Edit and run code
✅ See test results
✅ Get hints
✅ Track progress

## 🔧 Configuration

### Change API URL (for physical devices)

If testing on your phone with local backend:

1. Find your computer's IP:
   ```bash
   # Windows
   ipconfig
   
   # Mac/Linux
   ifconfig
   ```

2. Edit `mobile/src/constants/config.ts`:
   ```typescript
   BASE_URL: 'http://YOUR_IP:8080/api/v1'
   ```

3. Restart Expo: `npm start`

## 🐛 Troubleshooting

**Backend won't start:**
```bash
# Check if ports are available
netstat -an | findstr "8080"

# Stop existing containers
docker-compose down
make docker-up
```

**Mobile can't connect:**
- Check backend health: http://localhost:8080/health
- Use your IP instead of localhost for physical devices
- Check firewall settings

**Metro bundler cache issues:**
```bash
cd mobile
npm start -- --reset-cache
```

## 📚 Next Steps

- Read [mobile/SETUP.md](mobile/SETUP.md) for detailed mobile architecture
- Read [backend/README.md](backend/README.md) for API documentation
- Read [SYSTEM_DESIGN.md](SYSTEM_DESIGN.md) for system architecture

## 🎓 Tech Stack Summary

| Layer | Technology |
|-------|-----------|
| **Mobile** | React Native, Expo, TypeScript |
| **Backend** | Go, Gin framework |
| **Database** | PostgreSQL, Redis |
| **Auth** | JWT tokens |
| **State** | Zustand |
| **Navigation** | React Navigation |

## ✨ You're Ready!

Your full-stack interview prep platform is running:
- 📱 Mobile app with beautiful UI
- 🔧 REST API with authentication
- 💾 Database with sample patterns
- 🔐 Secure JWT authentication

**Start practicing and master those coding patterns!** 🚀

---

**Need help?** Check the documentation in each directory's README.md
