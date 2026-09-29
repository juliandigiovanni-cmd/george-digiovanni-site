import AVFoundation
let args = CommandLine.arguments
let src = URL(fileURLWithPath: args[1]), dst = URL(fileURLWithPath: args[2])
let videoBitRate = Int(args[3])!
// The iPhone original is 60 fps. Keep every other frame: a talking head needs no more,
// and at a fixed bitrate each kept frame gets twice the bits.
let fps = args.count > 4 ? Double(args[4])! : 30
try? FileManager.default.removeItem(at: dst)
let asset = AVURLAsset(url: src)
let vTrack = asset.tracks(withMediaType: .video)[0]
let aTrack = asset.tracks(withMediaType: .audio).first
let reader = try AVAssetReader(asset: asset)
let writer = try AVAssetWriter(outputURL: dst, fileType: .mp4)
writer.shouldOptimizeForNetworkUse = true   // moov atom first, so playback starts before download ends

let vOut = AVAssetReaderTrackOutput(track: vTrack, outputSettings: [
  kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange])
vOut.alwaysCopiesSampleData = false
reader.add(vOut)
let vIn = AVAssetWriterInput(mediaType: .video, outputSettings: [
  AVVideoCodecKey: AVVideoCodecType.h264,
  AVVideoWidthKey: 1280, AVVideoHeightKey: 720,
  AVVideoScalingModeKey: AVVideoScalingModeResizeAspect,
  AVVideoCompressionPropertiesKey: [
    AVVideoAverageBitRateKey: videoBitRate,
    // Explicit 4.0. AutoLevel labelled 720p60 as 3.1, which is below spec for that
    // frame rate and can make strict decoders refuse the stream.
    AVVideoProfileLevelKey: AVVideoProfileLevelH264High40,
    AVVideoExpectedSourceFrameRateKey: fps,
    AVVideoMaxKeyFrameIntervalDurationKey: 2,
  ]])
vIn.transform = vTrack.preferredTransform
vIn.expectsMediaDataInRealTime = false
writer.add(vIn)

var pairs: [(AVAssetWriterInput, AVAssetReaderOutput, String)] = [(vIn, vOut, "video")]
var nextFrameTime = 0.0
if let aTrack = aTrack {
  let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(aTrack.formatDescriptions[0] as! CMAudioFormatDescription)!.pointee
  print("audio source:", asbd.mSampleRate, "Hz,", asbd.mChannelsPerFrame, "ch")
  let aOut = AVAssetReaderTrackOutput(track: aTrack, outputSettings: [AVFormatIDKey: kAudioFormatLinearPCM])
  reader.add(aOut)
  let aIn = AVAssetWriterInput(mediaType: .audio, outputSettings: [
    AVFormatIDKey: kAudioFormatMPEG4AAC,
    AVSampleRateKey: asbd.mSampleRate,
    AVNumberOfChannelsKey: min(Int(asbd.mChannelsPerFrame), 2),
    AVEncoderBitRateKey: 128000])
  aIn.expectsMediaDataInRealTime = false
  writer.add(aIn)
  pairs.append((aIn, aOut, "audio"))
}

guard writer.startWriting() else { fatalError("writer: \(String(describing: writer.error))") }
guard reader.startReading() else { fatalError("reader: \(String(describing: reader.error))") }
writer.startSession(atSourceTime: .zero)

let group = DispatchGroup()
for (input, output, label) in pairs {
  group.enter()
  var done = false
  input.requestMediaDataWhenReady(on: DispatchQueue(label: label)) {
    while !done && input.isReadyForMoreMediaData {
      guard let sb = output.copyNextSampleBuffer() else {
        done = true; input.markAsFinished(); group.leave(); return
      }
      if label == "video" {
        let t = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sb))
        if t + 0.25 / fps < nextFrameTime { continue }
        nextFrameTime = max(nextFrameTime + 1 / fps, t + 0.5 / fps)
      }
      if !input.append(sb) {
        print("\(label) append failed:", writer.error as Any)
        done = true; input.markAsFinished(); group.leave(); return
      }
    }
  }
}
group.wait()
let sem = DispatchSemaphore(value: 0)
writer.finishWriting { sem.signal() }
sem.wait()
print("reader status:", reader.status.rawValue, "writer status:", writer.status.rawValue, writer.error as Any)
