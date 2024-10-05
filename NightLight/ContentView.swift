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
    // MARK: - 状态变量
    @State private var isOn = true
    @State private var brightness: Double = 0.5 {
        didSet {
            adjustScreenBrightness(to: brightness)
        }
    }
    @State private var colorIndex = 0
    @State private var timerEndTime: Date?
    @State private var showingTimerPicker = false
    @State private var styleIndex = 0 // 用于跟踪当前夜灯样式
    @State private var isControlPanelExpanded = true
    @State private var showingColorPicker = false
    @State private var customColor: Color = .white
    @State private var canAdjustBrightness: Bool = false
    @State private var screenBrightness: Double = 0.5

    // MARK: - 常量
    let styles = ["圆形", "方形", "圆环"]
    let buttonGradients: [[Color]] = [
        [Color(hex: "FF512F"), Color(hex: "DD2476")],  // 红色渐变
        [Color(hex: "11998e"), Color(hex: "38ef7d")],  // 绿色渐变
        [Color(hex: "2193b0"), Color(hex: "6dd5ed")]   // 蓝色渐变
    ]

    // MARK: - 环境变量
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // MARK: - 状态对象
    @StateObject private var timerManager = TimerManager()

    // MARK: - 颜色数组
    @State private var colors: [Color] = [
        .white,
        Color(hex: "FFD1DC"),  // 浅粉红
        Color(hex: "ADD8E6"),  // 浅蓝色
        Color(hex: "98FB98"),  // 浅绿色
        Color(hex: "FAFAD2"),  // 浅黄色
        Color(hex: "FFE4B5"),  // 淡橙色
        Color(hex: "E6E6FA"),  // 淡紫色
        .gray  // 自定义颜色位置
    ]

    // MARK: - 主体视图
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                if horizontalSizeClass == .regular {
                    // iPad 布局
                    iPadLayout(geometry: geometry)
                } else {
                    // iPhone 布局
                    iPhoneLayout(geometry: geometry)
                }
            }
            .frame(width: geometry.size.width)
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut, value: isOn)
        .onAppear(perform: setupOnAppear)
        .onDisappear(perform: cleanupOnDisappear)
        .sheet(isPresented: $showingTimerPicker) {
            TimerPickerView(timerEndTime: $timerEndTime)
        }
        .sheet(isPresented: $showingColorPicker) {
            ColorPickerView(selectedColor: $colorIndex, colors: $colors)
        }
    }

    // MARK: - 辅助方法
    private func safeColorIndex(_ index: Int) -> Int {
        return min(max(index, 0), colors.count - 1)
    }
    
    // MARK: - 布局方法
    private func iPadLayout(geometry: GeometryProxy) -> some View {
        VStack {
            Spacer().frame(height: 50)
            nightLightView(size: geometry.size)
                .frame(height: geometry.size.height * 0.5)
            Spacer()
            controlPanelView(size: geometry.size)
                .padding(.bottom, 30)
        }
    }
    
    private func iPhoneLayout(geometry: GeometryProxy) -> some View {
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

    // MARK: - 夜灯视图
    private func nightLightView(size: CGSize) -> some View {
        let dimension = calculateNightLightDimension(for: size)
        let currentColor = colors[safeColorIndex(colorIndex)]
        return ZStack {
            nightLightShape
                .fill(isOn ? currentColor.opacity(0.3) : Color.gray.opacity(0.1))
                .frame(width: dimension * 1.2, height: dimension * 1.2)
                .blur(radius: 40)
            
            nightLightShape
                .fill(isOn ? currentColor.opacity(brightness) : Color.gray.opacity(0.3))
                .frame(width: dimension, height: dimension)
                .shadow(color: isOn ? currentColor : .clear, radius: 40)
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.5), value: isOn)
        .animation(.easeInOut(duration: 0.5), value: brightness)
        .animation(.easeInOut(duration: 0.5), value: colorIndex)
        .animation(.easeInOut(duration: 0.5), value: styleIndex)
    }

    // MARK: - 控制面板视图
    private func controlPanelView(size: CGSize) -> some View {
        VStack {
            Spacer() // 这会将控制面板推到底部
            if horizontalSizeClass == .regular {
                controlPanel
                    .frame(maxWidth: 400)
            } else {
                controlPanel
                    .frame(maxWidth: min(size.width - 40, 400))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.horizontal, horizontalSizeClass == .regular ? 30 : 15)
        .padding(.bottom, 10) // 将底部内边距从 30 减小到 10，使控制面板更靠近屏幕底部
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
        VStack(spacing: 12) {  // 减小间距
            if isControlPanelExpanded {
                HStack {
                    Text(isOn ? "夜灯控制" : "夜灯已关闭")
                        .foregroundColor(.white)
                        .font(.custom("Avenir-Heavy", size: 16))  // 减小字体
                    Spacer()
                    Toggle("", isOn: $isOn)
                        .labelsHidden()
                        .tint(colorIndex == 0 ? .gray : colors[safeColorIndex(colorIndex)])
                        .scaleEffect(1.0)  // 减小开关大小
                }
                .padding(.bottom, 2)  // 减小底部间距
                
                if isOn {
                    VStack(spacing: 12) {  // 减小间距
                        brightnessControlView(title: "夜灯亮度", value: $brightness, color: colors[safeColorIndex(colorIndex)])
                        brightnessControlView(title: "屏幕亮度", value: $screenBrightness, color: .white) {
                            adjustScreenBrightness(to: screenBrightness)
                        }
                        
                        HStack(spacing: 6) {  // 减小按钮间距
                            controlButton(title: "颜色", icon: "paintpalette.fill", gradient: buttonGradients[0]) {
                                showingColorPicker = true
                            }
                            
                            controlButton(title: "样式", icon: "square.on.circle.fill", gradient: buttonGradients[1]) {
                                styleIndex = (styleIndex + 1) % styles.count
                            }
                            
                            timerButton
                        }
                    }
                }
            } else {
                HStack {
                    Text(isOn ? "夜灯已开启" : "夜灯已关闭")
                        .foregroundColor(.white)
                        .font(.custom("Avenir-Medium", size: 14))  // 减小字体
                    Spacer()
                    Toggle("", isOn: $isOn)
                        .labelsHidden()
                        .tint(colorIndex == 0 ? .gray : colors[safeColorIndex(colorIndex)])
                        .scaleEffect(1.0)  // 减小开关大小
                }
            }
        }
        .padding(12)  // 减小内边距
        .background(Color(UIColor.systemGray6).opacity(0.9))
        .cornerRadius(16)  // 减小圆角
        .shadow(color: colors[safeColorIndex(colorIndex)].opacity(0.3), radius: 8, x: 0, y: 4)  // 调整阴影
        .overlay(
            VStack {
                expandCollapseButton
                    .padding(.top, 4)  // 减小顶部距
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
            VStack(spacing: 2) {
                if title == "颜色" {
                    ZStack {
                        Circle()
                            .fill(colors[safeColorIndex(colorIndex)])
                            .frame(width: 24, height: 24)
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 24, height: 24)
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .onTapGesture {
                        showingColorPicker = true
                    }
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                }
                Text(title)
                    .font(.custom("Avenir-Medium", size: 10))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(LinearGradient(gradient: Gradient(colors: gradient), startPoint: .topLeading, endPoint: .bottomTrailing))
            .cornerRadius(12)
            .shadow(color: gradient[0].opacity(0.4), radius: 4, x: 0, y: 2)
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
            VStack(spacing: 2) {  // 减小间距
                Image(systemName: timerEndTime != nil ? "alarm.fill" : "alarm")
                    .font(.system(size: 18))  // 减小图标大小
                if let endTime = timerEndTime {
                    Text(timerText(for: endTime))
                        .font(.custom("Avenir-Heavy", size: 10))  // 减小字体
                } else {
                    Text("定时")
                        .font(.custom("Avenir-Medium", size: 10))  // 减小字体
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)  // 减小按钮高度
            .background(
                LinearGradient(
                    gradient: Gradient(colors: buttonGradients[2]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)  // 减小圆角
            .shadow(color: buttonGradients[2][0].opacity(0.4), radius: 4, x: 0, y: 2)  // 调整阴影
        }
    }
    
    private func brightnessControlView(title: String, value: Binding<Double>, color: Color, onChange: (() -> Void)? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {  // 减小间距
            Text(title)
                .foregroundColor(.white)
                .font(.custom("Avenir-Medium", size: 12))  // 减小字体
            HStack(spacing: 10) {  // 减小间距
                Image(systemName: "sun.min")
                    .foregroundColor(.yellow)
                    .font(.system(size: 12))  // 减小图标大小
                CustomSlider(value: value, color: color)
                    .frame(height: 20)  // 减小滑块高度
                    .onChange(of: value.wrappedValue) { _ in
                        onChange?()
                    }
                Image(systemName: "sun.max")
                    .foregroundColor(.yellow)
                    .font(.system(size: 12))  // 减小图标大小
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
    
    // MARK: - 生命周期方法
    private func setupOnAppear() {
        UIApplication.shared.isIdleTimerDisabled = true
        setupTimerCheck()
        checkBrightnessPermission()
    }

    private func cleanupOnDisappear() {
        UIApplication.shared.isIdleTimerDisabled = false
        timerManager.cancel()
        resetScreenBrightness()
    }

    // MARK: - 亮度调节方法
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

    // MARK: - 定时器相关方法
    private func setupTimerCheck() {
        timerManager.start {
            if let endTime = timerEndTime, endTime <= Date() {
                isOn = false
                timerEndTime = nil
            }
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
                return String(format: "%d钟", minutes)
            }
        } else {
            return "时间到"
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

// 修改 ColorPickerView 结构体
struct ColorPickerView: View {
    @Binding var selectedColor: Int
    @Binding var colors: [Color]
    @State private var customColor: Color = .gray
    @Environment(\.presentationMode) var presentationMode
    
    let columns = [
        GridItem(.adaptive(minimum: 60, maximum: 60))
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 自定义颜色选择器
                VStack(alignment: .leading) {
                    Text("自定义颜色")
                        .font(.headline)
                    ColorPicker("选择颜色", selection: $customColor)
                        .labelsHidden()
                    Button(action: {
                        useCustomColor()
                    }) {
                        Text("使用自定义颜色")
                            .foregroundColor(.white)
                            .padding()
                            .background(customColor)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(15)
                
                // 预设颜色网格
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                        ColorCircle(color: color, isSelected: selectedColor == index, index: index)
                            .onTapGesture {
                                selectedColor = index
                                presentationMode.wrappedValue.dismiss()
                            }
                    }
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .navigationTitle("选择颜色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            customColor = colors.last ?? .gray
        }
    }
    
    private func useCustomColor() {
        DispatchQueue.main.async {
            colors[colors.count - 1] = customColor
            selectedColor = colors.count - 1
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// 修改 ColorCircle 结构体
struct ColorCircle: View {
    let color: Color
    let isSelected: Bool
    let index: Int
    
    var body: some View {
        VStack {
            Circle()
                .fill(color)
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .opacity(isSelected ? 1 : 0)
                )
            Text(colorName(for: index))
                .font(.system(size: 10))
                .foregroundColor(.white)
        }
    }
    
    private func colorName(for index: Int) -> String {
        let names = ["白", "粉", "蓝", "绿", "黄", "橙", "紫", "自定义"]
        return names[index]
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