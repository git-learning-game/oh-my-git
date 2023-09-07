export class Mutex {
    private mutex = Promise.resolve()

    lock(): PromiseLike<() => void> {
        let begin: (unlock: () => void) => void = (unlock) => {}

        this.mutex = this.mutex.then(() => {
            return new Promise(begin)
        })

        return new Promise((res) => {
            begin = res
        })
    }

    async dispatch(fn) {
        const unlock = await this.lock()
        try {
            return await Promise.resolve(fn())
        } finally {
            unlock()
        }
    }
}
