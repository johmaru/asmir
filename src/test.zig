//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

test "asm_test" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var asm1 = asm_test.asmCore.asm_struct.init(allocator);
    var data1 = asm_test.asmCore.data.init(allocator);
    data1.data_name = try allocator.dupe(u8, "test");
    data1.message = try allocator.dupe(u8, "Hello, World!");
    asm1.instruction = asm_test.asmCore.instruction.mov;
    asm1.reg = asm_test.asmCore.register.rax;
    asm1.value = 1;

    var asm2 = asm_test.asmCore.asm_struct.init(allocator);
    asm2.instruction = asm_test.asmCore.instruction.mov;
    asm2.reg = asm_test.asmCore.register.rdi;
    asm2.value = 1;
    asm1.linkNext(&asm2);

    var asm3 = asm_test.asmCore.asm_struct.init(allocator);
    asm3.instruction = asm_test.asmCore.instruction.mov;
    asm3.reg = asm_test.asmCore.register.rsi;
    asm3.msg = data1.data_name;
    asm2.linkNext(&asm3);

    var asm4 = asm_test.asmCore.asm_struct.init(allocator);
    asm4.instruction = asm_test.asmCore.instruction.mov;
    asm4.reg = asm_test.asmCore.register.rdx;
    const length_str = try data1.getLength();
    asm4.msg = length_str;
    asm3.linkNext(&asm4);

    var asm5 = asm_test.asmCore.asm_struct.init(allocator);
    asm5.instruction = asm_test.asmCore.instruction.syscall;
    asm4.linkNext(&asm5);

    try asm_test.asmCore.asm_build(&asm1, &data1, true);

    allocator.free(data1.data_name);
    allocator.free(data1.message);
    if (asm1.msg) |msg| allocator.free(msg);
    if (asm2.msg) |msg| allocator.free(msg);

    if (asm4.msg) |msg| allocator.free(msg);
    if (asm5.msg) |msg| allocator.free(msg);
}

const std = @import("std");
const asm_test = @import("asm.zig");
