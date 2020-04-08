contract ISynth {
  function issue(address _who, uint256 _value) external;
  function burn(address _who, uint256 _value) external;
}
