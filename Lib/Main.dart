import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

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
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      phoneNumber: map['phoneNumber']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
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
      orders: (map['orders'] as List? ?? []).map((e) => DeliveryOrder.fromMap(Map<String, dynamic>.from(e))).toList(),
      customers: (map['customers'] as List? ?? []).map((e) => Customer.fromMap(Map<String, dynamic>.from(e))).toList(),
      wallet: map['wallet'] != null ? WalletStateData.fromMap(Map<String, dynamic>.from(map['wallet'])) : WalletStateData(),
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

  void lendMoneyDirectly(Customer customer, double amount, String sourceAccount) {
    double c = state.wallet.cash;
    double b = state.wallet.bank;
    double ep = state.wallet.easyPaisa;
    double jc = state.wallet.jazzCash;

    switch (sourceAccount) {
      case 'Cash': c -= amount; break;
      case 'Bank': b -= amount; break;
      case 'EasyPaisa': ep -= amount; break;
      case 'JazzCash': jc -= amount; break;
    }

    final udharOrder = DeliveryOrder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerName: customer.name,
      phoneNumber: customer.phoneNumber,
      customerAddress: customer.address,
      items: [OrderItem(name: 'Direct Cash Lending ($sourceAccount)', quantity: 1, price: amount)],
      deliveryCharges: 0.0,
      totalAmount: amount,
      paidAmount: 0.0,
      remainingAmount: amount,
      paymentMode: 'Udhar ($sourceAccount)',
      status: 'Udhar',
      dateTime: DateTime.now(),
    );

    final updatedOrders = List<DeliveryOrder>.from(state.orders)..insert(0, udharOrder);

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

  static const Color primaryGray = Color(0xFF3A3F44);
  static const Color accentOrange = Color(0xFFFF7619);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => KhataBloc(),
      child: MaterialApp(
        title: 'Durshal Delivery Khata',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: primaryGray,
          scaffoldBackgroundColor: const Color(0xFFF4F4F5),
          colorScheme: ColorScheme.fromSeed(
            seedColor: primaryGray,
            primary: primaryGray,
            secondary: accentOrange,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: primaryGray, 
            foregroundColor: Colors.white,
            elevation: 2,
            centerTitle: true,
            titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: accentOrange,
            unselectedItemColor: Color(0xFF71717A),
            selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            type: BottomNavigationBarType.fixed,
            elevation: 10,
          ),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

// ==========================================
// UTILITY: WHATSAPP DIRECT SENDER
// ==========================================

void sendWhatsAppInvoice({
  required String phone,
  required String message,
}) async {
  String cleanPhone = phone.replaceAll(RegExp(r'\+|\s+|-'), '');
  if (!cleanPhone.startsWith('92') && cleanPhone.startsWith('0')) {
    cleanPhone = '92${cleanPhone.substring(1)}';
  }

  final encodedMsg = Uri.encodeComponent(message);
  final whatsappUri = Uri.parse("whatsapp://send?phone=$cleanPhone&text=$encodedMsg");
  final webUri = Uri.parse("https://wa.me/$cleanPhone?text=$encodedMsg");

  try {
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  } catch (_) {
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
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
            const Icon(Icons.security, size: 70, color: DeliveryKhataApp.primaryGray),
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
                backgroundColor: DeliveryKhataApp.primaryGray,
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
            const Icon(Icons.lock, size: 70, color: DeliveryKhataApp.primaryGray),
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
                backgroundColor: DeliveryKhataApp.primaryGray,
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
        backgroundColor: DeliveryKhataApp.primaryGray,
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
          style: ElevatedButton.styleFrom(backgroundColor: DeliveryKhataApp.primaryGray),
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
                    backgroundColor: DeliveryKhataApp.primaryGray,
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
        backgroundColor: DeliveryKhataApp.primaryGray,
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

  Future<void> _pickFromContacts() async {
    try {
      if (await FlutterContacts.requestPermission()) {
        final contact = await FlutterContacts.openExternalPick();
        if (contact != null) {
          final fullContact = await FlutterContacts.getContact(contact.id);
          if (fullContact != null) {
            setState(() {
              _nameController.text = fullContact.displayName;
              if (fullContact.phones.isNotEmpty) {
                _phoneController.text = fullContact.phones.first.number;
              }
            });
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contacts permission is required to pick a contact.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking contact: $e')),
        );
      }
    }
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
            if (!isEdit) ...[
              OutlinedButton.icon(
                onPressed: _pickFromContacts,
                icon: const Icon(Icons.contacts, color: DeliveryKhataApp.accentOrange),
                label: const Text('Pick from Phone Contacts', style: TextStyle(color: DeliveryKhataApp.accentOrange, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: DeliveryKhataApp.accentOrange),
                  minimumSize: const Size.fromHeight(45),
                ),
              ),
              const SizedBox(height: 12),
            ],
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
          style: ElevatedButton.styleFrom(backgroundColor: DeliveryKhataApp.primaryGray),
          child: Text(isEdit ? 'Update' : 'Save Customer', style: const TextStyle(color: Colors.white)),
        )
      ],
    );
  }
}

