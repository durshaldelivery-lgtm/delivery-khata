import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const DurshalDeliveryApp());
}

class DurshalDeliveryApp extends StatelessWidget {
  const DurshalDeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Durshal Delivery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF3A3F44),
        scaffoldBackgroundColor: const Color(0xFFF4F4F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3A3F44),
          primary: const Color(0xFF3A3F44),
          secondary: const Color(0xFFFF7619), 
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF3A3F44),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFFFF7619),
          unselectedItemColor: Color(0xFF71717A),
          backgroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const MainHomeScreen(),
    );
  }
}

// Data Models
class Order {
  String id; // Unique ID for swipe tracking
  String name;
  double amount;
  String status; 
  String paymentMethod; 

  Order({
    required this.id,
    required this.name,
    required this.amount,
    required this.status,
    required this.paymentMethod,
  });
}

class Loan {
  String id; // Unique ID for swipe tracking
  String clientName;
  double amount;
  String sourceAccount;
  DateTime date;

  Loan({
    required this.id,
    required this.clientName,
    required this.amount,
    required this.sourceAccount,
    required this.date,
  });
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;

  // Global Wallet Balances
  Map<String, double> walletBalances = {
    'Cash': 3500.0,
    'Bank': 1850.0,
    'EasyPaisa': 0.0,
    'JazzCash': 1177.0,
  };

  // Simulation Lists
  List<Order> orders = [
    Order(id: '1', name: 'hshs', amount: 1177.0, status: 'Paid', paymentMethod: 'JazzCash'),
    Order(id: '2', name: 'ikram', amount: 5320.0, status: 'Udhar', paymentMethod: 'Udhar'),
    Order(id: '3', name: 'aslam', amount: 3500.0, status: 'Paid', paymentMethod: 'Cash'),
    Order(id: '4', name: 'irfan', amount: 1850.0, status: 'Paid', paymentMethod: 'Bank'),
  ];

  List<Loan> activeLoans = [];

