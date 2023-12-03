//
//  Level_Indicators.swift
//  Aerosentinel GCS
//
//  Created by Yassine Dehhani on 09/08/2023.
//

import SwiftUI

struct Level_Indicators: View {
    @State var speed_progressValue: Float = 0.0
    @State var altitude_progressValue: Float = 0.0
    
    var body: some View {
        HStack{
            Speed(progress: self.$speed_progressValue)
                .frame(width: 80.0, height: 80.0)
                .padding(10.0).onAppear(){
                    self.speed_progressValue = 0.1
                }
            Altitude(progress: self.$altitude_progressValue)
                .frame(width: 80.0, height: 80.0)
                .padding(10.0).onAppear(){
                    self.altitude_progressValue = 0.5
                }
        }
    }
}

class HostingController: NSHostingController<Level_Indicators> {
    override var representedObject: Any? {
        didSet {
            rootView = Level_Indicators()
        }
    }
}

struct Speed: View {
    @Binding var progress: Float
    var color: Color = Color.green
    
    
    var body: some View{
        ZStack{
            Circle()
                .stroke(lineWidth: 10.0)
                .opacity(0.20)
                .foregroundColor(Color.gray)
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 10.0, lineCap: .round, lineJoin: .round))
                .foregroundColor(color)
                .rotationEffect(Angle(degrees: 270))
                .animation(.easeInOut, value: 2.0)
        }
    }
    
    
}
struct Altitude: View {
    @Binding var progress: Float
    var color: Color = Color.green
    
    
    var body: some View{
        ZStack{
            Circle()
                .stroke(lineWidth: 10.0)
                .opacity(0.20)
                .foregroundColor(Color.gray)
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 10.0, lineCap: .round, lineJoin: .round))
                .foregroundColor(color)
                .rotationEffect(Angle(degrees: 270))
                .animation(.easeInOut, value: 2.0)
        }
    }
    
    
}


struct Level_Indicators_Previews: PreviewProvider {
    static var previews: some View {
        Level_Indicators()
    }
}