// ==========================================
// 8. WALLET TAB (WITH DIRECT LENDING DIALOG)
// ==========================================

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  void _openTransferFundsDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const TransferFundsDialog());
  }

  void _openInjectMoneyDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const InjectMoneyDialog());
  }

  void _openDirectLendingDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const DirectLendingDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card),
            tooltip: 'Deposit / Withdraw',
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

          double totalLending = 0.0;
          for (var o in state.orders) {
            totalLending += o.remainingAmount;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildWalletCard('Cash Account', w.cash, Colors.green),
              _buildWalletCard('Bank Account', w.bank, Colors.blue),
              _buildWalletCard('EasyPaisa Account', w.easyPaisa, Colors.lightGreen),
              _buildWalletCard('JazzCash Account', w.jazzCash, DeliveryKhataApp.accentOrange),
              const SizedBox(height: 8),

              Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFF1E6),
                    child: Icon(Icons.handshake_outlined, color: DeliveryKhataApp.accentOrange),
                  ),
                  title: const Text(
                    'Lending / Udhar Account',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text('Total Market Udhar: Rs. ${totalLending.toStringAsFixed(1)}'),
                  trailing: const Icon(Icons.add_circle_outline, color: DeliveryKhataApp.accentOrange),
                  onTap: () => _openDirectLendingDialog(context),
                ),
              ),
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

// DIRECT LEND MONEY DIALOG (NEW FEATURE)
class DirectLendingDialog extends StatefulWidget {
  const DirectLendingDialog({super.key});

  @override
  State<DirectLendingDialog> createState() => _DirectLendingDialogState();
}

class _DirectLendingDialogState extends State<DirectLendingDialog> {
  Customer? _selectedCustomer;
  String _selectedSourceAccount = 'Cash';
  final _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final customersList = context.watch<KhataBloc>().state.customers;

    return AlertDialog(
      title: const Text('Lend Money / Give Udhar'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Customer>(
              value: _selectedCustomer,
              decoration: const InputDecoration(labelText: 'Select Customer', border: OutlineInputBorder()),
              items: customersList.map((c) {
                return DropdownMenuItem<Customer>(
                  value: c,
                  child: Text('${c.name} (${c.phoneNumber})'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedCustomer = val),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedSourceAccount,
              decoration: const InputDecoration(labelText: 'Select Account Source', border: OutlineInputBorder()),
              items: ['Cash', 'Bank', 'EasyPaisa', 'JazzCash'].map((acc) => DropdownMenuItem(value: acc, child: Text(acc))).toList(),
              onChanged: (val) => setState(() => _selectedSourceAccount = val!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (Rs.)', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_selectedCustomer == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a customer.')),
              );
              return;
            }

            final amt = double.tryParse(_amountController.text) ?? 0.0;
            if (amt <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a valid amount.')),
              );
              return;
            }

            context.read<KhataBloc>().lendMoneyDirectly(_selectedCustomer!, amt, _selectedSourceAccount);
            Navigator.pop(context);

            if (_selectedCustomer!.phoneNumber.isNotEmpty) {
              final message = "🚚 *DURSHAL DELIVERY KHATA*\n\n"
                  "Hello ${_selectedCustomer!.name},\n"
                  "An amount of *Rs. ${amt.toStringAsFixed(1)}* has been credited to your Udhar account via *$_selectedSourceAccount*.\n\n"
                  "Thank you!";
              sendWhatsAppInvoice(phone: _selectedCustomer!.phoneNumber, message: message);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: DeliveryKhataApp.primaryGray),
          child: const Text('Lend Money & Send WhatsApp', style: TextStyle(color: Colors.white)),
        ),
      ],
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
      title: const Text('Deposit / Withdraw Money'),
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
            decoration: const InputDecoration(
              labelText: 'Amount (e.g. 500 or -500 to withdraw)',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final amt = double.tryParse(_amountController.text) ?? 0.0;
            if (amt != 0) {
              context.read<KhataBloc>().injectOrWithdrawMoney(_selectedAccount, amt);
            }
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: DeliveryKhataApp.primaryGray),
          child: const Text('Update Balance', style: TextStyle(color: Colors.white)),
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
          style: ElevatedButton.styleFrom(backgroundColor: DeliveryKhataApp.primaryGray),
          child: const Text('Transfer', style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }
}

