#import "ViewController.h"
#import <mach/mach.h>

static mach_port_t tfp0 = MACH_PORT_NULL;

static void init_kfd() {
    task_for_pid(mach_task_self(), 0, &tfp0);
}

static uint64_t read64(uint64_t addr) {
    if (tfp0 == MACH_PORT_NULL) return 0;
    uint64_t v = 0;
    mach_vm_read_overwrite(tfp0, addr, 8, (mach_vm_address_t)&v, NULL);
    return v;
}

static void write32(uint64_t addr, uint32_t v) {
    if (tfp0 == MACH_PORT_NULL) return;
    mach_vm_write(tfp0, addr, (mach_vm_address_t)&v, 4);
}

static void write_float(uint64_t addr, float v) {
    uint32_t val = *(uint32_t*)&v;
    write32(addr, val);
}

@interface ViewController ()
@property (nonatomic, strong) UIButton *btnLoop;
@property (nonatomic, strong) UIButton *btn2048;
@property (nonatomic, strong) UILabel *status;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) BOOL isLooping;
@property (nonatomic, assign) uint64_t targetAddr;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    init_kfd();
    [self setupUI];
}

- (void)setupUI {
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 60, 340, 40)];
    title.text = @"Q2848456330";
    title.textColor = [UIColor cyanColor];
    title.font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:22];
    title.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:title];

    self.status = [[UILabel alloc] initWithFrame:CGRectMake(20, 110, 340, 30)];
    self.status.text = @"状态: 就绪";
    self.status.textColor = [UIColor greenColor];
    self.status.font = [UIFont fontWithName:@"CourierNewPSMT" size:14];
    self.status.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.status];

    self.btnLoop = [UIButton buttonWithType:UIButtonTypeSystem];
    self.btnLoop.frame = CGRectMake(20, 160, 340, 50);
    [self.btnLoop setTitle:@"[>] 蔡徐坤" forState:UIControlStateNormal];
    [self.btnLoop setTitleColor:[UIColor cyanColor] forState:UIControlStateNormal];
    self.btnLoop.titleLabel.font = [UIFont fontWithName:@"CourierNewPSMT" size:16];
    self.btnLoop.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1];
    self.btnLoop.layer.borderColor = [UIColor cyanColor].CGColor;
    self.btnLoop.layer.borderWidth = 1;
    self.btnLoop.layer.cornerRadius = 12;
    [self.btnLoop addTarget:self action:@selector(toggleLoop) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.btnLoop];

    self.btn2048 = [UIButton buttonWithType:UIButtonTypeSystem];
    self.btn2048.frame = CGRectMake(20, 220, 340, 50);
    [self.btn2048 setTitle:@"[>] 2048" forState:UIControlStateNormal];
    [self.btn2048 setTitleColor:[UIColor colorWithRed:0.4 green:1 blue:0.7 alpha:1] forState:UIControlStateNormal];
    self.btn2048.titleLabel.font = [UIFont fontWithName:@"CourierNewPSMT" size:16];
    self.btn2048.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1];
    self.btn2048.layer.borderColor = [UIColor colorWithRed:0.4 green:1 blue:0.7 alpha:1].CGColor;
    self.btn2048.layer.borderWidth = 1;
    self.btn2048.layer.cornerRadius = 12;
    [self.btn2048 addTarget:self action:@selector(action2048) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.btn2048];

    UILabel *footer = [[UILabel alloc] initWithFrame:CGRectMake(20, 300, 340, 20)];
    footer.text = @"[ KFD ]  [ CF ]";
    footer.textColor = [UIColor colorWithWhite:0.3 alpha:0.6];
    footer.font = [UIFont fontWithName:@"CourierNewPSMT" size:10];
    footer.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:footer];
}

- (void)toggleLoop {
    if (self.isLooping) {
        [self.timer invalidate];
        self.timer = nil;
        self.isLooping = NO;
        [self.btnLoop setTitle:@"[>] 蔡徐坤" forState:UIControlStateNormal];
        self.status.text = @"已停止";
        self.status.textColor = [UIColor orangeColor];
        return;
    }

    uint64_t addr = 0x100000000 + 0xC004BD0; // cf基址示例
    addr = read64(addr) + 0xA0;
    addr = read64(addr) + 0x1B0;
    addr = read64(addr) + 0x220;

    if (addr == 0) {
        self.status.text = @"指针断裂";
        self.status.textColor = [UIColor redColor];
        return;
    }

    self.targetAddr = addr;
    self.isLooping = YES;
    [self.btnLoop setTitle:@"[!] 停止" forState:UIControlStateNormal];
    self.status.text = @"循环中 (F32 20)";
    self.status.textColor = [UIColor cyanColor];

    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01 repeats:YES block:^(NSTimer * _Nonnull t) {
        if (self.targetAddr != 0) write_float(self.targetAddr, 20.0);
    }];
}

- (void)action2048 {
    uint64_t addr = 0x100000000 + 0xBFFC488;
    addr = read64(addr) + 0xA0;
    addr = read64(addr) + 0x190;
    addr = read64(addr) + 0x30;
    addr = read64(addr) + 0x444;

    if (addr == 0) {
        self.status.text = @"指针断裂";
        self.status.textColor = [UIColor redColor];
        return;
    }

    write32(addr, 108800);
    self.status.text = @"2048 写入成功!";
    self.status.textColor = [UIColor greenColor];
}

@end
