import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

// ==========================================
// 1. MODELS & DATA STRUCTURES
// ==========================================

class OrderItem {
  String name;
  int quantity;
  double price;

  OrderItem({
    this.name = '',
    this.quantity = 1,
    this.price = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      name: map['name'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DeliveryOrder {
  final String id;
  final String customerName;
  final String phoneNumber;
  final String customerAddress;
  final List<OrderItem> items;
  final double deliveryCharges;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String paymentMode; // Cash, Bank, EasyPaisa, JazzCash, Udhar
  final String status;      // Paid, Udhar
  final DateTime dateTime;

  DeliveryOrder({
    required this.id,
    required this.customerName,
    required this.phoneNumber,
    required this.customerAddress,
    required this.items,
    required this.deliveryCharges,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentMode,
    required this.status,
    required this.dateTime,
  });

  DeliveryOrder copyWith({
    double? paidAmount,
    double? remainingAmount,
    String? status,
  }) {
    return DeliveryOrder(
      id: id,
      customerName: customerName,
      phoneNumber: phoneNumber,
      customerAddress: customerAddress,
      items: items,
      deliveryCharges: deliveryCharges,
      totalAmount: totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      paymentMode: paymentMode,
      status: status ?? this.status,
      dateTime: dateTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'phoneNumber': phoneNumber,
      'customerAddress': customerAddress,
      'items': items.map((x) => x.toMap()).toList(),
      'deliveryCharges': deliveryCharges,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'paymentMode': paymentMode,
      'status': status,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  factory DeliveryOrder.fromMap(Map<String, dynamic> map) {
    return DeliveryOrder(
      id: map['id'] ?? '',
      customerName: map['customerName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      customerAddress: map['customerAddress'] ?? '',
      items: (map['items'] as List? ?? []).map((x) => OrderItem.fromMap(x)).toList(),
      deliveryCharges: (map['deliveryCharges'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (map['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: map['paymentMode'] ?? 'Cash',
      status: map['status'] ?? 'Paid',
      dateTime: DateTime.parse(map['dateTime']),
    );
  }
}

class Customer {
  final String id;
  final String name;
  final String phoneNumber;
  final String address;

  Customer({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
    );
  }
}

class WalletStateData {
  final double cash;
  final double bank;
  final double easyPaisa;
  final double jazzCash;

  WalletStateData({
    this.cash = 0.0,
    this.bank = 0.0,
    this.easyPaisa = 0.0,
    this.jazzCash = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'cash': cash,
      'bank': bank,
      'easyPaisa': easyPaisa,
      'jazzCash': jazzCash,
    };
  }

  factory WalletStateData.fromMap(Map<String, dynamic> map) {
    return WalletStateData(
      cash: (map['cash'] as num?)?.toDouble() ?? 0.0,
      bank: (map['bank'] as num?)?.toDouble() ?? 0.0,
      easyPaisa: (map['easyPaisa'] as num?)?.toDouble() ?? 0.0,
      jazzCash: (map['jazzCash'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ==========================================
// 2. STATE MANAGEMENT (HYDRATED BLOC)
// ==========================================

class KhataState {
  final String? pin;
  final bool isAuthenticated;
  final List<DeliveryOrder> orders;
  final List<Customer> customers;
  final WalletStateData wallet;

  KhataState({
    this.pin,
    this.isAuthenticated = false,
    required this.orders,
    required this.customers,
    required this.wallet,
  });

  factory KhataState.initial() {
    return KhataState(
      pin: null,
      isAuthenticated: false,
      orders: [],
      customers: [],
      wallet: WalletStateData(cash: 3500.0, bank: 1850.0, easyPaisa: 0.0, jazzCash: 1177.0),
    );
  }

  KhataState copyWith({
    String? pin,
    bool? isAuthenticated,
    List<DeliveryOrder>? orders,
    List<Customer>? customers,
    WalletStateData? wallet,
  }) {
    return KhataState(
      pin: pin ?? this.pin,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      orders: orders ?? this.orders,
      customers: customers ?? this.customers,
      wallet: wallet ?? this.wallet,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pin': pin,
      'orders': orders.map((e) => e.toMap()).toList(),
      'customers': customers.map((e) => e.toMap()).toList(),
      'wallet': wallet.toMap(),
    };
  }

  factory KhataState.fromMap(Map<String, dynamic> map) {
    return KhataState(
      pin: map['pin'],
      isAuthenticated: false,
      orders: (map['orders'] as List? ?? []).map((e) => DeliveryOrder.fromMap(e)).toList(),
      customers: (map['customers'] as List? ?? []).map((e) => Customer.fromMap(e)).toList(),
      wallet: map['wallet'] != null ? WalletStateData.fromMap(map['wallet']) : WalletStateData(),
    );
  }
}

class KhataBloc extends HydratedCubit<KhataState> {
  KhataBloc() : super(KhataState.initial());

  void setPin(String newPin) {
    emit(state.copyWith(pin: newPin, isAuthenticated: true));
  }

  bool authenticate(String inputPin) {
    if (state.pin == inputPin) {
      emit(state.copyWith(isAuthenticated: true));
      return true;
    }
    return false;
  }

  void logout() {
    emit(state.copyWith(isAuthenticated: false));
  }

  void addCustomer(Customer customer) {
    final updatedList = List<Customer>.from(state.customers)..add(customer);
    emit(state.copyWith(customers: updatedList));
  }

  void editCustomer(Customer updatedCustomer) {
    final updatedList = state.customers.map((c) => c.id == updatedCustomer.id ? updatedCustomer : c).toList();
    emit(state.copyWith(customers: updatedList));
  }

  void deleteCustomer(String id) {
    final updatedList = state.customers.where((c) => c.id != id).toList();
    emit(state.copyWith(customers: updatedList));
  }

  void addOrder(DeliveryOrder order) {
    final updatedOrders = List<DeliveryOrder>.from(state.orders)..insert(0, order);
    
    double c = state.wallet.cash;
    double b = state.wallet.bank;
    double ep = state.wallet.easyPaisa;
    double jc = state.wallet.jazzCash;

    if (order.status == 'Paid' && order.paidAmount > 0) {
      switch (order.paymentMode) {
        case 'Cash': c += order.paidAmount; break;
        case 'Bank': b += order.paidAmount; break;
        case 'EasyPaisa': ep += order.paidAmount; break;
        case 'JazzCash': jc += order.paidAmount; break;
      }
    }

    emit(state.copyWith(
      orders: updatedOrders,
      wallet: WalletStateData(cash: c, bank: b, easyPaisa: ep, jazzCash: jc),
    ));
  }

  void settleUdharOrder(String orderId, double paymentReceived, String destinationAccount) {
    double c = state.wallet.cash;
    double b = state.wallet.bank;
    double ep = state.wallet.easyPaisa;
    double jc = state.wallet.jazzCash;

    switch (destinationAccount) {
      case 'Cash': c += paymentReceived; break;
      case 'Bank': b += paymentReceived; break;
      case 'EasyPaisa': ep += paymentReceived; break;
      case 'JazzCash': jc += paymentReceived; break;
    }

    final updatedOrders = state.orders.map((order) {
      if (order.id == orderId) {
        final newPaid = order.paidAmount + paymentReceived;
        final newRemaining = order.totalAmount - newPaid;
        final finalRemaining = newRemaining > 0 ? newRemaining : 0.0;
        final newStatus = finalRemaining == 0 ? 'Paid' : 'Udhar';

        return order.copyWith(
          paidAmount: newPaid,
          remainingAmount: finalRemaining,
          status: newStatus,
        );
      }
      return order;
    }).toList();

    emit(state.copyWith(
      orders: updatedOrders,
      wallet: WalletStateData(cash: c, bank: b, easyPaisa: ep, jazzCash: jc),
    ));
  }

  void transferFunds(String from, String to, double amount) {
    double c = state.wallet.cash;
    double b = state.wallet.bank;
    double ep = state.wallet.easyPaisa;
    double jc = state.wallet.jazzCash;

    switch (from) {
      case 'Cash': c -= amount; break;
      case 'Bank': b -= amount; break;
      case 'EasyPaisa': ep -= amount; break;
      case 'JazzCash': jc -= amount; break;
    }
    switch (to) {
      case 'Cash': c += amount; break;
      case 'Bank': b += amount; break;
      case 'EasyPaisa': ep += amount; break;
      case 'JazzCash': jc += amount; break;
    }

    emit(state.copyWith(
      wallet: WalletStateData(cash: c, bank: b, easyPaisa: ep, jazzCash: jc),
    ));
  }

  void injectMoney(String account, double amount) {
    double c = state.wallet.cash;
    double b = state.wallet.bank;
    double ep = state.wallet.easyPaisa;
    double jc = state.wallet.jazzCash;

    switch (account) {
      case 'Cash': c += amount; break;
      case 'Bank': b += amount; break;
      case 'EasyPaisa': ep += amount; break;
      case 'JazzCash': jc += amount; break;
    }

    emit(state.copyWith(
      wallet: WalletStateData(cash: c, bank: b, easyPaisa: ep, jazzCash: jc),
    ));
  }

  @override
  KhataState? fromJson(Map<String, dynamic> json) => KhataState.fromMap(json);

  @override
  Map<String, dynamic>? toJson(KhataState state) => state.toMap();
}

// ==========================================
// 3. MAIN APP & THEME CONFIGURATION
// ==========================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: await getApplicationDocumentsDirectory(),
  );
  runApp(const DeliveryKhataApp());
}

class DeliveryKhataApp extends StatelessWidget {
  const DeliveryKhataApp({super.key});

  static const Color primaryRed = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => KhataBloc(),
      child: MaterialApp(
        title: 'Durshal Delivery Khata',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: primaryRed,
          colorScheme: ColorScheme.fromSeed(
            seedColor: primaryRed,
            primary: primaryRed,
            secondary: Colors.orangeAccent,
          ),
          scaffoldBackgroundColor: const Color(0xFFF4F5F7),
          appBarTheme: const AppBarTheme(
            backgroundColor: primaryRed, 
            foregroundColor: Colors.white,
            elevation: 2,
            centerTitle: true,
            titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: primaryRed,
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            type: BottomNavigationBarType.fixed,
            elevation: 10,
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

// ==========================================
// 4. AUTHENTICATION & PIN SCREENS
// ==========================================

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KhataBloc, KhataState>(
      builder: (context, state) {
        if (state.pin == null || state.pin!.isEmpty) {
          return const CreatePinScreen();
        }
        if (!state.isAuthenticated) {
          return const EnterPinScreen();
        }
        return const MainHomeScreen();
      },
    );
  }
}

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security Setup')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 70, color: DeliveryKhataApp.primaryRed),
            const SizedBox(height: 20),
            const Text(
              'Select your PIN & remember for future use',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(labelText: 'Enter 4-Digit PIN', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(labelText: 'Confirm 4-Digit PIN', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_pinController.text.length == 4 && _pinController.text == _confirmPinController.text) {
                  context.read<KhataBloc>().setPin(_pinController.text);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PINs do not match or are invalid.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DeliveryKhataApp.primaryRed,
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Save Security PIN', style: TextStyle(color: Colors.white, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}

class EnterPinScreen extends StatefulWidget {
  const EnterPinScreen({super.key});

  @override
  State<EnterPinScreen> createState() => _EnterPinScreenState();
}

class _EnterPinScreenState extends State<EnterPinScreen> {
  final _pinController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security Verification')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 70, color: DeliveryKhataApp.primaryRed),
            const SizedBox(height: 20),
            const Text(
              'Please enter your security PIN to access Delivery Khata',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(labelText: 'Enter Security PIN', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final success = context.read<KhataBloc>().authenticate(_pinController.text);
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incorrect Security PIN.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DeliveryKhataApp.primaryRed,
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Unlock App', style: TextStyle(color: Colors.white, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 5. MAIN NAVIGATION & TABS
// ==========================================

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DeliveriesScreen(),
    const CustomersScreen(),
    const WalletScreen(),
    const HistoryScreen(),
    const SummaryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: 'Deliveries'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Customers'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Summary'),
        ],
      ),
    );
  }
}

// ==========================================
// 6. DELIVERIES TAB
// ==========================================

class DeliveriesScreen extends StatelessWidget {
  const DeliveriesScreen({super.key});

  void _openNewOrderBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NewOrderBottomSheet(),
    );
  }

  void _openSettleUdharDialog(BuildContext context, DeliveryOrder order) {
    showDialog(
      context: context,
      builder: (context) => SettleUdharDialog(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Durshal Delivery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline),
            onPressed: () => context.read<KhataBloc>().logout(),
          )
        ],
      ),
      body: BlocBuilder<KhataBloc, KhataState>(
        builder: (context, state) {
          final runningOrders = state.orders.where((o) => o.status == 'Udhar').toList();
          final paidOrders = state.orders.where((o) => o.status == 'Paid').toList();
          final displayOrders = [...runningOrders, ...paidOrders];

          if (displayOrders.isEmpty) {
            return const Center(child: Text('No order records found. Tap + to create one.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: displayOrders.length,
            itemBuilder: (context, index) {
              final order = displayOrders[index];
              final isPaid = order.status == 'Paid';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Address: ${order.customerAddress}'),
                      Text('Total Bill: Rs. ${order.totalAmount.toStringAsFixed(1)} (DC: Rs. ${order.deliveryCharges})'),
                      if (!isPaid) ...[
                        Text('Received: Rs. ${order.paidAmount.toStringAsFixed(1)}', style: const TextStyle(color: Colors.green)),
                        Text('Remaining Udhar: Rs. ${order.remainingAmount.toStringAsFixed(1)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                      Text(DateFormat('dd MMM yyyy, hh:mm a').format(order.dateTime), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPaid ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPaid ? 'Paid' : 'Udhar',
                      style: TextStyle(color: isPaid ? Colors.green.shade900 : Colors.red.shade900, fontWeight: FontWeight.bold),
                    ),
                  ),
                  onTap: () {
                    if (!isPaid) {
                      _openSettleUdharDialog(context, order);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openNewOrderBottomSheet(context),
        backgroundColor: DeliveryKhataApp.primaryRed,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class SettleUdharDialog extends StatefulWidget {
  final DeliveryOrder order;
  const SettleUdharDialog({super.key, required this.order});

  @override
  State<SettleUdharDialog> createState() => _SettleUdharDialogState();
}

class _SettleUdharDialogState extends State<SettleUdharDialog> {
  late TextEditingController _paymentController;
  String _selectedAccount = 'Cash';

  @override
  void initState() {
    super.initState();
    _paymentController = TextEditingController(text: widget.order.remainingAmount.toStringAsFixed(1));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Settle Udhar: ${widget.order.customerName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Order Bill: Rs. ${widget.order.totalAmount.toStringAsFixed(1)}'),
          Text('Already Paid: Rs. ${widget.order.paidAmount.toStringAsFixed(1)}'),
          Text('Current Remaining Udhar: Rs. ${widget.order.remainingAmount.toStringAsFixed(1)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 16),
          TextField(
            controller: _paymentController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Received Payment Amount (Rs.)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedAccount,
            decoration: const InputDecoration(labelText: 'Deposit To Wallet Account', border: OutlineInputBorder()),
            items: ['Cash', 'Bank', 'EasyPaisa', 'JazzCash'].map((acc) => DropdownMenuItem(value: acc, child: Text(acc))).toList(),
            onChanged: (val) => setState(() => _selectedAccount = val!),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final amt = double.tryParse(_paymentController.text) ?? 0.0;
            if (amt > 0) {
              context.read<KhataBloc>().settleUdharOrder(widget.order.id, amt, _selectedAccount);
            }
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: DeliveryKhataApp.primaryRed),
          child: const Text('Receive Payment', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// ==========================================
// 7. CUSTOMERS TAB
// ==========================================

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  void _openAddCustomerDialog(BuildContext context, {Customer? customerToEdit}) {
    showDialog(
      context: context,
      builder: (context) => CustomerFormDialog(customerToEdit: customerToEdit),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customers Directory')),
      body: BlocBuilder<KhataBloc, KhataState>(
        builder: (context, state) {
          if (state.customers.isEmpty) {
            return const Center(child: Text('No customers registered. Tap + to add one.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: state.customers.length,
            itemBuilder: (context, index) {
              final c = state.customers[index];
              return Card(
                elevation: 1.5,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: DeliveryKhataApp.primaryRed,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Phone: ${c.phoneNumber}\nAddress: ${c.address}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _openAddCustomerDialog(context, customerToEdit: c),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Customer'),
                              content: Text('Are you sure you want to delete ${c.name}?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () {
                                    context.read<KhataBloc>().deleteCustomer(c.id);
                                    Navigator.pop(ctx);
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddCustomerDialog(context),
        backgroundColor: DeliveryKhataApp.primaryRed,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}

class CustomerFormDialog extends StatefulWidget {
  final Customer? customerToEdit;
  const CustomerFormDialog({super.key, this.customerToEdit});

  @override
  State<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customerToEdit?.name ?? '');
    _phoneController = TextEditingController(text: widget.customerToEdit?.phoneNumber ?? '');
    _addressController = TextEditingController(text: widget.customerToEdit?.address ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.customerToEdit != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Customer' : 'Add New Customer'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Customer Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'WhatsApp Phone Number', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isEmpty) return;

            final customer = Customer(
              id: widget.customerToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
              name: _nameController.text,
              phoneNumber: _phoneController.text,
              address: _addressController.text,
            );

            if (isEdit) {
              context.read<KhataBloc>().editCustomer(customer);
            } else {
              context.read<KhataBloc>().addCustomer(customer);
            }
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: DeliveryKhataApp.primaryRed),
          child: Text(isEdit ? 'Update' : 'Save Customer', style: const TextStyle(color: Colors.white)),
        )
      ],
    );
  }
}

// ==========================================
// 8. WALLET TAB & INJECT MONEY
// ==========================================

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  void _openTransferFundsDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const TransferFundsDialog());
  }

  void _openInjectMoneyDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const InjectMoneyDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card),
            tooltip: 'Inject Money / Top-up',
            onPressed: () => _openInjectMoneyDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Transfer Balance',
            onPressed: () => _openTransferFundsDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<KhataBloc, KhataState>(
        builder: (context, state) {
          final w = state.wallet;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildWalletCard('Cash Account', w.cash, Colors.green),
              _buildWalletCard('Bank Account', w.bank, Colors.blue),
              _buildWalletCard('EasyPaisa Account', w.easyPaisa, Colors.lightGreen),
              _buildWalletCard('JazzCash Account', w.jazzCash, DeliveryKhataApp.primaryRed),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWalletCard(String title, double balance, Color accentColor) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(width: 5, height: 25, color: accentColor),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            Text('Rs. ${balance.toStringAsFixed(1)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class InjectMoneyDialog extends StatefulWidget {
  const InjectMoneyDialog({super.key});

  @override
  State<InjectMoneyDialog> createState() => _InjectMoneyDialogState();
}

class _InjectMoneyDialogState extends State<InjectMoneyDialog> {
  String _selectedAccount = 'Cash';
  final _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Inject Money / Top-up Wallet'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedAccount,
            decoration: const InputDecoration(labelText: 'Target Account'),
            items: ['Cash', 'Bank', 'EasyPaisa', 'JazzCash'].map((acc) => DropdownMenuItem(value: acc, child: Text(acc))).toList(),
            onChanged: (val) => setState(() => _selectedAccount = val!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Amount (Rs.)', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final amt = double.tryParse(_amountController.text) ?? 0.0;
            if (amt > 0) {
              context.read<KhataBloc>().injectMoney(_selectedAccount, amt);
            }
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: DeliveryKhataApp.primaryRed),
          child: const Text('Deposit Funds', style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }
}

class TransferFundsDialog extends StatefulWidget {
  const TransferFundsDialog({super.key});

  @override
  State<TransferFundsDialog> createState() => _TransferFundsDialogState();
}

class _TransferFundsDialogState extends State<TransferFundsDialog> {
  String _fromWallet = 'Cash';
  String _toWallet = 'Bank';
  final _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Transfer Funds Between Accounts'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _fromWallet,
            decoration: const InputDecoration(labelText: 'Source Account'),
            items: ['Cash', 'Bank', 'EasyPaisa', 'JazzCash'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (val) => setState(() => _fromWallet = val!),
          ),
          DropdownButtonFormField<String>(
            value: _toWallet,
            decoration: const InputDecoration(labelText: 'Destination Account'),
            items: ['Cash', 'Bank', 'EasyPaisa', 'JazzCash'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (val) => setState(() => _toWallet = val!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Transfer Amount (Rs.)', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final amt = double.tryParse(_amountController.text) ?? 0.0;
            if (amt > 0 && _fromWallet != _toWallet) {
              context.read<KhataBloc>().transferFunds(_fromWallet, _toWallet, amt);
            }
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: DeliveryKhataApp.primaryRed),
          child: const Text('Transfer', style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }
}

// ==========================================
// 9. HISTORY & SUMMARY TABS
// ==========================================

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History Logs')),
      body: BlocBuilder<KhataBloc, KhataState>(
        builder: (context, state) {
          if (state.orders.isEmpty) {
            return const Center(child: Text('History log is currently clean.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: state.orders.length,
            itemBuilder: (context, index) {
              final item = state.orders[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    item.status == 'Paid' ? Icons.check_circle : Icons.hourglass_top,
                    color: item.status == 'Paid' ? Colors.green : DeliveryKhataApp.primaryRed,
                  ),
                  title: Text(item.customerName),
                  subtitle: Text('Total: Rs. ${item.totalAmount} | Received: Rs. ${item.paidAmount}\nMode: ${item.paymentMode}'),
                  trailing: Text(DateFormat('dd/MM\nhh:mm a').format(item.dateTime), textAlign: TextAlign.right),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Summary Overview')),
      body: BlocBuilder<KhataBloc, KhataState>(
        builder: (context, state) {
          double totalEarned = 0.0;
          double totalUdhar = 0.0;
          int completedDeliveries = 0;

          for (var order in state.orders) {
            totalEarned += order.paidAmount;
            totalUdhar += order.remainingAmount;
            if (order.status == 'Paid') {
              completedDeliveries++;
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Business Performance Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildMetricCard('Total Received Income', 'Rs. ${totalEarned.toStringAsFixed(1)}', Colors.green, Icons.monetization_on),
                _buildMetricCard('Outstanding Market Udhar', 'Rs. ${totalUdhar.toStringAsFixed(1)}', DeliveryKhataApp.primaryRed, Icons.hourglass_empty),
                _buildMetricCard('Completed Orders', '$completedDeliveries Orders', Colors.blue, Icons.local_shipping),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color col, IconData icon) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: col.withOpacity(0.1), child: Icon(icon, color: col)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        trailing: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: col)),
      ),
    );
  }
}

// ==========================================
// 10. NEW ORDER BOTTOM SHEET (DYNAMIC ITEMS & AUTOMATED CALCULATIONS)
// ==========================================

class NewOrderBottomSheet extends StatefulWidget {
  const NewOrderBottomSheet({super.key});

  @override
  State<NewOrderBottomSheet> createState() => _NewOrderBottomSheetState();
}

class _NewOrderBottomSheetState extends State<NewOrderBottomSheet> {
  Customer? _selectedCustomer;
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _deliveryChargesController = TextEditingController(text: '0');
  
  String _selectedPaymentMode = 'Cash';

  List<OrderItem> _items = [
    OrderItem(),
    OrderItem(),
    OrderItem(),
  ];

  void _addThreeMoreItems() {
    setState(() {
      _items.add(OrderItem());
      _items.add(OrderItem());
      _items.add(OrderItem());
    });
  }

  double get _itemsSubtotal {
    double sum = 0.0;
    for (var item in _items) {
      sum += (item.quantity * item.price);
    }
    return sum;
  }

  double get _grandTotal {
    final dc = double.tryParse(_deliveryChargesController.text) ?? 0.0;
    return _itemsSubtotal + dc;
  }

  void _triggerWhatsAppMessage(String name, String phone, double totalAmount) async {
    String cleanPhone = phone.replaceAll(RegExp(r'\+|\s+|-'), '');
    if (!cleanPhone.startsWith('92') && cleanPhone.startsWith('0')) {
      cleanPhone = '92${cleanPhone.substring(1)}';
    }

    final message = "Hello $name, your order from Durshal Delivery has been placed. Grand Total: Rs. ${totalAmount.toStringAsFixed(1)}. Thank you!";
    final url = "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}";

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersList = context.watch<KhataBloc>().state.customers;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 20, left: 16, right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('New Delivery Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 10),

            // Select Customer Dropdown
            DropdownButtonFormField<Customer>(
              value: _selectedCustomer,
              decoration: const InputDecoration(labelText: 'Select Registered Customer', border: OutlineInputBorder()),
              items: customersList.map((c) {
                return DropdownMenuItem<Customer>(
                  value: c,
                  child: Text('${c.name} (${c.phoneNumber})'),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCustomer = val;
                  if (val != null) {
                    _phoneController.text = val.phoneNumber;
                    _addressController.text = val.address;
                  }
                });
              },
            ),
            const SizedBox(height: 10),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'WhatsApp Phone Number', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Delivery Address', border: OutlineInputBorder())),
            
            const Divider(height: 30, thickness: 1.5),
            const Text('Order Items Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // Items Rows
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          decoration: InputDecoration(labelText: 'Item ${index + 1} Name', border: const OutlineInputBorder()),
                          onChanged: (val) => _items[index].name = val,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            setState(() {
                              _items[index].quantity = int.tryParse(val) ?? 1;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            setState(() {
                              _items[index].price = double.tryParse(val) ?? 0.0;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _addThreeMoreItems,
              icon: const Icon(Icons.add),
              label: const Text('Add 3 More Items'),
            ),

            const SizedBox(height: 12),
            TextField(
              controller: _deliveryChargesController,
              decoration: const InputDecoration(labelText: 'Delivery Charges (Rs.)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Grand Total Bill:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Rs. ${_grandTotal.toStringAsFixed(1)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DeliveryKhataApp.primaryRed)),
                ],
              ),
            ),

            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedPaymentMode,
              decoration: const InputDecoration(labelText: 'Payment Gateway Mode', border: OutlineInputBorder()),
              items: ['Cash', 'Bank', 'EasyPaisa', 'JazzCash', 'Udhar'].map((mode) => DropdownMenuItem(value: mode, child: Text(mode))).toList(),
              onChanged: (val) => setState(() => _selectedPaymentMode = val!),
            ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_selectedCustomer == null && _phoneController.text.isEmpty) return;

                final custName = _selectedCustomer?.name ?? 'Guest Customer';
                final phone = _phoneController.text;
                final address = _addressController.text;
                final dc = double.tryParse(_deliveryChargesController.text) ?? 0.0;
                final total = _grandTotal;

                final isUdhar = _selectedPaymentMode == 'Udhar';
                final initialPaid = isUdhar ? 0.0 : total;
                final initialRemaining = isUdhar ? total : 0.0;
                final initialStatus = isUdhar ? 'Udhar' : 'Paid';

                final order = DeliveryOrder(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  customerName: custName,
                  phoneNumber: phone,
                  customerAddress: address,
                  items: _items.where((i) => i.name.isNotEmpty).toList(),
                  deliveryCharges: dc,
                  totalAmount: total,
                  paidAmount: initialPaid,
                  remainingAmount: initialRemaining,
                  paymentMode: _selectedPaymentMode,
                  status: initialStatus,
                  dateTime: DateTime.now(),
                );

                context.read<KhataBloc>().addOrder(order);
                Navigator.pop(context);

                if (phone.isNotEmpty) {
                  _triggerWhatsAppMessage(custName, phone, total);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DeliveryKhataApp.primaryRed,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Place Order + Send WhatsApp Message', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
