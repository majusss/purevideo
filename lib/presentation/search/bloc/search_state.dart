import 'package:purevideo/data/models/movie_model.dart';

abstract class SearchState {
  const SearchState();

  List<MovieModel> get results => [];
}

class SearchInitial extends SearchState {
  const SearchInitial();
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchLoaded extends SearchState {
  final List<MovieModel> _results;

  const SearchLoaded(this._results);

  @override
  List<MovieModel> get results => _results;
}

class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);
}
