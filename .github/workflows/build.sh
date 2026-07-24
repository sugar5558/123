#!/bin/bash

echo "📦 开始构建..."

mkdir -p Payload/KFD_CF_Mod.app

cat > Payload/KFD_CF_Mod.app/Info.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>KFD_CF_Mod</string>
    <key>CFBundleIdentifier</key>
    <string>com.kfd.cfmod</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>KFD_CF_Mod</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
</dict>
</plist>
EOF

clang -o Payload/KFD_CF_Mod.app/KFD_CF_Mod \
    -framework UIKit \
    -framework Foundation \
    -framework MachO \
    -ObjC \
    -x objective-c \
    -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
    -target arm64-apple-ios15.0 \
    -fobjc-arc \
    <<'EOF'
#import <UIKit/UIKit.h>
#import <mach/mach.h>

static mach_port_t tfp0 = MACH_PORT_NULL;

__attribute__((constructor)) static void init_kfd() {
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

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor blackColor];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 60, 340, 40)];
    title.text = @"Q2848456330";
    title.textColor = [UIColor cyanColor];
    title.font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:22];
    title.textAlignment = NSTextAlignmentCenter;
    [vc.view addSubview:title];
    
    UILabel *status = [[UILabel alloc] initWithFrame:CGRectMake(20, 110, 340, 30)];
    status.text = @"状态: 就绪";
    status.textColor = [UIColor greenColor];
    status.font = [UIFont fontWithName:@"CourierNewPSMT" size:14];
    status.textAlignment = NSTextAlignmentCenter;
    [vc.view addSubview:status];
    
    UIButton *btnLoop = [UIButton buttonWithType:UIButtonTypeSystem];
    btnLoop.frame = CGRectMake(20, 160, 340, 50);
    [btnLoop setTitle:@"[>] 蔡徐坤" forState:UIControlStateNormal];
    [btnLoop setTitleColor:[UIColor cyanColor] forState:UIControlStateNormal];
    btnLoop.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1];
    btnLoop.layer.borderColor = [UIColor cyanColor].CGColor;
    btnLoop.layer.borderWidth = 1;
    btnLoop.layer.cornerRadius = 12;
    btnLoop.tag = 100;
    [btnLoop addTarget:self action:@selector(btnLoopTap:) forControlEvents:UIControlEventTouchUpInside];
    [vc.view addSubview:btnLoop];
    
    UIButton *btn2048 = [UIButton buttonWithType:UIButtonTypeSystem];
    btn2048.frame = CGRectMake(20, 220, 340, 50);
    [btn2048 setTitle:@"[>] 2048" forState:UIControlStateNormal];
    [btn2048 setTitleColor:[UIColor colorWithRed:0.4 green:1 blue:0.7 alpha:1] forState:UIControlStateNormal];
    btn2048.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1];
    btn2048.layer.borderColor = [UIColor colorWithRed:0.4 green:1 blue:0.7 alpha:1].CGColor;
    btn2048.layer.borderWidth = 1;
    btn2048.layer.cornerRadius = 12;
    btn2048.tag = 200;
    [btn2048 addTarget:self action:@selector(btn2048Tap:) forControlEvents:UIControlEventTouchUpInside];
    [vc.view addSubview:btn2048];
    
    UILabel *footer = [[UILabel alloc] initWithFrame:CGRectMake(20, 300, 340, 20)];
    footer.text = @"[ KFD ]  [ CF ]";
    footer.textColor = [UIColor colorWithWhite:0.3 alpha:0.6];
    footer.font = [UIFont fontWithName:@"CourierNewPSMT" size:10];
    footer.textAlignment = NSTextAlignmentCenter;
    [vc.view addSubview:footer];
    
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)btnLoopTap:(UIButton *)sender {
    UIViewController *vc = self.window.rootViewController;
    UILabel *status = vc.view.subviews[2];
    static BOOL isLooping = NO;
    static NSTimer *timer = nil;
    static uint64_t targetAddr = 0;
    
    if (isLooping) {
        [timer invalidate];
        timer = nil;
        isLooping = NO;
        [sender setTitle:@"[>] 蔡徐坤" forState:UIControlStateNormal];
        status.text = @"已停止";
        status.textColor = [UIColor orangeColor];
        return;
    }
    
    uint64_t addr = 0x100000000 + 0xC004BD0;
    addr = read64(addr) + 0xA0;
    addr = read64(addr) + 0x1B0;
    addr = read64(addr) + 0x220;
    
    if (addr == 0) {
        status.text = @"指针断裂";
        status.textColor = [UIColor redColor];
        return;
    }
    
    targetAddr = addr;
    isLooping = YES;
    [sender setTitle:@"[!] 停止" forState:UIControlStateNormal];
    status.text = @"循环中 (F32 20)";
    status.textColor = [UIColor cyanColor];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:0.01 repeats:YES block:^(NSTimer * _Nonnull t) {
        if (targetAddr != 0) write_float(targetAddr, 20.0);
    }];
}

- (void)btn2048Tap:(UIButton *)sender {
    UIViewController *vc = self.window.rootViewController;
    UILabel *status = vc.view.subviews[2];
    
    uint64_t addr = 0x100000000 + 0xBFFC488;
    addr = read64(addr) + 0xA0;
    addr = read64(addr) + 0x190;
    addr = read64(addr) + 0x30;
    addr = read64(addr) + 0x444;
    
    if (addr == 0) {
        status.text = @"指针断裂";
        status.textColor = [UIColor redColor];
        return;
    }
    
    write32(addr, 108800);
    status.text = @"2048 写入成功!";
    status.textColor = [UIColor greenColor];
}

@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
EOF

if [ $? -eq 0 ]; then
    echo "✅ 编译成功"
    zip -r KFD_CF_Mod.ipa Payload
    echo "✅ IPA 打包完成"
else
    echo "❌ 编译失败"
    exit 1
fi
