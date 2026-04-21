import { genkit } from 'genkit';
import { googleAI, gemini } from '@genkit-ai/googleai';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin
admin.initializeApp();

// Define secret for Google AI API Key
const GOOGLE_AI_API_KEY = defineSecret('GOOGLE_AI_API_KEY');

// Use Gemini 2.5 Flash Lite model (latest, cost-optimized)
const geminiModel = gemini('gemini-2.5-flash-lite');

// =============================================================================
// ERROR MESSAGES (Indonesian)
// =============================================================================

const ERROR_MESSAGES = {
  UNAUTHENTICATED: '🔐 Anda harus login terlebih dahulu\n\nSilakan sign in dengan Google untuk menggunakan fitur AI.',
  INVALID_PDF_TEXT: '📄 Konten PDF tidak valid\n\nPastikan file PDF dapat dibaca dan memiliki teks.',
  INVALID_QUESTION: '❓ Mohon masukkan pertanyaan\n\nContoh: "Apa topik utama dokumen ini?"',
  API_KEY_MISSING: '🔑 Konfigurasi AI belum siap\n\nSilakan hubungi administrator.',
  AI_ERROR: '⚠️ Gagal mendapatkan respons dari AI\n\nSilakan coba lagi dalam beberapa saat.',
  EMPTY_RESPONSE: '🤖 AI memberikan respons kosong\n\nSilakan coba pertanyaan lain.',
  RATE_LIMIT: '⏱️ Terlalu banyak permintaan\n\nMohon tunggu sebentar sebelum mencoba lagi.',
};

// =============================================================================
// SUMMARIZE FLOW
// =============================================================================

/**
 * Summarize PDF content
 * Expects: { pdfText: string }
 * Returns: { summary: string }
 */
export const summarizeFlow = onCall(
  {
    maxInstances: 10,
    region: 'asia-southeast1',
    secrets: [GOOGLE_AI_API_KEY],
  },
  async (request) => {
    console.log('=== summarizeFlow START ===');

    // Verify authentication
    if (!request.auth) {
      console.error('❌ Unauthenticated request');
      throw new HttpsError('unauthenticated', ERROR_MESSAGES.UNAUTHENTICATED);
    }

    console.log('✅ Authenticated:', request.auth.uid);

    const { pdfText } = request.data;

    // Validate pdfText
    if (!pdfText || typeof pdfText !== 'string') {
      console.error('❌ Invalid pdfText');
      throw new HttpsError('invalid-argument', ERROR_MESSAGES.INVALID_PDF_TEXT);
    }

    // Limit PDF text length
    const maxLength = 50000;
    const truncatedText = pdfText.length > maxLength
      ? pdfText.substring(0, maxLength) + '\n\n[Konten dipotong karena terlalu panjang...]'
      : pdfText;

    console.log('📊 PDF text length:', truncatedText.length);

    try {
      // Get API key from secret
      const apiKey = GOOGLE_AI_API_KEY.value();

      if (!apiKey) {
        console.error('❌ API Key not available');
        throw new HttpsError('failed-precondition', ERROR_MESSAGES.API_KEY_MISSING);
      }

      console.log('✅ API Key available');

      // Initialize AI with Google AI plugin
      const ai = genkit({
        plugins: [googleAI({ apiKey })],
        model: geminiModel,
      });

      console.log('📤 Calling Gemini AI...');

      const response = await ai.generate({
        prompt: `Buat ringkasan yang jelas dan ringkas dari konten PDF berikut. Fokus pada poin-poin utama dan informasi kunci:\n\n${truncatedText}`,
      });

      const summary = response.text?.trim();

      if (!summary || summary.length === 0) {
        console.error('❌ Empty summary received');
        throw new HttpsError('internal', ERROR_MESSAGES.EMPTY_RESPONSE);
      }

      console.log(`✅ Summary generated (${summary.length} chars)`);

      return {
        summary,
        model: 'gemini-2.5-flash-lite',
        truncated: pdfText.length > maxLength,
      };
    } catch (error: any) {
      console.error('❌ Error in summarizeFlow:', error?.message || error);

      // Check if it's a Firestore error
      if (error?.message?.includes('Firestore') || error?.message?.includes('Datastore')) {
        throw new HttpsError(
          'failed-precondition',
          'Konfigurasi database belum sesuai. Hubungi administrator.'
        );
      }

      throw new HttpsError('internal', ERROR_MESSAGES.AI_ERROR);
    }
  }
);

// =============================================================================
// CHAT FLOW
// =============================================================================

