/** @returns {Promise<import('jest').Config>} */
module.exports = async () => {
  return {
    cacheDirectory: '<rootDir>/.tmp/cache/jest',
    coverageDirectory: '<rootDir>/tmp/jest.coverage-results',
    moduleFileExtensions: ['js'],
    reporters: [
      'default',
      ['jest-junit', { outputDirectory: 'tmp', outputName: 'jest-results.xml' }],
      ['./node_modules/jest-html-reporter', { pageTitle: 'undertaker-runonce-registry', outputPath: './tmp/jest-results.html' }],
    ],
    testEnvironmentOptions: {
      customExportConditions: [
        'node',
        'node-addons',
      ],
    },
  };
};
