import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const MyFarmAccountsApp());

class MyFarmAccountsApp extends StatefulWidget {
  const MyFarmAccountsApp({super.key});
  @override State<MyFarmAccountsApp> createState() => _AppState();
}

class _AppState extends State<MyFarmAccountsApp> {
  bool ar = true;
  int page = 0;
  List<Worker> workers=[];
  List<StockItem> stock=[];
  final List<Tx> txs = [
    Tx(TxType.revenue, 'بيع تمر', 28500, DateTime.now()),
    Tx(TxType.expense, 'أسمدة ومستلزمات', 6200, DateTime.now()),
    Tx(TxType.expense, 'أجور عمالة', 12200, DateTime.now()),
  ];
  String t(String a, String e) => ar ? a : e;
  @override void initState(){super.initState();_loadFarmData();}
  Future<void> _loadFarmData() async { final p=await SharedPreferences.getInstance(); workers=(jsonDecode(p.getString('workers')??'[]') as List).map((x)=>Worker.fromJson(x)).toList(); stock=(jsonDecode(p.getString('stock')??'[]') as List).map((x)=>StockItem.fromJson(x)).toList(); setState((){}); }
  Future<void> _saveFarmData() async { final p=await SharedPreferences.getInstance(); await p.setString('workers',jsonEncode(workers.map((x)=>x.toJson()).toList())); await p.setString('stock',jsonEncode(stock.map((x)=>x.toJson()).toList())); }

  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'My Farm Accounts',
    locale: ar ? const Locale('ar') : const Locale('en'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(useMaterial3:true, colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFF2E6B3E)), scaffoldBackgroundColor:const Color(0xFFF5F7F3)),
    home: Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Shell(
        title:t('حسابات مزرعتي','My Farm Accounts'), page:page, ar:ar,
        onPage:(p)=>setState(()=>page=p), onLanguage:()=>setState(()=>ar=!ar),
        child: page==0 ? Dashboard(t:t,txs:txs) : TransactionsPage(
          t:t,type:page==1?TxType.revenue:TxType.expense,txs:txs,
          onAdd:(x)=>setState(()=>txs.insert(0,x)),onDelete:(x)=>setState(()=>txs.remove(x))),
      ),
    ),
  );
}

class Shell extends StatelessWidget {
  final String title; final int page; final bool ar; final ValueChanged<int> onPage; final VoidCallback onLanguage; final Widget child;
  const Shell({super.key,required this.title,required this.page,required this.ar,required this.onPage,required this.onLanguage,required this.child});
  @override Widget build(BuildContext context) {
    final wide=MediaQuery.sizeOf(context).width>=900;
    final menu=[(Icons.dashboard_rounded,ar?'لوحة التحكم':'Dashboard'),(Icons.trending_up_rounded,ar?'الإيرادات':'Revenue'),(Icons.trending_down_rounded,ar?'المصروفات':'Expenses'), (Icons.account_balance,ar?'رأس المال':'Capital'), (Icons.people,ar?'العمال والموظفون':'Workers & HR'), (Icons.event_available,ar?'الحضور والانصراف':'Attendance'), (Icons.inventory_2,ar?'المخازن والأصول':'Inventory'), (Icons.local_florist,ar?'الصوبة الزراعية':'Greenhouse'), (Icons.picture_as_pdf,ar?'التقارير':'Reports')];
    return Scaffold(
      appBar:AppBar(title:Text(title,style:const TextStyle(fontWeight:FontWeight.w800)),actions:[TextButton.icon(onPressed:onLanguage,icon:const Icon(Icons.translate),label:Text(ar?'EN':'عربي'))]),
      drawer:wide?null:Drawer(child:SideMenu(menu:menu,page:page,onPage:onPage,ar:ar)),
      body:Row(children:[if(wide) SizedBox(width:250,child:SideMenu(menu:menu,page:page,onPage:onPage,ar:ar)),Expanded(child:child)]),
    );
  }
}

