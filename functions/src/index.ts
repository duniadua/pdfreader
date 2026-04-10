import { genkit } from 'genkit';
import { googleAI, gemini } from '@genkit-ai/googleai';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import { randomUUID } from 'crypto';

// Use Gemini 2.5 Flash Lite model (cost-optimized)
const geminiModel = gemini('gemini-2.5-flash-lite');

// Define secrets using Google Secret Manager
const GOOGLE_AI_API_KEY = defineSecret('GOOGLE_AI_API_KEY');

// Initialize Firebase Admin
admin.initializeApp();

// =============================================================================
// UTILITY FUNCTIONS
// =============================================================================

/**
 * Sanitize content by removing dangerous characters and limiting length
 */
function sanitizeContent(input: string, maxLength: number = 50000): string {
  if (!input) return '';

  // Remove null bytes and control characters (except newlines/tabs)
  let sanitized = input.replace(/[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F]/g, '');

  // Remove excessive whitespace sequences
  sanitized = sanitized.replace(/[ \t]{20,}/g, ' ');

  // Truncate if too long
  if (sanitized.length > maxLength) {
    sanitized = sanitized.substring(0, maxLength);
  }

  return sanitized;
}

/**
 * Validate history item structure
 */
function validateHistoryItem(item: any, index: number): void {
  if (!item || typeof item !== 'object') {
    throw new HttpsError(
      'invalid-argument',
      '💬 Chat history error (message #' + (index + 1) + ')\n\n' +
      'One of the messages in your conversation has an invalid format.\n\n' +
      'Please start a new conversation to continue.'
    );
  }

  if (!item.role || typeof item.role !== 'string') {
    throw new HttpsError(
      'invalid-argument',
      '💬 Chat history error (message #' + (index + 1) + ')\n\n' +
      'A message in your conversation is missing its role information.\n\n' +
      'Please start a new conversation to continue.'
    );
  }

  if (!item.content || typeof item.content !== 'string') {
    throw new HttpsError(
      'invalid-argument',
      '💬 Chat history error (message #' + (index + 1) + ')\n\n' +
      'A message in your conversation is missing its text content.\n\n' +
      'Please start a new conversation to continue.'
    );
  }

  if (!['user', 'model', 'assistant'].includes(item.role)) {
    throw new HttpsError(
      'invalid-argument',
      '💬 Chat history error (message #' + (index + 1) + ')\n\n' +
      'A message in your conversation has an invalid type.\n\n' +
      'Please start a new conversation to continue.'
    );
  }

  if (item.content.length > 10000) {
    const excessChars = item.content.length - 10000;
    throw new HttpsError(
      'invalid-argument',
      '💬 One message in your conversation is too long!\n\n' +
      'Message #' + (index + 1) + ' is ' + item.content.length + ' characters.\n' +
      'Maximum: 10,000 characters per message.\n' +
      'Excess: ' + excessChars + ' characters.\n\n' +
      '💡 Try asking shorter questions or start a new conversation.'
    );
  }
}

/**
 * Rate limit check result
 */
interface RateLimitResult {
  allowed: boolean;
  remaining: number;
  resetTime: number;
  limit: number;
  message?: string;
}

/**
 * Check rate limit for a user
 */
