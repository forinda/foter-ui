import { test } from 'node:test'
import assert from 'node:assert/strict'
import { parseNoteBody } from '../src/lib/notes.ts'

test('valid body trimmed', () => assert.equal(parseNoteBody({ body: '  hi ' }), 'hi'))

test('rejects missing/non-string/blank', () => {
  for (const v of [null, {}, { body: 3 }, { body: '   ' }, 'x']) assert.equal(parseNoteBody(v), null)
})

test('500 ok, 501 rejected', () => {
  assert.equal(parseNoteBody({ body: 'a'.repeat(500) })?.length, 500)
  assert.equal(parseNoteBody({ body: 'a'.repeat(501) }), null)
})
