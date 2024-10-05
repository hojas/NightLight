//
//  ContentView.swift
//  NightLight
//
//  Created by yuanxiang on 2024/10/4.
//

import SwiftUI
import Combine
import UIKit

struct ContentView: View {
    @State private var isOn = true
    @State private var brightness: Double = 0.5 {
        didSet {
            adjustScreenBrightness(to: brightness)
        }
    }
    @State private var colorIndex = 0
    @State private var timerEndTime: Date?
    @State private var showingTimerPicker = false
    @State private var styleIndex = 0 // 新增: 用于跟踪当前样式
    
    @State private var isControlPanelExpanded = true
    
    let colors: [Color] = [.white, Color(hex: "FFB3BA"), Color(hex: "BAFFC9"), Color(hex: "BAE1FF"), Color(hex: "FFFFBA"), Color(hex: "FFD8B3"), Color(hex: "E0BBE4")]
    let styles = ["圆形", "方形", "圆环"]
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @StateObject private var timerManager = TimerManager()
    
    @State private var canAdjustBrightness: Bool = false

    @State private var screenBrightness: Double = 0.5

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                if horizontalSizeClass == .regular {
                    // iPad 布局
                    VStack {
                        Spacer()
                        nightLightView(size: geometry.size)
                            .frame(height: geometry.size.height * 0.5)
                        Spacer()
                        controlPanelView(size: geometry.size)
                            .padding(.bottom, 30)
                    }
                } else {
                    // iPhone 布局
                    ScrollView {
                        VStack(spacing: 30) {
                            Spacer(minLength: 20)
                            nightLightView(size: geometry.size)
                                .frame(height: geometry.size.height * 0.5)
                            controlPanelView(size: geometry.size)
                            Spacer(minLength: 20)
                        }
                        .frame(minHeight: geometry.size.height)
                    }
                }
            }
            .frame(width: geometry.size.width)
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut, value: isOn)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            setupTimerCheck()
            checkBrightnessPermission()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            timerManager.cancel()
            resetScreenBrightness()
        }
        .sheet(isPresented: $showingTimerPicker) {
            TimerPickerView(timerEndTime: $timerEndTime)
        }
    }
    
    private func nightLightView(size: CGSize) -> some View {
        let dimension = calculateNightLightDimension(for: size)
        return ZStack {
            nightLightShape
                .fill(isOn ? colors[colorIndex].opacity(0.3) : Color.gray.opacity(0.1))
                .frame(width: dimension * 1.2, height: dimension * 1.2)
                .blur(radius: 40)
            
            nightLightShape
                .fill(isOn ? colors[colorIndex].opacity(brightness) : Color.gray.opacity(0.3))
                .frame(width: dimension, height: dimension)
                .shadow(color: isOn ? colors[colorIndex] : .clear, radius: 40)
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.5), value: isOn)
        .animation(.easeInOut(duration: 0.5), value: brightness)
        .animation(.easeInOut(duration: 0.5), value: colorIndex)
        .animation(.easeInOut(duration: 0.5), value: styleIndex)
    }
    
    private func controlPanelView(size: CGSize) -> some View {
        VStack {
            Spacer() // 添加这行来将控制面板推到底部
            if horizontalSizeClass == .regular {
                controlPanel
                    .frame(maxWidth: 400)
            } else {
                controlPanel
                    .frame(maxWidth: min(size.width - 40, 400))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // 修改这行
        .padding(.horizontal, horizontalSizeClass == .regular ? 30 : 15)
        .padding(.bottom, 20) // 添加底部内边距
    }
    
    private func calculateNightLightDimension(for size: CGSize) -> CGFloat {
        let minDimension = min(size.width, size.height)
        let isLandscape = size.width > size.height
        
        if horizontalSizeClass == .regular {
            // iPad
            return isLandscape ? minDimension * 0.5 : minDimension * 0.6
        } else {
            // iPhone
            return minDimension * 0.8
        }
    }
    
    private var controlPanel: some View {
        VStack(spacing: 18) {
            if isControlPanelExpanded {
                HStack {
                    Text(isOn ? "夜灯控制" : "夜灯已关闭")
                        .foregroundColor(.white)
                        .font(.custom("Avenir-Heavy", size: 18))
                    Spacer()
                    Toggle("", isOn: $isOn)
                        .labelsHidden()
                        .tint(colorIndex == 0 ? .gray : colors[colorIndex])
                        .scaleEffect(1.1)
                }
                .padding(.bottom, 5)
                
                if isOn {
                    VStack(spacing: 18) {
                        brightnessControlView(title: "夜灯亮度", value: $brightness, color: colors[colorIndex])
                        brightnessControlView(title: "屏幕亮度", value: $screenBrightness, color: .white) {
                            adjustScreenBrightness(to: screenBrightness)
                        }
                        
                        HStack(spacing: 10) {
                            controlButton(title: "更换颜色", icon: "wand.and.stars", gradient: [Color(hex: "8A2387"), Color(hex: "E94057"), Color(hex: "F27121")]) {
                                colorIndex = (colorIndex + 1) % colors.count
                            }
                            
                            controlButton(title: "切换样式", icon: "sparkles", gradient: [Color(hex: "11998e"), Color(hex: "38ef7d")]) {
                                styleIndex = (styleIndex + 1) % styles.count
                            }
                        }
                        
                        timerButton
                    }
                }
            } else {
                HStack {
                    Text(isOn ? "夜灯已开启" : "夜灯已关闭")
                        .foregroundColor(.white)
                        .font(.custom("Avenir-Medium", size: 16))
                    Spacer()
                    Toggle("", isOn: $isOn)
                        .labelsHidden()
                        .tint(colorIndex == 0 ? .gray : colors[colorIndex])
                        .scaleEffect(1.1)
                }
            }
        }
        .padding(20)
        .background(Color(UIColor.systemGray6).opacity(0.9))
        .cornerRadius(20)
        .shadow(color: colors[colorIndex].opacity(0.3), radius: 10, x: 0, y: 5)
        .overlay(
            VStack {
                expandCollapseButton
                    .padding(.top, 8)
                Spacer()
            }
        )
    }
    
    private var expandCollapseButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                isControlPanelExpanded.toggle()
            }
        }) {
            Image(systemName: isControlPanelExpanded ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                .foregroundColor(.white)
                .font(.system(size: 24))
                .background(Color.black.opacity(0.3))
                .clipShape(Circle())
        }
    }
    
    private func controlButton(title: String, icon: String, gradient: [Color], action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
            }
            .font(.custom("Avenir-Medium", size: 13))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)  // 减小垂直内边距
            .background(LinearGradient(gradient: Gradient(colors: gradient), startPoint: .leading, endPoint: .trailing))
            .cornerRadius(10)  // 稍微减小圆角
        }
    }
    
    private var timerButton: some View {
        Button(action: {
            if timerEndTime != nil {
                timerEndTime = nil
            } else {
                showingTimerPicker = true
            }
        }) {
            HStack {
                Image(systemName: timerEndTime != nil ? "alarm.fill" : "alarm")
                    .foregroundColor(.white)
                    .font(.system(size: 14))
                if let endTime = timerEndTime {
                    Text(timerText(for: endTime))
                        .font(.custom("Avenir-Heavy", size: 13))
                        .foregroundColor(.white)
                    Spacer()
                    Text("取消")
                        .font(.custom("Avenir-Medium", size: 11))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.red.opacity(0.8))
                        .clipShape(Capsule())
                } else {
                    Text("设置定时")
                        .foregroundColor(.white)
                }
            }
            .font(.custom("Avenir-Medium", size: 13))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)  // 减小垂直内边距
            .padding(.horizontal, 14)  // 稍微减小水平内边距
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        timerEndTime != nil ? Color(hex: "FF512F") : Color(hex: "2193b0"),
                        timerEndTime != nil ? Color(hex: "DD2476") : Color(hex: "6dd5ed")
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(10)  // 稍微减小圆角
        }
    }
    
    private func brightnessControlView(title: String, value: Binding<Double>, color: Color, onChange: (() -> Void)? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .foregroundColor(.white)
                .font(.custom("Avenir-Medium", size: 14))
            HStack(spacing: 12) {
                Image(systemName: "sun.min")
                    .foregroundColor(.yellow)
                    .font(.system(size: 14))
                CustomSlider(value: value, color: color)
                    .frame(height: 24)
                    .onChange(of: value.wrappedValue) { _ in
                        onChange?()
                    }
                Image(systemName: "sun.max")
                    .foregroundColor(.yellow)
                    .font(.system(size: 14))
            }
        }
    }
    
    struct CustomSlider: View {
        @Binding var value: Double
        var color: Color
        
        var body: some View {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景轨道
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                    
                    // 填充轨道
                    Capsule()
                        .fill(color)
                        .frame(width: max(0, min(geometry.size.width * CGFloat(value), geometry.size.width)), height: 8)
                    
                    // 滑块圆点
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                        .position(x: max(12, min(geometry.size.width * CGFloat(value), geometry.size.width - 12)),
                                  y: geometry.size.height / 2)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    let newValue = (gesture.location.x - 12) / (geometry.size.width - 24)
                                    self.value = min(max(Double(newValue), 0), 1)
                                }
                        )
                }
            }
            .frame(height: 24)
        }
    }
    
    // 修改 nightLightShape 计算属性
    var nightLightShape: some Shape {
        switch styles[styleIndex] {
        case "形":
            return AnyShape(Circle())
        case "方形":
            return AnyShape(RoundedRectangle(cornerRadius: 25))
        case "圆环":
            return AnyShape(Ring(thickness: 0.3))
        default:
            return AnyShape(Circle())
        }
    }
    
    func timerText(for endTime: Date) -> String {
        let remaining = endTime.timeIntervalSince(Date())
        if remaining > 0 {
            let hours = Int(remaining) / 3600
            let minutes = (Int(remaining) % 3600) / 60
            
            if hours > 0 {
                return String(format: "%d:%02d", hours, minutes)
            } else {
                return String(format: "%d分钟", minutes)
            }
        } else {
            return "时间到"
        }
    }
    
    private func setupTimerCheck() {
        timerManager.start {
            if let endTime = timerEndTime, endTime <= Date() {
                isOn = false
                timerEndTime = nil
            }
        }
    }

    // 添加这个新函数来调整屏幕亮度
    private func adjustScreenBrightness(to value: Double) {
        if canAdjustBrightness {
            UIScreen.main.brightness = CGFloat(value)
            print("屏幕亮度已调整为: \(value)")
        } else {
            print("无法调整屏幕亮度")
        }
    }

    private func checkBrightnessPermission() {
        canAdjustBrightness = UIScreen.main.brightness >= 0
        print("是否可以调整屏幕亮度: \(canAdjustBrightness)")
    }

    private func resetScreenBrightness() {
        if canAdjustBrightness {
            UIScreen.main.brightness = UIScreen.main.brightness
            print("屏幕亮度已重置")
        }
    }
}

