import lastRun from 'last-run';
import DefaultRegistry from 'undertaker-registry';

export default class RunOnceRegistry extends DefaultRegistry {

    init(taker) {
        this.#taker = taker;
        super.init(taker);

        taker.task = function(name, fn, runOnce) {
            if (typeof name === 'function') {
                runOnce = fn;
                fn = name;
                name = fn.displayName || fn.name;
            }

            if (!fn) {
                return taker._getTask(name);
            }

            let f = fn;
            if (runOnce) {
                f = function runner(done) {
                    if (!lastRun(f)) {
                        return fn.apply(this, arguments);
                    } else {
                        done();
                    }
                }
            }
            taker._setTask(name, f);
            return fn;
        }
   }

   get instance() {
    return this.#taker;
   }

   #taker;
}
