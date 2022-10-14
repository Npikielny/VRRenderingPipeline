//
//  ViewController.swift
//  VRRenderPipeline
//
//  Created by Noah Pikielny on 8/29/22.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif
import MetalKit
import ShaderKit
#if os(iOS)
class ViewController: UIViewController {
#else
    class ViewController: UIViewController {
#endif
    let device = MTLCreateSystemDefaultDevice()!
    lazy var commandQueue = device.makeCommandQueue()!
    lazy var metalView: MTKView = {
        let view = MTKView(frame: CGRect(x: 0, y: 0, width: 512, height: 512), device: device)
        view.autoResizeDrawable = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var pipeline: SKShader = try! RenderPipeline(
        pipeline: .constructors("cornerVert", "cornerFrag", RenderPipelineDescriptor.pixelFormat(metalView.colorPixelFormat)),
        renderPassDescriptor: RenderPassDescriptor.drawable
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(metalView)
        metalView.addConstraints([
            metalView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            metalView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            metalView.topAnchor.constraint(equalTo: view.topAnchor),
            metalView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let library = device.makeDefaultLibrary()
        let editImage = library?.makeFunction(name: "editName")
        let compute = device.makeComputePipelineState(function: editImage!)
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        let enoder = commandBuffer?.makeComputeCommandEncoder()
        encoder.setBytes([0, 1], length: MemoryLayout<Int32>.stride, index: 0)
        
        let _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task {
                try await self.commandQueue.execute { self.pipeline }
            }
        }
    }


}

