import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/model.dart';
import '../../utils/image.dart';

/// fork: 移动端的「本地指针」。
///
/// 被控端的视频帧里不包含光标（`scrap::is_cursor_embedded()` 在非 X11 恒返回
/// false，`display_service::update_sync_displays()` 也硬编码 `cursor_embedded:
/// false`），所以移动端屏幕上看到的指针只能是客户端自己画出来的。而原来那个
/// 绘制（`remote_page.dart` 的 `CursorPaint`）用的是服务端 `CursorPosition`
/// 消息回报的位置 —— 等于把 1~2 个 RTT 塞进了视觉回路，并且会和虚拟鼠标面板
/// 自带的本地光标叠成「两个箭头」。
///
/// 这里改为按 [CursorModel] 的本地位置绘制，缩放/平移跟随 [CanvasModel]。
/// [CursorModel] 是 ChangeNotifier，`setCursorPosition` 触发通知后会自动重绘。
class LocalCursorPaint extends StatelessWidget {
  const LocalCursorPaint({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final m = Provider.of<CursorModel>(context);
    final c = Provider.of<CanvasModel>(context);
    final s = c.scale;

    double hotx = m.hotx;
    double hoty = m.hoty;
    var image = m.image;
    if (image == null) {
      if (preDefaultCursor.image != null) {
        image = preDefaultCursor.image;
        hotx = preDefaultCursor.image!.width / 2;
        hoty = preDefaultCursor.image!.height / 2;
      }
    }
    if (image == null) {
      return const Offstage();
    }

    // 画面缩得很小时给光标一个最小可见尺寸，和 remote_page.dart 的旧实现一致。
    const double minSize = 12.0;
    final double mins =
        minSize / (image.width > image.height ? image.width : image.height);
    final double factor = s < mins ? s / mins : 1.0;
    final double s2 = s < mins ? mins : s;
    final double adjust = c.getAdjustY();

    return CustomPaint(
      painter: ImagePainter(
        image: image,
        x: (m.x - hotx) * factor + c.x / s2,
        y: (m.y - hoty) * factor + (c.y + adjust) / s2,
        scale: s2,
      ),
    );
  }
}
