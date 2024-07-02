import 'dart:convert'; // For JSON encoding and decoding

import 'package:clothes_app/api_connection/api_connection.dart'; // API connection for the app
import 'package:clothes_app/users/controllers/cart_list_controller.dart'; // Controller for cart list management
import 'package:clothes_app/users/model/cart.dart'; // Cart model class
import 'package:clothes_app/users/model/clothes.dart'; // Clothes model class
import 'package:clothes_app/users/userPreferences/current_user.dart'; // Current user management
import 'package:flutter/material.dart'; // Flutter framework for building UI
import 'package:fluttertoast/fluttertoast.dart'; // For showing toast messages
import 'package:get/get.dart'; // State management and navigation package
import 'package:http/http.dart' as http; // HTTP package for making API requests

import '../item/item_details_screen.dart'; // Item details screen

class CartListScreen extends StatefulWidget {
  @override
  State<CartListScreen> createState() => _CartListScreenState();
}

class _CartListScreenState extends State<CartListScreen> {
  final currentOnlineUser = Get.put(CurrentUser());
  final cartListController = Get.put(CartListController());

  // Function to get the current user's cart list
  getCurrentUserCartList() async {
    List<Cart> cartListOfCurrentUser = [];

    try {
      var res = await http.post(Uri.parse(API.getCartList), body: {
        "currentOnlineUserID": currentOnlineUser.user.user_id.toString(),
      });

      if (res.statusCode == 200) {
        var responseBodyOfGetCurrentUserCartItems = jsonDecode(res.body);

        if (responseBodyOfGetCurrentUserCartItems['success'] == true) {
          (responseBodyOfGetCurrentUserCartItems['currentUserCartData'] as List)
              .forEach((eachCurrentUserCartItemData) {
            cartListOfCurrentUser
                .add(Cart.fromJson(eachCurrentUserCartItemData));
          });
        } else {
          Fluttertoast.showToast(msg: "Your Cart List is Empty.");
        }

        cartListController.setList(cartListOfCurrentUser);
      } else {
        Fluttertoast.showToast(msg: "Status Code is not 200");
      }
    } catch (errorMsg) {
      Fluttertoast.showToast(msg: "Error: " + errorMsg.toString());
    }
    calculateTotalAmount(); // Calculate the total amount after getting the cart list
  }


// Function to calculate the total amount of selected items in the cart
  calculateTotalAmount() {
    // Reset the total amount to 0 at the start
    cartListController.setTotal(0);

    // Check if there are any selected items in the cart
    if (cartListController.selectedItemList.length > 0) {
      // Iterate over each item in the cart list
      cartListController.cartList.forEach((itemInCart) {
        // Check if the current item is selected
        if (cartListController.selectedItemList.contains(itemInCart.cart_id)) {
          // Calculate the total amount for the current item
          // itemInCart.price is the price of the item
          // itemInCart.quantity is the quantity of the item (converted to double)
          double eachItemTotalAmount = (itemInCart.price!) *
              (double.parse(itemInCart.quantity.toString()));

          // Update the total amount in the controller by adding the total amount for the current item
          cartListController
              .setTotal(cartListController.total + eachItemTotalAmount);
        }
      });
    }
  }

  // Function to delete selected items from the user's cart list
  deleteSelectedItemsFromUserCartList(int cartID) async {
    try {
      var res = await http
          .post(Uri.parse(API.deleteSelectedItemsFromCartList), body: {
        "cart_id": cartID.toString(),
      });

      if (res.statusCode == 200) {
        var responseBodyFromDeleteCart = jsonDecode(res.body);

        if (responseBodyFromDeleteCart["success"] == true) {
          getCurrentUserCartList();
        }
      } else {
        Fluttertoast.showToast(msg: "Error, Status Code is not 200");
      }
    } catch (errorMessage) {
      print("Error: " + errorMessage.toString());
      Fluttertoast.showToast(msg: "Error: " + errorMessage.toString());
    }
  }