/**
 * Chat with PDF context
 * Expects: { pdfText: string, question: string, history?: Array<{role: string, content: string}> }
 * Returns: { response: string }
 */
export const chatFlow = onCall(
  {
    maxInstances: 10,
    region: 'asia-southeast1',
    timeoutSeconds: 120,
    secrets: [GOOGLE_AI_API_KEY],
  },
  async (request) => {
    console.log('=== chatFlow START ===');
    console.log('Timestamp:', new Date().toISOString());

    // Authentication check
    if (!request.auth) {
      console.error('❌ Unauthenticated request');
      throw new HttpsError('unauthenticated', ERROR_MESSAGES.UNAUTHENTICATED);
    }

    console.log('✅ Authenticated:', request.auth.uid);

    const { pdfText, question, history = [] } = request.data;

    // PDF text validation
    if (!pdfText || typeof pdfText !== 'string') {
      console.error('❌ Invalid pdfText');
      throw new HttpsError('invalid-argument', ERROR_MESSAGES.INVALID_PDF_TEXT);
    }

    // Question validation
    if (!question || typeof question !== 'string') {
      console.error('❌ Invalid question');
      throw new HttpsError('invalid-argument', ERROR_MESSAGES.INVALID_QUESTION);
    }

    // Limit question length
    const MAX_QUESTION_LENGTH = 1000;
    if (question.length > MAX_QUESTION_LENGTH) {
      throw new HttpsError(
        'invalid-argument',
        `❓ Pertanyaan terlalu panjang (maksimum ${MAX_QUESTION_LENGTH} karakter)`
      );
    }

    console.log('📊 Request info:');
    console.log('  - Question:', question);
    console.log('  - PDF text length:', pdfText.length);
    console.log('  - History items:', history?.length || 0);

    // Sanitize and limit PDF text
    const MAX_PDF_LENGTH = 30000;
    const sanitizedPdfText = pdfText.length > MAX_PDF_LENGTH
      ? pdfText.substring(0, MAX_PDF_LENGTH) + '\n\n[Konten PDF dipotok...]'
      : pdfText;

    try {
      // Get API key from secret
      const apiKey = GOOGLE_AI_API_KEY.value();

      if (!apiKey) {
        console.error('❌ API Key not available');
        throw new HttpsError('failed-precondition', ERROR_MESSAGES.API_KEY_MISSING);
      }

      console.log('✅ API Key available');
      console.log('🤖 Initializing AI model...');

      // Initialize AI with Google AI plugin
      const ai = genkit({
        plugins: [googleAI({ apiKey })],
        model: geminiModel,
      });

      // Format chat history
      let conversationHistory = '';
      if (history && Array.isArray(history) && history.length > 0) {
        const chatHistory = history
          .filter((msg: any) => msg.role === 'user' || msg.role === 'model')
          .slice(-10); // Last 10 messages only

        if (chatHistory.length > 0) {
          conversationHistory = '\n\n--- Percakapan Sebelumnya ---\n';
          for (const msg of chatHistory) {
            const role = msg.role === 'user' ? 'Pengguna' : 'Asisten';
            conversationHistory += `${role}: ${msg.content}\n`;
          }
          conversationHistory += '--- Akhir Percakapan Sebelumnya ---\n';
        }
        console.log('📜 Using', chatHistory.length, 'messages from history');
      }

      // Construct prompt
      const prompt = `Anda adalah asisten yang membantu menjawab pertanyaan tentang dokumen PDF.

KONTEN PDF:
${sanitizedPdfText}

${conversationHistory}

PERTANYAAN SAAT INI: ${question}

INSTRUKSI:
1. Jawab berdasarkan konten PDF di atas
2. Jika informasi ADA di PDF, berikan jawaban yang jelas dan akurat
3. Jika informasi TIDAK ADA di PDF, katakan dengan sopan: "Maaf, informasi tersebut tidak saya temukan dalam dokumen PDF ini."
4. Jawaban dalam Bahasa Indonesia
5. Gunakan bullet point untuk daftar
6. Pertahankan konteks dari percakapan sebelumnya jika relevan
7. Pastikan seluruh penjelasan Anda selesai sepenuhnya sebelum mencapai batas 350 token agar tidak terpotong. Jika informasi terlalu banyak, rangkum menjadi poin-poin terpenting.

Jawaban:`;

      console.log('📤 Sending prompt to AI...');
      console.log('Prompt length:', prompt.length, 'chars');

      const response = await ai.generate({
        prompt,
        config: {
          maxOutputTokens: 1000,
        },
      });

      // Empty response check
      if (!response.text || response.text.trim().length === 0) {
        console.error('❌ AI returned empty response');
        throw new HttpsError('internal', ERROR_MESSAGES.EMPTY_RESPONSE);
      }

      const trimmedResponse = response.text.trim();

      console.log('✅ chatFlow SUCCESS');
      console.log('  - Response length:', trimmedResponse.length);

      return {
        response: trimmedResponse,
        model: 'gemini-2.5-flash-lite',
      };
    } catch (error: any) {
      console.error('❌ chatFlow ERROR:', error?.message || error);

      // Check if it's a Firestore error
      if (error?.message?.includes('Firestore') || error?.message?.includes('Datastore')) {
        throw new HttpsError(
          'failed-precondition',
          'Konfigurasi database belum sesuai. Hubungi administrator.'
        );
      }

      throw new HttpsError('internal', ERROR_MESSAGES.AI_ERROR);
    }
  }
);

