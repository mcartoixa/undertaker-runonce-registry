import RunOnceRegistry from '..';
import DefaultRegistry from 'undertaker-registry';
import gulp from 'gulp';
import { Readable } from 'node:stream';

function createGulp() {
  const g = new gulp.Gulp();
  g.registry(new RunOnceRegistry());
  return g;
}

function run(fn) {
  return new Promise((resolve, reject) => fn((err, result) => (err ? reject(err) : resolve(result))));
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function noop(done) {
  done();
}

describe('RunOnceRegistry', () => {
  test('should be an instance of DefaultRegistry', () => {
    const r = new RunOnceRegistry();

    expect(r).toBeInstanceOf(DefaultRegistry);
  });

  test('should execute a task referenced twice in a series once', async () => {
    const g = createGulp();
    let count = 0;
    g.task('prepare', (done) => {
      count++;
      done();
    });

    await run(g.series('prepare', noop, 'prepare'));

    expect(count).toBe(1);
  });

  test('should execute a task referenced by concurrent branches once', async () => {
    const g = createGulp();
    let count = 0;
    g.task('prepare', (done) => {
      count++;
      setTimeout(done, 20);
    });

    await run(g.parallel(g.series('prepare', noop), g.series('prepare', noop)));

    expect(count).toBe(1);
  });

  test('should execute callback, promise and stream tasks once', async () => {
    const g = createGulp();
    const counts = { callback: 0, promise: 0, stream: 0 };
    g.task('callback', (done) => {
      counts.callback++;
      setTimeout(done, 10);
    });
    g.task('promise', async () => {
      counts.promise++;
      await delay(10);
    });
    g.task('stream', () => {
      counts.stream++;
      return Readable.from(['a', 'b']);
    });

    await run(g.parallel('callback', 'promise', 'stream', g.series('callback', 'promise', 'stream')));

    expect(counts).toEqual({ callback: 1, promise: 1, stream: 1 });
  });

  test('should report a failure to every reference and execute the task again in the next run', async () => {
    const g = createGulp();
    let count = 0;
    g.task('fail', (done) => {
      count++;
      setTimeout(() => done(new Error('boom')), 10);
    });
    const failures = [];
    g.on('error', (e) => {
      if (e.name === 'fail') {
        failures.push(e.error.message);
      }
    });

    await expect(run(g.parallel(g.series('fail'), g.series('fail')))).rejects.toThrow('boom');
    await delay(10);

    expect(count).toBe(1);
    expect(failures).toEqual(['boom', 'boom']);

    await expect(run(g.series('fail'))).rejects.toThrow('boom');

    expect(count).toBe(2);
  });

  test('should execute a task once per run', async () => {
    const g = createGulp();
    let count = 0;
    g.task('prepare', (done) => {
      count++;
      done();
    });

    await run(g.series('prepare', 'prepare'));
    await run(g.series('prepare', 'prepare'));

    expect(count).toBe(2);
  });

  test('should start a new run when reset while a task is executing', async () => {
    const g = new gulp.Gulp();
    const r = new RunOnceRegistry();
    g.registry(r);
    let count = 0;
    g.task('prepare', (done) => {
      count++;
      done();
    });
    let stopWatching;
    g.task('watch', (done) => {
      stopWatching = done;
    });
    function build(done) {
      g.series('prepare', 'prepare')(done);
    }

    const watching = run(g.series('watch'));
    await run(build);
    await run(build);

    expect(count).toBe(1);

    r.reset();
    await run(build);

    expect(count).toBe(2);

    stopWatching();
    await watching;
  });

  test('should not end a run while an unregistered function is executing', async () => {
    const g = createGulp();
    let count = 0;
    g.task('prepare', (done) => {
      count++;
      done();
    });
    function slow(done) {
      setTimeout(done, 20);
    }

    await run(g.series('prepare', slow, g.parallel('prepare', noop)));

    expect(count).toBe(1);
  });

  test('should execute tasks registered before the registry once', async () => {
    const g = new gulp.Gulp();
    let count = 0;
    g.task('prepare', (done) => {
      count++;
      done();
    });
    g.registry(new RunOnceRegistry());

    await run(g.series('prepare', 'prepare'));

    expect(count).toBe(1);
  });

  test('should preserve the tree of tasks registered before the registry', () => {
    const g = new gulp.Gulp();
    g.task('prepare', noop);
    g.task('build', g.series('prepare', noop));
    g.registry(new RunOnceRegistry());

    expect(g.tree().nodes).toEqual(['prepare', 'build']);
    expect(g.tree({ deep: true }).nodes[1].nodes[0].nodes.map((n) => n.label)).toEqual(['prepare', 'noop']);
  });

  test('should preserve the original task and its last run', async () => {
    const g = createGulp();
    function prepare(done) {
      done();
    }
    prepare.description = 'Prepares the build';
    g.task(prepare);

    expect(g.task('prepare').displayName).toBe('prepare');
    expect(g.task('prepare').unwrap()).toBe(prepare);
    expect(g.lastRun('prepare')).toBeUndefined();

    await run(g.series('prepare'));

    expect(g.lastRun('prepare')).toEqual(expect.any(Number));
  });

  test('should execute a task referenced by function once per reference', async () => {
    const g = createGulp();
    let count = 0;
    function prepare(done) {
      count++;
      done();
    }
    g.task(prepare);

    await run(g.series(prepare, prepare));

    expect(count).toBe(2);
  });
});