  // Function to update the quantity of an item in the user's cart
  updateQuantityInUserCart(int cartID, int newQuantity) async {
    try {
      var res = await http.post(Uri.parse(API.updateItemInCartList), body: {
        "cart_id": cartID.toString(),
        "quantity": newQuantity.toString(),
      });

      if (res.statusCode == 200) {
        var responseBodyOfUpdateQuantity = jsonDecode(res.body);

        if (responseBodyOfUpdateQuantity["success"] == true) {
          getCurrentUserCartList();
        }
      } else {
        Fluttertoast.showToast(msg: "Error, Status Code is not 200");
      }
    } catch (errorMessage) {
      print("Error: " + errorMessage.toString());
      Fluttertoast.showToast(msg: "Error: " + errorMessage.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentUserCartList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("My Cart"),
        actions: [
          // Button to select all items
          Obx(() => IconButton(
                onPressed: () {
                  cartListController.setIsSelectedAllItems();
                  cartListController.clearAllSelectedItems();

                  if (cartListController.isSelectedAll) {
                    cartListController.cartList.forEach((eachItem) {
                      cartListController.addSelectedItem(eachItem.cart_id!);
                    });
                  }

                  calculateTotalAmount(); // Calculate the total amount after selecting all items
                },
                icon: Icon(
                  cartListController.isSelectedAll
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  color: cartListController.isSelectedAll
                      ? Colors.white
                      : Colors.grey,
                ),
              )),

          // Button to delete selected items
          GetBuilder(
              init: CartListController(),
              builder: (c) {
                if (cartListController.selectedItemList.length > 0) {
                  return IconButton(
                    onPressed: () async {
                      var responseFromDialogBox = await Get.dialog(
                        AlertDialog(
                          backgroundColor: Colors.grey,
                          title: const Text("Delete"),
                          content: const Text(
                              "Are you sure to Delete selected items from your Cart List?"),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Get.back();
                              },
                              child: const Text(
                                "No",
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Get.back(result: "yesDelete");
                              },
                              child: const Text(
                                "Yes",
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (responseFromDialogBox == "yesDelete") {
                        cartListController.selectedItemList
                            .forEach((selectedItemUserCartID) {
                          // Delete selected items now
                          deleteSelectedItemsFromUserCartList(
                              selectedItemUserCartID);
                        });
                      }

                      calculateTotalAmount(); // Calculate the total amount after deleting selected items
                    },
                    icon: const Icon(
                      Icons.delete_sweep,
                      size: 26,
                      color: Colors.redAccent,
                    ),
                  );
                } else {
                  return Container();
                }
              }),
        ],
      ),
      body: Obx(
        () => cartListController.cartList.length > 0
            ? ListView.builder(
                itemCount: cartListController.cartList.length,
                scrollDirection: Axis.vertical,
                itemBuilder: (context, index) {
                  Cart cartModel = cartListController.cartList[index];

                  Clothes clothesModel = Clothes(
                    item_id: cartModel.item_id,
                    colors: cartModel.colors,
                    image: cartModel.image,
                    name: cartModel.name,
                    price: cartModel.price,
                    rating: cartModel.rating,
                    sizes: cartModel.sizes,
                    description: cartModel.description,
                    tags: cartModel.tags,
                  );

                  return SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      children: [
                        // Checkbox for selecting items
                        GetBuilder(
                          init: CartListController(),
                          builder: (c) {
                            return IconButton(
                              onPressed: () {
                                if (cartListController.selectedItemList
                                    .contains(cartModel.cart_id)) {
                                  cartListController
                                      .deleteSelectedItem(cartModel.cart_id!);
                                } else {
                                  cartListController
                                      .addSelectedItem(cartModel.cart_id!);
                                }

                                calculateTotalAmount(); // Calculate the total amount after selecting/deselecting an item
                              },
                              icon: Icon(
                                cartListController.selectedItemList
                                        .contains(cartModel.cart_id)
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                color: cartListController.isSelectedAll
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                            );
                          },
                        ),

                        // Item details
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Get.to(ItemDetailsScreen(itemInfo: clothesModel));
                            },
                            child: Container(
                              margin: EdgeInsets.fromLTRB(
                                0,
                                index == 0 ? 16 : 8,
                                16,
                                index == cartListController.cartList.length - 1
                                    ? 16
                                    : 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.black,
                                boxShadow: const [
                                  BoxShadow(
                                    offset: Offset(0, 0),
                                    blurRadius: 6,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Item details (name, color, size, price)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Item name
                                          Text(
                                            clothesModel.name.toString(),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),

                                          const SizedBox(height: 20),

                                          // Item color, size, and price
                                          Row(
                                            children: [
                                              // Color and size
                                              Expanded(
                                                child: Text(
                                                  "Color: ${cartModel.color!.replaceAll('[', '').replaceAll(']', '')}" +
                                                      "\n" +
                                                      "Size: ${cartModel.size!.replaceAll('[', '').replaceAll(']', '')}",
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.white60,
                                                  ),
                                                ),
                                              ),

                                              // Price
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 12, right: 12.0),
                                                child: Text(
                                                  "\$" +
                                                      clothesModel.price
                                                          .toString(),
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    color: Colors.purpleAccent,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 20),

                                          // Quantity control (increase/decrease)
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              // Decrease quantity button
                                              IconButton(
                                                onPressed: () {
                                                  if (cartModel.quantity! - 1 >=
                                                      1) {
                                                    updateQuantityInUserCart(
                                                      cartModel.cart_id!,
                                                      cartModel.quantity! - 1,
                                                    );
                                                  }
                                                },
                                                icon: const Icon(
                                                  Icons.remove_circle_outline,
                                                  color: Colors.grey,
                                                  size: 30,
                                                ),
                                              ),

                                              const SizedBox(width: 10),

                                              // Display current quantity
                                              Text(
                                                cartModel.quantity.toString(),
                                                style: const TextStyle(
                                                  color: Colors.purpleAccent,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),

                                              const SizedBox(width: 10),

                                              // Increase quantity button
                                              IconButton(
                                                onPressed: () {
                                                  updateQuantityInUserCart(
                                                    cartModel.cart_id!,
                                                    cartModel.quantity! + 1,
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.add_circle_outline,
                                                  color: Colors.grey,
                                                  size: 30,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Item image
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(22),
                                      bottomRight: Radius.circular(22),
                                    ),
                                    child: FadeInImage(
                                      height: 185,
                                      width: 150,
                                      fit: BoxFit.cover,
                                      placeholder: const AssetImage(
                                          "assets/images/images.png"),
                                      image: NetworkImage(
                                        cartModel.image!,
                                      ),
                                      imageErrorBuilder:
                                          (context, error, stackTraceError) {
                                        return const Center(
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
            : const Center(
                child: Text("Cart is Empty"),
              ),
      ),
      bottomNavigationBar: GetBuilder(
        init: CartListController(),
        builder: (c) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, -3),
                  color: Colors.white24,
                  blurRadius: 6,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Display total amount
                const Text(
                  "Total Amount:",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Obx(() => Text(
                      "\$ " + cartListController.total.toStringAsFixed(2),
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )),

                const Spacer(),

                // Order now button
                Material(
                  color: cartListController.selectedItemList.length > 0
                      ? Colors.purpleAccent
                      : Colors.white24,
                  borderRadius: BorderRadius.circular(30),
                  child: InkWell(
                    onTap: () {
                      // Order now functionality here
                    },
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(
                        "Order Now",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
