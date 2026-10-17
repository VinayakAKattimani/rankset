// Mode A entry point. NOT DEPLOYED. Deploying Cloud Functions requires the Blaze plan.
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { handleSubmitAttempt } from './submit-attempt.js';
import { AppError } from './scoring.js';

initializeApp();

// maxInstances caps parallel instances, which also caps worst-case cost.
export const submitAttempt = onCall(
  { region: 'asia-south1', maxInstances: 5, timeoutSeconds: 30, memory: '256MiB' },
  async (request) => {
    try {
      return await handleSubmitAttempt({ db: getFirestore(), uid: request.auth?.uid, data: request.data });
    } catch (e) {
      if (e instanceof AppError) throw new HttpsError(e.code, e.message);
      console.error('submitAttempt failed', e);
      throw new HttpsError('internal', 'Could not submit the quiz. Please try again.');
    }
  },
);
