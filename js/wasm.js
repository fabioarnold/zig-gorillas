var memory;

const readString = (ptr, len) => {
    const array = new Uint8Array(memory.buffer, ptr, len)
    const decoder = new TextDecoder()
    return decoder.decode(array)
}

const consoleLog = (ptr, len) => {
    console.log(readString(ptr, len));
}

var wasm = {
    consoleLog,
    readString,
}