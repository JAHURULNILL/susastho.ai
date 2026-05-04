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
    const { profile, weekOf, historicalContext = {} } = req.body ?? {};
    if (!profile) {
      return res.status(400).json({ error: 'profile প্রয়োজন।' });
    }
    if (!geminiApiKey) {
      return res.status(500).json({ error: 'GEMINI_API_KEY is missing on backend.' });
    }

    const prompt = buildMealPlanPrompt(profile, weekOf, historicalContext);
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${geminiModel}:generateContent?key=${geminiApiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            temperature: 0.32,
            response_mime_type: 'application/json',
          },
        }),
      },
    );

    const json = await response.json();
    if (!response.ok) {
      return res.status(response.status).json({ error: json });
    }

    const parsed = safeJsonParse(extractText(json));
    return res.status(200).json(parsed);
  } catch (error) {
    return res.status(500).json({ error: stringifyError(error) });
  }
};

function buildMealPlanPrompt(profile, weekOf, historicalContext) {
  const conditions = Array.isArray(profile.conditions) && profile.conditions.length > 0
    ? profile.conditions.join(', ')
    : 'কোনো নির্দিষ্ট সমস্যা উল্লেখ নেই';

  return `
তুমি একজন অভিজ্ঞ বাংলাদেশি nutrition planner।

ইউজারের তথ্য:
- নাম: ${profile.name}
- বয়স: ${profile.age}
- লিঙ্গ: ${profile.gender || 'অজানা'}
- ওজন: ${profile.weightKg}kg
- উচ্চতা: ${profile.heightCm}cm
- দৈনিক ক্যালরি লক্ষ্য: ${profile.dailyCalorieTarget || 0} kcal
- লক্ষ্য: ${profile.goal}
- স্বাস্থ্য সমস্যা: ${conditions}
- সপ্তাহ শুরু: ${weekOf || ''}

গত কয়েক দিনের বাস্তব context:
${JSON.stringify(historicalContext || {}, null, 2)}

এই সপ্তাহের জন্য meal plan বানাও।

শুধু JSON:
{
  "plan": {
    "weekOf": "${weekOf || ''}",
    "days": {
      "saturday": {
        "morning": { "items": ["খাবার ১", "খাবার ২"], "calories": 320 },
        "lunch": { "items": ["খাবার ১", "খাবার ২"], "calories": 480 },
        "afternoon": { "items": ["খাবার ১"], "calories": 160 },
        "night": { "items": ["খাবার ১", "খাবার ২"], "calories": 360 }
      },
      "sunday": {},
      "monday": {},
      "tuesday": {},
      "wednesday": {},
      "thursday": {},
      "friday": {}
    },
    "weeklyTips": ["টিপস ১", "টিপস ২"],
    "specialNotes": "বিশেষ নোট"
  }
}

নিয়ম:
- শুধু বাংলাদেশি সহজলভ্য খাবার ব্যবহার করবে
- একই খাবার বারবার repeat করবে না
- historicalContext-এ repeated foods থাকলে smart rotation করবে
- যদি পানি কম, প্রোটিন কম, বা high-carb pattern থাকে, plan-এ সেটা rebalance করবে
- ডায়াবেটিস/পেটের চর্বি থাকলে refined carb কমাবে
- digestion issue থাকলে রাতের খাবার হালকা করবে
- budget-friendly mix রাখবে
- plan practical, home-friendly, premium এবং realistic হবে
`;
}

function extractText(payload) {
  const parts = payload?.candidates?.[0]?.content?.parts;
  const text = Array.isArray(parts) ? parts.map((part) => part?.text).filter(Boolean).join('\n') : '';
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

function stringifyError(error) {
  return error instanceof Error ? error.message : String(error);
}
