# undertaker-runonce-registry

This is a hacky hack that allows to declare tasks dependencies in a logical way without having to sweat about
the calling chain to avoid the same task being called twice in a build, (almost) the same way you did with
[Makefile](https://www.gnu.org/software/make/manual/make.html), [Ant](https://ant.apache.org/),
[MSBuild](https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild), [Rake](https://ruby.github.io/rake/),
[Phing](https://www.phing.info/) or even [Gulp 3](https://github.com/gulpjs/gulp/issues/1392).

There is [no supported way to do this easily with gulp 4+](https://github.com/orgs/gulpjs/discussions/2566) and
no entry point to add this functionality in a smooth way, hence the hack. Use with caution: I cannot guarantee support,
and it may break gulp in the future.

## Usage

You have to [plug this new registry](https://gulpjs.com/docs/en/api/registry). Then the dependencies that should be executed only once should be:
 * [registered as gulp tasks](https://gulpjs.com/docs/en/api/task) with a specific method on this registry (`instance.task`) with an additional `true` parameter.
 * referenced with their string name.

```js
import { registry, series, task } from 'gulp';
import RunOnceRegistry from 'undertaker-runonce-registry';

const ro = new RunOnceRegistry();
registry(ro);

function prepare(done) {
    console.log('prepare()');
    done();
}
ro.instance.task(prepare, true);

function doX(done) {
    done();
}

function doY(done) {
    done();
}

function doZ(done) {
    done();
}

export const build1 = series('prepare', parallel(doX, doY));
export const build2 = series('prepare', parallel(build1, doZ)); // prepare should be only executed once
```
