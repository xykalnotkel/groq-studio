import crypto from 'node:crypto';

const GIST_ID = 'ca5bfc46c70301e3ff7a892263de8456';
const SALT = 'xystudio-papan-2026';
const MAX_JUMP = 400000;

function cors(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}

function hash(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

function emailId(email) {
  return hash(String(email || '').trim().toLowerCase());
}

function pinHash(email, pin) {
  return hash(`${String(email).trim().toLowerCase()}|${pin}|${SALT}`);
}

function weekId(date = new Date()) {
  const utc = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
  const day = utc.getUTCDay() || 7;
  utc.setUTCDate(utc.getUTCDate() + 4 - day);
  const yearStart = new Date(Date.UTC(utc.getUTCFullYear(), 0, 1));
  const week = Math.ceil(((utc - yearStart) / 86400000 + 1) / 7);
  return `${utc.getUTCFullYear()}-W${String(week).padStart(2, '0')}`;
}

function publicUser(user, rank) {
  return {
    id: user.id,
    rank,
    name: user.name,
    tokens: user.tokens || 0,
    weekTokens: user.weekTokens || 0,
    generates: user.generates || 0,
  };
}

function cleanUsers(list, week) {
  return (Array.isArray(list) ? list : []).map((user) => {
    if (!user || typeof user !== 'object') return null;
    if (user.week !== week) {
      return { ...user, week, weekTokens: 0 };
    }
    return user;
  }).filter(Boolean);
}

async function loadBoard(token) {
  const response = await fetch(`https://api.github.com/gists/${GIST_ID}`, {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: 'application/vnd.github+json',
      'User-Agent': 'xystudio-leaderboard',
    },
  });
  if (!response.ok) {
    throw new Error(`gist ${response.status}`);
  }
  const gist = await response.json();
  const raw = gist.files?.['leaderboard.json']?.content || '{"users":[]}';
  let data;
  try {
    data = JSON.parse(raw);
  } catch {
    data = { users: [] };
  }
  if (!Array.isArray(data.users)) data.users = [];
  return data;
}

async function saveBoard(token, data) {
  const response = await fetch(`https://api.github.com/gists/${GIST_ID}`, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: 'application/vnd.github+json',
      'Content-Type': 'application/json',
      'User-Agent': 'xystudio-leaderboard',
    },
    body: JSON.stringify({
      files: {
        'leaderboard.json': {
          content: JSON.stringify(data, null, 2),
        },
      },
    }),
  });
  if (!response.ok) {
    throw new Error(`save ${response.status}`);
  }
}

function ranked(users, key) {
  return [...users]
    .sort((a, b) => (b[key] || 0) - (a[key] || 0) || (b.generates || 0) - (a.generates || 0))
    .map((user, index) => publicUser(user, index + 1));
}

function findMe(list, id) {
  return list.find((row) => row.id === id) || null;
}

export default async function handler(req, res) {
  cors(res);
  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return;
  }

  const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN || '';
  if (!token) {
    res.status(503).json({ error: 'Papan sedang disiapkan.' });
    return;
  }

  const week = weekId();

  try {
    if (req.method === 'GET') {
      const board = await loadBoard(token);
      const users = cleanUsers(board.users, week);
      const meRaw = req.query?.me ? String(req.query.me) : '';
      const me = meRaw.includes('@') ? emailId(meRaw) : meRaw;
      const all = ranked(users, 'tokens');
      const weekly = ranked(users, 'weekTokens');
      res.status(200).json({
        week,
        all,
        weekly,
        me: me ? findMe(all, me) : null,
        meWeek: me ? findMe(weekly, me) : null,
        total: users.length,
      });
      return;
    }

    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Metode tidak didukung.' });
      return;
    }

    const body = typeof req.body === 'string' ? JSON.parse(req.body || '{}') : (req.body || {});
    const action = String(body.action || 'sync');
    const email = String(body.email || '').trim().toLowerCase();
    const name = String(body.name || '').trim().slice(0, 24);
    const pin = String(body.pin || '').trim();
    const tokens = Math.max(0, Math.floor(Number(body.tokens) || 0));
    const generates = Math.max(0, Math.floor(Number(body.generates) || 0));

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      res.status(400).json({ error: 'Email tidak valid.' });
      return;
    }
    if (!/^\d{4,6}$/.test(pin)) {
      res.status(400).json({ error: 'PIN harus 4 sampai 6 digit angka.' });
      return;
    }

    const board = await loadBoard(token);
    const users = cleanUsers(board.users, week);
    const id = emailId(email);
    const hashed = pinHash(email, pin);
    let user = users.find((row) => row.id === id);

    if (action === 'register') {
      if (!name) {
        res.status(400).json({ error: 'Isi nama tampilan dulu.' });
        return;
      }
      if (user) {
        res.status(409).json({ error: 'Email ini sudah terdaftar. Masuk saja.' });
        return;
      }
      user = {
        id,
        name,
        pin: hashed,
        tokens: 0,
        weekTokens: 0,
        week,
        generates: 0,
        updatedAt: new Date().toISOString(),
      };
      users.push(user);
    } else if (action === 'login') {
      if (!user || user.pin !== hashed) {
        res.status(401).json({ error: 'Email atau PIN salah.' });
        return;
      }
      if (name) user.name = name;
    } else {
      if (!user) {
        if (!name) {
          res.status(400).json({ error: 'Daftar dulu dengan nama dan PIN.' });
          return;
        }
        user = {
          id,
          name,
          pin: hashed,
          tokens: 0,
          weekTokens: 0,
          week,
          generates: 0,
          updatedAt: new Date().toISOString(),
        };
        users.push(user);
      } else if (user.pin !== hashed) {
        res.status(401).json({ error: 'Email atau PIN salah.' });
        return;
      }
      if (name) user.name = name;
      const nextTokens = Math.min(tokens, (user.tokens || 0) + MAX_JUMP);
      if (nextTokens > (user.tokens || 0)) {
        const delta = nextTokens - (user.tokens || 0);
        user.tokens = nextTokens;
        user.weekTokens = (user.weekTokens || 0) + delta;
      }
      if (generates > (user.generates || 0)) {
        user.generates = generates;
      }
      user.week = week;
      user.updatedAt = new Date().toISOString();
    }

    board.users = users;
    await saveBoard(token, board);

    const all = ranked(users, 'tokens');
    const weekly = ranked(users, 'weekTokens');
    res.status(200).json({
      ok: true,
      week,
      profile: { id, name: user.name, email },
      me: findMe(all, id),
      meWeek: findMe(weekly, id),
      all: all.slice(0, 50),
      weekly: weekly.slice(0, 50),
      total: users.length,
    });
  } catch (error) {
    res.status(500).json({ error: 'Papan lagi sibuk. Coba sebentar lagi.' });
  }
}
