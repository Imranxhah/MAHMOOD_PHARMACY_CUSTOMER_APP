import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:customer_app/src/providers/order_provider.dart';
import 'package:customer_app/src/providers/cart_provider.dart';
import '../../../constants/app_sizes.dart';
import '../../../constants/app_strings.dart';
import '../../../common_widgets/primary_button.dart';
import '../../../common_widgets/custom_text_field.dart'; // Added for address/contact input

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double cartTotal;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.cartTotal,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _selectedPaymentIndex = 0; // 0 for Cash on Delivery, 1 for Card
  final TextEditingController _shippingAddressController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  bool _isValidatingCart = true;
  String? _cartValidationErrorMessage;

  @override
  void initState() {
    super.initState();
    _validateCartItems();
    // Default values for address/contact for now, user can fill these later.
    _shippingAddressController.text = "123 Main Street, New York, NY";
    _contactNumberController.text = "+1234567890";
  }

  @override
void dispose() {
    _shippingAddressController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  Future<void> _validateCartItems() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    setState(() {
      _isValidatingCart = true;
      _cartValidationErrorMessage = null;
    });

    try {
      final validationResult = await orderProvider.validateCart(widget.cartItems);
      if (!validationResult['valid']) {
        _cartValidationErrorMessage = (validationResult['errors'] as List).join('\n');
        if (!mounted) return;
        _showErrorDialog("Cart Validation Failed", _cartValidationErrorMessage!);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog("Error Validating Cart", e.toString());
      _cartValidationErrorMessage = e.toString();
    } finally {
      setState(() {
        _isValidatingCart = false;
      });
    }
  }

  Future<void> _placeOrder() async {
    if (_cartValidationErrorMessage != null) {
      _showErrorDialog("Cannot Place Order", "Please resolve cart validation issues first.");
      return;
    }
    
    if (_shippingAddressController.text.isEmpty || _contactNumberController.text.isEmpty) {
      _showErrorDialog("Missing Information", "Please provide shipping address and contact number.");
      return;
    }

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    try {
      await orderProvider.placeOrder(
        shippingAddress: _shippingAddressController.text,
        contactNumber: _contactNumberController.text,
        items: widget.cartItems,
      );
      if (!mounted) return;
      cartProvider.clearCart(); // Clear cart after successful order
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.orderPlacedSuccess)),
      );
      Navigator.of(context).popUntil((route) => route.isFirst); // Navigate back to main screen
    } on DioException catch (e) {
      String errorMessage = e.response?.data['error'] ?? 'Failed to place order.';
      if (!mounted) return;
      _showErrorDialog("Order Failed", errorMessage);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog("Order Failed", e.toString());
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text("Okay"),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.checkout)),
      body: _isValidatingCart
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                  CustomTextField(
                    controller: _shippingAddressController,
                    hintText: "Enter your shipping address",
                    validator: (value) => value!.isEmpty ? "Address cannot be empty" : null,
                  ),
                  const SizedBox(height: AppSizes.p12),
                  CustomTextField(
                    controller: _contactNumberController,
                    hintText: "Enter your contact number",
                    keyboardType: TextInputType.phone,
                    validator: (value) => value!.isEmpty ? "Contact number cannot be empty" : null,
                  ),
                  const SizedBox(height: AppSizes.p24),
                  
                  // Payment Method - Refactored to avoid deprecated warnings
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
                        ListTile(
                          title: const Text(AppStrings.cashOnDelivery),
                          leading: Radio<int>(
                            value: 0,
                            groupValue: _selectedPaymentIndex,
                            onChanged: (int? value) {
                              setState(() {
                                _selectedPaymentIndex = value!;
                              });
                            },
                          ),
                          onTap: () {
                            setState(() {
                              _selectedPaymentIndex = 0;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          title: const Text(AppStrings.creditDebitCard),
                          subtitle: const Text("**** **** **** 1234"),
                          leading: Radio<int>(
                            value: 1,
                            groupValue: _selectedPaymentIndex,
                            onChanged: (int? value) {
                              setState(() {
                                _selectedPaymentIndex = value!;
                              });
                            },
                          ),
                          onTap: () {
                            setState(() {
                              _selectedPaymentIndex = 1;
                            });
                          },
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
                          children: [Text(AppStrings.subtotal), Text("\$ ${widget.cartTotal.toStringAsFixed(2)}")],
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [Text(AppStrings.deliveryFee), Text("\$ 2.00")], // Hardcoded delivery fee for now
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
                              "\$ ${(widget.cartTotal + 2.00).toStringAsFixed(2)}", // Hardcoded delivery fee
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
                    onPressed: _placeOrder,
                  ),
                ],
              ),
            ),
    );
  }
}
