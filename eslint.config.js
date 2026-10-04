import { defineConfig } from 'eslint/config';
import js from '@eslint/js';
import jest from 'eslint-plugin-jest';
import globals from 'globals';

import { includeIgnoreFile } from '@eslint/compat';
import { fileURLToPath, URL } from 'node:url';

const gitIgnorePath = fileURLToPath(new URL('.gitignore', import.meta.url));

export default defineConfig([
  includeIgnoreFile(gitIgnorePath, '.gitignore patterns'),
  js.configs.recommended,
  {
    languageOptions: {
      globals: globals.node,
    }
  },
  {
    files: ['./test/**/*.test.js'],
    plugins: { jest: jest },
    languageOptions: {
      globals: jest.environments.globals.globals,
    }
  },
]);
