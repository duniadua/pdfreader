import { genkit, z } from 'genkit';
import { googleAI, gemini15Flash } from '@genkit-ai/googleai';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin
admin.initializeApp();

// Initialize Genkit with Google AI plugin
const ai = genkit({
  plugins: [googleAI()],
  model: gemini15Flash,
});

/**
 * Summarize PDF content
 * Expects: { pdfText: string }
 * Returns: { summary: string }
 */
export const summarizeFlow = onCall(
  {
    maxInstances: 10,
    region: 'asia-southeast1',
  },
  async (request) => {
    // Verify authentication
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { pdfText } = request.data;

    if (!pdfText || typeof pdfText !== 'string') {
      throw new HttpsError('invalid-argument', 'pdfText is required and must be a string');
    }

    // Limit PDF text length to avoid timeout
    const maxLength = 50000; // ~50k characters
    const truncatedText = pdfText.length > maxLength 
      ? pdfText.substring(0, maxLength) + '\n\n[Content truncated due to length...]' 
      : pdfText;

    try {
      const response = await ai.generate({
        prompt: `Summarize the following PDF content in a clear and concise way. Focus on the main points and key information:\n\n${truncatedText}`,
      });

      return { 
        summary: response.text,
        truncated: pdfText.length > maxLength 
      };
    } catch (error) {
      console.error('Error in summarizeFlow:', error);
      throw new HttpsError('internal', 'Failed to generate summary');
    }
  }
);

/**
 * Chat with PDF context
 * Expects: { pdfText: string, question: string, history?: Array<{role: string, content: string}> }
 * Returns: { response: string }
 */
export const chatFlow = onCall(
  {
    maxInstances: 10,
    region: 'asia-southeast1',
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { pdfText, question, history } = request.data;

    if (!pdfText || typeof pdfText !== 'string') {
      throw new HttpsError('invalid-argument', 'pdfText is required');
    }

    if (!question || typeof question !== 'string') {
      throw new HttpsError('invalid-argument', 'question is required');
    }

    // Limit context length
    const maxLength = 30000;
    const truncatedText = pdfText.length > maxLength 
      ? pdfText.substring(0, maxLength) + '\n\n[PDF content truncated...]'
      : pdfText;

    try {
      const response = await ai.generate({
        prompt: `You are a helpful assistant answering questions about a PDF document. 

PDF Context:
${truncatedText}

Question: ${question}

Provide a helpful and accurate answer based on the PDF content above. If the answer is not in the document, say so clearly.`,
      });

      return { response: response.text };
    } catch (error) {
      console.error('Error in chatFlow:', error);
      throw new HttpsError('internal', 'Failed to generate response');
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
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { pdfText, prompt } = request.data;

    if (!pdfText || typeof pdfText !== 'string') {
      throw new HttpsError('invalid-argument', 'pdfText is required');
    }

    if (!prompt || typeof prompt !== 'string') {
      throw new HttpsError('invalid-argument', 'prompt is required');
    }

    // Limit context length
    const maxLength = 50000;
    const truncatedText = pdfText.length > maxLength 
      ? pdfText.substring(0, maxLength) + '\n\n[Content truncated...]'
      : pdfText;

    try {
      const response = await ai.generate({
        prompt: `Extract the requested information from the following PDF content:

${truncatedText}

Request: ${prompt}

Provide the extracted information in a clear, structured format.`,
      });

      return { data: response.text };
    } catch (error) {
      console.error('Error in extractFlow:', error);
      throw new HttpsError('internal', 'Failed to extract information');
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
      version: '1.0.0'
    };
  }
);