// =============================================================================
// EXTRACT FLOW
// =============================================================================

/**
 * Extract specific information from PDF
 * Expects: { pdfText: string, prompt: string }
 * Returns: { data: string }
 */
export const extractFlow = onCall(
  {
    maxInstances: 10,
    region: 'asia-southeast1',
    secrets: [GOOGLE_AI_API_KEY],
  },
  async (request) => {
    console.log('=== extractFlow START ===');

    // Verify authentication
    if (!request.auth) {
      console.error('❌ Unauthenticated request');
      throw new HttpsError('unauthenticated', ERROR_MESSAGES.UNAUTHENTICATED);
    }

    console.log('✅ Authenticated:', request.auth.uid);

    const { pdfText, prompt } = request.data;

    if (!pdfText || typeof pdfText !== 'string') {
      console.error('❌ Invalid pdfText');
      throw new HttpsError('invalid-argument', ERROR_MESSAGES.INVALID_PDF_TEXT);
    }

    if (!prompt || typeof prompt !== 'string') {
      console.error('❌ Invalid prompt');
      throw new HttpsError('invalid-argument', 'Prompt tidak valid');
    }

    console.log('📊 Request info:');
    console.log('  - Prompt length:', prompt.length);
    console.log('  - PDF text length:', pdfText.length);

    // Limit context length
    const maxLength = 50000;
    const truncatedText = pdfText.length > maxLength
      ? pdfText.substring(0, maxLength) + '\n\n[Konten dipotok...]'
      : pdfText;

    try {
      // Get API key from secret
      const apiKey = GOOGLE_AI_API_KEY.value();

      if (!apiKey) {
        console.error('❌ API Key not available');
        throw new HttpsError('failed-precondition', ERROR_MESSAGES.API_KEY_MISSING);
      }

      console.log('✅ API Key available');

      // Initialize AI with Google AI plugin
      const ai = genkit({
        plugins: [googleAI({ apiKey })],
        model: geminiModel,
      });

      const extractionPrompt = `Ekstrak informasi yang diminta dari konten PDF berikut:

${truncatedText}

Permintaan: ${prompt}

Berikan informasi yang diekstrak dalam format yang jelas dan terstruktur.`;

      console.log('📤 Calling Gemini AI...');

      const response = await ai.generate({ prompt: extractionPrompt });

      const data = response.text?.trim();

      if (!data || data.length === 0) {
        console.error('❌ Empty extraction received');
        throw new HttpsError('internal', ERROR_MESSAGES.EMPTY_RESPONSE);
      }

      console.log(`✅ Extraction completed (${data.length} chars)`);

      return {
        data,
        model: 'gemini-2.5-flash-lite',
      };
    } catch (error: any) {
      console.error('❌ Error in extractFlow:', error?.message || error);

      // Check if it's a Firestore error
      if (error?.message?.includes('Firestore') || error?.message?.includes('Datastore')) {
        throw new HttpsError(
          'failed-precondition',
          'Konfigurasi database belum sesuai. Hubungi administrator.'
        );
      }

      throw new HttpsError('internal', ERROR_MESSAGES.AI_ERROR);
    }
  }
);

// =============================================================================
// HEALTH CHECK
// =============================================================================

/**
 * Health check function (no auth required)
 */
export const healthCheck = onCall(
  {
    maxInstances: 10,
    region: 'asia-southeast1',
  },
  async () => {
    return {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      version: '4.0.0',
      model: 'gemini-2.5-flash-lite',
      region: 'asia-southeast1',
      features: ['summarizeFlow', 'extractFlow', 'chatFlow'],
    };
  }
);
