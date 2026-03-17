import 'package:flutter/material.dart';
import 'package:monthly_count/data/qa_list.dart';
import 'package:monthly_count/widgets/info_card.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Q&A'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: qaList
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InfoCard(
                  title: item['question']!,
                  items: [item['answer']!],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
