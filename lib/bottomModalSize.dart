/// Represents the dimensions and text sizes for a bottom modal component.
class BottomModalSize {
  double _height;
  double _platformWidth;
  double _nameWidth;
  double _priceWidth;
  double _mainTextSize;
  double _auxiliaryTextSize;

  /// Constructs an instance of [BottomModalSize] with the given dimensions and text sizes.
  BottomModalSize({
    required double height,
    required double platformWidth,
    required double nameWidth,
    required double priceWidth,
    required double mainTextSize,
    required double auxiliaryTextSize,
  })  : _height = height,
        _platformWidth = platformWidth,
        _nameWidth = nameWidth,
        _priceWidth = priceWidth,
        _mainTextSize = mainTextSize,
        _auxiliaryTextSize = auxiliaryTextSize;

  /// Gets the height of the bottom modal.
  double get height => _height;

  /// Sets the height of the bottom modal.
  set height(double value) => _height = value;

  /// Gets the width of the logo in the bottom modal.
  double get platformWidth => _platformWidth;

  /// Sets the width of the logo in the bottom modal.
  set platformWidth(double value) => _platformWidth = value;

  /// Gets the width of the name field in the bottom modal.
  double get nameWidth => _nameWidth;

  /// Sets the width of the name field in the bottom modal.
  set nameWidth(double value) => _nameWidth = value;

  /// Gets the width of the price field in the bottom modal.
  double get priceWidth => _priceWidth;

  /// Sets the width of the price field in the bottom modal.
  set priceWidth(double value) => _priceWidth = value;

  /// Gets the size of the main text in the bottom modal.
  double get mainTextSize => _mainTextSize;

  /// Sets the size of the main text in the bottom modal.
  set mainTextSize(double value) => _mainTextSize = value;

  /// Gets the size of the auxiliary text in the bottom modal.
  double get auxiliaryTextSize => _auxiliaryTextSize;

  /// Sets the size of the auxiliary text in the bottom modal.
  set auxiliaryTextSize(double value) => _auxiliaryTextSize = value;
}

