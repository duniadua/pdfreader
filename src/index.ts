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
    timeout: 120, // 2 minutes
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
    const maxLength = 50000;
    const truncatedText = pdfText.length > maxLength
      ? pdfText.substring(0, maxLength) + '\n\n[Content truncated due to length...]'
      : pdfText;

    try {
      const response = await ai.generate({
        prompt: `Summarize the following PDF content in a clear and concise way. Focus on the main points and key information:\n\n${truncatedText}`,
      });

      const summary = response.text?.trim();
      if (!summary || summary.length === 0) {
        console.error('❌ Empty summary received');
        throw new HttpsError('internal', 'AI returned an empty summary');
      }

      console.log(`✅ Summary generated (${summary.length} chars)`);

      return {
        summary,
        truncated: pdfText.length > maxLength
      };
    } catch (error) {
      console.error('❌ Error in summarizeFlow:', error);
      throw new HttpsError('internal', `Failed to generate summary: ${error instanceof Error ? error.message : 'Unknown error'}`);
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
    timeout: 120, // 2 minutes for chat with history
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

    // Limit context length - match client limit (50000)
    const maxLength = 50000;
    const truncatedText = pdfText.length > maxLength
      ? pdfText.substring(0, maxLength) + '\n\n[PDF content truncated...]'
      : pdfText;

    try {
      // Build conversation history for context
      let conversationHistory = '';
      if (history && Array.isArray(history) && history.length > 0) {
        // Filter to only actual chat messages (not summaries or key points)
        // and limit to last 10 messages to avoid context overflow
        const chatHistory = history
          .filter(msg => msg.role === 'user' || msg.role === 'model')
          .slice(-10);

        if (chatHistory.length > 0) {
          conversationHistory = '\n\nPrevious conversation:\n' +
            chatHistory
              .map(msg => `${msg.role === 'user' ? 'User' : 'Assistant'}: ${msg.content}`)
              .join('\n') +
            '\n';
        }
        console.log(`📝 Using ${chatHistory.length} messages from history`);
      }

      const response = await ai.generate({
        prompt: `You are a helpful assistant answering questions about a PDF document.

${conversationHistory}PDF Context:
${truncatedText}

Current Question: ${question}

Provide a helpful and accurate answer based on the PDF content above. If the answer is not in the document, say so clearly.

IMPORTANT:
- Keep your answer concise and to the point
- If you're not sure, say so
- Use bullet points for lists
- For questions outside the PDF content, clearly state: "Based on the PDF document, this information is not available."`,
      });

      // Check for empty response
      const responseText = response.text?.trim();
      if (!responseText || responseText.length === 0) {
        console.error('❌ Empty AI response received');
        throw new HttpsError('internal', 'AI returned an empty response');
      }

      console.log(`✅ Chat response generated (${responseText.length} chars)`);

      return { response: responseText };
    } catch (error) {
      console.error('❌ Error in chatFlow:', error);
      console.error('❌ Error details:', JSON.stringify(error, null, 2));
      throw new HttpsError('internal', `Failed to generate response: ${error instanceof Error ? error.message : 'Unknown error'}`);
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
    timeout: 120, // 2 minutes
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

    // Limit context length - match client limit (50000)
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

      const data = response.text?.trim();
      if (!data || data.length === 0) {
        console.error('❌ Empty extraction received');
        throw new HttpsError('internal', 'AI returned an empty response');
      }

      console.log(`✅ Extraction completed (${data.length} chars)`);

      return { data };
    } catch (error) {
      console.error('❌ Error in extractFlow:', error);
      throw new HttpsError('internal', `Failed to extract information: ${error instanceof Error ? error.message : 'Unknown error'}`);
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
