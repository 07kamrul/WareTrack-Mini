import 'package:flutter/material.dart';

class ScannerLayoutMetrics {
  const ScannerLayoutMetrics({
    required this.contentMaxWidth,
    required this.pagePadding,
    required this.sectionGap,
    required this.componentGap,
    required this.pageColumns,
    required this.previewHeight,
    required this.cardRadius,
    required this.innerRadius,
    required this.bannerHeight,
    required this.buttonHeight,
    required this.secondaryButtonHeight,
    required this.cardPadding,
    required this.inputHorizontalPadding,
    required this.inputVerticalPadding,
    required this.inputMaxLines,
    required this.modeGap,
  });

  final double contentMaxWidth;
  final double pagePadding;
  final double sectionGap;
  final double componentGap;
  final int pageColumns;
  final double previewHeight;
  final double cardRadius;
  final double innerRadius;
  final double bannerHeight;
  final double buttonHeight;
  final double secondaryButtonHeight;
  final double cardPadding;
  final double inputHorizontalPadding;
  final double inputVerticalPadding;
  final int inputMaxLines;
  final double modeGap;

  bool get useSplitLayout => pageColumns > 1;

  factory ScannerLayoutMetrics.fromConstraints(BoxConstraints constraints) {
    final base = ScannerLayoutMetrics.fromWidth(constraints.maxWidth);
    final availableHeight = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : base.previewHeight;
    final maxPreviewHeight = base.useSplitLayout
        ? availableHeight * 0.66
        : availableHeight * 0.38;
    final minPreviewHeight = constraints.maxWidth < 360 ? 210.0 : 240.0;
    final responsivePreviewHeight = base.previewHeight
        .clamp(
          minPreviewHeight,
          maxPreviewHeight.clamp(minPreviewHeight, base.previewHeight),
        )
        .toDouble();

    return base.copyWith(previewHeight: responsivePreviewHeight);
  }

  ScannerLayoutMetrics copyWith({double? previewHeight}) {
    return ScannerLayoutMetrics(
      contentMaxWidth: contentMaxWidth,
      pagePadding: pagePadding,
      sectionGap: sectionGap,
      componentGap: componentGap,
      pageColumns: pageColumns,
      previewHeight: previewHeight ?? this.previewHeight,
      cardRadius: cardRadius,
      innerRadius: innerRadius,
      bannerHeight: bannerHeight,
      buttonHeight: buttonHeight,
      secondaryButtonHeight: secondaryButtonHeight,
      cardPadding: cardPadding,
      inputHorizontalPadding: inputHorizontalPadding,
      inputVerticalPadding: inputVerticalPadding,
      inputMaxLines: inputMaxLines,
      modeGap: modeGap,
    );
  }

  factory ScannerLayoutMetrics.fromWidth(double width) {
    if (width >= 1180) {
      return const ScannerLayoutMetrics(
        contentMaxWidth: 1280,
        pagePadding: 28,
        sectionGap: 28,
        componentGap: 18,
        pageColumns: 2,
        previewHeight: 500,
        cardRadius: 24,
        innerRadius: 18,
        bannerHeight: 52,
        buttonHeight: 60,
        secondaryButtonHeight: 130,
        cardPadding: 24,
        inputHorizontalPadding: 16,
        inputVerticalPadding: 16,
        inputMaxLines: 3,
        modeGap: 16,
      );
    }

    if (width >= 820) {
      return const ScannerLayoutMetrics(
        contentMaxWidth: 980,
        pagePadding: 24,
        sectionGap: 24,
        componentGap: 16,
        pageColumns: 2,
        previewHeight: 400,
        cardRadius: 22,
        innerRadius: 16,
        bannerHeight: 45,
        buttonHeight: 56,
        secondaryButtonHeight: 110,
        cardPadding: 20,
        inputHorizontalPadding: 16,
        inputVerticalPadding: 14,
        inputMaxLines: 3,
        modeGap: 14,
      );
    }

    if (width >= 420) {
      return const ScannerLayoutMetrics(
        contentMaxWidth: 720,
        pagePadding: 20,
        sectionGap: 20,
        componentGap: 14,
        pageColumns: 1,
        previewHeight: 320,
        cardRadius: 20,
        innerRadius: 14,
        bannerHeight: 40,
        buttonHeight: 52,
        secondaryButtonHeight: 96,
        cardPadding: 18,
        inputHorizontalPadding: 14,
        inputVerticalPadding: 14,
        inputMaxLines: 2,
        modeGap: 12,
      );
    }

    return const ScannerLayoutMetrics(
      contentMaxWidth: 680,
      pagePadding: 16,
      sectionGap: 18,
      componentGap: 12,
      pageColumns: 1,
      previewHeight: 260,
      cardRadius: 18,
      innerRadius: 12,
      bannerHeight: 38,
      buttonHeight: 50,
      secondaryButtonHeight: 88,
      cardPadding: 16,
      inputHorizontalPadding: 12,
      inputVerticalPadding: 12,
      inputMaxLines: 2,
      modeGap: 10,
    );
  }
}
