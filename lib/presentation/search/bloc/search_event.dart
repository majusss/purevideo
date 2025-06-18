abstract class SearchEvent {
  const SearchEvent();
}

class SearchRequested extends SearchEvent {
  final String query;

  const SearchRequested(this.query);
}

class SearchCleared extends SearchEvent {
  const SearchCleared();
}
