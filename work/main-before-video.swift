import Cocoa

struct ClockTime {
    let hour: Int
    let minute: Int
    let second: Int
    init(_ date: Date, calendar: Calendar = .current) {
        let c = calendar.dateComponents([.hour, .minute, .second], from: date)
        hour = c.hour!; minute = c.minute!; second = c.second!
    }
    var twelveHour: Int { hour % 12 == 0 ? 12 : hour % 12 }
    var digits: [Int?] { [twelveHour >= 10 ? 1 : nil, twelveHour % 10, minute / 10, minute % 10] }
}

final class ClockView: NSView {
    var date = Date()
    var displayOnly = UserDefaults.standard.bool(forKey: "displayOnly")
    var brightness: CGFloat = UserDefaults.standard.object(forKey: "dim") as? Bool == true ? 0.48 : 1
    override var isFlipped: Bool { true }
    override var mouseDownCanMoveWindow: Bool { true }
    let orange = NSColor(srgbRed: 1, green: 0.22, blue: 0.045, alpha: 1)
    func shape(_ rect: NSRect, radius: CGFloat, color: NSColor) {
        color.setFill(); NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
    }
    func polygon(_ points: [CGPoint]) -> NSBezierPath {
        let p = NSBezierPath(); p.move(to: points[0]); points.dropFirst().forEach { p.line(to: $0) }; p.close(); return p
    }
    func light(_ path: NSBezierPath, active: Bool = true) {
        NSGraphicsContext.saveGraphicsState()
        if active {
            let glow = NSShadow(); glow.shadowColor = orange.withAlphaComponent(0.65 * brightness); glow.shadowBlurRadius = 9; glow.shadowOffset = .zero; glow.set()
            orange.withAlphaComponent(brightness).setFill(); path.fill()
            NSShadow().set()
            NSColor(srgbRed: 1, green: 0.38, blue: 0.12, alpha: 0.5 * brightness).setStroke(); path.lineWidth = 0.6; path.stroke()
        } else { NSColor(srgbRed: 0.13, green: 0.065, blue: 0.045, alpha: 0.24).setFill(); path.fill() }
        NSGraphicsContext.restoreGraphicsState()
    }
    func digit(_ number: Int?, x: CGFloat, y: CGFloat, small: Bool = false) {
        if small {
            if number != nil {
                for offset: CGFloat in [5, 98] { light(NSBezierPath(rect: NSRect(x: x + 36, y: y + offset, width: 7, height: 86))) }
            }
            return
        }
        let masks = [0x3f,0x06,0x5b,0x4f,0x66,0x6d,0x7d,0x07,0x7f,0x6f]
        // Square-ended, slender shutter segments, rather than a digital font.
        let rects: [NSRect] = [
            NSRect(x: 7,y: 0,width: 76,height: 8), NSRect(x: 80,y: 5,width: 8,height: 86),
            NSRect(x: 80,y: 98,width: 8,height: 86), NSRect(x: 7,y: 181,width: 76,height: 8),
            NSRect(x: 0,y: 98,width: 8,height: 86), NSRect(x: 0,y: 5,width: 8,height: 86),
            NSRect(x: 7,y: 91,width: 76,height: 7)]
        for (i,r) in rects.enumerated() {
            light(NSBezierPath(rect: r.offsetBy(dx: x, dy: y)), active: number.map { masks[$0] & (1 << i) != 0 } ?? false)
        }
    }
    func flower(second: Int) {
        // Sixteen alternating teardrops and fine rays, traced from KT-10B photographs.
        let phase = Double(second) / 60 * 16
        for i in 0..<16 {
            NSGraphicsContext.saveGraphicsState()
            let t = NSAffineTransform(); t.translateX(by: 645, yBy: 212); t.concat()
            let r = NSAffineTransform(); r.rotate(byDegrees: CGFloat(i) * 22.5); r.concat()
            let p = NSBezierPath(); p.move(to: CGPoint(x: 0,y: -8))
            p.curve(to: CGPoint(x: -5,y: -31), controlPoint1: CGPoint(x: -4,y: -15), controlPoint2: CGPoint(x: -9,y: -28))
            p.curve(to: CGPoint(x: 5,y: -31), controlPoint1: CGPoint(x: -3,y: -39), controlPoint2: CGPoint(x: 3,y: -39))
            p.curve(to: CGPoint(x: 0,y: -8), controlPoint1: CGPoint(x: 9,y: -28), controlPoint2: CGPoint(x: 4,y: -15)); p.close()
            let narrow = AffineTransform(scaleByX: 0.48, byY: 1)
            p.transform(using: narrow)
            let savedBrightness = brightness
            let distance = (Double(i) - phase + 16).truncatingRemainder(dividingBy: 16)
            brightness *= CGFloat(0.22 + 0.78 * (1 - distance / 16))
            if i % 2 == 0 { light(p) } else {
                light(polygon([CGPoint(x: 0,y: -11),CGPoint(x: -1.7,y: -34),CGPoint(x: 0,y: -41),CGPoint(x: 1.7,y: -34)]))
            }
            light(NSBezierPath(ovalIn: NSRect(x: -1,y: -6,width: 2,height: 4)))
            brightness = savedBrightness
            NSGraphicsContext.restoreGraphicsState()
        }
    }
    override func draw(_ dirtyRect: NSRect) {
        NSColor(srgbRed: 0.075,green: 0.075,blue: 0.07,alpha: 1).setFill(); bounds.fill()
        NSGraphicsContext.saveGraphicsState()
        let scale = min(bounds.width / 800, bounds.height / (displayOnly ? 405 : 570))
        let transform = NSAffineTransform(); transform.translateX(by: (bounds.width - 800 * scale)/2, yBy: (bounds.height - (displayOnly ? 405 : 570)*scale)/2)
        transform.scale(by: scale); transform.concat()
        if !displayOnly {
            shape(NSRect(x: 235,y: 478,width: 330,height: 48),radius: 7,color: .black)
            let stem = polygon([CGPoint(x: 326,y: 383),CGPoint(x: 474,y: 383),CGPoint(x: 491,y: 504),CGPoint(x: 309,y: 504)])
            NSGradient(starting: NSColor(white: 0.91,alpha: 1), ending: NSColor(white: 0.64,alpha: 1))!.draw(in: stem,angle: 0)
            shape(NSRect(x: 228,y: 509,width: 344,height: 9),radius: 3,color: NSColor(white: 0.16,alpha: 1))
        }
        let body = NSBezierPath(roundedRect: NSRect(x: 24,y: 24,width: 752,height: 386),xRadius: 48,yRadius: 48)
        NSGradient(starting: NSColor(srgbRed: 0.96,green: 0.95,blue: 0.9,alpha: 1),ending: NSColor(srgbRed: 0.71,green: 0.71,blue: 0.66,alpha: 1))!.draw(in: body,angle: 90)
        shape(NSRect(x: 42,y: 37,width: 716,height: 327),radius: 31,color: NSColor(white: 0.025,alpha: 1))
        let glass = NSBezierPath(roundedRect: NSRect(x: 49,y: 43,width: 702,height: 312),xRadius: 26,yRadius: 26)
        NSGradient(starting: NSColor(srgbRed: 0.065,green: 0.061,blue: 0.047,alpha: 1),ending: NSColor(white: 0.012,alpha: 1))!.draw(in: glass,angle: 90)
        let time = ClockTime(date)
        let d = time.digits
        digit(d[0],x: 88,y: 102,small: true); digit(d[1],x: 153,y: 102)
        digit(d[2],x: 365,y: 102); digit(d[3],x: 477,y: 102)
        for y: CGFloat in [164,234] { light(NSBezierPath(rect: NSRect(x: 290,y: y,width: 12,height: 7))) }
        flower(second: time.second)
        NSGraphicsContext.saveGraphicsState(); glass.addClip()
        NSColor(white: 1,alpha: 0.025).setFill()
        polygon([CGPoint(x: 49,y: 43),CGPoint(x: 751,y: 43),CGPoint(x: 751,y: 67),CGPoint(x: 49,y: 150)]).fill()
        NSGraphicsContext.restoreGraphicsState()
        shape(NSRect(x: 568,y: 371,width: 118,height: 26),radius: 1,color: NSColor(srgbRed: 0.19,green: 0.13,blue: 0.10,alpha: 1))
        ("LUMITIME" as NSString).draw(at: CGPoint(x: 576,y: 373),withAttributes: [.font: NSFont(name: "HelveticaNeue-CondensedBold",size: 21) ?? NSFont.boldSystemFont(ofSize: 19),.foregroundColor: NSColor(white: 0.94,alpha: 1)])
        NSGraphicsContext.restoreGraphicsState()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let clock = ClockView()
    var timer: Timer?
    func applicationDidFinishLaunching(_ notification: Notification) {
        window = NSWindow(contentRect: NSRect(x: 0,y: 0,width: 800,height: 570),styleMask: [.titled,.closable,.miniaturizable,.resizable],backing: .buffered,defer: false)
        window.title = "Lumitime KT-10B"; window.backgroundColor = NSColor(white: 0.075,alpha: 1)
        window.titlebarAppearsTransparent = true; window.minSize = NSSize(width: 400,height: 310)
        window.contentView = clock; window.setFrameAutosaveName("LumitimeWindow")
        window.center(); window.makeKeyAndOrderFront(nil)
        window.level = UserDefaults.standard.bool(forKey: "onTop") ? .floating : .normal
        clock.setAccessibilityElement(true); clock.setAccessibilityRole(.staticText)
        update()
        timer = Timer(timeInterval: 0.1,target: self,selector: #selector(update),userInfo: nil,repeats: true)
        RunLoop.main.add(timer!,forMode: .common)
        let menu = NSMenu(); let appItem = NSMenuItem(); menu.addItem(appItem)
        let appMenu = NSMenu(); appItem.submenu = appMenu
        appMenu.addItem(withTitle: "About Lumitime",action: #selector(about),keyEquivalent: "")
        appMenu.addItem(.separator()); appMenu.addItem(withTitle: "Quit Lumitime",action: #selector(NSApplication.terminate(_:)),keyEquivalent: "q")
        let viewItem = NSMenuItem(); viewItem.title = "View"; menu.addItem(viewItem)
        let viewMenu = NSMenu(title: "View"); viewItem.submenu = viewMenu
        for (title,selector,key,on) in [("Keep on Top",#selector(onTop),"t",window.level == .floating),("Display Only",#selector(displayOnly),"d",clock.displayOnly),("Dim Display",#selector(dim),"b",clock.brightness < 1)] {
            let item = viewMenu.addItem(withTitle: title,action: selector,keyEquivalent: key); item.target = self; item.state = on ? .on : .off
        }
        viewMenu.addItem(withTitle: "Enter Full Screen",action: #selector(fullScreen),keyEquivalent: "f").target = self
        NSApp.mainMenu = menu; NSApp.activate(ignoringOtherApps: true)
    }
    @objc func update() { clock.date = Date(); clock.needsDisplay = true; clock.setAccessibilityValue(clock.date.formatted(date: .omitted,time: .standard)) }
    @objc func onTop(_ sender: NSMenuItem) { sender.state = sender.state == .on ? .off : .on; window.level = sender.state == .on ? .floating : .normal; UserDefaults.standard.set(sender.state == .on,forKey: "onTop") }
    @objc func displayOnly(_ sender: NSMenuItem) { clock.displayOnly.toggle(); sender.state = clock.displayOnly ? .on : .off; UserDefaults.standard.set(clock.displayOnly,forKey: "displayOnly"); clock.needsDisplay = true }
    @objc func dim(_ sender: NSMenuItem) { sender.state = sender.state == .on ? .off : .on; clock.brightness = sender.state == .on ? 0.48 : 1; UserDefaults.standard.set(sender.state == .on,forKey: "dim"); clock.needsDisplay = true }
    @objc func fullScreen() { window.toggleFullScreen(nil) }
    @objc func about() { NSApp.orderFrontStandardAboutPanel(options: [.applicationName: "Lumitime",.applicationVersion: "1.0",.credits: NSAttributedString(string: "A native tribute to the Tamura Lumitime KT-10B.\nCustom orange shutter digits and a flower seconds display.\nSeconds animation is an interpretation of the original mechanism.")]) }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

if CommandLine.arguments.contains("--self-test") {
    var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(secondsFromGMT: 0)!
    for h in 0..<24 { for m in 0..<60 { for s in [0,9,10,59] {
        let date = cal.date(from: DateComponents(year: 2026,month: 1,day: 1,hour: h,minute: m,second: s))!
        let t = ClockTime(date,calendar: cal)
        precondition(t.twelveHour == (h % 12 == 0 ? 12 : h % 12)); precondition(t.minute == m && t.second == s)
        precondition(t.digits[2] == m / 10 && t.digits[3] == m % 10)
    } } }
    print("Passed 5,760 clock cases, including midnight, noon and second boundaries.")
} else if let i = CommandLine.arguments.firstIndex(of: "--snapshot"), i + 1 < CommandLine.arguments.count {
    _ = NSApplication.shared
    let view = ClockView(frame: NSRect(x: 0,y: 0,width: 1000,height: 713))
    view.date = Calendar.current.date(from: DateComponents(year: 2026,month: 9,day: 5,hour: 10,minute: 28,second: 6))!
    let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
    view.cacheDisplay(in: view.bounds,to: bitmap)
    try bitmap.representation(using: .png,properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[i + 1]))
} else {
    let app = NSApplication.shared; let delegate = AppDelegate(); app.delegate = delegate; app.setActivationPolicy(.regular); app.run()
}
