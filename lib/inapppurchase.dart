import 'package:flutter/material.dart';
import 'dart:async';
// import 'package:flutter/cupertino.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';

class InApp extends StatefulWidget {
  const InApp({Key? key}) : super(key: key);

  @override
  State<InApp> createState() => _InAppState();
}

class _InAppState extends State<InApp> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final String _productID =
      'PREMIUM_PLAN'; //name of product ID registered on the store

  bool _available = true;
  List<ProductDetails> _products = [];
  final List<PurchaseDetails> _purchases = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  @override
  void initState() {
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;

    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      setState(() {
        _purchases.addAll(purchaseDetailsList);
        _listenToPurchaseUpdated(purchaseDetailsList);
      });
    }, onDone: () {
      _subscription!.cancel();
    }, onError: (error) {
      _subscription!.cancel();
    });

    _initialize();

    super.initState();
  }

  @override
  void dispose() {
    _subscription!.cancel();
    super.dispose();
  }

  void _initialize() async {
    _available = await _inAppPurchase.isAvailable();

    List<ProductDetails> products = await _getProducts(
      // ignore: prefer_collection_literals
      productIds: Set<String>.from(
        [_productID],
      ),
    );

    setState(() {
      _products = products;
    });
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          //  _showPendingUI();
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // bool valid = await _verifyPurchase(purchaseDetails);
          // if (!valid) {
          //   _handleInvalidPurchase(purchaseDetails);
          // }
          break;
        case PurchaseStatus.error:
          // ignore: avoid_print
          print(purchaseDetails.error!);
          // _handleError(purchaseDetails.error!);
          break;
        default:
          break;
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    });
  }

  Future<List<ProductDetails>> _getProducts(
      {required Set<String> productIds}) async {
    ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(productIds);

    return response.productDetails;
  }

  ListTile _buildProduct({required ProductDetails product}) {
    return ListTile(
      leading: const Icon(Icons.attach_money),
      title: Text('${product.title} - ${product.price}'),
      subtitle: Text(product.description),
      trailing: ElevatedButton(
        onPressed: () {
          _subscribe(product: product);
        },
        child: const Text(
          'Subscribe',
        ),
      ),
    );
  }

  ListTile _buildPurchase({required PurchaseDetails purchase}) {
    if (purchase.error != null) {
      return ListTile(
        title: Text('${purchase.error}'),
        subtitle: Text(purchase.status.toString()),
      );
    }

    String? transactionDate;
    if (purchase.status == PurchaseStatus.purchased) {
      DateTime date = DateTime.fromMillisecondsSinceEpoch(
        int.parse(purchase.transactionDate!),
      );
      transactionDate = ' @ ' + DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
    }

    return ListTile(
      title: Text('${purchase.productID} ${transactionDate ?? ''}'),
      subtitle: Text(purchase.status.toString()),
    );
  }

  void _subscribe({required ProductDetails product}) {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    _inAppPurchase.buyNonConsumable(
      purchaseParam: purchaseParam,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('In App Purchase 2.0.1'),
      ),
      body: _available
          ? Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Current Products ${_products.length}'),
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          return _buildProduct(
                            product: _products[index],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    // mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Past Purchases: ${_purchases.length}'),
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _purchases.length,
                          itemBuilder: (context, index) {
                            return _buildPurchase(
                              purchase: _purchases[index],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(
              child: Text('The Store Is Not Available'),
            ),
    );
  }
}
