import HealthKit
import Foundation

class HealthKitManager: ObservableObject {
    private var healthStore: HKHealthStore?
    @Published var isWorkingOut: Bool = false
    
    init() {
        // 检查设备是否支持 HealthKit
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
            requestAuthorization()
        } else {
            print("此设备不支持 HealthKit")
        }
    }
    
    func requestAuthorization() {
        guard let healthStore = healthStore else { return }
        
        // 请求访问运动数据的权限
        let workoutType = HKWorkoutType.workoutType()
        let types = Set([workoutType])
        
        // 在主线程执行授权请求
        DispatchQueue.main.async {
            healthStore.requestAuthorization(toShare: nil, read: types) { success, error in
                if success {
                    print("HealthKit 授权成功")
                    self.startWorkoutMonitoring()
                } else if let error = error {
                    print("HealthKit 授权失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func startWorkoutMonitoring() {
        guard let healthStore = healthStore else { return }
        let workoutType = HKWorkoutType.workoutType()
        
        // 创建观察者查询
        let query = HKObserverQuery(sampleType: workoutType, predicate: nil) { [weak self] query, completionHandler, error in
            if let error = error {
                print("观察者查询错误: \(error.localizedDescription)")
                completionHandler()
                return
            }
            
            self?.checkCurrentWorkout()
            completionHandler()
        }
        
        // 启用后台更新
        healthStore.enableBackgroundDelivery(for: workoutType, frequency: .immediate) { success, error in
            if let error = error {
                print("启用后台更新失败: \(error.localizedDescription)")
            }
        }
        
        // 执行查询
        do {
            try healthStore.execute(query)
        } catch {
            print("执行查询失败: \(error.localizedDescription)")
        }
    }
    
    private func checkCurrentWorkout() {
        guard let healthStore = healthStore else { return }
        let workoutType = HKWorkoutType.workoutType()
        
        let now = Date()
        let past = Calendar.current.date(byAdding: .minute, value: -30, to: now)!
        
        let predicate = HKQuery.predicateForSamples(withStart: past, end: now, options: .strictEndDate)
        
        let query = HKSampleQuery(sampleType: workoutType,
                                predicate: predicate,
                                limit: 1,
                                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { [weak self] query, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("查询运动数据失败: \(error.localizedDescription)")
                    return
                }
                self?.isWorkingOut = samples?.isEmpty == false
            }
        }
        
        healthStore.execute(query)
    }
} 