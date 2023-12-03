//
//  Telemetry_Graphs.swift
//  Aerosentinel GCS
//
//  Created by Yassine Dehhani on 09/08/2023.
//

import SwiftUI
import Charts
import Combine


struct Model: Identifiable {
    let reading_name:String
    let value: Double
    let time: String
    
    var id: String{time}
}

class DataSource: ObservableObject {
    @Published var accelerationArray: [Model] = []
    @Published var gyroscopeArray: [Model] = []

    // Singleton instance to access the shared data source
    static let shared = DataSource()
}



struct Telem_Graph: View {
    @Binding var array: [Model]
    var title: String
    
    var body: some View {
        VStack {
            Text(title) // Display the title above the graph
                .font(.headline)
                .padding(.top, 8)
            Chart {
                ForEach(array) { element in
                    LineMark(
                        x: .value("Timestamp", element.time),
                        y: .value("Value", element.value)
                    )
                    .foregroundStyle(by: .value("Reading_Name", element.reading_name))
                }
            }
        }
    }
}

struct Telemetry_Graphs: View {
    @ObservedObject var dataSource = DataSource.shared

    var body: some View {
        VStack {
            Telem_Graph(array: $dataSource.accelerationArray, title: "Acceleration (g)")
                .frame(width: 290.0, height: 240.0)
                .padding(10.0)
            Telem_Graph(array: $dataSource.gyroscopeArray, title: "Angular Rate (°/s)")
                .frame(width: 290.0, height: 240.0)
                .padding(10.0)
        }
    }
}


class TelemetryHostingController: NSHostingController<Telemetry_Graphs> {
    override var representedObject: Any? {
        didSet {
            rootView = Telemetry_Graphs()
        }
    }
}


struct Telemetry_Graphs_Previews: PreviewProvider {
    static var previews: some View {
        Telemetry_Graphs()
    }
}

