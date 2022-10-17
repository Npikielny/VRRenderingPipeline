//
//  ContentView.swift
//  VRRenderingPipeline
//
//  Created by Noah Pikielny on 10/13/22.
//
import CoreMotion
import MetalKit
import ShaderKit
import SwiftUI

enum Eye: Int32 {
    case left
    case right
    case none
}

struct ContentView: View {
#if os(iOS)
    static let rate = 1.0 / 60
    let gyro = CMMotionManager()
#else
    static let rate = 1.0 / 10
#endif
    static let device = MTLCreateSystemDefaultDevice()
    static let commandQueue = device?.makeCommandQueue()
    let view = MTKViewRepresentable(frame: CGRect(x: 0, y: 0, width: 512 * 2, height: 512), device: Self.device)
    
    @State var rotation = UnsafeMutablePointer<Float>.allocate(capacity: 2)
    
    static let hdri = Texture(Bundle.main.url(forResource: "cape_hill_4k", withExtension: "jpg")!.path)
    var operation: RenderBuffer!
    
    let timer = Timer.publish(every: Self.rate, on: .main, in: .default).autoconnect()
    
    @State var x = 0.0
    
    init(rendersVR: Bool = true) {
        
        if rendersVR {
            operation = try! RenderBuffer(presents: true) {
                let destination = Self.hdri.emptyCopy(name: "destination")
                let unwrapped = destination.unwrap(device: Self.device!)
                for eye in [Eye.left, Eye.right] {
                    let intermediate = Self.hdri.emptyCopy(
                        name: "Intermediate",
                        width: unwrapped.width / 2,
                        usage: [.shaderRead, .renderTarget]
                    )
                    let intermediate2 = Self.hdri.emptyCopy(
                        name: "Intermediate 2",
                        width: unwrapped.width / 2,
                        usage: [.shaderRead, .renderTarget]
                    )
                    let eyeBuffer = Buffer<MTLRenderCommandEncoder>(Bytes(eye.rawValue))
                    
                    try RenderPipeline(
                        pipeline: .constructors("imageVert", "renderImages", RenderPipelineDescriptor.texture(Self.hdri)),
                        fragmentTextures: [Self.hdri],
                        fragmentBuffers: [Buffer(Bytes(rotation, count: 2)), eyeBuffer],
                        renderPassDescriptor: RenderPassDescriptor.future(texture: intermediate),
                        vertexCount: 6
                    )
                    
                    try RenderPipeline(
                        pipeline: RenderPipeline.Pipeline.constructors(
                            "imageVert",
                            "applyFisheye",
                            RenderPipelineDescriptor.texture(Self.hdri)
                        ),
                        fragmentTextures: [intermediate],
                        renderPassDescriptor: RenderPassDescriptor.future(texture: intermediate2),
                        
                        vertexCount: 6
                    )
                    
                    let size = MTLSize(width: unwrapped.width / 2, height: unwrapped.height, depth: 1)
                    let origin = eye == .left ? MTLOrigin(x: 0, y: 0, z: 0) : MTLOrigin(x: size.width + size.width % 2, y: 0, z: 0)
                    BlitPipeline(
                        .partialCopy(
                            intermediate2,
                            0,
                            MTLOrigin(x: 0, y: 0, z: 0),
                            size,
                            destination,
                            0,
                            origin
                        )
                    )
                }
                
                try RenderPipeline(
                    pipeline: .constructors("imageVert", "copyToDrawable", RenderPipelineDescriptor.texture(Self.hdri)),
                    fragmentTextures: [destination],
                    renderPassDescriptor: RenderPassDescriptor.drawable,
                    vertexCount: 6
                )
            }
        } else {
            operation = RenderBuffer(presents: true) {
                try! RenderPipeline(
                    pipeline: .constructors("copyVert", "renderImages", RenderPipelineDescriptor.texture(Self.hdri)),
                    fragmentTextures: [Self.hdri],
                    fragmentBuffers: [
                        Buffer<MTLRenderCommandEncoder>(Bytes(rotation, count: 2)),
                        Buffer(Bytes(Eye.none.rawValue))
                    ],
                    renderPassDescriptor: RenderPassDescriptor.drawable,
                    vertexCount: 6
                )
            }
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
            rotation.successor().pointee -= Float(data.rotationRate.x * Self.rate)
        }
#endif
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
