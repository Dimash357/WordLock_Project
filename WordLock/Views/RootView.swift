import SwiftUI

struct RootView: View {
    @EnvironmentObject var model: AppModel
    @AppStorage("onboarded") private var onboarded = false

    var body: some View {
        ZStack {
            TabView {
                TodayView()
                    .tabItem { Label("Сегодня", systemImage: "sun.max.fill") }
                DictionaryView()
                    .tabItem { Label("Словарь", systemImage: "books.vertical.fill") }
                SettingsView()
                    .tabItem { Label("Настройки", systemImage: "gearshape.fill") }
            }
            .fullScreenCover(item: $model.session) { kind in
                SessionContainer(kind: kind)
            }
            .sheet(item: $model.cardRef) { ref in
                CardDetailView(cardID: ref.id)
            }

            if !onboarded || model.showOnboarding {
                OnboardingView {
                    onboarded = true
                    model.showOnboarding = false
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(.easeInOut, value: onboarded)
        .animation(.easeInOut, value: model.showOnboarding)
    }
}
