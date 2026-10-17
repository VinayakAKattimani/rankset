// Demo content for LOCAL EMULATOR testing only. Not real exam content.
// Pure data (no Firebase imports) so it can be unit tested.

export const IDS = {
  category: 'cat-ssc',
  exam: 'exam-ssc-cgl',
  subject: 'subj-general-awareness',
  topic: 'topic-india-basics',
  quiz: 'quiz-demo-1',
};

export const catalog = {
  categories: [{ id: IDS.category, name: { en: 'SSC Exams', hi: 'एसएससी परीक्षाएँ' }, order: 1, isPublished: true }],
  exams: [{ id: IDS.exam, categoryId: IDS.category, name: { en: 'SSC CGL', hi: 'एसएससी सीजीएल' }, order: 1, isPublished: true }],
  subjects: [{ id: IDS.subject, examId: IDS.exam, name: { en: 'General Awareness', hi: 'सामान्य जागरूकता' }, order: 1, isPublished: true }],
  topics: [{ id: IDS.topic, examId: IDS.exam, subjectId: IDS.subject, name: { en: 'India Basics (demo)', hi: 'भारत की बुनियादी जानकारी (डेमो)' }, order: 1, isPublished: true }],
};

export const quizTitle = { en: 'India Basics - Demo Quiz', hi: 'भारत की बुनियादी जानकारी - डेमो क्विज़' };

// correctIndex is 0-based. Explanations live in answerKeys, never in the public question doc.
export const questions = [
  {
    id: 'q1', order: 0, correctIndex: 1,
    en: { text: 'What is the capital of India?', options: ['Mumbai', 'New Delhi', 'Kolkata', 'Chennai'] },
    hi: { text: 'भारत की राजधानी कौन सी है?', options: ['मुंबई', 'नई दिल्ली', 'कोलकाता', 'चेन्नई'] },
    explanation: { en: 'New Delhi is the capital of India and the seat of the central government.', hi: 'नई दिल्ली भारत की राजधानी है और यहीं केंद्र सरकार का मुख्यालय है।' },
  },
  {
    id: 'q2', order: 1, correctIndex: 1,
    en: { text: 'Which animal is the national animal of India?', options: ['Lion', 'Tiger', 'Elephant', 'Leopard'] },
    hi: { text: 'भारत का राष्ट्रीय पशु कौन सा है?', options: ['शेर', 'बाघ', 'हाथी', 'तेंदुआ'] },
    explanation: { en: "The Bengal tiger is India's national animal.", hi: 'बंगाल टाइगर (बाघ) भारत का राष्ट्रीय पशु है।' },
  },
  {
    id: 'q3', order: 2, correctIndex: 1,
    en: { text: "Who wrote the national anthem 'Jana Gana Mana'?", options: ['Bankim Chandra Chatterjee', 'Rabindranath Tagore', 'Sarojini Naidu', 'Muhammad Iqbal'] },
    hi: { text: 'राष्ट्रगान "जन गण मन" की रचना किसने की?', options: ['बंकिमचंद्र चट्टोपाध्याय', 'रवींद्रनाथ टैगोर', 'सरोजिनी नायडू', 'मुहम्मद इक़बाल'] },
    explanation: { en: 'Rabindranath Tagore wrote Jana Gana Mana.', hi: 'जन गण मन की रचना रवींद्रनाथ टैगोर ने की थी।' },
  },
  {
    id: 'q4', order: 3, correctIndex: 2,
    en: { text: 'Which is the largest Indian state by area?', options: ['Madhya Pradesh', 'Maharashtra', 'Rajasthan', 'Uttar Pradesh'] },
    hi: { text: 'क्षेत्रफल के आधार पर भारत का सबसे बड़ा राज्य कौन सा है?', options: ['मध्य प्रदेश', 'महाराष्ट्र', 'राजस्थान', 'उत्तर प्रदेश'] },
    explanation: { en: 'Rajasthan is the largest state by area.', hi: 'क्षेत्रफल की दृष्टि से राजस्थान भारत का सबसे बड़ा राज्य है।' },
  },
  {
    id: 'q5', order: 4, correctIndex: 2,
    en: { text: 'In which year did India become independent?', options: ['1942', '1945', '1947', '1950'] },
    hi: { text: 'भारत को किस वर्ष स्वतंत्रता मिली?', options: ['1942', '1945', '1947', '1950'] },
    explanation: { en: 'India became independent on 15 August 1947.', hi: 'भारत 15 अगस्त 1947 को स्वतंत्र हुआ।' },
  },
];

export const demoUsers = [
  { uid: 'admin1', email: 'admin1@rankset.test', password: 'Passw0rd!demo', admin: true },
  { uid: 'admin2', email: 'admin2@rankset.test', password: 'Passw0rd!demo', admin: true },
  { uid: 'student1', email: 'student@rankset.test', password: 'Passw0rd!demo', admin: false },
];
