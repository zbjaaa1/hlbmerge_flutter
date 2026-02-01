import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';

import 'beans/Pair.dart';
import 'ffmpeg_hl_method_channel.dart';
import 'ffmpeg_hl_platform_interface.dart';

class FfmpegHlCommon extends FfmpegHlPlatform {
  final _methodChannel = MethodChannelFfmpegHl();

  @override
  Future<String?> getAvcodecCfg() async {
    FFmpegSession session = await FFmpegKit.execute('-version');
    final output = await session.getOutput();
    return Future.value(output);
  }

  @override
  Future<Pair<bool, String>> mergeVideos(
      List<String> videoPaths, String outputPath) async {

    final concatInput = videoPaths.join("|");

    final List<String> cmds = [
      '-i',
      '"concat:$concatInput"',
      '-c',
      'copy',
      outputPath // 无论路径是什么，都会被当作单一参数
    ];
    FFmpegSession session = await FFmpegKit.executeWithArguments(cmds);
    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      return Future.value(Pair(true, "合并成功"));
    } else {
      return Future.value(Pair(false, "合并失败"));
    }
  }

  @override
  Future<Pair<bool, String>> mergeAudioVideo(
      String audioPath, String videoPath, String outputPath) async {
  final List<String> cmds = [
  '-y',

  // ✅ 核心容错
  '-err_detect', 'ignore_err',
  '-fflags', '+discardcorrupt',

  // ✅ 限制音视频最大交错间隔（关键）
  '-max_interleave_delta', '0',

  // 输入顺序：video -> audio
  '-i', videoPath,
  '-i', audioPath,

  // 明确映射
  '-map', '0:v:0',
  '-map', '1:a:0',

  // 不重编码
  '-c', 'copy',

  // 可选：对在线播放 / Media3 更友好
  '-movflags', '+faststart',

  outputPath,
];
    FFmpegSession session = await FFmpegKit.executeWithArguments(cmds);
    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      return Future.value(Pair(true, "合并成功"));
    } else {
      var errMsg = await session.getFailStackTrace();
      if(errMsg == null || errMsg.trim().isEmpty){
        final logs = await session.getLogs();
        //打印
        // for (var log in logs) {
        //   print(log.getMessage());
        // }
        errMsg = logs.last.getMessage();
      }
      return Future.value(Pair(false, "$errMsg"));
    }
  }

  @override
  Future<String?> getPlatformVersion() {
    return _methodChannel.getPlatformVersion();
  }
}
