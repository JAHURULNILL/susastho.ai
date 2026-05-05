const {
  addDays,
  getDocument,
  queryCollection,
  todayDateKey,
} = require('../_firestore_admin');

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
    const weekStart = addDays(today, -6);

    const [streakDocs, todayLogs, weekLogs, nofapDoc] = await Promise.all([
      queryCollection('wellness_streaks', [{ field: 'userId', value: userId }]),
      queryCollection('wellness_logs', [
        { field: 'userId', value: userId },
        { field: 'date', value: today },
      ]),
      queryCollection('wellness_logs', [
        { field: 'userId', value: userId },
        { field: 'date', op: 'GREATER_THAN_OR_EQUAL', value: weekStart },
        { field: 'date', op: 'LESS_THAN_OR_EQUAL', value: today },
      ]),
      getDocument('nofap_tracker', userId),
    ]);

    return res.status(200).json({
      success: true,
      streaks: Object.fromEntries(streakDocs.map((item) => [item.data.moduleId, item.data])),
      todayLogs: todayLogs.map((item) => item.data.moduleId),
      weekLogs: weekLogs.map((item) => item.data),
      nofapTracker: nofapDoc?.data ?? null,
    });
  } catch (error) {
    return res.status(500).json({
      error: error instanceof Error ? error.message : String(error),
    });
  }
};