async function checkRateLimit(
  uid: string,
  db: admin.firestore.Firestore
): Promise<RateLimitResult> {
  const now = Date.now();
  const oneMinuteMs = 60000;
  const oneDayMs = 86400000;

  // Rate limit configuration
  const LIMITS = {
    perMinute: 8,   // 8 requests per minute
    perDay: 30,     // 30 requests per day
  };

  const userRef = db.collection('rate_limits').doc(uid);
  const requestsRef = userRef.collection('requests');

  // Check per-minute limit
  const minuteSnapshot = await requestsRef
    .where('timestamp', '>', now - oneMinuteMs)
    .get();

  const minuteCount = minuteSnapshot.size;
  if (minuteCount >= LIMITS.perMinute) {
    // Find oldest request to calculate reset time
    const oldestDoc = minuteSnapshot.docs[0];
    const resetTime = oldestDoc.data().timestamp + oneMinuteMs;
    const waitSeconds = Math.ceil((resetTime - now) / 1000);

    return {
      allowed: false,
      remaining: 0,
      resetTime: resetTime,
      limit: LIMITS.perMinute,
      message: `⏱️ You're sending messages too fast!\n\n` +
        `Rate limit: ${LIMITS.perMinute} messages per minute\n` +
        `Please wait: ${waitSeconds} seconds\n\n` +
        `💡 Take your time to read the AI responses and formulate your next question. ` +
        `This helps keep the service fast for everyone!`,
    };
  }

  // Check per-day limit
  const daySnapshot = await requestsRef
    .where('timestamp', '>', now - oneDayMs)
    .get();

  const dayCount = daySnapshot.size;
  if (dayCount >= LIMITS.perDay) {
    // Find oldest request to calculate reset time (from start of day window)
    const oldestDoc = daySnapshot.docs[0];
    const resetTime = oldestDoc.data().timestamp + oneDayMs;
    const waitMinutes = Math.ceil((resetTime - now) / 60000);

    return {
      allowed: false,
      remaining: 0,
      resetTime: resetTime,
      limit: LIMITS.perDay,
      message: `🌙 You've reached your daily limit!\n\n` +
        `Daily limit: ${LIMITS.perDay} messages per day\n` +
        `Resets in: ${waitMinutes} minutes\n\n` +
        `💡 Tips:\n` +
        `• Combine multiple questions into one message\n` +
        `• Be specific to get better answers\n` +
        `• Your limit will reset tomorrow\n\n` +
        `Thank you for using our service!`,
    };
  }

  // Request is allowed
  return {
    allowed: true,
    remaining: Math.min(
      LIMITS.perMinute - minuteCount,
      LIMITS.perDay - dayCount
    ),
    resetTime: now,
    limit: LIMITS.perMinute,
  };
}

/**
 * Log a rate limit request
 */
async function logRateLimitRequest(
  uid: string,
  db: admin.firestore.Firestore
): Promise<void> {
  const now = Date.now();
  await db
    .collection('rate_limits')
    .doc(uid)
    .collection('requests')
    .add({ timestamp: now });
}

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
    // Verify authentication
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { pdfText } = request.data;

    // Validate pdfText
    if (!pdfText || typeof pdfText !== 'string') {
      throw new HttpsError('invalid-argument', 'pdfText is required and must be a string');
    }

    // Edge case: Empty or whitespace-only pdfText
    const trimmedText = pdfText.trim();
    if (trimmedText.length === 0) {
      throw new HttpsError('invalid-argument', 'pdfText cannot be empty');
    }

    // Limit PDF text length to avoid timeout
    const maxLength = 50000; // ~50k characters
    const truncatedText = pdfText.length > maxLength
      ? pdfText.substring(0, maxLength) + '\n\n[Content truncated due to length...]'
      : pdfText;

    // Edge case: Missing API key
    if (!GOOGLE_AI_API_KEY.value()) {
      console.error('Google AI API Key is missing');
      throw new HttpsError('failed-precondition', 'Google AI API Key is not configured');
    }

    try {
      const ai = genkit({
        plugins: [googleAI({ apiKey: GOOGLE_AI_API_KEY.value() })],
        model: geminiModel,
      });

      const response = await ai.generate({
        prompt: `Summarize the following PDF content in a clear and concise way. Focus on the main points and key information:\n\n${truncatedText}`,
      });

      // Edge case: Empty response from AI
      if (!response.text || response.text.trim().length === 0) {
        console.error('AI returned empty response');
        throw new HttpsError('internal', 'AI model returned an empty response');
      }

      return {
        summary: response.text.trim(),
        truncated: pdfText.length > maxLength,
        model: 'gemini-2.5-flash-lite',
        timestamp: new Date().toISOString(),
        originalLength: pdfText.length,
        generatedLength: response.text.length,
      };
    } catch (error: any) {
      console.error('Error in summarizeFlow:', error?.message);

      // Handle specific error types
      if (error?.message?.includes('404') || error?.message?.includes('not found')) {
        throw new HttpsError('not-found', 'AI model is not available. Please check the model configuration.');
      }

      if (error?.message?.includes('API key')) {
        throw new HttpsError('failed-precondition', 'Google AI API key is invalid or missing');
      }

      throw new HttpsError('internal', `Failed to generate summary: ${error?.message || 'Unknown error'}`);
    }
  }
);

/**
 * Chat with PDF context
 * Expects: { pdfText: string, question: string, history: array }
 * Returns: { response: string }
 */