class SideMenu extends StatelessWidget {
  final List<(IconData,String)> menu; final int page; final ValueChanged<int> onPage; final bool ar;
  const SideMenu({super.key,required this.menu,required this.page,required this.onPage,required this.ar});
  @override Widget build(BuildContext context)=>Material(
    color:const Color(0xFF173D25),
    child:SafeArea(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      const SizedBox(height:22),const Icon(Icons.energy_savings_leaf_rounded,color:Colors.white,size:52),
      const SizedBox(height:8),Text(ar?'حسابات مزرعتي':'My Farm Accounts',textAlign:TextAlign.center,style:const TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.w800)),
      const SizedBox(height:28),
      ...List.generate(menu.length,(i)=>ListTile(selected:page==i,selectedTileColor:Colors.white.withValues(alpha:.14),leading:Icon(menu[i].$1,color:Colors.white),title:Text(menu[i].$2,style:const TextStyle(color:Colors.white)),onTap:(){onPage(i);if(Navigator.canPop(context))Navigator.pop(context);})),
      const Spacer(),Padding(padding:const EdgeInsets.all(16),child:Text(ar?'تصميم وتطوير: مهندس / محمد رزق عبداللا\nرقم الهاتف: 01126201133':'Designed & developed by Eng. Mohamed Rizk Abdella\nPhone: 01126201133',textAlign:TextAlign.center,style:TextStyle(color:Colors.white70,fontSize:12))),
    ])),
  );
}

class Dashboard extends StatelessWidget {
  final String Function(String,String) t; final List<Tx> txs;
  const Dashboard({super.key,required this.t,required this.txs});
  @override Widget build(BuildContext context){
    final rev=txs.where((x)=>x.type==TxType.revenue).fold(0.0,(s,x)=>s+x.amount);
    final exp=txs.where((x)=>x.type==TxType.expense).fold(0.0,(s,x)=>s+x.amount);
    final cards=[(t('الإيرادات','Revenue'),rev,Icons.trending_up_rounded),(t('المصروفات','Expenses'),exp,Icons.trending_down_rounded),(t('صافي الحركة','Net Balance'),rev-exp,Icons.account_balance_wallet_rounded),(t('عدد الحركات','Transactions'),txs.length.toDouble(),Icons.receipt_long_rounded)];
    return ListView(padding:const EdgeInsets.all(24),children:[
      Text(t('لوحة التحكم','Dashboard'),style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.w900)),
      const SizedBox(height:6),Text(t('ملخص مالي سريع للمزرعة','Quick financial overview for your farm')),const SizedBox(height:22),
      LayoutBuilder(builder:(_,c)=>GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:c.maxWidth>1100?4:c.maxWidth>650?2:1,crossAxisSpacing:16,mainAxisSpacing:16,childAspectRatio:2.25),itemCount:cards.length,itemBuilder:(_,i)=>Metric(title:cards[i].$1,value:cards[i].$2,icon:cards[i].$3,count:i==3))),
      const SizedBox(height:24),Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(t('آخر الحركات','Recent transactions'),style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800)),const SizedBox(height:12),
        ...txs.take(6).map((x)=>ListTile(leading:CircleAvatar(child:Icon(x.type==TxType.revenue?Icons.arrow_upward:Icons.arrow_downward)),title:Text(x.category),subtitle:Text(date(x.date)),trailing:Text((x.type==TxType.revenue?'+ ':'- ')+x.amount.toStringAsFixed(2)+' ج.م'))),
      ]))),
    ]);
  }
  String date(DateTime d)=>d.day.toString()+'/'+d.month.toString()+'/'+d.year.toString();
}

class Metric extends StatelessWidget {
  final String title; final double value; final IconData icon; final bool count;
  const Metric({super.key,required this.title,required this.value,required this.icon,required this.count});
  @override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(18),child:Row(children:[
    CircleAvatar(radius:26,child:Icon(icon)),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[
      Text(title,maxLines:1,overflow:TextOverflow.ellipsis),const SizedBox(height:4),
      Text(count?value.toInt().toString():value.toStringAsFixed(2)+' ج.م',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900)),
    ])),
  ])));
}

enum TxType { revenue, expense }
class Tx { TxType type; String category; double amount; DateTime date; Tx(this.type,this.category,this.amount,this.date); }

