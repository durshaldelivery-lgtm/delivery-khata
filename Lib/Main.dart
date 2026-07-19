import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // NEW
import 'package:intl/intl.dart'; // NEW

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('orders');
  await Hive.openBox('expenses');
  await Hive.openBox('transactions'); // NEW
  await Hive.openBox('wallet'); // NEW
  await Hive.openBox('settings');
  runApp(DurshalDelivery());
}

class DurshalDelivery extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Durshal Delivery',
      theme: ThemeData(
        primaryColor: Color(0xFF1E3A8A), // Durshal Blue
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF1E3A8A)),
        useMaterial3: true
      ),
      home: PinLockScreen(),
      debugShowCheckedModeBanner: false
    );
  }
}

class PinLockScreen extends StatefulWidget {
  @override _PinLockScreenState createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final pinController = TextEditingController();
  var box = Hive.box('settings');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Durshal Delivery", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              SizedBox(height: 20),
              Text("Enter PIN to Continue"),
              TextField(controller: pinController, obscureText: true, keyboardType: TextInputType.number, textAlign: TextAlign.center),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1E3A8A)),
                onPressed: () {
                  if (box.get('pin') == null) box.put('pin', pinController.text);
                  if (box.get('pin') == pinController.text)
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
                  else
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Wrong PIN")));
                },
                child: Text("Unlock")
              )
            ]
          )
        )
      )
    );
  }
}

// NEW 5 TAB LAYOUT
class HomeScreen extends StatefulWidget {
  @override _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _tabs = [
    DeliveriesTab(),
    ClientsTab(),
    WalletTab(),
    TransactionsTab(),
    SummaryTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Durshal Delivery"),
        backgroundColor: Color(0xFF1E3A8A),
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Color(0xFF1E3A8A),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: 'Deliveries'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clients'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Summary'),
        ],
      ),
    );
  }
}

// TAB 1: DELIVERIES
class DeliveriesTab extends StatefulWidget {
  @override _DeliveriesTabState createState() => _DeliveriesTabState();
}

class _DeliveriesTabState extends State<DeliveriesTab> {
  var box = Hive.box('orders');
  var txBox = Hive.box('transactions');
  var walletBox = Hive.box('wallet');

  void markAsPaid(int index, Map order) {
    // Add income to wallet
    String method = order['payment'];
    double amount = order['total'];
    walletBox.put(method, (walletBox.get(method, defaultValue: 0.0) + amount));

    // Add transaction
    txBox.add({
      'date': DateTime.now().toString(),
      'type': 'Income',
      'amount': amount,
      'method': method,
      'note': 'From ${order['name']} - ${order['shop']}'
    });

    setState((){});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Rs $amount added to $method")));
  }

  @override
  Widget build(BuildContext context) {
    var orders = box.values.toList().reversed.toList();
    return Scaffold(
      body: orders.isEmpty
       ? Center(child: Text("No deliveries yet. Tap + to add"))
        : ListView.builder(
            itemCount: orders.length,
            itemBuilder: (_, i) {
              var o = orders[i];
              return Slidable(
                endActionPane: ActionPane(motion: DrawerMotion(), children: [
                  SlidableAction(onPressed: (_) => box.deleteAt(box.length - 1 - i), backgroundColor: Colors.red, icon: Icons.delete, label: 'Delete')
                ]),
                child: Card(
                  child: ListTile(
                    title: Text(o['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${o['shop']}\nTotal: Rs ${o['total']} | ${o['payment']}"),
                    trailing: o['payment'] == 'Udhar'
                     ? ElevatedButton(onPressed: () => markAsPaid(box.length - 1 - i, o), child: Text("Paid"))
                      : null,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddOrderScreen(order: o, index: box.length - 1 - i))),
                  ),
                ),
              );
            }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF1E3A8A),
        child: Icon(Icons.add),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddOrderScreen())),
      ),
    );
  }
}

// TAB 2: CLIENTS - Placeholder for now
class ClientsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Clients Tab - Coming Next"));
  }
}

// TAB 3: WALLET
class WalletTab extends StatefulWidget {
  @override _WalletTabState createState() => _WalletTabState();
}

class _WalletTabState extends State<WalletTab> {
  var walletBox = Hive.box('wallet');

  @override
  Widget build(BuildContext context) {
    double cash = walletBox.get('Cash', defaultValue: 0.0);
    double bank = walletBox.get('Bank', defaultValue: 0.0);
    double easy = walletBox.get('Easypaisa', defaultValue: 0.0);
    double jazz = walletBox.get('JazzCash', defaultValue: 0.0);
    double total = cash + bank + easy + jazz;

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Card(color: Color(0xFF1E3A8A), child: ListTile(title: Text("Total Balance", style: TextStyle(color: Colors.white)), trailing: Text("Rs $total", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)))),
          SizedBox(height: 10),
          _walletCard("Cash", cash, Icons.money),
          _walletCard("Bank", bank, Icons.account_balance),
          _walletCard("Easypaisa", easy, Icons.phone_android),
          _walletCard("JazzCash", jazz, Icons.phone_android),
        ],
      ),
    );
  }
  Widget _walletCard(String title, double amount, IconData icon) {
    return Card(child: ListTile(leading: Icon(icon, color: Color(0xFF1E3A8A)), title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)), trailing: Text("Rs $amount", style: TextStyle(fontSize: 18))));
  }
}

