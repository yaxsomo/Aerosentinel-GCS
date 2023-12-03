//
//  Stage_Control.swift
//  Aerosentinel GCS
//
//  Created by Yassine Dehhani on 10/08/2023.
//

import SwiftUI


let stages: [String] = ["Preflight","Countdown Sequence","Liftoff", "Propulsion End", "Apogee", "Parachute Deployment", "Reentry Phase","Landing"] // Add your stage labels here
let minimum_progression_bar: Float = 0.478
let maximum_progression_bar: Float = 0.723


class Stage_Ctrl: ObservableObject {
    @Published var Stage: String = ""
    @Published var progress_override: Float = 0.0
    
    // Singleton instance to access the shared data source
    static let shared = Stage_Ctrl()
}

struct Stage_Control: View {
    @ObservedObject var dataSource = Stage_Ctrl.shared
    //@State var progressValue: Float = 0.478
    @State private var degress: Double = -110
    
    var body: some View {
        ZStack {
            Text(dataSource.Stage) // Use the Stage variable here
                .bold()
                .font(.custom("Aquire", size: 22))
                .foregroundColor(Color.init(hex: "E0E0E0"))
            ProgressBar(progress: $dataSource.progress_override)
                .frame(width: 810.0, height: 180.0)
        }
    }
    
    struct ProgressBar: View {
        @Binding var progress: Float
        


        var body: some View {
            ZStack {
                Circle()
                    .trim(from: 0.3, to: 0.9)
                    .stroke(style: StrokeStyle(lineWidth: 6.0)) // Adjust the stroke width
                    .opacity(0.3)
                    .foregroundColor(Color.gray)
                    .rotationEffect(.degrees(54.5))
                    .offset(y: 450)
                    .frame(width: 1000.0, height: 1000.0) // Adjust the frame size

                Circle()
                    .trim(from: 0.3, to: CGFloat(self.progress))
                    .stroke(style: StrokeStyle(lineWidth: 6.0)) // Adjust the stroke width
                    .fill(AngularGradient(gradient: Gradient(stops: [
                        .init(color: Color.init(hex: "ED4D4D"), location: 0.39000002),
                        .init(color: Color.init(hex: "E59148"), location: 0.48000002),
                        .init(color: Color.init(hex: "EFBF39"), location: 0.5999999),
                        .init(color: Color.init(hex: "EEED56"), location: 0.7199998),
                        .init(color: Color.init(hex: "32E1A0"), location: 0.8099997)]), center: .center))
                    .rotationEffect(.degrees(54.5))
                    .offset(y: 450)
                    .frame(width: 1000.0, height: 1000.0) // Adjust the frame size
                    ForEach(stages.indices, id: \.self) { index in
                        StageIndicator(index: index, totalCount: stages.count)
                            .offset(x: 145 ,y: 500)
                            .rotationEffect(.degrees(-90))
                       
                    }
            }
        }
    }
    
    

}




struct StageIndicator: View {
    var index: Int
    var totalCount: Int
    let circleRadius: CGFloat = 7.0 // Adjust the radius of the stage indicators

    var body: some View {
        let startAngle = -45.0 // Start angle for the upper right part
        let angleRange = 90.0 // Angle range for the upper right part
        let angle = startAngle + (Double(index) / Double(totalCount - 1)) * angleRange
        let rotation = Angle(degrees: angle)

        Circle()
            .fill(Color.blue) // Customize the color of the stage indicators
            .frame(width: circleRadius * 2, height: circleRadius * 2)
            .position(x: 405 * cos(rotation.radians), y: 460 * sin(rotation.radians)) // Position using polar coordinates
    }
}


struct Stage_Control_Previews: PreviewProvider {
    static var previews: some View {
        Stage_Control()
    }
}

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


class StageControl_Controller: NSHostingController<Stage_Control> {
    override var representedObject: Any? {
        didSet {
            rootView = Stage_Control()
        }
    }
}

