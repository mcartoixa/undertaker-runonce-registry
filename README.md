# undertaker-runonce-registry

This is a hacky hack that allows to declare tasks dependencies in a logical way without having to sweat about
the calling chain to avoid the same task being called twice in a build, (almost) the same way you did with
[Makefile](https://www.gnu.org/software/make/manual/make.html), [Ant](https://ant.apache.org/),
[MSBuild](https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild), [Rake](https://ruby.github.io/rake/),
[Phing](https://www.phing.info/) or even [Gulp 3](https://github.com/gulpjs/gulp/issues/1392).

There is [no supported way to do this easily with gulp 4+](https://github.com/orgs/gulpjs/discussions/2566), hence the hack.
It relies on the [custom registry](https://gulpjs.com/docs/en/api/registry) API, but also on the (undocumented) events
gulp emits when tasks start and stop. Use with caution: I cannot guarantee support, and it may break gulp in the future.

## Usage

[Plug this new registry](https://gulpjs.com/docs/en/api/registry) before declaring your tasks. Then every task that is:
 * [registered as a gulp task](https://gulpjs.com/docs/en/api/task) (or exported from your gulpfile),
 * referenced with its string name,

is executed only once per run, however many times it is referenced.

```js
import { parallel, registry, series, task } from 'gulp';
import RunOnceRegistry from 'undertaker-runonce-registry';

registry(new RunOnceRegistry());

function prepare(done) {
    console.log('prepare()');
    done();
}
task(prepare);

function doX(done) {
    done();
}

function doY(done) {
    done();
}

function doZ(done) {
    done();
}

task('build1', series('prepare', parallel(doX, doY)));
export const build2 = series('prepare', parallel('build1', doZ)); // prepare is executed only once
```

A run ends when no task is executing anymore. A task that failed is executed again in the next run.

### Watch

The task that calls [`watch`](https://gulpjs.com/docs/en/api/watch) is still executing as long as it does not signal
its completion, and so is the run: every build triggered by a change would then skip the tasks that were already executed.
Either signal completion as soon as the watcher is set up:

```js
export function dev(done) {
    watch('src/**', series('prepare', 'build1'));
    done();
}
```

or start a new run explicitly at the beginning of every build:

```js
const runOnce = new RunOnceRegistry();
registry(runOnce);

function newRun(done) {
    runOnce.reset();
    done();
}

export const dev = series('build1', () => watch('src/**', series(newRun, 'prepare', 'build1')));
```

## Limitations

 * A task referenced as a function (e.g. `series(prepare)`) is not handled by the registry, and is executed every time.
 * Runs that overlap (e.g. 2 watchers triggered at the same time) count as a single run.
