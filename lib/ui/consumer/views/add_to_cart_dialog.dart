import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/models/product.dart';

// Dialog for adding products to cart with quantity selection
class AddToCartDialog extends StatefulWidget {
  const AddToCartDialog({
    super.key,
    required this.product,
  });

  final Product product;

  @override
  State<AddToCartDialog> createState() => _AddToCartDialogState();
}

class _AddToCartDialogState extends State<AddToCartDialog> {
  late final TextEditingController _quantityController;
  late int _quantity;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Start with minimum order quantity
    _quantity = widget.product.minimumOrder.clamp(1, widget.product.stockQuantity);
    _quantityController = TextEditingController(text: _quantity.toString());
    
    // Add listener to validate input as user types
    _quantityController.addListener(_validateQuantity);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  // Validate quantity input against min order and stock
  void _validateQuantity() {
    final input = _quantityController.text.trim();
    
    if (input.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a quantity';
        _quantity = 0;
      });
      return;
    }

    final quantity = int.tryParse(input);
    
    if (quantity == null) {
      setState(() {
        _errorMessage = 'Please enter a valid number';
        _quantity = 0;
      });
      return;
    }

    if (quantity <= 0) {
      setState(() {
        _errorMessage = 'Quantity must be greater than 0';
        _quantity = 0;
      });
      return;
    }

    if (quantity < widget.product.minimumOrder) {
      setState(() {
        _errorMessage =
            'Minimum order is ${widget.product.minimumOrder} ${widget.product.unit}';
        _quantity = quantity;
      });
      return;
    }

    if (quantity > widget.product.stockQuantity) {
      setState(() {
        _errorMessage =
            'Only ${widget.product.stockQuantity} ${widget.product.unit} available';
        _quantity = quantity;
      });
      return;
    }

    // Valid quantity
    setState(() {
      _errorMessage = null;
      _quantity = quantity;
    });
  }

  // Calculate total price for the quantity
  int get _totalPrice {
    if (_quantity <= 0) {
      return 0;
    }
    return widget.product.retailPrice * _quantity;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Price per unit
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Price per ${widget.product.unit}:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${widget.product.retailPrice} ₸',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Quantity input
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity (${widget.product.unit})',
                hintText: 'Enter quantity',
                errorText: _errorMessage,
                border: const OutlineInputBorder(),
                prefixIcon: IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    if (_quantity > widget.product.minimumOrder) {
                      final newQuantity = _quantity - 1;
                      _quantityController.text = newQuantity.toString();
                    }
                  },
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (_quantity < widget.product.stockQuantity) {
                      final newQuantity = _quantity + 1;
                      _quantityController.text = newQuantity.toString();
                    }
                  },
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (_) => _validateQuantity(),
            ),

            const SizedBox(height: 8),

            // Stock and minimum order info
            Text(
              'Available: ${widget.product.stockQuantity} ${widget.product.unit}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
            if (widget.product.minimumOrder > 1)
              Text(
                'Minimum: ${widget.product.minimumOrder} ${widget.product.unit}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),

            const SizedBox(height: 24),

            // Total price
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Total:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${_totalPrice} ₸',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _errorMessage == null && _quantity > 0
              ? () => Navigator.of(context).pop(_quantity)
              : null,
          child: const Text('Add to Cart'),
        ),
      ],
    );
  }
}

