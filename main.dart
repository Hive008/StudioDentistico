import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:whatislove/registration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyABZq2PCCaDWiKH1aZn-b1_dZXaNpk-CFQ',
      appId: '1:515157067414:android:8dfff6aa0c32b4e7b2e4b7',
      messagingSenderId: '515157067414',
      projectId: 'studiodentistico-1a349',
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('it', 'IT'),
      ],
      initialRoute: '/register',
      routes: {
        '/register': (context) => const RegistrationPage(),
        '/login': (context) => const LoginPage(),
      },
      debugShowCheckedModeBanner: false,
      title: 'Studio Dentistico',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasData && snapshot.data!.uid.isNotEmpty) {
            return const MyHomePage(); // Navigate to the main screen if user is logged in
          } else {
            return const RegistrationPage(); // Show registration page if user is not logged in
          }
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final _auth = FirebaseAuth.instance;
  List<Booking> _bookings = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _deleteBooking(Booking booking) {
    setState(() {
      _bookings.remove(booking);
    });
    _saveBookingData();
  }

  Widget _buildLastBookingCard() {
    if (_bookings.isEmpty) {
      // Se non ci sono prenotazioni, mostra un messaggio
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 50, 0, 40),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Il tuo ultimo appuntamento',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
          ),
          Text(
            'Non hai appuntamenti recenti',
            style: GoogleFonts.poppins(
              fontSize: 32,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 100),
        ],
      );
    }

    final lastBooking = _bookings.last;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 50, 0, 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Il tuo ultimo appuntamento',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ),
        Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 50.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      lastBooking.imageUrl,
                      height: 160,
                      width: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lastBooking.serviceName,
                        style: GoogleFonts.poppins(
                            fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        lastBooking.details.isNotEmpty
                            ? lastBooking.details
                            : 'Nessun dettaglio',
                        style: GoogleFonts.poppins(fontSize: 18),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        height: 50,
                        width: 120,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                            textStyle: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 20,
                            ),
                          ),
                          child: const Text('Ripeti'),
                          onPressed: () {
                            // qui andrà la logica per l'onTap
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadBookingData(); // Carica la cronologia delle prenotazioni quando l'app viene aperta
  }

  void _addBooking(Booking booking) {
    setState(() {
      _bookings.add(booking);
    });
    _saveBookingData(); // Salva la cronologia delle prenotazioni ogni volta che viene aggiunta una nuova prenotazione
  }

  Future<void> _loadBookingData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonData = prefs.getString('bookings');
    if (jsonData != null) {
      List<dynamic> data = jsonDecode(jsonData);
      setState(() {
        _bookings = data.map((item) => Booking.fromJson(item)).toList();
      });
    }
  }

  Future<void> _saveBookingData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonData =
        jsonEncode(_bookings.map((item) => item.toJson()).toList());
    prefs.setString('bookings', jsonData);
  }

  @override
  Widget build(BuildContext context) {
    String displayName = _auth.currentUser?.displayName ?? '';
    List<String> nameParts = displayName.split(' ');
    String firstName = nameParts.isNotEmpty ? nameParts[0] : '';

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF3499FF),
                    Color(0xFF3A3985)
                  ], // Modifica qui con il tuo gradiente
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: DrawerHeader(
                child: Center(
                  child: Text(
                    'Impostazioni',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              leading: const Icon(Icons.account_circle, size: 30),
              title: const Text(
                'Profilo',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54),
              ),
              onTap: () {
                // Aggiungi la tua navigazione o logica qui
              },
            ),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              leading: const Icon(Icons.notifications, size: 30),
              title: const Text(
                'Notifiche',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54),
              ),
              onTap: () {
                // Aggiungi la tua navigazione o logica qui
              },
            ),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              leading: const Icon(Icons.history, size: 30),
              title: const Text(
                'Cronologia',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54),
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryPage(
                      bookings: _bookings,
                      onDelete: _deleteBooking,
                    ),
                  ),
                );
                _loadBookingData();
              },
            ),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              leading: const Icon(Icons.logout, color: Colors.red, size: 30),
              title: const Text(
                'Logout',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.red,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                // Aggiungi la tua navigazione o logica qui
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3499FF), Color(0xFF3A3985)],
              ),
            ),
            child: LayoutBuilder(
              // Qui
              builder:
                  (BuildContext context, BoxConstraints viewportConstraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    // e qui
                    constraints: BoxConstraints(
                      minHeight: viewportConstraints.maxHeight,
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Appbar
                            AppBar(
                              automaticallyImplyLeading: false,
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              toolbarHeight: 120,
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bentornato!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  Text(
                                    'Ciao, $firstName',
                                    style: GoogleFonts.poppins(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                              actions: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(right: 20.0),
                                  child: Material(
                                    color: Colors.white.withOpacity(0.8),
                                    shape: const CircleBorder(),
                                    elevation: 5.0,
                                    child: IconButton(
                                      iconSize: 32.0,
                                      icon: const Icon(Icons.settings,
                                          color: Colors.blue),
                                      onPressed: () {
                                        _scaffoldKey.currentState?.openDrawer();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 30, 0, 15),
                              child: Text(
                                'I nostri servizi',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ),
                            // Service Cards
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: services.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 3 / 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemBuilder: (BuildContext context, int index) {
                                return GestureDetector(
                                  onTap: () {
                                    if (services[index].serviceName ==
                                        'Altro') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DettagliPage(
                                            serviceName:
                                                services[index].serviceName,
                                            imageUrl: services[index].imageUrl,
                                          ),
                                        ),
                                      );
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BookingPage(
                                            serviceName:
                                                services[index].serviceName,
                                            imageUrl: services[index].imageUrl,
                                            details:
                                                '', // oppure 'Nessun dettaglio specificato'
                                            addBookingCallback: _addBooking,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Card(
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                        image: DecorationImage(
                                          image: NetworkImage(
                                              services[index].imageUrl),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(15.0),
                                          color: Colors.black.withOpacity(0.3),
                                        ),
                                        child: Center(
                                          child: Text(
                                            services[index].serviceName,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.poppins(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildLastBookingCard(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Service {
  final String serviceName;
  final String imageUrl;
  final String details;

  Service(
      {required this.serviceName,
      required this.imageUrl,
      this.details = "Nessun dettaglio"});
}

List<Service> services = [
  Service(
      serviceName: 'Pulizia Dentale',
      imageUrl:
          'https://th.bing.com/th/id/OIP.ncL3v2TEqIHttQT0i7a0cQHaGQ?pid=ImgDet&rs=1'),
  Service(
      serviceName: 'Estrazione Dentaria',
      imageUrl:
          'https://th.bing.com/th/id/R.8497ccefd0b69e902cbbeeb15f45a7d0?rik=%2fG45AliEkMGQsA&pid=ImgRaw&r=0'),
  Service(
      serviceName: 'Sbiancamento Dentale',
      imageUrl:
          'https://th.bing.com/th/id/R.42a7238c5dcbce915d7f6f82fa1374e3?rik=zzrvgHhB%2fJ4hQw&riu=http%3a%2f%2fwww.cesmed.net%2fwp-content%2fuploads%2f2020%2f06%2fsbiancamento-dentale.jpg&ehk=PW2l0ttLlGtEcbYnVHw3wKAfomV4rROoRTdQJIDCRRM%3d&risl=&pid=ImgRaw&r=0'),
  Service(
      serviceName: 'Otturazione Carie',
      imageUrl:
          'https://th.bing.com/th/id/OIP.812Yftvxm9T5XiQGIryBCQHaE8?pid=ImgDet&rs=1'),
  Service(
      serviceName: 'Gestione Apparecchio',
      imageUrl:
          'https://th.bing.com/th/id/OIP.yuDRO9JmdE3lue1XreYcFgHaE8?pid=ImgDet&rs=1'),
  Service(
      serviceName: 'Altro',
      imageUrl:
          'https://th.bing.com/th/id/OIP.8eVQUMQnrBGov7GZB7AOswHaE8?pid=ImgDet&rs=1'),
];

class DettagliPage extends StatefulWidget {
  final String serviceName;
  final String imageUrl;

  const DettagliPage({
    Key? key,
    required this.serviceName,
    required this.imageUrl,
  }) : super(key: key);

  @override
  DettagliPageState createState() => DettagliPageState();
}

class DettagliPageState extends State<DettagliPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Booking> _bookings = [];

  void _addBooking(Booking booking) {
    setState(() {
      _bookings.add(booking);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF3499FF), Color(0xFF3A3985)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    Expanded(
                      child: Text(
                        'Dettagli del servizio',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 34,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: SizedBox(
                    height: 450,
                    width: double.infinity,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              widget.imageUrl,
                              width: double.infinity,
                              height: 300,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: TextFormField(
                            controller: _controller,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Per favore inserisci i dettagli del servizio';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Di che servizio hai bisogno?',
                              hintText:
                                  'Es. Voglio controllare la salute generale dei miei denti',
                              labelStyle: GoogleFonts.poppins(),
                              hintStyle: GoogleFonts.poppins(),
                            ),
                            minLines: 1,
                            maxLines: 5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 50.0),
                child: SizedBox(
                  width: 180,
                  height: 80,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_controller.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Per favore inserisci i dettagli del servizio'),
                          ),
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => BookingPage(
                              serviceName: 'Servizio Personalizzato',
                              details: _controller.text,
                              imageUrl: widget.imageUrl,
                              addBookingCallback: _addBooking,
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    child: Text(
                      'Conferma',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BookingPage extends StatefulWidget {
  final String serviceName;
  final String imageUrl;
  final String details;
  final Function(Booking) addBookingCallback;

  const BookingPage({
    Key? key,
    required this.serviceName,
    required this.imageUrl,
    required this.details,
    required this.addBookingCallback,
  }) : super(key: key);

  @override
  BookingPageState createState() => BookingPageState();
}

class BookingPageState extends State<BookingPage> {
  String? _details;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _details = widget.details;
  }

  Future<void> _navigateToDetailsPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DettagliPage(
          serviceName: widget.serviceName,
          imageUrl: widget.imageUrl,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _details = result;
      });
    }
  }

  void _presentDatePicker(BuildContext context) {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('it', 'IT'),
    ).then((pickedDate) {
      if (pickedDate == null) {
        return;
      }
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF3499FF), Color(0xFF3A3985)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      Expanded(
                        child: Text(
                          'Prenota il tuo servizio',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 34,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      height: 450,
                      width: double.infinity,
                      padding: const EdgeInsets.all(0),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.network(
                                widget.imageUrl,
                                width: double.infinity,
                                height: 300,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              widget.serviceName,
                              style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: (_details == null || _details!.isEmpty)
                                ? TextButton(
                                    onPressed: _navigateToDetailsPage,
                                    child: Text(
                                      'Aggiungi dettagli (facoltativo)',
                                      style: GoogleFonts.poppins(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Dettagli: $_details',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      color: Colors.black.withOpacity(0.8),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 10.0),
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      height: 450,
                      width: double.infinity,
                      padding: const EdgeInsets.all(0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(top: 40.0),
                            child: Text(
                              'Seleziona una data',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 100.0, left: 60.0, right: 60.0),
                            child: SizedBox(
                              width: 200,
                              height: 80,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 5,
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                onPressed: () => _presentDatePicker(context),
                                child: Text(
                                  'Seleziona la data',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_selectedDate != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 100.0),
                              child: Text(
                                'Data selezionata: ${DateFormat.yMd().format(_selectedDate!)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: Colors.black.withOpacity(0.8),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_selectedDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 50.0, bottom: 100.0),
                    child: SizedBox(
                      height: 80,
                      width: 180,
                      child: ElevatedButton(
                        onPressed: () {
                          widget.addBookingCallback(Booking(
                            serviceName: widget.serviceName,
                            imageUrl: widget.imageUrl,
                            details: _details ?? 'Nessun dettaglio',
                            date: _selectedDate!,
                          ));

                          // Mostra un messaggio.
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Prenotazione aggiunta alla cronologia'),
                              duration: Duration(seconds: 2),
                            ),
                          );

                          // Ritorna a MyHomePage.
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MyHomePage()),
                            (route) =>
                                false, // rimuove tutte le precedenti routes dallo stack
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 5,
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        child: Text(
                          'Prenota',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Booking {
  final String serviceName;
  final String imageUrl;
  final String details;
  final DateTime date;

  Booking({
    required this.serviceName,
    required this.imageUrl,
    required this.details,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'serviceName': serviceName,
        'imageUrl': imageUrl,
        'details': details,
        'date': date.toIso8601String(),
      };

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        serviceName: json['serviceName'],
        imageUrl: json['imageUrl'],
        details: json['details'],
        date: DateTime.parse(json['date']),
      );
}

class HistoryPage extends StatefulWidget {
  final List<Booking> bookings;
  final Function(Booking) onDelete;

  const HistoryPage({Key? key, required this.bookings, required this.onDelete})
      : super(key: key);

  @override
  HistoryPageState createState() => HistoryPageState();
}

class HistoryPageState extends State<HistoryPage> {
  List<Booking> get bookings => widget.bookings;

  void _deleteBooking(int index) {
    Booking bookingToDelete = bookings.reversed.toList()[index];

    setState(() {
      bookings.remove(bookingToDelete);
    });

    widget.onDelete(bookingToDelete);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF3499FF), Color(0xFF3A3985)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    Expanded(
                      child: Text(
                        'Cronologia',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 34,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                Expanded(
                  child: bookings.isNotEmpty
                      ? ListView.builder(
                          itemCount: bookings.length,
                          itemBuilder: (ctx, index) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15.0),
                            child: _buildBookingCard(ctx, index),
                          ),
                        )
                      : Center(
                          child: Text(
                            'Non hai appuntamenti recenti',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 30,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, int index) {
    Booking booking = bookings.reversed.toList()[index];
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        booking.imageUrl,
                        height: 160,
                        width: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.serviceName,
                          style: GoogleFonts.poppins(
                              fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          booking.details.isNotEmpty
                              ? booking.details
                              : 'Nessun dettaglio',
                          style: GoogleFonts.poppins(fontSize: 18),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          DateFormat.yMd().format(booking.date),
                          style: GoogleFonts.poppins(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Conferma eliminazione'),
                      content: const Text(
                          'Sei sicuro di voler eliminare questa prenotazione?'),
                      actions: [
                        TextButton(
                          child: const Text('No'),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                          },
                        ),
                        TextButton(
                          child: const Text('Sì'),
                          onPressed: () {
                            _deleteBooking(index);
                            Navigator.of(ctx).pop();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
