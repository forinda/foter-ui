import pg from 'pg'

let ready: Promise<pg.Pool> | undefined

/** Shared pool; creates the notes table on first use and retries setup after a failure. */
export function db(): Promise<pg.Pool> {
  ready ??= (async () => {
    const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL })
    pool.on('error', () => {}) // idle client dropped (e.g. DB restart); next query reconnects
    try {
      await pool.query(
        'CREATE TABLE IF NOT EXISTS notes (id serial primary key, body text not null, created_at timestamptz default now())',
      )
      return pool
    } catch (err) {
      ready = undefined
      await pool.end().catch(() => {})
      throw err
    }
  })()
  return ready
}
