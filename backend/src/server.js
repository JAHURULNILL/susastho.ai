import 'dotenv/config';
import express from 'express';
import cors from 'cors';

const app = express();
const port = Number(process.env.PORT || 8787);
const geminiApiKey = process.env.GEMINI_API_KEY || '';
const geminiModel = process.env.GEMINI_MODEL || 'gemini-2.5-flash';

app.use(cors());
app.use(express.json({ limit: '15mb' }));

app.get('/', (_req, res) => {
  res.json({
    ok: true,
    message: 'Sushastho.ai Gemini backend is live.'
  });
});

app.get('/health', (_req, res) => {
  res.json({
    ok: true,
    provider: 'gemini',
    model: geminiModel,
    date: new Date().toISOString()
  });
});

app.post('/api/nutrition/analyze', async (req, res) => {
  try {
    const { imageBase64, mimeType, profile } = req.body ?? {};
    if (!imageBase64 || !mimeType || !profile) {
      return res.status(400).json({ error: 'imageBase64, mimeType এবং profile প্রয়োজন।' });
    }

    if (!geminiApiKey) {
      return res.status(500).json({ error: 'GEMINI_API_KEY is missing on backend.' });
    }

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${geminiModel}:generateContent?key=${geminiApiKey}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          system_instruction: {
            parts: [
              {
                text: 'আপনি একজন বাংলা ভাষাভিত্তিক ক্লিনিক্যাল নিউট্রিশন সহকারী। সব উত্তর খাঁটি বাংলায় দেবেন এবং শুধু JSON schema অনুসরণ করবেন।'
              }
            ]
          },
          contents: [
            {
              parts: [
                { text: buildNutritionPrompt(profile) },
                {
                  inline_data: {
                    mime_type: mimeType,
                    data: imageBase64
                  }
                }
              ]
            }
          ],
          generationConfig: {
            temperature: 0.2,
            response_mime_type: 'application/json'
          }
        })
      }
    );

    const json = await response.json();
    if (!response.ok) {
      return res.status(response.status).json({ error: json });
    }

    const text = extractText(json);
    const analysis = safeJsonParse(text);

    res.json({
      model: {
        id: geminiModel,
        name: 'Gemini',
        version: geminiModel
      },
      analysis
    });
  } catch (error) {
    res.status(500).json({ error: stringifyError(error) });
  }
});

app.listen(port, () => {
  console.log(`Sushastho.ai Gemini backend listening on http://localhost:${port}`);
});

function buildNutritionPrompt(profile) {
  const conditions = Array.isArray(profile.conditions) && profile.conditions.length > 0
    ? profile.conditions.join(', ')
    : 'কোনো নির্দিষ্ট রোগ উল্লেখ নেই';

  return `
ব্যবহারকারীর প্রোফাইল:
- নাম: ${profile.name}
- বয়স: ${profile.age}
- ওজন: ${profile.weightKg} কেজি
- উচ্চতা: ${profile.heightCm} সেমি
- লক্ষ্য: ${profile.goal}
- রোগ/অবস্থা: ${conditions}

ছবির খাবার বিশ্লেষণ করুন। সম্ভাব্য বাংলাদেশি খাবার হিসেবে শনাক্ত করুন।
শুধু এই JSON format-এ উত্তর দিন:
{
  "foodName": "খাবারের নাম",
  "macros": {
    "calories": 0,
    "protein": 0,
    "carbs": 0,
    "fat": 0
  },
  "pros": ["কারণ ১", "কারণ ২"],
  "warnings": ["সতর্কতা ১", "সতর্কতা ২"],
  "summary": "১-২ লাইনের বাংলা সারাংশ",
  "healthScore": 0
}

বিশেষ নির্দেশনা:
- ডায়াবেটিস থাকলে সাদা ভাত, মিষ্টি, high glycemic load নিয়ে সতর্ক করুন।
- হৃদরোগ থাকলে cholesterol, saturated fat, অতিরিক্ত তেল নিয়ে সতর্ক করুন।
- স্থূলতা বা পেটের চর্বি থাকলে portion control এবং carb/fat load নিয়ে সতর্ক করুন।
- underweight থাকলে calorie density এবং protein quality নিয়ে ভালো দিক লিখুন।
- ED বা urinary issues থাকলে hydration, zinc, excess spice/caffeine বিষয়ে প্রাসঙ্গিক পরামর্শ দিন।
- উত্তর অবশ্যই বাংলায় দিন।
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
  if (start == -1 || end == -1) {
    throw new Error('Model JSON parse failed.');
  }
  return JSON.parse(cleaned.slice(start, end + 1));
}

function stringifyError(error) {
  return error instanceof Error ? error.message : String(error);
}
