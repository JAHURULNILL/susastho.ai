# Sushastho.ai Backend

এই backend-এ `GEMINI_API_KEY` থাকবে এবং Flutter app এই server-এর মাধ্যমে food analysis নেবে।

## Setup

1. `.env.example` কপি করে `.env` বানান
2. `.env`-এ `GEMINI_API_KEY` দিন
3. চাইলে `GEMINI_MODEL` পরিবর্তন করুন
4. dependencies install করুন
5. server চালান

## Commands

```powershell
cd C:\Users\Jahurul Haque\Documents\health\backend
Copy-Item .env.example .env
npm install
npm start
```

## Flutter Run

```powershell
flutter run --dart-define=BACKEND_BASE_URL=https://your-server-domain.com
```

## Endpoints

- `GET /health`
- `POST /api/nutrition/analyze`
