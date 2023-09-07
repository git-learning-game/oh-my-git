class Mutex {
    constructor() {
        this._queue = [] // Queue of pending tasks
        this._locked = false // Mutex state
    }

    lock() {
        if (this._locked) {
            // If locked, return a promise that resolves when the mutex is unlocked
            return new Promise((resolve) => this._queue.push(resolve))
        } else {
            // If not locked, set it to locked and return a resolved promise
            this._locked = true
            return Promise.resolve()
        }
    }

    unlock() {
        if (this._queue.length > 0) {
            // If there are tasks waiting in the queue, pop the first task and resolve its promise
            const nextTask = this._queue.shift()
            nextTask()
        } else {
            // If no tasks in the queue, just unlock the mutex
            this._locked = false
        }
    }
}
const mutex = new Mutex()

var emulator

// Whether or not to restore the VM state from a file. Set to false to perform a regular boot.
let restoreState = true

function testy(cmd) {
    return new Promise((resolve, reject) => {
        setTimeout(() => {
            resolve("testy!!" + cmd)
        }, 100)
    })
}
window["testy"] = testy

// Run a command via the serial port (/dev/ttyS0) and return the output.
function run(cmd) {
    return new Promise((resolve, reject) => {
        mutex.lock().then(() => {
            emulator.serial0_send(cmd + "\n")

            var output = ""
            var listener = (char) => {
                if (char !== "\r") {
                    output += char
                }

                if (output.endsWith("# ")) {
                    emulator.remove_listener("serial0-output-char", listener)
                    let outputWithoutPrompt = output.slice(0, -3)
                    let outputWithoutFirstLine = outputWithoutPrompt.slice(
                        outputWithoutPrompt.indexOf("\n") + 1
                    )
                    if (outputWithoutFirstLine.endsWith("\n")) {
                        outputWithoutFirstLine = outputWithoutFirstLine.slice(
                            0,
                            -1
                        )
                    }
                    emulator.remove_listener("serial0-output-char", listener)
                    mutex.unlock()
                    resolve(outputWithoutFirstLine)
                }
            }
            emulator.add_listener("serial0-output-char", listener)
        })
    })
}
window["run"] = run
window["web_shell"] = {run, testy}

/*

// Run a test command and return true if the exit code is 0, false otherwise.
async function test(condition) {
    let result = await run(`test ${condition} && echo 'yes' || echo 'no'`)
    return result == "yes"
}

*/

// Set emulator config.
let config = {
    wasm_path: "/web-shell/lib/v86.wasm",
    memory_size: 64 * 1024 * 1024,
    vga_memory_size: 2 * 1024 * 1024,
    screen_container: document.getElementById("screen_container"),
    bios: {url: "/web-shell/images/seabios.bin"},
    vga_bios: {url: "/web-shell/images/vgabios.bin"},
    cdrom: {url: "/web-shell/images/image.iso.zst"},
    disable_mouse: true,
    autostart: true,
}
if (restoreState) {
    config["initial_state"] = {
        url: "/web-shell/images/booted-state.bin.zst",
    }
}

function boot() {
    return new Promise((resolve, reject) => {
        // Start the emulator!
        emulator = window["emulator"] = new V86Starter(config)

        // Wait for the emulator to start, then resolve the promise.
        var interval = setInterval(() => {
            if (emulator.is_running()) {
                run("PS1='#  '")
                clearInterval(interval)
                resolve(true)
            }
        }, 100)
    })
}

/*

// Allow saving and restoring the state using the buttons below the console.
var state
document.getElementById("save_restore").onclick = async function () {
    var button = this

    if (state) {
        button.value = "Save state"
        await emulator.restore_state(state)
        state = undefined
    } else {
        const new_state = await emulator.save_state()
        console.log("Saved state of " + new_state.byteLength + " bytes")
        button.value = "Restore state"
        state = new_state
    }

    button.blur()
}
document.getElementById("save_file").onclick = async function () {
    const new_state = await emulator.save_state()
    var a = document.createElement("a")
    a.download = "v86state.bin"
    a.href = window.URL.createObjectURL(new Blob([new_state]))
    a.dataset.downloadurl =
        "application/octet-stream:" + a.download + ":" + a.href
    a.click()

    this.blur()
}
document.getElementById("restore_file").onchange = function () {
    if (this.files.length) {
        var filereader = new FileReader()
        emulator.stop()

        filereader.onload = async function (e) {
            await emulator.restore_state(e.target.result)
            emulator.run()
        }

        filereader.readAsArrayBuffer(this.files[0])

        this.value = ""
    }

    this.blur()
}

*/