class TransactionsPage extends StatefulWidget {
  final String Function(String,String) t; final TxType type; final List<Tx> txs; final ValueChanged<Tx> onAdd; final ValueChanged<Tx> onDelete;
  const TransactionsPage({super.key,required this.t,required this.type,required this.txs,required this.onAdd,required this.onDelete});
  @override State<TransactionsPage> createState()=>_TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage>{
  String q='';
  @override Widget build(BuildContext context){
    final revenue=widget.type==TxType.revenue;
    final list=widget.txs.where((x)=>x.type==widget.type&&x.category.toLowerCase().contains(q.toLowerCase())).toList();
    return ListView(padding:const EdgeInsets.all(24),children:[
      Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(widget.t(revenue?'الإيرادات':'المصروفات',revenue?'Revenue':'Expenses'),style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.w900)),
        Text(widget.t('إدارة وتسجيل الحركات المالية','Manage and record financial transactions')),
      ])),FilledButton.icon(onPressed:()=>add(context),icon:const Icon(Icons.add),label:Text(widget.t('إضافة','Add')))]),
      const SizedBox(height:18),
      TextField(decoration:InputDecoration(prefixIcon:const Icon(Icons.search),hintText:widget.t('بحث...','Search...'),border:const OutlineInputBorder()),onChanged:(v)=>setState(()=>q=v)),
      const SizedBox(height:12),
      ...list.map((x)=>Card(child:ListTile(leading:CircleAvatar(child:Icon(revenue?Icons.trending_up:Icons.trending_down)),title:Text(x.category),subtitle:Text(x.date.day.toString()+'/'+x.date.month.toString()+'/'+x.date.year.toString()),trailing:Row(mainAxisSize:MainAxisSize.min,children:[Text(x.amount.toStringAsFixed(2)+' ج.م',style:const TextStyle(fontWeight:FontWeight.w800)),IconButton(onPressed:()=>widget.onDelete(x),icon:const Icon(Icons.delete_outline))])))),
      if(list.isEmpty)Padding(padding:const EdgeInsets.all(40),child:Center(child:Text(widget.t('لا توجد بيانات','No transactions')))),
    ]);
  }
  Future<void> add(BuildContext context)async{
    final name=TextEditingController(),amount=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:Text(widget.t('إضافة حركة','Add transaction')),content:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:name,decoration:InputDecoration(labelText:widget.t('البند','Category'))),
      TextField(controller:amount,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:widget.t('المبلغ','Amount'))),
    ]),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:Text(widget.t('إلغاء','Cancel'))),FilledButton(onPressed:()=>Navigator.pop(context,true),child:Text(widget.t('حفظ','Save')))]));
    final n=double.tryParse(amount.text);
    if(ok==true&&name.text.trim().isNotEmpty&&n!=null)widget.onAdd(Tx(widget.type,name.text.trim(),n,DateTime.now()));
  }
}

