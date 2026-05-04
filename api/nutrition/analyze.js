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
    const { imageBase64, mimeType, profile, description, consumedCalories, remainingCalories } = req.body ?? {};
    if ((!imageBase64 || !mimeType) && !description) {
      return res.status(400).json({ error: 'imageBase64/mimeType অথবা description প্রয়োজন।' });
    }

    if (!profile) {
      return res.status(400).json({ error: 'profile প্রয়োজন।' });
    }

    if (!geminiApiKey) {
      return res.status(500).json({ error: 'GEMINI_API_KEY is missing on backend.' });
    }

    const prompt = buildNutritionPrompt(profile, description, consumedCalories, remainingCalories);
    const contentParts = [{ text: prompt }];

    if (imageBase64 && mimeType) {
      contentParts.push({
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
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          system_instruction: {
            parts: [
              {
                text: 'আপনি একজন বিশেষজ্ঞ বাংলাদেশি পুষ্টিবিদ ও AI health guide। সব উত্তর বাংলায় দেবেন এবং শুধু valid JSON schema অনুসরণ করবেন।',
              },
            ],
          },
          contents: [{ parts: contentParts }],
          generationConfig: {
            temperature: 0.25,
            response_mime_type: 'application/json',
          },
        }),
      },
    );

    const json = await response.json();
    if (!response.ok) {
      return res.status(response.status).json({ error: json });
    }

    const text = extractText(json);
    const analysis = safeJsonParse(text);

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

function buildNutritionPrompt(profile, description, consumedCalories, remainingCalories) {
  const conditions = Array.isArray(profile.conditions) && profile.conditions.length > 0
    ? profile.conditions.join(', ')
    : 'কোনো নির্দিষ্ট রোগ উল্লেখ নেই';

  return `
তুমি একজন বিশেষজ্ঞ বাংলাদেশি পুষ্টিবিদ।

এই user-এর তথ্য:
- নাম: ${profile.name}
- বয়স: ${profile.age}
- ওজন: ${profile.weightKg}kg
- উচ্চতা: ${profile.heightCm}cm
- লক্ষ্য: ${profile.goal}
- স্বাস্থ্য সমস্যা: ${conditions}
- আজ এখন পর্যন্ত খেয়েছে: ${consumedCalories ?? 0} kcal
- আজ বাকি আছে: ${remainingCalories ?? 'অজানা'} kcal

${description ? `User লিখেছে: "${description}"` : 'ছবির খাবার বিশ্লেষণ করো।'}

গুরুত্বপূর্ণ:
1. যদি খাবারটি mixed Bangladeshi plate হয়, তাহলে ভাত, ডাল, মাছ, ভাজি, শাক, মাংস, সালাদ ইত্যাদি আলাদা করে reasoning দাও।
2. user-এর condition অনুযায়ী instant red flag থাকলে সেটা red_flags এ দাও।
3. advice এমন হতে হবে যেন personal doctor-এর মতো practical হয়।
4. data uncertain হলে reasonable estimate দাও, কিন্তু confident clinical tone রেখো।

শুধু valid JSON দাও:
{
  "name": "খাবারের নাম",
  "calories": 0,
  "protein": 0,
  "carbs": 0,
  "fat": 0,
  "fiber": 0,
  "vitamins": ["ভিটামিন A"],
  "minerals": ["আয়রন"],
  "score": 85,
  "score_reason": "সংক্ষিপ্ত ব্যাখ্যা",
  "benefits": ["উপকার ১", "উপকার ২"],
  "harms": ["সতর্কতা ১"],
  "red_flags": ["condition-specific instant warning"],
  "plate_breakdown": ["প্লেটের অংশ ১", "প্লেটের অংশ ২"],
  "condition_advice": "এই user-এর সমস্যার জন্য advice",
  "doctor_tip": "খাওয়ার পর doctor-style ছোট practical tip",
  "timing_advice": "দিনের কোন সময় উপযুক্ত",
  "portion_advice": "কতটুকু খাওয়া উচিত",
  "alternative": "আরও স্বাস্থ্যকর দেশীয় বিকল্প",
  "remaining_after": 0
}
`;
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
