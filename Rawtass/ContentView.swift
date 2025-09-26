import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "swift")
                .imageScale(.large)
                .foregroundStyle(.tint)
                .font(.system(size: 64))
            
            Text("Welcome to Rawtass")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("A little different.")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Text("UNDER DEVELOPMENT")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 20)
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
}

#Preview {
    ContentView()
}