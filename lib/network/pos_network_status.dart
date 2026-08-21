enum PosBroadcastStatus { idle, starting, broadcasting, error }

class PosNetworkState {
  final PosBroadcastStatus status;
  final int connectedKiosks;

  PosNetworkState({
    required this.status,
    this.connectedKiosks = 0,
  });

  PosNetworkState copyWith({PosBroadcastStatus? status, int? connectKiosks}) {
    return PosNetworkState(
        status: status ?? this.status,
        connectedKiosks: connectKiosks ?? this.connectedKiosks);
  }
}
