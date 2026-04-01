module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/test'],
  testMatch: ['**/?(*.)+(spec|test).ts'],
  transform: {
    '^.+\\.tsx?$': 'ts-jest',
  },
  transformIgnorePatterns: [
    'node_modules/(?!(genkit|@genkit-ai)/)',
  ],
  collectCoverageFrom: [
    'lib/**/*.ts',
    '!lib/**/*.d.ts',
    '!lib/**/*.freezed.ts',
    '!lib/**/*.g.dart',
  ],
  coverageDirectory: 'coverage',
  verbose: true,
  testTimeout: 30000,
  modulePathIgnorePatterns: ['<rootDir>/lib'],
  testPathIgnorePatterns: ['<rootDir>/lib'],
  globals: {
    'ts-jest': {
      tsconfig: {
        esModuleInterop: true,
        allowSyntheticDefaultImports: true,
        module: 'commonjs',
      },
    },
  },
};
