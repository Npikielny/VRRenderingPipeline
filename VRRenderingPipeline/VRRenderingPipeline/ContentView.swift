//
//  ContentView.swift
//  VRRenderingPipeline
//
//  Created by Noah Pikielny on 10/13/22.
//

import CoreMotion
import ShaderKit
import SwiftUI

struct ContentView: View {
#if os(iOS)
    static let rate = 1.0 / 60
    let gyro = CMMotionManager()
#else
    static let rate = 1.0 / 10
#endif
    static let device = MTLCreateSystemDefaultDevice()
    static let commandQueue = device?.makeCommandQueue()
    let view = MTKViewRepresentable(frame: CGRect(x: 0, y: 0, width: 512, height: 512), device: Self.device)
    
    
    @State var rotation = UnsafeMutablePointer<Float>.allocate(capacity: 2)
    
    static let hdri = Texture(Bundle.main.url(forResource: "cape_hill_4k", withExtension: "jpg")!.path)
    let intermediate = hdri.emptyCopy(name: "Intermediate", usage: [.shaderRead, .renderTarget])
    var operation: RenderBuffer!
    
    let timer = Timer.publish(every: Self.rate, on: .main, in: .default).autoconnect()
    
    @State var x = 0.0
    
    init() {
        operation = RenderBuffer(presents: true) {
            try! RenderPipeline(
                pipeline: .constructors("copyVert", "renderImages", RenderPipelineDescriptor.texture(Self.hdri)),
                fragmentTextures: [Self.hdri],
                fragmentBuffers: [
                    Buffer<MTLRenderCommandEncoder>(
                        Bytes<MTLRenderCommandEncoder>(rotation, count: 2)
                    )
                ],
                renderPassDescriptor: RenderPassDescriptor.future(texture: intermediate),
                vertexCount: 12
            )
            try! RenderPipeline(
                pipeline: .constructors("copyVert", "applyFisheye", RenderPipelineDescriptor.texture(Self.hdri)),
                fragmentTextures: [intermediate],
                renderPassDescriptor: RenderPassDescriptor.drawable,
                vertexCount: 12
            )
        }
        rotation.assign(repeating: 0, count: 2)
    }
    
    var body: some View {
        GeometryReader { geometry in
            view
                .onReceive(timer) { _ in
                    Task {
                        updateParameters()
                    }
                    draw()
                }
                .padding()
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            print("dragging \(rotation.pointee) \(rotation.successor().pointee)")
                            
                            let translation = value.translation
                            rotation.successor().pointee += Float(translation.width / geometry.size.width) * Float.pi / 4
                            rotation.pointee += Float(translation.height / geometry.size.height) * Float.pi / 4
                        }
                )
            #if os(iOS)
                .onAppear {
                    setupGyroscope()
                }
            #endif
        }
    }
    
    func draw() {
        guard let commandQueue = Self.commandQueue,
              let descriptor = view.view.currentRenderPassDescriptor,
              let drawable = view.view.currentDrawable
        else {
            print("unable to draw"); return
        }
        Task {
            do {
                try await operation.execute(
                    commandQueue: commandQueue,
                    drawable: drawable,
                    renderDescriptor: descriptor
                )
            } catch {
                print(error)
            }
        }
    }
    
#if os(iOS)
    func setupGyroscope() {
        if gyro.isGyroAvailable {
            gyro.gyroUpdateInterval = Self.rate
            gyro.startGyroUpdates()
        }
    }
#endif
    
    func updateParameters() {
#if os(iOS)
        if let data = gyro.gyroData {
            rotation.pointee += Float(data.rotationRate.z * Self.rate)
            rotation.successor().pointee -= Float(data.rotationRate.y * Self.rate)
        }
#endif
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
