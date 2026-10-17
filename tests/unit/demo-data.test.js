import { test } from 'node:test';
import assert from 'node:assert/strict';
import { questions, catalog, IDS } from '../../scripts/demo-data.js';

test('every demo question has stable id, 4 options and a valid answer in each language', () => {
  const ids = new Set();
  for (const q of questions) {
    assert.ok(!ids.has(q.id), `duplicate id ${q.id}`); ids.add(q.id);
    for (const lang of ['en', 'hi']) {
      assert.equal(q[lang].options.length, 4, `${q.id}/${lang} options`);
      assert.ok(q[lang].text.length > 0);
      assert.equal(new Set(q[lang].options).size, 4, `${q.id}/${lang} duplicate options`);
    }
    assert.ok(Number.isInteger(q.correctIndex) && q.correctIndex >= 0 && q.correctIndex <= 3);
    assert.ok(q.explanation.en && q.explanation.hi);
  }
});

test('question orders are 0..n-1 and catalog links are consistent', () => {
  assert.deepEqual(questions.map((q) => q.order), questions.map((_, i) => i));
  assert.equal(catalog.exams[0].categoryId, catalog.categories[0].id);
  assert.equal(catalog.subjects[0].examId, IDS.exam);
  assert.equal(catalog.topics[0].subjectId, IDS.subject);
});
