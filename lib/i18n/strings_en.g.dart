///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final tr = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	dynamic operator[](String key) => _meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$common$en common = Translations$common$en.internal(_root);
	late final Translations$player$en player = Translations$player$en.internal(_root);
	Map<String, String> get languages => {
		'en': 'English',
		'es': 'Spanish',
		'fr': 'French',
		'de': 'German',
		'it': 'Italian',
		'pt': 'Portuguese',
		'nl': 'Dutch',
		'sv': 'Swedish',
		'no': 'Norwegian',
		'da': 'Danish',
		'fi': 'Finnish',
		'pl': 'Polish',
		'cs': 'Czech',
		'hu': 'Hungarian',
		'ro': 'Romanian',
		'el': 'Greek',
		'ru': 'Russian',
		'uk': 'Ukrainian',
		'tr': 'Turkish',
		'ar': 'Arabic',
		'he': 'Hebrew',
		'hi': 'Hindi',
		'bn': 'Bengali',
		'pa': 'Punjabi',
		'ta': 'Tamil',
		'te': 'Telugu',
		'ur': 'Urdu',
		'th': 'Thai',
		'vi': 'Vietnamese',
		'id': 'Indonesian',
		'zh': 'Chinese',
		'ja': 'Japanese',
		'ko': 'Korean',
	};
	late final Translations$subtitleSize$en subtitleSize = Translations$subtitleSize$en.internal(_root);
	late final Translations$units$en units = Translations$units$en.internal(_root);
	late final Translations$downloads$en downloads = Translations$downloads$en.internal(_root);
	late final Translations$watchActions$en watchActions = Translations$watchActions$en.internal(_root);
	late final Translations$show$en show = Translations$show$en.internal(_root);
	late final Translations$shell$en shell = Translations$shell$en.internal(_root);
	late final Translations$resume$en resume = Translations$resume$en.internal(_root);
	late final Translations$library$en library = Translations$library$en.internal(_root);
	late final Translations$liveTv$en liveTv = Translations$liveTv$en.internal(_root);
	late final Translations$ai$en ai = Translations$ai$en.internal(_root);
	late final Translations$search$en search = Translations$search$en.internal(_root);
	late final Translations$settings$en settings = Translations$settings$en.internal(_root);
	late final Translations$onboarding$en onboarding = Translations$onboarding$en.internal(_root);
	late final Translations$addSource$en addSource = Translations$addSource$en.internal(_root);
	late final Translations$plex$en plex = Translations$plex$en.internal(_root);
	late final Translations$local$en local = Translations$local$en.internal(_root);
	late final Translations$smb$en smb = Translations$smb$en.internal(_root);
	late final Translations$xtream$en xtream = Translations$xtream$en.internal(_root);
	late final Translations$transfer$en transfer = Translations$transfer$en.internal(_root);
}

// Path: common
class Translations$common$en {
	Translations$common$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Back'
	String get back => 'Back';

	/// en: 'Try again'
	String get tryAgain => 'Try again';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'No DRM. Protected commercial catalogues such as Netflix or Disney+ cannot be played.'
	String get noDrm => 'No DRM. Protected commercial catalogues such as Netflix or Disney+ cannot be played.';
}

// Path: player
class Translations$player$en {
	Translations$player$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'That share is no longer configured.'
	String get shareGone => 'That share is no longer configured.';

	/// en: 'That file is no longer on the share.'
	String get shareFileGone => 'That file is no longer on the share.';

	/// en: 'That file is no longer on this device.'
	String get deviceFileGone => 'That file is no longer on this device.';

	/// en: 'That line is no longer configured.'
	String get lineGone => 'That line is no longer configured.';

	/// en: 'Video'
	String get untitledVideo => 'Video';

	/// en: 'Episode'
	String get untitledEpisode => 'Episode';

	/// en: 'Film'
	String get untitledFilm => 'Film';

	/// en: 'Live'
	String get untitledLive => 'Live';

	/// en: 'This channel stopped and did not come back.'
	String get channelFroze => 'This channel stopped and did not come back.';

	/// en: 'This channel is not responding. Listings often outrun reality on a panel, so try another, or the same one again.'
	String get channelNotResponding => 'This channel is not responding. Listings often outrun reality on a panel, so try another, or the same one again.';

	/// en: 'This did not start playing. The server may be busy, or the file may need transcoding, which is not supported yet.'
	String get didNotStart => 'This did not start playing. The server may be busy, or the file may need transcoding, which is not supported yet.';

	/// en: 'Stopped while the app was in the background, so the connection is free for other devices.'
	String get released => 'Stopped while the app was in the background, so the connection is free for other devices.';

	/// en: 'Rejoin'
	String get rejoin => 'Rejoin';

	/// en: 'LIVE'
	String get live => 'LIVE';

	/// en: 'Back {seconds} seconds'
	String skipBack({required Object seconds}) => 'Back ${seconds} seconds';

	/// en: 'Forward {seconds} seconds'
	String skipForward({required Object seconds}) => 'Forward ${seconds} seconds';

	/// en: 'Pause'
	String get pause => 'Pause';

	/// en: 'Play'
	String get play => 'Play';

	/// en: 'Audio and subtitles'
	String get tracks => 'Audio and subtitles';

	/// en: 'Audio'
	String get audio => 'Audio';

	/// en: 'Subtitles'
	String get subtitles => 'Subtitles';

	/// en: 'Off'
	String get off => 'Off';

	/// en: 'Track {n}'
	String trackNumber({required Object n}) => 'Track ${n}';
}

// Path: subtitleSize
class Translations$subtitleSize$en {
	Translations$subtitleSize$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Small'
	String get small => 'Small';

	/// en: 'Medium'
	String get medium => 'Medium';

	/// en: 'Large'
	String get large => 'Large';
}

// Path: units
class Translations$units$en {
	Translations$units$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: '{m} min'
	String minutes({required Object m}) => '${m} min';

	/// en: '{h} h'
	String hours({required Object h}) => '${h} h';

	/// en: '{h} h {m} min'
	String hoursMinutes({required Object h, required Object m}) => '${h} h ${m} min';

	/// en: '{m} min left'
	String minutesLeft({required Object m}) => '${m} min left';

	/// en: '{s} s'
	String seconds({required Object s}) => '${s} s';
}

// Path: downloads
class Translations$downloads$en {
	Translations$downloads$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Nothing downloaded yet. Press and hold a movie or episode from your Plex library and choose Download, then watch it here with no network.'
	String get empty => 'Nothing downloaded yet. Press and hold a movie or episode from your Plex library and choose Download, then watch it here with no network.';

	/// en: 'Downloads'
	String get title => 'Downloads';

	/// en: '(one) {{n} item · {size} on this device} (other) {{n} items · {size} on this device}'
	String summary({required num n, required Object size}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} item · ${size} on this device',
		other: '${n} items · ${size} on this device',
	);

	/// en: '(one) {1 watch here is waiting to be sent to Plex.} (other) {{n} watches here are waiting to be sent to Plex.}'
	String pendingWatches({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '1 watch here is waiting to be sent to Plex.',
		other: '${n} watches here are waiting to be sent to Plex.',
	);

	/// en: 'Downloads continue while the app is open. Closing it pauses them, and nothing already saved is lost.'
	String get foregroundOnly => 'Downloads continue while the app is open. Closing it pauses them, and nothing already saved is lost.';

	/// en: 'Downloading, {received}'
	String downloadingBytes({required Object received}) => 'Downloading, ${received}';

	/// en: 'Downloading {percent}% · {received} of {total}'
	String downloadingPercent({required Object percent, required Object received, required Object total}) => 'Downloading ${percent}% · ${received} of ${total}';

	/// en: 'Waiting for its turn'
	String get queued => 'Waiting for its turn';

	/// en: 'Paused'
	String get paused => 'Paused';

	/// en: 'Paused at {percent}% · select to resume'
	String pausedAt({required Object percent}) => 'Paused at ${percent}% · select to resume';

	/// en: '{error} Select to try again.'
	String failed({required Object error}) => '${error} Select to try again.';

	/// en: 'It did not finish.'
	String get failedUnknown => 'It did not finish.';

	/// en: 'Delete this download?'
	String get deleteTitle => 'Delete this download?';

	/// en: 'Cancel this download?'
	String get cancelTitle => 'Cancel this download?';

	/// en: '"{title}" will be removed from this device. It stays on your Plex server.'
	String removeBody({required Object title}) => '"${title}" will be removed from this device. It stays on your Plex server.';

	/// en: '"{title}" will be removed from this device, freeing {size}. It stays on your Plex server.'
	String removeBodyFreeing({required Object title, required Object size}) => '"${title}" will be removed from this device, freeing ${size}. It stays on your Plex server.';

	/// en: 'Keep it'
	String get keepIt => 'Keep it';

	/// en: 'Delete'
	String get delete => 'Delete';

	late final Translations$downloads$errors$en errors = Translations$downloads$errors$en.internal(_root);
	late final Translations$downloads$rule$en rule = Translations$downloads$rule$en.internal(_root);
}

// Path: watchActions
class Translations$watchActions$en {
	Translations$watchActions$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: ' (every episode)'
	String get everyEpisode => ' (every episode)';

	/// en: 'Mark as watched{scope}'
	String markWatched({required Object scope}) => 'Mark as watched${scope}';

	/// en: 'Mark as unwatched{scope}'
	String markUnwatched({required Object scope}) => 'Mark as unwatched${scope}';

	/// en: 'Download to this device'
	String get download => 'Download to this device';

	/// en: 'Delete download'
	String get deleteDownload => 'Delete download';

	/// en: 'Cancel download'
	String get cancelDownload => 'Cancel download';

	/// en: 'Remove from favourites'
	String get removeFavourite => 'Remove from favourites';

	/// en: 'Add to favourites'
	String get addFavourite => 'Add to favourites';

	/// en: 'Remove from Continue watching'
	String get removeResume => 'Remove from Continue watching';

	/// en: 'Downloading. See the Downloads tab.'
	String get downloading => 'Downloading. See the Downloads tab.';

	/// en: 'Marked as watched here. Plex will be told when it can be reached.'
	String get markedOffline => 'Marked as watched here. Plex will be told when it can be reached.';

	/// en: 'Plex didn't accept that. The server may be offline.'
	String get plexRefused => 'Plex didn\'t accept that. The server may be offline.';
}

// Path: show
class Translations$show$en {
	Translations$show$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'This show has no episodes on the server.'
	String get noEpisodes => 'This show has no episodes on the server.';
}

// Path: shell
class Translations$shell$en {
	Translations$shell$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Library'
	String get library => 'Library';

	/// en: 'Search'
	String get search => 'Search';

	/// en: 'Downloads'
	String get downloads => 'Downloads';

	/// en: 'Settings'
	String get settings => 'Settings';

	/// en: 'Exit Subnext Player?'
	String get exitTitle => 'Exit Subnext Player?';

	/// en: 'Exit'
	String get exit => 'Exit';

	/// en: 'Stay'
	String get stay => 'Stay';
}

// Path: resume
class Translations$resume$en {
	Translations$resume$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Up next'
	String get upNext => 'Up next';

	/// en: 'Continue watching'
	String get title => 'Continue watching';

	/// en: 'Remove from continue watching'
	String get remove => 'Remove from continue watching';
}

// Path: library
class Translations$library$en {
	Translations$library$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$library$placement$en placement = Translations$library$placement$en.internal(_root);
	late final Translations$library$tab$en tab = Translations$library$tab$en.internal(_root);

	/// en: '{server} did not respond within {seconds} seconds. It may be asleep or off the network.'
	String serverTimeout({required Object server, required Object seconds}) => '${server} did not respond within ${seconds} seconds. It may be asleep or off the network.';

	/// en: 'Everything in Movies is watched.'
	String get allWatched => 'Everything in Movies is watched.';

	/// en: 'Show all'
	String get showAll => 'Show all';

	/// en: 'No sources connected yet.'
	String get noSources => 'No sources connected yet.';

	/// en: 'Nothing in {tab} yet.'
	String nothingIn({required Object tab}) => 'Nothing in ${tab} yet.';

	/// en: 'Add a source'
	String get addSource => 'Add a source';

	/// en: '{sort} · Unwatched'
	String sortFiltered({required Object sort}) => '${sort} · Unwatched';

	/// en: 'Sort by'
	String get sortBy => 'Sort by';

	/// en: 'Unwatched only'
	String get unwatchedOnly => 'Unwatched only';

	late final Translations$library$shelf$en shelf = Translations$library$shelf$en.internal(_root);
	late final Translations$library$sort$en sort = Translations$library$sort$en.internal(_root);
	late final Translations$library$tile$en tile = Translations$library$tile$en.internal(_root);
}

// Path: liveTv
class Translations$liveTv$en {
	Translations$liveTv$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$liveTv$group$en group = Translations$liveTv$group$en.internal(_root);

	/// en: 'No playlist or panel configured.'
	String get noPanel => 'No playlist or panel configured.';

	/// en: 'Add one'
	String get addOne => 'Add one';

	/// en: 'No categories chosen yet. Panels carry tens of thousands of channels, so Subnext Player only fetches the ones you pick.'
	String get noCategories => 'No categories chosen yet.\nPanels carry tens of thousands of channels, so Subnext Player only fetches the ones you pick.';

	/// en: 'Choose categories'
	String get chooseCategories => 'Choose categories';

	/// en: 'Those categories returned no channels.'
	String get noChannels => 'Those categories returned no channels.';

	/// en: 'No channel matching "{query}".'
	String noMatch({required Object query}) => 'No channel matching "${query}".';

	/// en: '(one) {Search {n} channel} (other) {Search {n} channels}'
	String searchHint({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'Search ${n} channel',
		other: 'Search ${n} channels',
	);

	/// en: 'All'
	String get all => 'All';
}

// Path: ai
class Translations$ai$en {
	Translations$ai$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$ai$picks$en picks = Translations$ai$picks$en.internal(_root);
	late final Translations$ai$search$en search = Translations$ai$search$en.internal(_root);

	/// en: 'Other'
	String get presetOther => 'Other';

	/// en: 'Model ids are listed at openrouter.ai/models. Free ones end in ":free".'
	String get hintOpenRouter => 'Model ids are listed at openrouter.ai/models. Free ones end in ":free".';

	/// en: 'Use your computer's address on this network, for example http://192.168.1.20:11434/v1. Nothing leaves your network.'
	String get hintOllama => 'Use your computer\'s address on this network, for example http://192.168.1.20:11434/v1. Nothing leaves your network.';

	/// en: 'Any service that speaks the OpenAI chat format.'
	String get hintCustom => 'Any service that speaks the OpenAI chat format.';

	late final Translations$ai$feature$en feature = Translations$ai$feature$en.internal(_root);
	late final Translations$ai$errors$en errors = Translations$ai$errors$en.internal(_root);

