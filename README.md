# safexec

A v1 command execution sandbox written in Zig, currently focused on timeout control, output capture, and safe process handling.

## Status

This project is **under development**.

Current version: **v1**

## Features

- Run a command with arguments
- Kill the process if it exceeds a timeout
- Capture stdout
- Capture stderr
- Show exit code / termination status

## What v1 is not

This is **not** yet a full OS-level sandbox.

Not implemented in v1:
- cgroup memory limits
- namespace isolation
- seccomp restrictions
- deep process sandboxing

## Installing Zig

Zig provides self-contained archives. The official setup is to download the right archive for your platform, extract it, and add Zig to your `PATH`. 0

### Linux (example)

For Linux x86_64:

```bash
cd ~
curl -LO https://ziglang.org/download/0.15.2/zig-x86_64-linux-0.15.2.tar.xz
tar xf zig-x86_64-linux-0.15.2.tar.xz
echo 'export PATH="$HOME/zig-x86_64-linux-0.15.2:$PATH"' >> ~/.bashrc
source ~/.bashrc
zig version
```

For Linux aarch64:

```
cd ~
curl -LO https://ziglang.org/download/0.15.2/zig-aarch64-linux-0.15.2.tar.xz
tar xf zig-aarch64-linux-0.15.2.tar.xz
echo 'export PATH="$HOME/zig-aarch64-linux-0.15.2:$PATH"' >> ~/.bashrc
source ~/.bashrc
zig version
```

If extraction fails because .xz is not supported, install xz support first:

```
sudo apt update && sudo apt install -y xz-utils
```

## Installation

```
git clone https://github.com/ExVoider/safexec.git
cd safexec
```

## Build 

```
zig build
```

## Usage

```
zig build run -- 3 ls -la
zig build run -- 2 sleep 5
zig build run -- 3 sh -c "echo out && echo err 1>&2"
```

### Example Output

```
Command: sleep 5
Status: timed out after 2s
Terminated by signal: 9

--- stdout ---

--- stderr ---
```
