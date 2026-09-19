import 'package:flutter/material.dart';
import 'app_colors.dart';
import '../utils/responsive.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle h1 = TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
      letterSpacing: -0.5);

  static const TextStyle h2 = TextStyle(
      fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary);

  static const TextStyle h3 = TextStyle(
      fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  static const TextStyle body = TextStyle(
      fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary);

  static const TextStyle bodyMuted = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary);

  static const TextStyle caption = TextStyle(
      fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textHint);

  static const TextStyle label = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: 0.1);

  static TextStyle responsiveH1(BuildContext context) =>
      h1.copyWith(fontSize: ResponsiveUtils.scaledFont(context, 26));

  static TextStyle responsiveH2(BuildContext context) =>
      h2.copyWith(fontSize: ResponsiveUtils.scaledFont(context, 20));

  static TextStyle responsiveH3(BuildContext context) =>
      h3.copyWith(fontSize: ResponsiveUtils.scaledFont(context, 16));

  static TextStyle responsiveBody(BuildContext context) =>
      body.copyWith(fontSize: ResponsiveUtils.scaledFont(context, 14));

  static TextStyle responsiveLabel(BuildContext context) =>
      label.copyWith(fontSize: ResponsiveUtils.scaledFont(context, 13));
}
