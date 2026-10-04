import asyncDone from 'async-done';
import DefaultRegistry from 'undertaker-registry';

/**
 * Registry that executes each task at most once per run, however many times it is referenced by name.
 * A run ends when no task is executing anymore, or when reset() is called.
 */
export default class RunOnceRegistry extends DefaultRegistry {

  init(taker) {
    super.init(taker);

    // Tasks copied from the previous registry were set without undertaker's metadata (used by tree() and gulp --tasks)
    for (const [name, task] of Object.entries(this.tasks())) {
      taker.task(name, task.unwrap());
    }

    taker.on('start', () => this.#executing++);
    taker.on('stop', () => this.#onExecutionEnd());
    taker.on('error', () => this.#onExecutionEnd());
  }

  set(name, fn) {
    const runs = this.#runs;
    runs.delete(name);

    function runOnce(done) {
      let run = runs.get(name);
      if (!run) {
        run = new Promise((resolve, reject) => {
          asyncDone(fn.bind(this), (err, result) => (err ? reject(err) : resolve(result)));
        });
        runs.set(name, run);
      }
      run.then((result) => done(null, result), done);
    }
    runOnce.displayName = name;
    // Allows gulp-cli to find the description and flags of the original task
    runOnce.unwrap = fn.unwrap;

    return super.set(name, runOnce);
  }

  /**
   * Starts a new run: every task will be executed again when next referenced.
   */
  reset() {
    this.#runs.clear();
  }

  #onExecutionEnd() {
    this.#executing--;
    if (this.#executing === 0) {
      // The next step of a series starts synchronously after the previous one ends:
      // the run is only over if nothing has started in the meantime.
      queueMicrotask(() => {
        if (this.#executing === 0) {
          this.reset();
        }
      });
    }
  }

  #executing = 0;
  #runs = new Map();
}