class TimerManager: ObservableObject {
    private var cancellable: AnyCancellable?
    
    func start(action: @escaping () -> Void) {
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                action()
            }
    }
    
    func cancel() {
        cancellable?.cancel()
    }
}

struct AnyShape: Shape {
    private let path: (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        path = { rect in
            shape.path(in: rect)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        path(rect)
    }
}

extension AnyShape: @unchecked Sendable {}

struct Ring: Shape {
    var thickness: CGFloat // 圆环的厚度,0.0 到 1.0 之间
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * (1 - thickness)
        
        path.addArc(center: center, radius: radius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        path.addArc(center: center, radius: innerRadius, startAngle: .degrees(360), endAngle: .degrees(0), clockwise: true)
        path.closeSubpath()
        
        return path
    }
}

struct TimerPickerView: View {
    @Binding var timerEndTime: Date?
    @State private var selectedMode: TimerMode = .duration
    @State private var selectedDuration: TimeInterval = 30 * 60
    @State private var selectedTime = Date()
    @Environment(\.presentationMode) var presentationMode
    
    enum TimerMode {
        case duration, time
    }
    
    var body: some View {
        NavigationView {
            Form {
                Picker("定时模式", selection: $selectedMode) {
                    Text("持续时间").tag(TimerMode.duration)
                    Text("具体时间").tag(TimerMode.time)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                if selectedMode == .duration {
                    Picker("选择时长", selection: $selectedDuration) {
                        Text("30分钟").tag(TimeInterval(30 * 60))
                        Text("1小时").tag(TimeInterval(60 * 60))
                        Text("2小时").tag(TimeInterval(2 * 60 * 60))
                        Text("4小时").tag(TimeInterval(4 * 60 * 60))
                    }
                } else {
                    DatePicker("选择时间", selection: $selectedTime, displayedComponents: .hourAndMinute)
                }
            }
            .navigationBarTitle("设置定时", displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("设置") {
                    setTimer()
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .preferredColorScheme(.dark)
    }
    
    private func setTimer() {
        if selectedMode == .duration {
            timerEndTime = Date().addingTimeInterval(selectedDuration)
        } else {
            let calendar = Calendar.current
            let now = Date()
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
            components.hour = timeComponents.hour
            components.minute = timeComponents.minute
            
            if let setTime = calendar.date(from: components), setTime > now {
                timerEndTime = setTime
            } else {
                // If the selected time is earlier than now, set it for tomorrow
                components.day! += 1
                timerEndTime = calendar.date(from: components)
            }
        }
    }
}

// 添加一个扩展来支持十六进制颜色代码
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .previewDevice("iPhone 12 Pro")
                .previewDisplayName("iPhone 12 Pro")
            
            ContentView()
                .previewDevice("iPad Pro (11-inch) (3rd generation)")
                .previewDisplayName("iPad Pro 11-inch")
            
            ContentView()
                .previewDevice("iPad Pro (11-inch) (3rd generation)")
                .previewDisplayName("iPad Pro 11-inch Landscape")
                .previewInterfaceOrientation(.landscapeLeft)
        }
    }
}