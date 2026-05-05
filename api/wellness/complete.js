const {
  diffDays,
  getDocument,
  setDocument,
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
    const { userId, moduleId, duration = 0, details = {} } = req.body ?? {};
    if (!userId || !moduleId) {
      return res.status(400).json({ error: 'userId এবং moduleId প্রয়োজন।' });
    }

    const today = todayDateKey();
    const logId = `${userId}_${today}_${moduleId}`;
    await setDocument('wellness_logs', logId, {
      userId,
      moduleId,
      date: today,
      completedAt: new Date().toISOString(),
      duration,
      details,
    });

    const streakId = `${userId}_${moduleId}`;
    const existingStreak = await getDocument('wellness_streaks', streakId);
    let streakValue = 1;

    if (!existingStreak) {
      await setDocument('wellness_streaks', streakId, {
        userId,
        moduleId,
        currentStreak: 1,
        longestStreak: 1,
        lastCompletedDate: today,
        totalSessions: 1,
        startedAt: new Date().toISOString(),
      });
    } else {
      const data = existingStreak.data;
      const gap = diffDays(data.lastCompletedDate, today);

      if (gap === 0) {
        streakValue = Number(data.currentStreak || 0);
      } else {
        streakValue = gap === 1 ? Number(data.currentStreak || 0) + 1 : 1;
        await setDocument('wellness_streaks', streakId, {
          userId,
          moduleId,
          currentStreak: streakValue,
          longestStreak: Math.max(streakValue, Number(data.longestStreak || 0)),
          lastCompletedDate: today,
          totalSessions: Number(data.totalSessions || 0) + 1,
          startedAt: data.startedAt || new Date().toISOString(),
        });
      }
    }

    if (moduleId === 'nofap') {
      const tracker = await getDocument('nofap_tracker', userId);
      if (!tracker) {
        await setDocument('nofap_tracker', userId, {
          userId,
          currentStreak: 1,
          longestStreak: 1,
          startDate: today,
          lastResetDate: '',
          totalResets: 0,
        });
      } else {
        const data = tracker.data;
        const current = Number(data.currentStreak || 0);
        const next = streakValue > 0 ? Math.max(current, streakValue) : current;
        await setDocument('nofap_tracker', userId, {
          userId,
          currentStreak: next,
          longestStreak: Math.max(next, Number(data.longestStreak || 0)),
          startDate: data.startDate || today,
          lastResetDate: data.lastResetDate || '',
          totalResets: Number(data.totalResets || 0),
        });
      }
    }

    return res.status(200).json({ success: true, streak: streakValue });
  } catch (error) {
    return res.status(500).json({
      error: error instanceof Error ? error.message : String(error),
    });
  }
};
