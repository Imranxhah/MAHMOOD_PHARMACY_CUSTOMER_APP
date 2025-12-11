import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:customer_app/src/providers/order_provider.dart';
import 'package:customer_app/src/providers/cart_provider.dart';
import 'package:customer_app/src/providers/branch_provider.dart';
import 'package:customer_app/src/providers/address_provider.dart'; // Import AddressProvider
import 'package:customer_app/src/models/branch_model.dart';
import 'package:customer_app/src/models/address_model.dart'; // Import AddressModel
import '../../../constants/app_sizes.dart';
import '../../../constants/app_strings.dart';
import '../../../common_widgets/custom_widgets.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double cartTotal;
  final bool isBuyNow;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.cartTotal,
    this.isBuyNow = false,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _selectedPaymentIndex = 0; // 0 for Cash on Delivery, 1 for Card
  String _selectedOrderType = "Normal"; // Default to Normal
  final TextEditingController _shippingAddressController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  BranchModel? _selectedBranch;
  AddressModel? _selectedAddress; // For address dropdown
  bool _isValidatingCart = true;
  String? _cartValidationErrorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.isBuyNow) {
      _selectedOrderType = "Quick";
    }
    _validateCartItems();
    // Default values for address/contact for now, user can fill these later.
    _shippingAddressController.text = "123 Main Street, New York, NY";
    _contactNumberController.text = "+1234567890";
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BranchProvider>(context, listen: false).listBranches();
      Provider.of<AddressProvider>(context, listen: false).fetchAddresses(); // Fetch addresses
    });
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

    // Branch selection is mandatory only if it's a "Normal" order type or if using Normal endpoint logic
    // If using Quick endpoint, branch might not be supported.
    // If widget.isBuyNow is false, we ALWAYS use placeOrder (Normal endpoint), so Branch is likely needed unless Quick Type implies no branch? 
    // Assuming Branch is required for Normal Endpoint regardless of type string.
    if (!widget.isBuyNow && _selectedBranch == null) {
       _showErrorDialog("Missing Information", "Please select a branch.");
       return;
    }
    
    if (widget.cartItems.isEmpty) {
       _showErrorDialog("Error", "Cart is empty.");
       return;
    }

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final paymentMethod = _selectedPaymentIndex == 0 ? "COD" : "PAYED";

    try {
      if (widget.isBuyNow && _selectedOrderType == "Quick") {
        // Use Quick Order Endpoint
        final item = widget.cartItems.first;
        await orderProvider.quickOrder(
          productId: int.parse(item['product_id'].toString()),
          quantity: int.parse(item['quantity'].toString()),
          shippingAddress: _shippingAddressController.text,
          contactNumber: _contactNumberController.text,
        );
      } else {
        // Use Normal Order Endpoint (even if BuyNow but selected "Normal" type, or Cart)
        await orderProvider.placeOrder(
          shippingAddress: _shippingAddressController.text,
          contactNumber: _contactNumberController.text,
          items: widget.cartItems,
          branchId: _selectedBranch?.id,
          paymentMethod: paymentMethod,
          orderType: _selectedOrderType,
        );
      }

      if (!mounted) return;
      
      if (!widget.isBuyNow) {
        cartProvider.clearCart(); // Clear cart after successful order only if not Buy Now
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.orderPlacedSuccess)),
      );
      Navigator.of(context).popUntil((route) => route.isFirst); // Navigate back to main screen
    } on DioException catch (e) {
      String errorMessage = e.response?.data['error'] ?? 'Failed to place order.';
      if (e.response?.statusCode == 400 && e.response?.data is Map) {
         final data = e.response?.data as Map;
         if (data.containsKey('error')) {
            errorMessage = data['error'];
         } else if (data.containsKey('errors')) {
            errorMessage = data['errors'].toString();
         }
      }
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
                   // Order Type Selection
                  Text(
                    "Order Type",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSizes.p12),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text("Normal"),
                          value: "Normal",
                          groupValue: _selectedOrderType,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) {
                            setState(() {
                              _selectedOrderType = value!;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text("Quick"),
                          value: "Quick",
                          groupValue: _selectedOrderType,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) {
                            setState(() {
                              _selectedOrderType = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.p24),

                  // Saved Addresses Dropdown
                  Text(
                    "Select Saved Address",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSizes.p12),
                  Consumer<AddressProvider>(
                    builder: (context, addressProvider, child) {
                      if (addressProvider.isLoading) {
                        return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))));
                      }
                      return DropdownButtonFormField<AddressModel>(
                        value: _selectedAddress,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          hintText: "Choose from saved addresses",
                        ),
                        isExpanded: true,
                        items: addressProvider.addresses.map((address) {
                          return DropdownMenuItem<AddressModel>(
                            value: address,
                            child: Text(
                              address.address,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedAddress = value;
                            if (value != null) {
                              _shippingAddressController.text = value.address;
                            }
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppSizes.p24),

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
                    hint: "Enter your shipping address",
                    validator: (value) => value!.isEmpty ? "Address cannot be empty" : null,
                  ),
                  const SizedBox(height: AppSizes.p12),
                  CustomTextField(
                    controller: _contactNumberController,
                    hint: "Enter your contact number",
                    keyboardType: TextInputType.phone,
                    validator: (value) => value!.isEmpty ? "Contact number cannot be empty" : null,
                  ),
                  const SizedBox(height: AppSizes.p24),

                  // Branch Section (Only if Order Type is Normal)
                  if (_selectedOrderType == "Normal") ...[
                    Text(
                      "Select Branch",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSizes.p12),
                    Consumer<BranchProvider>(
                      builder: (context, branchProvider, child) {
                        if (branchProvider.isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (branchProvider.error != null) {
                          return Text(branchProvider.error!, style: const TextStyle(color: Colors.red));
                        }
                        return DropdownButtonFormField<BranchModel>(
                          value: _selectedBranch,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          hint: const Text("Choose a branch"),
                          isExpanded: true, // Prevent overflow
                          items: branchProvider.branches.map((branch) {
                            return DropdownMenuItem<BranchModel>(
                              value: branch,
                              child: Text(
                                branch.name,
                                overflow: TextOverflow.ellipsis, // Handle text overflow
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedBranch = value;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: AppSizes.p24),
                  ],
                  
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
                  CustomButton(
                    text: AppStrings.placeOrder,
                    onPressed: _placeOrder,
                  ),
                ],
              ),
            ),
    );
  }
}