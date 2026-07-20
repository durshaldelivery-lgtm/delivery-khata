import 'package0:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
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

class PaymentReceipt {
  final double amount;
  final String sourceAccount;
  final DateTime dateTime;

  PaymentReceipt({
    required this.amount,
    required this.sourceAccount,
    required this.dateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'sourceAccount': sourceAccount,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  factory PaymentReceipt.fromMap(Map<String, dynamic> map) {
    return PaymentReceipt(
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      sourceAccount: map['sourceAccount'] ?? 'Cash',
      dateTime: DateTime.parse(map['dateTime']),
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
  final List<PaymentReceipt> paymentHistory;

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
    this.paymentHistory = const [],
  });

  DeliveryOrder copyWith({
    double? paidAmount,
    double? remainingAmount,
    String? status,
    List<PaymentReceipt>? paymentHistory,
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
      paymentHistory: paymentHistory ?? this.paymentHistory,
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
      'paymentHistory': paymentHistory.map((x) => x.toMap()).toList(),
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
      paymentHistory: (map['paymentHistory'] as List? ?? []).map((x) => PaymentReceipt.fromMap(x)).toList(),
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

        final newReceipt = PaymentReceipt(
          amount: paymentReceived,
          sourceAccount: destinationAccount,
          dateTime: DateTime.now(),
        );

        final updatedHistory = List<PaymentReceipt>.from(order.paymentHistory)..add(newReceipt);

        return order.copyWith(
          paidAmount: newPaid,
          remainingAmount: finalRemaining,
          status: newStatus,
          paymentHistory: updatedHistory,
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

  void injectOrWithdrawMoney(String account, double amount) {
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
                      Text('Total Bill: Rs. ${order.totalAmount.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (!isPaid) ...[
                        Text('Received: Rs. ${order.paidAmount.toStringAsFixed(1)}', style: const TextStyle(color: Colors.green)),
                        Text('Remaining Udhar: Rs. ${order.remainingAmount.toStringAsFixed(1)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                      if (order.paymentHistory.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        const Text('Payment Logs:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ...order.paymentHistory.map((receipt) => Text(
                          '• Rs. ${receipt.amount.toStringAsFixed(1)} via ${receipt.sourceAccount} on ${DateFormat('dd MMM, hh:mm a').format(receipt.dateTime)}',
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                        )),
                      ],
                      const SizedBox(height: 4),
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
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _openAddCustomerDialog(context, customerToEdit: c);
                      } else if (value == 'delete') {
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
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
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
        child: const Icon(Icons.add, color: Colors.white),
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
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.customerToEdit != null) {
      _nameController.text = widget.customerToEdit!.name;
      _phoneController.text = widget.customerToEdit!.phoneNumber;
      _addressController.text = widget.customerToEdit!.address;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customerToEdit != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit Customer' : 'Add New Customer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Customer Name')),
          TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number')),
          TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              final newCust = Customer(
                id: isEditing ? widget.customerToEdit!.id : DateTime.now().millisecondsSinceEpoch.toString(),
                name: _nameController.text,
                phoneNumber: _phoneController.text,
                address: _addressController.text,
              );
              if (isEditing) {
                context.read<KhataBloc>().editCustomer(newCust);
              } else {
                context.read<KhataBloc>().addCustomer(newCust);
              }
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: DeliveryKhataApp.primaryRed),
          child: Text(isEditing ? 'Update' : 'Save', style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// ==========================================
// 8. NEW ORDER BOTTOM SHEET (WITHOUT WHATSAPP)
// ==========================================

class NewOrderBottomSheet extends StatefulWidget {
  const NewOrderBottomSheet({super.key});

  @override
  State<NewOrderBottomSheet> createState() => _NewOrderBottomSheetState();
}

class _NewOrderBottomSheetState extends State<NewOrderBottomSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _deliveryChargesController = TextEditingController(text: '0');
  final _paidAmountController = TextEditingController(text: '0');

  List<OrderItem> items = [OrderItem()];
  String _paymentMode = 'Cash';

  void _saveOrder() {
    double itemTotal = items.fold(0.0, (sum, item) => sum + (item.quantity * item.price));
    double delivery = double.tryParse(_deliveryChargesController.text) ?? 0.0;
    double total = itemTotal + delivery;
    double paid = double.tryParse(_paidAmountController.text) ?? 0.0;

    if (_paymentMode == 'Udhar') {
      paid = 0.0;
    } else if (paid > total) {
      paid = total;
    }

    double remaining = total - paid;
    String status = remaining <= 0 ? 'Paid' : 'Udhar';

    final newOrder = DeliveryOrder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerName: _nameController.text.isEmpty ? 'Walk-in Customer' : _nameController.text,
      phoneNumber: _phoneController.text,
      customerAddress: _addressController.text,
      items: items,
      deliveryCharges: delivery,
      totalAmount: total,
      paidAmount: paid,
      remainingAmount: remaining,
      paymentMode: _paymentMode,
      status: status,
      dateTime: DateTime.now(),
      paymentHistory: paid > 0
          ? [
              PaymentReceipt(
                amount: paid,
                sourceAccount: _paymentMode,
                dateTime: DateTime.now(),
              )
            ]
          : [],
    );

    context.read<KhataBloc>().addOrder(newOrder);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    double itemTotal = items.fold(0.0, (sum, item) => sum + (item.quantity * item.price));
    double delivery = double.tryParse(_deliveryChargesController.text) ?? 0.0;
    double grantTotal = itemTotal + delivery;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Order Entry', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Customer Name', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Delivery Address', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            const Text('Order Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...items.asMap().entries.map((entry) {
              int idx = entry.key;
              OrderItem item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Item Name', border: OutlineInputBorder()),
                        onChanged: (val) => item.name = val,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder()),
                        onChanged: (val) => setState(() => item.quantity = int.tryParse(val) ?? 1),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()),
                        onChanged: (val) => setState(() => item.price = double.tryParse(val) ?? 0.0),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        if (items.length > 1) {
                          setState(() => items.removeAt(idx));
                        }
                      },
                    )
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: () => setState(() => items.add(OrderItem())),
              icon: const Icon(Icons.add),
              label: const Text('Add Another Item'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _deliveryChargesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Delivery Charges (Rs.)', border: OutlineInputBorder()),
              onChanged: (val) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _paymentMode,
                    decoration: const InputDecoration(labelText: 'Payment Mode', border: OutlineInputBorder()),
                    items: ['Cash', 'Bank', 'EasyPaisa', 'JazzCash', 'Udhar'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) => setState(() => _paymentMode = val!),
                  ),
                ),
                if (_paymentMode != 'Udhar') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _paidAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Paid Amount (Rs.)', border: OutlineInputBorder()),
                    ),
                  ),
                ]
              ],
            ),
            const SizedBox(height: 16),
            Text('Grand Total: Rs. ${grantTotal.toStringAsFixed(1)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DeliveryKhataApp.primaryRed)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveOrder,
                style: ElevatedButton.styleFrom(backgroundColor: DeliveryKhataApp.primaryRed),
                child: const Text('Save Order', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 9. WALLET TAB
// ==========================================

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  void _openTransferDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const TransferFundsDialog());
  }

  void _openInjectWithdrawDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const InjectWithdrawDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet Balances')),
      body: BlocBuilder<KhataBloc, KhataState>(
        builder: (context, state) {
          final w = state.wallet;
          double grandTotalWallet = w.cash + w.bank + w.easyPaisa + w.jazzCash;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  color: DeliveryKhataApp.primaryRed,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text('Total Net Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('Rs. ${grandTotalWallet.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _buildWalletCard('Cash In Hand', w.cash, Icons.money, Colors.green),
                      _buildWalletCard('Bank Account', w.bank, Icons.account_balance, Colors.blue),
                      _buildWalletCard('EasyPaisa', w.easyPaisa, Icons.phone_android, Colors.green.shade700),
                      _buildWalletCard('JazzCash', w.jazzCash, Icons.payment, Colors.red.shade700),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openTransferDialog(context),
                        icon: const Icon(Icons.swap_horiz, color: Colors.white),
                        label: const Text('Transfer Funds', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openInjectWithdrawDialog(context),
                        icon: const Icon(Icons.add_card, color: Colors.white),
                        label: const Text('Adjust Cash', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWalletCard(String title, double amount, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text('Rs. ${amount.toStringAsFixed(1)}', style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class TransferFundsDialog extends StatefulWidget {
  const TransferFundsDialog({super.key});

  @override
  State<TransferFundsDialog> createState() => _TransferFundsDialogState();
}

class _TransferFundsDialogState extends State<TransferFundsDialog> {
  String _fromAccount = 'Cash';
  String _toAccount = 'Bank';
  final _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Internal Transfer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _fromAccount,
            decoration: const InputDecoration(labelText: 'From Account'),
            items: ['Cash', 'Bank', 'EasyPaisa', 'JazzCash'].map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
            onChanged: (val) => setState(() => _fromAccount = val!),
          ),
          DropdownButtonFormField<String>(
            value: _toAccount,
            decoration: const InputDecoration(labelText: 'To Account'),
            items: ['Cash', 'Bank', 'EasyPaisa', 'JazzCash'].map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
            onChanged: (val) => setState(() => _toAccount = val!),
          ),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Transfer Amount (Rs.)'),
          )
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final amt = double.tryParse(_amountController.text) ?? 0.0;
            if (amt > 0 && _fromAccount != _toAccount) {
              context.read<KhataBloc>().transferFunds(_fromAccount, _toAccount, amt);
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

class InjectWithdrawDialog extends StatefulWidget {
  const InjectWithdrawDialog({super.key});

  @override
  State<InjectWithdrawDialog> createState() => _InjectWithdrawDialogState();
}

class _InjectWithdrawDialogState extends State<InjectWithdrawDialog> {
  String _account = 'Cash';
  final _amountController = TextEditingController();
  bool _isAddition = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adjust Account Balance'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ChoiceChip(label: const Text('Add Cash'), selected: _isAddition, onSelected: (val) => setState(() => _isAddition = true)),
              const SizedBox(width: 8),
              ChoiceChip(label: const Text('Withdraw'), selected: !_isAddition, onSelected: (val) => setState(() => _isAddition = false)),
            ],
          ),
          DropdownButtonFormField<String>(
            value: _account,
            decoration: const InputDecoration(labelText: 'Account'),
            items: ['Cash', 'Bank', 'EasyPaisa', 'JazzCash'].map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
            onChanged: (val) => setState(() => _account = val!),
          ),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount (Rs.)'),
          )
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            double amt = double.tryParse(_amountController.text) ?? 0.0;
            if (amt > 0) {
              if (!_isAddition) amt = -amt;
              context.read<KhataBloc>().injectOrWithdrawMoney(_account, amt);
            }
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: DeliveryKhataApp.primaryRed),
          child: const Text('Confirm', style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }
}

// ==========================================
// 10. HISTORY TAB
// ==========================================

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order History')),
      body: BlocBuilder<KhataBloc, KhataState>(
        builder: (context, state) {
          if (state.orders.isEmpty) {
            return const Center(child: Text('No order history available.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: state.orders.length,
            itemBuilder: (context, index) {
              final order = state.orders[index];
              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Total: Rs. ${order.totalAmount.toStringAsFixed(1)} | Paid: Rs. ${order.paidAmount.toStringAsFixed(1)}\n${DateFormat('dd MMM yyyy, hh:mm a').format(order.dateTime)}'),
                  trailing: Text(order.status, style: TextStyle(color: order.status == 'Paid' ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// 11. SUMMARY TAB
// ==========================================

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Analytics')),
      body: BlocBuilder<KhataBloc, KhataState>(
        builder: (context, state) {
          double totalRevenue = state.orders.fold(0.0, (sum, o) => sum + o.paidAmount);
          double totalPendingUdhar = state.orders.fold(0.0, (sum, o) => sum + o.remainingAmount);
          int totalOrdersCount = state.orders.length;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSummaryTile('Total Orders Delivered', totalOrdersCount.toString(), Icons.shopping_bag, Colors.blue),
                const SizedBox(height: 12),
                _buildSummaryTile('Total Payments Collected', 'Rs. ${totalRevenue.toStringAsFixed(1)}', Icons.attach_money, Colors.green),
                const SizedBox(height: 12),
                _buildSummaryTile('Total Market Udhar (Receivable)', 'Rs. ${totalPendingUdhar.toStringAsFixed(1)}', Icons.money_off, Colors.red),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryTile(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }
}
