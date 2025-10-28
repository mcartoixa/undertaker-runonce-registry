import RunOnceRegistry from '..';
import DefaultRegistry from 'undertaker-registry';

describe('RunOnceRegistry', () => {
  test('should be an instance of DefaultRegistry', () => {
    const r = new RunOnceRegistry();

    expect(r).toBeInstanceOf(DefaultRegistry);
  });
});
