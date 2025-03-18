import Foundation
import UserNotifications
import SwiftUI
import Combine

class WaterViewModel: ObservableObject {
    @Published var todayWaterAmount: Double = 0
    @Published var dailyGoal: Double = 2000
    @Published var reminderInterval: Int = 60  // 这是分钟单位的默认值
    @Published var isReminderEnabled: Bool = true
    @Published var quickAddAmounts: [Int] = [100, 350]
    @Published var waterRecords: [Date: WaterRecord] = [:]
    @Published var healthKitManager = HealthKitManager()
    
    private let userDefaults = UserDefaults.standard
    private let calendar = Calendar.current
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        loadData()  // 先加载数据
        setupNotifications()  // 再设置通知
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    // MARK: - 数据持久化
    private func loadData() {
        // 如果有保存的值就使用保存的值，否则使用默认值60分钟
        if let savedInterval = userDefaults.string(forKey: "reminderInterval"),
           let interval = Int(savedInterval) {
            reminderInterval = interval
        } else {
            reminderInterval = 60  // 默认60分钟
            userDefaults.set("60", forKey: "reminderInterval")
        }
        
        dailyGoal = userDefaults.double(forKey: "dailyGoal")
        isReminderEnabled = userDefaults.bool(forKey: "isReminderEnabled")  // 加载提醒开关状态
        if let data = userDefaults.data(forKey: "waterRecords"),
           let decoded = try? JSONDecoder().decode([Date: WaterRecord].self, from: data) {
            waterRecords = decoded
        }
        loadTodayAmount()
    }
    
    func saveData() {
        userDefaults.set(dailyGoal, forKey: "dailyGoal")
        userDefaults.set("\(reminderInterval)", forKey: "reminderInterval")
        userDefaults.set(isReminderEnabled, forKey: "isReminderEnabled")  // 保存提醒开关状态
        if let encoded = try? JSONEncoder().encode(waterRecords) {
            userDefaults.set(encoded, forKey: "waterRecords")
        }
    }
    
    // MARK: - 饮水记录管理
    func addWater(_ amount: Double) {
        todayWaterAmount += amount
        updateTodayRecord()
    }
    
    private func loadTodayAmount() {
        if let todayRecord = waterRecords[calendar.startOfDay(for: Date())] {
            todayWaterAmount = todayRecord.amount
        } else {
            todayWaterAmount = 0
        }
    }
    
    private func updateTodayRecord() {
        let today = calendar.startOfDay(for: Date())
        let record = WaterRecord(date: today, amount: todayWaterAmount)
        waterRecords[today] = record
        saveData()
    }
    
    // MARK: - 通知管理
    func setupNotifications() {
        // 请求通知权限
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("通知权限已获取")
                    self.isReminderEnabled = true
                    self.scheduleNotifications()
                } else {
                    print("通知权限被拒绝")
                    self.isReminderEnabled = false
                }
                self.saveData()
            }
        }
    }
    
    func scheduleNotifications() {
        guard isReminderEnabled else { return }
        
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // 基础提醒间隔（分钟）
        let baseInterval = reminderInterval
        
        let content = UNMutableNotificationContent()
        content.sound = .default
        content.badge = NSNumber(value: 1)
        
        // 根据是否在运动设置不同的提醒内容和间隔
        if healthKitManager.isWorkingOut {
            content.title = "运动期间要多补充水分！"
            content.body = "运动时建议每15-20分钟饮用100-200ml水"
            // 运动时缩短提醒间隔
            let workoutInterval = min(baseInterval, 15) // 最长15分钟
            
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(workoutInterval * 60),
                repeats: true
            )
            
            let request = UNNotificationRequest(
                identifier: "workoutWaterReminder",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request)
            
        } else {
            content.title = "该喝水了！"
            content.body = "保持规律饮水习惯，让身体更健康！"
            
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(baseInterval * 60),
                repeats: true
            )
            
            let request = UNNotificationRequest(
                identifier: "waterReminder",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    func toggleReminder(_ isEnabled: Bool) {
        isReminderEnabled = isEnabled
        saveData()
        
        if isEnabled {
            // 如果开启提醒，先检查权限
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    switch settings.authorizationStatus {
                    case .authorized:
                        // 已有权限，直接设置通知
                        self.scheduleNotifications()
                    case .notDetermined:
                        // 未决定，请求权限
                        self.setupNotifications()
                    case .denied:
                        // 权限被拒绝，提示用户去设置中开启
                        print("通知权限被拒绝，请在设置中开启")
                        self.isReminderEnabled = false
                        self.saveData()
                    default:
                        break
                    }
                }
            }
        } else {
            // 关闭提醒，移除所有通知
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }
    
    // MARK: - 目标计算
    func calculateRecommendedWaterIntake(weight: Double, height: Double) -> Double {
        // 使用更准确的计算公式
        // 这里使用简单的计算公式：体重(kg) * 30ml + 身高(cm) * 0.1ml
        let baseOnWeight = weight * 30
        let baseOnHeight = height * 0.1
        return baseOnWeight + baseOnHeight
    }
    
    func updateDailyGoal(_ newGoal: Double) {
        dailyGoal = newGoal
        saveData()
    }
    
    // 添加：清除角标的方法
    func clearBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    // 添加观察运动状态变化的方法
    func observeWorkoutStatus() {
        healthKitManager.$isWorkingOut
            .sink { [weak self] isWorkingOut in
                if isWorkingOut {
                    print("检测到正在运动，调整提醒频率")
                    self?.scheduleNotifications()
                } else {
                    print("运动结束，恢复正常提醒频率")
                    self?.scheduleNotifications()
                }
            }
            .store(in: &cancellables)
    }
} 