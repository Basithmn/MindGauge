import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'ui_components.dart';
import 'services/score_service.dart';

class PuzzleGameScreen extends StatefulWidget {
  const PuzzleGameScreen({super.key});

  @override
  State<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen> {
  final List<IconData> _allIcons = [
    Icons.favorite, Icons.star, Icons.wb_sunny, Icons.local_florist,
    Icons.music_note, Icons.pets, Icons.ac_unit, Icons.airplanemode_active,
    Icons.anchor, Icons.apartment, Icons.apple, Icons.audiotrack,
    Icons.beach_access, Icons.bedtime, Icons.bolt, Icons.cake,
    Icons.camera_alt, Icons.car_rental, Icons.castle, Icons.celebration,
    Icons.coffee, Icons.color_lens, Icons.diamond, Icons.directions_boat,
    Icons.eco, Icons.emoji_emotions, Icons.extension, Icons.fastfood,
    Icons.fitness_center, Icons.flight, Icons.forest, Icons.headphones,
  ];

  late List<IconData> _cards;
  late List<bool> _flipped;
  late List<bool> _matched;
  
  int _previousIndex = -1;
  bool _flipAnim = false;
  int _moves = 0;

  late ConfettiController _confettiController;
  Timer? _timer;
  int _secondsElapsed = 0;
  int? _bestTime;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadBestTime();
    _startNewGame();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBestTime() async {
    final best = await ScoreService.getBestTime('puzzle');
    if (mounted) {
      setState(() {
        _bestTime = best;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsElapsed = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _startNewGame() {
    List<IconData> shuffledIcons = List.from(_allIcons)..shuffle(Random());
    List<IconData> selectedPairs = shuffledIcons.take(6).toList();
    
    _cards = [...selectedPairs, ...selectedPairs];
    _cards.shuffle(Random());
    _flipped = List.generate(_cards.length, (_) => false);
    _matched = List.generate(_cards.length, (_) => false);
    _previousIndex = -1;
    _flipAnim = false;
    _moves = 0;
    _startTimer();
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
          _handleWin();
        }
      } else {
        _flipAnim = true;
        
        // Show wrong move alert
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Oops! Not a match.'),
            duration: Duration(milliseconds: 800),
            behavior: SnackBarBehavior.floating,
          ),
        );

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

  Future<void> _handleWin() async {
    _timer?.cancel();
    
    // Save best time
    await ScoreService.setBestTime('puzzle', _secondsElapsed);
    await _loadBestTime();

    if (_secondsElapsed <= 180) {
      _confettiController.play();
    }

    _showWinDialog();
  }

  void _showWinDialog() {
    bool over3Mins = _secondsElapsed > 180;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          over3Mins ? 'Great perseverance!' : 'Congratulations!', 
          style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)
        ),
        content: Text(
          over3Mins 
            ? 'You finished in ${_formatTime(_secondsElapsed)}.\nBetter luck next time for a faster solve!'
            : 'You found all pairs in $_moves moves and ${_formatTime(_secondsElapsed)}! Great job relaxing your mind!'
        ),
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
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Time: ${_formatTime(_secondsElapsed)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text),
                    ),
                    Text(
                      _bestTime != null ? 'Best: ${_formatTime(_bestTime!)}' : 'Best: --:--',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary),
                    ),
                  ],
                ),
              ),
              GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
              const HowToPlayCard(
                rules: [
                  Text('Tap a card to reveal its icon.', style: TextStyle(fontSize: 16)),
                  Text('Find the matching icon by tapping another card.', style: TextStyle(fontSize: 16)),
                  Text('Match all pairs to win the game in the shortest time possible.', style: TextStyle(fontSize: 16)),
                ],
              ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
