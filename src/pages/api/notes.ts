import type { RequestHandler } from 'clarusjs/server'
import { db } from '~/lib/db.ts'
import { MAX_NOTE_LENGTH, parseNoteBody } from '~/lib/notes.ts'

export const GET: RequestHandler = async () => {
  const { rows } = await (await db()).query('SELECT id, body, created_at FROM notes ORDER BY id DESC LIMIT 50')
  return Response.json(rows)
}

export const POST: RequestHandler = async ({ request }) => {
  const body = parseNoteBody(await request.json().catch(() => null))
  if (body === null) {
    return Response.json({ error: `Note must be 1-${MAX_NOTE_LENGTH} characters` }, { status: 400 })
  }
  const { rows } = await (await db()).query('INSERT INTO notes (body) VALUES ($1) RETURNING id, body, created_at', [body])
  return Response.json(rows[0], { status: 201 })
}
