import 'package:flutter/material.dart';

class TopicSelector extends StatelessWidget {
  final List<String> topics;
  final String selectedTopic;
  final ValueChanged<String> onTopicSelected;

  const TopicSelector({
    super.key,
    required this.topics,
    required this.selectedTopic,
    required this.onTopicSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12.0,
      runSpacing: 5.0,
      children: topics.map((topic) {
        final isSelected = selectedTopic == topic;
        return ChoiceChip(
          label: Text(topic),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              onTopicSelected(topic);
            }
          },
          selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}
