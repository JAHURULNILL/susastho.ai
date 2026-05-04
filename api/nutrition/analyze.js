const { buildLocalFoodKnowledge } = require('../_local_food_knowledge');

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed.' });
  }

  const geminiApiKey = process.env.GEMINI_API_KEY || '';
  const geminiModel = process.env.GEMINI_MODEL || 'gemini-2.5-flash';

  try {
    const {
      imageBase64,
      mimeType,
      profile,
      description,
      consumedCalories,
      remainingCalories,
      mode = 'meal',
      recentMeals = [],
      healthContext = {},
    } = req.body ?? {};

    if ((!imageBase64 || !mimeType) && !description) {
      return res.status(400).json({ error: 'imageBase64/mimeType অথবা description প্রয়োজন।' });
    }

    if (!profile) {
      return res.status(400).json({ error: 'profile প্রয়োজন।' });
    }

    if (!geminiApiKey) {
      return res.status(500).json({ error: 'GEMINI_API_KEY is missing on backend.' });
    }

    const prompt = buildNutritionPrompt({
      profile,
      description,
      consumedCalories,
      remainingCalories,
      mode,
      recentMeals,
      healthContext,
    });

    const parts = [{ text: prompt }];
    if (imageBase64 && mimeType) {
      parts.push({
        inline_data: {
          mime_type: mimeType,
          data: imageBase64,
        },
      });
    }

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${geminiModel}:generateContent?key=${geminiApiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          system_instruction: {
            parts: [
              {
                text: 'তুমি একজন অভিজ্ঞ বাংলাদেশি ডাক্তার, পুষ্টিবিদ, health coach এবং local food intelligence specialist। সব user-visible response বাংলায় দেবে এবং valid JSON ছাড়া অন্য কিছু দেবে না।',
              },
            ],
          },
          contents: [{ parts }],
          generationConfig: {
            temperature: 0.22,
            response_mime_type: 'application/json',
          },
        }),
      },
    );

    const json = await response.json();
    if (!response.ok) {
      return res.status(response.status).json({ error: json });
    }

    return res.status(200).json({
      model: {
        id: geminiModel,
        name: 'Gemini',
        version: geminiModel,
      },
      analysis: safeJsonParse(extractText(json)),
    });
  } catch (error) {
    return res.status(500).json({ error: stringifyError(error) });
  }
};