// TAB 4: TRANSACTIONS
class TransactionsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var txBox = Hive.box('transactions');
    var txs = txBox.values.toList().reversed.toList();
    return txs.isEmpty
     ? Center(child: Text("No transactions yet"))
      : ListView.builder(
          itemCount: txs.length,
          itemBuilder: (_, i) {
            var t = txs[i];
            return ListTile(
              leading: Icon(t['type'] == 'Income'? Icons.arrow_downward : Icons.arrow_upward, color: t['type'] == 'Income'? Colors.green : Colors.red),
              title: Text(t['note']),
              subtitle: Text(DateFormat('MMM d, y').format(DateTime.parse(t['date']))),
              trailing: Text("Rs ${t['amount']}", style: TextStyle(fontWeight: FontWeight.bold)),
            );
          });
  }
}

// TAB 5: SUMMARY
class SummaryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var orders = Hive.box('orders').values.toList();
    var expenses = Hive.box('expenses').values.toList();
    double income = orders.fold(0, (sum, e) => sum + (double.tryParse(e['total'].toString())?? 0));
    double deliveryProfit = orders.fold(0, (sum, e) => sum + (double.tryParse(e['delivery'].toString())?? 0));
    double spent = expenses.fold(0, (sum, e) => sum + (double.tryParse(e['amount'].toString())?? 0));
    double net = deliveryProfit - spent;

    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text("Delivery Profit: Rs $deliveryProfit", style: TextStyle(fontSize: 18)),
      Text("Total Expenses: Rs $spent", style: TextStyle(fontSize: 18)),
      Text("Net: Rs $net", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: net >= 0? Colors.green : Colors.red))
    ]));
  }
}

// NEW ORDER / EDIT ORDER SCREEN
class AddOrderScreen extends StatefulWidget {
  final Map? order;
  final int? index;
  AddOrderScreen({this.order, this.index});
  @override _AddOrderScreenState createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final shop = TextEditingController();
  final bill = TextEditingController();
  final delivery = TextEditingController();
  String payment = "Cash";
  var box = Hive.box('orders');
  var txBox = Hive.box('transactions');

  @override
  void initState() {
    super.initState();
    if(widget.order!= null){
      name.text = widget.order!['name'];
      phone.text = widget.order!['phone'];
      shop.text = widget.order!['shop'];
      bill.text = widget.order!['bill'].toString();
      delivery.text = widget.order!['delivery'].toString();
      payment = widget.order!['payment'];
    }
  }

  void saveOrder() async {
    double total = (double.tryParse(bill.text)?? 0) + (double.tryParse(delivery.text)?? 0);
    var data = {'date': DateTime.now().toString(), 'name': name.text, 'phone': phone.text, 'shop': shop.text, 'bill': bill.text, 'delivery': delivery.text, 'total': total, 'payment': payment};

    if(widget.index!= null) box.putAt(widget.index!, data); else box.add(data);

    if(payment == 'Udhar') {
      txBox.add({'date': DateTime.now().toString(), 'type': 'Due', 'amount': total, 'method': 'Udhar', 'note': 'To ${name.text} - ${shop.text}'});
    }

    String msg = "Order Receipt%0AName: ${name.text}%0AShop: ${shop.text}%0ABill: ${bill.text}%0ADelivery: ${delivery.text}%0ATotal: $total%0APaid via: $payment%0AThank you - Durshal Delivery";
    String url = "https://wa.me/92${phone.text}?text=$msg";
    if(await canLaunch(url)) launch(url);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.order == null? "New Order" : "Edit Order"), backgroundColor: Color(0xFF1E3A8A)),
      body: Padding(padding: EdgeInsets.all(16), child: ListView(children: [
        TextField(controller: name, decoration: InputDecoration(labelText: "Customer Name")),
        TextField(controller: phone, decoration: InputDecoration(labelText: "WhatsApp: 3xxxxxxxxx")),
        TextField(controller: shop, decoration: InputDecoration(labelText: "Shop/Restaurant")),
        TextField(controller: bill, decoration: InputDecoration(labelText: "Bill Amount"), keyboardType: TextInputType.number),
        TextField(controller: delivery, decoration: InputDecoration(labelText: "Delivery Charge"), keyboardType: TextInputType.number),
        DropdownButton(value: payment, isExpanded: true, items: ["Cash","Bank","Easypaisa","JazzCash","Udhar"].map((e)=>DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v)=>setState(()=>payment=v!)),
        SizedBox(height: 20),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1E3A8A)), onPressed: saveOrder, child: Text("Save + Send WhatsApp"))
      ]))
    );
  }
}
