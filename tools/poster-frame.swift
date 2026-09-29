import AVFoundation
import AppKit
let src = URL(fileURLWithPath: CommandLine.arguments[1])
let asset = AVURLAsset(url: src)
let gen = AVAssetImageGenerator(asset: asset)
gen.appliesPreferredTrackTransform = true
gen.maximumSize = CGSize(width: 1280, height: 720)
gen.requestedTimeToleranceBefore = .zero
gen.requestedTimeToleranceAfter = .zero
for s in CommandLine.arguments.dropFirst(3) {
  let t = CMTime(seconds: Double(s)!, preferredTimescale: 600)
  let img = try gen.copyCGImage(at: t, actualTime: nil)
  let rep = NSBitmapImageRep(cgImage: img)
  let data = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.82])!
  let out = CommandLine.arguments[2] + "/frame-\(s).jpg"
  try data.write(to: URL(fileURLWithPath: out))
  print(out, img.width, img.height)
}
