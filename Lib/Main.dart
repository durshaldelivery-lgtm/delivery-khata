import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  // Register raw boxes directly into persistent phone memory
  await Hive.openBox('deliveries');
  await Hive.openBox('customers');
  await Hive.openBox('transactions');
  await Hive.openBox('wallet_balances');

  runApp(const DeliveryKhataApp());
}

class DeliveryKhataApp extends StatelessWidget {
  const DeliveryKhataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Durshal Delivery Khata',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const MainHomeScreen(),
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
  final Box deliveryBox = Hive.box('deliveries');
  final Box customerBox = Hive.box('customers');
  final Box transBox = Hive.box('transactions');
  final Box walletBox = Hive.box('wallet_balances');

  @override
  void initState() {
    super.initState();
    // Establish structural fallback profiles for regional funding channels
    if (walletBox.isEmpty) {
      walletBox.put('Cash', 0.0);
      walletBox.put('Bank', 0.0);
      walletBox.put('EasyPaisa', 0.0);
      walletBox.put('JazzCash', 0.0);
    }
  }

  // Opens native Android phone book screen overlay to extract data 
  Future<Contact?> _pickPhoneContact() async {
    if (await Permission.contacts.request().isGranted) {
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      if (contacts.isNotEmpty) {
        return await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text("Select Contact"), backgroundColor: Colors.teal),
              body: ListView.builder(
                itemCount: contacts.length,
                itemBuilder: (context, i) {
                  final c = contacts[i];
                  final phone = c.phones.isNotEmpty ? c.phones.first.number : 'No Number';
                  return ListTile(
                    title: Text(c.displayName),
                    subtitle: Text(phone),
                    onTap: () => Navigator.pop(context, c),
                  );
                },
              ),
            ),
          ),
        );
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Structural index for all 5 essential operational tabs
    final List<Widget> tabs = [
      _buildDeliveriesTab(),
      _buildCustomersTab(),
      _buildWalletTab(),
      _buildHistoryTab(),
      _buildSummaryTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Durshal Delivery Khata', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.teal,
      ),
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Deliveries'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Customers'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Summary'),
        ],
      ),
    );
  }

  // --- 1. DELIVERIES TAB ---
  Widget _buildDeliveriesTab() {
    return ValueListenableBuilder(
      valueListenable: deliveryBox.listenable(),
      builder: (context, Box box, _) {
        final list = box.values.toList();
        return Scaffold(
          body: list.isEmpty
              ? const Center(child: Text("No deliveries added yet."))
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final d = list[i] as Map;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text("${d['customerName']} (${d['customerPhone']})"),
                        subtitle: Text("Rs. ${d['amount']} — ${d['status']}"),
                        trailing: d['status'] == 'Pending'
                            ? IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                onPressed: () {
                                  final updatedData = Map<String, dynamic>.from(d);
                                  updatedData['status'] = 'Delivered';
                                  box.putAt(i, updatedData);

                                  // Automatically assign incoming cash to local physical register 
                                  double cash = walletBox.get('Cash') ?? 0.0;
                                  walletBox.put('Cash', cash + d['amount']);

                                  // Append clear record details into history vault logs
                                  transBox.add({
                                    'type': 'delivery_payout',
                                    'sourceAccount': 'Cash',
                                    'amount': d['amount'],
                                    'date': DateTime.now().toString(),
                                    'description': "Order for ${d['customerName']} Delivered",
                                  });
                                  setState(() {});
                                },
                              )
                            : const Icon(Icons.done_all, color: Colors.teal),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddDeliveryDialog(),
            backgroundColor: Colors.teal,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  void _showAddDeliveryDialog() {
    String selectedName = '';
    String selectedPhone = '';
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("New Delivery Order"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    onPressed: () async {
                      final c = await _pickPhoneContact();
                      if (c != null) {
                        setDialogState(() {
                          selectedName = c.displayName;
                          selectedPhone = c.phones.isNotEmpty ? c.phones.first.number : '';
                        });
                      }
                    },
                    icon: const Icon(Icons.contact_phone, color: Colors.white),
                    label: const Text("Select from Phonebook", style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    hint: const Text("Or choose saved customer"),
                    items: customerBox.values.map((c) {
                      final map = c as Map;
                      return DropdownMenuItem(value: "${map['name']}||${map['phone']}", child: Text(map['name']));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final split = val.split("||");
                        setDialogState(() {
                          selectedName = split[0];
                          selectedPhone = split[1];
                        });
                      }
                    },
                  ),
                  if (selectedName.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text("Target: $selectedName ($selectedPhone)", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                  ],
                  TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: "Bill Amount (Rs.)"), keyboardType: TextInputType.number),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                onPressed: () {
                  if (selectedName.isNotEmpty && amountCtrl.text.isNotEmpty) {
                    deliveryBox.add({
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'customerName': selectedName,
                      'customerPhone': selectedPhone,
                      'amount': double.parse(amountCtrl.text),
                      'status': 'Pending',
                      'date': DateTime.now().toString(),
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text("Create Order", style: TextStyle(color: Colors.white)),
              )
            ],
          );
        });
      },
    );
  }

  // --- 2. CUSTOMERS TAB ---
  Widget _buildCustomersTab() {
    return ValueListenableBuilder(
      valueListenable: customerBox.listenable(),
      builder: (context, Box box, _) {
        final list = box.values.toList();
        return Scaffold(
          body: list.isEmpty
              ? const Center(child: Text("No Customers added yet."))
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final c = list[i] as Map;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.person, color: Colors.white)),
                        title: Text(c['name']),
                        subtitle: Text(c['phone']),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddCustomerDialog(),
            backgroundColor: Colors.teal,
            child: const Icon(Icons.person_add, color: Colors.white),
          ),
        );
      },
    );
  }

  void _showAddCustomerDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Customer"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () async {
                final c = await _pickPhoneContact();
                if (c != null) {
                  nameCtrl.text = c.displayName;
                  phoneCtrl.text = c.phones.isNotEmpty ? c.phones.first.number : '';
                }
              },
              icon: const Icon(Icons.import_contacts, color: Colors.white),
              label: const Text("Import From Phone Book", style: TextStyle(color: Colors.white)),
            ),
            const Divider(height: 20),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Manual Form Name")),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Manual Phone Link"), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                customerBox.add({
                  'name': nameCtrl.text,
                  'phone': phoneCtrl.text,
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // --- 3. WALLET TAB ---
  Widget _buildWalletTab() {
    final accounts = ['Cash', 'Bank', 'EasyPaisa', 'JazzCash'];
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3),
                itemCount: accounts.length,
                itemBuilder: (context, i) {
                  final acc = accounts[i];
                  final bal = walletBox.get(acc) ?? 0.0;
                  return Card(
                    color: Colors.teal.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(acc, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                          const SizedBox(height: 8),
                          Text("Rs. $bal", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: () => _showAddMoneyDialog(),
                    icon: const Icon(Icons.account_balance, color: Colors.white),
                    label: const Text("Inject Cash / Top-Up", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: () => _showTransferMoneyDialog(),
                    icon: const Icon(Icons.compare_arrows, color: Colors.white),
                    label: const Text("Transfer Funds", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showAddMoneyDialog() {
    String selectedAcc = 'Cash';
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Inject Capital (Top-Up)"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedAcc,
              items: ['Cash', 'Bank', 'EasyPaisa', 'JazzCash'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => selectedAcc = val!,
              decoration: const InputDecoration(labelText: "Target Account Profile"),
            ),
            TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: "Amount (Rs.)"), keyboardType: TextInputType.number),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Source Note (e.g., Owner personal cash)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              if (amountCtrl.text.isNotEmpty) {
                double amount = double.parse(amountCtrl.text);
                double currentBal = walletBox.get(selectedAcc) ?? 0.0;
                walletBox.put(selectedAcc, currentBal + amount);

                transBox.add({
                  'type': 'income',
                  'sourceAccount': selectedAcc,
                  'amount': amount,
                  'date': DateTime.now().toString(),
                  'description': descCtrl.text.isEmpty ? "Direct Balance Addition" : descCtrl.text,
                });
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text("Add Balance", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _showTransferMoneyDialog() {
    String fromAcc = 'Cash';
    String toAcc = 'Bank';
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Transfer Balance internally"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: fromAcc,
              items: ['Cash', 'Bank', 'EasyPaisa', 'JazzCash'].map((e) => DropdownMenuItem(value: e, child: Text("From: $e"))).toList(),
              onChanged: (val) => fromAcc = val!,
            ),
            DropdownButtonFormField<String>(
              value: toAcc,
              items: ['Cash', 'Bank', 'EasyPaisa', 'JazzCash'].map((e) => DropdownMenuItem(value: e, child: Text("To: $e"))).toList(),
              onChanged: (val) => toAcc = val!,
            ),
            TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: "Transfer Amount (Rs.)"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () {
              double amount = double.parse(amountCtrl.text);
              double fromBal = walletBox.get(fromAcc) ?? 0.0;
              if (fromBal >= amount) {
                walletBox.put(fromAcc, fromBal - amount);
                double toBal = walletBox.get(toAcc) ?? 0.0;
                walletBox.put(toAcc, toBal + amount);

                transBox.add({
                  'type': 'transfer',
                  'sourceAccount': fromAcc,
                  'destinationAccount': toAcc,
                  'amount': amount,
                  'date': DateTime.now().toString(),
                  'description': "Transferred from $fromAcc to $toAcc",
                });
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text("Execute Transfer", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // --- 4. HISTORY TAB ---
  Widget _buildHistoryTab() {
    return ValueListenableBuilder(
      valueListenable: transBox.listenable(),
      builder: (context, Box box, _) {
        final list = box.values.toList().reversed.toList();
        return list.isEmpty
            ? const Center(child: Text("No transaction logs registered yet."))
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final t = list[i] as Map;
                  IconData icon = Icons.arrow_downward;
                  Color iconColor = Colors.green;
                  if (t['type'] == 'transfer') {
                    icon = Icons.compare_arrows;
                    iconColor = Colors.blue;
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: iconColor.withOpacity(0.1), child: Icon(icon, color: iconColor)),
                      title: Text(t['description']),
                      subtitle: Text("Channel Context: ${t['sourceAccount']}"),
                      trailing: Text("Rs. ${t['amount']}", style: TextStyle(fontWeight: FontWeight.bold, color: iconColor)),
                    ),
                  );
                },
              );
      },
    );
  }

  // --- 5. SUMMARY TAB ---
  Widget _buildSummaryTab() {
    double totalEarned = 0;
    double totalPending = 0;
    int completedCount = 0;

    for (var d in deliveryBox.values) {
      final map = d as Map;
      if (map['status'] == 'Delivered') {
        totalEarned += map['amount'];
        completedCount++;
      } else if (map['status'] == 'Pending') {
        totalPending += map['amount'];
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Business Logistics Metrics", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
          const SizedBox(height: 20),
          _buildSummaryCard("Total Earned Valuations", "Rs. $totalEarned", Colors.green, Icons.monetization_on),
          const SizedBox(height: 12),
          _buildSummaryCard("Pending Credit (Market Stuck)", "Rs. $totalPending", Colors.orange, Icons.hourglass_empty),
          const SizedBox(height: 12),
          _buildSummaryCard("Delivered Consignments", "$completedCount Orders", Colors.blue, Icons.assignment_turned_in),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        trailing: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }
}
