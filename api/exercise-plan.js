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
    const { profile, historicalContext = {} } = req.body ?? {};
    if (!profile) {
      return res.status(400).json({ error: 'profile প্রয়োজন।' });
    }
    if (!geminiApiKey) {
      return res.status(500).json({ error: 'GEMINI_API_KEY is missing on backend.' });
    }

    const prompt = buildExercisePrompt(profile, historicalContext);
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${geminiModel}:generateContent?key=${geminiApiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            temperature: 0.28,
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

function buildExercisePrompt(profile, historicalContext) {
  const bmi = profile.weightKg && profile.heightCm
    ? (profile.weightKg / ((profile.heightCm / 100) ** 2)).toFixed(1)
    : '0.0';
  const conditions = Array.isArray(profile.conditions) && profile.conditions.length > 0
    ? profile.conditions.join(', ')
    : 'কোনো নির্দিষ্ট সমস্যা উল্লেখ নেই';

  return `
তুমি একজন অভিজ্ঞ বাংলাদেশি fitness coach এবং rehabilitation-aware health guide।

ইউজার:
- নাম: ${profile.name}
- বয়স: ${profile.age}
- লিঙ্গ: ${profile.gender || 'অজানা'}
- BMI: ${bmi}
- লক্ষ্য: ${profile.goal}
- স্বাস্থ্য সমস্যা: ${conditions}

সাম্প্রতিক বাস্তব context:
${JSON.stringify(historicalContext || {}, null, 2)}

আজকের জন্য ৩টি উপযুক্ত ব্যায়াম suggest করো।

শুধু JSON:
{
  "items": [
    {
      "name": "ব্যায়ামের নাম বাংলায়",
      "duration_minutes": 15,
      "calories_burned": 80,
      "instructions": "এক লাইনে কিভাবে করবে",
      "condition_benefit": "এই ব্যায়াম তার কোন সমস্যায় কীভাবে সাহায্য করে"
    }
  ]
}

নিয়ম:
- equipment-less বা ঘরে করা যায় এমন ব্যায়াম prefer করবে
- historicalContext-এ steps কম থাকলে walking/mobility mix রাখবে
- belly fat/obesity থাকলে walk + core + consistency mix রাখবে
- urinary বা পুরুষ স্বাস্থ্যের concern থাকলে pelvic floor / kegel relevant হলে include করবে
- sleep trend খারাপ হলে রাতে heavy workout না দিয়ে calming movement দেবে
- exercise practical, safe, beginner-friendly এবং premium coaching tone-এ হবে
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
