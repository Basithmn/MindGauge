import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'ui_components.dart';

class PuzzleGameScreen extends StatefulWidget {
  const PuzzleGameScreen({super.key});

  @override
  State<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen> {
  final List<IconData> _iconPairs = [
    Icons.favorite,
    Icons.star,
    Icons.wb_sunny,
    Icons.local_florist,
    Icons.music_note,
    Icons.pets,
  ];

  late List<IconData> _cards;
  late List<bool> _flipped;
  late List<bool> _matched;
  
  int _previousIndex = -1;
  bool _flipAnim = false;
  int _moves = 0;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    _cards = [..._iconPairs, ..._iconPairs];
    _cards.shuffle(Random());
    _flipped = List.generate(_cards.length, (_) => false);
    _matched = List.generate(_cards.length, (_) => false);
    _previousIndex = -1;
    _flipAnim = false;
    _moves = 0;
    setState(() {});
  }

  void _onCardTap(int index) {
    if (_flipAnim || _flipped[index] || _matched[index]) return;

    setState(() {
      _flipped[index] = true;
    });

    if (_previousIndex == -1) {
      _previousIndex = index;
    } else {
      _moves++;
      if (_cards[_previousIndex] == _cards[index]) {
        _matched[_previousIndex] = true;
        _matched[index] = true;
        _previousIndex = -1;
        
        if (_matched.every((m) => m)) {
          _showWinDialog();
        }
      } else {
        _flipAnim = true;
        Timer(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _flipped[_previousIndex] = false;
              _flipped[index] = false;
              _previousIndex = -1;
              _flipAnim = false;
            });
          }
        });
      }
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Congratulations!', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
        content: Text('You found all pairs in $_moves moves. Great job relaxing your mind!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startNewGame();
            },
            child: const Text('Play Again', style: TextStyle(color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Back', style: TextStyle(color: AppColors.text)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mental Relief Puzzle'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Moves: $_moves',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _onCardTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: _flipped[index] || _matched[index] 
                          ? Colors.white 
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        )
                      ],
                      border: Border.all(
                        color: _flipped[index] || _matched[index] ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: _flipped[index] || _matched[index]
                          ? Icon(
                              _cards[index],
                              size: 40,
                              color: AppColors.secondary,
                            )
                          : const Icon(
                              Icons.help_outline,
                              size: 40,
                              color: Colors.white,
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
