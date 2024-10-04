//
//  ContentView.swift
//  NightLight
//
//  Created by yuanxiang on 2024/10/4.
//

import SwiftUI

struct ContentView: View {
    @State private var isOn = true
    @State private var brightness: Double = 0.5
    @State private var colorIndex = 0
    @State private var timerEndTime: Date?
    @State private var showingTimerPicker = false
    @State private var styleIndex = 0 // 新增: 用于跟踪当前样式
    
    let colors: [Color] = [.white, Color(hex: "FFB3BA"), Color(hex: "BAFFC9"), Color(hex: "BAE1FF"), Color(hex: "FFFFBA"), Color(hex: "FFD8B3"), Color(hex: "E0BBE4")]
    let styles = ["圆形", "方形", "圆环"]
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Spacer().frame(height: 20)
                
                ZStack {
                    nightLightShape // 新增: 使用自定义形状
                        .fill(isOn ? colors[colorIndex].opacity(0.3) : Color.gray.opacity(0.1))
                        .frame(width: 360, height: 360) // 增加尺寸
                        .blur(radius: 40) // 稍微增加模糊半径
                    
                    nightLightShape // 新增: 使用自定义形状
                        .fill(isOn ? colors[colorIndex].opacity(brightness) : Color.gray.opacity(0.3))
                        .frame(width: 300, height: 300) // 增加尺寸
                        .shadow(color: isOn ? colors[colorIndex] : .clear, radius: 40) // 增加阴影半径
                }
                .animation(.easeInOut(duration: 0.5), value: isOn)
                .animation(.easeInOut(duration: 0.5), value: brightness)
                .animation(.easeInOut(duration: 0.5), value: colorIndex)
                .animation(.easeInOut(duration: 0.5), value: styleIndex) // 新增: 样式切换动画
                
                Spacer()
                
                VStack(spacing: 25) {
                    HStack {
                        Text(isOn ? "开灯" : "关灯")
                            .foregroundColor(.white)
                            .font(.custom("Avenir-Heavy", size: 20))
                        Spacer()
                        Toggle("", isOn: $isOn)
                            .labelsHidden()
                            .tint(colorIndex == 0 ? .gray : colors[colorIndex])
                            .scaleEffect(1.2)
                    }
                    .padding(.bottom, 10)
                    
                    if isOn {
                        VStack(spacing: 25) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("亮度")
                                    .foregroundColor(.white)
                                    .font(.custom("Avenir-Medium", size: 16))
                                HStack {
                                    Image(systemName: "sun.min.fill")
                                        .foregroundColor(.yellow)
                                    Slider(value: $brightness, in: 0.1...1)
                                        .accentColor(colors[colorIndex])
                                    Image(systemName: "sun.max.fill")
                                        .foregroundColor(.yellow)
                                }
                            }
                            
                            HStack(spacing: 15) {
                                Button(action: {
                                    colorIndex = (colorIndex + 1) % colors.count
                                }) {
                                    HStack {
                                        Image(systemName: "wand.and.stars")
                                        Text("更换颜色")
                                    }
                                    .font(.custom("Avenir-Medium", size: 16))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(LinearGradient(gradient: Gradient(colors: [Color(hex: "8A2387"), Color(hex: "E94057"), Color(hex: "F27121")]), startPoint: .leading, endPoint: .trailing))
                                    .cornerRadius(20)
                                }
                                
                                Button(action: {
                                    styleIndex = (styleIndex + 1) % styles.count
                                }) {
                                    HStack {
                                        Image(systemName: "sparkles")
                                        Text("切换样式")
                                    }
                                    .font(.custom("Avenir-Medium", size: 16))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(LinearGradient(gradient: Gradient(colors: [Color(hex: "11998e"), Color(hex: "38ef7d")]), startPoint: .leading, endPoint: .trailing))
                                    .cornerRadius(20)
                                }
                            }
                            
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
                                    if let endTime = timerEndTime {
                                        Text(timerText(for: endTime))
                                            .font(.custom("Avenir-Heavy", size: 16))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text("取消")
                                            .font(.custom("Avenir-Medium", size: 14))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.red.opacity(0.8))
                                            .clipShape(Capsule())
                                    } else {
                                        Text("设置定时")
                                    }
                                }
                                .font(.custom("Avenir-Medium", size: 16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 15)
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
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                                .cornerRadius(20)
                            }
                        }
                        .transition(.opacity)
                    }
                }
                .padding(25)
                .background(Color(UIColor.systemGray6).opacity(0.9))
                .cornerRadius(30)
                .shadow(color: colors[colorIndex].opacity(0.3), radius: 15, x: 0, y: 5)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut, value: isOn)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .sheet(isPresented: $showingTimerPicker) {
            TimerPickerView(timerEndTime: $timerEndTime)
        }
        .onChange(of: timerEndTime) { newValue in
            if let endTime = newValue, endTime <= Date() {
                isOn = false
                timerEndTime = nil
            }
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

#Preview {
    ContentView()
}