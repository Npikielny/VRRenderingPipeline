//
//  ViewController.swift
//  VRRenderPipeline
//
//  Created by Noah Pikielny on 8/29/22.
//

import UIKit
import MetalKit
import ShaderKit

class ViewController: UIViewController {

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
        
        let _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task {
                try await self.commandQueue.execute { self.pipeline }
            }
        }
    }


}

