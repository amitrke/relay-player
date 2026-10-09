import 'dart:io';

/// One network interface, reduced to what picking an address needs.
typedef LanInterface = ({String name, List<String> addresses});

/// The address a phone on the same Wi-Fi should be told to connect to, or null
/// when this device has none.
///
/// A TV or a laptop usually has several: Wi-Fi, Ethernet, a VPN tunnel, a
/// container bridge, a mobile-data interface. Only a private-range address on
/// a real LAN interface is any use to a phone in the room, and the order
/// matters because showing the VPN's address produces a QR code that scans
/// perfectly and never connects.
String? pickLanAddress(Iterable<LanInterface> interfaces) {
  ({int rank, String address})? best;
  for (final iface in interfaces) {
    final name = iface.name.toLowerCase();
    if (_virtualPrefixes.any(name.startsWith) ||
        _virtualWords.any(name.contains)) {
      continue;
    }
    for (final address in iface.addresses) {
      if (!_isPrivate(address)) continue;
      // Wired and wireless first; anything else private still beats nothing.
      final rank =
          _preferredPrefixes.any(name.startsWith) ||
              _preferredWords.any(name.contains)
          ? 0
          : 1;
      if (best == null || rank < best.rank) {
        best = (rank: rank, address: address);
      }
    }
  }
  return best?.address;
}

/// Names that mean a tunnel, a bridge or a cellular modem. Short ones are
/// prefixes only, and the loopback `lo` is left to `includeLoopback: false`:
/// matching it as a prefix or a substring would also throw away Windows'
/// "Local Area Connection".
const _virtualPrefixes = [
  'tun',
  'tap',
  'ppp',
  'veth',
  'virbr',
  'br-',
  'rmnet',
  'ccmni',
  'pdp',
  'p2p',
  'awdl',
  'llw',
  'utun',
];

const _virtualWords = ['vpn', 'docker', 'vmnet', 'vethernet', 'virtual'];

const _preferredPrefixes = ['wlan', 'eth', 'en'];

const _preferredWords = ['wi-fi', 'wifi', 'ethernet', 'wireless'];

bool _isPrivate(String address) {
  final parts = address.split('.');
  if (parts.length != 4) return false;
  final o = [for (final p in parts) int.tryParse(p) ?? -1];
  if (o.any((n) => n < 0 || n > 255)) return false;
  return o[0] == 10 ||
      (o[0] == 192 && o[1] == 168) ||
      (o[0] == 172 && o[1] >= 16 && o[1] <= 31);
}

/// [pickLanAddress] over this device's real interfaces.
Future<String?> findLanAddress() async {
  final found = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLoopback: false,
  );
  return pickLanAddress([
    for (final i in found)
      (name: i.name, addresses: [for (final a in i.addresses) a.address]),
  ]);
}
