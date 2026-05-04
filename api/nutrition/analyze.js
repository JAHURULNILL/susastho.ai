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

    const normalizedDescription = normalizeBanglaDescription(description || '');

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
      normalizedDescription,
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
                text: [
                  'তুমি একজন অভিজ্ঞ বাংলাদেশি ডাক্তার, পুষ্টিবিদ, health coach এবং local Bangladeshi food intelligence specialist।',
                  'সব user-visible response বাংলায় দেবে এবং valid JSON ছাড়া অন্য কিছু দেবে না।',
                  'সব analysis, alternative, menu suggestion, grocery suggestion, warning এবং doctor tip শুধু বাংলাদেশি খাবার, বাংলাদেশি রান্না ও বাংলাদেশি lifestyle context অনুযায়ী হবে।',
                  'কোনো foreign dish, western replacement বা non-Bangladeshi example ব্যবহার করবে না।',
                ].join(' '),
              },
            ],
          },
          contents: [{ parts }],
          generationConfig: {
            temperature: 0.2,
            response_mime_type: 'application/json',
          },
        }),
      },
    );

    const json = await response.json();

    if (!response.ok) {
      return res.status(response.status).json({ error: json });
    }

    const analysis = safeJsonParse(extractText(json));

    return res.status(200).json({
      model: {
        id: geminiModel,
        name: 'Gemini',
        version: geminiModel,
      },
      analysis,
    });
  } catch (error) {
    return res.status(500).json({ error: stringifyError(error) });
  }
};

function buildNutritionPrompt({
  profile,
  description,
  normalizedDescription,
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

  const localFoodKnowledge = buildLocalFoodKnowledge(normalizedDescription || description || '');

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
2. user Roman Bangla, Bangla বা mixed spelling-এ লিখতে পারে। আগে সেটা বাংলাদেশি খাবারের বাস্তব নাম হিসেবে বুঝে নেবে।
3. যদি user একাধিক meal একসাথে লিখে, combined intake ধরে হিসাব করবে।
4. mixed plate হলে ভাত, ডাল, মাছ, মাংস, শাক, ভর্তা আলাদা reasoning দেবে।
5. user-এর সমস্যার অনুযায়ী instant red flag থাকলে clearভাবে বলবে।
6. recent pattern থাকলে memory_insight-এ সেটা ব্যবহার করবে।
7. budget-friendly deshi বিকল্প থাকলে alternative-এ বলবে।
8. local food knowledge base-এর দেশীয় খাবারগুলোকে priority দেবে।
9. alternative, best_choice, grocery_suggestions, menu_suggestions এবং doctor_tip-এ foreign food দেবে না।
10. valid JSON ছাড়া অন্য কোনো text দেবে না।
`;

  if (mode === 'menu') {
    return `${base}

ইনপুটটি restaurant menu বা food option list।
${description ? `User লিখেছে: "${description}"` : 'ছবি থেকে menu পড়ে বোঝো।'}
${normalizedDescription && normalizedDescription !== description ? `বোঝা normalized রূপ: "${normalizedDescription}"` : ''}

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
${normalizedDescription && normalizedDescription !== description ? `বোঝা normalized রূপ: "${normalizedDescription}"` : ''}

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
${normalizedDescription && normalizedDescription !== description ? `বোঝা normalized রূপ: "${normalizedDescription}"` : ''}
${description ? 'গুরুত্বপূর্ণ: description থাকলে সেটাকেই প্রধান input হিসেবে ধরে নির্দিষ্ট খাবার, meal slot, portion এবং context বোঝো। শুধু text input থেকেও পূর্ণ nutrition analysis দেবে।' : ''}

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
  "budget_impact": "বাজেট বিষয়ক insight",
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

function normalizeBanglaDescription(input) {
  return String(input || '')
    .toLowerCase()
    .replace(/\bvaat\b/g, 'ভাত')
    .replace(/\bbhat\b/g, 'ভাত')
    .replace(/\bdupure\b/g, 'দুপুরে')
    .replace(/\bdupur\b/g, 'দুপুর')
    .replace(/\bshokale\b/g, 'সকালে')
    .replace(/\bsokale\b/g, 'সকালে')
    .replace(/\brate\b/g, 'রাতে')
    .replace(/\bnoina\b/g, 'নয়না')
    .replace(/\bnoyna\b/g, 'নয়না')
    .replace(/\bmach\b/g, 'মাছ')
    .replace(/\bmaach\b/g, 'মাছ')
    .replace(/\bjhol\b/g, 'ঝোল')
    .replace(/\bdal\b/g, 'ডাল')
    .replace(/\bdim\b/g, 'ডিম')
    .replace(/\bgorur mangsho\b/g, 'গরুর মাংস')
    .replace(/\bmurgi\b/g, 'মুরগি')
    .replace(/\bkola\b/g, 'কলা')
    .replace(/\bdudh\b/g, 'দুধ')
    .replace(/\bpanta\b/g, 'পান্তা')
    .replace(/\bbhorta\b/g, 'ভর্তা')
    .replace(/\bshak\b/g, 'শাক')
    .replace(/\bchola\b/g, 'ছোলা')
    .replace(/\bpeyara\b/g, 'পেয়ারা')
    .replace(/\bkomla\b/g, 'কমলা')
    .replace(/\bmalta\b/g, 'মাল্টা')
    .replace(/\bkacchi\b/g, 'কাচ্চি')
    .replace(/\bborhani\b/g, 'বোরহানি')
    .trim();
}
