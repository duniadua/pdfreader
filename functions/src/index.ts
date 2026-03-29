import { genkit } from 'genkit';
import { googleAI, gemini } from '@genkit-ai/googleai';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';

// Use Gemini 2.5 Flash model (latest stable)
const geminiModel = gemini('gemini-2.5-flash');

// Define secrets using Google Secret Manager
const GOOGLE_AI_API_KEY = defineSecret('GOOGLE_AI_API_KEY');

// Initialize Firebase Admin
admin.initializeApp();

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
        model: 'gemini-2.5-flash',
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
 * Expects: { pdfText: string, question: string }
 * Returns: { response: string }
 */
export const chatFlow = onCall(
  {
    maxInstances: 10,
    region: 'asia-southeast1',
    secrets: [GOOGLE_AI_API_KEY],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { pdfText, question } = request.data;

    // Edge case: Invalid pdfText
    if (!pdfText || typeof pdfText !== 'string') {
      throw new HttpsError('invalid-argument', 'pdfText is required');
    }

    // Edge case: Empty pdfText
    if (pdfText.trim().length === 0) {
      throw new HttpsError('invalid-argument', 'pdfText cannot be empty');
    }

    // Edge case: Invalid question
    if (!question || typeof question !== 'string') {
      throw new HttpsError('invalid-argument', 'question is required');
    }

    // Edge case: Empty question
    if (question.trim().length === 0) {
      throw new HttpsError('invalid-argument', 'question cannot be empty');
    }

    // Limit context length
    const maxLength = 30000;
    const truncatedText = pdfText.length > maxLength
      ? pdfText.substring(0, maxLength) + '\n\n[PDF content truncated...]'
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

      const prompt = `You are a helpful assistant answering questions about a PDF document.

PDF Context:
${truncatedText}

Question: ${question}

Provide a helpful and accurate answer based on the PDF content above. If the answer is not in the document, say so clearly.`;

      const response = await ai.generate({ prompt });

      // Edge case: Empty response
      if (!response.text || response.text.trim().length === 0) {
        console.error('AI returned empty response');
        throw new HttpsError('internal', 'AI model returned an empty response');
      }

      return {
        response: response.text.trim(),
        model: 'gemini-2.5-flash',
        timestamp: new Date().toISOString(),
        questionLength: question.length,
        responseLength: response.text.length,
      };
    } catch (error: any) {
      console.error('Error in chatFlow:', error?.message);

      // Handle specific error types
      if (error?.message?.includes('404') || error?.message?.includes('not found')) {
        throw new HttpsError('not-found', 'AI model is not available');
      }

      if (error?.message?.includes('API key')) {
        throw new HttpsError('failed-precondition', 'Google AI API key is invalid');
      }

      throw new HttpsError('internal', `Failed to generate response: ${error?.message}`);
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
        model: 'gemini-2.5-flash',
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
      model: 'gemini-2.5-flash',
      region: 'asia-southeast1',
      features: ['summarizeFlow', 'extractFlow', 'chatFlow'],
    };
  }
);
