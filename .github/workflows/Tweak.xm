#import <UIKit/UIKit.h>
#import <mach/mach.h>
#import <mach/vm_map.h>
#import <sys/sysctl.h>

static mach_port_t tfp0 = MACH_PORT_NULL;

static mach_port_t get_tfp0() {
    if (tfp0 != MACH_PORT_NULL) return tfp0;
    task_for_pid(mach_task_self(), 0, &tfp0);
    return tfp0;
}

static uint64_t kread64(uint64_t addr) {
    mach_port_t port = get_tfp0();
    if (port == MACH_PORT_NULL) return 0;
    uint64_t v = 0;
    vm_read_overwrite(port, addr, 8, (vm_address_t)&v, NULL);
    return v;
}

static void kwrite32(uint64_t addr, uint32_t v) {
    mach_port_t port = get_tfp0();
    if (port == MACH_PORT_NULL) return;
    vm_write(port, addr, (vm_address_t)&v, 4);
}

static void kwrite_float(uint64_t addr, float v) {
    uint32_t val = *(uint32_t*)&v;
    kwrite32(addr, val);
}

static uint64_t get_cf_base() {
    int pid = 0;
    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    size_t size = 0;
    sysctl(mib, 3, NULL, &size, NULL, 0);
    struct kinfo_proc *procs = malloc(size);
    if (!procs) return 0;
    sysctl(mib, 3, procs, &size, NULL, 0);
    for (int i = 0; i < size / sizeof(struct kinfo_proc); i++) {
        if (strcmp(procs[i].kp_proc.p_comm, "cf") == 0) {
            pid = procs[i].kp_proc.p_pid;
            break;
        }
    }
    free(procs);
    if (pid == 0) return 0;

    task_t task;
    kern_return_t kr = task_for_pid(mach_task_self(), pid, &task);
    if (kr != KERN_SUCCESS || task == MACH_PORT_NULL) return 0;

    struct vm_region_submap_info_64 info;
    mach_msg_type_number_t count = VM_REGION_SUBMAP_INFO_COUNT_64;
    vm_address_t addr = 0;
    vm_size_t size2 = 0;
    natural_t depth = 0;

    while (1) {
        kr = vm_region_recurse_64(task, &addr, &size2, &depth, (vm_region_info_64_t)&info, &count);
        if (kr != KERN_SUCCESS) break;
        if (info.is_submap) { depth++; continue; }
        if (info.protection & VM_PROT_READ && info.protection & VM_PROT_EXECUTE) {
            return (uint64_t)addr;
        }
        addr += size2;
    }
    return 0;
}

static void *aim_loop(void *arg) {
    uint64_t base = get_cf_base();
    if (base == 0) {
        NSLog(@"AimAssist: 未找到 cf 进程");
        return NULL;
    }

    uint64_t addr = base + 0xABCCE80;
    addr = kread64(addr) + 0x640;
    addr = kread64(addr) + 0xA0;
    addr = kread64(addr) + 0x6D4;

    if (addr == 0) {
        NSLog(@"AimAssist: 指针链断裂");
        return NULL;
    }

    while (1) {
        float current = 0;
        vm_read_overwrite(tfp0, addr, 4, (vm_address_t)&current, NULL);
        float target = 3.0;
        float threshold = 0.5;
        if (fabs(current - target) > threshold) {
            kwrite_float(addr, target);
        }
        if (arc4random() % 10 < 2) {
            uint64_t dummy = base + 0x1000 + (arc4random() % 0xFFF);
            uint32_t val;
            vm_read_overwrite(tfp0, dummy, 4, (vm_address_t)&val, NULL);
        }
        usleep(50000 + arc4random() % 250000);
    }
    return NULL;
}

%ctor {
    pthread_t thread;
    pthread_create(&thread, NULL, aim_loop, NULL);
    pthread_detach(thread);
    NSLog(@"AimAssist: 插件加载成功");
}
