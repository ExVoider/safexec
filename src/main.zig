const std = @import("std");

fn printUsage() void {
    std.debug.print(
        \\Usage:
        \\  safexec <timeout_seconds> <command> [args...]
        \\
        \\Example:
        \\  safexec 3 ls -la
        \\
    , .{});
}

fn readAllFromPipe(
    allocator: std.mem.Allocator,
    reader: anytype,
    max_output: usize,
) []u8 {
    return reader.readAllAlloc(allocator, max_output) catch allocator.dupe(u8, "Failed to capture output\n") catch unreachable;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 3) {
        printUsage();
        return;
    }

    const timeout_seconds = std.fmt.parseInt(u64, args[1], 10) catch {
        std.debug.print("Invalid timeout: {s}\n", .{args[1]});
        return;
    };

    const child_args = args[2..];

    var child = std.process.Child.init(child_args, allocator);
    child.stdin_behavior = .Ignore;
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    try child.spawn();

    const stdout_pipe = child.stdout.?;
    const stderr_pipe = child.stderr.?;

    var stdout_reader = stdout_pipe.reader();
    var stderr_reader = stderr_pipe.reader();

    const max_output = 1024 * 1024;

    const stdout_thread = try std.Thread.spawn(.{}, readAllFromPipe, .{ allocator, &stdout_reader, max_output });
    const stderr_thread = try std.Thread.spawn(.{}, readAllFromPipe, .{ allocator, &stderr_reader, max_output });

    const start_ms = std.time.milliTimestamp();
    const timeout_ms: i64 = @as(i64, @intCast(timeout_seconds)) * 1000;

    var timed_out = false;

    while (true) {
        const result = child.tryWait() catch |err| {
            std.debug.print("Failed while waiting for child: {}\n", .{err});
            return;
        };

        if (result != null) {
            break;
        }

        const elapsed = std.time.milliTimestamp() - start_ms;
        if (elapsed >= timeout_ms) {
            timed_out = true;
            _ = child.kill() catch {};
            break;
        }

        std.time.sleep(50 * std.time.ns_per_ms);
    }

    const stdout_result = stdout_thread.join();
    const stderr_result = stderr_thread.join();

    defer allocator.free(stdout_result);
    defer allocator.free(stderr_result);

    const final_term = try child.wait();

    std.debug.print("Command: ", .{});
    for (child_args, 0..) |arg, i| {
        if (i > 0) std.debug.print(" ", .{});
        std.debug.print("{s}", .{arg});
    }
    std.debug.print("\n", .{});

    if (timed_out) {
        std.debug.print("Status: timed out after {d}s\n", .{timeout_seconds});
    } else {
        std.debug.print("Status: completed\n", .{});
    }

    switch (final_term) {
        .Exited => |code| std.debug.print("Exit code: {d}\n", .{code}),
        .Signal => |sig| std.debug.print("Terminated by signal: {d}\n", .{sig}),
        .Stopped => |sig| std.debug.print("Stopped by signal: {d}\n", .{sig}),
        .Unknown => |code| std.debug.print("Unknown termination: {d}\n", .{code}),
    }

    std.debug.print("\n--- stdout ---\n{s}\n", .{stdout_result});
    std.debug.print("\n--- stderr ---\n{s}\n", .{stderr_result});
}
