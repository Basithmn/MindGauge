import 'package:flutter/material.dart';
import 'ui_components.dart';

class InterestsSection extends StatefulWidget {
  final List<String> initialInterests;
  final Function(List<String>) onInterestsChanged;

  const InterestsSection({
    super.key,
    required this.initialInterests,
    required this.onInterestsChanged,
  });

  @override
  State<InterestsSection> createState() => _InterestsSectionState();
}

class _InterestsSectionState extends State<InterestsSection> {
  late List<String> _interests;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final List<String> _suggestions = [
    'Reading books',
    'Listening to music',
    'Watching movies / web series',
    'Playing video games',
    'Playing sports (cricket, football, badminton)',
    'Drawing / sketching',
    'Dancing',
    'Singing',
    'Traveling',
    'Photography',
    'Cooking / baking',
    'Gardening',
    'Cycling',
    'Swimming',
    'Writing (stories, poems, journaling)',
    'Learning new skills online',
    'Browsing the internet',
    'Social media content creation',
    'Fitness / gym workouts',
    'Yoga',
  ];

  @override
  void initState() {
    super.initState();
    _interests = List.from(widget.initialInterests);
  }

  void _addInterest(String interest) {
    interest = interest.trim();
    if (interest.isNotEmpty && !_interests.contains(interest)) {
      setState(() {
        _interests.add(interest);
      });
      widget.onInterestsChanged(_interests);
    }
    _controller.clear();
  }

  void _removeInterest(String interest) {
    setState(() {
      _interests.remove(interest);
    });
    widget.onInterestsChanged(_interests);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'YOUR INTERESTS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _interests.map((interest) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 8,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              interest,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.white,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _removeInterest(interest),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_interests.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                    'Add your favorite hobbies to help revive your mood!',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: AppColors.text,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              RawAutocomplete<String>(
                textEditingController: _controller,
                focusNode: _focusNode,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return _suggestions.where((String option) {
                    return option.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    );
                  });
                },
                onSelected: (String selection) {
                  _addInterest(selection);
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: 'Add an interest',
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: AppColors.primary,
                            ),
                            onPressed: () => _addInterest(controller.text),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (value) => _addInterest(value),
                      );
                    },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      borderRadius: BorderRadius.circular(15),
                      child: IntrinsicWidth(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              return InkWell(
                                onTap: () => onSelected(option),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(option),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
