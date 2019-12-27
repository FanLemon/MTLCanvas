//
//  ViewController.swift
//  MTLCanvas
//
//  Created by Fan on 2019/12/11.
//  Copyright © 2019 Yoko. All rights reserved.
//

import Cocoa
import MetalKit



class ViewController: NSViewController {

    @IBOutlet var canvasView: MTKView!
    
    var render: CanvasRender!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return
        }
        
        canvasView.device = defaultDevice
        canvasView.colorPixelFormat = CanvasRender.colorPixelFormat
        canvasView.sampleCount = CanvasRender.sampleCount
        canvasView.isPaused = true
        canvasView.enableSetNeedsDisplay = false
        
        render = CanvasRender(aDevice: defaultDevice)
        canvasView.delegate = render
        
        canvasView.draw()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func draggedSize(_ sender: Any) {
        if let slider = sender as? NSSlider {
            let value = slider.floatValue
            render.setPointSize(size: value)
            canvasView.draw()
        }
    }
    
    @IBAction func draggedStrite(_ sender: Any) {
        if let slider = sender as? NSSlider {
            let value = slider.intValue
            render.setSpriteCounts(count: Int(value))
            canvasView.draw()
        }
    }
}

