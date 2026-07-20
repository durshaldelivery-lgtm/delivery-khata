import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

// ==========================================
// 1. MODELS & DATA STRUCTURES
// ==========================================

class DeliveryOrder {
  final String id;
  final String customerName;
  final String phoneNumber;
  final double billAmount;
  final String paymentMode; // Cash, Bank, EasyPaisa, JazzCash, Udhar
  final String status;      // Paid, Pending
  final DateTime dateTime;

  DeliveryOrder({
    required this.id,
    required this.customerName,
    required this.phoneNumber,
    required this.billAmount,
    required this.paymentMode,
    required this.status,
    required this.dateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'phoneNumber': phoneNumber,
      'billAmount': billAmount,
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
      billAmount: (map['billAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: map['paymentMode'] ?? 'Cash',
      status: map['status'] ?? 'Paid',
      dateTime: DateTime.parse(map['dateTime']),
    );
  }
}

class ClientContact {
  final String id;
  final String name;
  final String phoneNumber;

  ClientContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
    };
  }

  factory ClientContact.fromMap(Map<String, dynamic> map) {
    return ClientContact(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
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
  final List<DeliveryOrder> orders;
  final List<ClientContact> clients;
  final WalletStateData wallet;

  KhataState({
    required this.orders,
    required this.clients,
    required this.wallet,
  });

  factory KhataState.initial() {
    return KhataState(
      orders: [],
      clients: [],
      wallet: WalletStateData(cash: 3500.0, bank: 1850.0, easyPaisa: 0.0, jazzCash: 1177.0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orders': orders.map((e) => e.toMap()).toList(),
      'clients': clients.map((e) => e.toMap()).toList(),
      'wallet': wallet.toMap(),
    };
  }

  factory KhataState.fromMap(Map<String, dynamic> map) {
    return KhataState(
      orders: (map['orders'] as List? ?? []).map((e) => DeliveryOrder.fromMap(e)).toList(),
      clients: (map['clients'] as List? ?? []).map((e) => ClientContact.fromMap(e)).toList(),
      wallet: map['wallet'] != null ? WalletStateData.fromMap(map['wallet']) : WalletStateData(),
    );
  }
}

class KhataBloc extends HydratedCubit<KhataState> {
  KhataBloc() : super(KhataState.initial());

  void addOrder(DeliveryOrder order) {
    final updatedOrders = List<DeliveryOrder>.from(state.orders)..insert(0, order);
    
    double c = state.wallet.cash;
    double b = state.wallet.bank;
    double ep = state.wallet.easyPaisa;
    double jc = state.wallet.jazzCash;

    if (order.status == 'Paid') {
      switch (order.paymentMode) {
        case 'Cash': c += order.billAmount; break;
        case 'Bank': b += order.billAmount; break;
        case 'EasyPaisa': ep += order.billAmount; break;
        case 'JazzCash': jc += order.billAmount; break;
      }
    }

    emit(KhataState(
      orders: updatedOrders,
      clients: state.clients,
      wallet: WalletStateData(cash: c, bank: b, easyPaisa: ep, jazzCash: jc),
    ));
  }

  void addClient(ClientContact client) {
    final updatedClients = List<ClientContact>.from(state.clients)..add(client);
    emit(KhataState(
      orders: state.orders,
      clients: updatedClients,
      wallet: state.wallet,
    ));
  }

  void updateOrderStatus(String id, String newStatus) {
    double c = state.wallet.cash;
    double b = state.wallet.bank;
    double ep = state.wallet.easyPaisa;
    double jc = state.wallet.jazzCash;

    final updatedOrders = state.orders.map((order) {
      if (order.id == id) {
        if (order.status != 'Paid' && newStatus == 'Paid') {
          switch (order.paymentMode) {
            case 'Cash': c += order.billAmount; break;
            case 'Bank': b += order.billAmount; break;
            case 'EasyPaisa': ep += order.billAmount; break;
            case 'JazzCash': jc += order.billAmount; break;
          }
        }
        return DeliveryOrder(
          id: order.id,
          customerName: order.customerName,
          phoneNumber: order.phoneNumber,
          billAmount: order.billAmount,
          paymentMode: order.paymentMode,
          status: newStatus,
          dateTime: order.dateTime,
        );
      }
      return order;
    }).toList();

    emit(KhataState(
      orders: updatedOrders,
      clients: state.clients,
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

    emit(KhataState(
      orders: state.orders,
      clients: state.clients,
      wallet: WalletStateData(cash: c, bank: b, easyPaisa: ep, jazzCash: jc),
    ));
  }

  @override
  KhataState? fromJson(Map<String, dynamic> json) => KhataState.fromMap(json);

  @override
  Map<String, dynamic>? toJson(KhataState state) => state.toMap();
}

// ==========================================
// 3. MAIN APPLICATION & ORIGINAL LOGO THEME
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

  static const Color primaryRed = Color(0xFFD32F2F); // لوگو کا سرخ رنگ

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
            titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
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
        home: const MainHomeScreen(),
      ),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DeliveriesScreen(),
    const ClientsScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clients'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Summary'),
        ],
      ),
    );
  }
}

