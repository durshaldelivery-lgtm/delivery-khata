import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('clients');
  await Hive.openBox('deliveries');
  runApp(const DeliveryKhataApp());
}

class DeliveryKhataApp extends StatelessWidget {
  const DeliveryKhataApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Delivery Khata',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Client {
  String name; String phone; String address; double due;
  Client({required this.name, required this.phone, required this.address, this.due = 0});
  Map toMap() => {'name': name, 'phone': phone, 'address': address, 'due': due};
  static Client fromMap(Map m) => Client(name: m['name'], phone: m['phone'], address: m['address'], due: m['due']);
}

class Delivery {
  String clientName; String product; int qty; double price; DateTime date; bool paid;
  Delivery({required this.clientName, required this.product, required this.qty, required this.price, required this.date, this.paid = false});
  double get total => qty * price;
  Map toMap() => {'clientName': clientName, 'product': product, 'qty': qty, 'price': price, 'date': date.toIso8601String(), 'paid': paid};
  static Delivery fromMap(Map m) => Delivery(clientName: m['clientName'], product: m['product'], qty: m['qty'], price: m['price'], date: DateTime.parse(m['date']), paid: m['paid']);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  final boxes = [ClientsPage(), DeliveriesPage(), SummaryPage()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Khata')),
      body: boxes[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clients'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Deliveries'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Summary'),
        ],
      ),
      floatingActionButton: _index!= 2? FloatingActionButton(
        onPressed: () => _index == 0? _addClient() : _addDelivery(),
        child: const Icon(Icons.add),
      ) : null,
    );
  }
  
  void _addClient() { showDialog(context: context, builder: (_) => ClientDialog()); }
  void _addDelivery() { showDialog(context: context, builder: (_) => DeliveryDialog()); }
}

class ClientsPage extends StatefulWidget {
  @override State<ClientsPage> createState() => _ClientsPageState();
}
class _ClientsPageState extends State<ClientsPage> {
  var box = Hive.box('clients');
  List<Client> get clients => box.values.map((e) => Client.fromMap(Map.from(e))).toList();
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: clients.length,
      itemBuilder: (_, i) {
        final c = clients[i];
        return Card(
          child: ListTile(
            title: Text(c.name),
            subtitle: Text('${c.phone}\nDue: Rs ${c.due.toStringAsFixed(0)}'),
            trailing: IconButton(icon: Icon(Icons.call), onPressed: () => launchUrl(Uri.parse('tel:${c.phone}'))),
          ),
        );
      }
    );
  }
}

class DeliveriesPage extends StatefulWidget {
  @override State<DeliveriesPage> createState() => _DeliveriesPageState();
}
class _DeliveriesPageState extends State<DeliveriesPage> {
  var box = Hive.box('deliveries');
  List<Delivery> get deliveries => box.values.map((e) => Delivery.fromMap(Map.from(e))).toList();
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: deliveries.length,
      itemBuilder: (_, i) {
        final d = deliveries[i];
        return Card(
          child: ListTile(
            title: Text(d.product),
            subtitle: Text('${d.clientName} - Qty: ${d.qty} - Total: Rs ${d.total.toStringAsFixed(0)}'),
            trailing: Checkbox(value: d.paid, onChanged: (v) {
              d.paid = v!; box.putAt(i, d.toMap()); setState((){});
            }),
          ),
        );
      }
    );
  }
}

class SummaryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var cBox = Hive.box('clients');
    var dBox = Hive.box('deliveries');
    double totalDue = cBox.values.fold(0, (sum, e) => sum + Client.fromMap(Map.from(e)).due);
    double totalSales = dBox.values.fold(0, (sum, e) => sum + Delivery.fromMap(Map.from(e)).total);
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('Total Sales: Rs ${totalSales.toStringAsFixed(0)}', style: TextStyle(fontSize: 20)),
      Text('Total Due: Rs ${totalDue.toStringAsFixed(0)}', style: TextStyle(fontSize: 20, color: Colors.red)),
      SizedBox(height: 20),
      ElevatedButton(onPressed: () => _generatePDF(context), child: Text('Export PDF'))
    ]));
  }
  
  void _generatePDF(BuildContext context) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (pw.Context context) => pw.Center(child: pw.Text('Delivery Khata Report'))));
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'khata.pdf');
  }
}

class ClientDialog extends StatefulWidget {
  @override State<ClientDialog> createState() => _ClientDialogState();
}
class _ClientDialogState extends State<ClientDialog> {
  final name = TextEditingController(); final phone = TextEditingController(); final address = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return AlertDialog(title: Text('Add Client'), content: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: name, decoration: InputDecoration(labelText: 'Name')),
      TextField(controller: phone, decoration: InputDecoration(labelText: 'Phone')),
      TextField(controller: address, decoration: InputDecoration(labelText: 'Address')),
    ]), actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
      TextButton(onPressed: () {
        Hive.box('clients').add(Client(name: name.text, phone: phone.text, address: address.text).toMap());
        Navigator.pop(context);
      }, child: Text('Save')),
    ]);
  }
}

class DeliveryDialog extends StatefulWidget {
  @override State<DeliveryDialog> createState() => _DeliveryDialogState();
}
class _DeliveryDialogState extends State<DeliveryDialog> {
  final product = TextEditingController(); final qty = TextEditingController(); final price = TextEditingController();
  String? client;
  @override
  Widget build(BuildContext context) {
    var clients = Hive.box('clients').values.map((e) => Client.fromMap(Map.from(e)).name).toList();
    return AlertDialog(title: Text('Add Delivery'), content: Column(mainAxisSize: MainAxisSize.min, children: [
      DropdownButtonFormField(items: clients.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), 
        onChanged: (v) => client = v, decoration: InputDecoration(labelText: 'Client')),
      TextField(controller: product, decoration: InputDecoration(labelText: 'Product')),
      TextField(controller: qty, decoration: InputDecoration(labelText: 'Qty'), keyboardType: TextInputType.number),
      TextField(controller: price, decoration: InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
    ]), actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
      TextButton(onPressed: () {
        Hive.box('deliveries').add(Delivery(clientName: client!, product: product.text, qty: int.parse(qty.text), price: double.parse(price.text), date: DateTime.now()).toMap());
        Navigator.pop(context);
      }, child: Text('Save')),
    ]);
  }
}
