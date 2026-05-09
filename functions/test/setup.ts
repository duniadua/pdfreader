/**
 * Test Setup File
 *
 * Global setup for Jest tests
 * - Configure environment variables
 * - Set up test mocks
 * - Configure test timeouts
 */

// Set environment variables for tests
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
process.env.FIREBASE_PROJECT_ID = 'test-project';
process.env.GCLOUD_PROJECT = 'test-project';
process.env.FIREBASE_CONFIG = JSON.stringify({
  projectId: 'test-project',
  storageBucket: 'test-project.appspot.com',
});

// Increase timeout for integration tests
jest.setTimeout(30000);

// Mock console methods to reduce noise in tests (optional)
const originalError = console.error;
const originalWarn = console.warn;

beforeAll(() => {
  // You can suppress console output here if needed
  // console.error = jest.fn();
  // console.warn = jest.fn();
});

afterAll(() => {
  // Restore console methods
  console.error = originalError;
  console.warn = originalWarn;
});

// Global test cleanup
afterEach(() => {
  jest.clearAllMocks();
});

// Handle unhandled promises
process.on('unhandledRejection', (error) => {
  console.error('Unhandled Promise Rejection:', error);
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
});
