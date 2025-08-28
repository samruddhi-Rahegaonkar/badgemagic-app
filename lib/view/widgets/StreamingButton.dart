import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StreamingButton extends StatefulWidget {
  final VoidCallback onPressed;

  const StreamingButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  _StreamingButtonState createState() => _StreamingButtonState();
}

class _StreamingButtonState extends State<StreamingButton> {
  bool _isStreaming = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isStreaming ? null : _handleTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2.r),
          color: _isStreaming ? Colors.orange : Colors.green,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isStreaming) ...[
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 8.w),
            ],
            Text(
              _isStreaming ? 'Streaming...' : 'Stream',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTap() async {
    setState(() {
      _isStreaming = true;
    });

    try {
      widget.onPressed();
    } finally {
      if (mounted) {
        setState(() {
          _isStreaming = false;
        });
      }
    }
  }
}
