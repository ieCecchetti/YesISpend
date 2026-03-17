import 'package:flutter/material.dart';

class AutofillTextBox extends StatefulWidget {
  const AutofillTextBox({
    super.key,
    required this.controller,
    required this.labelText,
    required this.options,
    this.enabled = true,
    this.readOnly = false,
    this.validator,
    this.onSelected,
    this.decoration,
  });

  final TextEditingController controller;
  final String labelText;
  final List<String> options;
  final bool enabled;
  final bool readOnly;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSelected;
  final InputDecoration? decoration;

  @override
  State<AutofillTextBox> createState() => _AutofillTextBoxState();
}

class _AutofillTextBoxState extends State<AutofillTextBox> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return const Iterable<String>.empty();
        return widget.options.where(
          (option) => option.toLowerCase().contains(query),
        );
      },
      onSelected: (selection) {
        widget.controller.text = selection;
        widget.onSelected?.call(selection);
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, minWidth: 220),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Text(
                        option,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, textEditingController, focusNode, _) {
        final defaultDecoration =
            widget.decoration ??
            InputDecoration(
              labelText: widget.labelText,
            );
        final mergedDecoration = defaultDecoration.copyWith(
          labelText: defaultDecoration.labelText ?? widget.labelText,
        );

        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          decoration: mergedDecoration,
          validator: widget.validator,
        );
      },
    );
  }
}
