import { parallel, src, series, task } from 'gulp';
import { deleteAsync } from 'del';
import eslint from 'gulp-eslint-new';
import { run as jestRun } from 'jest-cli';



function doAnalyze() {
  return src(['**/*.js', '!node_modules/**'])
    .pipe(eslint())
    .pipe(eslint.format())
    .pipe(eslint.failAfterError());
}

function doClean() {
  return deleteAsync(['./tmp/**']);
}

function doNothing(done) {
  done();
}

function doTest() {
  return jestRun([]);
}



task('analyze', doAnalyze);
task('clean', doClean);
task('compile', doNothing);
task('package', doNothing);
task('prepare', doNothing);
task('test', doTest);

export const build = parallel('analyze', 'compile', 'test');
export const rebuild = series('clean', build);
export const release = series(rebuild, 'package');
export default series(build);
