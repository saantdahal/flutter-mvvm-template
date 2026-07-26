sealed class ViewState<T> {
  const ViewState();
}

final class ViewStateLoading<T> extends ViewState<T> {
  const ViewStateLoading();
}

final class ViewStateSuccess<T> extends ViewState<T> {
  final T data;

  const ViewStateSuccess(this.data);
}

final class ViewStateError<T> extends ViewState<T> {
  final String message;

  const ViewStateError(this.message);
}
