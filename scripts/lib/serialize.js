// JSON (de)serialisation of Firestore values for backups. Pure functions, unit tested.
// Timestamps -> { "__type": "timestamp", "iso": "..." }, document refs -> { "__type": "ref", "path": "..." }.

function isTimestampLike(v) {
  return v && typeof v === 'object' && typeof v.toDate === 'function'
    && (typeof v.seconds === 'number' || typeof v._seconds === 'number');
}

function isRefLike(v) {
  return v && typeof v === 'object' && typeof v.path === 'string' && typeof v.collection === 'function';
}

export function encodeValue(v) {
  if (v === null || v === undefined) return v ?? null;
  if (isTimestampLike(v)) return { __type: 'timestamp', iso: v.toDate().toISOString() };
  if (isRefLike(v)) return { __type: 'ref', path: v.path };
  if (Array.isArray(v)) return v.map(encodeValue);
  if (typeof v === 'object') return Object.fromEntries(Object.entries(v).map(([k, x]) => [k, encodeValue(x)]));
  return v;
}

// `Timestamp` must be firebase-admin's Timestamp class; `db` is used to rebuild document refs.
export function decodeValue(v, { Timestamp, db }) {
  if (v === null || typeof v !== 'object') return v;
  if (Array.isArray(v)) return v.map((x) => decodeValue(x, { Timestamp, db }));
  if (v.__type === 'timestamp') return Timestamp.fromDate(new Date(v.iso));
  if (v.__type === 'ref') return db.doc(v.path);
  return Object.fromEntries(Object.entries(v).map(([k, x]) => [k, decodeValue(x, { Timestamp, db })]));
}
