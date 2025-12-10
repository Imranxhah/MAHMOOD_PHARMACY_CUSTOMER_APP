import 'package:flutter/material.dart';

import '../../../constants/app_sizes.dart';
import '../../../common_widgets/product_card.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Products"),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list)),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(AppSizes.p16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 10,
        itemBuilder: (context, index) {
          return ProductCard(
            name: "Paracetamol 500mg Tablet ${index + 1}",
            price: "\$ 5.${index * 2}",
            imageUrl: "",
            onTap: () {
              // Navigate to Details
            },
          );
        },
      ),
    );
  }
}
