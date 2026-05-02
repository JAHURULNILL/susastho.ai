import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { defineSecret, defineString } from 'firebase-functions/params';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

initializeApp();

const geminiApiKey = defineSecret('GEMINI_API_KEY');
const geminiModel = defineString('GEMINI_MODEL', {
  default: 'gemini-2.5-flash',
});

export const analyzeFood = onCall(
  {
    region: 'asia-south1',
    cors: true,
    timeoutSeconds: 120,
    memory: '512MiB',
    secrets: [geminiApiKey],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'ব্যবহারকারী সেশন পাওয়া যায়নি।');
    }

    const { imageBase64, mimeType, profile } = request.data ?? {};
    if (!imageBase64 || !mimeType || !profile) {
      throw new HttpsError('invalid-argument', 'ছবি, mime type এবং profile প্রয়োজন।');
    }

    const modelName = geminiModel.value();
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${geminiApiKey.value()}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          system_instruction: {
            parts: [
              {
                text: 'আপনি একজন বাংলা ভাষাভিত্তিক ক্লিনিক্যাল নিউট্রিশন সহকারী। সব উত্তর খাঁটি বাংলায় দেবেন এবং শুধু JSON schema অনুসরণ করবেন।',
              },
            ],
          },
          contents: [
            {
              parts: [
                { text: buildNutritionPrompt(profile) },
                {
                  inline_data: {
                    mime_type: mimeType,
                    data: imageBase64,
                  },
                },
              ],
            },
          ],
          generationConfig: {
            temperature: 0.2,
            response_mime_type: 'application/json',
          },
        }),
      },
    );

    const payload = await response.json();
    if (!response.ok) {
      throw new HttpsError('internal', JSON.stringify(payload));
    }

    const text = extractText(payload);
    const analysis = safeJsonParse(text);

    await getFirestore()
      .collection('users')
      .doc(request.auth.uid)
      .collection('meal_history')
      .add({
        profile,
        analysis,
        model: modelName,
        createdAt: FieldValue.serverTimestamp(),
      });

    return {
      model: {
        id: modelName,
        name: 'Gemini',
        version: modelName,
      },
      analysis,
    };
  },
);

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
    throw new HttpsError('internal', 'Gemini response empty');
  }

  return text;
}

function safeJsonParse(text) {
  const cleaned = String(text).replace(/```json/g, '').replace(/```/g, '').trim();
  const start = cleaned.indexOf('{');
  const end = cleaned.lastIndexOf('}');
  if (start === -1 || end === -1) {
    throw new HttpsError('internal', 'Model JSON parse failed');
  }

  return JSON.parse(cleaned.slice(start, end + 1));
}
