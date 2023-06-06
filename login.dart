import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whatislove/registration.dart';
import 'loading.dart';
import 'main.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;

  String _email = '';
  String _password = '';
  bool _obscureText = true;

  void _togglePasswordVisibility() {
    // cambiare la visibilità della password
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _login() async {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      form.save();
      try {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (newContext) {
              _auth
                  .signInWithEmailAndPassword(
                email: _email,
                password: _password,
              )
                  .then((_) {
                Navigator.of(newContext).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const MyHomePage(),
                  ),
                );
              });
              return const LoadingScreen();
            },
          ),
        );
      } catch (e) {
        if (kDebugMode) {
          print('Failed to sign in: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3499FF), Color(0xFF3A3985)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Bentornato!',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 30),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'Email'),
                            validator: MultiValidator([
                              RequiredValidator(
                                  errorText: 'Questo campo è obbligatorio'),
                              EmailValidator(
                                  errorText:
                                      'Inserisci un indirizzo email valido'),
                            ]),
                            style: GoogleFonts.poppins(),
                            onSaved: (value) => _email = value!,
                          ),
                          TextFormField(
                            decoration: InputDecoration(
                                labelText: 'Password',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureText
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  onPressed: _togglePasswordVisibility,
                                )),
                            obscureText: _obscureText,
                            validator: RequiredValidator(
                                errorText: 'Questo campo è obbligatorio'),
                            style: GoogleFonts.poppins(),
                            onSaved: (value) => _password = value!,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 30),
                            child: SizedBox(
                              width: 160,
                              height: 60,
                              child: ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: Text('Accedi',
                                      style: GoogleFonts.poppins(
                                        fontSize: 22,
                                      ))),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text('Non hai ancora un account?',
                                    style: GoogleFonts.poppins(
                                        color: Colors.black.withOpacity(0.6))),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const RegistrationPage()),
                                    );
                                  },
                                  child: Text(
                                    "Registrati",
                                    style: GoogleFonts.poppins(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
