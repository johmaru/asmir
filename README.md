# asm parser library

## depend on nasm

```zig  

    // Example usage

    // use arena allocator to allocate memory
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // allways require a init and defer deinit function if you forget this you will have a memory leak
    var asm1 = asm_test.asmCore.asm_struct.init(allocator);
    defer asm1.deinit();
    var data1 = asm_test.asmCore.data.init(allocator);
    defer data1.deinit();

    // owns_data_name and owns_message is false by default
    // also you can abbreviate the following code
    // if you assign not literal string you need to use true for owns_data_name or owns_message
    // data1.message = try allocator.dupe(u8, "Dynamic message");
    // data1.owns_message = true;
    data1.data_name = "test";
    data1.owns_data_name = false;
    data1.message = "Hello, World!";
    data1.owns_message = false;
    asm1.instruction = asm_test.asmCore.instruction.mov;
    asm1.reg = asm_test.asmCore.register.rax;
    asm1.value = 1;

    var asm2 = asm_test.asmCore.asm_struct.init(allocator);
    defer asm2.deinit();
    asm2.instruction = asm_test.asmCore.instruction.mov;
    asm2.reg = asm_test.asmCore.register.rdi;
    asm2.value = 1;

    // linkNext is a function that will link the next asm_struct to the current asm_struct
    asm1.linkNext(&asm2);

    var asm3 = asm_test.asmCore.asm_struct.init(allocator);
    defer asm3.deinit();
    asm3.instruction = asm_test.asmCore.instruction.mov;
    asm3.reg = asm_test.asmCore.register.rsi;
    asm3.msg = data1.data_name;
    asm2.linkNext(&asm3);

    var asm4 = asm_test.asmCore.asm_struct.init(allocator);
    defer asm4.deinit();
    asm4.instruction = asm_test.asmCore.instruction.mov;
    asm4.reg = asm_test.asmCore.register.rdx;
    const length_str = try data1.getLength();
    asm4.msg = length_str;
    asm3.linkNext(&asm4);

    var asm5 = asm_test.asmCore.asm_struct.init(allocator);
    defer asm5.deinit();
    asm5.instruction = asm_test.asmCore.instruction.syscall;
    asm4.linkNext(&asm5);

    // build the asmir.asm file
    try asm_test.asmCore.asm_build(&asm1, &data1, true);
```