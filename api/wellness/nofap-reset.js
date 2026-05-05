const { getDocument, setDocument, todayDateKey } = require('../_firestore_admin');

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
    const tracker = await getDocument('nofap_tracker', userId);

    if (!tracker) {
      await setDocument('nofap_tracker', userId, {
        userId,
        currentStreak: 0,
        longestStreak: 0,
        startDate: today,
        lastResetDate: today,
        totalResets: 1,
      });
    } else {
      const data = tracker.data;
      await setDocument('nofap_tracker', userId, {
        userId,
        currentStreak: 0,
        longestStreak: Math.max(Number(data.currentStreak || 0), Number(data.longestStreak || 0)),
        startDate: today,
        lastResetDate: today,
        totalResets: Number(data.totalResets || 0) + 1,
      });
    }

    return res.status(200).json({ success: true });
  } catch (error) {
    return res.status(500).json({
      error: error instanceof Error ? error.message : String(error),
    });
  }
};