class Worker {
  String name, phone; double salary, advance, deduction, bonus; int present, absent;
  Worker({required this.name,required this.phone,required this.salary,this.advance=0,this.deduction=0,this.bonus=0,this.present=0,this.absent=0});
  double get due=>salary-advance-deduction-(salary/30*absent)+bonus;
  Map<String,dynamic> toJson()=>{'name':name,'phone':phone,'salary':salary,'advance':advance,'deduction':deduction,'bonus':bonus,'present':present,'absent':absent};
  static Worker fromJson(Map<String,dynamic>x)=>Worker(name:x['name'],phone:x['phone'],salary:(x['salary']as num).toDouble(),advance:(x['advance']as num).toDouble(),deduction:(x['deduction']as num).toDouble(),bonus:(x['bonus']as num).toDouble(),present:x['present'],absent:x['absent']);
}
class StockItem {
  String name,type; double quantity;
  StockItem({required this.name,required this.type,required this.quantity});
  Map<String,dynamic> toJson()=>{'name':name,'type':type,'quantity':quantity};
  static StockItem fromJson(Map<String,dynamic>x)=>StockItem(name:x['name'],type:x['type'],quantity:(x['quantity']as num).toDouble());
}
class WorkersPage extends StatelessWidget {
 final String Function(String,String)t; final List<Worker>workers; final VoidCallback onChange;
 const WorkersPage({super.key,required this.t,required this.workers,required this.onChange});
 @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(24),children:[
  Text(t('الموارد البشرية والعمالة','Workers & HR'),style:Theme.of(c).textTheme.headlineMedium),
  FilledButton.icon(onPressed:()=>add(c),icon:const Icon(Icons.add),label:Text(t('إضافة عامل','Add worker'))),
  ...workers.map((w)=>Card(child:ListTile(title:Text(w.name),subtitle:Text(w.phone+' • '+t('المستحق','Due')+' '+w.due.toStringAsFixed(2)),trailing:Text(w.salary.toStringAsFixed(2))))
  )
 ]);
 Future<void>add(BuildContext c)async{
  final n=TextEditingController(),p=TextEditingController(),s=TextEditingController();
  final ok=await showDialog<bool>(context:c,builder:(_)=>AlertDialog(title:Text(t('عامل جديد','New worker')),content:Column(mainAxisSize:MainAxisSize.min,children:[
   TextField(controller:n,decoration:InputDecoration(labelText:t('الاسم','Name'))),TextField(controller:p,decoration:InputDecoration(labelText:t('الهاتف','Phone'))),TextField(controller:s,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:t('الراتب','Salary')))
  ]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:Text(t('إلغاء','Cancel'))),FilledButton(onPressed:()=>Navigator.pop(c,true),child:Text(t('حفظ','Save')))]));
  final v=double.tryParse(s.text); if(ok==true&&v!=null&&n.text.isNotEmpty){workers.add(Worker(name:n.text,phone:p.text,salary:v));onChange();}
 }
}
class AttendancePage extends StatelessWidget {
 final String Function(String,String)t; final List<Worker>workers; final VoidCallback onChange;
 const AttendancePage({super.key,required this.t,required this.workers,required this.onChange});
 @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(24),children:[
  Text(t('الحضور والانصراف','Attendance'),style:Theme.of(c).textTheme.headlineMedium),
  ...workers.map((w)=>Card(child:ListTile(title:Text(w.name),subtitle:Text(t('حاضر','Present')+' '+w.present.toString()+' • '+t('غياب','Absent')+' '+w.absent.toString()+' • '+w.due.toStringAsFixed(2)),trailing:Wrap(children:[
   IconButton(onPressed:(){w.present++;onChange();},icon:const Icon(Icons.check_circle)),
   IconButton(onPressed:(){w.absent++;onChange();},icon:const Icon(Icons.cancel))
  ]))))
 ]);
}
class StockPage extends StatelessWidget {
 final String Function(String,String)t; final List<StockItem>stock; final String type; final VoidCallback onChange;
 const StockPage({super.key,required this.t,required this.stock,required this.type,required this.onChange});
 @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(24),children:[
  Text(type=='inventory'?t('المخازن والأصول الزراعية','Inventory & Assets'):t('الصوبة الزراعية والشتلات','Greenhouse & Seedlings'),style:Theme.of(c).textTheme.headlineMedium),
  FilledButton.icon(onPressed:(){stock.add(StockItem(name:type=='inventory'?t('أسمدة','Fertilizers'):t('شتلات نخيل','Palm seedlings'),type:type,quantity:1));onChange();},icon:const Icon(Icons.add),label:Text(t('إضافة','Add'))),
  ...stock.where((x)=>x.type==type).map((x)=>Card(child:ListTile(title:Text(x.name),trailing:Text(x.quantity.toString()))))
 ]);
}
class CapitalPage extends StatelessWidget {
 final String Function(String,String)t; const CapitalPage({super.key,required this.t});
 @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(24),children:[
  Text(t('حسابات المالك ورأس المال','Owner & Capital'),style:Theme.of(c).textTheme.headlineMedium),
  ListTile(leading:const Icon(Icons.add_circle),title:Text(t('إيداعات رأس المال','Capital deposits'))),
  ListTile(leading:const Icon(Icons.remove_circle),title:Text(t('سحوبات المالك','Owner withdrawals')))
 ]);
}
class ReportsPage extends StatelessWidget {
 final String Function(String,String)t; final List<Tx>txs; final List<Worker>workers;
 const ReportsPage({super.key,required this.t,required this.txs,required this.workers});
 @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(24),children:[
  Text(t('التقارير والتحليلات','Reports & Analytics'),style:Theme.of(c).textTheme.headlineMedium),
  FilledButton.icon(onPressed:()=>makePdf(),icon:const Icon(Icons.picture_as_pdf),label:Text(t('إنشاء PDF وطباعة','Create PDF / Print'))),
  OutlinedButton.icon(onPressed:()=>openWhatsApp(),icon:const Icon(Icons.chat),label:Text(t('إرسال عبر واتساب','Send via WhatsApp')))
 ]);
 Future<void>makePdf()async{final d=pw.Document();d.addPage(pw.Page(build:(_)=>pw.Column(children:[pw.Text('My Farm Accounts'),pw.Text('Transactions: '+txs.length.toString()),pw.Text('Workers: '+workers.length.toString())])));await Printing.layoutPdf(onLayout:(_)=>d.save());}
 Future<void>openWhatsApp()async{final u=Uri.parse('https://wa.me/?text=My%20Farm%20Accounts');if(await canLaunchUrl(u))await launchUrl(u,mode:LaunchMode.externalApplication);}
}
