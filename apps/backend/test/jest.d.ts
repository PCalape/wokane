import 'jest';

// This file ensures TypeScript recognizes Jest globals when running tests
declare global {
  namespace NodeJS {
    interface Global {
      describe: (typeof import('@jest/globals'))['describe'];
      expect: (typeof import('@jest/globals'))['expect'];
      it: (typeof import('@jest/globals'))['it'];
      beforeAll: (typeof import('@jest/globals'))['beforeAll'];
      afterAll: (typeof import('@jest/globals'))['afterAll'];
      beforeEach: (typeof import('@jest/globals'))['beforeEach'];
      afterEach: (typeof import('@jest/globals'))['afterEach'];
      jest: (typeof import('@jest/globals'))['jest'];
    }
  }
}
