const crypto = require('crypto');

const TOKEN_SCOPE = 'https://www.googleapis.com/auth/datastore';
const TOKEN_URL = 'https://oauth2.googleapis.com/token';

let cachedToken = null;
let cachedTokenExpiry = 0;

function getProjectId() {
  const value =
    process.env.FIREBASE_PROJECT_ID ||
    process.env.GOOGLE_CLOUD_PROJECT ||
    process.env.GCLOUD_PROJECT ||
    '';

  if (!value) {
    throw new Error('FIREBASE_PROJECT_ID is missing.');
  }

  return value;
}

function getClientEmail() {
  const value = process.env.FIREBASE_CLIENT_EMAIL || process.env.GOOGLE_CLIENT_EMAIL || '';
  if (!value) {
    throw new Error('FIREBASE_CLIENT_EMAIL is missing.');
  }
  return value;
}

function getPrivateKey() {
  const value = process.env.FIREBASE_PRIVATE_KEY || process.env.GOOGLE_PRIVATE_KEY || '';
  if (!value) {
    throw new Error('FIREBASE_PRIVATE_KEY is missing.');
  }
  return value.replace(/\\n/g, '\n');
}

function base64UrlEncode(input) {
  return Buffer.from(input)
    .toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

function signJwt(unsignedToken, privateKey) {
  const signer = crypto.createSign('RSA-SHA256');
  signer.update(unsignedToken);
  signer.end();
  return signer
    .sign(privateKey, 'base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

async function getAccessToken() {
  if (cachedToken && Date.now() < cachedTokenExpiry - 60_000) {
    return cachedToken;
  }

  const issuedAt = Math.floor(Date.now() / 1000);
  const expiresAt = issuedAt + 3600;

  const header = base64UrlEncode(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claims = base64UrlEncode(
    JSON.stringify({
      iss: getClientEmail(),
      sub: getClientEmail(),
      aud: TOKEN_URL,
      iat: issuedAt,
      exp: expiresAt,
      scope: TOKEN_SCOPE,
    }),
  );

  const unsigned = `${header}.${claims}`;
  const assertion = `${unsigned}.${signJwt(unsigned, getPrivateKey())}`;

  const response = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });

  const payload = await response.json();
  if (!response.ok) {
    throw new Error(JSON.stringify(payload));
  }

  cachedToken = payload.access_token;
  cachedTokenExpiry = Date.now() + ((payload.expires_in || 3600) * 1000);
  return cachedToken;
}

function documentBaseUrl() {
  return `https://firestore.googleapis.com/v1/projects/${getProjectId()}/databases/(default)/documents`;
}

async function firestoreRequest(path, { method = 'GET', body } = {}) {
  const token = await getAccessToken();
  const response = await fetch(`${documentBaseUrl()}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: body == null ? undefined : JSON.stringify(body),
  });

  if (response.status === 404) {
    return null;
  }

  const payload = await response.json();
  if (!response.ok) {
    throw new Error(JSON.stringify(payload));
  }

  return payload;
}

function encodeValue(value) {
  if (value === null || value === undefined) {
    return { nullValue: null };
  }
  if (typeof value === 'string') {
    return { stringValue: value };
  }
  if (typeof value === 'boolean') {
    return { booleanValue: value };
  }
  if (typeof value === 'number') {
    if (Number.isInteger(value)) {
      return { integerValue: String(value) };
    }
    return { doubleValue: value };
  }
  if (Array.isArray(value)) {
    return {
      arrayValue: {
        values: value.map((item) => encodeValue(item)),
      },
    };
  }
  if (value instanceof Date) {
    return { timestampValue: value.toISOString() };
  }
  if (typeof value === 'object') {
    return {
      mapValue: {
        fields: toFields(value),
      },
    };
  }
  return { stringValue: String(value) };
}

function toFields(data) {
  const fields = {};
  for (const [key, value] of Object.entries(data || {})) {
    fields[key] = encodeValue(value);
  }
  return fields;
}

function decodeValue(value) {
  if (!value) {
    return null;
  }
  if ('stringValue' in value) {
    return value.stringValue;
  }
  if ('booleanValue' in value) {
    return value.booleanValue;
  }
  if ('integerValue' in value) {
    return Number(value.integerValue);
  }
  if ('doubleValue' in value) {
    return Number(value.doubleValue);
  }
  if ('timestampValue' in value) {
    return value.timestampValue;
  }
  if ('nullValue' in value) {
    return null;
  }
  if ('arrayValue' in value) {
    return (value.arrayValue.values || []).map((item) => decodeValue(item));
  }
  if ('mapValue' in value) {
    return fromFields(value.mapValue.fields || {});
  }
  return null;
}

function fromFields(fields) {
  const data = {};
  for (const [key, value] of Object.entries(fields || {})) {
    data[key] = decodeValue(value);
  }
  return data;
}

async function getDocument(collection, docId) {
  const payload = await firestoreRequest(`/${collection}/${docId}`);
  if (!payload) {
    return null;
  }
  return {
    id: docId,
    data: fromFields(payload.fields || {}),
  };
}

async function setDocument(collection, docId, data) {
  await firestoreRequest(`/${collection}/${docId}`, {
    method: 'PATCH',
    body: {
      fields: toFields(data),
    },
  });
}

async function queryCollection(collection, filters) {
  const where = buildWhere(filters);
  const payload = await firestoreRequest(`:runQuery`, {
    method: 'POST',
    body: {
      structuredQuery: {
        from: [{ collectionId: collection }],
        where,
      },
    },
  });

  if (!Array.isArray(payload)) {
    return [];
  }

  return payload
    .map((item) => item.document)
    .filter(Boolean)
    .map((document) => ({
      id: document.name.split('/').pop(),
      data: fromFields(document.fields || {}),
    }));
}

function buildWhere(filters) {
  if (!filters || filters.length === 0) {
    return undefined;
  }

  if (filters.length === 1) {
    return buildFieldFilter(filters[0]);
  }

  return {
    compositeFilter: {
      op: 'AND',
      filters: filters.map((filter) => buildFieldFilter(filter)),
    },
  };
}

function buildFieldFilter(filter) {
  return {
    fieldFilter: {
      field: { fieldPath: filter.field },
      op: filter.op || 'EQUAL',
      value: encodeValue(filter.value),
    },
  };
}

function todayDateKey() {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Dhaka',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(new Date());
}

function addDays(dateKey, delta) {
  const [year, month, day] = dateKey.split('-').map(Number);
  const date = new Date(Date.UTC(year, month - 1, day));
  date.setUTCDate(date.getUTCDate() + delta);
  return date.toISOString().slice(0, 10);
}

function diffDays(fromDate, toDate) {
  if (!fromDate || !toDate) {
    return Number.POSITIVE_INFINITY;
  }
  const from = Date.parse(`${fromDate}T00:00:00Z`);
  const to = Date.parse(`${toDate}T00:00:00Z`);
  return Math.floor((to - from) / 86_400_000);
}

module.exports = {
  addDays,
  diffDays,
  getDocument,
  queryCollection,
  setDocument,
  todayDateKey,
};
