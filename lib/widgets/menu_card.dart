import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';

class MenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;
  final Color? backgroundColor;

  const MenuCard({
    super.key,
    required this.title,
    required this.icon,
    this.iconColor,
    required this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        color: backgroundColor ?? AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: iconColor ?? AppTheme.primaryColor),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WalletCard extends StatelessWidget {
  final String cardNumber;
  final String cardHolderName;
  final String balance;
  final VoidCallback onTap;

  const WalletCard({
    super.key,
    required this.cardNumber,
    required this.cardHolderName,
    required this.balance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.cardShadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Şehir Kartım',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textLightColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const FaIcon(
                  FontAwesomeIcons.creditCard,
                  color: AppTheme.textLightColor,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              maskCardNumber(cardNumber),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textLightColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kart Sahibi',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textLightColor.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cardHolderName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textLightColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Bakiye',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textLightColor.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$balance ₺',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textLightColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String maskCardNumber(String number) {
    if (number.length < 8) return number;
    final String last4Digits = number.substring(number.length - 4);
    return '•••• •••• •••• $last4Digits';
  }
}
