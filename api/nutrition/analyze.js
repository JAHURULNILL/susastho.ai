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
    const { imageBase64, mimeType, profile, description } = req.body ?? {};
    if ((!imageBase64 || !mimeType) && !description) {
      return res.status(400).json({ error: 'imageBase64/mimeType অথবা description প্রয়োজন।' });
    }

    if (!profile) {
      return res.status(400).json({ error: 'profile প্রয়োজন।' });
    }

    if (!geminiApiKey) {
      return res.status(500).json({ error: 'GEMINI_API_KEY is missing on backend.' });
    }

    const prompt = buildNutritionPrompt(profile, description);
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
                text: 'আপনি একজন বিশেষজ্ঞ বাংলাদেশি পুষ্টিবিদ। সব উত্তর বাংলায় দেবেন এবং শুধু JSON schema অনুসরণ করবেন।',
              },
            ],
          },
          contents: [{ parts: contentParts }],
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

function buildNutritionPrompt(profile, description) {
  const conditions = Array.isArray(profile.conditions) && profile.conditions.length > 0
    ? profile.conditions.join(', ')
    : 'কোনো নির্দিষ্ট রোগ উল্লেখ নেই';

  return `
তুমি একজন বিশেষজ্ঞ বাংলাদেশি পুষ্টিবিদ।
ইউজারের তথ্য:
- নাম: ${profile.name}
- বয়স: ${profile.age}
- ওজন: ${profile.weightKg}kg
- উচ্চতা: ${profile.heightCm}cm
- স্বাস্থ্য সমস্যা: ${conditions}
- দৈনিক লক্ষ্য: ${profile.goal}

${description ? `ইউজার লিখেছে: "${description}"` : 'ছবিতে দেখা খাবার বিশ্লেষণ করো।'}

শুধু JSON দাও:
{
  "name": "খাবারের নাম (বাংলায়)",
  "calories": 0,
  "protein": 0,
  "carbs": 0,
  "fat": 0,
  "fiber": 0,
  "vitamins": ["ভিটামিন A"],
  "minerals": ["আয়রন"],
  "score": 85,
  "score_reason": "কেন এই স্কোর",
  "benefits": ["উপকার ১", "উপকার ২"],
  "harms": ["সতর্কতা ১"],
  "condition_advice": "ইউজারের সমস্যার জন্য নির্দিষ্ট পরামর্শ",
  "timing_advice": "দিনের কোন সময়ে ভালো",
  "portion_advice": "কতটুকু খাওয়া উচিত",
  "alternative": "আরও স্বাস্থ্যকর দেশীয় বিকল্প"
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
