#!/usr/bin/env swift
import AppKit
import CoreGraphics

// Genera l'icona dell'app: sfondo squircle con gradiente blu/turchese in stile macOS
// e simbolo "wand.and.sparkles" al centro. Esporta PuliziaMac.iconset/icon_1024x1024.png,
// pronto per `iconutil -c icns`.

let size = 1024.0
let pixelSize = Int(size)

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: pixelSize,
    pixelsHigh: pixelSize,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fatalError("Impossibile creare il bitmap")
}
bitmap.size = NSSize(width: size, height: size)

guard let ctx = NSGraphicsContext(bitmapImageRep: bitmap)?.cgContext else {
    fatalError("Nessun contesto grafico disponibile")
}
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

// Squircle di sfondo (stile icone macOS Big Sur+): angolo ~22.5% della dimensione.
let cornerRadius = size * 0.225
let rect = CGRect(x: 0, y: 0, width: size, height: size)
let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
ctx.addPath(path)
ctx.clip()

let colors = [
    NSColor(calibratedRed: 0.20, green: 0.55, blue: 0.95, alpha: 1.0).cgColor,
    NSColor(calibratedRed: 0.10, green: 0.80, blue: 0.75, alpha: 1.0).cgColor
]
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0])!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])

// Simbolo centrale.
let symbolConfig = NSImage.SymbolConfiguration(pointSize: size * 0.5, weight: .medium)
    .applying(.init(paletteColors: [.white]))
if let symbol = NSImage(systemSymbolName: "wand.and.sparkles", accessibilityDescription: nil)?
    .withSymbolConfiguration(symbolConfig) {
    let symbolSize = symbol.size
    let origin = CGPoint(x: (size - symbolSize.width) / 2, y: (size - symbolSize.height) / 2)
    symbol.draw(at: origin, from: .zero, operation: .sourceOver, fraction: 1.0)
}

NSGraphicsContext.current?.flushGraphics()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Impossibile generare il PNG")
}

let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "PuliziaMac.iconset"
let fm = FileManager.default
try? fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
let outputPath = outputDir + "/icon_1024x1024.png"
try! png.write(to: URL(fileURLWithPath: outputPath))
print("Scritto \(outputPath)")
