export const MAX_NOTE_LENGTH = 500

/** Returns the trimmed note body, or null when the payload isn't a valid note. */
export function parseNoteBody(input: unknown): string | null {
  const body = (input as { body?: unknown } | null)?.body
  if (typeof body !== 'string') return null
  const trimmed = body.trim()
  return trimmed && trimmed.length <= MAX_NOTE_LENGTH ? trimmed : null
}
