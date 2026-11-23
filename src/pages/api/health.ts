import type { RequestHandler } from 'clarusjs/server'
import { db } from '~/lib/db.ts'

export const GET: RequestHandler = async () => {
  try {
    await (await db()).query('SELECT 1')
    return Response.json({ ok: true })
  } catch {
    return Response.json({ ok: false }, { status: 503 })
  }
}
