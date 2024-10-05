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
    // 状态变量
    @State private var isOn = true
    @State private var brightness: Double = 0.5
    @State private var colorIndex = 0
    @State private var timerEndTime: Date?
    @State private var showingTimerPicker = false
    @State private var styleIndex = 0
    @State private var isControlPanelExpanded = true
    @State private var showingColorPicker = false
    @State private var customColor: Color = .white
    @State private var screenBrightness: Double = 0.5
    @State private var language: Language = .chinese
    @State private var showingControlPanel = false
    
    // 环境变量
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // 状态对象
    @StateObject private var timerManager = TimerManager()
    @StateObject private var brightnessManager = BrightnessManager()

    // 常量
    let styles = ["Circle", "Square", "Ring"]
    let buttonGradients: [[Color]] = [
        [Color(hex: "FF512F"), Color(hex: "DD2476")],
        [Color(hex: "11998e"), Color(hex: "38ef7d")],
        [Color(hex: "2193b0"), Color(hex: "6dd5ed")]
    ]
    let colors: [Color] = [
        .white,
        Color(hex: "FFD1DC"),
        Color(hex: "ADD8E6"),
        Color(hex: "98FB98"),
        Color(hex: "FAFAD2"),
        Color(hex: "FFE4B5"),
        Color(hex: "E6E6FA"),
        .gray
    ]

    // 主体视图
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                if horizontalSizeClass == .regular {
                    iPadLayout(geometry: geometry)
                } else {
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
            ColorPickerView(selectedColor: $colorIndex, colors: colors)
        }
        .environment(\.locale, Locale(identifier: language.rawValue))
        .id(language)
    }

    // iPad布局
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
    
    // iPhone布局
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

    // 夜灯视图
    private func nightLightView(size: CGSize) -> some View {
        let dimension = calculateNightLightDimension(for: size)
        let currentColor = colors[colorIndex]
        return ZStack {
            // 背景光晕
            nightLightShape
                .fill(isOn ? currentColor.opacity(0.3) : Color.gray.opacity(0.1))
                .frame(width: dimension * 1.2, height: dimension * 1.2)
                .blur(radius: 40)
            
            // 主要夜灯形状
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

    // 控制面板视图
    private func controlPanelView(size: CGSize) -> some View {
        VStack {
            Spacer()
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
        .padding(.bottom, 10)
    }
    
    // 控制面板内容
    private var controlPanel: some View {
        VStack(spacing: 12) {
            if isControlPanelExpanded {
                expandedControlPanel
            } else {
                collapsedControlPanel
            }
        }
        .padding(16)
        .background(Color(UIColor.systemGray6).opacity(0.9))
        .cornerRadius(16)
        .shadow(color: colors[colorIndex].opacity(0.3), radius: 8, x: 0, y: 4)
        .overlay(expandCollapseButton, alignment: .top)
    }
    
    // 展开的控制面板
    private var expandedControlPanel: some View {
        VStack(spacing: 12) {
            toggleView
            if isOn {
                VStack(spacing: 12) {
                    brightnessControlView(title: "NightLightBrightness", value: $brightness, color: colors[colorIndex])
                    brightnessControlView(title: "ScreenBrightness", value: $screenBrightness, color: .white) {
                        brightnessManager.adjustScreenBrightness(to: screenBrightness)
                    }
                    controlButtonsRow
                }
            }
        }
    }
    
    // 折叠的控制面板
    private var collapsedControlPanel: some View {
        toggleView
    }
    
    // 开关视图
    private var toggleView: some View {
        HStack {
            Text(LocalizedStringKey(isOn ? "NightLightControl" : "NightLightOff"))
                .foregroundColor(.white)
                .font(.subheadline)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(colorIndex == 0 ? .gray : colors[colorIndex])
                .scaleEffect(0.8)
        }
    }
    
    // 控制按钮行
    private var controlButtonsRow: some View {
        HStack(spacing: 8) {
            controlButton(title: LocalizedStringKey("Color"), icon: "paintpalette.fill", gradient: buttonGradients[0]) {
                showingColorPicker = true
            }
            controlButton(title: LocalizedStringKey("Style"), icon: "square.on.circle.fill", gradient: buttonGradients[1]) {
                styleIndex = (styleIndex + 1) % styles.count
            }
            timerButton
            controlButton(title: LocalizedStringKey(language == .chinese ? "EN" : "中"), icon: "globe", gradient: buttonGradients[2]) {
                language = language == .chinese ? .english : .chinese
            }
        }
        .frame(height: 50)
    }
    
    // 展开/折叠按钮
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
        .padding(.top, 4)
    }
    
    // 计算夜灯尺寸
    private func calculateNightLightDimension(for size: CGSize) -> CGFloat {
        let minDimension = min(size.width, size.height)
        let isLandscape = size.width > size.height
        return horizontalSizeClass == .regular
            ? (isLandscape ? minDimension * 0.5 : minDimension * 0.6)
            : minDimension * 0.8
    }
    
    // 夜灯形状
    private var nightLightShape: some Shape {
        switch styles[styleIndex] {
        case "Circle": return AnyShape(Circle())
        case "Square": return AnyShape(RoundedRectangle(cornerRadius: 25))
        case "Ring": return AnyShape(Ring(thickness: 0.3))
        default: return AnyShape(Circle())
        }
    }
    
    // 设置初始状态
    private func setupOnAppear() {
        UIApplication.shared.isIdleTimerDisabled = true
        timerManager.start {
            if let endTime = timerEndTime, endTime <= Date() {
                isOn = false
                timerEndTime = nil
            }
        }
        brightnessManager.checkPermission()
    }

    // 清理资源
    private func cleanupOnDisappear() {
        UIApplication.shared.isIdleTimerDisabled = false
        timerManager.cancel()
        brightnessManager.resetScreenBrightness()
    }

    // 亮度控制视图
    private func brightnessControlView(title: String, value: Binding<Double>, color: Color, onChange: (() -> Void)? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(LocalizedStringKey(title))
                .foregroundColor(.white)
                .font(.caption)
            HStack(spacing: 8) {
                Image(systemName: "sun.min")
                    .foregroundColor(.yellow)
                    .font(.system(size: 12))
                CustomSlider(value: value, color: color)
                    .frame(height: 24)
                    .onChange(of: value.wrappedValue) { _ in
                        onChange?()
                    }
                Image(systemName: "sun.max")
                    .foregroundColor(.yellow)
                    .font(.system(size: 12))
            }
        }
    }

    // 控制按钮
    private func controlButton(title: LocalizedStringKey, icon: String, gradient: [Color], action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 10))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(LinearGradient(gradient: Gradient(colors: gradient), startPoint: .topLeading, endPoint: .bottomTrailing))
            .cornerRadius(12)
        }
    }

    // 定时器按钮
    private var timerButton: some View {
        Button(action: {
            if timerEndTime != nil {
                timerEndTime = nil
            } else {
                showingTimerPicker = true
            }
        }) {
            VStack(spacing: 2) {
                Image(systemName: timerEndTime != nil ? "alarm.fill" : "alarm")
                    .font(.system(size: 16))
                if let endTime = timerEndTime {
                    Text(timerText(for: endTime))
                        .font(.system(size: 10))
                } else {
                    Text(LocalizedStringKey("Timer"))
                        .font(.system(size: 10))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: buttonGradients[2]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
        }
    }

    // 格式化定时器文本
    private func timerText(for endTime: Date) -> String {
        let remaining = endTime.timeIntervalSince(Date())
        if remaining > 0 {
            let hours = Int(remaining) / 3600
            let minutes = (Int(remaining) % 3600) / 60
            
            if hours > 0 {
                return String(format: "%d:%02d", hours, minutes)
            } else {
                return String(format: "%d分", minutes)
            }
        } else {
            return "TimeUp"
        }
    }
}

// 以下是辅助类型和视图，可以根据需要添加注释

enum Language: String {
    case chinese = "zh"
    case english = "en"
}

class TimerManager: ObservableObject {
    private var cancellable: AnyCancellable?
    
    func start(action: @escaping () -> Void) {
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in action() }
    }
    
    func cancel() {
        cancellable?.cancel()
    }
}

