import '../../data/xtream/xtream_client.dart';

/// One heading in the Live TV tab: a chosen category, or Favourites.
class ChannelGroup {
  const ChannelGroup({
    required this.id,
    required this.name,
    required this.channels,
  });

  /// A panel category id, or [favouritesGroupId].
  final String id;
  final String name;
  final List<XtreamChannel> channels;
}

/// Not a panel id: Xtream category ids are numeric strings, so this cannot
/// collide with one.
const favouritesGroupId = 'favourites';

/// Groups channels under the categories the viewer chose (§4.1).
///
/// Until 2026-09-28 the tab flattened them back into one list, although the
/// only reason those channels are on the device at all is that someone picked
/// their categories one by one. With a few large categories chosen that is
/// hundreds of rows to scroll past on a remote.
///
/// The rules, each pinned in `channel_groups_test.dart`:
///
/// - **Favourites first**, as a group of its own, when there are any. It is
///   the same set the flat list used to float to the top, now reachable in one
///   step. A favourite still appears in its own category as well: removing it
///   from there would make a category look short by however many were starred.
/// - **Categories in [categoryOrder]**, which the picker saves in the panel's
///   order. A chosen category that returned no channels gets no heading; an
///   empty group on a remote is a stop that leads nowhere.
/// - **Channels in the order they arrived**, which is the panel's order within
///   each category. Not sorted by name: panels number and order channels on
///   purpose, and the viewer's other apps show that order.
/// - A channel whose category is not in [categoryOrder] goes under **Other**
///   at the end rather than disappearing. It should not happen, since channels
///   are fetched per chosen category, but a panel that files a stream under a
///   different id than the one asked for would otherwise lose it silently.
///
/// [names] lacking an id gives "Category N", by position: a bare panel id says
/// nothing to anyone, and the gap only lasts until the names arrive.
List<ChannelGroup> groupChannels({
  required List<XtreamChannel> channels,
  required List<String> categoryOrder,
  required Map<String, String> names,
  required bool Function(XtreamChannel) isFavourite,
}) {
  final byCategory = <String, List<XtreamChannel>>{};
  final other = <XtreamChannel>[];
  final known = categoryOrder.toSet();
  for (final channel in channels) {
    if (known.contains(channel.categoryId)) {
      (byCategory[channel.categoryId] ??= []).add(channel);
    } else {
      other.add(channel);
    }
  }

  final favourites = [
    for (final c in channels)
      if (isFavourite(c)) c,
  ];

  return [
    if (favourites.isNotEmpty)
      ChannelGroup(
        id: favouritesGroupId,
        name: 'Favourites',
        channels: favourites,
      ),
    for (final (i, id) in categoryOrder.indexed)
      if (byCategory[id] case final list? when list.isNotEmpty)
        ChannelGroup(
          id: id,
          name: names[id] ?? 'Category ${i + 1}',
          channels: list,
        ),
    if (other.isNotEmpty)
      ChannelGroup(id: '', name: 'Other', channels: other),
  ];
}