	/// en: 'Send data to {provider}?'
	String consentTitle({required Object provider}) => 'Send data to ${provider}?';

	/// en: '{feature} will send this to {provider}: {sends}'
	String consentBody({required Object feature, required Object provider, required Object sends}) => '${feature} will send this to ${provider}: ${sends}';

	/// en: 'It goes straight from this device to them, never through us. You can switch this off again in Settings, AI features.'
	String get consentTail => 'It goes straight from this device to them, never through us. You can switch this off again in Settings, AI features.';

	/// en: 'Not now'
	String get notNow => 'Not now';

	/// en: 'Allow'
	String get allow => 'Allow';
}

// Path: search
class Translations$search$en {
	Translations$search$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$search$filters$en filters = Translations$search$filters$en.internal(_root);

	/// en: 'Search your sources'
	String get hint => 'Search your sources';

	/// en: 'Search movies and series across your server.'
	String get prompt => 'Search movies and series across your server.';

	/// en: 'Keep typing…'
	String get keepTyping => 'Keep typing…';

	/// en: 'Nothing matching "{query}".'
	String noMatch({required Object query}) => 'Nothing matching "${query}".';

	/// en: 'Back to results'
	String get backToResults => 'Back to results';

	/// en: 'Ask AI'
	String get askAi => 'Ask AI';

	/// en: 'Because you watched '
	String get becauseYouWatched => 'Because you watched ';
}

// Path: settings
class Translations$settings$en {
	Translations$settings$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$settings$about$en about = Translations$settings$about$en.internal(_root);
	late final Translations$settings$privacy$en privacy = Translations$settings$privacy$en.internal(_root);
	late final Translations$settings$playback$en playback = Translations$settings$playback$en.internal(_root);
	late final Translations$settings$metadata$en metadata = Translations$settings$metadata$en.internal(_root);
	late final Translations$settings$ai$en ai = Translations$settings$ai$en.internal(_root);
	late final Translations$settings$appearance$en appearance = Translations$settings$appearance$en.internal(_root);
	late final Translations$settings$section$en section = Translations$settings$section$en.internal(_root);
	late final Translations$settings$advanced$en advanced = Translations$settings$advanced$en.internal(_root);
	late final Translations$settings$sources$en sources = Translations$settings$sources$en.internal(_root);
}

// Path: onboarding
class Translations$onboarding$en {
	Translations$onboarding$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Play from the sources you connect.'
	String get tagline => 'Play from the sources you connect.';

	/// en: 'Subnext Player streams from sources you connect yourself: a Plex server, a home NAS or local files, or optionally an IPTV provider or playlist. We host no content.'
	String get blurb => 'Subnext Player streams from sources you connect yourself: a Plex server, a home NAS or local files, or optionally an IPTV provider or playlist. We host no content.';

	/// en: 'Files on this PC, or a folder on a home NAS or SMB share.'
	String get localDesktop => 'Files on this PC, or a folder on a home NAS or SMB share.';

	/// en: 'A folder on a home NAS or SMB share.'
	String get localTv => 'A folder on a home NAS or SMB share.';

	/// en: 'Video on this device, or a folder on a home NAS or SMB share.'
	String get local => 'Video on this device, or a folder on a home NAS or SMB share.';

	/// en: 'Sign in with your own account on this TV.'
	String get plexTv => 'Sign in with your own account on this TV.';

	/// en: 'Your personal library, signed in with your own account.'
	String get plex => 'Your personal library, signed in with your own account.';

	/// en: 'Off by default. Turn on in Settings.'
	String get advancedTv => 'Off by default. Turn on in Settings.';

	/// en: 'Off by default. Turn on in Settings to use an IPTV provider or playlist.'
	String get advanced => 'Off by default. Turn on in Settings to use an IPTV provider or playlist.';

	/// en: 'Local & Network'
	String get localTitle => 'Local & Network';

	/// en: 'Advanced sources'
	String get advancedTitle => 'Advanced sources';

	/// en: 'Add your first source'
	String get addFirst => 'Add your first source';

	/// en: 'Not now'
	String get notNow => 'Not now';

	/// en: 'Connect a source'
	String get connect => 'Connect a source';

	/// en: 'Add source'
	String get addSource => 'Add source';

	/// en: 'OK'
	String get okKey => 'OK';

	/// en: 'to select'
	String get toSelect => 'to select';
}

// Path: addSource
class Translations$addSource$en {
	Translations$addSource$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Credentials stay on this device. Nothing is sent to us: there is no account and no server in the middle.'
	String get privacy => 'Credentials stay on this device. Nothing is sent to us: there is no account and no server in the middle.';

	late final Translations$addSource$kind$en kind = Translations$addSource$kind$en.internal(_root);

	/// en: 'Copy from another device'
	String get copyFromDevice => 'Copy from another device';

	/// en: 'Already set up on your phone? Send it here instead of typing it again.'
	String get copyFromDeviceSub => 'Already set up on your phone? Send it here instead of typing it again.';

	/// en: 'Add a source'
	String get title => 'Add a source';

	/// en: 'Advanced sources'
	String get advanced => 'Advanced sources';

	/// en: 'Or'
	String get or => 'Or';

	/// en: 'Looking for an IPTV provider or playlist? Turn on '
	String get advancedHintLead => 'Looking for an IPTV provider or playlist? Turn on ';

	/// en: ' in Settings.'
	String get advancedHintTail => ' in Settings.';

	/// en: 'Source type'
	String get sourceType => 'Source type';

	/// en: 'Link with a code'
	String get plexRail => 'Link with a code';

	/// en: 'Files on this PC'
	String get pcFiles => 'Files on this PC';

	/// en: 'Choose a folder'
	String get pcFilesSub => 'Choose a folder';

	/// en: 'NAS or Windows share'
	String get smbRail => 'NAS or Windows share';

	/// en: 'Send it from your phone'
	String get copyRail => 'Send it from your phone';

	/// en: 'Credentials are stored in your device keystore, never in the app database.'
	String get keystore => 'Credentials are stored in your device keystore, never in the app database.';

	/// en: 'Choose a source type to get started.'
	String get pick => 'Choose a source type to get started.';
}

// Path: plex
class Translations$plex$en {
	Translations$plex$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Plex connected.'
	String get connected => 'Plex connected.';

	/// en: 'Connected to {name}.'
	String connectedTo({required Object name}) => 'Connected to ${name}.';

	/// en: 'Connected. Opening your library…'
	String get opening => 'Connected. Opening your library…';

	/// en: 'Connect to Plex'
	String get connect => 'Connect to Plex';

	/// en: 'Subnext Player plays what your own Plex server already holds. Nothing is uploaded, and no account details reach anyone but Plex.'
	String get explain => 'Subnext Player plays what your own Plex server already holds. Nothing is uploaded, and no account details reach anyone but Plex.';

	/// en: 'Contacting Plex…'
	String get contacting => 'Contacting Plex…';

	/// en: 'On any device, open plex.tv/link and enter:'
	String get enterCode => 'On any device, open plex.tv/link and enter:';

	/// en: 'Waiting for approval…'
	String get waiting => 'Waiting for approval…';

	/// en: 'Copy code'
	String get copyCode => 'Copy code';

	/// en: 'Choose a server'
	String get chooseServer => 'Choose a server';

	/// en: 'Every server on this account is already connected.'
	String get allConnected => 'Every server on this account is already connected.';

	/// en: 'Your servers'
	String get yourServers => 'Your servers';

	/// en: 'Shared with you'
	String get sharedWithYou => 'Shared with you';

	/// en: 'Connecting… this can take a few seconds'
	String get connecting => 'Connecting… this can take a few seconds';

	/// en: 'Offline'
	String get offline => 'Offline';

	/// en: 'Plex Relay only, playback may be limited'
	String get relayOnly => 'Plex Relay only, playback may be limited';

	/// en: 'That code expired. Try again.'
	String get codeExpired => 'That code expired. Try again.';

	/// en: 'That account has no Plex servers.'
	String get noServers => 'That account has no Plex servers.';

	late final Translations$plex$errors$en errors = Translations$plex$errors$en.internal(_root);
}

// Path: local
class Translations$local$en {
	Translations$local$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Subnext Player cannot see your videos without media access. You can grant it in {where}.'
	String noAccess({required Object where}) => 'Subnext Player cannot see your videos without media access. You can grant it in ${where}.';

	/// en: 'the Settings app'
	String get settingsIos => 'the Settings app';

	/// en: 'Android settings'
	String get settingsAndroid => 'Android settings';

	/// en: 'Play videos stored on this device. Subnext Player only asks for video access, never full file access.'
	String get intro => 'Play videos stored on this device.\nSubnext Player only asks for video access, never full file access.';

	/// en: 'Allow video access'
	String get allowAccess => 'Allow video access';

	/// en: 'Or pick a folder instead'
	String get pickFolderInstead => 'Or pick a folder instead';

	/// en: 'Add a network share'
	String get addShare => 'Add a network share';

	/// en: 'Network shares'
	String get shares => 'Network shares';

	/// en: 'Folders you picked'
	String get pickedFolders => 'Folders you picked';

	/// en: 'On this device'
	String get onDevice => 'On this device';

	/// en: 'No videos found on this device.'
	String get noVideos => 'No videos found on this device.';

	/// en: 'Add a folder'
	String get addFolderShort => 'Add a folder';

	/// en: 'Add a share'
	String get addShareShort => 'Add a share';

	/// en: 'Scan this device'
	String get scanDevice => 'Scan this device';

	/// en: 'Forget this folder'
	String get forgetFolder => 'Forget this folder';

	/// en: 'Folder'
	String get folder => 'Folder';

	/// en: 'This folder is no longer readable. Android may have dropped the permission, so remove it and pick it again. {error}'
	String safUnreadable({required Object error}) => 'This folder is no longer readable. Android may have dropped the permission, so remove it and pick it again.\n\n${error}';

	/// en: 'No videos or subfolders here.'
	String get safEmpty => 'No videos or subfolders here.';
}

// Path: smb
class Translations$smb$en {
	Translations$smb$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Could not connect: {error}'
	String connectFailed({required Object error}) => 'Could not connect: ${error}';

	/// en: 'Add a network share'
	String get title => 'Add a network share';

	/// en: 'A NAS or a shared folder on another computer on your network.'
	String get explain => 'A NAS or a shared folder on another computer on your network.';

	/// en: 'Server address'
	String get host => 'Server address';

	/// en: 'e.g. nas'
	String get hostHint => 'e.g. nas';

	/// en: 'Username'
	String get username => 'Username';

	/// en: 'Password'
	String get password => 'Password';

	/// en: 'Domain (optional)'
	String get domain => 'Domain (optional)';

	/// en: 'Name (optional)'
	String get name => 'Name (optional)';

	/// en: 'Connect and add'
	String get connectAndAdd => 'Connect and add';

	/// en: 'That share is no longer configured.'
	String get gone => 'That share is no longer configured.';

	/// en: 'Could not reach this share. The server may be asleep or off the network. {error}'
	String unreachable({required Object error}) => 'Could not reach this share. The server may be asleep or off the network.\n\n${error}';

	/// en: 'No videos or folders here.'
	String get empty => 'No videos or folders here.';
}

// Path: xtream
class Translations$xtream$en {
	Translations$xtream$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'That line is no longer configured.'
	String get lineGone => 'That line is no longer configured.';

	late final Translations$xtream$catalogue$en catalogue = Translations$xtream$catalogue$en.internal(_root);
	late final Translations$xtream$errors$en errors = Translations$xtream$errors$en.internal(_root);

	/// en: 'Everything else'
	String get everythingElse => 'Everything else';

	late final Translations$xtream$series$en series = Translations$xtream$series$en.internal(_root);

	/// en: 'Remove'
	String get remove => 'Remove';

	/// en: 'Add a playlist or panel'
	String get add => 'Add a playlist or panel';

	late final Translations$xtream$addLine$en addLine = Translations$xtream$addLine$en.internal(_root);
	late final Translations$xtream$picker$en picker = Translations$xtream$picker$en.internal(_root);
	late final Translations$xtream$channels$en channels = Translations$xtream$channels$en.internal(_root);
	late final Translations$xtream$hidden$en hidden = Translations$xtream$hidden$en.internal(_root);
}

// Path: transfer
class Translations$transfer$en {
	Translations$transfer$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'This device is not on a Wi-Fi or Ethernet network. Connect it to the same network as the other device and try again.'
	String get noNetwork => 'This device is not on a Wi-Fi or Ethernet network. Connect it to the same network as the other device and try again.';

	/// en: 'Could not start listening: {error}'
	String cannotListen({required Object error}) => 'Could not start listening: ${error}';

	/// en: 'That code has expired. Start again for a new one.'
	String get expired => 'That code has expired. Start again for a new one.';

	/// en: 'Something went wrong: {error}'
	String wentWrong({required Object error}) => 'Something went wrong: ${error}';

	/// en: 'Something went wrong.'
	String get wentWrongPlain => 'Something went wrong.';

	/// en: 'Getting ready…'
	String get gettingReady => 'Getting ready…';

	/// en: 'Waiting for the other device…'
	String get waitingOther => 'Waiting for the other device…';

	/// en: 'Copy code'
	String get copyCode => 'Copy code';

	/// en: 'Scan its code instead'
	String get scanInstead => 'Scan its code instead';

	/// en: 'Type its code instead'
	String get typeInstead => 'Type its code instead';

	/// en: 'Done'
	String get done => 'Done';

	/// en: 'Close'
	String get close => 'Close';

	late final Translations$transfer$receive$en receive = Translations$transfer$receive$en.internal(_root);
	late final Translations$transfer$pairing$en pairing = Translations$transfer$pairing$en.internal(_root);
	late final Translations$transfer$pane$en pane = Translations$transfer$pane$en.internal(_root);
	late final Translations$transfer$notes$en notes = Translations$transfer$notes$en.internal(_root);
	late final Translations$transfer$send$en send = Translations$transfer$send$en.internal(_root);
	late final Translations$transfer$item$en item = Translations$transfer$item$en.internal(_root);
	late final Translations$transfer$client$en client = Translations$transfer$client$en.internal(_root);
}

// Path: downloads.errors
class Translations$downloads$errors$en {
	Translations$downloads$errors$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'That server is not connected. Reconnect it in Settings, then resume.'
	String get serverNotConnected => 'That server is not connected. Reconnect it in Settings, then resume.';

	/// en: 'The file did not match the size the server reported. Try again.'
	String get sizeMismatch => 'The file did not match the size the server reported. Try again.';

	/// en: 'Could not write the file. The device may be out of space.'
	String get cannotWrite => 'Could not write the file. The device may be out of space.';

	/// en: 'The file changed on the server. Start the download again.'
	String get changedOnServer => 'The file changed on the server. Start the download again.';

	/// en: 'The server would not let this device download that.'
	String get refused => 'The server would not let this device download that.';

