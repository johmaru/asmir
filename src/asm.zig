const std = @import("std");

pub const asmCore = struct {
    pub const register = struct {
        pub const eax = 0;
        pub const ecx = 1;
        pub const edx = 2;
        pub const ebx = 3;
        pub const esp = 4;
        pub const ebp = 5;
        pub const esi = 6;
        pub const edi = 7;
        pub const ax = 8;
        pub const cx = 9;
        pub const dx = 10;
        pub const bx = 11;
        pub const sp = 12;
        pub const bp = 13;
        pub const si = 14;
        pub const di = 15;
        pub const al = 16;
        pub const cl = 17;
        pub const dl = 18;
        pub const bl = 19;
        pub const ah = 20;
        pub const ch = 21;
        pub const dh = 22;
        pub const bh = 23;
        pub const spl = 24;
        pub const bpl = 25;
        pub const sil = 26;
        pub const dil = 27;
        pub const r8b = 28;
        pub const r9b = 29;
        pub const r10b = 30;
        pub const r11b = 31;
        pub const r12b = 32;
        pub const r13b = 33;
        pub const r14b = 34;
        pub const r15b = 35;
        pub const rax = 36;
        pub const rcx = 37;
        pub const rdx = 38;
        pub const rbx = 39;
        pub const rsp = 40;
        pub const rbp = 41;
        pub const rsi = 42;
        pub const rdi = 43;
        pub const r8 = 44;
        pub const r9 = 45;
        pub const r10 = 46;
        pub const r11 = 47;
        pub const r12 = 48;
        pub const r13 = 49;
        pub const r14 = 50;
        pub const r15 = 51;
        pub const eip = 52;
    };

    pub const instruction = struct {
        pub const mov = 0;
        pub const add = 1;
        pub const sub = 2;
        pub const mul = 3;
        pub const div = 4;
        pub const inc = 5;
        pub const dec = 6;
        pub const cmp = 7;
        pub const jmp = 8;
        pub const je = 9;
        pub const jne = 10;
        pub const jl = 11;
        pub const jle = 12;
        pub const jg = 13;
        pub const jge = 14;
        pub const call = 15;
        pub const ret = 16;
        pub const push = 17;
        pub const pop = 18;
        pub const leave = 19;
        pub const nop = 20;
        pub const syscall = 21;
    };

    pub const syscall_numberr = struct {
        pub const read = 0;
        pub const write = 1;
        pub const open = 2;
        pub const close = 3;
        pub const stat = 4;
        pub const fstat = 5;
        pub const lstat = 6;
        pub const poll = 7;
        pub const lseek = 8;
        pub const mmap = 9;
        pub const mprotect = 10;
        pub const munmap = 11;
        pub const brk = 12;
        pub const rt_sigaction = 13;
        pub const rt_sigprocmask = 14;
        pub const fork = 57;
        pub const execve = 59;
        pub const exit = 60;
        pub const wait4 = 61;
        pub const kill = 62;
    };

    pub const data = struct {
        message: ?[]const u8,
        data_name: ?[]const u8,
        allocator: std.mem.Allocator,
        owns_message: bool = false,
        owns_data_name: bool = false,
        next: ?*@This() = null,

        pub fn init(allocator: std.mem.Allocator) @This() {
            return .{
                .allocator = allocator,
                .message = "",
                .data_name = "",
                .next = null,
                .owns_message = false,
                .owns_data_name = false,
            };
        }

        pub fn toAllocPrint(self: @This(), arena_allocator: std.mem.Allocator) ![]const u8 {
            return std.fmt.allocPrint(arena_allocator, "   {?s}: db \"{?s}\", 0xa\n   {?s}_length: equ $ - {?s}\n", .{
                self.data_name,
                self.message,
                self.data_name,
                self.data_name,
            });
        }

        pub fn getLength(self: @This()) ![]const u8 {
            return std.fmt.allocPrint(self.allocator, "{?s}_length", .{self.data_name});
        }

        pub fn deinit(self: *@This()) void {
            if (self.data_name) |name| {
                if (self.owns_data_name) {
                    self.allocator.free(name);
                }
            }

            if (self.message) |msg| {
                if (self.owns_message) {
                    self.allocator.free(msg);
                }
            }

            if (self.next) |next| {
                next.deinit();
            }
        }

        pub fn getNext(self: *@This()) ?*@This() {
            return self.next;
        }

        pub fn linkNext(self: *@This(), next: *@This()) void {
            self.next = next;
        }
    };

    const registerSize = 4;

    const instructionSize = 1;

    pub const asm_struct = struct {
        allocator: std.mem.Allocator,
        adress_count: u32 = 0,
        instruction: u32 = 0,
        reg: u8 = 0,
        value: u32 = 0,
        msg: ?[]const u8 = "",
        owns_msg: bool = false,
        syscall_number: ?u32 = 0,
        next: ?*@This() = null,

        pub fn init(allocator: std.mem.Allocator) @This() {
            return .{
                .allocator = allocator,
                .adress_count = 0,
                .instruction = 0,
                .reg = 0,
                .value = 0,
                .msg = null,
                .syscall_number = null,
                .next = null,
                .owns_msg = false,
            };
        }

        pub fn deinit(self: *@This()) void {
            if (self.msg) |msg| {
                if (self.owns_msg) {
                    self.allocator.free(msg);
                }
            }
            if (self.next) |next| {
                next.deinit();
            }
        }

        pub fn toAsmString(self: *@This(), arena_allocator: std.mem.Allocator) ![]const u8 {
            switch (self.instruction) {
                asmCore.instruction.mov => {
                    if (self.value == 0 and self.msg == null) {
                        return error.MissingValue;
                    }
                    if (self.value != 0) {
                        return std.fmt.allocPrint(arena_allocator, "   mov {s}, {d}\n", .{
                            registerToString(self.reg),
                            self.value,
                        });
                    }
                    if (self.msg) |msg| {
                        return std.fmt.allocPrint(arena_allocator, "   mov {s}, {s}\n", .{
                            registerToString(self.reg),
                            msg,
                        });
                    }
                    unreachable;
                },
                asmCore.instruction.add => {
                    if (self.value == 0 and self.msg == null) {
                        return error.MissingValue;
                    }
                    if (self.value != 0) {
                        return std.fmt.allocPrint(arena_allocator, "add {s}, {d}\n", .{
                            registerToString(self.reg),
                            self.value,
                        });
                    }

                    if (self.msg) |msg| {
                        return std.fmt.allocPrint(arena_allocator, "add {s}, {s}\n", .{
                            registerToString(self.reg),
                            msg,
                        });
                    }
                    unreachable;
                },
                asmCore.instruction.sub => {
                    if (self.value == 0 and self.msg == null) {
                        return error.MissingValue;
                    }
                    if (self.value != 0) {
                        return std.fmt.allocPrint(arena_allocator, "sub {s}, {d}\n", .{
                            registerToString(self.reg),
                            self.value,
                        });
                    }

                    if (self.msg) |msg| {
                        return std.fmt.allocPrint(arena_allocator, "sub {s}, {s}\n", .{
                            registerToString(self.reg),
                            msg,
                        });
                    }
                    unreachable;
                },
                asmCore.instruction.mul => {
                    if (self.value == 0 and self.msg == null) {
                        return error.MissingValue;
                    }
                    if (self.value != 0) {
                        return std.fmt.allocPrint(arena_allocator, "mul {s}, {d}\n", .{
                            registerToString(self.reg),
                            self.value,
                        });
                    }

                    if (self.msg) |msg| {
                        return std.fmt.allocPrint(arena_allocator, "mul {s}, {s}\n", .{
                            registerToString(self.reg),
                            msg,
                        });
                    }
                },
                asmCore.instruction.div => {
                    if (self.value == 0 and self.msg == null) {
                        return error.MissingValue;
                    }
                    if (self.value != 0) {
                        return std.fmt.allocPrint(arena_allocator, "div {s}, {d}\n", .{
                            registerToString(self.reg),
                            self.value,
                        });
                    }

                    if (self.msg) |msg| {
                        return std.fmt.allocPrint(arena_allocator, "div {s}, {s}\n", .{
                            registerToString(self.reg),
                            msg,
                        });
                    }
                },
                asmCore.instruction.inc => {
                    return std.fmt.allocPrint(arena_allocator, "inc {s}\n", .{
                        registerToString(self.reg),
                    });
                },
                asmCore.instruction.dec => {
                    return std.fmt.allocPrint(arena_allocator, "dec {s}\n", .{
                        registerToString(self.reg),
                    });
                },
                asmCore.instruction.cmp => {
                    if (self.value == 0 and self.msg == null) {
                        return error.MissingValue;
                    }
                    if (self.value != 0) {
                        return std.fmt.allocPrint(arena_allocator, "cmp {s}, {d}\n", .{
                            registerToString(self.reg),
                            self.value,
                        });
                    }

                    if (self.msg) |msg| {
                        return std.fmt.allocPrint(arena_allocator, "cmp {s}, {s}\n", .{
                            registerToString(self.reg),
                            msg,
                        });
                    }
                },
                asmCore.instruction.jmp => {
                    if (self.value == 0 and self.msg == null) {
                        return error.MissingValue;
                    }
                    if (self.value != 0) {
                        return std.fmt.allocPrint(arena_allocator, "jmp {d}\n", .{
                            self.value,
                        });
                    }

                    if (self.msg) |msg| {
                        return std.fmt.allocPrint(arena_allocator, "jmp {s}\n", .{
                            msg,
                        });
                    }
                },
                asmCore.instruction.je => {
                    if (self.value == 0 and self.msg == null) {
                        return error.MissingValue;
                    }
                    if (self.value != 0) {
                        return std.fmt.allocPrint(arena_allocator, "je {d}\n", .{
                            self.value,
                        });
                    }

                    if (self.msg) |msg| {
                        return std.fmt.allocPrint(arena_allocator, "je {s}\n", .{
                            msg,
                        });
                    }
                },
                asmCore.instruction.jne => {
                    if (self.value == 0 and self.msg == null) {
                        return error.MissingValue;
                    }
                    if (self.value != 0) {
                        return std.fmt.allocPrint(arena_allocator, "jne {d}\n", .{
                            self.value,
                        });
                    }

                    if (self.msg) |msg| {
                        return std.fmt.allocPrint(arena_allocator, "jne {s}\n", .{
                            msg,
                        });
                    }
                },
                asmCore.instruction.jl => {
                    if (self.value == 0 and self.msg == null) {
                        return error.MissingValue;
                    }
                    if (self.value != 0) {
                        return std.fmt.allocPrint(arena_allocator, "jl {d}\n", .{
                            self.value,
                        });
                    }

                    if (self.msg) |msg| {
                        return std.fmt.allocPrint(arena_allocator, "jl {s}\n", .{
                            msg,
                        });
                    }
                },
                asmCore.instruction.jle => {
                    if (self.value == 0 and self.msg == null) {
                        return error.MissingValue;
                    }
                    if (self.value != 0) {
                        return std.fmt.allocPrint(arena_allocator, "jle {d}\n", .{
                            self.value,
                        });
                    }

                    if (self.msg) |msg| {
                        return std.fmt.allocPrint(arena_allocator, "jle {s}\n", .{
                            msg,
                        });
                    }
                },
                asmCore.instruction.jg => {
                    if (self.value == 0 and self.msg == null) {
                        return error.MissingValue;
                    }
                    if (self.value != 0) {
                        return std.fmt.allocPrint(arena_allocator, "jg {d}\n", .{
                            self.value,
                        });
                    }

                    if (self.msg) |msg| {
                        return std.fmt.allocPrint(arena_allocator, "jg {s}\n", .{
                            msg,
                        });
                    }
                },
                asmCore.instruction.jge => {
                    if (self.value == 0 and self.msg == null) {
                        return error.MissingValue;
                    }
                    if (self.value != 0) {
                        return std.fmt.allocPrint(arena_allocator, "jge {d}\n", .{
                            self.value,
                        });
                    }

                    if (self.msg) |msg| {
                        return std.fmt.allocPrint(arena_allocator, "jge {s}\n", .{
                            msg,
                        });
                    }
                },
                asmCore.instruction.call => {
                    if (self.value == 0 and self.msg == null) {
                        return error.MissingValue;
                    }
                    if (self.value != 0) {
                        return std.fmt.allocPrint(arena_allocator, "call {d}\n", .{
                            self.value,
                        });
                    }

                    if (self.msg) |msg| {
                        return std.fmt.allocPrint(arena_allocator, "call {s}\n", .{
                            msg,
                        });
                    }
                },
                asmCore.instruction.ret => {
                    if (self.msg) |msg| {
                        return std.fmt.allocPrint(arena_allocator, "ret {s}\n", .{
                            msg,
                        });
                    } else {
                        return std.fmt.allocPrint(arena_allocator, "ret\n", .{});
                    }
                },
                asmCore.instruction.push => {
                    if (self.msg) |msg| {
                        return std.fmt.allocPrint(arena_allocator, "push {s}\n", .{
                            msg,
                        });
                    } else {
                        return std.fmt.allocPrint(arena_allocator, "push {s}\n", .{
                            registerToString(self.reg),
                        });
                    }
                },
                asmCore.instruction.pop => {
                    if (self.msg) |msg| {
                        return std.fmt.allocPrint(arena_allocator, "pop {s}\n", .{
                            msg,
                        });
                    } else {
                        return std.fmt.allocPrint(arena_allocator, "pop {s}\n", .{
                            registerToString(self.reg),
                        });
                    }
                },
                asmCore.instruction.leave => {
                    if (self.msg) |msg| {
                        return std.fmt.allocPrint(arena_allocator, "leave {s}\n", .{
                            msg,
                        });
                    } else {
                        return std.fmt.allocPrint(arena_allocator, "leave\n", .{});
                    }
                },
                asmCore.instruction.nop => {
                    if (self.msg) |msg| {
                        return std.fmt.allocPrint(arena_allocator, "nop {s}\n", .{
                            msg,
                        });
                    } else {
                        return std.fmt.allocPrint(arena_allocator, "nop\n", .{});
                    }
                },
                asmCore.instruction.syscall => {
                    if (self.syscall_number) |num| {
                        return std.fmt.allocPrint(arena_allocator, "   syscall {d}\n", .{num});
                    } else {
                        return std.fmt.allocPrint(arena_allocator, "   syscall\n", .{});
                    }
                },

                else => return error.UnsupportedInstruction,
            }
            return error.UnsupportedInstruction;
        }

        fn registerToString(reg: u8) []const u8 {
            switch (reg) {
                asmCore.register.eax => return "eax",
                asmCore.register.ecx => return "ecx",
                asmCore.register.edx => return "edx",
                asmCore.register.ebx => return "ebx",
                asmCore.register.esp => return "esp",
                asmCore.register.ebp => return "ebp",
                asmCore.register.esi => return "esi",
                asmCore.register.edi => return "edi",
                asmCore.register.ax => return "ax",
                asmCore.register.cx => return "cx",
                asmCore.register.dx => return "dx",
                asmCore.register.bx => return "bx",
                asmCore.register.sp => return "sp",
                asmCore.register.bp => return "bp",
                asmCore.register.si => return "si",
                asmCore.register.di => return "di",
                asmCore.register.al => return "al",
                asmCore.register.cl => return "cl",
                asmCore.register.dl => return "dl",
                asmCore.register.bl => return "bl",
                asmCore.register.ah => return "ah",
                asmCore.register.ch => return "ch",
                asmCore.register.dh => return "dh",
                asmCore.register.bh => return "bh",
                asmCore.register.spl => return "spl",
                asmCore.register.bpl => return "bpl",
                asmCore.register.sil => return "sil",
                asmCore.register.dil => return "dil",
                asmCore.register.r8b => return "r8b",
                asmCore.register.r9b => return "r9b",
                asmCore.register.r10b => return "r10b",
                asmCore.register.r11b => return "r11b",
                asmCore.register.r12b => return "r12b",
                asmCore.register.r13b => return "r13b",
                asmCore.register.r14b => return "r14b",
                asmCore.register.r15b => return "r15b",
                asmCore.register.rax => return "rax",
                asmCore.register.rcx => return "rcx",
                asmCore.register.rdx => return "rdx",
                asmCore.register.rbx => return "rbx",
                asmCore.register.rsp => return "rsp",
                asmCore.register.rbp => return "rbp",
                asmCore.register.rsi => return "rsi",
                asmCore.register.rdi => return "rdi",
                asmCore.register.r8 => return "r8",
                asmCore.register.r9 => return "r9",
                asmCore.register.r10 => return "r10",
                asmCore.register.r11 => return "r11",
                asmCore.register.r12 => return "r12",
                asmCore.register.r13 => return "r13",
                asmCore.register.r14 => return "r14",
                asmCore.register.r15 => return "r15",
                asmCore.register.eip => return "eip",
                else => return "",
            }
        }

        pub fn getNext(self: *@This()) ?*@This() {
            return self.next;
        }

        pub fn linkNext(self: *@This(), next: *@This()) void {
            self.next = next;
        }
    };

    pub fn asm_build(first_instruction: *asm_struct, data_instruction: ?*data, stackframe: ?bool) !void {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        var asm_content = std.ArrayList(u8).init(allocator);

        if (data_instruction) |data_content| {
            try asm_content.appendSlice("section .data\n");
            var current: ?*data = data_content;
            while (current != null) {
                const data_str = try current.?.toAllocPrint(allocator);
                try asm_content.appendSlice(data_str);
                current = current.?.next;
            }
        }

        try asm_content.appendSlice("section .text\n   global _start\n_start:\n");

        if (stackframe.?) {
            try asm_content.appendSlice(
                \\   push rbp
                \\   mov rbp, rsp
                \\
            );
        }

        var current_inst: ?*asm_struct = first_instruction;
        while (current_inst != null) {
            const asm_str = try current_inst.?.toAsmString(allocator);
            try asm_content.appendSlice(asm_str);
            current_inst = current_inst.?.next;
        }

        if (stackframe.?) {
            try asm_content.appendSlice(
                \\   mov rsp, rbp
                \\   pop rbp
                \\
            );
        }

        try asm_content.appendSlice(
            \\   mov rax, 60
            \\   mov rdi, 0
            \\   syscall
            \\
        );

        const file = try std.fs.cwd().createFile("asmir.asm", .{});
        defer file.close();
        try file.writeAll(asm_content.items);
    }
};
