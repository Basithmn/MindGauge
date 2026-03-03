import 'package:flutter/material.dart';

import 'models.dart';
import 'services.dart';
import 'ui_components.dart';
class JournalingScreen extends StatefulWidget {
  final DateTime date;
  final JournalEntry? initialEntry;

  const JournalingScreen({
    super.key,
    required this.date,
    this.initialEntry,
  });

  @override
  State<JournalingScreen> createState() => _JournalingScreenState();
}

class _JournalingScreenState extends State<JournalingScreen> {
  late final TextEditingController _controller;
  final MockSentimentService _sentimentService = MockSentimentService();
  SentimentResult _currentSentiment = const SentimentResult("⚪", 0.0, "Analyzing...");

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialEntry?.text ?? '');
    if (widget.initialEntry != null) {
      _currentSentiment = widget.initialEntry!.sentiment;
    }  
  }

  void _saveJournal() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Journal entry cannot be empty.')),
      );
      return;
    }

    setState(() {
      _currentSentiment = const SentimentResult("⏳", 0.0, "Analyzing...");
    });

    final text = _controller.text.trim();
    
    // Call the real API
    final analyzedSentiment =
        await analyzeSentiment(text) ??
        _sentimentService.analyze(text);

    setState(() {
      _currentSentiment = analyzedSentiment;
    });

    // Small delay to let user see the result
    await Future.delayed(const Duration(milliseconds: 800));

    final newEntry = JournalEntry(
      date: widget.date.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0),
      text: text,
      sentiment: analyzedSentiment,
    );

    if (!mounted) return;
    Navigator.of(context).pop(newEntry);
  }
  
  // FIX: Added dispose method
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thought Flow for ${widget.date.day}/${widget.date.month}/${widget.date.year}'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(
                    'Sentiment: ${_currentSentiment.emoji}',
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _currentSentiment.description,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: TextFormField(
                controller: _controller,
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: "Write down your thoughts and feelings...",
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: StyledButton(
                text: 'Save Thought Flow',
                onPressed: _saveJournal,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}