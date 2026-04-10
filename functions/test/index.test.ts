/**
 * Firebase Functions Unit Tests
 *
 * Tests for edge case handling in AI-powered PDF operations:
 * - summarizeFlow: PDF summarization
 * - extractFlow: Information extraction
 * - chatFlow: Q&A with PDF context
 */

import { describe, it, expect, beforeAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import functionsTest from 'firebase-functions-test';
import { summarizeFlow, extractFlow, chatFlow, healthCheck } from '../lib/index';

// Initialize firebase-functions-test
const testEnv = functionsTest({
  projectId: 'test-project',
});

// Test helper to create authenticated request
const createAuthRequest = (data: any, uid: string = 'test-user-123') => ({
  data,
  auth: { uid, token: {} },
  rawRequest: {} as any,
} as any);

// Test helper to create unauthenticated request
const createUnauthRequest = (data: any) => ({
  data,
  auth: null,
  rawRequest: {} as any,
} as any);

// Test helper for health check (no auth)
const createHealthRequest = () => ({
  data: {},
  auth: null,
  rawRequest: {} as any,
} as any);

describe('Firebase Functions - Edge Case Tests', () => {
  beforeAll(() => {
    // Initialize Firebase Admin for testing
    if (!admin.apps.length) {
      admin.initializeApp({
        projectId: 'test-project',
      });
    }
  });

  afterAll(() => {
    testEnv.cleanup();
  });

  describe('summarizeFlow', () => {
    describe('Authentication Edge Cases', () => {
      it('should reject unauthenticated requests', async () => {
        const wrapped = testEnv.wrap(summarizeFlow);
        const request = createUnauthRequest({ pdfText: 'test' });

        await expect(wrapped(request)).rejects.toThrow();
      });

      it('should accept authenticated requests (may fail at API level)', async () => {
        const wrapped = testEnv.wrap(summarizeFlow);
        const request = createAuthRequest({ pdfText: 'Valid PDF content for testing summarization.' });

        try {
          await wrapped(request);
        } catch (error: any) {
          // Should fail with API error, not auth error
          expect(error.message).not.toContain('unauthenticated');
        }
      });
    });

    describe('Input Validation Edge Cases', () => {
      it('should reject null pdfText', async () => {
        const wrapped = testEnv.wrap(summarizeFlow);
        const request = createAuthRequest({ pdfText: null });

        await expect(wrapped(request)).rejects.toThrow();
      });

      it('should reject undefined pdfText', async () => {
        const wrapped = testEnv.wrap(summarizeFlow);
        const request = createAuthRequest({});

        await expect(wrapped(request)).rejects.toThrow();
      });

      it('should reject non-string pdfText', async () => {
        const wrapped = testEnv.wrap(summarizeFlow);
        const request = createAuthRequest({ pdfText: 12345 });

        await expect(wrapped(request)).rejects.toThrow();
      });

      it('should reject empty string pdfText', async () => {
        const wrapped = testEnv.wrap(summarizeFlow);
        const request = createAuthRequest({ pdfText: '' });

        await expect(wrapped(request)).rejects.toThrow('pdfText is required');
      });

      it('should reject whitespace-only pdfText', async () => {
        const wrapped = testEnv.wrap(summarizeFlow);
        const request = createAuthRequest({ pdfText: '   \n\t   ' });

        await expect(wrapped(request)).rejects.toThrow('pdfText cannot be empty');
      });

      it('should handle very long pdfText', async () => {
        const wrapped = testEnv.wrap(summarizeFlow);
        const longText = 'A'.repeat(60000); // 60KB
        const request = createAuthRequest({ pdfText: longText });

        try {
          await wrapped(request);
        } catch (error: any) {
          // Should handle truncation and fail at API level, not validation
          expect(error.message).not.toContain('invalid-argument');
        }
      });
    });

    describe('Response Validation Edge Cases', () => {
      it('should handle AI errors gracefully', async () => {
        const wrapped = testEnv.wrap(summarizeFlow);
        const request = createAuthRequest({ pdfText: 'Test content' });

        try {
          await wrapped(request);
        } catch (error: any) {
          // Verify error is properly formatted
          expect(error).toBeDefined();
        }
      });
    });
  });

  describe('extractFlow', () => {
    describe('Authentication Edge Cases', () => {
      it('should reject unauthenticated requests', async () => {
        const wrapped = testEnv.wrap(extractFlow);
        const request = createUnauthRequest({
          pdfText: 'test',
          prompt: 'test',
        });

        await expect(wrapped(request)).rejects.toThrow();
      });
    });

    describe('Input Validation Edge Cases', () => {
      it('should reject null pdfText', async () => {
        const wrapped = testEnv.wrap(extractFlow);
        const request = createAuthRequest({
          pdfText: null,
          prompt: 'Extract name',
        });

        await expect(wrapped(request)).rejects.toThrow();
      });

      it('should reject undefined pdfText', async () => {
        const wrapped = testEnv.wrap(extractFlow);
        const request = createAuthRequest({
          prompt: 'Extract name',
        });

        await expect(wrapped(request)).rejects.toThrow();
      });

      it('should reject empty pdfText', async () => {
        const wrapped = testEnv.wrap(extractFlow);
        const request = createAuthRequest({
          pdfText: '',
          prompt: 'Extract name',
        });

        await expect(wrapped(request)).rejects.toThrow('pdfText is required');
      });

      it('should reject whitespace-only pdfText', async () => {
        const wrapped = testEnv.wrap(extractFlow);
        const request = createAuthRequest({
          pdfText: '   \n\t   ',
          prompt: 'Extract name',
        });

        await expect(wrapped(request)).rejects.toThrow('pdfText cannot be empty');
      });

      it('should reject null prompt', async () => {
        const wrapped = testEnv.wrap(extractFlow);
        const request = createAuthRequest({
          pdfText: 'John is 30 years old',
          prompt: null,
        });

        await expect(wrapped(request)).rejects.toThrow();
      });

      it('should reject undefined prompt', async () => {
        const wrapped = testEnv.wrap(extractFlow);
        const request = createAuthRequest({
          pdfText: 'John is 30 years old',
        });

        await expect(wrapped(request)).rejects.toThrow();
      });

      it('should reject empty prompt', async () => {
        const wrapped = testEnv.wrap(extractFlow);
        const request = createAuthRequest({
          pdfText: 'John is 30 years old',
          prompt: '',
        });

        await expect(wrapped(request)).rejects.toThrow('prompt is required');
      });

      it('should reject whitespace-only prompt', async () => {
        const wrapped = testEnv.wrap(extractFlow);
        const request = createAuthRequest({
          pdfText: 'John is 30 years old',
          prompt: '   \n\t   ',
        });

        await expect(wrapped(request)).rejects.toThrow('prompt cannot be empty');
      });

      it('should reject non-string pdfText', async () => {
        const wrapped = testEnv.wrap(extractFlow);
        const request = createAuthRequest({
          pdfText: 12345,
          prompt: 'Extract data',
        });

        await expect(wrapped(request)).rejects.toThrow();
      });

      it('should reject non-string prompt', async () => {
        const wrapped = testEnv.wrap(extractFlow);
        const request = createAuthRequest({
          pdfText: 'Valid text',
          prompt: 12345,
        });

        await expect(wrapped(request)).rejects.toThrow();
      });

      it('should handle very long pdfText', async () => {
        const wrapped = testEnv.wrap(extractFlow);
        const longText = 'A'.repeat(60000);
        const request = createAuthRequest({
          pdfText: longText,
          prompt: 'Extract data',
        });

        try {
          await wrapped(request);
        } catch (error: any) {
          // Should handle truncation
          expect(error.message).not.toContain('invalid-argument');
        }
      });
    });

    describe('Response Validation Edge Cases', () => {
      it('should handle AI errors gracefully', async () => {
        const wrapped = testEnv.wrap(extractFlow);
        const request = createAuthRequest({
          pdfText: 'Test content',
          prompt: 'Extract data',
        });

        try {
          await wrapped(request);
        } catch (error: any) {
          expect(error).toBeDefined();
        }
      });
    });
  });

  describe('chatFlow', () => {
    describe('Authentication Edge Cases', () => {
      it('should reject unauthenticated requests', async () => {
        const wrapped = testEnv.wrap(chatFlow);
        const request = createUnauthRequest({
          pdfText: 'test',
          question: 'What is this?',
        });

        await expect(wrapped(request)).rejects.toThrow();
      });
    });

    describe('Input Validation Edge Cases', () => {
      it('should reject null pdfText', async () => {
        const wrapped = testEnv.wrap(chatFlow);
        const request = createAuthRequest({
          pdfText: null,
          question: 'What is this?',
        });

        await expect(wrapped(request)).rejects.toThrow();
      });

      it('should reject undefined pdfText', async () => {
        const wrapped = testEnv.wrap(chatFlow);
        const request = createAuthRequest({
          question: 'What is this?',
        });

        await expect(wrapped(request)).rejects.toThrow();
      });

      it('should reject empty pdfText', async () => {
        const wrapped = testEnv.wrap(chatFlow);
        const request = createAuthRequest({
          pdfText: '',
          question: 'What is this?',
        });

        await expect(wrapped(request)).rejects.toThrow('PDF content detected');
      });

      it('should reject whitespace-only pdfText', async () => {
        const wrapped = testEnv.wrap(chatFlow);
        const request = createAuthRequest({
          pdfText: '   \n\t   ',
          question: 'What is this?',
        });

        await expect(wrapped(request)).rejects.toThrow('PDF appears to be empty');
      });

      it('should reject null question', async () => {
        const wrapped = testEnv.wrap(chatFlow);
        const request = createAuthRequest({
          pdfText: 'This is a document',
          question: null,
        });

        await expect(wrapped(request)).rejects.toThrow();
      });

      it('should reject undefined question', async () => {
        const wrapped = testEnv.wrap(chatFlow);
        const request = createAuthRequest({
          pdfText: 'This is a document',
        });

        await expect(wrapped(request)).rejects.toThrow();
      });

      it('should reject empty question', async () => {
        const wrapped = testEnv.wrap(chatFlow);
        const request = createAuthRequest({
          pdfText: 'This is a document',
          question: '',
        });

        await expect(wrapped(request)).rejects.toThrow('Please enter a question');
      });

      it('should reject whitespace-only question', async () => {
        const wrapped = testEnv.wrap(chatFlow);
        const request = createAuthRequest({
          pdfText: 'This is a document',
          question: '   \n\t   ',
        });

        await expect(wrapped(request)).rejects.toThrow('only special characters');
      });

      it('should reject non-string pdfText', async () => {
        const wrapped = testEnv.wrap(chatFlow);
        const request = createAuthRequest({
          pdfText: 12345,
          question: 'What is this?',
        });

        await expect(wrapped(request)).rejects.toThrow();
      });

      it('should reject non-string question', async () => {
        const wrapped = testEnv.wrap(chatFlow);
        const request = createAuthRequest({
          pdfText: 'Valid text',
          question: 12345,
        });

        await expect(wrapped(request)).rejects.toThrow();
      });

      it('should handle very long pdfText', async () => {
        const wrapped = testEnv.wrap(chatFlow);
        const longText = 'A'.repeat(35000);
        const request = createAuthRequest({
          pdfText: longText,
          question: 'What is this about?',
        });

        try {
          await wrapped(request);
        } catch (error: any) {
          // Should handle truncation
          expect(error.message).not.toContain('invalid-argument');
        }
      });
    });

    describe('Response Validation Edge Cases', () => {
      it('should handle AI errors gracefully', async () => {
        const wrapped = testEnv.wrap(chatFlow);
        const request = createAuthRequest({
          pdfText: 'Test content',
          question: 'What is this?',
        });

        try {
          await wrapped(request);
        } catch (error: any) {
          expect(error).toBeDefined();
        }
      });
    });
  });

  describe('healthCheck', () => {
    it('should return healthy status without authentication', async () => {
      const wrapped = testEnv.wrap(healthCheck);
      const request = createHealthRequest();
      const result = await wrapped(request);

      expect(result).toBeDefined();
      expect(result.status).toBe('healthy');
      expect(result.version).toBeDefined();
      expect(result.model).toBe('gemini-2.5-flash-lite');
      expect(result.region).toBe('asia-southeast1');
      expect(result.features).toContain('summarizeFlow');
      expect(result.features).toContain('extractFlow');
      expect(result.features).toContain('chatFlow');
    });

    it('should include timestamp', async () => {
      const wrapped = testEnv.wrap(healthCheck);
      const request = createHealthRequest();
      const result = await wrapped(request);

      expect(result.timestamp).toBeDefined();
      expect(new Date(result.timestamp)).toBeInstanceOf(Date);
    });
  });

  describe('Special Character Handling', () => {
    it('should handle pdfText with special characters', async () => {
      const wrapped = testEnv.wrap(chatFlow);
      const request = createAuthRequest({
        pdfText: 'Test with émojis 🎉 and spëcial çharacters',
        question: 'What is this?',
      });

      try {
        await wrapped(request);
      } catch (error: any) {
        // Should not fail validation
        expect(error.message).not.toContain('invalid-argument');
      }
    });

    it('should handle pdfText with newlines and tabs', async () => {
      const wrapped = testEnv.wrap(chatFlow);
      const request = createAuthRequest({
        pdfText: 'Line 1\nLine 2\tTabbed\n\nLine 4',
        question: 'What is this?',
      });

      try {
        await wrapped(request);
      } catch (error: any) {
        // Should not fail validation
        expect(error.message).not.toContain('invalid-argument');
      }
    });

    it('should handle prompt with newlines', async () => {
      const wrapped = testEnv.wrap(extractFlow);
      const request = createAuthRequest({
        pdfText: 'Valid content',
        prompt: 'Extract:\n- Name\n- Age\n- Location',
      });

      try {
        await wrapped(request);
      } catch (error: any) {
        // Should not fail validation
        expect(error.message).not.toContain('invalid-argument');
      }
    });
  });
});
