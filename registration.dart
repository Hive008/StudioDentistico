import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'loading.dart';
import 'login.dart';
import 'main.dart';
import 'package:google_fonts/google_fonts.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  RegistrationPageState createState() => RegistrationPageState();
}

class RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _passwordController = TextEditingController();

  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _name = '';

  bool _isPasswordHidden = true;

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordHidden = !_isPasswordHidden;
    });
  }

  void _submitForm() async {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      form.save();
      if (_password == _confirmPassword) {
        try {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (newContext) {
                _auth
                    .createUserWithEmailAndPassword(
                  email: _email,
                  password: _password,
                )
                    .then((userCredential) async {
                  await userCredential.user?.updateDisplayName(_name);

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const MyHomePage(),
                      ),
                    );
                  });
                });
                return const LoadingScreen();
              },
            ),
          );
        } catch (e) {
          if (kDebugMode) {
            print('Failed to create user: $e');
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
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
                  'Crea un account',
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
                      child: SingleChildScrollView(
                        child: Column(
                          children: <Widget>[
                            TextFormField(
                              decoration: const InputDecoration(
                                  labelText: 'Nome e Cognome'),
                              validator: MultiValidator([
                                RequiredValidator(
                                    errorText: 'Questo campo è obbligatorio'),
                              ]),
                              style: GoogleFonts.poppins(),
                              onSaved: (value) => _name = value!,
                            ),
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
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordHidden
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Theme.of(context).primaryColorDark,
                                  ),
                                  onPressed: _togglePasswordVisibility,
                                ),
                              ),
                              obscureText: _isPasswordHidden,
                              validator: MultiValidator([
                                RequiredValidator(
                                    errorText: 'Questo campo è obbligatorio'),
                                MinLengthValidator(6,
                                    errorText:
                                        'La password deve essere di almeno 6 caratteri'),
                              ]),
                              style: GoogleFonts.poppins(),
                              onSaved: (value) => _password = value!,
                            ),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Conferma Password',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordHidden
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Theme.of(context).primaryColorDark,
                                  ),
                                  onPressed: _togglePasswordVisibility,
                                ),
                              ),
                              obscureText: _isPasswordHidden,
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return 'Le password non corrispondono';
                                }
                                return null;
                              },
                              style: GoogleFonts.poppins(),
                              onSaved: (value) => _confirmPassword = value!,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 30),
                              child: Column(
                                children: <Widget>[
                                  SizedBox(
                                    width: 160,
                                    height: 60,
                                    child: ElevatedButton(
                                      onPressed: _submitForm,
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                      ),
                                      child: Text(
                                        'Registrati',
                                        style: GoogleFonts.poppins(
                                          fontSize: 22,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text("Hai già un account?",
                                          style: GoogleFonts.poppins()),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const LoginPage(),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          "Accedi",
                                          style: GoogleFonts.poppins(
                                            color:
                                                Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
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
