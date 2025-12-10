import 'package:flutter/material.dart';
import '../../../constants/app_sizes.dart';
import '../../../constants/app_strings.dart';
import '../../../common_widgets/primary_button.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _selectedAddressIndex = 0;
  int _selectedPaymentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.checkout)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Address Section
            Text(
              AppStrings.shippingAddress,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.p12),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppSizes.radius12),
              ),
              child: Column(
                children: [
                  RadioListTile(
                    value: 0,
                    groupValue: _selectedAddressIndex,
                    onChanged: (val) =>
                        setState(() => _selectedAddressIndex = val!),
                    title: const Text("Home"),
                    subtitle: const Text("123 Main Street, New York, NY"),
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  const Divider(height: 1),
                  RadioListTile(
                    value: 1,
                    groupValue: _selectedAddressIndex,
                    onChanged: (val) =>
                        setState(() => _selectedAddressIndex = val!),
                    title: const Text(AppStrings.office),
                    subtitle: const Text("456 Business Rd, New York, NY"),
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.p24),

            // Payment Method
            Text(
              AppStrings.paymentMethod,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.p12),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppSizes.radius12),
              ),
              child: Column(
                children: [
                  RadioListTile(
                    value: 0,
                    groupValue: _selectedPaymentIndex,
                    onChanged: (val) =>
                        setState(() => _selectedPaymentIndex = val!),
                    title: const Text(AppStrings.cashOnDelivery),
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  const Divider(height: 1),
                  RadioListTile(
                    value: 1,
                    groupValue: _selectedPaymentIndex,
                    onChanged: (val) =>
                        setState(() => _selectedPaymentIndex = val!),
                    title: const Text(AppStrings.creditDebitCard),
                    subtitle: const Text("**** **** **** 1234"),
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.p24),

            // Order Summary
            Text(
              AppStrings.orderSummary,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.p12),
            Container(
              padding: const EdgeInsets.all(AppSizes.p16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppSizes.radius12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(AppStrings.subtotal), const Text("\$ 38.97")],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(AppStrings.deliveryFee), const Text("\$ 2.00")],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.total,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        "\$ 40.97",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.p32),
            PrimaryButton(
              text: AppStrings.placeOrder,
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.orderPlacedSuccess)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