// ==========================================
// 9. HISTORY TAB
// ==========================================

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filterType = 'Today';
  DateTime? _selectedDate;
  String? _selectedCustomerFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History Logs')),
      body: BlocBuilder<KhataBloc, KhataState>(
        builder: (context, state) {
          List<DeliveryOrder> filteredOrders = List.from(state.orders);

          if (_filterType == 'Today') {
            final now = DateTime.now();
            filteredOrders = filteredOrders.where((o) =>
                o.dateTime.year == now.year &&
                o.dateTime.month == now.month &&
                o.dateTime.day == now.day).toList();
          } else if (_filterType == 'Specific Date' && _selectedDate != null) {
            filteredOrders = filteredOrders.where((o) =>
                o.dateTime.year == _selectedDate!.year &&
                o.dateTime.month == _selectedDate!.month &&
                o.dateTime.day == _selectedDate!.day).toList();
          }

          if (_selectedCustomerFilter != null && _selectedCustomerFilter != 'All Customers') {
            filteredOrders = filteredOrders.where((o) => o.customerName == _selectedCustomerFilter).toList();
          }

          final customersList = ['All Customers', ...state.customers.map((c) => c.name).toSet()];

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _filterType,
                            decoration: const InputDecoration(labelText: 'Timeframe Filter', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                            items: ['Today', 'All', 'Specific Date'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                            onChanged: (val) async {
                              if (val == 'Specific Date') {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _filterType = 'Specific Date';
                                    _selectedDate = picked;
                                  });
                                }
                              } else {
                                setState(() {
                                  _filterType = val!;
                                  _selectedDate = null;
                                });
                              }
                            },
                          ),
                        ),
                        if (_filterType == 'Specific Date' && _selectedDate != null) ...[
                          const SizedBox(width: 8),
                          Text(DateFormat('dd/MM/yy').format(_selectedDate!), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ]
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCustomerFilter ?? 'All Customers',
                      decoration: const InputDecoration(labelText: 'Filter By Customer', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                      items: customersList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCustomerFilter = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredOrders.isEmpty
                    ? const Center(child: Text('No orders found for the selected filter.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final item = filteredOrders[index];
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                item.status == 'Paid' ? Icons.check_circle : Icons.hourglass_top,
                                color: item.status == 'Paid' ? Colors.green : DeliveryKhataApp.primaryGray,
                              ),
                              title: Text(item.customerName),
                              subtitle: Text('Total: Rs. ${item.totalAmount} | Received: Rs. ${item.paidAmount}\nMode: ${item.paymentMode}'),
                              trailing: Text(DateFormat('dd/MM\nhh:mm a').format(item.dateTime), textAlign: TextAlign.right),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ==========================================
// 10. SUMMARY TAB
// ==========================================

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  String _filterType = 'All Time';
  DateTime? _selectedDate;
  String? _selectedCustomerFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Summary Overview')),
      body: BlocBuilder<KhataBloc, KhataState>(
        builder: (context, state) {
          List<DeliveryOrder> filteredOrders = List.from(state.orders);

          if (_filterType == 'Today') {
            final now = DateTime.now();
            filteredOrders = filteredOrders.where((o) =>
                o.dateTime.year == now.year &&
                o.dateTime.month == now.month &&
                o.dateTime.day == now.day).toList();
          } else if (_filterType == 'Specific Date' && _selectedDate != null) {
            filteredOrders = filteredOrders.where((o) =>
                o.dateTime.year == _selectedDate!.year &&
                o.dateTime.month == _selectedDate!.month &&
                o.dateTime.day == _selectedDate!.day).toList();
          }

          if (_selectedCustomerFilter != null && _selectedCustomerFilter != 'All Customers') {
            filteredOrders = filteredOrders.where((o) => o.customerName == _selectedCustomerFilter).toList();
          }

          final customersList = ['All Customers', ...state.customers.map((c) => c.name).toSet()];

          double totalEarned = 0.0;
          double totalUdhar = 0.0;
          int completedDeliveries = 0;

          for (var order in filteredOrders) {
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
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterType,
                        decoration: const InputDecoration(labelText: 'Period', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        items: ['All Time', 'Today', 'Specific Date'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                        onChanged: (val) async {
                          if (val == 'Specific Date') {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() {
                                _filterType = 'Specific Date';
                                _selectedDate = picked;
                              });
                            }
                          } else {
                            setState(() {
                              _filterType = val!;
                              _selectedDate = null;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCustomerFilter ?? 'All Customers',
                        decoration: const InputDecoration(labelText: 'Customer', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        items: customersList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCustomerFilter = val;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Business Performance Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildMetricCard('Total Received Income', 'Rs. ${totalEarned.toStringAsFixed(1)}', Colors.green, Icons.monetization_on),
                _buildMetricCard('Outstanding Market Udhar', 'Rs. ${totalUdhar.toStringAsFixed(1)}', DeliveryKhataApp.primaryGray, Icons.hourglass_empty),
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
// 11. NEW ORDER BOTTOM SHEET (WITH DETAILED INVOICE)
// ==========================================

class NewOrderBottomSheet extends StatefulWidget {
  const NewOrderBottomSheet({super.key});

  @override
  State<NewOrderBottomSheet> createState() => _NewOrderBottomSheetState();
}

class _NewOrderBottomSheetState extends State<NewOrderBottomSheet> {
  Customer? _selectedCustomer;
  final _deliveryChargesController = TextEditingController(text: '0');
  String _selectedPaymentMode = 'Cash';

  final List<OrderItem> _items = [
    OrderItem(),
    OrderItem(),
    OrderItem(),
  ];

  void _addSingleItem() {
    setState(() {
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

  String _generateDetailedWhatsAppMessage({
    required String customerName,
    required List<OrderItem> validItems,
    required double deliveryCharges,
    required double grandTotal,
    required double paidAmount,
    required double remainingAmount,
    required String paymentMode,
  }) {
    StringBuffer buffer = StringBuffer();
    buffer.writeln("🚚 *DURSHAL DELIVERY ORDER RECEIPT*");
    buffer.writeln("----------------------------------");
    buffer.writeln("👤 *Customer:* $customerName");
    buffer.writeln("📅 *Date:* ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}");
    buffer.writeln("----------------------------------");
    buffer.writeln("📋 *ITEMS ORDERED:*");

    for (int i = 0; i < validItems.length; i++) {
      final item = validItems[i];
      final itemTotal = item.quantity * item.price;
      buffer.writeln("${i + 1}. ${item.name} x${item.quantity} = Rs. ${itemTotal.toStringAsFixed(1)}");
    }

    buffer.writeln("----------------------------------");
    buffer.writeln("📦 *Subtotal:* Rs. ${_itemsSubtotal.toStringAsFixed(1)}");
    buffer.writeln("🛵 *Delivery Charges:* Rs. ${deliveryCharges.toStringAsFixed(1)}");
    buffer.writeln("💰 *Grand Total:* Rs. ${grandTotal.toStringAsFixed(1)}");
    buffer.writeln("----------------------------------");
    buffer.writeln("💳 *Payment Mode:* $paymentMode");
    buffer.writeln("✅ *Paid Amount:* Rs. ${paidAmount.toStringAsFixed(1)}");
    buffer.writeln("📌 *Remaining Balance:* Rs. ${remainingAmount.toStringAsFixed(1)}");
    buffer.writeln("----------------------------------");
    buffer.writeln("Thank you for using Durshal Delivery!");

    return buffer.toString();
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
                });
              },
            ),

            const Divider(height: 30, thickness: 1.5),
            const Text('Order Items Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

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
              onPressed: _addSingleItem,
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
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
                  Text('Rs. ${_grandTotal.toStringAsFixed(1)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DeliveryKhataApp.primaryGray)),
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
                if (_selectedCustomer == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a registered customer first.')),
                  );
                  return;
                }

                final custName = _selectedCustomer!.name;
                final phone = _selectedCustomer!.phoneNumber;
                final address = _selectedCustomer!.address;
                final dc = double.tryParse(_deliveryChargesController.text) ?? 0.0;
                final total = _grandTotal;

                final isUdhar = _selectedPaymentMode == 'Udhar';
                final initialPaid = isUdhar ? 0.0 : total;
                final initialRemaining = isUdhar ? total : 0.0;
                final initialStatus = isUdhar ? 'Udhar' : 'Paid';

                final validItems = _items.where((i) => i.name.isNotEmpty).toList();

                final order = DeliveryOrder(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  customerName: custName,
                  phoneNumber: phone,
                  customerAddress: address,
                  items: validItems,
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
                  final detailedMessage = _generateDetailedWhatsAppMessage(
                    customerName: custName,
                    validItems: validItems,
                    deliveryCharges: dc,
                    grandTotal: total,
                    paidAmount: initialPaid,
                    remainingAmount: initialRemaining,
                    paymentMode: _selectedPaymentMode,
                  );

                  sendWhatsAppInvoice(phone: phone, message: detailedMessage);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DeliveryKhataApp.primaryGray,
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
