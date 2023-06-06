import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:searchfield/searchfield.dart';

class SearchFieldSample extends StatefulWidget {
  const SearchFieldSample({Key? key}) : super(key: key);

  @override
  State<SearchFieldSample> createState() => _SearchFieldSampleState();
}

class _SearchFieldSampleState extends State<SearchFieldSample> {
  final focus = FocusNode();
  late Timer _timer;
  List<String> suggestions = [];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (focus.hasFocus) {
        fetchSuggestions();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> fetchSuggestions() async {
    final value = searchController.text;
    final apiUrl =
        'https://nominatim.openstreetmap.org/search?q=$value&format=json&polygon_geojson=1&addressdetails=1';
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<String> fetchedSuggestions = [];
      for (final suggestion in data) {
        final String country = suggestion['display_name'];
        fetchedSuggestions.add(country);
      }
      setState(() {
        suggestions = fetchedSuggestions;
      });
    } else {
      throw Exception('Failed to fetch suggestions');
    }
  }

  final searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic Sample Demo'),
      ),
      body: Center(
        child: SearchField(
          onSearchTextChanged: (query) {
            searchController.text = query;
            return suggestions
                .where((element) =>
                    element.toLowerCase().contains(query.toLowerCase()))
                .map(
                  (e) => SearchFieldListItem<String>(
                    e,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        e,
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                )
                .toList();
          },
          key: const Key('searchfield'),
          hint: 'Search by country name',
          itemHeight: 50,
          suggestionsDecoration: SuggestionDecoration(
            padding: const EdgeInsets.all(4),
            border: Border.all(color: Colors.blue),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          suggestions: suggestions
              .map(
                (e) => SearchFieldListItem<String>(
                  e,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      e,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
          focusNode: focus,
          suggestionState: Suggestion.expand,
          onSuggestionTap: (SearchFieldListItem<String> x) {
            focus.unfocus();
          },
        ),
      ),
    );
  }
}
