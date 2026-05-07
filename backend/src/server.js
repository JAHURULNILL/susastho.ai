import 'dotenv/config';
import express from 'express';
import cors from 'cors';

const app = express();
const port = Number(process.env.PORT || 8787);
const geminiApiKey = process.env.GEMINI_API_KEY || '';
const geminiModel = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
const appApiKey = process.env.APP_API_KEY || '';

app.use(cors());
app.use(express.json({ limit: '15mb' }));

// ─── Health checks ───────────────────────────────────────────────
app.get('/', (_req, res) => {
  res.json({ ok: true, message: 'Sushastho.ai backend is live.' });
});

app.get('/health', (_req, res) => {
  res.json({ ok: true, provider: 'gemini', model: geminiModel, date: new Date().toISOString() });
});

app.get('/privacy', (_req, res) => {
  res.type('html').send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Privacy Policy - Sushastho.ai</title>
      <style>
        body { font-family: system-ui, sans-serif; line-height: 1.6; max-width: 800px; margin: 0 auto; padding: 2rem; color: #333; }
        h1, h2 { color: #2D8A5B; }
      </style>
    </head>
    <body>
      <h1>Privacy Policy for Sushastho.ai</h1>
      <p>Last updated: May 2026</p>
      
      <h2>1. Information We Collect</h2>
      <p>We collect basic health metrics (age, weight, height, gender), dietary preferences, and activity data to provide personalized health insights. We also collect photos of food to analyze nutritional content via AI.</p>
      
      <h2>2. How We Use Your Information</h2>
      <p>Your data is used solely to provide and improve the Sushastho.ai service, generate personalized meal plans, and track your wellness journey. We process food images through AI models to estimate nutrition.</p>
      
      <h2>3. Data Storage and Security</h2>
      <p>We use industry-standard security measures, including Google Firebase, to securely store your data. We do not sell your personal data to third parties.</p>
      
      <h2>4. Your Rights</h2>
      <p>You can delete your data at any time by uninstalling the app or contacting us.</p>
      
      <h2>5. Contact Us</h2>
      <p>If you have any questions about this Privacy Policy, please contact us.</p>
    </body>
    </html>
  `);
});

// ─── Shared helpers ──────────────────────────────────────────────
function extractText(payload) {
  const parts = payload?.candidates?.[0]?.content?.parts;
  const text = Array.isArray(parts) ? parts.map((p) => p?.text).filter(Boolean).join('\n') : '';
  if (!text) throw new Error('Gemini response is empty.');
  return text;
}

function safeJsonParse(text) {
  const cleaned = String(text).replace(/```json/g, '').replace(/```/g, '').trim();
  const start = cleaned.indexOf('{');
  const end = cleaned.lastIndexOf('}');
  if (start === -1 || end === -1) throw new Error('Model JSON parse failed.');
  return JSON.parse(cleaned.slice(start, end + 1));
}

function errStr(e) { return e instanceof Error ? e.message : String(e); }

function requireKey(res) {
  if (!geminiApiKey) { res.status(500).json({ error: 'GEMINI_API_KEY is missing on backend.' }); return false; }
  return true;
}

function requireAppKey(req, res, next) {
  if (!appApiKey) return next(); // If not set on backend, allow all (dev mode)
  const key = req.headers['x-api-key'];
  if (key !== appApiKey) {
    return res.status(401).json({ error: 'Unauthorized: Invalid API Key.' });
  }
  next();
}

app.use('/api', requireAppKey);

async function geminiCall(prompt, { parts, temperature = 0.2, systemInstruction } = {}) {
  const contentParts = parts || [{ text: prompt }];
  const body = {
    contents: [{ parts: contentParts }],
    generationConfig: { temperature, response_mime_type: 'application/json' },
  };
  if (systemInstruction) {
    body.system_instruction = { parts: [{ text: systemInstruction }] };
  }

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${geminiModel}:generateContent?key=${geminiApiKey}`,
    { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) },
  );
  const json = await response.json();
  if (!response.ok) throw new Error(JSON.stringify(json));
  return json;
}

// ─── Roman Bangla normalizer ─────────────────────────────────────
function normalizeBangla(input) {
  return String(input || '').toLowerCase()
    .replace(/\bvaat\b/g, 'ভাত').replace(/\bbhat\b/g, 'ভাত')
    .replace(/\bdupure?\b/g, 'দুপুর').replace(/\bsh?okale\b/g, 'সকালে')
    .replace(/\brate\b/g, 'রাতে').replace(/\bnoyn?a\b/g, 'নয়না')
    .replace(/\bmaa?ch\b/g, 'মাছ').replace(/\bjhol\b/g, 'ঝোল')
    .replace(/\bdal\b/g, 'ডাল').replace(/\bdim\b/g, 'ডিম')
    .replace(/\bgorur mangsho\b/g, 'গরুর মাংস').replace(/\bmurgi\b/g, 'মুরগি')
    .replace(/\bkola\b/g, 'কলা').replace(/\bdudh\b/g, 'দুধ')
    .replace(/\bpanta\b/g, 'পান্তা').replace(/\bbhorta\b/g, 'ভর্তা')
    .replace(/\bshak\b/g, 'শাক').replace(/\bchola\b/g, 'ছোলা')
    .replace(/\bpeyara\b/g, 'পেয়ারা').replace(/\bkomla\b/g, 'কমলা')
    .replace(/\bmalta\b/g, 'মাল্টা').replace(/\bkacchi\b/g, 'কাচ্চি')
    .replace(/\bborhani\b/g, 'বোরহানি').trim();
}

// ═══════════════════════════════════════════════════════════════════
// 1. POST /api/nutrition/analyze — Food analysis (image + text)
// ═══════════════════════════════════════════════════════════════════
app.post('/api/nutrition/analyze', async (req, res) => {
  if (!requireKey(res)) return;
  try {
    const { imageBase64, mimeType, profile, description, consumedCalories, remainingCalories, mode = 'meal', recentMeals = [], healthContext = {} } = req.body ?? {};
    const normalizedDescription = normalizeBangla(description || '');

    if ((!imageBase64 || !mimeType) && !description) {
      return res.status(400).json({ error: 'imageBase64/mimeType অথবা description প্রয়োজন।' });
    }
    if (!profile) return res.status(400).json({ error: 'profile প্রয়োজন।' });

    const conditions = Array.isArray(profile.conditions) && profile.conditions.length > 0 ? profile.conditions.join(', ') : 'কোনো নির্দিষ্ট সমস্যা উল্লেখ নেই';
    const recentMealText = Array.isArray(recentMeals) && recentMeals.length > 0
      ? recentMeals.map((m) => `- ${m.date || ''} ${m.slot || ''}: ${m.foodName || ''} (${m.calories || 0} kcal)`).join('\n')
      : 'সাম্প্রতিক কোনো মিল হিস্ট্রি নেই';

    const base = `
ইউজারের তথ্য:
- নাম: ${profile.name}, লিঙ্গ: ${profile.gender || 'অজানা'}, বয়স: ${profile.age}
- ওজন: ${profile.weightKg}kg, উচ্চতা: ${profile.heightCm}cm
- লক্ষ্য: ${profile.goal}, স্বাস্থ্য সমস্যা: ${conditions}
- আজ এখন পর্যন্ত খেয়েছে: ${consumedCalories ?? 0} kcal, বাকি আছে: ${remainingCalories ?? 'অজানা'} kcal

গত কয়েক দিনের মিল প্যাটার্ন:
${recentMealText}

অতিরিক্ত health context: ${JSON.stringify(healthContext || {})}

নিয়ম:
1. generic analysis করবে না, নির্দিষ্ট বিশ্লেষণ দেবে।
2. user Roman Bangla, Bangla বা mixed spelling-এ লিখতে পারে।
3. mixed plate হলে ভাত, ডাল, মাছ, মাংস, শাক আলাদা reasoning দেবে।
4. user-এর সমস্যা অনুযায়ী red flag clearভাবে বলবে।
5. budget-friendly দেশীয় বিকল্প দেবে, foreign food দেবে না।
6. valid JSON ছাড়া অন্য কিছু দেবে না।
`;

    let prompt;
    if (mode === 'menu') {
      prompt = `${base}\nইনপুটটি restaurant menu বা food option list।\n${description ? `User লিখেছে: "${description}"` : 'ছবি থেকে menu পড়ে বোঝো।'}\n${normalizedDescription && normalizedDescription !== description ? `normalized রূপ: "${normalizedDescription}"` : ''}\nশুধু valid JSON:\n{"name":"আজকের সেরা বাছাই","analysis_mode":"menu","calories":0,"protein":0,"carbs":0,"fat":0,"fiber":0,"score":0,"score_reason":"কারণ","benefits":["উপকার"],"harms":["সতর্কতা"],"red_flags":[],"menu_suggestions":["অপশন ১","অপশন ২"],"best_choice":"সেরা item","condition_advice":"condition advice","memory_insight":"pattern insight","doctor_tip":"practical tip","alternative":"দেশীয় choice","budget_impact":"বাজেট insight"}`;
    } else if (mode === 'receipt') {
      prompt = `${base}\nইনপুটটি বাজার বা restaurant receipt।\n${description ? `User লিখেছে: "${description}"` : 'ছবি থেকে receipt পড়ে বোঝো।'}\nশুধু valid JSON:\n{"name":"বাজার বিশ্লেষণ","analysis_mode":"receipt","calories":0,"protein":0,"carbs":0,"fat":0,"fiber":0,"score":0,"score_reason":"কারণ","benefits":["ভালো দিক"],"harms":["উন্নতি দরকার"],"receipt_insights":["insight"],"grocery_suggestions":["পরের বাজারে কিনুন"],"condition_advice":"condition advice","doctor_tip":"practical tip","alternative":"স্বাস্থ্যকর choice","budget_impact":"বাজেট insight"}`;
    } else {
      prompt = `${base}\nইনপুটটি একটি খাবার বা mixed Bangladeshi plate।\n${description ? `User লিখেছে: "${description}"` : 'ছবি দেখে খাবার বিশ্লেষণ করো।'}\n${normalizedDescription && normalizedDescription !== description ? `normalized রূপ: "${normalizedDescription}"` : ''}\n${description ? 'description থাকলে সেটাকেই প্রধান input ধরে পূর্ণ nutrition analysis দেবে।' : ''}\nশুধু valid JSON:\n{"name":"খাবারের নাম","analysis_mode":"meal","calories":0,"protein":0,"carbs":0,"fat":0,"fiber":0,"vitamins":["ভিটামিন"],"minerals":["মিনারেল"],"score":0,"score_reason":"সংক্ষিপ্ত কারণ","benefits":["উপকার ১","উপকার ২"],"harms":["সতর্কতা"],"red_flags":["condition-specific warning"],"plate_breakdown":["প্লেটের অংশ"],"condition_advice":"condition advice","memory_insight":"pattern insight","doctor_tip":"practical tip","timing_advice":"কোন সময়ে ভালো","portion_advice":"কতটুকু খাওয়া উচিত","alternative":"স্বাস্থ্যকর দেশীয় বিকল্প","best_choice":"সেরা অংশ","budget_impact":"বাজেট insight"}`;
    }

    const contentParts = [{ text: prompt }];
    if (imageBase64 && mimeType) {
      contentParts.push({ inline_data: { mime_type: mimeType, data: imageBase64 } });
    }

    const systemInstruction = [
      'তুমি একজন অভিজ্ঞ বাংলাদেশি ডাক্তার, পুষ্টিবিদ এবং local food intelligence specialist।',
      'সব response বাংলায় দেবে এবং valid JSON ছাড়া অন্য কিছু দেবে না।',
      'কোনো foreign dish, western replacement বা non-Bangladeshi example ব্যবহার করবে না।',
    ].join(' ');

    const payload = await geminiCall(prompt, { parts: contentParts, temperature: 0.2, systemInstruction });
    const analysis = safeJsonParse(extractText(payload));

    res.json({ model: { id: geminiModel, name: 'Gemini', version: geminiModel }, analysis });
  } catch (e) {
    console.error('Error in /api/nutrition/analyze:', e);
    res.status(500).json({ error: errStr(e) });
  }
});

// ═══════════════════════════════════════════════════════════════════
// 2. POST /api/doctor-note — AI Doctor's personalized note
// ═══════════════════════════════════════════════════════════════════
app.post('/api/doctor-note', async (req, res) => {
  if (!requireKey(res)) return;
  try {
    const { profile, todayData, recentCategories = [], historicalContext = {} } = req.body ?? {};
    if (!profile || !todayData) return res.status(400).json({ error: 'profile এবং todayData প্রয়োজন।' });

    const now = new Date();
    const hour = now.getHours();
    const dayOfWeek = ['রবিবার','সোমবার','মঙ্গলবার','বুধবার','বৃহস্পতিবার','শুক্রবার','শনিবার'][now.getDay()];
    const timeOfDay = hour < 6 ? 'রাত' : hour < 12 ? 'সকাল' : hour < 17 ? 'দুপুর' : hour < 20 ? 'বিকাল' : 'রাত';

    const allCategories = ['morning_routine','food_suggestion','water_reminder','exercise_tip','sleep_advice','meditation_stress','mental_health','lifestyle_habit','condition_specific','nutrition_fact','motivation','digestion','sexual_health','hormonal_health','posture_ergonomics','breathing_exercise','sunlight_vitamin_d','intermittent_fasting','gut_health','immune_system'];
    const timePriority = { সকাল: ['morning_routine','food_suggestion','sunlight_vitamin_d'], দুপুর: ['food_suggestion','water_reminder','digestion'], বিকাল: ['exercise_tip','water_reminder','motivation'], রাত: ['sleep_advice','mental_health','meditation_stress'] };
    const prioritized = [...(timePriority[timeOfDay] || []), ...allCategories].filter((item, i, arr) => arr.indexOf(item) === i);
    const category = prioritized.find((item) => !recentCategories.includes(item)) || prioritized[0];

    const conditions = Array.isArray(profile.conditions) && profile.conditions.length > 0 ? profile.conditions.join(', ') : 'কোনো নির্দিষ্ট সমস্যা উল্লেখ নেই';
    const bmi = profile.weightKg && profile.heightCm ? (profile.weightKg / ((profile.heightCm / 100) ** 2)).toFixed(1) : '0.0';

    const prompt = `তুমি একজন অভিজ্ঞ বাংলাদেশি ডাক্তার, পুষ্টিবিদ ও behaviour coach।
এখন ${timeOfDay}, ${dayOfWeek}।

ইউজার: ${profile.name}, বয়স: ${profile.age}, লিঙ্গ: ${profile.gender || 'অজানা'}, BMI: ${bmi}
লক্ষ্য: ${profile.goal}, সমস্যা: ${conditions}
আজ খেয়েছে: ${todayData.totalCal || 0} kcal, প্রোটিন: ${todayData.totalProtein || 0}g, পানি: ${todayData.waterLog || 0}/8
ব্যায়াম: ${todayData.exerciseDone || 0}টি, পোড়া: ${todayData.burnedCal || 0} kcal, বাকি: ${todayData.remainCal || 0}

গত কয়েক দিনের pattern: ${JSON.stringify(historicalContext || {}, null, 2)}

পরামর্শের ধরন: ${category}

শুধু valid JSON:
{"content":"২-৩ বাক্যের উষ্ণ, নির্দিষ্ট পরামর্শ","category":"${category}","contextSnapshot":{"timeOfDay":"${timeOfDay}","dayOfWeek":"${dayOfWeek}","totalCal":${todayData.totalCal || 0},"waterLog":${todayData.waterLog || 0},"exerciseDone":${todayData.exerciseDone || 0}}}

নিয়ম: ${profile.name} নাম ১বার ব্যবহার করবে, generic advice নয়, calm premium tone, বাংলায়।`;

    const payload = await geminiCall(prompt, { temperature: 0.35 });
    const parsed = safeJsonParse(extractText(payload));
    res.json(parsed);
  } catch (e) {
    console.error('Error in /api/doctor-note:', e);
    res.status(500).json({ error: errStr(e) });
  }
});

// ═══════════════════════════════════════════════════════════════════
// 3. POST /api/exercise-plan — AI Exercise suggestions
// ═══════════════════════════════════════════════════════════════════
app.post('/api/exercise-plan', async (req, res) => {
  if (!requireKey(res)) return;
  try {
    const { profile, historicalContext = {} } = req.body ?? {};
    if (!profile) return res.status(400).json({ error: 'profile প্রয়োজন।' });

    const bmi = profile.weightKg && profile.heightCm ? (profile.weightKg / ((profile.heightCm / 100) ** 2)).toFixed(1) : '0.0';
    const conditions = Array.isArray(profile.conditions) && profile.conditions.length > 0 ? profile.conditions.join(', ') : 'কোনো সমস্যা নেই';

    const prompt = `তুমি একজন বাংলাদেশি fitness coach।

ইউজার: ${profile.name}, বয়স: ${profile.age}, লিঙ্গ: ${profile.gender || 'অজানা'}, BMI: ${bmi}
লক্ষ্য: ${profile.goal}, সমস্যা: ${conditions}

context: ${JSON.stringify(historicalContext || {}, null, 2)}

আজকের জন্য ৩টি উপযুক্ত ব্যায়াম suggest করো। equipment-less, ঘরে করা যায় এমন।

শুধু JSON:
{"items":[{"name":"ব্যায়ামের নাম বাংলায়","duration_minutes":15,"calories_burned":80,"instructions":"কিভাবে করবে","condition_benefit":"কোন সমস্যায় সাহায্য করে"}]}`;

    const payload = await geminiCall(prompt, { temperature: 0.28 });
    const parsed = safeJsonParse(extractText(payload));
    res.json(parsed);
  } catch (e) {
    console.error('Error in /api/exercise-plan:', e);
    res.status(500).json({ error: errStr(e) });
  }
});

// ═══════════════════════════════════════════════════════════════════
// 4. POST /api/meal-plan — AI Weekly meal plan
// ═══════════════════════════════════════════════════════════════════
app.post('/api/meal-plan', async (req, res) => {
  if (!requireKey(res)) return;
  try {
    const { profile, weekOf, historicalContext = {} } = req.body ?? {};
    if (!profile) return res.status(400).json({ error: 'profile প্রয়োজন।' });

    const conditions = Array.isArray(profile.conditions) && profile.conditions.length > 0 ? profile.conditions.join(', ') : 'কোনো সমস্যা নেই';

    const prompt = `তুমি একজন বাংলাদেশি nutrition planner।

ইউজার: ${profile.name}, বয়স: ${profile.age}, ওজন: ${profile.weightKg}kg, উচ্চতা: ${profile.heightCm}cm
দৈনিক ক্যালরি: ${profile.dailyCalorieTarget || 0} kcal, লক্ষ্য: ${profile.goal}, সমস্যা: ${conditions}
সপ্তাহ: ${weekOf || ''}

context: ${JSON.stringify(historicalContext || {}, null, 2)}

শুধু বাংলাদেশি সহজলভ্য খাবার, budget-friendly, practical।

শুধু JSON:
{"plan":{"weekOf":"${weekOf || ''}","days":{"saturday":{"morning":{"items":["খাবার"],"calories":320},"lunch":{"items":["খাবার"],"calories":480},"afternoon":{"items":["খাবার"],"calories":160},"night":{"items":["খাবার"],"calories":360}},"sunday":{},"monday":{},"tuesday":{},"wednesday":{},"thursday":{},"friday":{}},"weeklyTips":["টিপস"],"specialNotes":"নোট"}}`;

    const payload = await geminiCall(prompt, { temperature: 0.32 });
    const parsed = safeJsonParse(extractText(payload));
    res.json(parsed);
  } catch (e) {
    console.error('Error in /api/meal-plan:', e);
    res.status(500).json({ error: errStr(e) });
  }
});

// ═══════════════════════════════════════════════════════════════════
// 5. POST /api/wellness/complete — Log wellness module completion
// ═══════════════════════════════════════════════════════════════════
app.post('/api/wellness/complete', async (req, res) => {
  try {
    const { userId, moduleId, duration = 0, details = {} } = req.body ?? {};
    if (!userId || !moduleId) return res.status(400).json({ error: 'userId এবং moduleId প্রয়োজন।' });
    // Without Firestore admin, return success — data is stored locally on device
    res.json({ success: true, streak: 1 });
  } catch (e) {
    console.error('Error in /api/wellness/complete:', e);
    res.status(500).json({ error: errStr(e) });
  }
});

// ═══════════════════════════════════════════════════════════════════
// 6. POST /api/wellness/nofap-reset — Reset NoFap streak
// ═══════════════════════════════════════════════════════════════════
app.post('/api/wellness/nofap-reset', async (req, res) => {
  try {
    const { userId } = req.body ?? {};
    if (!userId) return res.status(400).json({ error: 'userId প্রয়োজন।' });
    res.json({ success: true });
  } catch (e) {
    console.error('Error in /api/wellness/nofap-reset:', e);
    res.status(500).json({ error: errStr(e) });
  }
});

// ═══════════════════════════════════════════════════════════════════
// 7. POST /api/wellness/daily-benefit — AI daily wellness tip
// ═══════════════════════════════════════════════════════════════════
app.post('/api/wellness/daily-benefit', async (req, res) => {
  try {
    const { userId } = req.body ?? {};
    if (!userId) return res.status(400).json({ error: 'userId প্রয়োজন।' });

    if (!geminiApiKey) {
      return res.json({ benefit: 'আজকের wellness অভ্যাসগুলো ধীরে ধীরে সম্পন্ন করুন। ছোট করে breathing দিয়ে শুরু করুন।' });
    }

    const prompt = `তুমি একজন বাংলাদেশি স্বাস্থ্য বিশেষজ্ঞ। এই মুহূর্তে ইউজারের জন্য একটি wellness পরামর্শ দাও। ২-৩ বাক্য, বাংলায়, motivating কিন্তু realistic। শুধু পরামর্শের text, কোনো JSON নয়।`;

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${geminiModel}:generateContent?key=${geminiApiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { temperature: 0.35 },
        }),
      },
    );
    const payload = await response.json();
    const benefit = response.ok ? (extractText(payload) || 'ধারাবাহিকতা বজায় রাখুন।') : 'ধারাবাহিকতা বজায় রাখুন।';
    res.json({ benefit });
  } catch (e) {
    res.json({ benefit: 'আজকের wellness অভ্যাসগুলো ধীরে ধীরে সম্পন্ন করুন।' });
  }
});

// ═══════════════════════════════════════════════════════════════════
// 8. POST /api/wellness/streak — Fetch wellness streaks
// ═══════════════════════════════════════════════════════════════════
app.post('/api/wellness/streak', async (req, res) => {
  try {
    const { userId } = req.body ?? {};
    if (!userId) return res.status(400).json({ error: 'userId প্রয়োজন।' });
    // Without Firestore admin, return empty — device has local data
    res.json({ success: true, streaks: {}, todayLogs: [], weekLogs: [], nofapTracker: null });
  } catch (e) {
    console.error('Error in /api/wellness/streak:', e);
    res.status(500).json({ error: errStr(e) });
  }
});

if (process.env.NODE_ENV !== 'production') {
  app.listen(port, () => {
    console.log(`Sushastho.ai backend listening on http://localhost:${port}`);
  });
}

export default app;