  // 1. Deliveries: Mark as Paid Popup
  void _showPaymentMethodDialog(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Account for ${order.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Cash', 'Bank', 'EasyPaisa', 'JazzCash'].map((method) {
              return ListTile(
                title: Text(method),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  setState(() {
                    order.status = 'Paid';
                    order.paymentMethod = method;
                    walletBalances[method] = (walletBalances[method] ?? 0) + order.amount;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Rs ${order.amount} credited to $method!')),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // 2. Wallet: Internal Fund Transfer Popup
  void _showTransferDialog(BuildContext context) {
    String fromAccount = 'Cash';
    String toAccount = 'Bank';
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Internal Fund Transfer'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: fromAccount,
                    decoration: const InputDecoration(labelText: 'From Account'),
                    items: walletBalances.keys.map((String key) {
                      return DropdownMenuItem<String>(value: key, child: Text('$key (Rs ${walletBalances[key]})'));
                    }).toList(),
                    onChanged: (val) => setDialogState(() => fromAccount = val!),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: toAccount,
                    decoration: const InputDecoration(labelText: 'To Account'),
                    items: walletBalances.keys.map((String key) {
                      return DropdownMenuItem<String>(value: key, child: Text(key));
                    }).toList(),
                    onChanged: (val) => setDialogState(() => toAccount = val!),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Transfer Amount (Rs)'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    double transferAmount = double.tryParse(amountController.text) ?? 0.0;
                    if (transferAmount <= 0) return;

                    if ((walletBalances[fromAccount] ?? 0) >= transferAmount) {
                      setState(() {
                        walletBalances[fromAccount] = walletBalances[fromAccount]! - transferAmount;
                        walletBalances[toAccount] = (walletBalances[toAccount] ?? 0) + transferAmount;
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Transferred Rs $transferAmount from $fromAccount to $toAccount!')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Insufficient balance!'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: const Text('Transfer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 3. Clients: Lend Money (Give Udhar) Popup
  void _showLendMoneyDialog(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String sourceAccount = 'Cash';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Lend Money (Give Udhar)'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Client/Customer Name'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: sourceAccount,
                    decoration: const InputDecoration(labelText: 'Source Account (Deduct From)'),
                    items: walletBalances.keys.map((s) => DropdownMenuItem(value: s, child: Text('$s (Rs ${walletBalances[s]})'))).toList(),
                    onChanged: (val) => setDialogState(() => sourceAccount = val!),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Udhar Amount (Rs)'),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    double amount = double.tryParse(amountController.text) ?? 0.0;
                    if (nameController.text.isEmpty || amount <= 0) return;

                    if ((walletBalances[sourceAccount] ?? 0) >= amount) {
                      setState(() {
                        walletBalances[sourceAccount] = walletBalances[sourceAccount]! - amount;
                        activeLoans.add(Loan(
                          id: DateTime.now().toString(),
                          clientName: nameController.text,
                          amount: amount,
                          sourceAccount: sourceAccount,
                          date: DateTime.now(),
                        ));
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Rs $amount Udhar given to ${nameController.text}')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Insufficient funds!'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: const Text('Lend'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // WhatsApp Link Automation
  void _sendWhatsAppBusinessMessage(String phone, String name, double amount) async {
    String message = "Durshal Delivery\n\nDear $name,\nYour delivery entry is confirmed. Balance Due: Rs $amount.\nThank you!";
    String url = "whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}";
    final Uri whatsappUri = Uri.parse(url);
    
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    } else {
      String webUrl = "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";
      await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
    }
  }

  void _openNewOrderScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewOrderScreen(
          onSave: (name, phone, amount, method) {
            setState(() {
              orders.add(Order(
                id: DateTime.now().toString(),
                name: name, 
                amount: amount, 
                status: method == 'Udhar' ? 'Udhar' : 'Paid', 
                paymentMethod: method
              ));
              if (method != 'Udhar') {
                walletBalances[method] = (walletBalances[method] ?? 0) + amount;
              }
            });
            if (phone.isNotEmpty && phone != "3xxxxxxxxx") {
              _sendWhatsAppBusinessMessage(phone, name, amount);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      // 1. Deliveries Tab Layout (with Swipe to Delete)
      ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Dismissible(
            key: Key(order.id),
            direction: DismissDirection.endToStart, // Swipe right to left
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) {
              setState(() {
                orders.removeAt(index);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Order for ${order.name} deleted')),
              );
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text(order.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Text('Total: Rs ${order.amount} | Mode: ${order.paymentMethod}'),
                trailing: order.status == 'Udhar'
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary, 
                          foregroundColor: Colors.white
                        ),
                        onPressed: () => _showPaymentMethodDialog(context, order),
                        child: const Text('Paid'),
                      )
                    : Chip(
                        label: Text(order.status), 
                        backgroundColor: Colors.green.withOpacity(0.2), 
                        side: BorderSide.none
                      ),
              ),
            ),
          );
        },
      ),

      // 2. Clients Tab Layout (with Swipe to Delete)
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () => _showLendMoneyDialog(context),
              icon: const Icon(Icons.money_off),
              label: const Text('Give Udhar (Lend Money to Client)'),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: activeLoans.isEmpty
                  ? const Center(child: Text('No active external loans recorded.'))
                  : ListView.builder(
                      itemCount: activeLoans.length,
                      itemBuilder: (context, index) {
                        final loan = activeLoans[index];
                        return Dismissible(
                          key: Key(loan.id),
                          direction: DismissDirection.endToStart, // Swipe right to left
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20.0),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            setState(() {
                              activeLoans.removeAt(index);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Udhar record for ${loan.clientName} removed')),
                            );
                          },
                          child: Card(
                            child: ListTile(
                              title: Text(loan.clientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Deducted from: ${loan.sourceAccount}'),
                              trailing: Text(
                                'Rs ${loan.amount}',
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      // 3. Wallet Tab Layout with Internal Transfer Option
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary, 
                foregroundColor: Colors.white, 
                minimumSize: const Size.fromHeight(50)
              ),
              onPressed: () => _showTransferDialog(context),
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Transfer Funds Between Accounts'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: walletBalances.keys.map((String key) {
                  return Card(
                    child: ListTile(
                      title: Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text(
                        'Rs ${walletBalances[key]}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3A3F44)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),

      const Center(child: Text('History Records Screen')),
      const Center(child: Text('Summary and Charts Overview')),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Durshal Delivery')),
      body: IndexedStack(index: _currentIndex, children: tabs),
      floatingActionButton: _currentIndex == 0 
          ? FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              onPressed: _openNewOrderScreen,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: 'Deliveries'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clients'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.assessment), label: 'Summary'),
        ],
      ),
    );
  }
}

class NewOrderScreen extends StatefulWidget {
  final Function(String, String, double, String) onSave;
  const NewOrderScreen({super.key, required this.onSave});

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedMethod = 'Cash';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Order')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Customer Name')),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'WhatsApp Number (e.g. 923xxxxxxxx)')),
            TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Bill Amount')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedMethod,
              items: ['Cash', 'Bank', 'EasyPaisa', 'JazzCash', 'Udhar'].map((method) {
                return DropdownMenuItem(value: method, child: Text(method));
              }).toList(),
              onChanged: (val) => setState(() => _selectedMethod = val!),
              decoration: const InputDecoration(labelText: 'Initial Payment Mode/Status'),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary, 
                foregroundColor: Colors.white, 
                minimumSize: const Size.fromHeight(50)
              ),
              onPressed: () {
                if (_nameController.text.isNotEmpty && _amountController.text.isNotEmpty) {
                  widget.onSave(
                    _nameController.text, 
                    _phoneController.text, 
                    double.parse(_amountController.text), 
                    _selectedMethod
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Save + Send WhatsApp'),
            )
          ],
        ),
      ),
    );
  }
}
