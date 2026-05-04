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
    const { profile, todayData, recentCategories = [], historicalContext = {} } = req.body ?? {};
    if (!profile || !todayData) {
      return res.status(400).json({ error: 'profile এবং todayData প্রয়োজন।' });
    }
    if (!geminiApiKey) {
      return res.status(500).json({ error: 'GEMINI_API_KEY is missing on backend.' });
    }

    const prompt = buildDoctorNotePrompt(profile, todayData, recentCategories, historicalContext);
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${geminiModel}:generateContent?key=${geminiApiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            temperature: 0.35,
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

function buildDoctorNotePrompt(profile, todayData, recentCategories, historicalContext) {
  const now = new Date();
  const hour = now.getHours();
  const dayOfWeek = ['রবিবার', 'সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার', 'শুক্রবার', 'শনিবার'][now.getDay()];
  const timeOfDay = hour < 6 ? 'রাত' : hour < 12 ? 'সকাল' : hour < 17 ? 'দুপুর' : hour < 20 ? 'বিকাল' : 'রাত';
  const allCategories = [
    'morning_routine',
    'food_suggestion',
    'water_reminder',
    'exercise_tip',
    'sleep_advice',
    'meditation_stress',
    'mental_health',
    'lifestyle_habit',
    'condition_specific',
    'nutrition_fact',
    'motivation',
    'digestion',
    'sexual_health',
    'hormonal_health',
    'posture_ergonomics',
    'breathing_exercise',
    'sunlight_vitamin_d',
    'intermittent_fasting',
    'gut_health',
    'immune_system',
  ];

  const timePriority = {
    সকাল: ['morning_routine', 'food_suggestion', 'sunlight_vitamin_d'],
    দুপুর: ['food_suggestion', 'water_reminder', 'digestion'],
    বিকাল: ['exercise_tip', 'water_reminder', 'motivation'],
    রাত: ['sleep_advice', 'mental_health', 'meditation_stress'],
  };

  const prioritized = [...(timePriority[timeOfDay] || []), ...allCategories]
    .filter((item, index, arr) => arr.indexOf(item) === index);
  const category = prioritized.find((item) => !recentCategories.includes(item)) || prioritized[0];

  const bmi = profile.weightKg && profile.heightCm
    ? (profile.weightKg / ((profile.heightCm / 100) ** 2)).toFixed(1)
    : '0.0';

  const conditions = Array.isArray(profile.conditions) && profile.conditions.length > 0
    ? profile.conditions.join(', ')
    : 'কোনো নির্দিষ্ট সমস্যা উল্লেখ নেই';

  return `
তুমি একজন অভিজ্ঞ বাংলাদেশি ডাক্তার, পুষ্টিবিদ, স্বাস্থ্য-সহচর এবং behaviour coach।
এখন ${timeOfDay}, ${dayOfWeek}।

ইউজারের তথ্য:
- নাম: ${profile.name}
- বয়স: ${profile.age}
- লিঙ্গ: ${profile.gender || 'অজানা'}
- ওজন: ${profile.weightKg}kg
- উচ্চতা: ${profile.heightCm}cm
- BMI: ${bmi}
- লক্ষ্য: ${profile.goal}
- স্বাস্থ্য সমস্যা: ${conditions}
- আজ খেয়েছে: ${todayData.totalCal || 0} kcal
- আজ প্রোটিন: ${todayData.totalProtein || 0} g
- আজ পানি: ${todayData.waterLog || 0}/8 গ্লাস
- আজ ব্যায়াম: ${todayData.exerciseDone || 0}টি
- আজ পোড়া ক্যালরি: ${todayData.burnedCal || 0}
- আজ বাকি ক্যালরি: ${todayData.remainCal || 0}

গত কয়েক দিনের বাস্তব pattern:
${JSON.stringify(historicalContext || {}, null, 2)}

পরামর্শের ধরন: ${category}

শুধু valid JSON দাও:
{
  "content": "২-৩ বাক্যের উষ্ণ, নির্দিষ্ট, ডাক্তার-মানের পরামর্শ",
  "category": "${category}",
  "contextSnapshot": {
    "timeOfDay": "${timeOfDay}",
    "dayOfWeek": "${dayOfWeek}",
    "totalCal": ${todayData.totalCal || 0},
    "waterLog": ${todayData.waterLog || 0},
    "exerciseDone": ${todayData.exerciseDone || 0}
  }
}

নিয়ম:
- ${profile.name} নাম একবার ব্যবহার করবে
- generic advice দেবে না
- historicalContext-এর অন্তত ১টি বাস্তব pattern mention করবে, যদি relevant হয়
- যদি পানি, প্রোটিন, meal pattern, sleep, steps বা repeated food trend দেখা যায়, সেটা explain করবে
- কোনো ভয় দেখানো ভাষা নয়; calm, premium, helpful tone
- বাংলায় লিখবে
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
