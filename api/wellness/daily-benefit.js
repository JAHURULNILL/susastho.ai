const {
  getDocument,
  queryCollection,
  setDocument,
  todayDateKey,
} = require('../_firestore_admin');

const CACHE_TTL_MS = 20 * 60 * 1000;

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

  try {
    const { userId } = req.body ?? {};
    if (!userId) {
      return res.status(400).json({ error: 'userId প্রয়োজন।' });
    }

    const today = todayDateKey();
    const cacheId = `${userId}_${today}`;
    const cached = await getDocument('wellness_notes', cacheId);
    if (cached?.data?.expiresAt && new Date(cached.data.expiresAt) > new Date()) {
      return res.status(200).json({ benefit: cached.data.content || '' });
    }

    const [userDoc, streakDocs, nofapDoc, todayLogs] = await Promise.all([
      getDocument('users', userId),
      queryCollection('wellness_streaks', [{ field: 'userId', value: userId }]),
      getDocument('nofap_tracker', userId),
      queryCollection('wellness_logs', [
        { field: 'userId', value: userId },
        { field: 'date', value: today },
      ]),
    ]);

    const user = userDoc?.data ?? {};
    const streaks = {};
    for (const item of streakDocs) {
      streaks[item.data.moduleId] = Number(item.data.currentStreak || 0);
    }
    const completedToday = todayLogs.map((item) => item.data.moduleId);
    const nofapStreak = nofapDoc?.data ? Number(nofapDoc.data.currentStreak || 0) : 0;

    const fallback = buildFallbackBenefit({
      user,
      streaks,
      nofapStreak,
      completedToday,
    });

    const geminiApiKey = process.env.GEMINI_API_KEY || '';
    const geminiModel = process.env.GEMINI_MODEL || 'gemini-2.5-flash';

    let content = fallback;
    if (geminiApiKey) {
      const prompt = buildPrompt({
        user,
        streaks,
        nofapStreak,
        completedToday,
      });

      const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${geminiModel}:generateContent?key=${geminiApiKey}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }],
            generationConfig: {
              temperature: 0.35,
            },
          }),
        },
      );

      const payload = await response.json();
      if (response.ok) {
        content = extractText(payload) || fallback;
      }
    }

    const expiresAt = new Date(Date.now() + CACHE_TTL_MS).toISOString();
    await setDocument('wellness_notes', cacheId, {
      userId,
      date: today,
      content,
      expiresAt,
      generatedAt: new Date().toISOString(),
    });

    return res.status(200).json({ benefit: content });
  } catch (error) {
    return res.status(500).json({
      error: error instanceof Error ? error.message : String(error),
    });
  }
};

function buildPrompt({ user, streaks, nofapStreak, completedToday }) {
  const conditions = Array.isArray(user.conditions) && user.conditions.length > 0
    ? user.conditions.join(', ')
    : 'কোনো নির্দিষ্ট সমস্যা উল্লেখ নেই';

  return `
তুমি একজন অভিজ্ঞ বাংলাদেশি স্বাস্থ্য বিশেষজ্ঞ।
ইউজার: ${user.name || 'ব্যবহারকারী'}, বয়স: ${user.age || 'অজানা'}
স্বাস্থ্য সমস্যা: ${conditions}

Wellness streaks:
- শ্বাস-প্রশ্বাস: ${streaks.breathing || 0} দিন
- কেগেল: ${streaks.kegel || 0} দিন
- মেডিটেশন: ${streaks.meditation || 0} দিন
- No Fap: ${nofapStreak} দিন
- ঘুমের রুটিন: ${streaks.sleep || 0} দিন
- ঠান্ডা গোসল: ${streaks.coldshower || 0} দিন

আজ সম্পন্ন: ${completedToday.join(', ') || 'কিছু না'}

এই মুহূর্তে ${user.name || 'ইউজার'} এর জন্য একটি wellness পরামর্শ দাও।
- actual streak data reference করো
- ২-৩ বাক্য
- বাংলায়
- motivating কিন্তু realistic
- শুধু পরামর্শের text
`.trim();
}

function buildFallbackBenefit({ user, streaks, nofapStreak, completedToday }) {
  const name = user.name || 'আপনি';
  if (completedToday.length === 0) {
    return `${name}, আজ এখনো কোনো wellness module সম্পন্ন হয়নি। ছোট করে breathing বা meditation দিয়ে শুরু করুন, তাহলে বাকিগুলো follow করা সহজ হবে।`;
  }

  const strongest = Object.entries(streaks).sort((left, right) => Number(right[1] || 0) - Number(left[1] || 0))[0];
  const strongestLabel = strongest ? strongest[0] : 'wellness';
  const strongestDays = strongest ? Number(strongest[1] || 0) : 0;

  return `${name}, আজ ${completedToday.join(', ')} সম্পন্ন হয়েছে। ${strongestDays > 0 ? `${strongestLabel} এ ${strongestDays} দিনের streak আছে,` : 'ধারাবাহিকতা তৈরি হচ্ছে,'} আর No Fap ${nofapStreak} দিন থাকলে সেই steady rhythm ধরে রাখুন।`;
}

function extractText(payload) {
  const parts = payload?.candidates?.[0]?.content?.parts;
  return Array.isArray(parts)
    ? parts.map((part) => part?.text).filter(Boolean).join('\n').trim()
    : '';
}
