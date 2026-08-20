// import 'package:flutter/material.dart';
// import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
// import 'package:get/get.dart';
// import 'package:keep_link/core/config/theme/app_colors.dart';

// class ExpandableText extends StatelessWidget {
//   ExpandableText({
//     super.key,
//     this.lineHeight = 1.5,
//     required this.text,
//     this.trimLines = 3,
//     this.fontSize = 14,
//     this.fontSizeReadMore = 15,
//     this.colorText,
//     this.fontWeight = FontWeight.w400,
//     this.fontWeightReadMore = FontWeight.w400,
//   });

//   final double lineHeight;
//   final String text;
//   final int trimLines;
//   final double fontSize;
//   final double fontSizeReadMore;
//   final FontWeight fontWeight;
//   final FontWeight fontWeightReadMore;
//   final Color? colorText;

//   // Use GetX's reactive state management
//   final RxBool _isExpanded = false.obs;

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (BuildContext context, BoxConstraints constraints) {
//         final textStyle = TextStyle(
//           color: colorText,
//           fontSize: fontSize,
//           fontWeight: fontWeight,
//           height: lineHeight,
//         );

//         // Use a TextPainter to check if the text exceeds trimLines
//         final textPainter = TextPainter(
//           text: TextSpan(text: text, style: textStyle),
//           textDirection: TextDirection.ltr,
//           maxLines: trimLines,
//           ellipsis: '...',
//         )..layout(maxWidth: constraints.maxWidth);

//         if (textPainter.didExceedMaxLines) {
//           return Obx(() {
//             // Show full HTML when expanded, or trimmed version when collapsed
//             final String displayedText = _isExpanded.value
//                 ? text
//                 : text.substring(
//                     0,
//                     textPainter
//                         .getPositionForOffset(
//                           Offset(
//                             constraints.maxWidth,
//                             textPainter.size.height,
//                           ),
//                         )
//                         .offset);

//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 HtmlWidget(
//                   displayedText,
//                   textStyle: textStyle,
//                   customStylesBuilder: (element) {
//                     return {
//                       'line-height': '$lineHeight',
//                       'font-size': '${fontSize}px',
//                       'color': AppColors.t700.toString(),
//                     };
//                   },
//                 ),
//                 GestureDetector(
//                   onTap: () => _isExpanded.value = !_isExpanded.value,
//                   child: Text(
//                     _isExpanded.value
//                         ? "Thu gọn"
//                         : "Xem thêm",
//                     style: TextStyle(
//                       color: AppColors.t700,
//                       fontWeight: fontWeightReadMore,
//                       fontSize: fontSizeReadMore,
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           });
//         } else {
//           return HtmlWidget(
//             text,
//             textStyle: textStyle,
//             customStylesBuilder: (element) {
//               return {
//                 'line-height': '$lineHeight',
//                 'font-size': '${fontSize}px',
//                 'color': AppColors.t700.toString(),
//               };
//             },
//           );
//         }
//       },
//     );
//   }
// }
