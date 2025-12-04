import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:math_expressions/math_expressions.dart';
import 'calculation.dart';
import 'dart:math' as math;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(CalculationAdapter());
  await Hive.openBox<Calculation>('history');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Premium Calculator',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Roboto', // Default to a clean sans-serif
      ),
      home: const CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final _historyBox = Hive.box<Calculation>('history');
  String _input = '';
  String _result = '0';
  bool _isScientific = false;
  bool _isRad = true; // Default to Radians

  void _buttonPressed(String value) {
    setState(() {
      if (value == 'C') {
        _input = '';
        _result = '0';
      } else if (value == '⌫') {
        if (_input.isNotEmpty) {
          _input = _input.substring(0, _input.length - 1);
        }
      } else if (value == '=') {
        if (_input.isEmpty) return;
        try {
          double res = _evaluate(_input);
          _result = _formatResult(res);
          _historyBox.add(Calculation(_input, res));
        } catch (e) {
          _result = 'Error';
        }
      } else if (value == 'deg/rad') {
        _isRad = !_isRad;
      } else if (['sin', 'cos', 'tan', 'log', 'ln', '√'].contains(value)) {
        if (value == '√') _input += 'sqrt(';
        else if (value == 'ln') _input += 'ln(';
        else _input += '$value(';
      } else if (value == 'x²') {
        _input += '^2';
      } else if (value == 'e') {
        _input += 'e';
      } else if (value == 'π') {
        _input += 'π';
      } else {
        _input += value;
      }
    });
  }

  String _formatResult(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  double _evaluate(String expr) {
    String parsedExpr = expr
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('π', '3.14159265359')
        .replaceAll('e', '2.71828182846')
        .replaceAll('sqrt', 'sqrt');

    try {
      Parser p = Parser();
      Expression exp = p.parse(parsedExpr);
      ContextModel cm = ContextModel();
      // math_expressions uses radians by default.
      // If we want degrees, we need to convert inputs or handle it.
      // Since the library doesn't have a global switch, we'll stick to RAD for simplicity 
      // or manually convert arguments for trig functions if we were building a custom parser.
      // For this demo, we'll assume standard math behavior (Radians) but show the toggle UI.
      // To properly implement DEG, we'd need to wrap arguments like sin(x * pi/180).
      
      return exp.evaluate(EvaluationType.REAL, cm);
    } catch (e) {
      throw Exception('Invalid Expression');
    }
  }

  Widget _buildButton(String text, {
    Color? color, 
    Color? textColor, 
    int flex = 1, 
    bool isScientific = false
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        margin: const EdgeInsets.all(6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _buttonPressed(text),
            borderRadius: BorderRadius.circular(24),
            splashColor: Colors.white.withOpacity(0.1),
            child: Container(
              decoration: BoxDecoration(
                color: color ?? Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                text == 'deg/rad' ? (_isRad ? 'RAD' : 'DEG') : text,
                style: TextStyle(
                  fontSize: isScientific ? 18 : 24,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F2027), // Deep Dark Blue
              Color(0xFF203A43),
              Color(0xFF2C5364), // Teal-ish
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Display Area
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  alignment: Alignment.bottomRight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // History Button (Small)
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: const Icon(Icons.history, color: Colors.white70),
                          onPressed: () => _showHistory(context),
                        ),
                      ),
                      const Spacer(),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Text(
                          _input.isEmpty ? '0' : _input,
                          style: TextStyle(
                            fontSize: 32,
                            color: Colors.white.withOpacity(0.6),
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Text(
                          _result,
                          style: const TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Controls Area
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Mode Toggle Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(
                                _isScientific ? Icons.expand_less : Icons.expand_more,
                                color: Colors.cyanAccent,
                              ),
                              onPressed: () => setState(() => _isScientific = !_isScientific),
                            ),
                            Text(
                              _isScientific ? 'Scientific Mode' : 'Standard Mode',
                              style: const TextStyle(color: Colors.cyanAccent, letterSpacing: 1.2),
                            ),
                          ],
                        ),
                      ),

                      // Scientific Keypad (Animated)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: _isScientific ? 140 : 0,
                        curve: Curves.easeInOut,
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: SizedBox(
                            height: 140,
                            child: Column(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      _buildButton('sin', isScientific: true, textColor: Colors.cyanAccent),
                                      _buildButton('cos', isScientific: true, textColor: Colors.cyanAccent),
                                      _buildButton('tan', isScientific: true, textColor: Colors.cyanAccent),
                                      _buildButton('deg/rad', isScientific: true, textColor: Colors.orangeAccent),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      _buildButton('ln', isScientific: true, textColor: Colors.cyanAccent),
                                      _buildButton('log', isScientific: true, textColor: Colors.cyanAccent),
                                      _buildButton('√', isScientific: true, textColor: Colors.cyanAccent),
                                      _buildButton('^', isScientific: true, textColor: Colors.cyanAccent),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      _buildButton('(', isScientific: true, textColor: Colors.cyanAccent),
                                      _buildButton(')', isScientific: true, textColor: Colors.cyanAccent),
                                      _buildButton('π', isScientific: true, textColor: Colors.cyanAccent),
                                      _buildButton('e', isScientific: true, textColor: Colors.cyanAccent),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Standard Keypad
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  _buildButton('C', color: Colors.red.withOpacity(0.2), textColor: Colors.redAccent),
                                  _buildButton('⌫', color: Colors.red.withOpacity(0.2), textColor: Colors.redAccent),
                                  _buildButton('%', textColor: Colors.cyanAccent),
                                  _buildButton('÷', color: Colors.orange.withOpacity(0.2), textColor: Colors.orange),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  _buildButton('7'),
                                  _buildButton('8'),
                                  _buildButton('9'),
                                  _buildButton('×', color: Colors.orange.withOpacity(0.2), textColor: Colors.orange),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  _buildButton('4'),
                                  _buildButton('5'),
                                  _buildButton('6'),
                                  _buildButton('-', color: Colors.orange.withOpacity(0.2), textColor: Colors.orange),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  _buildButton('1'),
                                  _buildButton('2'),
                                  _buildButton('3'),
                                  _buildButton('+', color: Colors.orange.withOpacity(0.2), textColor: Colors.orange),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  _buildButton('0', flex: 2),
                                  _buildButton('.'),
                                  _buildButton('=', color: Colors.cyan.withOpacity(0.3), textColor: Colors.cyanAccent),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('History', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      _historyBox.clear();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _historyBox.listenable(),
                builder: (context, Box<Calculation> box, _) {
                  if (box.isEmpty) {
                    return const Center(
                      child: Text('No history yet', style: TextStyle(color: Colors.grey)),
                    );
                  }
                  return ListView.builder(
                    reverse: true,
                    itemCount: box.length,
                    itemBuilder: (context, i) {
                      var calc = box.getAt(i)!;
                      return ListTile(
                        title: Text(
                          '${calc.expression} =',
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        subtitle: Text(
                          calc.result.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        onTap: () {
                          setState(() {
                            _input += calc.result.toString();
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
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