# Rate Limiting Integration Tests

Comprehensive integration tests for the rate limiting system, testing end-to-end flows under various conditions.

## Test Suites

### 1. End-to-End Rate Limit Flow (`rateLimit.test.ts`)
Tests complete rate limiting scenarios:
- Hourly rate limiting and reset behavior
- Daily rate limiting and reset behavior
- Request interval enforcement
- Independent user counters
- Circuit breaker integration
- Fail-open behavior
- User usage statistics
- Performance under load
- Edge cases and error handling

**Run:**
```bash
npm test -- rateLimit.test.ts
```

### 2. Concurrent Request Handling (`concurrentRateLimit.test.ts`)
Tests rate limiting under concurrent load:
- 100 concurrent users with independent counters
- 1000 concurrent requests across users
- Concurrent requests from same user
- Sharded counter performance
- No race conditions or counter drift
- Performance under high load
- Mixed concurrent scenarios
- Stress testing (500+ concurrent requests)

**Run:**
```bash
npm test -- concurrentRateLimit.test.ts
```

### 3. Circuit Breaker Integration (`circuitBreaker.test.ts`)
Tests circuit breaker lifecycle:
- Circuit opening after 5 failures
- Auto-recovery after 60 seconds
- Half-open state handling
- Circuit closing on success
- Integration with rate limiting
- Failure counting accuracy
- Real-world outage scenarios

**Run:**
```bash
npm test -- circuitBreaker.test.ts
```

### 4. Fail-Open Behavior (`failOpen.test.ts`)
Tests fail-open when dependencies fail:
- Firestore unavailability
- Remote Config unreachable
- Network timeouts
- Error logging and request allowance
- Recovery scenarios
- Real-world failure simulation

**Run:**
```bash
npm test -- failOpen.test.ts
```

### 5. Remote Config Changes (`remoteConfigChange.test.ts`)
Tests dynamic configuration changes:
- Rate limit changes taking effect
- Enabling/disabling rate limiting
- Configuration propagation
- Backward compatibility
- Multiple function types
- Performance with config changes

**Run:**
```bash
npm test -- remoteConfigChange.test.ts
```

## Prerequisites

### 1. Start Firebase Emulators

The tests require Firebase emulators to be running:

```bash
# From the project root
firebase emulators:start --only firestore

# Or start all emulators
firebase emulators:start
```

**Default ports:**
- Firestore: 8080
- Functions: 5001

### 2. Install Dependencies

```bash
cd functions
npm install
```

### 3. Build TypeScript

```bash
npm run build
```

## Running Tests

### Run All Integration Tests

```bash
# From functions directory
npm test

# Run with coverage
npm run test:coverage

# Run in watch mode
npm run test:watch
```

### Run Specific Test Suite

```bash
# Rate limit tests
npm test -- rateLimit.test.ts

# Concurrent tests
npm test -- concurrentRateLimit.test.ts

# Circuit breaker tests
npm test -- circuitBreaker.test.ts

# Fail-open tests
npm test -- failOpen.test.ts

# Remote config tests
npm test -- remoteConfigChange.test.ts
```

### Run Specific Test

```bash
# Run a specific test by name
npm test -- -t "should limit user after 11 summarize requests"

# Run tests matching a pattern
npm test -- -t "concurrent"
```

### Debug Tests

```bash
# Run with verbose output
npm test -- --verbose

# Run with debugger
node --inspect-brk node_modules/.bin/jest --runInBand

# Run single test file with logs
npm test -- rateLimit.test.ts --no-coverage --verbose
```

## Test Configuration

### Jest Configuration (`jest.config.js`)

```javascript
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/test'],
  testMatch: ['**/*.test.ts'],
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/index.ts',
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
  },
  setupFilesAfterEnv: ['<rootDir>/test/setup.ts'],
};
```

### Environment Variables

Create a `.env.test` file:

```bash
FIRESTORE_EMULATOR_HOST=localhost:8080
FIREBASE_PROJECT_ID=test-project
GCLOUD_PROJECT=test-project
```

## Test Data Management

### Cleanup

Tests automatically clean up after themselves, but you can manually clean:

```bash
# Delete all rate limit counters
firebase firestore:delete --rateLimitCounters

# Delete circuit breaker state
firebase firestore:delete --circuitBreaker

# Delete config
firebase firestore:delete --config
```

### Test Users

Integration tests use prefixed test user IDs:
- `test-user-rate-limit-1`
- `test-user-rate-limit-2`
- `concurrent-user-0` through `concurrent-user-99`
- `circuit-breaker-test-user`
- `fail-open-test-user`
- `remote-config-test-user`

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - uses: actions/setup-node@v3
        with:
          node-version: '20'

      - name: Install dependencies
        run: |
          cd functions
          npm install

      - name: Build
        run: |
          cd functions
          npm run build

      - name: Start Firebase Emulators
        run: |
          npx firebase emulators:start --only firestore &
          npx wait-on http://localhost:8080

      - name: Run integration tests
        run: |
          cd functions
          npm test -- test/integration

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./functions/coverage/lcov.info
```

## Performance Benchmarks

Expected performance targets:

| Metric | Target |
|--------|--------|
| Rate limit check | <100ms |
| Concurrent requests (100 users) | <5000ms total |
| Circuit breaker check | <50ms |
| Config refresh | <200ms |
| Counter increment | <100ms |

## Troubleshooting

### Tests Fail to Connect to Emulator

**Error:** `FirebaseError: 7 ABORTED: The emulator was disconnected`

**Solution:**
```bash
# Ensure emulator is running
firebase emulators:start --only firestore

# Check port is available
lsof -i :8080

# Set environment variable
export FIRESTORE_EMULATOR_HOST=localhost:8080
```

### Tests Time Out

**Error:** `Timeout - Async callback was not invoked within the 5000ms timeout`

**Solution:**
```bash
# Increase timeout in jest.config.js
jest.setTimeout(30000);

# Or for specific test
test('slow test', async () => {
  // ...
}, 30000);
```

### Counter Mismatch

**Error:** Counter counts don't match expected values

**Solution:**
- Check for leftover test data: Delete all documents in `rateLimitCounters` collection
- Run tests sequentially: `npm test -- --runInBand`
- Increase delay between tests: `await new Promise(resolve => setTimeout(resolve, 1000));`

### Firestore Already Initialized

**Error:** `FirebaseAppError: The default Firebase app already exists`

**Solution:**
```typescript
// In test setup
try {
  await admin.initializeApp();
} catch (e: any) {
  if (e.code !== 'app/duplicate-app') {
    throw e;
  }
}
```

## Best Practices

### 1. Test Isolation
- Each test should clean up its data
- Use unique test user IDs
- Don't rely on test execution order

### 2. Performance
- Use `--runInBand` for debugging, but parallel for CI
- Mock external dependencies (Gemini AI API)
- Use in-memory Firestore emulator

### 3. Readability
- Use descriptive test names
- Group related tests with `describe`
- Add comments for complex scenarios

### 4. Maintenance
- Update tests when rate limit logic changes
- Add new tests for new features
- Keep test data realistic

## Coverage Goals

Target coverage for rate limiting code:

| Component | Target |
|-----------|--------|
| Middleware | 90% |
| Distributed Counter | 85% |
| Circuit Breaker | 90% |
| Remote Config | 80% |
| Overall | 85% |

## Additional Resources

- [Firebase Functions Test SDK](https://firebase.google.com/docs/functions/unit-testing)
- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [Firestore Emulator](https://firebase.google.com/docs/emulator-suite/connect_firestore)
- [Circuit Breaker Pattern](https://martinfowler.com/bliki/CircuitBreaker.html)