function buildNutritionPrompt({
  profile,
  description,
  consumedCalories,
  remainingCalories,
  mode,
  recentMeals,
  healthContext,
}) {
  const conditions = Array.isArray(profile.conditions) && profile.conditions.length > 0
    ? profile.conditions.join(', ')
    : 'কোনো নির্দিষ্ট সমস্যা উল্লেখ নেই';

  const recentMealText = Array.isArray(recentMeals) && recentMeals.length > 0
    ? recentMeals
        .map((meal) => `- ${meal.date || ''} ${meal.slot || ''}: ${meal.foodName || ''} (${meal.calories || 0} kcal)`)
        .join('\n')
    : 'সাম্প্রতিক কোনো মিল হিস্ট্রি নেই';

  const localFoodKnowledge = buildLocalFoodKnowledge(description || '');

  const base = `
ইউজারের তথ্য:
- নাম: ${profile.name}
- লিঙ্গ: ${profile.gender || 'অজানা'}
- বয়স: ${profile.age}
- ওজন: ${profile.weightKg}kg
- উচ্চতা: ${profile.heightCm}cm
- লক্ষ্য: ${profile.goal}
- স্বাস্থ্য সমস্যা: ${conditions}
- আজ এখন পর্যন্ত খেয়েছে: ${consumedCalories ?? 0} kcal
- আজ বাকি আছে: ${remainingCalories ?? 'অজানা'} kcal

গত কয়েক দিনের মিল প্যাটার্ন:
${recentMealText}

অতিরিক্ত health context:
${JSON.stringify(healthContext || {})}

লোকাল খাবারের reference:
${localFoodKnowledge}

নিয়ম:
1. generic analysis করবে না।
2. দেশীয় mixed plate হলে ভাত, ডাল, মাছ, মাংস, শাক, ভর্তা আলাদা reasoning দেবে।
3. user-এর সমস্যা অনুযায়ী instant red flag থাকলে clearভাবে বলবে।
4. recent pattern থাকলে memory_insight-এ সেটা ব্যবহার করবে।
5. budget-friendly deshi বিকল্প থাকলে alternative-এ বলবে।
`;

  if (mode === 'menu') {
    return `${base}

ইনপুটটি restaurant menu বা food option list।
${description ? `User লিখেছে: "${description}"` : 'ছবি থেকে menu পড়ে বোঝো।'}

শুধু valid JSON দাও:
{
  "name": "আজকের সেরা বাছাই",
  "analysis_mode": "menu",
  "calories": 0,
  "protein": 0,
  "carbs": 0,
  "fat": 0,
  "fiber": 0,
  "score": 0,
  "score_reason": "এক লাইনের কারণ",
  "benefits": ["উপকার ১"],
  "harms": ["সতর্কতা ১"],
  "red_flags": ["তাৎক্ষণিক সতর্কতা"],
  "menu_suggestions": ["ভালো অপশন ১", "ভালো অপশন ২", "ভালো অপশন ৩"],
  "best_choice": "সবচেয়ে ভালো item এবং কেন",
  "condition_advice": "ইউজারের condition অনুযায়ী menu decision",
  "memory_insight": "গত কয়েক দিনের pattern ধরে insight",
  "doctor_tip": "order করার আগে ছোট practical tip",
  "alternative": "আরও ভালো দেশীয় choice",
  "budget_impact": "বাজেট অনুযায়ী insight"
}`;
  }

  if (mode === 'receipt') {
    return `${base}

ইনপুটটি বাজার বা restaurant receipt।
${description ? `User লিখেছে: "${description}"` : 'ছবি থেকে receipt পড়ে বোঝো।'}

শুধু valid JSON দাও:
{
  "name": "এই সপ্তাহের বাজার বিশ্লেষণ",
  "analysis_mode": "receipt",
  "calories": 0,
  "protein": 0,
  "carbs": 0,
  "fat": 0,
  "fiber": 0,
  "score": 0,
  "score_reason": "এক লাইনের কারণ",
  "benefits": ["ভালো দিক ১"],
  "harms": ["উন্নতি দরকার ১"],
  "receipt_insights": ["receipt insight ১", "receipt insight ২"],
  "grocery_suggestions": ["পরের বাজারে কিনুন ১", "পরের বাজারে কিনুন ২"],
  "memory_insight": "shopping pattern ধরে insight",
  "condition_advice": "এই shopping pattern user-এর condition-এ কেমন impact ফেলবে",
  "doctor_tip": "পরের বাজারের আগে ছোট practical tip",
  "alternative": "আরও স্বাস্থ্যকর দেশীয় market choice",
  "budget_impact": "স্বাস্থ্য বনাম বাজেট insight"
}`;
  }

  return `${base}

ইনপুটটি একটি খাবার বা mixed Bangladeshi plate।
${description ? `User লিখেছে: "${description}"` : 'ছবি দেখে খাবার বিশ্লেষণ করো।'}

শুধু valid JSON দাও:
{
  "name": "খাবারের নাম",
  "analysis_mode": "meal",
  "calories": 0,
  "protein": 0,
  "carbs": 0,
  "fat": 0,
  "fiber": 0,
  "vitamins": ["ভিটামিন A"],
  "minerals": ["আয়রন"],
  "score": 0,
  "score_reason": "সংক্ষিপ্ত কারণ",
  "benefits": ["উপকার ১", "উপকার ২", "উপকার ৩"],
  "harms": ["সতর্কতা ১"],
  "red_flags": ["condition-specific instant warning"],
  "plate_breakdown": ["প্লেটের অংশ ১", "প্লেটের অংশ ২"],
  "condition_advice": "এই ইউজারের condition অনুযায়ী advice",
  "memory_insight": "গত কয়েক দিনের pattern অনুযায়ী insight",
  "doctor_tip": "খাওয়ার পরে practical tip",
  "timing_advice": "দিনের কোন সময়ে ভালো",
  "portion_advice": "কতটুকু খাওয়া উচিত",
  "alternative": "আরও স্বাস্থ্যকর দেশীয় বিকল্প",
  "best_choice": "এই খাবারের সেরা অংশ",
  "budget_impact": "বাজেট বিষয়ে insight",
  "remaining_after": 0
}`;
}

function extractText(payload) {
  const parts = payload?.candidates?.[0]?.content?.parts;
  const text = Array.isArray(parts)
    ? parts.map((part) => part?.text).filter(Boolean).join('\n')
    : '';
  if (!text) {
    throw new Error('Gemini response is empty.');
  }
  return text;
}

function safeJsonParse(text) {
  const cleaned = String(text).replace(/```json/g, '').replace(/```/g, '').trim();
  const start = cleaned.indexOf('{');
  const end = cleaned.lastIndexOf('}');
  if (start === -1 || end === -1) {
    throw new Error('Model JSON parse failed.');
  }
  return JSON.parse(cleaned.slice(start, end + 1));
}

function stringifyError(error) {
  return error instanceof Error ? error.message : String(error);
}