export const chatFlow = onCall(
  {
    maxInstances: 10,
    region: 'asia-southeast1',
    secrets: [GOOGLE_AI_API_KEY],
    timeoutSeconds: 55,
  },
  async (request) => {
    const startTime = Date.now();
    const requestId = randomUUID();

    console.log('=== chatFlow START ===');
    console.log('Request ID:', requestId);
    console.log('Timestamp:', new Date().toISOString());

    // Authentication check
    if (!request.auth) {
      console.error('❌ Unauthenticated request');
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }
    console.log('✅ Authenticated:', request.auth.uid);

    const { pdfText, question, history = [] } = request.data;
    const userId = request.auth.uid;

    // Size limit validation
    const MAX_REQUEST_SIZE = 100000; // 100KB total
    const totalSize = JSON.stringify({ pdfText, question, history }).length;
    if (totalSize > MAX_REQUEST_SIZE) {
      console.error('❌ Request too large:', totalSize, 'chars');
      throw new HttpsError(
        'invalid-argument',
        `📦 Your message is too large! (${Math.round(totalSize / 1000)}KB / 100KB limit)\n\n` +
        `To fix this:\n` +
        `• Shorten your question (max 1000 characters)\n` +
        `• Reduce chat history (old messages count toward size)\n` +
        `• Try asking a more specific question\n\n` +
        `Tip: Start a new conversation if history is too long.`
      );
    }

    // PDF text validation
    if (!pdfText || typeof pdfText !== 'string') {
      console.error('❌ Invalid pdfText');
      throw new HttpsError(
        'invalid-argument',
        '📄 No PDF content detected\n\n' +
        'The PDF text appears to be missing or invalid. This could happen if:\n' +
        '• The PDF file is corrupted\n' +
        '• The PDF could not be read properly\n' +
        '• The app is still processing the PDF\n\n' +
        'Please try re-opening the PDF or select a different PDF file.'
      );
    }

    // Sanitize PDF text
    const sanitizedPdfText = sanitizeContent(pdfText, 30000);
    if (sanitizedPdfText.trim().length === 0) {
      console.error('❌ Empty pdfText after sanitization');
      throw new HttpsError(
        'invalid-argument',
        '📄 This PDF appears to be empty\n\n' +
        'The PDF content is empty or contains only special characters that cannot be read.\n\n' +
        'Please try:\n' +
        '• Opening a different PDF file\n' +
        '• Checking if the PDF has readable text content\n' +
        '• Converting scanned PDFs to searchable text first'
      );
    }

    // Question validation
    if (!question || typeof question !== 'string') {
      console.error('❌ Invalid question');
      throw new HttpsError(
        'invalid-argument',
        '❓ Please enter a question\n\n' +
        'You need to type a question about the PDF to get an answer.\n\n' +
        'Examples of good questions:\n' +
        '• "What is the main topic of this document?"\n' +
        '• "Summarize the key findings"\n' +
        '• "What does it say about [topic]?"'
      );
    }

    const MAX_QUESTION_LENGTH = 1000;
    if (question.length > MAX_QUESTION_LENGTH) {
      console.error('❌ Question too long:', question.length);
      const excessChars = question.length - MAX_QUESTION_LENGTH;
      throw new HttpsError(
        'invalid-argument',
        `❓ Your question is too long!\n\n` +
        `Current: ${question.length} characters\n` +
        `Maximum: ${MAX_QUESTION_LENGTH} characters\n` +
        `Excess: ${excessChars} characters\n\n` +
        `💡 Try breaking your question into smaller parts or be more concise.\n\n` +
        `Example: Instead of "What are all the findings related to X, Y, and Z..."\n` +
        `Try: "What are the main findings?"`
      );
    }

    // Sanitize question
    const sanitizedQuestion = sanitizeContent(question, MAX_QUESTION_LENGTH);
    if (sanitizedQuestion.trim().length === 0) {
      console.error('❌ Empty question after sanitization');
      throw new HttpsError(
        'invalid-argument',
        '❓ Your question contains only special characters\n\n' +
        'Please enter a readable question using letters and numbers.\n\n' +
        'The question should not contain only spaces, tabs, or special characters.'
      );
    }

    // History validation
    if (!Array.isArray(history)) {
      console.error('❌ Invalid history format');
      throw new HttpsError(
        'invalid-argument',
        '💬 Chat history format error\n\n' +
        'The conversation history has an invalid format. This is likely a technical issue.\n\n' +
        'Please try:\n' +
        '• Refreshing the page\n' +
        '• Starting a new conversation\n' +
        '• If the problem persists, contact support'
      );
    }

    const MAX_HISTORY_ITEMS = 50;
    if (history.length > MAX_HISTORY_ITEMS) {
      console.error('❌ Too many history items:', history.length);
      throw new HttpsError(
        'invalid-argument',
        `💬 Conversation is too long!\n\n` +
        `Your conversation has ${history.length} messages, but the maximum is ${MAX_HISTORY_ITEMS}.\n\n` +
        `To continue:\n` +
        `• Start a new conversation\n` +
        `• The app will begin with a fresh context\n\n` +
        `💡 Tip: For very long discussions, starting fresh often works better!`
      );
    }

    // Validate each history item
    for (let i = 0; i < history.length; i++) {
      validateHistoryItem(history[i], i);
    }

    console.log('📊 Request info:');
    console.log('  - Question length:', sanitizedQuestion.length);
    console.log('  - PDF text length:', sanitizedPdfText.length);
    console.log('  - History items:', history.length);
    console.log('  - Total size:', totalSize, 'chars');

    // Rate limiting check
    const db = admin.firestore();
    const rateLimitCheck = await checkRateLimit(userId, db);

    if (!rateLimitCheck.allowed) {
      console.warn('⚠️ Rate limit exceeded:', rateLimitCheck.message);
      throw new HttpsError(
        'resource-exhausted',
        rateLimitCheck.message || 'Rate limit exceeded. Please try again later.'
      );
    }

    console.log('✅ Rate limit check passed');
    console.log('  - Remaining:', rateLimitCheck.remaining);

    // API key check
    if (!GOOGLE_AI_API_KEY.value()) {
      console.error('❌ Google AI API Key is missing');
      throw new HttpsError(
        'failed-precondition',
        'Google AI API Key is not configured.'
      );
    }
    console.log('✅ API Key available');

    try {
      console.log('🤖 Initializing AI model...');
      const ai = genkit({
        plugins: [googleAI({ apiKey: GOOGLE_AI_API_KEY.value() })],
        model: geminiModel,
      });

      // Filter history: remove last user message (would be duplicate)
      let filteredHistory = history;
      if (history.length > 0) {
        const lastMsg = history[history.length - 1];
        if (lastMsg.role === 'user') {
          console.log('🔄 Removing last user message from history (avoids duplicate)');
          filteredHistory = history.slice(0, -1);
        }
      }
      console.log('📜 History after filtering:', filteredHistory.length, 'items');

      // Format chat history (limit to last 20 messages)
      let conversationHistory = '';
      if (filteredHistory.length > 0) {
        const recentHistory = filteredHistory.slice(-20);
        conversationHistory = '\n\n--- Previous conversation ---\n';
        for (const msg of recentHistory) {
          const role = msg.role === 'user' ? 'User' : 'Assistant';
          conversationHistory += `${role}: ${msg.content}\n`;
        }
        conversationHistory += '--- End of previous conversation ---\n';
      }

      // Construct prompt
      const prompt = `You are a helpful assistant answering questions about a PDF document.

PDF DOCUMENT CONTENT:
${sanitizedPdfText}

${conversationHistory}

CURRENT QUESTION: ${sanitizedQuestion}

INSTRUCTIONS:
1. Answer based on the PDF content provided above
2. If the information is in the PDF, provide a clear and accurate answer
3. If the information is NOT in the PDF, politely say: "I don't find that information in this PDF document."
4. Keep your response concise and relevant
5. You can refer to previous conversation context if relevant

Answer:`;

      console.log('📤 Sending prompt to AI...');
      console.log('Prompt length:', prompt.length, 'chars');

      const response = await ai.generate({ prompt });

      // Empty response check
      if (!response.text || response.text.trim().length === 0) {
        console.error('❌ AI returned empty response');
        throw new HttpsError(
          'internal',
          'AI model returned an empty response. Please try again.'
        );
      }

      let trimmedResponse = response.text.trim();

      // Response size limit
      const MAX_RESPONSE_LENGTH = 5000;
      if (trimmedResponse.length > MAX_RESPONSE_LENGTH) {
        console.warn('⚠️ Response too long, truncating');
        trimmedResponse = trimmedResponse.substring(0, MAX_RESPONSE_LENGTH) +
          '\n\n[Response truncated due to length...]';
      }

      // Log successful request
      await logRateLimitRequest(userId, db);

      const duration = Date.now() - startTime;

      console.log('✅ chatFlow SUCCESS');
      console.log('  - Response length:', trimmedResponse.length);
      console.log('  - Duration:', duration, 'ms');
      console.log('  - History items used:', filteredHistory.length);
      console.log('  - Request ID:', requestId);

      return {
        response: trimmedResponse,
        model: 'gemini-2.5-flash-lite',
        timestamp: new Date().toISOString(),
        questionLength: sanitizedQuestion.length,
        responseLength: trimmedResponse.length,
        historyItems: filteredHistory.length,
        requestId: requestId,
        rateLimitRemaining: rateLimitCheck.remaining,
      };
    } catch (error: any) {
      const duration = Date.now() - startTime;
      console.error('❌ chatFlow ERROR after', duration, 'ms');
      console.error('  - Request ID:', requestId);
      console.error('  - Error type:', error?.constructor?.name || 'Unknown');
      console.error('  - Error message:', error?.message);

      // Handle specific error types
      if (error?.message?.includes('404') || error?.message?.includes('not found')) {
        throw new HttpsError(
          'not-found',
          'AI model is not available. Please try again.'
        );
      }

      if (error?.message?.includes('API key')) {
        throw new HttpsError(
          'failed-precondition',
          'Google AI API key is invalid or missing.'
        );
      }

      throw new HttpsError(
        'internal',
        `Failed to generate response: ${error?.message || 'Unknown error'}`
      );
    }
  }
);

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
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { pdfText, prompt } = request.data;

    if (!pdfText || typeof pdfText !== 'string') {
      throw new HttpsError('invalid-argument', 'pdfText is required');
    }

    // Edge case: Empty pdfText
    if (pdfText.trim().length === 0) {
      throw new HttpsError('invalid-argument', 'pdfText cannot be empty');
    }

    if (!prompt || typeof prompt !== 'string') {
      throw new HttpsError('invalid-argument', 'prompt is required');
    }

    // Edge case: Empty prompt
    if (prompt.trim().length === 0) {
      throw new HttpsError('invalid-argument', 'prompt cannot be empty');
    }

    // Limit context length
    const maxLength = 50000;
    const truncatedText = pdfText.length > maxLength
      ? pdfText.substring(0, maxLength) + '\n\n[Content truncated...]'
      : pdfText;

    // Edge case: Missing API key
    if (!GOOGLE_AI_API_KEY.value()) {
      console.error('Google AI API Key is missing');
      throw new HttpsError('failed-precondition', 'Google AI API Key is not configured');
    }

    try {
      const ai = genkit({
        plugins: [googleAI({ apiKey: GOOGLE_AI_API_KEY.value() })],
        model: geminiModel,
      });

      const fullPrompt = `Extract the requested information from the following PDF content:

${truncatedText}

Request: ${prompt}

Provide the extracted information in a clear, structured format.`;

      const response = await ai.generate({ prompt: fullPrompt });

      // Edge case: Empty response
      if (!response.text || response.text.trim().length === 0) {
        console.error('AI returned empty response');
        throw new HttpsError('internal', 'AI model returned an empty response');
      }

      return {
        data: response.text.trim(),
        model: 'gemini-2.5-flash-lite',
        timestamp: new Date().toISOString(),
        originalLength: pdfText.length,
        extractedLength: response.text.length,
      };
    } catch (error: any) {
      console.error('Error in extractFlow:', error?.message);

      // Handle specific error types
      if (error?.message?.includes('404') || error?.message?.includes('not found')) {
        throw new HttpsError('not-found', 'AI model is not available');
      }

      if (error?.message?.includes('API key')) {
        throw new HttpsError('failed-precondition', 'Google AI API key is invalid');
      }

      throw new HttpsError('internal', `Failed to extract information: ${error?.message}`);
    }
  }
);

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
      version: '1.0.0',
      model: 'gemini-2.5-flash-lite',
      region: 'asia-southeast1',
      features: ['summarizeFlow', 'extractFlow', 'chatFlow'],
    };
  }
);
