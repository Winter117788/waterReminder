import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WaterViewModel()
    
    var body: some View {
        TabView {
            HomeView(viewModel: viewModel)
                .tabItem {
                    Label("今日", systemImage: "drop.fill")
                }
            
            CalendarView(viewModel: viewModel)
                .tabItem {
                    Label("记录", systemImage: "calendar")
                }
            
            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
        }
        .onAppear {
            viewModel.clearBadge()
        }
        .onChange(of: UIApplication.shared.applicationState) { newState in
            if newState == .active {
                viewModel.clearBadge()
            }
        }
    }
}

struct HomeView: View {
    @ObservedObject var viewModel: WaterViewModel
    @State private var showingCustomAmountSheet = false
    @AppStorage("customContainer") private var customContainer: Double = 0
    @State private var showingContainerInput = false
    @State private var tempContainerAmount: String = ""
    @State private var customAmount: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 进度圆环
                    ZStack {
                        Circle()
                            .stroke(Color.blue.opacity(0.2), lineWidth: 20)
                        Circle()
                            .trim(from: 0, to: min(viewModel.todayWaterAmount / viewModel.dailyGoal, 1))
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(), value: viewModel.todayWaterAmount)
                        
                        VStack {
                            Text("\(Int(viewModel.todayWaterAmount))ml")
                                .font(.largeTitle)
                                .bold()
                            Text("目标: \(Int(viewModel.dailyGoal))ml")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(40)
                    
                    // 快捷添加按钮
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        // 只显示前两个快捷按钮（100ml和350ml）
                        ForEach(viewModel.quickAddAmounts.prefix(2), id: \.self) { amount in
                            QuickAddButton(amount: amount) {
                                viewModel.addWater(Double(amount))
                            }
                        }
                        
                        // 自定义添加按钮放在第三个位置
                        Button(action: {
                            customAmount = ""
                            showingCustomAmountSheet = true
                        }) {
                            VStack {
                                Image(systemName: "plus")
                                Text("自定义")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                            .frame(width: 80, height: 80)
                            .background(Color.green)
                            .clipShape(Circle())
                        }
                    }
                    .padding()
                    
                    // 自定义容器部分
                    HStack {
                        Button(action: {
                            showingContainerInput = true
                            tempContainerAmount = customContainer > 0 ? "\(Int(customContainer))" : ""
                        }) {
                            HStack {
                                Image(systemName: "bottle.fill")
                                Text(customContainer > 0 ? "\(Int(customContainer))毫升" : "设置容器容量")
                                    .foregroundColor(customContainer > 0 ? .primary : .gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        if customContainer > 0 {
                            Button(action: {
                                viewModel.addWater(customContainer)
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                            .padding(.leading, 8)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("饮水记录")
            .alert("添加饮水量", isPresented: $showingCustomAmountSheet) {
                TextField("输入饮水量(毫升)", text: $customAmount)
                    .keyboardType(.numberPad)
                    .moveTextFieldCursorToEnd()
                Button("取消", role: .cancel) { }
                Button("确定") {
                    if let amount = Double(customAmount) {
                        viewModel.addWater(amount)
                    }
                }
            } message: {
                Text("请输入饮水量（毫升）")
            }
            .alert("设置容器容量", isPresented: $showingContainerInput) {
                TextField("输入容量(毫升)", text: $tempContainerAmount)
                    .keyboardType(.numberPad)
                    .moveTextFieldCursorToEnd()
                Button("取消", role: .cancel) { }
                Button("确定") {
                    if let amount = Double(tempContainerAmount) {
                        customContainer = amount
                    }
                }
            } message: {
                Text("请输入容器的容量（毫升）")
            }
        }
    }
}

struct QuickAddButton: View {
    let amount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Text("+\(amount)")
                    .font(.headline)
                Text("ml")
                    .font(.caption)
            }
            .foregroundColor(.white)
            .frame(width: 80, height: 80)
            .background(Color.blue)
            .clipShape(Circle())
        }
    }
}

struct CalendarView: View {
    @ObservedObject var viewModel: WaterViewModel
    @State private var selectedDate: Date = Date()
    private let calendar = Calendar.current
    
    var body: some View {
        NavigationView {
            VStack {
                // 自定义日历视图
                VStack {
                    // 月份选择器
                    HStack {
                        Button(action: { changeMonth(by: -1) }) {
                            Image(systemName: "chevron.left")
                        }
                        
                        Text(monthYearString(from: selectedDate))
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                        
                        Button(action: { changeMonth(by: 1) }) {
                            Image(systemName: "chevron.right")
                        }
                    }
                    .padding()
                    
                    // 星期标题
                    HStack {
                        ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                            Text(day)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    
                    // 日期网格
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                        ForEach(daysInMonth()) { item in
                            if let date = item.date {
                                DayCell(
                                    date: date,
                                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                    completion: getCompletionPercentage(for: date)
                                )
                                .onTapGesture {
                                    selectedDate = date
                                }
                            } else {
                                Color.clear
                                    .frame(height: 40)
                            }
                        }
                    }
                }
                .padding()
                
                // 选中日期的详细信息
                if let record = viewModel.waterRecords[calendar.startOfDay(for: selectedDate)] {
                    VStack(spacing: 10) {
                        Text("饮水量: \(Int(record.amount))ml")
                            .font(.title2)
                        
                        let percentage = viewModel.dailyGoal > 0 ? (record.amount / viewModel.dailyGoal) : 0
                        Text("完成度: \(Int(min(percentage * 100, 100)))%")
                            .foregroundColor(getColorForPercentage(percentage))
                    }
                    .padding()
                } else {
                    Text("暂无记录")
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            .navigationTitle("饮水记录")
        }
    }
    
    private func getCompletionPercentage(for date: Date) -> Double? {
        if let record = viewModel.waterRecords[calendar.startOfDay(for: date)] {
            return viewModel.dailyGoal > 0 ? min(record.amount / viewModel.dailyGoal, 1.0) : 0
        }
        return nil
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        return formatter.string(from: date)
    }
    
    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func daysInMonth() -> [DateItem] {
        let interval = calendar.dateInterval(of: .month, for: selectedDate)!
        let firstDate = interval.start
        
        // 获取月初是周几（0是周日）
        let firstWeekday = calendar.component(.weekday, from: firstDate) - 1
        
        // 获取这个月总天数
        let daysInMonth = calendar.range(of: .day, in: .month, for: selectedDate)!.count
        
        var days: [DateItem] = []
        
        // 添加月初的空白天
        for i in 0..<firstWeekday {
            days.append(DateItem(id: "empty\(i)", date: nil))
        }
        
        // 添加实际的日期
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDate) {
                days.append(DateItem(id: "day\(day)", date: date))
            }
        }
        
        // 补齐最后一周
        let remainingDays = (7 - (days.count % 7)) % 7
        for i in 0..<remainingDays {
            days.append(DateItem(id: "endEmpty\(i)", date: nil))
        }
        
        return days
    }
    
    private func getColorForPercentage(_ percentage: Double) -> Color {
        switch percentage {
        case 0..<0.5: return .red
        case 0.5..<0.8: return .orange
        default: return .green
        }
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let completion: Double?
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))")
                .fontWeight(isSelected ? .bold : .regular)
            
            // 完成度指示点
            if let completion = completion {
                Circle()
                    .fill(getColorForPercentage(completion))
                    .frame(width: 8, height: 8)
            }
        }
        .frame(height: 40)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func getColorForPercentage(_ percentage: Double) -> Color {
        switch percentage {
        case 0..<0.5: return .red
        case 0.5..<0.8: return .orange
        default: return .green
        }
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: WaterViewModel
    @AppStorage("savedWeight") private var weight: String = ""
    @AppStorage("savedHeight") private var height: String = ""
    @AppStorage("reminderInterval") private var intervalString: String = "60"
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("提醒设置")) {
                    Toggle(isOn: Binding(
                        get: { viewModel.isReminderEnabled },
                        set: { viewModel.toggleReminder($0) }
                    )) {
                        Text("开启提醒")
                    }
                    
                    if viewModel.isReminderEnabled {
                        HStack {
                            Text("提醒间隔")
                            Spacer()
                            TextField("", text: $intervalString)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                                .moveTextFieldCursorToEnd()
                                .onChange(of: intervalString) { newValue in
                                    if let interval = Int(newValue) {
                                        let validInterval = max(1, min(interval, 180))
                                        viewModel.reminderInterval = validInterval
                                        viewModel.scheduleNotifications()
                                        intervalString = "\(validInterval)"
                                    }
                                }
                            Text("分钟")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("目标设置")) {
                    HStack {
                        Text("每日目标")
                        Spacer()
                        HStack(spacing: 0) {
                            TextField("", value: $viewModel.dailyGoal, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                                .moveTextFieldCursorToEnd()
                            Text("毫升")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("目标计算器")) {
                    HStack {
                        Text("体重")
                        TextField("", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .moveTextFieldCursorToEnd()
                        Text("g")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("身高")
                        TextField("", text: $height)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .moveTextFieldCursorToEnd()
                        Text("cm")
                            .foregroundColor(.gray)
                    }
                    
                    Button {
                        print("按钮被点击")
                        calculateRecommendedWaterIntake()
                    } label: {
                        HStack {
                            Spacer()
                            Text("计算推荐饮水量")
                                .foregroundColor(.white)
                                .padding()
                            Spacer()
                        }
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("设置")
            .dismissKeyboardOnTap()
            .onAppear {
                if intervalString.isEmpty {
                    intervalString = "\(viewModel.reminderInterval)"
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func calculateRecommendedWaterIntake() {
        print("开始计算")
        let trimmedWeight = weight.trimmingCharacters(in: .whitespaces)
        let trimmedHeight = height.trimmingCharacters(in: .whitespaces)
        
        print("输入值 - 体重: \(trimmedWeight), 身高: \(trimmedHeight)")
        
        guard !trimmedWeight.isEmpty && !trimmedHeight.isEmpty else {
            print("输入为空")
            alertTitle = "输入错误"
            alertMessage = "请输入体重和身高"
            showAlert = true
            return
        }
        
        guard let weightValue = Double(trimmedWeight),
              let heightValue = Double(trimmedHeight) else {
            print("转换数字失败")
            alertTitle = "输入错误"
            alertMessage = "请输入有效的数字"
            showAlert = true
            return
        }
        
        print("转换后的数值 - 体重: \(weightValue), 身高: \(heightValue)")
        
        let newGoal = viewModel.calculateRecommendedWaterIntake(
            weight: weightValue,
            height: heightValue
        )
        
        print("计算结果: \(newGoal)")
        
        viewModel.updateDailyGoal(newGoal)
        
        alertTitle = "计算完成"
        alertMessage = "每日推荐饮水量已更新为 \(Int(viewModel.dailyGoal))ml"
        showAlert = true
        print("计算完成，显示提示")
    }
}

struct DateItem: Identifiable {
    let id: String
    let date: Date?
}

#Preview {
    ContentView()
} 
