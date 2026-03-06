import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for FilteringTextInputFormatter
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:customer_app/src/providers/auth_provider.dart'; // Import AuthProvider
import 'package:customer_app/src/providers/order_provider.dart';
import 'package:customer_app/src/providers/cart_provider.dart';
import 'package:customer_app/src/providers/branch_provider.dart';
import 'package:customer_app/src/providers/address_provider.dart'; // Import AddressProvider
import 'package:customer_app/src/services/location_service.dart'; // Import LocationService
import 'package:customer_app/src/features/profile/presentation/screens/address_list_screen.dart'; // Import AddressListScreen
import 'package:customer_app/src/models/branch_model.dart';
import 'package:customer_app/src/models/address_model.dart'; // Import AddressModel
import 'package:customer_app/src/features/profile/presentation/order_history_screen.dart'; // Import OrderHistoryScreen
import '../../../constants/app_sizes.dart';
import '../../../constants/app_strings.dart';
import '../../../common_widgets/custom_widgets.dart';
import '../../../common_widgets/pharmacy_loader_with_background.dart';

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
  final _formKey = GlobalKey<FormState>(); // Add GlobalKey for Form
  String _selectedOrderType = "Normal"; // Default to Normal
  final TextEditingController _shippingAddressController =
      TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  BranchModel? _selectedBranch;
  AddressModel? _selectedAddress; // For address dropdown
  bool _isValidatingCart = true;
  bool _isPlacingOrder = false;
  bool _isAutoFetchingAddress = false;
  bool _useLoyaltyPoints = false; // Add this
  String? _cartValidationErrorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.isBuyNow) {
      _selectedOrderType = "Quick";
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _validateCartItems();
      _fetchCurrentLocationAddress();
      Provider.of<BranchProvider>(context, listen: false).fetchLocationAndData();
      Provider.of<AddressProvider>(
        context,
        listen: false,
      ).fetchAddresses(); // Fetch addresses
      
      final cartProvider = Provider.of<CartProvider>(
        context,
        listen: false,
      );
      await cartProvider.fetchDeliveryCharges(); // Fetch delivery charges
      
      if (mounted) {
         final deliveryFee = cartProvider.deliveryFee;
         final total = widget.cartTotal + deliveryFee;
         Provider.of<OrderProvider>(context, listen: false).validateMinimumOrderAmount(total);
      }
    });
  }

  @override
  void dispose() {
    _shippingAddressController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocationAddress() async {
    setState(() {
      _isAutoFetchingAddress = true;
    });

    try {
      final branchProvider = Provider.of<BranchProvider>(context, listen: false);
      await branchProvider.fetchLocationAndData();
      
      if (branchProvider.currentPosition != null) {
        final address = await LocationService.getAddressFromLatLng(
          branchProvider.currentPosition!.latitude,
          branchProvider.currentPosition!.longitude,
        );
        
        if (address != null && mounted) {
          setState(() {
            _shippingAddressController.text = address;
          });
        }
      }
    } catch (e) {
      debugPrint("Error auto-fetching address: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isAutoFetchingAddress = false;
        });
      }
    }
  }

  Future<void> _validateCartItems() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    setState(() {
      _isValidatingCart = true;
      _cartValidationErrorMessage = null;
    });

    try {
      final validationResult = await orderProvider.validateCart(
        widget.cartItems,
      );
      if (!validationResult['valid']) {
        _cartValidationErrorMessage = (validationResult['errors'] as List).join(
          '\n',
        );
        if (!mounted) return;
        _showErrorDialog(
          "Cart Validation Failed",
          _cartValidationErrorMessage!,
        );
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
    // Validate Form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_cartValidationErrorMessage != null) {
      _showErrorDialog(
        "Cannot Place Order",
        "Please resolve cart validation issues first.",
      );
      return;
    }

    // Check validation one last time (though UI shouldn't allow this)
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    if (!orderProvider.isAmountValid) {
       _showErrorDialog("Invalid Amount", orderProvider.amountValidationError ?? "Order amount is invalid.");
       return;
    }

    if (_shippingAddressController.text.isEmpty ||
        _contactNumberController.text.isEmpty) {
      _showErrorDialog(
        "Missing Information",
        "Please provide shipping address and contact number.",
      );
      return;
    }

    if (_selectedBranch == null) {
      _showErrorDialog("Missing Information", "Please select a branch.");
      return;
    }

    if (widget.cartItems.isEmpty) {
      _showErrorDialog("Error", "Cart is empty.");
      return;
    }

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    const paymentMethod = "COD";

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      // Unify order placement to always use orderProvider.placeOrder
      await orderProvider.placeOrder(
        shippingAddress: _shippingAddressController.text,
        contactNumber: _contactNumberController.text,
        items: widget.cartItems, // This will contain one item for buy now, multiple for cart
        branchId: _selectedBranch?.id,
        paymentMethod: paymentMethod,
        orderType: _selectedOrderType, // Keep this for now, it's just a string in payload
        useLoyaltyPoints: _useLoyaltyPoints, // Pass loyalty points flag
      );

      if (!mounted) return;

      if (!widget.isBuyNow) {
        cartProvider
            .clearCart(); // Clear cart after successful order only if not Buy Now
      }

      // Reload user profile to update loyalty points balance
      if (mounted) {
        await Provider.of<AuthProvider>(context, listen: false).reloadUserProfile();
      }

      Navigator.of(
        context,
      ).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
        (route) => route.isFirst,
      );
    } on DioException catch (e) {
      String errorMessage =
          e.response?.data['error'] ?? 'Failed to place order.';
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
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
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
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deliveryFee = Provider.of<CartProvider>(context).deliveryFee;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.checkout)),
      body: Stack(
        children: [
          _isValidatingCart
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.p16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  // Order Type Selection
                  Text(
                    "Order Type",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p12),
                  Consumer<AddressProvider>(
                    builder: (context, addressProvider, child) {
                      if (addressProvider.isLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      
                      // Check if addresses are empty and not loading
                      if (addressProvider.addresses.isEmpty &&
                          !addressProvider.isLoading) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "No saved addresses found.",
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(height: AppSizes.p8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const AddressListScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppSizes.radius8),
                                ),
                              ),
                              child: const Text("Add New Address"),
                            ),
                            const SizedBox(height: AppSizes.p16),
                          ],
                        );
                      }

                      return DropdownButtonFormField<AddressModel>(
                        value: _selectedAddress,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          hintText: "Choose from saved addresses",
                        ),
                        isExpanded: true,
                        items: addressProvider.addresses.map((address) {
                          return DropdownMenuItem<AddressModel>(
                            value: address,
                            child: Text(
                              address.address,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Enter your shipping address",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isAutoFetchingAddress)
                        const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.my_location, size: 20),
                          onPressed: _fetchCurrentLocationAddress,
                          tooltip: "Use Current Location",
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.p12),
                  CustomTextField(
                    controller: _shippingAddressController,
                    hint: "e.g., House No. 123, Street 45, City",
                    maxLines: 3,
                    validator: (value) =>
                        value!.isEmpty ? "Address cannot be empty" : null,
                  ),
                  const SizedBox(height: AppSizes.p12),
                  CustomTextField(
                    controller: _contactNumberController,
                    hint: "e.g., 03001234567",
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Contact number cannot be empty";
                      }
                      if (value.length != 11) {
                        return "Phone number must be 11 digits";
                      }
                      if (!value.startsWith("03")) {
                        return "Phone number must start with 03";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.p24),

                  // Branch Section
                  // Branch selection is now always visible as per user request
                  Text(
                    "Select Nearest Branch",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p12),
                  Consumer<BranchProvider>(
                    builder: (context, branchProvider, child) {
                      if (branchProvider.isLoading ||
                          branchProvider.isLocationLoading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      // If we have branches (either nearest or fallback), show the dropdown
                      if (branchProvider.foundBranches.isNotEmpty) {
                        // Ensure _selectedBranch is either null or exists in the current foundBranches list
                        // Using .contains now works because of operator == in BranchModel
                        if (_selectedBranch != null && !branchProvider.foundBranches.contains(_selectedBranch)) {
                           _selectedBranch = null;
                        }

                        // Auto-select the first branch if none is selected
                        if (_selectedBranch == null) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && branchProvider.foundBranches.isNotEmpty) {
                              setState(() {
                                _selectedBranch = branchProvider.foundBranches.first;
                              });
                            }
                          });
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (branchProvider.currentPosition == null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  "Please select the nearest branch manually because location services are disabled.",
                                  style: TextStyle(
                                    color: Colors.orange[800],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            DropdownButtonFormField<BranchModel>(
                              value: _selectedBranch,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              hint: const Text("Choose a branch"),
                              isExpanded: true,
                              items: branchProvider.foundBranches.map((branch) {
                                final distanceStr = branch.distanceKm != null 
                                  ? " (${branch.distanceKm!.toStringAsFixed(1)} km)" 
                                  : "";
                                return DropdownMenuItem<BranchModel>(
                                  value: branch,
                                  child: Text(
                                    "${branch.name}$distanceStr",
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedBranch = value;
                                });
                              },
                            ),
                          ],
                        );
                      }

                      // If no branches found at all (real error)
                      if (branchProvider.locationError != null) {
                        return Text(
                          branchProvider.locationError!,
                          style: const TextStyle(color: Colors.red),
                        );
                      }
                      
                      return const Text("No branches available at the moment.");
                    },
                  ),
                  const SizedBox(height: AppSizes.p24),

                  // Loyalty Points Section
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final points = authProvider.user?.loyaltyPoints ?? 0;
                      
                      if (points < 500) {
                        return const SizedBox.shrink();
                      }
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Loyalty Points",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSizes.p12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(AppSizes.radius12),
                              border: Border.all(color: Theme.of(context).dividerColor),
                            ),
                            child: CheckboxListTile(
                              title: Text("Use Loyalty Points (Available: $points)"),
                              subtitle: const Text("1 Point = 1 PKR", style: TextStyle(fontSize: 12)),
                              value: _useLoyaltyPoints,
                              onChanged: (value) {
                                setState(() {
                                  _useLoyaltyPoints = value ?? false;
                                });
                              },
                              secondary: const Icon(Icons.stars, color: Colors.amber),
                              activeColor: Theme.of(context).colorScheme.primary,
                              contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p8),
                            ),
                          ),
                          const SizedBox(height: AppSizes.p24),
                        ],
                      );
                    },
                  ),

                  // Payment Method
                  Text(
                    AppStrings.paymentMethod,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSizes.p16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(AppSizes.radius12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.money, color: Colors.green),
                        const SizedBox(width: 12),
                        Text(
                          AppStrings.cashOnDelivery,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.p24),

                  // Order Summary
                  Text(
                    AppStrings.orderSummary,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p12),
                  Container(
                    padding: const EdgeInsets.all(AppSizes.p16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(AppSizes.radius12),
                    ),
                    child: Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        final subtotal = widget.cartTotal;
                        final total = subtotal + deliveryFee;
                        double discount = 0.0;
                        
                        if (_useLoyaltyPoints) {
                          final points = authProvider.user?.loyaltyPoints ?? 0;
                          discount = points.toDouble();
                          if (discount > total) {
                            discount = total;
                          }
                        }
                        
                        final finalTotal = total - discount;

                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(AppStrings.subtotal),
                                Text("PKR ${subtotal.toStringAsFixed(2)}"),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(AppStrings.deliveryFee),
                                Text("PKR ${deliveryFee.toStringAsFixed(2)}"),
                              ],
                            ),
                            if (_useLoyaltyPoints && discount > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Loyalty Discount", style: TextStyle(color: Colors.green)),
                                  Text("- PKR ${discount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.green)),
                                ],
                              ),
                            ],
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppStrings.total,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "PKR ${finalTotal.toStringAsFixed(2)}",
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSizes.p32),
                  Consumer<OrderProvider>(
                    builder: (context, orderProvider, child) {
                      if (orderProvider.isValidatingAmount) {
                         return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (orderProvider.amountValidationError != null) {
                        return Container(
                          padding: const EdgeInsets.all(AppSizes.p12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSizes.radius8),
                            border: Border.all(color: Colors.red.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  orderProvider.amountValidationError!,
                                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return CustomButton(
                        text: AppStrings.placeOrder,
                        onPressed: _placeOrder,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          if (_isPlacingOrder)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const PharmacyLoaderWithBackground(),
            ),
        ],
      ),
    );
  }
}