// ==========================================
// 4. TAB SCREENS
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Durshal Delivery')),
      body: BlocBuilder<KhataBloc, KhataState>(
        builder: (context, state) {
          final runningOrders = state.orders.where((o) => o.status == 'Pending').toList();
          final historicalOrders = state.orders.where((o) => o.status == 'Paid').toList();
          final displayOrders = [...runningOrders, ...historicalOrders];

          if (displayOrders.isEmpty) {
            return const Center(child: Text('کوئی آرڈر موجود نہیں ہے۔ نیچے + پر کلک کریں۔', style: TextStyle(fontSize: 16)));
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
                      Text('Total: Rs. ${order.billAmount} | Mode: ${order.paymentMode}'),
                      Text(DateFormat('dd MMM yyyy, hh:mm a').format(order.dateTime), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('تکمیل آرڈر'),
                          content: Text('کیا ${order.customerName} کا آرڈر وصول ہو گیا ہے؟'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('نہیں')),
                            ElevatedButton(
                              onPressed: () {
                                context.read<KhataBloc>().updateOrderStatus(order.id, 'Paid');
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: DeliveryKhataApp.primaryRed),
                              child: const Text('ہاں (Paid)', style: TextStyle(color: Colors.white)),
                            )
                          ],
                        ),
                      );
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

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  void _showAddCustomerModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddCustomerFormDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      body: BlocBuilder<KhataBloc, KhataState>(
        builder: (context, state) {
          if (state.clients.isEmpty) {
            return const Center(child: Text('کوئی کلائنٹ موجود نہیں ہے۔', style: TextStyle(fontSize: 15)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: state.clients.length,
            itemBuilder: (context, index) {
              final client = state.clients[index];
              return Card(
                elevation: 1.5,
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: DeliveryKhataApp.primaryRed, child: Icon(Icons.person, color: Colors.white)),
                  title: Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(client.phoneNumber),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomerModal(context),
        backgroundColor: DeliveryKhataApp.primaryRed,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  void _openTransferFundsDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const TransferFundsDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet Ledger'),
        actions: [
          IconButton(icon: const Icon(Icons.swap_horiz), onPressed: () => _openTransferFundsDialog(context)),
        ],
      ),
      body: BlocBuilder<KhataBloc, KhataState>(
        builder: (context, state) {
          final w = state.wallet;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildWalletBalanceRow('Cash', w.cash, Colors.green),
              _buildWalletBalanceRow('Bank Account', w.bank, Colors.blue),
              _buildWalletBalanceRow('EasyPaisa', w.easyPaisa, Colors.lightGreen),
              _buildWalletBalanceRow('JazzCash', w.jazzCash, DeliveryKhataApp.primaryRed),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWalletBalanceRow(String label, double amount, Color accent) {
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
                Container(width: 5, height: 25, color: accent),
                const SizedBox(width: 12),
                Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
            Text('Rs. ${amount.toStringAsFixed(1)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History Logs')),
      body: BlocBuilder<KhataBloc, KhataState>(
        builder: (context, state) {
          final reversedOrders = List<DeliveryOrder>.from(state.orders);
          if (reversedOrders.isEmpty) {
            return const Center(child: Text('ہسٹری خالی ہے۔'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reversedOrders.length,
            itemBuilder: (context, index) {
              final item = reversedOrders[index];
              return ListTile(
                leading: Icon(item.status == 'Paid' ? Icons.check_circle : Icons.error, color: item.status == 'Paid' ? Colors.green : DeliveryKhataApp.primaryRed),
                title: Text(item.customerName),
                subtitle: Text('Amount: Rs. ${item.billAmount} via ${item.paymentMode}'),
                trailing: Text(DateFormat('dd/MM').format(item.dateTime)),
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
          double totalVal = 0.0;
          double pendingVal = 0.0;
          int deliveredCount = 0;

          for (var order in state.orders) {
            if (order.status == 'Paid') {
              totalVal += order.billAmount;
              deliveredCount++;
            } else {
              pendingVal += order.billAmount;
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('کاروباری کارکردگی', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 20),
                _buildMetricCard('کل وصولی (Earned)', 'Rs. ${totalVal.toStringAsFixed(1)}', Colors.green, Icons.monetization_on),
                _buildMetricCard('کل ادھار (Pending)', 'Rs. ${pendingVal.toStringAsFixed(1)}', DeliveryKhataApp.primaryRed, Icons.hourglass_empty),
                _buildMetricCard('ڈیلیور شدہ آرڈرز', '$deliveredCount Orders', Colors.blue, Icons.local_shipping),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color col, IconData icon) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: col.withOpacity(0.1), child: Icon(icon, color: col)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        trailing: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: col)),
      ),
    );
  }
}

// ==========================================
// 5. INTERACTION DIALOGS
// ==========================================

class NewOrderBottomSheet extends StatefulWidget {
  const NewOrderBottomSheet({super.key});

  @override
  State<NewOrderBottomSheet> createState() => _NewOrderBottomSheetState();
}

class _NewOrderBottomSheetState extends State<NewOrderBottomSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedPaymentMode = 'Cash';
  String _selectedStatus = 'Paid';

  Future<void> _selectFromPhoneBook() async {
    if (await FlutterContacts.requestPermission()) {
      final contact = await FlutterContacts.openExternalPick();
      if (contact != null && contact.phones.isNotEmpty) {
        setState(() {
          _nameController.text = contact.displayName;
          String phone = contact.phones.first.number.replaceAll(RegExp(r'\s+|-|\(|\)'), '');
          _phoneController.text = phone;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فون بک کی اجازت نہیں ملی۔')),
        );
      }
    }
  }

  void _triggerWhatsAppMessage(String name, String phone, double amount) async {
    String cleanPhone = phone.replaceAll('+', '');
    if (!cleanPhone.startsWith('92') && cleanPhone.startsWith('0')) {
      cleanPhone = '92${cleanPhone.substring(1)}';
    }
    final message = "السلام علیکم $name! درشال ڈیلیوری پر آپ کا آرڈر درج ہو چکا ہے۔ کل رقم: Rs. $amount. شکریہ!";
    final url = "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}";
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 24, left: 20, right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('نیا آرڈر شامل کریں', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _selectFromPhoneBook,
              icon: const Icon(Icons.contact_phone),
              label: const Text('فون بک سے نمبر منتخب کریں'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DeliveryKhataApp.primaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'گاہک کا نام', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'واٹس ایپ نمبر (مثلاً 923xxxxxxxxx)', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            TextField(controller: _amountController, decoration: const InputDecoration(labelText: 'بل کی رقم (Rs.)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedPaymentMode,
              decoration: const InputDecoration(labelText: 'ادائیگی کا طریقہ', border: OutlineInputBorder()),
              items: ['Cash', 'Bank', 'EasyPaisa', 'JazzCash', 'Udhar'].map((mode) => DropdownMenuItem(value: mode, child: Text(mode))).toList(),
              onChanged: (val) => setState(() {
                _selectedPaymentMode = val!;
                if (_selectedPaymentMode == 'Udhar') {
                  _selectedStatus = 'Pending';
                } else {
                  _selectedStatus = 'Paid';
                }
              }),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isEmpty || _amountController.text.isEmpty) return;
                
                final amt = double.tryParse(_amountController.text) ?? 0.0;
                final order = DeliveryOrder(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  customerName: _nameController.text,
                  phoneNumber: _phoneController.text,
                  billAmount: amt,
                  paymentMode: _selectedPaymentMode,
                  status: _selectedStatus,
                  dateTime: DateTime.now(),
                );

                context.read<KhataBloc>().addOrder(order);
                Navigator.pop(context);

                if (_phoneController.text.isNotEmpty) {
                  _triggerWhatsAppMessage(order.customerName, order.phoneNumber, order.billAmount);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DeliveryKhataApp.primaryRed,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('آرڈر محفوظ کریں + واٹس ایپ میسج', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class AddCustomerFormDialog extends StatefulWidget {
  const AddCustomerFormDialog({super.key});

  @override
  State<AddCustomerFormDialog> createState() => _AddCustomerFormDialogState();
}

class _AddCustomerFormDialogState extends State<AddCustomerFormDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  Future<void> _importContactDirectly() async {
    if (await FlutterContacts.requestPermission()) {
      final contact = await FlutterContacts.openExternalPick();
      if (contact != null) {
        setState(() {
          _nameController.text = contact.displayName;
          if (contact.phones.isNotEmpty) {
            _phoneController.text = contact.phones.first.number;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('نیا کلائنٹ شامل کریں'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: _importContactDirectly,
              icon: const Icon(Icons.import_contacts),
              label: const Text('فون بک سے امپورٹ کریں'),
              style: ElevatedButton.styleFrom(backgroundColor: DeliveryKhataApp.primaryRed, foregroundColor: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'نام', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'فون نمبر', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('منسوخ')),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isEmpty) return;
            final client = ClientContact(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: _nameController.text,
              phoneNumber: _phoneController.text,
            );
            context.read<KhataBloc>().addClient(client);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: DeliveryKhataApp.primaryRed),
          child: const Text('محفوظ کریں', style: TextStyle(color: Colors.white)),
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
      title: const Text('رقم منتقل کریں'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _fromWallet,
            decoration: const InputDecoration(labelText: 'کہاں سے (Source)'),
            items: ['Cash', 'Bank', 'EasyPaisa', 'JazzCash'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (val) => setState(() => _fromWallet = val!),
          ),
          DropdownButtonFormField<String>(
            value: _toWallet,
            decoration: const InputDecoration(labelText: 'کہاں (Destination)'),
            items: ['Cash', 'Bank', 'EasyPaisa', 'JazzCash'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (val) => setState(() => _toWallet = val!),
          ),
          TextField(controller: _amountController, decoration: const InputDecoration(labelText: 'رقم (Rs.)'), keyboardType: TextInputType.number),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('منسوخ')),
        ElevatedButton(
          onPressed: () {
            final amt = double.tryParse(_amountController.text) ?? 0.0;
            if (amt > 0 && _fromWallet != _toWallet) {
              context.read<KhataBloc>().transferFunds(_fromWallet, _toWallet, amt);
            }
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: DeliveryKhataApp.primaryRed),
          child: const Text('ٹرانسفر کریں', style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }
}