	/// en: 'The server answered {code}.'
	String status({required Object code}) => 'The server answered ${code}.';

	/// en: 'The connection dropped part-way. Resume to continue.'
	String get dropped => 'The connection dropped part-way. Resume to continue.';

	/// en: 'Could not reach the server. Check the connection and resume.'
	String get unreachable => 'Could not reach the server. Check the connection and resume.';

	/// en: 'The server took too long to answer.'
	String get timeout => 'The server took too long to answer.';
}

// Path: downloads.rule
class Translations$downloads$rule$en {
	Translations$downloads$rule$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Keep episodes downloaded'
	String get off => 'Keep episodes downloaded';

	/// en: '(one) {Keeping the next episode downloaded} (other) {Keeping the next {n} episodes downloaded}'
	String keeping({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'Keeping the next episode downloaded',
		other: 'Keeping the next ${n} episodes downloaded',
	);

	/// en: 'Downloads the next unwatched episodes and replaces them as you watch, while the app is open. Watched ones it downloaded are removed.'
	String get explain => 'Downloads the next unwatched episodes and replaces them as you watch, while the app is open. Watched ones it downloaded are removed.';

	/// en: 'Off'
	String get choiceOff => 'Off';

	/// en: '(one) {Next episode} (other) {Next {n} episodes}'
	String choice({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'Next episode',
		other: 'Next ${n} episodes',
	);
}

// Path: library.placement
class Translations$library$placement$en {
	Translations$library$placement$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Movies'
	String get movies => 'Movies';

	/// en: 'Series'
	String get series => 'Series';

	/// en: 'Hidden'
	String get hidden => 'Hidden';
}

// Path: library.tab
class Translations$library$tab$en {
	Translations$library$tab$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Movies'
	String get movies => 'Movies';

	/// en: 'Series'
	String get series => 'Series';

	/// en: 'Local & Network'
	String get localNetwork => 'Local & Network';

	/// en: 'Live TV'
	String get liveTv => 'Live TV';

	/// en: 'No movies on this server.'
	String get emptyMovies => 'No movies on this server.';

	/// en: 'No series on this server.'
	String get emptySeries => 'No series on this server.';

	/// en: 'No folders or network shares yet. Device storage and SMB shares are not connectable in this build.'
	String get emptyLocalNetwork => 'No folders or network shares yet.\nDevice storage and SMB shares are not connectable in this build.';

	/// en: 'No playlist or panel configured. Add one from Settings once Advanced sources is on.'
	String get emptyLiveTv => 'No playlist or panel configured.\nAdd one from Settings once Advanced sources is on.';

	/// en: '(one) {{n} movie} (other) {{n} movies}'
	String countMovies({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} movie',
		other: '${n} movies',
	);

	/// en: '(one) {{n} series} (other) {{n} series}'
	String countSeries({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} series',
		other: '${n} series',
	);

	/// en: '(one) {{n} item} (other) {{n} items}'
	String countItems({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} item',
		other: '${n} items',
	);

	/// en: '(one) {{n} channel} (other) {{n} channels}'
	String countChannels({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} channel',
		other: '${n} channels',
	);
}

// Path: library.shelf
class Translations$library$shelf$en {
	Translations$library$shelf$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'See all'
	String get seeAll => 'See all';

	/// en: '(one) {{n} title} (other) {{n} titles}'
	String titles({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} title',
		other: '${n} titles',
	);

	/// en: 'Nothing here any more.'
	String get gone => 'Nothing here any more.';
}

// Path: library.sort
class Translations$library$sort$en {
	Translations$library$sort$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Title'
	String get title => 'Title';

	/// en: 'Recently added'
	String get recentlyAdded => 'Recently added';

	/// en: 'Year'
	String get year => 'Year';

	/// en: 'Release date'
	String get releaseDate => 'Release date';
}

// Path: library.tile
class Translations$library$tile$en {
	Translations$library$tile$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Series'
	String get series => 'Series';

	/// en: 'Movie'
	String get movie => 'Movie';

	/// en: 'Watched'
	String get watched => 'Watched';

	/// en: '{percent}% watched'
	String percentWatched({required Object percent}) => '${percent}% watched';
}

// Path: liveTv.group
class Translations$liveTv$group$en {
	Translations$liveTv$group$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Favourites'
	String get favourites => 'Favourites';

	/// en: 'Category {n}'
	String numbered({required Object n}) => 'Category ${n}';

	/// en: 'Other'
	String get other => 'Other';
}

// Path: ai.picks
class Translations$ai$picks$en {
	Translations$ai$picks$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'your provider'
	String get yourProvider => 'your provider';

	/// en: 'What should I watch?'
	String get ask => 'What should I watch?';

	/// en: 'Ask {provider} to pick from your own library.'
	String askExplain({required Object provider}) => 'Ask ${provider} to pick from your own library.';

	/// en: 'Picked for you by '
	String get pickedBy => 'Picked for you by ';

	/// en: 'Updating'
	String get updating => 'Updating';

	/// en: 'Again'
	String get again => 'Again';

	/// en: 'Getting your picks ready...'
	String get preparing => 'Getting your picks ready...';
}

// Path: ai.search
class Translations$ai$search$en {
	Translations$ai$search$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Asking {provider}...'
	String asking({required Object provider}) => 'Asking ${provider}...';

	/// en: 'Searching your library... {searched} of {covered} titles'
	String searching({required Object searched, required Object covered}) => 'Searching your library... ${searched} of ${covered} titles';

	/// en: 'There is nothing in your library to search yet.'
	String get emptyLibrary => 'There is nothing in your library to search yet.';

	/// en: 'The model did not find anything in {total} titles that fits that. Try describing it differently.'
	String notFound({required Object total}) => 'The model did not find anything in ${total} titles that fits that. Try describing it differently.';

	/// en: 'The model did not find anything in the first {covered} of {total} titles that fits that. Try describing it differently.'
	String notFoundFirst({required Object covered, required Object total}) => 'The model did not find anything in the first ${covered} of ${total} titles that fits that. Try describing it differently.';

	/// en: 'Still searching: {searched} of {covered} titles'
	String stillSearching({required Object searched, required Object covered}) => 'Still searching: ${searched} of ${covered} titles';

	/// en: 'Searched the first {covered} of {total} titles'
	String searchedFirst({required Object covered, required Object total}) => 'Searched the first ${covered} of ${total} titles';

	/// en: 'Picked by {provider} for "{query}"'
	String pickedFor({required Object provider, required Object query}) => 'Picked by ${provider} for "${query}"';

	/// en: 'Search again'
	String get searchAgain => 'Search again';

	/// en: '{failed} of {parts} parts could not be searched, so some of your library was not looked at. The provider may be limiting requests'
	String partsFailed({required Object failed, required Object parts}) => '${failed} of ${parts} parts could not be searched, so some of your library was not looked at. The provider may be limiting requests';
}

// Path: ai.feature
class Translations$ai$feature$en {
	Translations$ai$feature$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Natural-language search'
	String get naturalSearch => 'Natural-language search';

	/// en: 'Your search text, and the titles and years in your library.'
	String get naturalSearchSends => 'Your search text, and the titles and years in your library.';

	/// en: 'A large library is sent in several requests of a few hundred titles each, so a search makes more than one.'
	String get naturalSearchTiming => 'A large library is sent in several requests of a few hundred titles each, so a search makes more than one.';

	/// en: 'Recommendations'
	String get recommendations => 'Recommendations';

	/// en: 'The films you watched recently, and the titles and years of what you have not watched yet in your library.'
	String get recommendationsSends => 'The films you watched recently, and the titles and years of what you have not watched yet in your library.';

	/// en: 'Picks are prepared in the background shortly after the app opens, but only when what you watched has changed or they are over a day old, so it is not a request on every launch.'
	String get recommendationsTiming => 'Picks are prepared in the background shortly after the app opens, but only when what you watched has changed or they are over a day old, so it is not a request on every launch.';
}

// Path: ai.errors
class Translations$ai$errors$en {
	Translations$ai$errors$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'The model ran out of reply space while thinking and never gave an answer. A model that does not "think" first will work better.'
	String get ranOutThinking => 'The model ran out of reply space while thinking and never gave an answer. A model that does not "think" first will work better.';

	/// en: 'The model sent back an empty answer.'
	String get empty => 'The model sent back an empty answer.';

	/// en: 'The provider rejected that key{suffix}.'
	String rejectedKey({required Object suffix}) => 'The provider rejected that key${suffix}.';

	/// en: 'The provider says this account is out of credit{suffix}.'
	String noCredit({required Object suffix}) => 'The provider says this account is out of credit${suffix}.';

	/// en: 'The provider does not know that model or address{suffix}.'
	String unknownModel({required Object suffix}) => 'The provider does not know that model or address${suffix}.';

	/// en: 'The provider is rate limiting this key. Try again shortly{suffix}.'
	String rateLimited({required Object suffix}) => 'The provider is rate limiting this key. Try again shortly${suffix}.';

	/// en: 'The provider had a problem (HTTP {status}){suffix}.'
	String serverError({required Object status, required Object suffix}) => 'The provider had a problem (HTTP ${status})${suffix}.';

	/// en: 'The provider took too long to answer.'
	String get timeout => 'The provider took too long to answer.';

	/// en: 'Could not reach the provider. Check the address.'
	String get unreachable => 'Could not reach the provider. Check the address.';

	/// en: 'The request failed{suffix}.'
	String failed({required Object suffix}) => 'The request failed${suffix}.';

	/// en: 'The request failed (HTTP {status}){suffix}.'
	String failedStatus({required Object status, required Object suffix}) => 'The request failed (HTTP ${status})${suffix}.';

	/// en: 'Fill in the address and the model.'
	String get fillIn => 'Fill in the address and the model.';

	/// en: 'This provider needs an API key.'
	String get needsKey => 'This provider needs an API key.';

	/// en: 'No AI provider is set up.'
	String get notSetUp => 'No AI provider is set up.';

	/// en: 'Natural-language search is switched off for this provider.'
	String get searchOff => 'Natural-language search is switched off for this provider.';

	/// en: 'The search failed.'
	String get searchFailed => 'The search failed.';

	/// en: 'Watch a film first, so there is something to base picks on.'
	String get noSignal => 'Watch a film first, so there is something to base picks on.';

	/// en: 'The model did not pick anything this time.'
	String get noPicks => 'The model did not pick anything this time.';
}

// Path: search.filters
class Translations$search$filters$en {
	Translations$search$filters$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: '{decade}s and earlier'
	String decadeOldest({required Object decade}) => '${decade}s and earlier';

	/// en: '{decade}s'
	String decade({required Object decade}) => '${decade}s';

	/// en: 'Type'
	String get type => 'Type';

	/// en: 'Movies'
	String get movies => 'Movies';

	/// en: 'Series'
	String get series => 'Series';

	/// en: 'Source'
	String get source => 'Source';

	/// en: 'Unknown source'
	String get unknownSource => 'Unknown source';

	/// en: 'Year'
	String get year => 'Year';

	/// en: 'Language'
	String get language => 'Language';

	/// en: 'Guessed from IPTV category names. Plex titles have no language here.'
	String get languageNote => 'Guessed from IPTV category names. Plex titles have no language here.';

	/// en: 'Genre'
	String get genre => 'Genre';

	/// en: 'Rating'
	String get rating => 'Rating';

	/// en: 'TMDB user rating out of 10. Titles TMDB has no rating for are left out.'
	String get ratingNote => 'TMDB user rating out of 10. Titles TMDB has no rating for are left out.';

	/// en: 'Original language'
	String get originalLanguage => 'Original language';

	/// en: 'The language the title was made in, from TMDB. A dubbed copy keeps its original language here.'
	String get originalLanguageNote => 'The language the title was made in, from TMDB. A dubbed copy keeps its original language here.';

	/// en: 'Clear'
	String get clear => 'Clear';

	/// en: 'Nothing matches those filters.'
	String get noMatches => 'Nothing matches those filters.';

	/// en: 'Clear filters'
	String get clearAll => 'Clear filters';

	/// en: '{label}: {value}'
	String chip({required Object label, required Object value}) => '${label}: ${value}';

	/// en: 'Any'
	String get any => 'Any';
}

// Path: settings.about
class Translations$settings$about$en {
	Translations$settings$about$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Version …'
	String get versionLoading => 'Version …';

	/// en: 'Version {version} ({build})'
	String version({required Object version, required Object build}) => 'Version ${version} (${build})';

	/// en: 'Privacy policy'
	String get privacyPolicy => 'Privacy policy';

	/// en: 'No account, no backend and no analytics. The full policy is at:'
	String get privacySummary => 'No account, no backend and no analytics. The full policy is at:';

	/// en: 'Open-source licences'
	String get licences => 'Open-source licences';
}

// Path: settings.privacy
class Translations$settings$privacy$en {
	Translations$settings$privacy$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Subnext Player has no backend and no analytics. What it keeps lives on this device, and the only places data is sent are the sources, TMDB and AI provider you connect yourself.'
	String get summary => 'Subnext Player has no backend and no analytics. What it keeps lives on this device, and the only places data is sent are the sources, TMDB and AI provider you connect yourself.';

	/// en: 'Cached data'
	String get cachedData => 'Cached data';

	/// en: 'Your library lists, TMDB lookups and AI picks are kept so the app opens quickly. Old ones clear themselves, after 30 days for a library and 90 for a lookup, and a source's entry goes when you remove the source. Clearing now leaves your sources, keys, settings and watch history alone, and everything is fetched again when needed.'
	String get cachedExplain => 'Your library lists, TMDB lookups and AI picks are kept so the app opens quickly. Old ones clear themselves, after 30 days for a library and 90 for a lookup, and a source\'s entry goes when you remove the source. Clearing now leaves your sources, keys, settings and watch history alone, and everything is fetched again when needed.';

	/// en: 'Clearing...'
	String get clearing => 'Clearing...';

	/// en: 'Clear cached data'
	String get clear => 'Clear cached data';

	/// en: 'Cleared. Your library is loading again.'
	String get cleared => 'Cleared. Your library is loading again.';
}

// Path: settings.playback
class Translations$settings$playback$en {
	Translations$settings$playback$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Skip back and forward'
	String get skip => 'Skip back and forward';

	/// en: 'The skip buttons, the fast-forward and rewind keys on a remote, and the first step when moving along the seek bar.'
	String get skipExplain => 'The skip buttons, the fast-forward and rewind keys on a remote, and the first step when moving along the seek bar.';

	/// en: 'Preferred audio language'
	String get audioLanguage => 'Preferred audio language';

	/// en: 'Used when a file has more than one audio track. Otherwise the file's own default plays.'
	String get audioLanguageExplain => 'Used when a file has more than one audio track. Otherwise the file\'s own default plays.';

	/// en: 'File's default'
	String get fileDefault => 'File\'s default';

	/// en: 'Show subtitles'
	String get showSubtitles => 'Show subtitles';

	/// en: 'Turn them on when a file has them. You can always switch in the player.'
	String get showSubtitlesExplain => 'Turn them on when a file has them. You can always switch in the player.';

	/// en: 'Preferred subtitle language'
	String get subtitleLanguage => 'Preferred subtitle language';

	/// en: 'If a file has no subtitles in this language, none are shown.'
	String get subtitleLanguageExplain => 'If a file has no subtitles in this language, none are shown.';

	/// en: 'Any'
	String get any => 'Any';

	/// en: 'Size'
	String get size => 'Size';

	/// en: 'For text subtitles, such as SRT and ASS.'
	String get sizeExplain => 'For text subtitles, such as SRT and ASS.';
}

// Path: settings.metadata
class Translations$settings$metadata$en {
	Translations$settings$metadata$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'This looks up the release date of every film and series in your library on TMDB, in the background, a few at a time. To do that it sends the title (and the year, when there is one) of each of them from this device to TMDB, and to no one else, not only the ones you search for. It also fills in genre and rating for the filters. Results are kept on this device for 90 days, and titles already looked up are not asked again. You can switch it off at any time. Removing your TMDB key switches it off too.'
	String get consent => 'This looks up the release date of every film and series in your library on TMDB, in the background, a few at a time. To do that it sends the title (and the year, when there is one) of each of them from this device to TMDB, and to no one else, not only the ones you search for. It also fills in genre and rating for the filters. Results are kept on this device for 90 days, and titles already looked up are not asked again.\n\nYou can switch it off at any time. Removing your TMDB key switches it off too.';

	/// en: 'Send your library titles to TMDB?'
	String get consentTitle => 'Send your library titles to TMDB?';

	/// en: 'Not now'
	String get notNow => 'Not now';

	/// en: 'Look them up'
	String get lookThemUp => 'Look them up';

	/// en: 'Waiting for your library to load.'
	String get waiting => 'Waiting for your library to load.';

	/// en: 'Paused: TMDB stopped answering. It carries on the next time the app opens, and what it found is kept.'
	String get stopped => 'Paused: TMDB stopped answering. It carries on the next time the app opens, and what it found is kept.';

	/// en: 'Looked up {settled} of {total} titles.'
	String running({required Object settled, required Object total}) => 'Looked up ${settled} of ${total} titles.';

	/// en: 'Looked up {settled} of {total} titles. The rest carry on the next time the app opens.'
	String partial({required Object settled, required Object total}) => 'Looked up ${settled} of ${total} titles. The rest carry on the next time the app opens.';

	/// en: 'Done: {found} release dates found for {total} titles.'
	String done({required Object found, required Object total}) => 'Done: ${found} release dates found for ${total} titles.';

	/// en: 'Release dates for your library'
	String get releaseDates => 'Release dates for your library';

	/// en: 'Adds exact release dates in the background, so Sort by Release date can order your library properly, including titles with no year. Sends every title in your library to TMDB.'
	String get releaseDatesExplain => 'Adds exact release dates in the background, so Sort by Release date can order your library properly, including titles with no year. Sends every title in your library to TMDB.';

	/// en: 'Connect your own TMDB key to add genre, rating and original language to search results, and suggestions based on what you have watched. It is optional, and nothing changes until you add one.'
	String get intro => 'Connect your own TMDB key to add genre, rating and original language to search results, and suggestions based on what you have watched. It is optional, and nothing changes until you add one.';

	/// en: 'The titles being looked up are sent from this device to TMDB, and to no one else. Create a free key in your TMDB account under Settings, API. Either the short key or the long Read Access Token works. On a TV it is easier to paste or type this on a phone or computer first.'
	String get keyExplain => 'The titles being looked up are sent from this device to TMDB, and to no one else. Create a free key in your TMDB account under Settings, API. Either the short key or the long Read Access Token works. On a TV it is easier to paste or type this on a phone or computer first.';

	/// en: 'TMDB key saved'
	String get keySaved => 'TMDB key saved';

	/// en: 'Remove key'
	String get removeKey => 'Remove key';

	/// en: 'TMDB API key'
	String get keyLabel => 'TMDB API key';

	/// en: 'Checking...'
	String get checking => 'Checking...';

	/// en: 'Verify and save'
	String get verify => 'Verify and save';

	late final Translations$settings$metadata$errors$en errors = Translations$settings$metadata$errors$en.internal(_root);
}

// Path: settings.ai
class Translations$settings$ai$en {
	Translations$settings$ai$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Connect your own provider and your own key. Requests go straight from this device to the provider you chose, never through us, because there is no server of ours in between. Nothing is sent until you allow a feature below.'
	String get intro => 'Connect your own provider and your own key. Requests go straight from this device to the provider you chose, never through us, because there is no server of ours in between. Nothing is sent until you allow a feature below.';

	/// en: 'Address'
	String get address => 'Address';

	/// en: 'Model'
	String get model => 'Model';

	/// en: 'API key (optional for a local server)'
	String get keyOptional => 'API key (optional for a local server)';

	/// en: 'API key'
	String get key => 'API key';

	/// en: 'Trying it...'
	String get trying => 'Trying it...';

	/// en: 'Test and save'
	String get testAndSave => 'Test and save';

	/// en: 'On your network'
	String get onNetwork => 'On your network';

	/// en: 'Key saved'
	String get keySaved => 'Key saved';

	/// en: 'Remove provider'
	String get remove => 'Remove provider';

	/// en: 'What it may send'
	String get maySend => 'What it may send';

	/// en: 'This provider is on your own network, so nothing reaches a third party and no consent is needed.'
	String get localNoConsent => 'This provider is on your own network, so nothing reaches a third party and no consent is needed.';

	/// en: 'Sends to {provider}: {sends}'
	String sendsTo({required Object provider, required Object sends}) => 'Sends to ${provider}: ${sends}';

	/// en: 'Allowed on {date}'
	String allowedOn({required Object date}) => 'Allowed on ${date}';

	/// en: 'Not allowed yet. You will be asked the first time.'
	String get notAllowed => 'Not allowed yet. You will be asked the first time.';

	/// en: 'Switch off'
	String get switchOff => 'Switch off';

	/// en: 'Allow'
	String get allow => 'Allow';
}

// Path: settings.appearance
class Translations$settings$appearance$en {
	Translations$settings$appearance$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$settings$appearance$palette$en palette = Translations$settings$appearance$palette$en.internal(_root);

	/// en: 'Theme'
	String get theme => 'Theme';

	/// en: 'Accent'
	String get accent => 'Accent';
}

// Path: settings.section
class Translations$settings$section$en {
	Translations$settings$section$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Sources'
	String get sources => 'Sources';

	/// en: 'Appearance'
	String get appearance => 'Appearance';

	/// en: 'Playback'
	String get playback => 'Playback';

	/// en: 'Subtitles'
	String get subtitles => 'Subtitles';

	/// en: 'Metadata'
	String get metadata => 'Metadata';

	/// en: 'AI features'
	String get aiFeatures => 'AI features';

	/// en: 'Advanced sources'
	String get advancedSources => 'Advanced sources';

	/// en: 'Move to another device'
	String get transfer => 'Move to another device';

	/// en: 'Privacy and data'
	String get privacy => 'Privacy and data';

	/// en: 'About'
	String get about => 'About';
}

// Path: settings.advanced
class Translations$settings$advanced$en {
	Translations$settings$advanced$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Turning on advanced sources'
	String get dialogTitle => 'Turning on advanced sources';

	/// en: 'You are about to connect a third-party provider using your own credentials.'
	String get dialogLead => 'You are about to connect a third-party provider using your own credentials.';

	/// en: 'Subnext Player does not provide, host, or endorse any content or provider. You supply the address and the login, and the app plays whatever that address returns.'
	String get dialogNoContent => 'Subnext Player does not provide, host, or endorse any content or provider. You supply the address and the login, and the app plays whatever that address returns.';

	/// en: 'You are responsible for holding the rights to whatever you connect to.'
	String get dialogRights => 'You are responsible for holding the rights to whatever you connect to.';

	/// en: 'I understand, turn on'
	String get dialogConfirm => 'I understand, turn on';

	/// en: 'IPTV provider or playlist'
	String get toggle => 'IPTV provider or playlist';

	/// en: 'Adds Live TV and Xtream Codes logins.'
	String get toggleExplain => 'Adds Live TV and Xtream Codes logins.';

	/// en: 'Turning this off later hides Live TV but keeps any accounts you added.'
	String get offKeeps => 'Turning this off later hides Live TV but keeps any accounts you added.';
}

// Path: settings.sources
class Translations$settings$sources$en {
	Translations$settings$sources$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'No Plex servers connected.'
	String get noServers => 'No Plex servers connected.';

	/// en: 'Remove'
	String get remove => 'Remove';

	/// en: 'Could not load libraries from this server. {error}'
	String loadFailed({required Object error}) => 'Could not load libraries from this server.\n\n${error}';

	/// en: 'Look for more servers'
	String get lookForMore => 'Look for more servers';

	/// en: 'Add another server'
	String get addAnother => 'Add another server';

	/// en: 'Yours'
	String get yours => 'Yours';

	/// en: 'Shared with you'
	String get shared => 'Shared with you';

	/// en: 'via relay'
	String get viaRelay => 'via relay';

	/// en: 'Plex type: {type}'
	String plexType({required Object type}) => 'Plex type: ${type}';

	/// en: 'changed by you'
	String get changedByYou => 'changed by you';
}

// Path: addSource.kind
class Translations$addSource$kind$en {
	Translations$addSource$kind$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Plex server'
	String get plex => 'Plex server';

	/// en: 'Link with code'
	String get plexShort => 'Link with code';

	/// en: 'Approve this device in your browser. Your own server plus anything shared with you.'
	String get plexLong => 'Approve this device in your browser. Your own server plus anything shared with you.';

	/// en: 'Video on this device'
	String get localFiles => 'Video on this device';

	/// en: 'Scan your media library, or pick a single folder to keep access to.'
	String get localFilesSub => 'Scan your media library, or pick a single folder to keep access to.';

	/// en: 'Play the videos in your photo library.'
	String get localFilesIos => 'Play the videos in your photo library.';

	/// en: 'Network share (SMB)'
	String get smb => 'Network share (SMB)';

	/// en: 'A NAS or Windows share on your home network.'
	String get smbSub => 'A NAS or Windows share on your home network.';

	/// en: 'Xtream Codes login'
	String get xtream => 'Xtream Codes login';

	/// en: 'Host, username and password from your provider.'
	String get xtreamSub => 'Host, username and password from your provider.';
}

// Path: plex.errors
class Translations$plex$errors$en {
	Translations$plex$errors$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: '"{server}" did not answer on any of its {count} advertised addresses.'
	String noAnswer({required Object server, required Object count}) => '"${server}" did not answer on any of its ${count} advertised addresses.';

	/// en: 'That item is no longer on the server.'
	String get itemGone => 'That item is no longer on the server.';

	/// en: 'No playable file on this item. Transcode-only sources are not supported yet.'
	String get noFile => 'No playable file on this item. Transcode-only sources are not supported yet.';

	/// en: 'Not connected to a Plex server.'
	String get notConnected => 'Not connected to a Plex server.';
}

// Path: xtream.catalogue
class Translations$xtream$catalogue$en {
	Translations$xtream$catalogue$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Live TV'
	String get live => 'Live TV';

	/// en: 'Movies'
	String get vod => 'Movies';

	/// en: 'Series'
	String get series => 'Series';
}

// Path: xtream.errors
class Translations$xtream$errors$en {
	Translations$xtream$errors$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'The panel returned {code}. Try again later.'
	String status({required Object code}) => 'The panel returned ${code}. Try again later.';

	/// en: 'The panel did not respond in time.'
	String get timeout => 'The panel did not respond in time.';

	/// en: 'Could not reach that address. Check the host and port.'
	String get unreachable => 'Could not reach that address. Check the host and port.';

	/// en: 'Could not talk to the panel ({type}).'
	String other({required Object type}) => 'Could not talk to the panel (${type}).';

	/// en: 'That address did not answer like an Xtream panel.'
	String get notXtream => 'That address did not answer like an Xtream panel.';

	/// en: 'The panel rejected those credentials.'
	String get rejected => 'The panel rejected those credentials.';

	/// en: 'Wrong username or password.'
	String get wrongLogin => 'Wrong username or password.';

	/// en: 'Unnamed'
	String get unnamed => 'Unnamed';

	/// en: 'Episode'
	String get episode => 'Episode';

	/// en: 'That line has no stored password. Remove it and add it again.'
	String get noPassword => 'That line has no stored password. Remove it and add it again.';
}

// Path: xtream.series
class Translations$xtream$series$en {
	Translations$xtream$series$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Series'
	String get title => 'Series';

	/// en: 'The panel returned no episodes for this series.'
	String get noEpisodes => 'The panel returned no episodes for this series.';

	/// en: 'Season {n}'
	String season({required Object n}) => 'Season ${n}';
}

// Path: xtream.addLine
class Translations$xtream$addLine$en {
	Translations$xtream$addLine$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Discard this line?'
	String get discardTitle => 'Discard this line?';

	/// en: 'What you typed here has not been saved.'
	String get discardBody => 'What you typed here has not been saved.';

	/// en: 'Discard'
	String get discard => 'Discard';

	/// en: 'Keep editing'
	String get keepEditing => 'Keep editing';

	/// en: 'The panel says this line is "{status}".'
	String inactive({required Object status}) => 'The panel says this line is "${status}".';

	/// en: 'Subnext Player does not provide, host, or endorse any content or provider. You supply the address and the login, and the app plays whatever that address returns.'
	String get noContent => 'Subnext Player does not provide, host, or endorse any content or provider. You supply the address and the login, and the app plays whatever that address returns.';

	/// en: 'Server address'
	String get host => 'Server address';

	/// en: 'Name (optional)'
	String get name => 'Name (optional)';

	/// en: 'What you want to call this line'
	String get nameHint => 'What you want to call this line';

	/// en: 'Checking…'
	String get checking => 'Checking…';

	/// en: 'Verify and add'
	String get verify => 'Verify and add';

	/// en: '(one) {Connected. {n} concurrent stream allowed.} (other) {Connected. {n} concurrent streams allowed.}'
	String connected({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'Connected. ${n} concurrent stream allowed.',
		other: 'Connected. ${n} concurrent streams allowed.',
	);
}

// Path: xtream.picker
class Translations$xtream$picker$en {
	Translations$xtream$picker$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'That pattern matched nothing.'
	String get patternNone => 'That pattern matched nothing.';

	/// en: '{catalogue} categories'
	String title({required Object catalogue}) => '${catalogue} categories';

	/// en: 'Save'
	String get save => 'Save';

	/// en: 'Nothing matches "{query}".'
	String noMatch({required Object query}) => 'Nothing matches "${query}".';

	/// en: 'Nothing chosen yet.'
	String get noneChosen => 'Nothing chosen yet.';

	/// en: 'Search all categories'
	String get search => 'Search all categories';

	/// en: 'Chosen {n}'
	String chosen({required Object n}) => 'Chosen ${n}';

	/// en: 'Hide words'
	String get hideWords => 'Hide words';

	/// en: 'Hide {n}'
	String hideCount({required Object n}) => 'Hide ${n}';

	/// en: 'Pattern'
	String get pattern => 'Pattern';

	/// en: 'Un-ticked "{name}", which "{word}" hides. Save to keep that.'
	String untickedOne({required Object name, required Object word}) => 'Un-ticked "${name}", which "${word}" hides. Save to keep that.';

	/// en: 'Un-ticked {n} chosen categories that "{word}" hides. Save to keep that.'
	String untickedMany({required Object n, required Object word}) => 'Un-ticked ${n} chosen categories that "${word}" hides. Save to keep that.';

	/// en: 'Showing the categories your hidden words leave out.'
	String get showingHidden => 'Showing the categories your hidden words leave out.';

	/// en: '{n} hidden by your words.'
	String hiddenCount({required Object n}) => '${n} hidden by your words.';

	/// en: 'Hide again'
	String get hideAgain => 'Hide again';

	/// en: 'Show them'
	String get showThem => 'Show them';

	/// en: 'Select or clear every category matching a word or pattern'
	String get patternHint => 'Select or clear every category matching a word or pattern';

	/// en: 'Select matching'
	String get selectMatching => 'Select matching';

	/// en: 'Deselect matching'
	String get deselectMatching => 'Deselect matching';

	/// en: 'Groups'
	String get groups => 'Groups';

	/// en: 'Clear all'
	String get clearAll => 'Clear all';

	/// en: 'Select all'
	String get selectAll => 'Select all';

	/// en: '(one) {{n} channel} (other) {{n} channels}'
	String channelsPicked({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} channel',
		other: '${n} channels',
	);

	/// en: '{n} chosen'
	String pickedChosen({required Object n}) => '${n} chosen';

	/// en: '(one) {{n} category} (other) {{n} categories}'
	String categories({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} category',
		other: '${n} categories',
	);

	/// en: 'Channels'
	String get channels => 'Channels';
}

// Path: xtream.channels
class Translations$xtream$channels$en {
	Translations$xtream$channels$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Done'
	String get done => 'Done';

	/// en: 'Search this category'
	String get search => 'Search this category';

	/// en: '{picked} of {total}'
	String pickedOf({required Object picked, required Object total}) => '${picked} of ${total}';

	/// en: 'Whole category'
	String get whole => 'Whole category';

	/// en: 'Select shown'
	String get selectShown => 'Select shown';

	/// en: 'Clear'
	String get clear => 'Clear';

	/// en: 'Clear shown'
	String get clearShown => 'Clear shown';

	/// en: 'The panel lists no channels in this category.'
	String get none => 'The panel lists no channels in this category.';
}

// Path: xtream.hidden
class Translations$xtream$hidden$en {
	Translations$xtream$hidden$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Hide words'
	String get title => 'Hide words';

	/// en: 'A category or channel with any of these as a whole word is left out of the lists. "UK" hides "UK News" and not "Ukraine". Add a phrase such as "south indian" to hide it as one thing. Case does not matter.'
	String get explain => 'A category or channel with any of these as a whole word is left out of the lists. "UK" hides "UK News" and not "Ukraine". Add a phrase such as "south indian" to hide it as one thing. Case does not matter.';

	/// en: 'A country, a language, a word'
	String get hint => 'A country, a language, a word';

	/// en: 'Add'
	String get add => 'Add';

	/// en: 'Nothing hidden yet.'
	String get none => 'Nothing hidden yet.';

	/// en: 'Select a word to stop hiding it.'
	String get tapToRemove => 'Select a word to stop hiding it.';
}

// Path: transfer.receive
class Translations$transfer$receive$en {
	Translations$transfer$receive$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Could not save the settings: {error}'
	String cannotSave({required Object error}) => 'Could not save the settings: ${error}';

	/// en: 'Receive settings'
	String get title => 'Receive settings';

	/// en: 'Asking the other device…'
	String get asking => 'Asking the other device…';

	/// en: 'Waiting for the other device to send. Say yes there when it asks.'
	String get awaitingPush => 'Waiting for the other device to send. Say yes there when it asks.';

	/// en: 'Saving…'
	String get saving => 'Saving…';

	/// en: 'On the device that has your settings, open Settings, Move to another device, and choose Send. Then scan this code.'
	String get waitingInstructions => 'On the device that has your settings, open Settings, Move to another device, and choose Send. Then scan this code.';

	/// en: 'On the device that has your settings, open Settings, Move to another device, and choose Send, then Show a code. Point the camera at it.'
	String get scanInstructions => 'On the device that has your settings, open Settings, Move to another device, and choose Send, then Show a code. Point the camera at it.';

	/// en: 'Show my code instead'
	String get showMine => 'Show my code instead';

	/// en: 'On the device that has your settings, open Settings, Move to another device, and choose Send, then Show a code. Then enter what it shows.'
	String get typeInstructions => 'On the device that has your settings, open Settings, Move to another device, and choose Send, then Show a code. Then enter what it shows.';

	/// en: 'Connect'
	String get connect => 'Connect';

	/// en: 'Another device wants to send you these. Anything that is already here with the same name is replaced; nothing else is removed.'
	String get review => 'Another device wants to send you these. Anything that is already here with the same name is replaced; nothing else is removed.';

	/// en: 'Save these'
	String get saveThese => 'Save these';

	/// en: 'Decline'
	String get decline => 'Decline';

	/// en: 'Done. Your settings are on this device.'
	String get saved => 'Done. Your settings are on this device.';
}

// Path: transfer.pairing
class Translations$transfer$pairing$en {
	Translations$transfer$pairing$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'No camera? Choose Type the code there, and enter:'
	String get noCamera => 'No camera? Choose Type the code there, and enter:';

	/// en: 'Code to scan from the other device'
	String get qrLabel => 'Code to scan from the other device';

	/// en: 'The camera is switched off for this app. Type the code instead, or allow the camera in your phone's settings.'
	String get cameraOff => 'The camera is switched off for this app. Type the code instead, or allow the camera in your phone\'s settings.';

	/// en: 'The camera could not start. Type the code instead.'
	String get cameraFailed => 'The camera could not start. Type the code instead.';

	/// en: 'That is not a code from this app.'
	String get foreign => 'That is not a code from this app.';

	/// en: 'Check the address (like 192.168.1.20:41234) and the 16-character code.'
	String get checkEntry => 'Check the address (like 192.168.1.20:41234) and the 16-character code.';

	/// en: 'Address'
	String get address => 'Address';

	/// en: 'Code'
	String get code => 'Code';
}

// Path: transfer.pane
class Translations$transfer$pane$en {
	Translations$transfer$pane$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Copy your sources, keys and preferences to another device on the same Wi-Fi, so you do not have to type them again. It goes straight from one device to the other, encrypted with a code that only the two screens share, and the receiving device asks before it saves anything.'
	String get explain => 'Copy your sources, keys and preferences to another device on the same Wi-Fi, so you do not have to type them again. It goes straight from one device to the other, encrypted with a code that only the two screens share, and the receiving device asks before it saves anything.';

	/// en: 'Not copied: Plex (link it on the other device with its own code), watch history, favourites, and the consent you gave for Advanced sources and AI features, which each device asks for itself.'
	String get notCopied => 'Not copied: Plex (link it on the other device with its own code), watch history, favourites, and the consent you gave for Advanced sources and AI features, which each device asks for itself.';

	/// en: 'Receive from another device'
	String get receive => 'Receive from another device';

	/// en: 'Send to another device'
	String get send => 'Send to another device';
}

// Path: transfer.notes
class Translations$transfer$notes$en {
	Translations$transfer$notes$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Your AI provider runs on this device, so it is not sent. Set it up again there with this device's address on your network.'
	String get aiLocal => 'Your AI provider runs on this device, so it is not sent. Set it up again there with this device\'s address on your network.';

	/// en: 'The IPTV accounts are saved but hidden. Turn on Advanced sources in Settings to use them.'
	String get xtreamHidden => 'The IPTV accounts are saved but hidden. Turn on Advanced sources in Settings to use them.';

	/// en: 'AI features will ask before they send anything to the provider.'
	String get aiAsks => 'AI features will ask before they send anything to the provider.';

	/// en: 'Could not save: {failed}. The rest was saved.'
	String partial({required Object failed}) => 'Could not save: ${failed}. The rest was saved.';
}

// Path: transfer.send
class Translations$transfer$send$en {
	Translations$transfer$send$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Could not read this device's settings: {error}'
	String cannotRead({required Object error}) => 'Could not read this device\'s settings: ${error}';

	/// en: 'Send to {host}?'
	String askTitle({required Object host}) => 'Send to ${host}?';

	/// en: 'A device on your network scanned this code and is asking for: {summary} Only agree if you just asked for this on that device.'
	String askBody({required Object summary}) => 'A device on your network scanned this code and is asking for:\n\n${summary}\n\nOnly agree if you just asked for this on that device.';

	/// en: 'Not now'
	String get notNow => 'Not now';

	/// en: 'Send'
	String get send => 'Send';

	/// en: 'Send settings'
	String get title => 'Send settings';

	/// en: 'Reading your settings…'
	String get reading => 'Reading your settings…';

	/// en: 'Sending. The other device will ask before it saves anything.'
	String get sending => 'Sending. The other device will ask before it saves anything.';

	/// en: 'Copies these to another device on the same Wi-Fi, so you do not have to type them again. It goes straight there and is encrypted; nothing passes through us.'
	String get explain => 'Copies these to another device on the same Wi-Fi, so you do not have to type them again. It goes straight there and is encrypted; nothing passes through us.';

	/// en: 'There is nothing set up on this device to send yet.'
	String get nothing => 'There is nothing set up on this device to send yet.';

	/// en: 'Continue'
	String get proceed => 'Continue';

	/// en: 'Show a code instead'
	String get showInstead => 'Show a code instead';

	/// en: 'Type the code instead'
	String get typeInstead => 'Type the code instead';

	/// en: 'On the other device, open Settings, Move to another device, and choose Receive. Point the camera at the code it shows.'
	String get scanInstructions => 'On the other device, open Settings, Move to another device, and choose Receive. Point the camera at the code it shows.';

	/// en: 'On the other device, open Settings, Move to another device, and choose Receive, then Scan its code and point its camera here. You will be asked before anything is sent.'
	String get showInstructions => 'On the other device, open Settings, Move to another device, and choose Receive, then Scan its code and point its camera here. You will be asked before anything is sent.';

	/// en: 'On the other device, open Settings, Move to another device, and choose Receive. Then enter what it shows.'
	String get typeInstructions => 'On the other device, open Settings, Move to another device, and choose Receive. Then enter what it shows.';

	/// en: 'Sent. The other device has saved your settings.'
	String get sent => 'Sent. The other device has saved your settings.';
}

// Path: transfer.item
class Translations$transfer$item$en {
	Translations$transfer$item$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Preferences'
	String get preferences => 'Preferences';

	/// en: 'Playback and subtitle choices, hidden words and library placement.'
	String get preferencesSub => 'Playback and subtitle choices, hidden words and library placement.';

	/// en: 'IPTV accounts'
	String get xtream => 'IPTV accounts';

	/// en: 'Logins and the categories and channels you chose.'
	String get xtreamSub => 'Logins and the categories and channels you chose.';

	/// en: 'Network shares'
	String get smb => 'Network shares';

	/// en: 'SMB shares and their passwords.'
	String get smbSub => 'SMB shares and their passwords.';

	/// en: 'TMDB key'
	String get tmdb => 'TMDB key';

	/// en: 'Your own key for genre, rating and language filters.'
	String get tmdbSub => 'Your own key for genre, rating and language filters.';

	/// en: 'AI provider'
	String get ai => 'AI provider';

	/// en: 'The provider, its model and your key.'
	String get aiSub => 'The provider, its model and your key.';

	/// en: '(one) {{n} setting} (other) {{n} settings}'
	String settings({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} setting',
		other: '${n} settings',
	);

	/// en: '(one) {{n} account} (other) {{n} accounts}'
	String accounts({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} account',
		other: '${n} accounts',
	);

	/// en: '(one) {{n} share} (other) {{n} shares}'
	String shares({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} share',
		other: '${n} shares',
	);

	/// en: 'That was not a settings bundle.'
	String get notBundle => 'That was not a settings bundle.';

	/// en: 'That bundle is from a newer version of the app. Update this device and try again.'
	String get newer => 'That bundle is from a newer version of the app. Update this device and try again.';
}

// Path: transfer.client
class Translations$transfer$client$en {
	Translations$transfer$client$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'The other device did not accept the settings.'
	String get declined => 'The other device did not accept the settings.';

	/// en: 'The code was not right. Check it against the other screen.'
	String get wrongCode => 'The code was not right. Check it against the other screen.';

	/// en: 'The other device already received something. Open Receive again there for a fresh code.'
	String get used => 'The other device already received something. Open Receive again there for a fresh code.';

	/// en: 'That was too much to send.'
	String get tooBig => 'That was too much to send.';

	/// en: 'The other device could not read that.'
	String get unreadable => 'The other device could not read that.';

	/// en: 'The other device answered unexpectedly ({status}).'
	String unexpected({required Object status}) => 'The other device answered unexpectedly (${status}).';

	/// en: 'The other device did not agree to send its settings.'
	String get refusedToSend => 'The other device did not agree to send its settings.';

	/// en: 'The other device is already answering someone else. Ask it for a fresh code.'
	String get busy => 'The other device is already answering someone else. Ask it for a fresh code.';

	/// en: 'Could not reach {address}. Both devices need to be on the same Wi-Fi, and the other one has to still be showing its code.'
	String unreachable({required Object address}) => 'Could not reach ${address}. Both devices need to be on the same Wi-Fi, and the other one has to still be showing its code.';

	/// en: 'The connection dropped part-way.'
	String get dropped => 'The connection dropped part-way.';

	/// en: 'No answer from {address}. Check the other screen.'
	String noAnswer({required Object address}) => 'No answer from ${address}. Check the other screen.';
}

// Path: settings.metadata.errors
class Translations$settings$metadata$errors$en {
	Translations$settings$metadata$errors$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'TMDB rejected that key.'
	String get rejected => 'TMDB rejected that key.';

	/// en: 'TMDB is rate limiting this device.'
	String get rateLimited => 'TMDB is rate limiting this device.';

	/// en: 'Could not reach TMDB ({type}).'
	String unreachable({required Object type}) => 'Could not reach TMDB (${type}).';
}

// Path: settings.appearance.palette
class Translations$settings$appearance$palette$en {
	Translations$settings$appearance$palette$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'System'
	String get system => 'System';

	/// en: 'Midnight'
	String get midnight => 'Midnight';

	/// en: 'Slate'
	String get slate => 'Slate';

	/// en: 'Daylight'
	String get daylight => 'Daylight';

	/// en: 'Amber'
	String get amber => 'Amber';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'common.back' => 'Back',
			'common.tryAgain' => 'Try again',
			'common.cancel' => 'Cancel',
			'common.noDrm' => 'No DRM. Protected commercial catalogues such as Netflix or Disney+ cannot be played.',
			'player.shareGone' => 'That share is no longer configured.',
			'player.shareFileGone' => 'That file is no longer on the share.',
			'player.deviceFileGone' => 'That file is no longer on this device.',
			'player.lineGone' => 'That line is no longer configured.',
			'player.untitledVideo' => 'Video',
			'player.untitledEpisode' => 'Episode',
			'player.untitledFilm' => 'Film',
			'player.untitledLive' => 'Live',
			'player.channelFroze' => 'This channel stopped and did not come back.',
			'player.channelNotResponding' => 'This channel is not responding. Listings often outrun reality on a panel, so try another, or the same one again.',
			'player.didNotStart' => 'This did not start playing. The server may be busy, or the file may need transcoding, which is not supported yet.',
			'player.released' => 'Stopped while the app was in the background, so the connection is free for other devices.',
			'player.rejoin' => 'Rejoin',
			'player.live' => 'LIVE',
			'player.skipBack' => ({required Object seconds}) => 'Back ${seconds} seconds',
			'player.skipForward' => ({required Object seconds}) => 'Forward ${seconds} seconds',
			'player.pause' => 'Pause',
			'player.play' => 'Play',
			'player.tracks' => 'Audio and subtitles',
			'player.audio' => 'Audio',
			'player.subtitles' => 'Subtitles',
			'player.off' => 'Off',
			'player.trackNumber' => ({required Object n}) => 'Track ${n}',
			'languages.en' => 'English',
			'languages.es' => 'Spanish',
			'languages.fr' => 'French',
			'languages.de' => 'German',
			'languages.it' => 'Italian',
			'languages.pt' => 'Portuguese',
			'languages.nl' => 'Dutch',
			'languages.sv' => 'Swedish',
			'languages.no' => 'Norwegian',
			'languages.da' => 'Danish',
			'languages.fi' => 'Finnish',
			'languages.pl' => 'Polish',
			'languages.cs' => 'Czech',
			'languages.hu' => 'Hungarian',
			'languages.ro' => 'Romanian',
			'languages.el' => 'Greek',
			'languages.ru' => 'Russian',
			'languages.uk' => 'Ukrainian',
			'languages.tr' => 'Turkish',
			'languages.ar' => 'Arabic',
			'languages.he' => 'Hebrew',
			'languages.hi' => 'Hindi',
			'languages.bn' => 'Bengali',
			'languages.pa' => 'Punjabi',
			'languages.ta' => 'Tamil',
			'languages.te' => 'Telugu',
			'languages.ur' => 'Urdu',
			'languages.th' => 'Thai',
			'languages.vi' => 'Vietnamese',
			'languages.id' => 'Indonesian',
			'languages.zh' => 'Chinese',
			'languages.ja' => 'Japanese',
			'languages.ko' => 'Korean',
			'subtitleSize.small' => 'Small',
			'subtitleSize.medium' => 'Medium',
			'subtitleSize.large' => 'Large',
			'units.minutes' => ({required Object m}) => '${m} min',
			'units.hours' => ({required Object h}) => '${h} h',
			'units.hoursMinutes' => ({required Object h, required Object m}) => '${h} h ${m} min',
			'units.minutesLeft' => ({required Object m}) => '${m} min left',
			'units.seconds' => ({required Object s}) => '${s} s',
			'downloads.empty' => 'Nothing downloaded yet. Press and hold a movie or episode from your Plex library and choose Download, then watch it here with no network.',
			'downloads.title' => 'Downloads',
			'downloads.summary' => ({required num n, required Object size}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} item · ${size} on this device', other: '${n} items · ${size} on this device', ), 
			'downloads.pendingWatches' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '1 watch here is waiting to be sent to Plex.', other: '${n} watches here are waiting to be sent to Plex.', ), 
			'downloads.foregroundOnly' => 'Downloads continue while the app is open. Closing it pauses them, and nothing already saved is lost.',
			'downloads.downloadingBytes' => ({required Object received}) => 'Downloading, ${received}',
			'downloads.downloadingPercent' => ({required Object percent, required Object received, required Object total}) => 'Downloading ${percent}% · ${received} of ${total}',
			'downloads.queued' => 'Waiting for its turn',
			'downloads.paused' => 'Paused',
			'downloads.pausedAt' => ({required Object percent}) => 'Paused at ${percent}% · select to resume',
			'downloads.failed' => ({required Object error}) => '${error} Select to try again.',
			'downloads.failedUnknown' => 'It did not finish.',
			'downloads.deleteTitle' => 'Delete this download?',
			'downloads.cancelTitle' => 'Cancel this download?',
			'downloads.removeBody' => ({required Object title}) => '"${title}" will be removed from this device. It stays on your Plex server.',
			'downloads.removeBodyFreeing' => ({required Object title, required Object size}) => '"${title}" will be removed from this device, freeing ${size}. It stays on your Plex server.',
			'downloads.keepIt' => 'Keep it',
			'downloads.delete' => 'Delete',
			'downloads.errors.serverNotConnected' => 'That server is not connected. Reconnect it in Settings, then resume.',
			'downloads.errors.sizeMismatch' => 'The file did not match the size the server reported. Try again.',
			'downloads.errors.cannotWrite' => 'Could not write the file. The device may be out of space.',
			'downloads.errors.changedOnServer' => 'The file changed on the server. Start the download again.',
			'downloads.errors.refused' => 'The server would not let this device download that.',
			'downloads.errors.status' => ({required Object code}) => 'The server answered ${code}.',
			'downloads.errors.dropped' => 'The connection dropped part-way. Resume to continue.',
			'downloads.errors.unreachable' => 'Could not reach the server. Check the connection and resume.',
			'downloads.errors.timeout' => 'The server took too long to answer.',
			'downloads.rule.off' => 'Keep episodes downloaded',
			'downloads.rule.keeping' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'Keeping the next episode downloaded', other: 'Keeping the next ${n} episodes downloaded', ), 
			'downloads.rule.explain' => 'Downloads the next unwatched episodes and replaces them as you watch, while the app is open. Watched ones it downloaded are removed.',
			'downloads.rule.choiceOff' => 'Off',
			'downloads.rule.choice' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'Next episode', other: 'Next ${n} episodes', ), 
			'watchActions.everyEpisode' => ' (every episode)',
			'watchActions.markWatched' => ({required Object scope}) => 'Mark as watched${scope}',
			'watchActions.markUnwatched' => ({required Object scope}) => 'Mark as unwatched${scope}',
			'watchActions.download' => 'Download to this device',
			'watchActions.deleteDownload' => 'Delete download',
			'watchActions.cancelDownload' => 'Cancel download',
			'watchActions.removeFavourite' => 'Remove from favourites',
			'watchActions.addFavourite' => 'Add to favourites',
			'watchActions.removeResume' => 'Remove from Continue watching',
			'watchActions.downloading' => 'Downloading. See the Downloads tab.',
			'watchActions.markedOffline' => 'Marked as watched here. Plex will be told when it can be reached.',
			'watchActions.plexRefused' => 'Plex didn\'t accept that. The server may be offline.',
			'show.noEpisodes' => 'This show has no episodes on the server.',
			'shell.library' => 'Library',
			'shell.search' => 'Search',
			'shell.downloads' => 'Downloads',
			'shell.settings' => 'Settings',
			'shell.exitTitle' => 'Exit Subnext Player?',
			'shell.exit' => 'Exit',
			'shell.stay' => 'Stay',
			'resume.upNext' => 'Up next',
			'resume.title' => 'Continue watching',
			'resume.remove' => 'Remove from continue watching',
			'library.placement.movies' => 'Movies',
			'library.placement.series' => 'Series',
			'library.placement.hidden' => 'Hidden',
			'library.tab.movies' => 'Movies',
			'library.tab.series' => 'Series',
			'library.tab.localNetwork' => 'Local & Network',
			'library.tab.liveTv' => 'Live TV',
			'library.tab.emptyMovies' => 'No movies on this server.',
			'library.tab.emptySeries' => 'No series on this server.',
			'library.tab.emptyLocalNetwork' => 'No folders or network shares yet.\nDevice storage and SMB shares are not connectable in this build.',
			'library.tab.emptyLiveTv' => 'No playlist or panel configured.\nAdd one from Settings once Advanced sources is on.',
			'library.tab.countMovies' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} movie', other: '${n} movies', ), 
			'library.tab.countSeries' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} series', other: '${n} series', ), 
			'library.tab.countItems' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} item', other: '${n} items', ), 
			'library.tab.countChannels' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} channel', other: '${n} channels', ), 
			'library.serverTimeout' => ({required Object server, required Object seconds}) => '${server} did not respond within ${seconds} seconds. It may be asleep or off the network.',
			'library.allWatched' => 'Everything in Movies is watched.',
			'library.showAll' => 'Show all',
			'library.noSources' => 'No sources connected yet.',
			'library.nothingIn' => ({required Object tab}) => 'Nothing in ${tab} yet.',
			'library.addSource' => 'Add a source',
			'library.sortFiltered' => ({required Object sort}) => '${sort} · Unwatched',
			'library.sortBy' => 'Sort by',
			'library.unwatchedOnly' => 'Unwatched only',
			'library.shelf.seeAll' => 'See all',
			'library.shelf.titles' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} title', other: '${n} titles', ), 
			'library.shelf.gone' => 'Nothing here any more.',
			'library.sort.title' => 'Title',
			'library.sort.recentlyAdded' => 'Recently added',
			'library.sort.year' => 'Year',
			'library.sort.releaseDate' => 'Release date',
			'library.tile.series' => 'Series',
			'library.tile.movie' => 'Movie',
			'library.tile.watched' => 'Watched',
			'library.tile.percentWatched' => ({required Object percent}) => '${percent}% watched',
			'liveTv.group.favourites' => 'Favourites',
			'liveTv.group.numbered' => ({required Object n}) => 'Category ${n}',
			'liveTv.group.other' => 'Other',
			'liveTv.noPanel' => 'No playlist or panel configured.',
			'liveTv.addOne' => 'Add one',
			'liveTv.noCategories' => 'No categories chosen yet.\nPanels carry tens of thousands of channels, so Subnext Player only fetches the ones you pick.',
			'liveTv.chooseCategories' => 'Choose categories',
			'liveTv.noChannels' => 'Those categories returned no channels.',
			'liveTv.noMatch' => ({required Object query}) => 'No channel matching "${query}".',
			'liveTv.searchHint' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'Search ${n} channel', other: 'Search ${n} channels', ), 
			'liveTv.all' => 'All',
			'ai.picks.yourProvider' => 'your provider',
			'ai.picks.ask' => 'What should I watch?',
			'ai.picks.askExplain' => ({required Object provider}) => 'Ask ${provider} to pick from your own library.',
			'ai.picks.pickedBy' => 'Picked for you by ',
			'ai.picks.updating' => 'Updating',
			'ai.picks.again' => 'Again',
			'ai.picks.preparing' => 'Getting your picks ready...',
			'ai.search.asking' => ({required Object provider}) => 'Asking ${provider}...',
			'ai.search.searching' => ({required Object searched, required Object covered}) => 'Searching your library... ${searched} of ${covered} titles',
			'ai.search.emptyLibrary' => 'There is nothing in your library to search yet.',
			'ai.search.notFound' => ({required Object total}) => 'The model did not find anything in ${total} titles that fits that. Try describing it differently.',
			'ai.search.notFoundFirst' => ({required Object covered, required Object total}) => 'The model did not find anything in the first ${covered} of ${total} titles that fits that. Try describing it differently.',
			'ai.search.stillSearching' => ({required Object searched, required Object covered}) => 'Still searching: ${searched} of ${covered} titles',
			'ai.search.searchedFirst' => ({required Object covered, required Object total}) => 'Searched the first ${covered} of ${total} titles',
			'ai.search.pickedFor' => ({required Object provider, required Object query}) => 'Picked by ${provider} for "${query}"',
			'ai.search.searchAgain' => 'Search again',
			'ai.search.partsFailed' => ({required Object failed, required Object parts}) => '${failed} of ${parts} parts could not be searched, so some of your library was not looked at. The provider may be limiting requests',
			'ai.presetOther' => 'Other',
			'ai.hintOpenRouter' => 'Model ids are listed at openrouter.ai/models. Free ones end in ":free".',
			'ai.hintOllama' => 'Use your computer\'s address on this network, for example http://192.168.1.20:11434/v1. Nothing leaves your network.',
			'ai.hintCustom' => 'Any service that speaks the OpenAI chat format.',
			'ai.feature.naturalSearch' => 'Natural-language search',
			'ai.feature.naturalSearchSends' => 'Your search text, and the titles and years in your library.',
			'ai.feature.naturalSearchTiming' => 'A large library is sent in several requests of a few hundred titles each, so a search makes more than one.',
			'ai.feature.recommendations' => 'Recommendations',
			'ai.feature.recommendationsSends' => 'The films you watched recently, and the titles and years of what you have not watched yet in your library.',
			'ai.feature.recommendationsTiming' => 'Picks are prepared in the background shortly after the app opens, but only when what you watched has changed or they are over a day old, so it is not a request on every launch.',
			'ai.errors.ranOutThinking' => 'The model ran out of reply space while thinking and never gave an answer. A model that does not "think" first will work better.',
			'ai.errors.empty' => 'The model sent back an empty answer.',
			'ai.errors.rejectedKey' => ({required Object suffix}) => 'The provider rejected that key${suffix}.',
			'ai.errors.noCredit' => ({required Object suffix}) => 'The provider says this account is out of credit${suffix}.',
			'ai.errors.unknownModel' => ({required Object suffix}) => 'The provider does not know that model or address${suffix}.',
			'ai.errors.rateLimited' => ({required Object suffix}) => 'The provider is rate limiting this key. Try again shortly${suffix}.',
			'ai.errors.serverError' => ({required Object status, required Object suffix}) => 'The provider had a problem (HTTP ${status})${suffix}.',
			'ai.errors.timeout' => 'The provider took too long to answer.',
			'ai.errors.unreachable' => 'Could not reach the provider. Check the address.',
			'ai.errors.failed' => ({required Object suffix}) => 'The request failed${suffix}.',
			'ai.errors.failedStatus' => ({required Object status, required Object suffix}) => 'The request failed (HTTP ${status})${suffix}.',
			'ai.errors.fillIn' => 'Fill in the address and the model.',
			'ai.errors.needsKey' => 'This provider needs an API key.',
			'ai.errors.notSetUp' => 'No AI provider is set up.',
			'ai.errors.searchOff' => 'Natural-language search is switched off for this provider.',
			'ai.errors.searchFailed' => 'The search failed.',
			'ai.errors.noSignal' => 'Watch a film first, so there is something to base picks on.',
			'ai.errors.noPicks' => 'The model did not pick anything this time.',
			'ai.consentTitle' => ({required Object provider}) => 'Send data to ${provider}?',
			'ai.consentBody' => ({required Object feature, required Object provider, required Object sends}) => '${feature} will send this to ${provider}: ${sends}',
			'ai.consentTail' => 'It goes straight from this device to them, never through us. You can switch this off again in Settings, AI features.',
			'ai.notNow' => 'Not now',
			'ai.allow' => 'Allow',
			'search.filters.decadeOldest' => ({required Object decade}) => '${decade}s and earlier',
			'search.filters.decade' => ({required Object decade}) => '${decade}s',
			'search.filters.type' => 'Type',
			'search.filters.movies' => 'Movies',
			'search.filters.series' => 'Series',
			'search.filters.source' => 'Source',
			'search.filters.unknownSource' => 'Unknown source',
			'search.filters.year' => 'Year',
			'search.filters.language' => 'Language',
			'search.filters.languageNote' => 'Guessed from IPTV category names. Plex titles have no language here.',
			'search.filters.genre' => 'Genre',
			'search.filters.rating' => 'Rating',
			'search.filters.ratingNote' => 'TMDB user rating out of 10. Titles TMDB has no rating for are left out.',
			'search.filters.originalLanguage' => 'Original language',
			'search.filters.originalLanguageNote' => 'The language the title was made in, from TMDB. A dubbed copy keeps its original language here.',
			'search.filters.clear' => 'Clear',
			'search.filters.noMatches' => 'Nothing matches those filters.',
			'search.filters.clearAll' => 'Clear filters',
			'search.filters.chip' => ({required Object label, required Object value}) => '${label}: ${value}',
			'search.filters.any' => 'Any',
			'search.hint' => 'Search your sources',
			'search.prompt' => 'Search movies and series across your server.',
			'search.keepTyping' => 'Keep typing…',
			'search.noMatch' => ({required Object query}) => 'Nothing matching "${query}".',
			'search.backToResults' => 'Back to results',
			'search.askAi' => 'Ask AI',
			'search.becauseYouWatched' => 'Because you watched ',
			'settings.about.versionLoading' => 'Version …',
			'settings.about.version' => ({required Object version, required Object build}) => 'Version ${version} (${build})',
			'settings.about.privacyPolicy' => 'Privacy policy',
			'settings.about.privacySummary' => 'No account, no backend and no analytics. The full policy is at:',
			'settings.about.licences' => 'Open-source licences',
			'settings.privacy.summary' => 'Subnext Player has no backend and no analytics. What it keeps lives on this device, and the only places data is sent are the sources, TMDB and AI provider you connect yourself.',
			'settings.privacy.cachedData' => 'Cached data',
			'settings.privacy.cachedExplain' => 'Your library lists, TMDB lookups and AI picks are kept so the app opens quickly. Old ones clear themselves, after 30 days for a library and 90 for a lookup, and a source\'s entry goes when you remove the source. Clearing now leaves your sources, keys, settings and watch history alone, and everything is fetched again when needed.',
			'settings.privacy.clearing' => 'Clearing...',
			'settings.privacy.clear' => 'Clear cached data',
			'settings.privacy.cleared' => 'Cleared. Your library is loading again.',
			'settings.playback.skip' => 'Skip back and forward',
			'settings.playback.skipExplain' => 'The skip buttons, the fast-forward and rewind keys on a remote, and the first step when moving along the seek bar.',
			'settings.playback.audioLanguage' => 'Preferred audio language',
			'settings.playback.audioLanguageExplain' => 'Used when a file has more than one audio track. Otherwise the file\'s own default plays.',
			'settings.playback.fileDefault' => 'File\'s default',
			'settings.playback.showSubtitles' => 'Show subtitles',
			'settings.playback.showSubtitlesExplain' => 'Turn them on when a file has them. You can always switch in the player.',
			'settings.playback.subtitleLanguage' => 'Preferred subtitle language',
			'settings.playback.subtitleLanguageExplain' => 'If a file has no subtitles in this language, none are shown.',
			'settings.playback.any' => 'Any',
			'settings.playback.size' => 'Size',
			'settings.playback.sizeExplain' => 'For text subtitles, such as SRT and ASS.',
			'settings.metadata.consent' => 'This looks up the release date of every film and series in your library on TMDB, in the background, a few at a time. To do that it sends the title (and the year, when there is one) of each of them from this device to TMDB, and to no one else, not only the ones you search for. It also fills in genre and rating for the filters. Results are kept on this device for 90 days, and titles already looked up are not asked again.\n\nYou can switch it off at any time. Removing your TMDB key switches it off too.',
			'settings.metadata.consentTitle' => 'Send your library titles to TMDB?',
			'settings.metadata.notNow' => 'Not now',
			'settings.metadata.lookThemUp' => 'Look them up',
			'settings.metadata.waiting' => 'Waiting for your library to load.',
			'settings.metadata.stopped' => 'Paused: TMDB stopped answering. It carries on the next time the app opens, and what it found is kept.',
			'settings.metadata.running' => ({required Object settled, required Object total}) => 'Looked up ${settled} of ${total} titles.',
			'settings.metadata.partial' => ({required Object settled, required Object total}) => 'Looked up ${settled} of ${total} titles. The rest carry on the next time the app opens.',
			'settings.metadata.done' => ({required Object found, required Object total}) => 'Done: ${found} release dates found for ${total} titles.',
			'settings.metadata.releaseDates' => 'Release dates for your library',
			'settings.metadata.releaseDatesExplain' => 'Adds exact release dates in the background, so Sort by Release date can order your library properly, including titles with no year. Sends every title in your library to TMDB.',
			'settings.metadata.intro' => 'Connect your own TMDB key to add genre, rating and original language to search results, and suggestions based on what you have watched. It is optional, and nothing changes until you add one.',
			'settings.metadata.keyExplain' => 'The titles being looked up are sent from this device to TMDB, and to no one else. Create a free key in your TMDB account under Settings, API. Either the short key or the long Read Access Token works. On a TV it is easier to paste or type this on a phone or computer first.',
			'settings.metadata.keySaved' => 'TMDB key saved',
			'settings.metadata.removeKey' => 'Remove key',
			'settings.metadata.keyLabel' => 'TMDB API key',
			'settings.metadata.checking' => 'Checking...',
			'settings.metadata.verify' => 'Verify and save',
			'settings.metadata.errors.rejected' => 'TMDB rejected that key.',
			'settings.metadata.errors.rateLimited' => 'TMDB is rate limiting this device.',
			'settings.metadata.errors.unreachable' => ({required Object type}) => 'Could not reach TMDB (${type}).',
			'settings.ai.intro' => 'Connect your own provider and your own key. Requests go straight from this device to the provider you chose, never through us, because there is no server of ours in between. Nothing is sent until you allow a feature below.',
			'settings.ai.address' => 'Address',
			'settings.ai.model' => 'Model',
			'settings.ai.keyOptional' => 'API key (optional for a local server)',
			'settings.ai.key' => 'API key',
			'settings.ai.trying' => 'Trying it...',
			'settings.ai.testAndSave' => 'Test and save',
			'settings.ai.onNetwork' => 'On your network',
			'settings.ai.keySaved' => 'Key saved',
			'settings.ai.remove' => 'Remove provider',
			'settings.ai.maySend' => 'What it may send',
			'settings.ai.localNoConsent' => 'This provider is on your own network, so nothing reaches a third party and no consent is needed.',
			'settings.ai.sendsTo' => ({required Object provider, required Object sends}) => 'Sends to ${provider}: ${sends}',
			'settings.ai.allowedOn' => ({required Object date}) => 'Allowed on ${date}',
			'settings.ai.notAllowed' => 'Not allowed yet. You will be asked the first time.',
			'settings.ai.switchOff' => 'Switch off',
			'settings.ai.allow' => 'Allow',
			'settings.appearance.palette.system' => 'System',
			'settings.appearance.palette.midnight' => 'Midnight',
			'settings.appearance.palette.slate' => 'Slate',
			'settings.appearance.palette.daylight' => 'Daylight',
			'settings.appearance.palette.amber' => 'Amber',
			'settings.appearance.theme' => 'Theme',
			'settings.appearance.accent' => 'Accent',
			'settings.section.sources' => 'Sources',
			'settings.section.appearance' => 'Appearance',
			'settings.section.playback' => 'Playback',
			'settings.section.subtitles' => 'Subtitles',
			'settings.section.metadata' => 'Metadata',
			'settings.section.aiFeatures' => 'AI features',
			'settings.section.advancedSources' => 'Advanced sources',
			'settings.section.transfer' => 'Move to another device',
			'settings.section.privacy' => 'Privacy and data',
			'settings.section.about' => 'About',
			'settings.advanced.dialogTitle' => 'Turning on advanced sources',
			'settings.advanced.dialogLead' => 'You are about to connect a third-party provider using your own credentials.',
			'settings.advanced.dialogNoContent' => 'Subnext Player does not provide, host, or endorse any content or provider. You supply the address and the login, and the app plays whatever that address returns.',
			'settings.advanced.dialogRights' => 'You are responsible for holding the rights to whatever you connect to.',
			'settings.advanced.dialogConfirm' => 'I understand, turn on',
			'settings.advanced.toggle' => 'IPTV provider or playlist',
			'settings.advanced.toggleExplain' => 'Adds Live TV and Xtream Codes logins.',
			'settings.advanced.offKeeps' => 'Turning this off later hides Live TV but keeps any accounts you added.',
			'settings.sources.noServers' => 'No Plex servers connected.',
			'settings.sources.remove' => 'Remove',
			'settings.sources.loadFailed' => ({required Object error}) => 'Could not load libraries from this server.\n\n${error}',
			'settings.sources.lookForMore' => 'Look for more servers',
			'settings.sources.addAnother' => 'Add another server',
			'settings.sources.yours' => 'Yours',
			'settings.sources.shared' => 'Shared with you',
			'settings.sources.viaRelay' => 'via relay',
			'settings.sources.plexType' => ({required Object type}) => 'Plex type: ${type}',
			'settings.sources.changedByYou' => 'changed by you',
			'onboarding.tagline' => 'Play from the sources you connect.',
			'onboarding.blurb' => 'Subnext Player streams from sources you connect yourself: a Plex server, a home NAS or local files, or optionally an IPTV provider or playlist. We host no content.',
			'onboarding.localDesktop' => 'Files on this PC, or a folder on a home NAS or SMB share.',
			'onboarding.localTv' => 'A folder on a home NAS or SMB share.',
			'onboarding.local' => 'Video on this device, or a folder on a home NAS or SMB share.',
			'onboarding.plexTv' => 'Sign in with your own account on this TV.',
			'onboarding.plex' => 'Your personal library, signed in with your own account.',
			'onboarding.advancedTv' => 'Off by default. Turn on in Settings.',
			'onboarding.advanced' => 'Off by default. Turn on in Settings to use an IPTV provider or playlist.',
			'onboarding.localTitle' => 'Local & Network',
			'onboarding.advancedTitle' => 'Advanced sources',
			'onboarding.addFirst' => 'Add your first source',
			'onboarding.notNow' => 'Not now',
			'onboarding.connect' => 'Connect a source',
			'onboarding.addSource' => 'Add source',
			'onboarding.okKey' => 'OK',
			'onboarding.toSelect' => 'to select',
			'addSource.privacy' => 'Credentials stay on this device. Nothing is sent to us: there is no account and no server in the middle.',
			'addSource.kind.plex' => 'Plex server',
			'addSource.kind.plexShort' => 'Link with code',
			'addSource.kind.plexLong' => 'Approve this device in your browser. Your own server plus anything shared with you.',
			'addSource.kind.localFiles' => 'Video on this device',
			'addSource.kind.localFilesSub' => 'Scan your media library, or pick a single folder to keep access to.',
			'addSource.kind.localFilesIos' => 'Play the videos in your photo library.',
			'addSource.kind.smb' => 'Network share (SMB)',
			'addSource.kind.smbSub' => 'A NAS or Windows share on your home network.',
			'addSource.kind.xtream' => 'Xtream Codes login',
			'addSource.kind.xtreamSub' => 'Host, username and password from your provider.',
			'addSource.copyFromDevice' => 'Copy from another device',
			'addSource.copyFromDeviceSub' => 'Already set up on your phone? Send it here instead of typing it again.',
			'addSource.title' => 'Add a source',
			'addSource.advanced' => 'Advanced sources',
			'addSource.or' => 'Or',
			'addSource.advancedHintLead' => 'Looking for an IPTV provider or playlist? Turn on ',
			'addSource.advancedHintTail' => ' in Settings.',
			'addSource.sourceType' => 'Source type',
			'addSource.plexRail' => 'Link with a code',
			'addSource.pcFiles' => 'Files on this PC',
			'addSource.pcFilesSub' => 'Choose a folder',
			'addSource.smbRail' => 'NAS or Windows share',
			'addSource.copyRail' => 'Send it from your phone',
			'addSource.keystore' => 'Credentials are stored in your device keystore, never in the app database.',
			'addSource.pick' => 'Choose a source type to get started.',
			'plex.connected' => 'Plex connected.',
			'plex.connectedTo' => ({required Object name}) => 'Connected to ${name}.',
			'plex.opening' => 'Connected. Opening your library…',
			'plex.connect' => 'Connect to Plex',
			'plex.explain' => 'Subnext Player plays what your own Plex server already holds. Nothing is uploaded, and no account details reach anyone but Plex.',
			'plex.contacting' => 'Contacting Plex…',
			'plex.enterCode' => 'On any device, open plex.tv/link and enter:',
			'plex.waiting' => 'Waiting for approval…',
			'plex.copyCode' => 'Copy code',
			'plex.chooseServer' => 'Choose a server',
			'plex.allConnected' => 'Every server on this account is already connected.',
			'plex.yourServers' => 'Your servers',
			'plex.sharedWithYou' => 'Shared with you',
			'plex.connecting' => 'Connecting… this can take a few seconds',
			'plex.offline' => 'Offline',
			'plex.relayOnly' => 'Plex Relay only, playback may be limited',
			'plex.codeExpired' => 'That code expired. Try again.',
			'plex.noServers' => 'That account has no Plex servers.',
			'plex.errors.noAnswer' => ({required Object server, required Object count}) => '"${server}" did not answer on any of its ${count} advertised addresses.',
			'plex.errors.itemGone' => 'That item is no longer on the server.',
			'plex.errors.noFile' => 'No playable file on this item. Transcode-only sources are not supported yet.',
			'plex.errors.notConnected' => 'Not connected to a Plex server.',
			'local.noAccess' => ({required Object where}) => 'Subnext Player cannot see your videos without media access. You can grant it in ${where}.',
			'local.settingsIos' => 'the Settings app',
			'local.settingsAndroid' => 'Android settings',
			'local.intro' => 'Play videos stored on this device.\nSubnext Player only asks for video access, never full file access.',
			'local.allowAccess' => 'Allow video access',
			'local.pickFolderInstead' => 'Or pick a folder instead',
			'local.addShare' => 'Add a network share',
			'local.shares' => 'Network shares',
			'local.pickedFolders' => 'Folders you picked',
			'local.onDevice' => 'On this device',
			'local.noVideos' => 'No videos found on this device.',
			'local.addFolderShort' => 'Add a folder',
			'local.addShareShort' => 'Add a share',
			'local.scanDevice' => 'Scan this device',
			'local.forgetFolder' => 'Forget this folder',
			'local.folder' => 'Folder',
			'local.safUnreadable' => ({required Object error}) => 'This folder is no longer readable. Android may have dropped the permission, so remove it and pick it again.\n\n${error}',
			'local.safEmpty' => 'No videos or subfolders here.',
			'smb.connectFailed' => ({required Object error}) => 'Could not connect: ${error}',
			'smb.title' => 'Add a network share',
			'smb.explain' => 'A NAS or a shared folder on another computer on your network.',
			'smb.host' => 'Server address',
			'smb.hostHint' => 'e.g. nas',
			'smb.username' => 'Username',
			'smb.password' => 'Password',
			'smb.domain' => 'Domain (optional)',
			'smb.name' => 'Name (optional)',
			'smb.connectAndAdd' => 'Connect and add',
			'smb.gone' => 'That share is no longer configured.',
			'smb.unreachable' => ({required Object error}) => 'Could not reach this share. The server may be asleep or off the network.\n\n${error}',
			'smb.empty' => 'No videos or folders here.',
			'xtream.lineGone' => 'That line is no longer configured.',
			'xtream.catalogue.live' => 'Live TV',
			'xtream.catalogue.vod' => 'Movies',
			'xtream.catalogue.series' => 'Series',
			'xtream.errors.status' => ({required Object code}) => 'The panel returned ${code}. Try again later.',
			'xtream.errors.timeout' => 'The panel did not respond in time.',
			'xtream.errors.unreachable' => 'Could not reach that address. Check the host and port.',
			'xtream.errors.other' => ({required Object type}) => 'Could not talk to the panel (${type}).',
			'xtream.errors.notXtream' => 'That address did not answer like an Xtream panel.',
			'xtream.errors.rejected' => 'The panel rejected those credentials.',
			'xtream.errors.wrongLogin' => 'Wrong username or password.',
			'xtream.errors.unnamed' => 'Unnamed',
			'xtream.errors.episode' => 'Episode',
			'xtream.errors.noPassword' => 'That line has no stored password. Remove it and add it again.',
			'xtream.everythingElse' => 'Everything else',
			'xtream.series.title' => 'Series',
			'xtream.series.noEpisodes' => 'The panel returned no episodes for this series.',
			'xtream.series.season' => ({required Object n}) => 'Season ${n}',
			'xtream.remove' => 'Remove',
			'xtream.add' => 'Add a playlist or panel',
			'xtream.addLine.discardTitle' => 'Discard this line?',
			'xtream.addLine.discardBody' => 'What you typed here has not been saved.',
			'xtream.addLine.discard' => 'Discard',
			'xtream.addLine.keepEditing' => 'Keep editing',
			'xtream.addLine.inactive' => ({required Object status}) => 'The panel says this line is "${status}".',
			'xtream.addLine.noContent' => 'Subnext Player does not provide, host, or endorse any content or provider. You supply the address and the login, and the app plays whatever that address returns.',
			'xtream.addLine.host' => 'Server address',
			'xtream.addLine.name' => 'Name (optional)',
			'xtream.addLine.nameHint' => 'What you want to call this line',
			'xtream.addLine.checking' => 'Checking…',
			'xtream.addLine.verify' => 'Verify and add',
			'xtream.addLine.connected' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'Connected. ${n} concurrent stream allowed.', other: 'Connected. ${n} concurrent streams allowed.', ), 
			'xtream.picker.patternNone' => 'That pattern matched nothing.',
			'xtream.picker.title' => ({required Object catalogue}) => '${catalogue} categories',
			'xtream.picker.save' => 'Save',
			'xtream.picker.noMatch' => ({required Object query}) => 'Nothing matches "${query}".',
			'xtream.picker.noneChosen' => 'Nothing chosen yet.',
			'xtream.picker.search' => 'Search all categories',
			'xtream.picker.chosen' => ({required Object n}) => 'Chosen ${n}',
			'xtream.picker.hideWords' => 'Hide words',
			'xtream.picker.hideCount' => ({required Object n}) => 'Hide ${n}',
			'xtream.picker.pattern' => 'Pattern',
			'xtream.picker.untickedOne' => ({required Object name, required Object word}) => 'Un-ticked "${name}", which "${word}" hides. Save to keep that.',
			'xtream.picker.untickedMany' => ({required Object n, required Object word}) => 'Un-ticked ${n} chosen categories that "${word}" hides. Save to keep that.',
			'xtream.picker.showingHidden' => 'Showing the categories your hidden words leave out.',
			'xtream.picker.hiddenCount' => ({required Object n}) => '${n} hidden by your words.',
			'xtream.picker.hideAgain' => 'Hide again',
			'xtream.picker.showThem' => 'Show them',
			'xtream.picker.patternHint' => 'Select or clear every category matching a word or pattern',
			'xtream.picker.selectMatching' => 'Select matching',
			'xtream.picker.deselectMatching' => 'Deselect matching',
			'xtream.picker.groups' => 'Groups',
			'xtream.picker.clearAll' => 'Clear all',
			'xtream.picker.selectAll' => 'Select all',
			'xtream.picker.channelsPicked' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} channel', other: '${n} channels', ), 
			'xtream.picker.pickedChosen' => ({required Object n}) => '${n} chosen',
			'xtream.picker.categories' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} category', other: '${n} categories', ), 
			'xtream.picker.channels' => 'Channels',
			'xtream.channels.done' => 'Done',
			'xtream.channels.search' => 'Search this category',
			'xtream.channels.pickedOf' => ({required Object picked, required Object total}) => '${picked} of ${total}',
			'xtream.channels.whole' => 'Whole category',
			'xtream.channels.selectShown' => 'Select shown',
			'xtream.channels.clear' => 'Clear',
			'xtream.channels.clearShown' => 'Clear shown',
			'xtream.channels.none' => 'The panel lists no channels in this category.',
			'xtream.hidden.title' => 'Hide words',
			'xtream.hidden.explain' => 'A category or channel with any of these as a whole word is left out of the lists. "UK" hides "UK News" and not "Ukraine". Add a phrase such as "south indian" to hide it as one thing. Case does not matter.',
			'xtream.hidden.hint' => 'A country, a language, a word',
			'xtream.hidden.add' => 'Add',
			'xtream.hidden.none' => 'Nothing hidden yet.',
			'xtream.hidden.tapToRemove' => 'Select a word to stop hiding it.',
			'transfer.noNetwork' => 'This device is not on a Wi-Fi or Ethernet network. Connect it to the same network as the other device and try again.',
			'transfer.cannotListen' => ({required Object error}) => 'Could not start listening: ${error}',
			_ => null,
		} ?? switch (path) {
			'transfer.expired' => 'That code has expired. Start again for a new one.',
			'transfer.wentWrong' => ({required Object error}) => 'Something went wrong: ${error}',
			'transfer.wentWrongPlain' => 'Something went wrong.',
			'transfer.gettingReady' => 'Getting ready…',
			'transfer.waitingOther' => 'Waiting for the other device…',
			'transfer.copyCode' => 'Copy code',
			'transfer.scanInstead' => 'Scan its code instead',
			'transfer.typeInstead' => 'Type its code instead',
			'transfer.done' => 'Done',
			'transfer.close' => 'Close',
			'transfer.receive.cannotSave' => ({required Object error}) => 'Could not save the settings: ${error}',
			'transfer.receive.title' => 'Receive settings',
			'transfer.receive.asking' => 'Asking the other device…',
			'transfer.receive.awaitingPush' => 'Waiting for the other device to send. Say yes there when it asks.',
			'transfer.receive.saving' => 'Saving…',
			'transfer.receive.waitingInstructions' => 'On the device that has your settings, open Settings, Move to another device, and choose Send. Then scan this code.',
			'transfer.receive.scanInstructions' => 'On the device that has your settings, open Settings, Move to another device, and choose Send, then Show a code. Point the camera at it.',
			'transfer.receive.showMine' => 'Show my code instead',
			'transfer.receive.typeInstructions' => 'On the device that has your settings, open Settings, Move to another device, and choose Send, then Show a code. Then enter what it shows.',
			'transfer.receive.connect' => 'Connect',
			'transfer.receive.review' => 'Another device wants to send you these. Anything that is already here with the same name is replaced; nothing else is removed.',
			'transfer.receive.saveThese' => 'Save these',
			'transfer.receive.decline' => 'Decline',
			'transfer.receive.saved' => 'Done. Your settings are on this device.',
			'transfer.pairing.noCamera' => 'No camera? Choose Type the code there, and enter:',
			'transfer.pairing.qrLabel' => 'Code to scan from the other device',
			'transfer.pairing.cameraOff' => 'The camera is switched off for this app. Type the code instead, or allow the camera in your phone\'s settings.',
			'transfer.pairing.cameraFailed' => 'The camera could not start. Type the code instead.',
			'transfer.pairing.foreign' => 'That is not a code from this app.',
			'transfer.pairing.checkEntry' => 'Check the address (like 192.168.1.20:41234) and the 16-character code.',
			'transfer.pairing.address' => 'Address',
			'transfer.pairing.code' => 'Code',
			'transfer.pane.explain' => 'Copy your sources, keys and preferences to another device on the same Wi-Fi, so you do not have to type them again. It goes straight from one device to the other, encrypted with a code that only the two screens share, and the receiving device asks before it saves anything.',
			'transfer.pane.notCopied' => 'Not copied: Plex (link it on the other device with its own code), watch history, favourites, and the consent you gave for Advanced sources and AI features, which each device asks for itself.',
			'transfer.pane.receive' => 'Receive from another device',
			'transfer.pane.send' => 'Send to another device',
			'transfer.notes.aiLocal' => 'Your AI provider runs on this device, so it is not sent. Set it up again there with this device\'s address on your network.',
			'transfer.notes.xtreamHidden' => 'The IPTV accounts are saved but hidden. Turn on Advanced sources in Settings to use them.',
			'transfer.notes.aiAsks' => 'AI features will ask before they send anything to the provider.',
			'transfer.notes.partial' => ({required Object failed}) => 'Could not save: ${failed}. The rest was saved.',
			'transfer.send.cannotRead' => ({required Object error}) => 'Could not read this device\'s settings: ${error}',
			'transfer.send.askTitle' => ({required Object host}) => 'Send to ${host}?',
			'transfer.send.askBody' => ({required Object summary}) => 'A device on your network scanned this code and is asking for:\n\n${summary}\n\nOnly agree if you just asked for this on that device.',
			'transfer.send.notNow' => 'Not now',
			'transfer.send.send' => 'Send',
			'transfer.send.title' => 'Send settings',
			'transfer.send.reading' => 'Reading your settings…',
			'transfer.send.sending' => 'Sending. The other device will ask before it saves anything.',
			'transfer.send.explain' => 'Copies these to another device on the same Wi-Fi, so you do not have to type them again. It goes straight there and is encrypted; nothing passes through us.',
			'transfer.send.nothing' => 'There is nothing set up on this device to send yet.',
			'transfer.send.proceed' => 'Continue',
			'transfer.send.showInstead' => 'Show a code instead',
			'transfer.send.typeInstead' => 'Type the code instead',
			'transfer.send.scanInstructions' => 'On the other device, open Settings, Move to another device, and choose Receive. Point the camera at the code it shows.',
			'transfer.send.showInstructions' => 'On the other device, open Settings, Move to another device, and choose Receive, then Scan its code and point its camera here. You will be asked before anything is sent.',
			'transfer.send.typeInstructions' => 'On the other device, open Settings, Move to another device, and choose Receive. Then enter what it shows.',
			'transfer.send.sent' => 'Sent. The other device has saved your settings.',
			'transfer.item.preferences' => 'Preferences',
			'transfer.item.preferencesSub' => 'Playback and subtitle choices, hidden words and library placement.',
			'transfer.item.xtream' => 'IPTV accounts',
			'transfer.item.xtreamSub' => 'Logins and the categories and channels you chose.',
			'transfer.item.smb' => 'Network shares',
			'transfer.item.smbSub' => 'SMB shares and their passwords.',
			'transfer.item.tmdb' => 'TMDB key',
			'transfer.item.tmdbSub' => 'Your own key for genre, rating and language filters.',
			'transfer.item.ai' => 'AI provider',
			'transfer.item.aiSub' => 'The provider, its model and your key.',
			'transfer.item.settings' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} setting', other: '${n} settings', ), 
			'transfer.item.accounts' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} account', other: '${n} accounts', ), 
			'transfer.item.shares' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} share', other: '${n} shares', ), 
			'transfer.item.notBundle' => 'That was not a settings bundle.',
			'transfer.item.newer' => 'That bundle is from a newer version of the app. Update this device and try again.',
			'transfer.client.declined' => 'The other device did not accept the settings.',
			'transfer.client.wrongCode' => 'The code was not right. Check it against the other screen.',
			'transfer.client.used' => 'The other device already received something. Open Receive again there for a fresh code.',
			'transfer.client.tooBig' => 'That was too much to send.',
			'transfer.client.unreadable' => 'The other device could not read that.',
			'transfer.client.unexpected' => ({required Object status}) => 'The other device answered unexpectedly (${status}).',
			'transfer.client.refusedToSend' => 'The other device did not agree to send its settings.',
			'transfer.client.busy' => 'The other device is already answering someone else. Ask it for a fresh code.',
			'transfer.client.unreachable' => ({required Object address}) => 'Could not reach ${address}. Both devices need to be on the same Wi-Fi, and the other one has to still be showing its code.',
			'transfer.client.dropped' => 'The connection dropped part-way.',
			'transfer.client.noAnswer' => ({required Object address}) => 'No answer from ${address}. Check the other screen.',
			_ => null,
		};
	}
}
