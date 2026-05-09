/**
 * Manual mock for firebase-admin
 * This provides reliable mocking for unit tests
 */

import { jest } from '@jest/globals';

// Create typed mock functions using 'as any' to avoid type issues
const mockGet = jest.fn() as any;
const mockSet = jest.fn() as any;
const mockDoc = jest.fn() as any;
const mockCollection = jest.fn() as any;
const mockGetTemplate = jest.fn() as any;

// Reset all mocks before each test
beforeEach(() => {
  mockGet.mockReset();
  mockSet.mockReset();
  mockDoc.mockReset();
  mockCollection.mockReset();
  mockGetTemplate.mockReset();

  // Setup default mock chain
  mockCollection.mockReturnValue({
    doc: mockDoc,
  });

  mockDoc.mockReturnValue({
    get: mockGet,
    set: mockSet,
  });

  // Default: document doesn't exist
  mockGet.mockResolvedValue({ exists: false });

  // Default: Remote Config template
  mockGetTemplate.mockResolvedValue({
    version: { versionNumber: '1' },
    parameterGroups: {},
  });
});

export const firestore = jest.fn(() => ({
  collection: mockCollection,
})) as any;

export const remoteConfig = jest.fn(() => ({
  getTemplate: mockGetTemplate,
})) as any;

// Export mock functions
export { mockGet, mockSet, mockDoc, mockCollection, mockGetTemplate };

export default {
  firestore,
  remoteConfig,
};