class BrightnessManager: ObservableObject {
    @Published var canAdjustBrightness: Bool = false
    
    func checkPermission() {
        canAdjustBrightness = UIScreen.main.brightness >= 0
    }
    
    func adjustScreenBrightness(to value: Double) {
        guard canAdjustBrightness else { return }
        UIScreen.main.brightness = CGFloat(value)
    }
    
    func resetScreenBrightness() {
        guard canAdjustBrightness else { return }
        UIScreen.main.brightness = UIScreen.main.brightness
    }
}

struct CustomSlider: View {
    @Binding var value: Double
    var color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 8)
                
                Capsule()
                    .fill(color)
                    .frame(width: max(0, min(geometry.size.width * CGFloat(value), geometry.size.width)), height: 8)
                
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

struct Ring: Shape {
    var thickness: CGFloat
    
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

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct AnyShape: Shape {
    private let path: (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        path = { rect in shape.path(in: rect) }
    }
    
    func path(in rect: CGRect) -> Path {
        path(rect)
    }
}

extension AnyShape: @unchecked Sendable {}

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
                Picker(LocalizedStringKey("TimerMode"), selection: $selectedMode) {
                    Text(LocalizedStringKey("Duration")).tag(TimerMode.duration)
                    Text(LocalizedStringKey("SpecificTime")).tag(TimerMode.time)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                if selectedMode == .duration {
                    Picker(LocalizedStringKey("SelectDuration"), selection: $selectedDuration) {
                        Text(LocalizedStringKey("30Minutes")).tag(TimeInterval(30 * 60))
                        Text(LocalizedStringKey("1Hour")).tag(TimeInterval(60 * 60))
                        Text(LocalizedStringKey("2Hours")).tag(TimeInterval(2 * 60 * 60))
                        Text(LocalizedStringKey("4Hours")).tag(TimeInterval(4 * 60 * 60))
                    }
                } else {
                    DatePicker(LocalizedStringKey("SelectTime"), selection: $selectedTime, displayedComponents: .hourAndMinute)
                }
            }
            .navigationBarTitle(LocalizedStringKey("SetTimer"), displayMode: .inline)
            .navigationBarItems(
                leading: Button(LocalizedStringKey("Cancel")) {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(LocalizedStringKey("Set")) {
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

struct ColorPickerView: View {
    @Binding var selectedColor: Int
    let colors: [Color]
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
                    Text("CustomColor")
                        .font(.headline)
                    ColorPicker("SelectColor", selection: $customColor)
                        .labelsHidden()
                    Button(action: {
                        useCustomColor()
                    }) {
                        Text("UseCustomColor")
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
            .navigationTitle("SelectColor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
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
            selectedColor = colors.count - 1
            presentationMode.wrappedValue.dismiss()
        }
    }
}

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
    
    private func colorName(for index: Int) -> LocalizedStringKey {
        let names: [LocalizedStringKey] = ["White", "Pink", "Blue", "Green", "Yellow", "Orange", "Purple", "Custom"]
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