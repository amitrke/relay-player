///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsDe extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsDe({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.de,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <de>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsDe _root = this; // ignore: unused_field

	@override 
	TranslationsDe $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsDe(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$common$de common = _Translations$common$de._(_root);
	@override late final _Translations$player$de player = _Translations$player$de._(_root);
	@override Map<String, String> get languages => {
		'en': 'Englisch',
		'es': 'Spanisch',
		'fr': 'Französisch',
		'de': 'Deutsch',
		'it': 'Italienisch',
		'pt': 'Portugiesisch',
		'nl': 'Niederländisch',
		'sv': 'Schwedisch',
		'no': 'Norwegisch',
		'da': 'Dänisch',
		'fi': 'Finnisch',
		'pl': 'Polnisch',
		'cs': 'Tschechisch',
		'hu': 'Ungarisch',
		'ro': 'Rumänisch',
		'el': 'Griechisch',
		'ru': 'Russisch',
		'uk': 'Ukrainisch',
		'tr': 'Türkisch',
		'ar': 'Arabisch',
		'he': 'Hebräisch',
		'hi': 'Hindi',
		'bn': 'Bengalisch',
		'pa': 'Panjabi',
		'ta': 'Tamil',
		'te': 'Telugu',
		'ur': 'Urdu',
		'th': 'Thailändisch',
		'vi': 'Vietnamesisch',
		'id': 'Indonesisch',
		'zh': 'Chinesisch',
		'ja': 'Japanisch',
		'ko': 'Koreanisch',
	};
	@override late final _Translations$subtitleSize$de subtitleSize = _Translations$subtitleSize$de._(_root);
	@override late final _Translations$units$de units = _Translations$units$de._(_root);
	@override late final _Translations$downloads$de downloads = _Translations$downloads$de._(_root);
	@override late final _Translations$watchActions$de watchActions = _Translations$watchActions$de._(_root);
	@override late final _Translations$show$de show = _Translations$show$de._(_root);
	@override late final _Translations$shell$de shell = _Translations$shell$de._(_root);
	@override late final _Translations$resume$de resume = _Translations$resume$de._(_root);
	@override late final _Translations$library$de library = _Translations$library$de._(_root);
	@override late final _Translations$liveTv$de liveTv = _Translations$liveTv$de._(_root);
	@override late final _Translations$ai$de ai = _Translations$ai$de._(_root);
	@override late final _Translations$search$de search = _Translations$search$de._(_root);
	@override late final _Translations$settings$de settings = _Translations$settings$de._(_root);
	@override late final _Translations$onboarding$de onboarding = _Translations$onboarding$de._(_root);
	@override late final _Translations$addSource$de addSource = _Translations$addSource$de._(_root);
	@override late final _Translations$plex$de plex = _Translations$plex$de._(_root);
	@override late final _Translations$local$de local = _Translations$local$de._(_root);
	@override late final _Translations$smb$de smb = _Translations$smb$de._(_root);
	@override late final _Translations$xtream$de xtream = _Translations$xtream$de._(_root);
	@override late final _Translations$transfer$de transfer = _Translations$transfer$de._(_root);
	@override late final _Translations$mediaBrowser$de mediaBrowser = _Translations$mediaBrowser$de._(_root);
	@override late final _Translations$trackers$de trackers = _Translations$trackers$de._(_root);
	@override late final _Translations$seerr$de seerr = _Translations$seerr$de._(_root);
}

// Path: common
class _Translations$common$de extends Translations$common$en {
	_Translations$common$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get back => 'Zurück';
	@override String get tryAgain => 'Erneut versuchen';
	@override String get cancel => 'Abbrechen';
	@override String get noDrm => 'Kein DRM. Geschützte kommerzielle Kataloge wie Netflix oder Disney+ können nicht abgespielt werden.';
}

// Path: player
class _Translations$player$de extends Translations$player$en {
	_Translations$player$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get shareGone => 'Diese Freigabe ist nicht mehr eingerichtet.';
	@override String get shareFileGone => 'Diese Datei liegt nicht mehr auf der Freigabe.';
	@override String get deviceFileGone => 'Diese Datei ist nicht mehr auf diesem Gerät.';
	@override String get lineGone => 'Dieser Zugang ist nicht mehr eingerichtet.';
	@override String get untitledVideo => 'Video';
	@override String get untitledEpisode => 'Folge';
	@override String get untitledFilm => 'Film';
	@override String get untitledLive => 'Live';
	@override String get channelFroze => 'Dieser Sender ist stehen geblieben und nicht zurückgekommen.';
	@override String get channelNotResponding => 'Dieser Sender antwortet nicht. Die Listen eines Panels sind der Wirklichkeit oft voraus, also versuch einen anderen oder denselben noch einmal.';
	@override String get didNotStart => 'Die Wiedergabe ist nicht gestartet. Der Server ist vielleicht ausgelastet, oder die Datei muss transkodiert werden, was noch nicht unterstützt wird.';
	@override String get released => 'Angehalten, während die App im Hintergrund war, damit die Verbindung für andere Geräte frei ist.';
	@override String get rejoin => 'Wieder einsteigen';
	@override String get live => 'LIVE';
	@override String skipBack({required Object seconds}) => '${seconds} Sekunden zurück';
	@override String skipForward({required Object seconds}) => '${seconds} Sekunden vor';
	@override String get pause => 'Pause';
	@override String get play => 'Abspielen';
	@override String get tracks => 'Audio und Untertitel';
	@override String get audio => 'Audio';
	@override String get subtitles => 'Untertitel';
	@override String get off => 'Aus';
	@override String trackNumber({required Object n}) => 'Spur ${n}';
}

// Path: subtitleSize
class _Translations$subtitleSize$de extends Translations$subtitleSize$en {
	_Translations$subtitleSize$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get small => 'Klein';
	@override String get medium => 'Mittel';
	@override String get large => 'Groß';
}

// Path: units
class _Translations$units$de extends Translations$units$en {
	_Translations$units$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String minutes({required Object m}) => '${m} Min.';
	@override String hours({required Object h}) => '${h} Std.';
	@override String hoursMinutes({required Object h, required Object m}) => '${h} Std. ${m} Min.';
	@override String minutesLeft({required Object m}) => 'Noch ${m} Min.';
	@override String seconds({required Object s}) => '${s} s';
}

// Path: downloads
class _Translations$downloads$de extends Translations$downloads$en {
	_Translations$downloads$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get empty => 'Noch nichts heruntergeladen. Halte einen Film oder eine Folge aus deiner Plex-Mediathek gedrückt und wähle Herunterladen, dann schau es hier ohne Netz.';
	@override String get title => 'Downloads';
	@override String summary({required num n, required Object size}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${n} Eintrag · ${size} auf diesem Gerät',
		other: '${n} Einträge · ${size} auf diesem Gerät',
	);
	@override String pendingWatches({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '1 Wiedergabe von hier wartet darauf, an Plex gesendet zu werden.',
		other: '${n} Wiedergaben von hier warten darauf, an Plex gesendet zu werden.',
	);
	@override String get foregroundOnly => 'Downloads laufen weiter, solange die App geöffnet ist. Beim Schließen werden sie pausiert, und nichts bereits Gespeichertes geht verloren.';
	@override String downloadingBytes({required Object received}) => 'Wird heruntergeladen, ${received}';
	@override String downloadingPercent({required Object percent, required Object received, required Object total}) => 'Wird heruntergeladen: ${percent} % · ${received} von ${total}';
	@override String get queued => 'Wartet, bis es an der Reihe ist';
	@override String get paused => 'Pausiert';
	@override String pausedAt({required Object percent}) => 'Bei ${percent} % pausiert · zum Fortsetzen auswählen';
	@override String failed({required Object error}) => '${error} Zum erneuten Versuchen auswählen.';
	@override String get failedUnknown => 'Es wurde nicht fertig.';
	@override String get deleteTitle => 'Diesen Download löschen?';
	@override String get cancelTitle => 'Diesen Download abbrechen?';
	@override String removeBody({required Object title}) => '„${title}“ wird von diesem Gerät entfernt. Auf deinem Plex-Server bleibt es erhalten.';
	@override String removeBodyFreeing({required Object title, required Object size}) => '„${title}“ wird von diesem Gerät entfernt, dadurch werden ${size} frei. Auf deinem Plex-Server bleibt es erhalten.';
	@override String get keepIt => 'Behalten';
	@override String get delete => 'Löschen';
	@override late final _Translations$downloads$errors$de errors = _Translations$downloads$errors$de._(_root);
	@override late final _Translations$downloads$rule$de rule = _Translations$downloads$rule$de._(_root);
}

// Path: watchActions
class _Translations$watchActions$de extends Translations$watchActions$en {
	_Translations$watchActions$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get everyEpisode => ' (alle Folgen)';
	@override String markWatched({required Object scope}) => 'Als gesehen markieren${scope}';
	@override String markUnwatched({required Object scope}) => 'Als ungesehen markieren${scope}';
	@override String get download => 'Auf dieses Gerät herunterladen';
	@override String get deleteDownload => 'Download löschen';
	@override String get cancelDownload => 'Download abbrechen';
	@override String get removeFavourite => 'Aus Favoriten entfernen';
	@override String get addFavourite => 'Zu Favoriten hinzufügen';
	@override String get removeResume => 'Aus Weiterschauen entfernen';
	@override String get downloading => 'Wird heruntergeladen. Siehe Tab Downloads.';
	@override String get markedOffline => 'Hier als gesehen markiert. Plex erfährt es, sobald es erreichbar ist.';
	@override String get plexRefused => 'Plex hat das nicht angenommen. Der Server ist vielleicht offline.';
}

// Path: show
class _Translations$show$de extends Translations$show$en {
	_Translations$show$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get noEpisodes => 'Diese Serie hat keine Folgen auf dem Server.';
}

// Path: shell
class _Translations$shell$de extends Translations$shell$en {
	_Translations$shell$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get library => 'Mediathek';
	@override String get search => 'Suche';
	@override String get downloads => 'Downloads';
	@override String get settings => 'Einstellungen';
	@override String get exitTitle => 'Subnext Player beenden?';
	@override String get exit => 'Beenden';
	@override String get stay => 'Bleiben';
}

// Path: resume
class _Translations$resume$de extends Translations$resume$en {
	_Translations$resume$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get upNext => 'Als Nächstes';
	@override String get title => 'Weiterschauen';
	@override String get remove => 'Aus Weiterschauen entfernen';
}

// Path: library
class _Translations$library$de extends Translations$library$en {
	_Translations$library$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _Translations$library$placement$de placement = _Translations$library$placement$de._(_root);
	@override late final _Translations$library$tab$de tab = _Translations$library$tab$de._(_root);
	@override String serverTimeout({required Object server, required Object seconds}) => '${server} hat nicht innerhalb von ${seconds} Sekunden geantwortet. Er ist vielleicht im Ruhezustand oder nicht im Netzwerk.';
	@override String get allWatched => 'In Filme ist alles gesehen.';
	@override String get showAll => 'Alle anzeigen';
	@override String get noSources => 'Noch keine Quellen verbunden.';
	@override String nothingIn({required Object tab}) => 'Noch nichts in ${tab}.';
	@override String get addSource => 'Quelle hinzufügen';
	@override String sortFiltered({required Object sort}) => '${sort} · Ungesehen';
	@override String get sortBy => 'Sortieren nach';
	@override String get unwatchedOnly => 'Nur ungesehene';
	@override late final _Translations$library$shelf$de shelf = _Translations$library$shelf$de._(_root);
	@override late final _Translations$library$sort$de sort = _Translations$library$sort$de._(_root);
	@override late final _Translations$library$tile$de tile = _Translations$library$tile$de._(_root);
}

// Path: liveTv
class _Translations$liveTv$de extends Translations$liveTv$en {
	_Translations$liveTv$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _Translations$liveTv$group$de group = _Translations$liveTv$group$de._(_root);
	@override String get noPanel => 'Keine Playlist und kein Panel eingerichtet.';
	@override String get addOne => 'Hinzufügen';
	@override String get noCategories => 'Noch keine Kategorien ausgewählt.\nPanels haben Zehntausende Sender, deshalb lädt Subnext Player nur die, die du auswählst.';
	@override String get chooseCategories => 'Kategorien auswählen';
	@override String get noChannels => 'Diese Kategorien haben keine Sender geliefert.';
	@override String noMatch({required Object query}) => 'Kein Sender passt zu „${query}“.';
	@override String searchHint({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${n} Sender durchsuchen',
		other: '${n} Sender durchsuchen',
	);
	@override String get all => 'Alle';
}

// Path: ai
class _Translations$ai$de extends Translations$ai$en {
	_Translations$ai$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _Translations$ai$picks$de picks = _Translations$ai$picks$de._(_root);
	@override late final _Translations$ai$search$de search = _Translations$ai$search$de._(_root);
	@override String get presetOther => 'Andere';
	@override String get hintOpenRouter => 'Modell-IDs stehen unter openrouter.ai/models. Kostenlose enden auf ":free".';
	@override String get hintOllama => 'Verwende die Adresse deines Computers in diesem Netzwerk, zum Beispiel http://192.168.1.20:11434/v1. Nichts verlässt dein Netzwerk.';
	@override String get hintCustom => 'Jeder Dienst, der das Chat-Format von OpenAI spricht.';
	@override late final _Translations$ai$feature$de feature = _Translations$ai$feature$de._(_root);
	@override late final _Translations$ai$errors$de errors = _Translations$ai$errors$de._(_root);
	@override String consentTitle({required Object provider}) => 'Daten an ${provider} senden?';
	@override String consentBody({required Object feature, required Object provider, required Object sends}) => '${feature} sendet Folgendes an ${provider}: ${sends}';
	@override String get consentTail => 'Es geht direkt von diesem Gerät dorthin, nie über uns. Du kannst das in Einstellungen, KI-Funktionen wieder ausschalten.';
	@override String get notNow => 'Nicht jetzt';
	@override String get allow => 'Erlauben';
}

// Path: search
class _Translations$search$de extends Translations$search$en {
	_Translations$search$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _Translations$search$filters$de filters = _Translations$search$filters$de._(_root);
	@override String get hint => 'Deine Quellen durchsuchen';
	@override String get prompt => 'Durchsuche Filme und Serien auf deinem Server.';
	@override String get keepTyping => 'Weiter tippen…';
	@override String noMatch({required Object query}) => 'Nichts passt zu „${query}“.';
	@override String get backToResults => 'Zurück zu den Ergebnissen';
	@override String get askAi => 'KI fragen';
	@override String get becauseYouWatched => 'Weil du gesehen hast: ';
}

// Path: settings
class _Translations$settings$de extends Translations$settings$en {
	_Translations$settings$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _Translations$settings$about$de about = _Translations$settings$about$de._(_root);
	@override late final _Translations$settings$privacy$de privacy = _Translations$settings$privacy$de._(_root);
	@override late final _Translations$settings$playback$de playback = _Translations$settings$playback$de._(_root);
	@override late final _Translations$settings$metadata$de metadata = _Translations$settings$metadata$de._(_root);
	@override late final _Translations$settings$ai$de ai = _Translations$settings$ai$de._(_root);
	@override late final _Translations$settings$appearance$de appearance = _Translations$settings$appearance$de._(_root);
	@override late final _Translations$settings$section$de section = _Translations$settings$section$de._(_root);
	@override late final _Translations$settings$advanced$de advanced = _Translations$settings$advanced$de._(_root);
	@override late final _Translations$settings$sources$de sources = _Translations$settings$sources$de._(_root);
}

// Path: onboarding
class _Translations$onboarding$de extends Translations$onboarding$en {
	_Translations$onboarding$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get tagline => 'Spiel ab, was deine verbundenen Quellen bieten.';
	@override String get blurb => 'Subnext Player spielt aus Quellen ab, die du selbst verbindest: einem Plex-Server, einem NAS zu Hause oder lokalen Dateien, oder optional einem IPTV-Anbieter oder einer Playlist. Wir hosten keine Inhalte.';
	@override String get localDesktop => 'Dateien auf diesem PC oder ein Ordner auf einem NAS zu Hause oder einer SMB-Freigabe.';
	@override String get localTv => 'Ein Ordner auf einem NAS zu Hause oder einer SMB-Freigabe.';
	@override String get local => 'Videos auf diesem Gerät oder ein Ordner auf einem NAS zu Hause oder einer SMB-Freigabe.';
	@override String get plexTv => 'Melde dich auf diesem Fernseher mit deinem eigenen Konto an.';
	@override String get plex => 'Deine persönliche Mediathek, mit deinem eigenen Konto.';
	@override String get advancedTv => 'Standardmäßig aus. In den Einstellungen einschalten.';
	@override String get advanced => 'Standardmäßig aus. In den Einstellungen einschalten, um einen IPTV-Anbieter oder eine Playlist zu nutzen.';
	@override String get localTitle => 'Lokal & Netzwerk';
	@override String get advancedTitle => 'Erweiterte Quellen';
	@override String get addFirst => 'Erste Quelle hinzufügen';
	@override String get notNow => 'Nicht jetzt';
	@override String get connect => 'Quelle verbinden';
	@override String get addSource => 'Quelle hinzufügen';
	@override String get okKey => 'OK';
	@override String get toSelect => 'zum Auswählen';
}

// Path: addSource
class _Translations$addSource$de extends Translations$addSource$en {
	_Translations$addSource$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get privacy => 'Zugangsdaten bleiben auf diesem Gerät. Nichts wird an uns gesendet: Es gibt kein Konto und keinen Server dazwischen.';
	@override late final _Translations$addSource$kind$de kind = _Translations$addSource$kind$de._(_root);
	@override String get copyFromDevice => 'Von einem anderen Gerät kopieren';
	@override String get copyFromDeviceSub => 'Schon auf deinem Handy eingerichtet? Schick es hierher, statt alles neu einzutippen.';
	@override String get title => 'Quelle hinzufügen';
	@override String get advanced => 'Erweiterte Quellen';
	@override String get or => 'Oder';
	@override String get advancedHintLead => 'Suchst du einen IPTV-Anbieter oder eine Playlist? Schalte ';
	@override String get advancedHintTail => ' in den Einstellungen ein.';
	@override String get sourceType => 'Art der Quelle';
	@override String get plexRail => 'Mit einem Code verknüpfen';
	@override String get pcFiles => 'Dateien auf diesem PC';
	@override String get pcFilesSub => 'Ordner auswählen';
	@override String get smbRail => 'NAS oder Windows-Freigabe';
	@override String get copyRail => 'Vom Handy aus senden';
	@override String get keystore => 'Zugangsdaten werden im Schlüsselspeicher des Geräts abgelegt, nie in der Datenbank der App.';
	@override String get pick => 'Wähle zum Start eine Art von Quelle.';
}

// Path: plex
class _Translations$plex$de extends Translations$plex$en {
	_Translations$plex$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get connected => 'Plex verbunden.';
	@override String connectedTo({required Object name}) => 'Mit ${name} verbunden.';
	@override String get opening => 'Verbunden. Deine Mediathek wird geöffnet…';
	@override String get connect => 'Mit Plex verbinden';
	@override String get explain => 'Subnext Player spielt ab, was dein eigener Plex-Server bereits hat. Es wird nichts hochgeladen, und deine Kontodaten erreichen niemanden außer Plex.';
	@override String get contacting => 'Plex wird kontaktiert…';
	@override String get enterCode => 'Öffne auf einem beliebigen Gerät plex.tv/link und gib ein:';
	@override String get waiting => 'Warte auf Freigabe…';
	@override String get copyCode => 'Code kopieren';
	@override String get chooseServer => 'Server auswählen';
	@override String get allConnected => 'Alle Server dieses Kontos sind bereits verbunden.';
	@override String get yourServers => 'Deine Server';
	@override String get sharedWithYou => 'Mit dir geteilt';
	@override String get connecting => 'Wird verbunden… das kann ein paar Sekunden dauern';
	@override String get offline => 'Offline';
	@override String get relayOnly => 'Nur über Plex Relay, die Wiedergabe kann eingeschränkt sein';
	@override String get codeExpired => 'Dieser Code ist abgelaufen. Versuch es erneut.';
	@override String get noServers => 'Dieses Konto hat keine Plex-Server.';
	@override late final _Translations$plex$errors$de errors = _Translations$plex$errors$de._(_root);
}

// Path: local
class _Translations$local$de extends Translations$local$en {
	_Translations$local$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String noAccess({required Object where}) => 'Subnext Player kann deine Videos ohne Medienzugriff nicht sehen. Du kannst ihn in ${where} erteilen.';
	@override String get settingsIos => 'der App Einstellungen';
	@override String get settingsAndroid => 'den Android-Einstellungen';
	@override String get intro => 'Spiel Videos ab, die auf diesem Gerät gespeichert sind.\nSubnext Player fragt nur nach Zugriff auf Videos, nie auf alle Dateien.';
	@override String get allowAccess => 'Zugriff auf Videos erlauben';
	@override String get pickFolderInstead => 'Oder stattdessen einen Ordner wählen';
	@override String get addShare => 'Netzwerkfreigabe hinzufügen';
	@override String get shares => 'Netzwerkfreigaben';
	@override String get pickedFolders => 'Ausgewählte Ordner';
	@override String get onDevice => 'Auf diesem Gerät';
	@override String get noVideos => 'Keine Videos auf diesem Gerät gefunden.';
	@override String get addFolderShort => 'Ordner hinzufügen';
	@override String get addShareShort => 'Freigabe hinzufügen';
	@override String get scanDevice => 'Dieses Gerät durchsuchen';
	@override String get forgetFolder => 'Diesen Ordner vergessen';
	@override String get folder => 'Ordner';
	@override String safUnreadable({required Object error}) => 'Dieser Ordner ist nicht mehr lesbar. Vielleicht hat Android die Berechtigung entzogen, also entferne ihn und wähle ihn erneut.\n\n${error}';
	@override String get safEmpty => 'Hier sind keine Videos oder Unterordner.';
}

// Path: smb
class _Translations$smb$de extends Translations$smb$en {
	_Translations$smb$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String connectFailed({required Object error}) => 'Verbindung fehlgeschlagen: ${error}';
	@override String get title => 'Netzwerkfreigabe hinzufügen';
	@override String get explain => 'Ein NAS oder ein freigegebener Ordner auf einem anderen Computer in deinem Netzwerk.';
	@override String get host => 'Serveradresse';
	@override String get hostHint => 'z. B. nas';
	@override String get username => 'Benutzername';
	@override String get password => 'Passwort';
	@override String get domain => 'Domäne (optional)';
	@override String get name => 'Name (optional)';
	@override String get connectAndAdd => 'Verbinden und hinzufügen';
	@override String get gone => 'Diese Freigabe ist nicht mehr eingerichtet.';
	@override String unreachable({required Object error}) => 'Diese Freigabe war nicht erreichbar. Der Server ist vielleicht im Ruhezustand oder nicht im Netzwerk.\n\n${error}';
	@override String get empty => 'Hier sind keine Videos oder Ordner.';
}

// Path: xtream
class _Translations$xtream$de extends Translations$xtream$en {
	_Translations$xtream$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get lineGone => 'Dieser Zugang ist nicht mehr eingerichtet.';
	@override late final _Translations$xtream$catalogue$de catalogue = _Translations$xtream$catalogue$de._(_root);
	@override late final _Translations$xtream$errors$de errors = _Translations$xtream$errors$de._(_root);
	@override String get everythingElse => 'Alles andere';
	@override late final _Translations$xtream$series$de series = _Translations$xtream$series$de._(_root);
	@override String get remove => 'Entfernen';
	@override String get add => 'Playlist oder Panel hinzufügen';
	@override late final _Translations$xtream$addLine$de addLine = _Translations$xtream$addLine$de._(_root);
	@override late final _Translations$xtream$picker$de picker = _Translations$xtream$picker$de._(_root);
	@override late final _Translations$xtream$channels$de channels = _Translations$xtream$channels$de._(_root);
	@override late final _Translations$xtream$hidden$de hidden = _Translations$xtream$hidden$de._(_root);
}

// Path: transfer
class _Translations$transfer$de extends Translations$transfer$en {
	_Translations$transfer$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get noNetwork => 'Dieses Gerät ist in keinem WLAN- oder Ethernet-Netzwerk. Verbinde es mit demselben Netzwerk wie das andere Gerät und versuch es erneut.';
	@override String cannotListen({required Object error}) => 'Empfang konnte nicht gestartet werden: ${error}';
	@override String get expired => 'Dieser Code ist abgelaufen. Starte neu, um einen neuen zu bekommen.';
	@override String wentWrong({required Object error}) => 'Etwas ist schiefgelaufen: ${error}';
	@override String get wentWrongPlain => 'Etwas ist schiefgelaufen.';
	@override String get gettingReady => 'Wird vorbereitet…';
	@override String get waitingOther => 'Warte auf das andere Gerät…';
	@override String get copyCode => 'Code kopieren';
	@override String get scanInstead => 'Stattdessen seinen Code scannen';
	@override String get typeInstead => 'Stattdessen seinen Code eingeben';
	@override String get done => 'Fertig';
	@override String get close => 'Schließen';
	@override late final _Translations$transfer$receive$de receive = _Translations$transfer$receive$de._(_root);
	@override late final _Translations$transfer$pairing$de pairing = _Translations$transfer$pairing$de._(_root);
	@override late final _Translations$transfer$pane$de pane = _Translations$transfer$pane$de._(_root);
	@override late final _Translations$transfer$notes$de notes = _Translations$transfer$notes$de._(_root);
	@override late final _Translations$transfer$send$de send = _Translations$transfer$send$de._(_root);
	@override late final _Translations$transfer$item$de item = _Translations$transfer$item$de._(_root);
	@override late final _Translations$transfer$client$de client = _Translations$transfer$client$de._(_root);
}

// Path: mediaBrowser
class _Translations$mediaBrowser$de extends Translations$mediaBrowser$en {
	_Translations$mediaBrowser$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _Translations$mediaBrowser$errors$de errors = _Translations$mediaBrowser$errors$de._(_root);
	@override String get title => 'Mit Jellyfin oder Emby verbinden';
	@override String get explain => 'Subnext Player spielt ab, was dein eigener Server bereits hat. Deine Anmeldung bleibt auf diesem Gerät und erreicht niemanden außer deinem Server.';
	@override String get address => 'Serveradresse';
	@override String get addressHint => 'z. B. 192.168.1.20:8096';
	@override String get find => 'Server suchen';
	@override String get finding => 'Server wird gesucht…';
	@override String found({required Object name, required Object kind, required Object version}) => '${name} · ${kind} ${version}';
	@override String get username => 'Benutzername';
	@override String get password => 'Passwort';
	@override String get signIn => 'Anmelden';
	@override String get signingIn => 'Wird angemeldet…';
	@override String get useQuickConnect => 'Stattdessen Quick Connect verwenden';
	@override String get usePassword => 'Stattdessen Benutzername und Passwort verwenden';
	@override String get quickConnectExplain => 'Öffne auf einem Handy oder Computer, der schon bei Jellyfin angemeldet ist, dein Profil, Quick Connect, und gib ein:';
	@override String get waiting => 'Warte auf Freigabe…';
	@override String get otherAddress => 'Andere Adresse verwenden';
	@override String connected({required Object name}) => 'Mit ${name} verbunden.';
}

// Path: trackers
class _Translations$trackers$de extends Translations$trackers$en {
	_Translations$trackers$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _Translations$trackers$errors$de errors = _Translations$trackers$errors$de._(_root);
	@override String get malCaught => 'Angemeldet. Du kannst dieses Fenster schließen und zu Subnext Player zurückkehren.';
	@override String get intro => 'Sende, was du auf deinen eigenen Servern zu Ende schaust, an einen Verlaufsdienst. Nichts aus IPTV wird gesendet, und nichts geht an uns.';
	@override String get animeNote => 'AniList und MyAnimeList bekommen nur Titel, die dein Server als Anime kennzeichnet, gesucht nach Namen.';
	@override String signedInAs({required Object name}) => 'Angemeldet als ${name}';
	@override String get signedIn => 'Angemeldet';
	@override String get notConnected => 'Nicht verbunden';
	@override String get signIn => 'Anmelden';
	@override String get signOut => 'Abmelden';
	@override String pending({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '1 Wiedergabe wartet darauf, gesendet zu werden.',
		other: '${n} Wiedergaben warten darauf, gesendet zu werden.',
	);
	@override String consentTitle({required Object service}) => 'Deine Wiedergaben an ${service} senden?';
	@override String consentBody({required Object service}) => 'Wenn du einen Film oder eine Folge von deinem eigenen Plex-, Jellyfin- oder Emby-Server zu Ende schaust, sendet Subnext Player an ${service} den Titel, das Jahr, die IMDb-, TMDB- oder TVDB-ID und wann du es gesehen hast. Es geht direkt von diesem Gerät an ${service}, nie über uns. Nichts aus IPTV wird gesendet. Du kannst dich jederzeit unter Einstellungen, Wiedergabe-Tracking abmelden.';
	@override String consentAnime({required Object service}) => 'An ${service} gehen nur Titel, die dein Server als Anime kennzeichnet, und sie werden über eine Suche nach ihrem Namen bei ${service} gefunden.';
	@override String get agree => 'Weiter';
	@override String get notNow => 'Nicht jetzt';
	@override String signInTitle({required Object service}) => 'Bei ${service} anmelden';
	@override String deviceCodeExplain({required Object url}) => 'Öffne auf einem beliebigen Gerät ${url} und gib ein:';
	@override String get waiting => 'Warte auf Freigabe…';
	@override String browserExplain({required Object service}) => 'Öffne diese Adresse in einem Browser, melde dich bei ${service} an und erlaube Subnext Player. Füge dann unten ein, was ${service} dir gibt.';
	@override String get anilistPaste => 'AniList zeigt nach der Freigabe ein langes Token an. Kopiere es vollständig.';
	@override String get malPaste => 'Auf diesem Gerät schließt die App die Anmeldung selbst ab. War der Browser woanders, endet er auf einer Seite, die nicht lädt: Kopiere deren vollständige Adresse.';
	@override String get tvHint => 'Auf einem Fernseher melde dich auf dem Handy an und übertrage es mit Auf ein anderes Gerät übertragen hierher.';
	@override String get pasteLabel => 'Hier einfügen';
	@override String get finish => 'Anmeldung abschließen';
	@override String get copyAddress => 'Adresse kopieren';
	@override String connected({required Object service}) => 'Mit ${service} verbunden.';
}

// Path: seerr
class _Translations$seerr$de extends Translations$seerr$en {
	_Translations$seerr$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _Translations$seerr$errors$de errors = _Translations$seerr$errors$de._(_root);
	@override String get intro => 'Verbinde deinen eigenen Overseerr-, Jellyseerr- oder Seerr-Server, um Filme und Serien anzufragen, die deine Mediathek noch nicht hat. Anfragen gehen an deinen Server und nirgendwo sonst; wer ihn betreibt, entscheidet über den Rest.';
	@override String get address => 'Serveradresse';
	@override String get addressHint => 'z. B. 192.168.1.20:5055';
	@override String get find => 'Server suchen';
	@override String get withPlex => 'Mit meinem Plex-Konto anmelden';
	@override String get withPassword => 'Mit Benutzername und Passwort anmelden';
	@override String get withKey => 'API-Schlüssel verwenden';
	@override String get username => 'Benutzername oder E-Mail';
	@override String get password => 'Passwort';
	@override String get apiKey => 'API-Schlüssel';
	@override String get keyNote => 'Ein API-Schlüssel handelt als Administrator des Servers, Anfragen damit laufen also nicht unter deinem Namen. Melde dich lieber an.';
	@override String get connect => 'Verbinden';
	@override String get connecting => 'Wird verbunden…';
	@override String connected({required Object title, required Object name}) => 'Mit ${title} verbunden als ${name}';
	@override String get disconnect => 'Trennen';
	@override String get myRequests => 'Deine letzten Anfragen';
	@override String get none => 'Noch keine Anfragen.';
	@override String get statusPending => 'Wartet auf Freigabe';
	@override String get statusApproved => 'Freigegeben';
	@override String get statusDeclined => 'Abgelehnt';
	@override String get statusAvailable => 'Verfügbar';
	@override String rowTitle({required Object title}) => 'Bei ${title} anfragen';
	@override String get requested => 'Angefragt';
	@override String get partial => 'Teilweise verfügbar';
	@override String askTitle({required Object title}) => '${title} anfragen?';
	@override String askMovie({required Object server}) => 'Damit bittest du ${server}, den Film hinzuzufügen. Wer ihn betreibt, entscheidet darüber.';
	@override String askShow({required Object server}) => 'Damit bittest du ${server}, alle Staffeln hinzuzufügen. Wer ihn betreibt, entscheidet darüber.';
	@override String get request => 'Anfragen';
	@override String sent({required Object title}) => '${title} angefragt.';
}

// Path: downloads.errors
class _Translations$downloads$errors$de extends Translations$downloads$errors$en {
	_Translations$downloads$errors$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get serverNotConnected => 'Dieser Server ist nicht verbunden. Verbinde ihn in den Einstellungen neu und setze dann fort.';
	@override String get sizeMismatch => 'Die Datei hat nicht die Größe, die der Server gemeldet hat. Versuch es erneut.';
	@override String get cannotWrite => 'Die Datei konnte nicht geschrieben werden. Vielleicht ist der Speicher des Geräts voll.';
	@override String get changedOnServer => 'Die Datei hat sich auf dem Server geändert. Starte den Download neu.';
	@override String get refused => 'Der Server erlaubt diesem Gerät nicht, das herunterzuladen.';
	@override String status({required Object code}) => 'Der Server hat mit ${code} geantwortet.';
	@override String get dropped => 'Die Verbindung ist zwischendurch abgebrochen. Zum Weitermachen fortsetzen.';
	@override String get unreachable => 'Der Server war nicht erreichbar. Prüfe die Verbindung und setze fort.';
	@override String get timeout => 'Der Server hat zu lange nicht geantwortet.';
}

// Path: downloads.rule
class _Translations$downloads$rule$de extends Translations$downloads$rule$en {
	_Translations$downloads$rule$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get off => 'Folgen heruntergeladen halten';
	@override String keeping({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: 'Die nächste Folge bleibt heruntergeladen',
		other: 'Die nächsten ${n} Folgen bleiben heruntergeladen',
	);
	@override String get explain => 'Lädt die nächsten ungesehenen Folgen herunter und füllt sie beim Anschauen nach, solange die App geöffnet ist. Gesehene Folgen, die es heruntergeladen hat, werden entfernt.';
	@override String get choiceOff => 'Aus';
	@override String choice({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: 'Nächste Folge',
		other: 'Nächste ${n} Folgen',
	);
}

// Path: library.placement
class _Translations$library$placement$de extends Translations$library$placement$en {
	_Translations$library$placement$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get movies => 'Filme';
	@override String get series => 'Serien';
	@override String get hidden => 'Ausgeblendet';
}

// Path: library.tab
class _Translations$library$tab$de extends Translations$library$tab$en {
	_Translations$library$tab$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get movies => 'Filme';
	@override String get series => 'Serien';
	@override String get localNetwork => 'Lokal & Netzwerk';
	@override String get liveTv => 'Live-TV';
	@override String get emptyMovies => 'Keine Filme auf diesem Server.';
	@override String get emptySeries => 'Keine Serien auf diesem Server.';
	@override String get emptyLocalNetwork => 'Noch keine Ordner oder Netzwerkfreigaben.\nGerätespeicher und SMB-Freigaben lassen sich in dieser Version nicht verbinden.';
	@override String get emptyLiveTv => 'Keine Playlist und kein Panel eingerichtet.\nFüge eines in den Einstellungen hinzu, sobald Erweiterte Quellen aktiviert ist.';
	@override String countMovies({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${n} Film',
		other: '${n} Filme',
	);
	@override String countSeries({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${n} Serie',
		other: '${n} Serien',
	);
	@override String countItems({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${n} Eintrag',
		other: '${n} Einträge',
	);
	@override String countChannels({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${n} Sender',
		other: '${n} Sender',
	);
}

// Path: library.shelf
class _Translations$library$shelf$de extends Translations$library$shelf$en {
	_Translations$library$shelf$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get seeAll => 'Alle ansehen';
	@override String titles({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${n} Titel',
		other: '${n} Titel',
	);
	@override String get gone => 'Hier ist nichts mehr.';
}

// Path: library.sort
class _Translations$library$sort$de extends Translations$library$sort$en {
	_Translations$library$sort$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titel';
	@override String get recentlyAdded => 'Zuletzt hinzugefügt';
	@override String get year => 'Jahr';
	@override String get releaseDate => 'Erscheinungsdatum';
}

// Path: library.tile
class _Translations$library$tile$de extends Translations$library$tile$en {
	_Translations$library$tile$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get series => 'Serie';
	@override String get movie => 'Film';
	@override String get watched => 'Gesehen';
	@override String percentWatched({required Object percent}) => '${percent} % gesehen';
}

// Path: liveTv.group
class _Translations$liveTv$group$de extends Translations$liveTv$group$en {
	_Translations$liveTv$group$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get favourites => 'Favoriten';
	@override String numbered({required Object n}) => 'Kategorie ${n}';
	@override String get other => 'Sonstige';
}

// Path: ai.picks
class _Translations$ai$picks$de extends Translations$ai$picks$en {
	_Translations$ai$picks$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get yourProvider => 'deinen Anbieter';
	@override String get ask => 'Was soll ich schauen?';
	@override String askExplain({required Object provider}) => 'Lass ${provider} aus deiner eigenen Mediathek auswählen.';
	@override String get pickedBy => 'Für dich ausgewählt von ';
	@override String get updating => 'Wird aktualisiert';
	@override String get again => 'Noch mal';
	@override String get preparing => 'Deine Vorschläge werden vorbereitet...';
}

// Path: ai.search
class _Translations$ai$search$de extends Translations$ai$search$en {
	_Translations$ai$search$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String asking({required Object provider}) => '${provider} wird gefragt...';
	@override String searching({required Object searched, required Object covered}) => 'Deine Mediathek wird durchsucht... ${searched} von ${covered} Titeln';
	@override String get emptyLibrary => 'In deiner Mediathek gibt es noch nichts zu durchsuchen.';
	@override String notFound({required Object total}) => 'Das Modell hat unter ${total} Titeln nichts Passendes gefunden. Beschreib es mal anders.';
	@override String notFoundFirst({required Object covered, required Object total}) => 'Das Modell hat unter den ersten ${covered} von ${total} Titeln nichts Passendes gefunden. Beschreib es mal anders.';
	@override String stillSearching({required Object searched, required Object covered}) => 'Suche läuft noch: ${searched} von ${covered} Titeln';
	@override String searchedFirst({required Object covered, required Object total}) => 'Die ersten ${covered} von ${total} Titeln wurden durchsucht';
	@override String pickedFor({required Object provider, required Object query}) => 'Von ${provider} ausgewählt für „${query}“';
	@override String get searchAgain => 'Erneut suchen';
	@override String partsFailed({required Object failed, required Object parts}) => '${failed} von ${parts} Teilen konnten nicht durchsucht werden, daher wurde ein Teil deiner Mediathek nicht angesehen. Der Anbieter begrenzt vielleicht die Anfragen';
}

// Path: ai.feature
class _Translations$ai$feature$de extends Translations$ai$feature$en {
	_Translations$ai$feature$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get naturalSearch => 'Suche in natürlicher Sprache';
	@override String get naturalSearchSends => 'Dein Suchtext sowie die Titel und Jahre in deiner Mediathek.';
	@override String get naturalSearchTiming => 'Eine große Mediathek wird in mehreren Anfragen mit je einigen hundert Titeln gesendet, eine Suche stellt also mehr als eine.';
	@override String get recommendations => 'Empfehlungen';
	@override String get recommendationsSends => 'Die Filme, die du zuletzt gesehen hast, sowie Titel und Jahre dessen, was du in deiner Mediathek noch nicht gesehen hast.';
	@override String get recommendationsTiming => 'Vorschläge werden kurz nach dem Öffnen der App im Hintergrund vorbereitet, aber nur, wenn sich geändert hat, was du gesehen hast, oder sie älter als einen Tag sind, also nicht bei jedem Start.';
}

// Path: ai.errors
class _Translations$ai$errors$de extends Translations$ai$errors$en {
	_Translations$ai$errors$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get ranOutThinking => 'Dem Modell ist beim Nachdenken der Platz für die Antwort ausgegangen, und es hat nie geantwortet. Ein Modell, das nicht erst „nachdenkt“, funktioniert besser.';
	@override String get empty => 'Das Modell hat eine leere Antwort geschickt.';
	@override String rejectedKey({required Object suffix}) => 'Der Anbieter hat diesen Schlüssel abgelehnt${suffix}.';
	@override String noCredit({required Object suffix}) => 'Der Anbieter meldet, dass dieses Konto kein Guthaben mehr hat${suffix}.';
	@override String unknownModel({required Object suffix}) => 'Der Anbieter kennt dieses Modell oder diese Adresse nicht${suffix}.';
	@override String rateLimited({required Object suffix}) => 'Der Anbieter drosselt diesen Schlüssel. Versuch es gleich noch einmal${suffix}.';
	@override String serverError({required Object status, required Object suffix}) => 'Beim Anbieter ist ein Problem aufgetreten (HTTP ${status})${suffix}.';
	@override String get timeout => 'Der Anbieter hat zu lange nicht geantwortet.';
	@override String get unreachable => 'Der Anbieter war nicht erreichbar. Prüfe die Adresse.';
	@override String failed({required Object suffix}) => 'Die Anfrage ist fehlgeschlagen${suffix}.';
	@override String failedStatus({required Object status, required Object suffix}) => 'Die Anfrage ist fehlgeschlagen (HTTP ${status})${suffix}.';
	@override String get fillIn => 'Gib die Adresse und das Modell an.';
	@override String get needsKey => 'Dieser Anbieter braucht einen API-Schlüssel.';
	@override String get notSetUp => 'Es ist kein KI-Anbieter eingerichtet.';
	@override String get searchOff => 'Die Suche in natürlicher Sprache ist für diesen Anbieter ausgeschaltet.';
	@override String get searchFailed => 'Die Suche ist fehlgeschlagen.';
	@override String get noSignal => 'Schau zuerst einen Film, damit es etwas gibt, worauf Vorschläge aufbauen können.';
	@override String get noPicks => 'Das Modell hat diesmal nichts ausgewählt.';
}

// Path: search.filters
class _Translations$search$filters$de extends Translations$search$filters$en {
	_Translations$search$filters$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String decadeOldest({required Object decade}) => '${decade}er und früher';
	@override String decade({required Object decade}) => '${decade}er';
	@override String get type => 'Art';
	@override String get movies => 'Filme';
	@override String get series => 'Serien';
	@override String get source => 'Quelle';
	@override String get unknownSource => 'Unbekannte Quelle';
	@override String get year => 'Jahr';
	@override String get language => 'Sprache';
	@override String get languageNote => 'Aus IPTV-Kategorienamen erraten. Plex-Titel haben hier keine Sprache.';
	@override String get genre => 'Genre';
	@override String get rating => 'Bewertung';
	@override String get ratingNote => 'TMDB-Nutzerbewertung von 10. Titel ohne TMDB-Bewertung werden ausgelassen.';
	@override String get originalLanguage => 'Originalsprache';
	@override String get originalLanguageNote => 'Die Sprache, in der der Titel gedreht wurde, laut TMDB. Eine synchronisierte Fassung behält hier ihre Originalsprache.';
	@override String get clear => 'Zurücksetzen';
	@override String get noMatches => 'Nichts passt zu diesen Filtern.';
	@override String get clearAll => 'Filter zurücksetzen';
	@override String chip({required Object label, required Object value}) => '${label}: ${value}';
	@override String get any => 'Beliebig';
}

// Path: settings.about
class _Translations$settings$about$de extends Translations$settings$about$en {
	_Translations$settings$about$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get versionLoading => 'Version …';
	@override String version({required Object version, required Object build}) => 'Version ${version} (${build})';
	@override String get privacyPolicy => 'Datenschutzerklärung';
	@override String get privacySummary => 'Kein Konto, kein eigener Server und keine Analyse. Die vollständige Erklärung steht unter:';
	@override String get licences => 'Open-Source-Lizenzen';
}

// Path: settings.privacy
class _Translations$settings$privacy$de extends Translations$settings$privacy$en {
	_Translations$settings$privacy$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get summary => 'Subnext Player hat keinen eigenen Server und keine Analyse. Was es speichert, bleibt auf diesem Gerät, und Daten gehen nur an die Quellen, an TMDB und an den KI-Anbieter, die du selbst verbindest.';
	@override String get cachedData => 'Zwischengespeicherte Daten';
	@override String get cachedExplain => 'Deine Mediathekslisten, TMDB-Abfragen und KI-Vorschläge werden gespeichert, damit die App schnell öffnet. Alte Einträge löschen sich selbst, nach 30 Tagen bei einer Mediathek und nach 90 bei einer Abfrage, und die Daten einer Quelle verschwinden, wenn du sie entfernst. Jetzt zu leeren lässt deine Quellen, Schlüssel, Einstellungen und deinen Verlauf unberührt, und alles wird bei Bedarf neu geladen.';
	@override String get clearing => 'Wird geleert...';
	@override String get clear => 'Zwischenspeicher leeren';
	@override String get cleared => 'Geleert. Deine Mediathek wird neu geladen.';
}

// Path: settings.playback
class _Translations$settings$playback$de extends Translations$settings$playback$en {
	_Translations$settings$playback$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get skip => 'Zurück- und vorspringen';
	@override String get skipExplain => 'Die Sprungtasten, die Vor- und Rückspultasten einer Fernbedienung und der erste Schritt beim Bewegen auf der Zeitleiste.';
	@override String get audioLanguage => 'Bevorzugte Audiosprache';
	@override String get audioLanguageExplain => 'Wird verwendet, wenn eine Datei mehr als eine Audiospur hat. Sonst läuft die Standardspur der Datei.';
	@override String get fileDefault => 'Standard der Datei';
	@override String get showSubtitles => 'Untertitel anzeigen';
	@override String get showSubtitlesExplain => 'Einschalten, wenn eine Datei welche hat. Im Player kannst du jederzeit wechseln.';
	@override String get subtitleLanguage => 'Bevorzugte Untertitelsprache';
	@override String get subtitleLanguageExplain => 'Hat eine Datei keine Untertitel in dieser Sprache, werden keine angezeigt.';
	@override String get any => 'Beliebig';
	@override String get size => 'Größe';
	@override String get sizeExplain => 'Für Textuntertitel wie SRT und ASS.';
}

// Path: settings.metadata
class _Translations$settings$metadata$de extends Translations$settings$metadata$en {
	_Translations$settings$metadata$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get consent => 'Dabei wird bei TMDB das Erscheinungsdatum jedes Films und jeder Serie in deiner Mediathek abgefragt, im Hintergrund und immer nur ein paar auf einmal. Dazu wird von jedem der Titel (und das Jahr, falls vorhanden) von diesem Gerät an TMDB gesendet, und an niemanden sonst, nicht nur die, nach denen du suchst. Außerdem werden Genre und Bewertung für die Filter ergänzt. Die Ergebnisse bleiben 90 Tage auf diesem Gerät, und bereits abgefragte Titel werden nicht noch einmal abgefragt.\n\nDu kannst das jederzeit ausschalten. Wenn du deinen TMDB-Schlüssel entfernst, wird es ebenfalls ausgeschaltet.';
	@override String get consentTitle => 'Titel deiner Mediathek an TMDB senden?';
	@override String get notNow => 'Nicht jetzt';
	@override String get lookThemUp => 'Abfragen';
	@override String get waiting => 'Warte, bis deine Mediathek geladen ist.';
	@override String get stopped => 'Pausiert: TMDB antwortet nicht mehr. Es geht beim nächsten Öffnen der App weiter, und was gefunden wurde, bleibt erhalten.';
	@override String running({required Object settled, required Object total}) => '${settled} von ${total} Titeln abgefragt.';
	@override String partial({required Object settled, required Object total}) => '${settled} von ${total} Titeln abgefragt. Der Rest folgt beim nächsten Öffnen der App.';
	@override String done({required Object found, required Object total}) => 'Fertig: ${found} Erscheinungsdaten für ${total} Titel gefunden.';
	@override String get releaseDates => 'Erscheinungsdaten für deine Mediathek';
	@override String get releaseDatesExplain => 'Ergänzt im Hintergrund genaue Erscheinungsdaten, damit Sortieren nach Erscheinungsdatum deine Mediathek richtig ordnen kann, auch Titel ohne Jahr. Sendet jeden Titel deiner Mediathek an TMDB.';
	@override String get intro => 'Verbinde deinen eigenen TMDB-Schlüssel, um Suchergebnisse um Genre, Bewertung und Originalsprache zu ergänzen und Vorschläge auf Basis dessen zu erhalten, was du gesehen hast. Das ist optional, und nichts ändert sich, bis du einen hinzufügst.';
	@override String get keyExplain => 'Die abgefragten Titel werden von diesem Gerät an TMDB gesendet, und an niemanden sonst. Erstelle einen kostenlosen Schlüssel in deinem TMDB-Konto unter Einstellungen, API. Der kurze Schlüssel und das lange Lesezugriffstoken funktionieren beide. Auf einem Fernseher ist es einfacher, ihn zuerst auf einem Handy oder Computer einzufügen oder einzutippen.';
	@override String get keySaved => 'TMDB-Schlüssel gespeichert';
	@override String get removeKey => 'Schlüssel entfernen';
	@override String get keyLabel => 'TMDB-API-Schlüssel';
	@override String get checking => 'Wird geprüft...';
	@override String get verify => 'Prüfen und speichern';
	@override late final _Translations$settings$metadata$errors$de errors = _Translations$settings$metadata$errors$de._(_root);
}

// Path: settings.ai
class _Translations$settings$ai$de extends Translations$settings$ai$en {
	_Translations$settings$ai$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get intro => 'Verbinde deinen eigenen Anbieter und deinen eigenen Schlüssel. Anfragen gehen direkt von diesem Gerät an den gewählten Anbieter, nie über uns, denn dazwischen gibt es keinen Server von uns. Es wird nichts gesendet, bevor du unten eine Funktion erlaubst.';
	@override String get address => 'Adresse';
	@override String get model => 'Modell';
	@override String get keyOptional => 'API-Schlüssel (optional bei einem lokalen Server)';
	@override String get key => 'API-Schlüssel';
	@override String get trying => 'Wird ausprobiert...';
	@override String get testAndSave => 'Testen und speichern';
	@override String get onNetwork => 'In deinem Netzwerk';
	@override String get keySaved => 'Schlüssel gespeichert';
	@override String get remove => 'Anbieter entfernen';
	@override String get maySend => 'Was gesendet werden darf';
	@override String get localNoConsent => 'Dieser Anbieter ist in deinem eigenen Netzwerk, also erreicht nichts Dritte, und es ist keine Einwilligung nötig.';
	@override String sendsTo({required Object provider, required Object sends}) => 'Sendet an ${provider}: ${sends}';
	@override String allowedOn({required Object date}) => 'Erlaubt am ${date}';
	@override String get notAllowed => 'Noch nicht erlaubt. Du wirst beim ersten Mal gefragt.';
	@override String get switchOff => 'Ausschalten';
	@override String get allow => 'Erlauben';
}

// Path: settings.appearance
class _Translations$settings$appearance$de extends Translations$settings$appearance$en {
	_Translations$settings$appearance$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _Translations$settings$appearance$palette$de palette = _Translations$settings$appearance$palette$de._(_root);
	@override String get theme => 'Design';
	@override String get accent => 'Akzentfarbe';
}

// Path: settings.section
class _Translations$settings$section$de extends Translations$settings$section$en {
	_Translations$settings$section$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get sources => 'Quellen';
	@override String get appearance => 'Darstellung';
	@override String get playback => 'Wiedergabe';
	@override String get subtitles => 'Untertitel';
	@override String get metadata => 'Metadaten';
	@override String get aiFeatures => 'KI-Funktionen';
	@override String get advancedSources => 'Erweiterte Quellen';
	@override String get transfer => 'Auf ein anderes Gerät übertragen';
	@override String get privacy => 'Datenschutz und Daten';
	@override String get about => 'Über';
	@override String get trackers => 'Wiedergabe-Tracking';
	@override String get requests => 'Anfragen';
}

// Path: settings.advanced
class _Translations$settings$advanced$de extends Translations$settings$advanced$en {
	_Translations$settings$advanced$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get dialogTitle => 'Erweiterte Quellen einschalten';
	@override String get dialogLead => 'Du bist dabei, einen Drittanbieter mit deinen eigenen Zugangsdaten zu verbinden.';
	@override String get dialogNoContent => 'Subnext Player stellt keine Inhalte oder Anbieter bereit, hostet sie nicht und unterstützt sie nicht. Du gibst Adresse und Anmeldung an, und die App spielt ab, was diese Adresse liefert.';
	@override String get dialogRights => 'Du bist dafür verantwortlich, die Rechte an allem zu haben, womit du dich verbindest.';
	@override String get dialogConfirm => 'Verstanden, einschalten';
	@override String get toggle => 'IPTV-Anbieter oder Playlist';
	@override String get toggleExplain => 'Fügt Live-TV und Xtream-Codes-Anmeldungen hinzu.';
	@override String get offKeeps => 'Später ausschalten blendet Live-TV aus, behält aber hinzugefügte Konten.';
}

// Path: settings.sources
class _Translations$settings$sources$de extends Translations$settings$sources$en {
	_Translations$settings$sources$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get noServers => 'Keine Plex-Server verbunden.';
	@override String get remove => 'Entfernen';
	@override String loadFailed({required Object error}) => 'Mediatheken dieses Servers konnten nicht geladen werden.\n\n${error}';
	@override String get lookForMore => 'Nach weiteren Servern suchen';
	@override String get addAnother => 'Weiteren Server hinzufügen';
	@override String get yours => 'Deiner';
	@override String get shared => 'Mit dir geteilt';
	@override String get viaRelay => 'über Relay';
	@override String plexType({required Object type}) => 'Plex-Typ: ${type}';
	@override String get changedByYou => 'von dir geändert';
	@override String get localTab => 'Lokal & Netzwerk anzeigen';
	@override String get localTabSub => 'Ein Tab auf der Startseite für Videos auf diesem Gerät und in Netzwerkfreigaben. Er schaltet sich von selbst ein, wenn du eine hinzufügst.';
}

// Path: addSource.kind
class _Translations$addSource$kind$de extends Translations$addSource$kind$en {
	_Translations$addSource$kind$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get plex => 'Plex-Server';
	@override String get plexShort => 'Mit Code verknüpfen';
	@override String get plexLong => 'Gib dieses Gerät in deinem Browser frei. Dein eigener Server und alles, was mit dir geteilt wird.';
	@override String get localFiles => 'Videos auf diesem Gerät';
	@override String get localFilesSub => 'Durchsuche deine Medienbibliothek oder wähle einen einzelnen Ordner, auf den der Zugriff bleiben soll.';
	@override String get localFilesIos => 'Spiel die Videos aus deiner Fotomediathek ab.';
	@override String get smb => 'Netzwerkfreigabe (SMB)';
	@override String get smbSub => 'Ein NAS oder eine Windows-Freigabe in deinem Heimnetz.';
	@override String get xtream => 'Xtream-Codes-Anmeldung';
	@override String get xtreamSub => 'Host, Benutzername und Passwort von deinem Anbieter.';
	@override String get mediaBrowser => 'Jellyfin- oder Emby-Server';
	@override String get mediaBrowserSub => 'Dein eigener Server, mit deinem eigenen Konto.';
}

// Path: plex.errors
class _Translations$plex$errors$de extends Translations$plex$errors$en {
	_Translations$plex$errors$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String noAnswer({required Object server, required Object count}) => '„${server}“ hat unter keiner seiner ${count} angegebenen Adressen geantwortet.';
	@override String get itemGone => 'Dieser Eintrag ist nicht mehr auf dem Server.';
	@override String get noFile => 'Keine abspielbare Datei für diesen Eintrag. Quellen, die nur transkodiert abspielbar sind, werden noch nicht unterstützt.';
	@override String get notConnected => 'Nicht mit einem Plex-Server verbunden.';
}

// Path: xtream.catalogue
class _Translations$xtream$catalogue$de extends Translations$xtream$catalogue$en {
	_Translations$xtream$catalogue$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get live => 'Live-TV';
	@override String get vod => 'Filme';
	@override String get series => 'Serien';
}

// Path: xtream.errors
class _Translations$xtream$errors$de extends Translations$xtream$errors$en {
	_Translations$xtream$errors$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String status({required Object code}) => 'Das Panel hat ${code} geliefert. Versuch es später noch einmal.';
	@override String get timeout => 'Das Panel hat nicht rechtzeitig geantwortet.';
	@override String get unreachable => 'Diese Adresse war nicht erreichbar. Prüfe Host und Port.';
	@override String other({required Object type}) => 'Keine Verbindung zum Panel möglich (${type}).';
	@override String get notXtream => 'Diese Adresse hat nicht wie ein Xtream-Panel geantwortet.';
	@override String get rejected => 'Das Panel hat diese Zugangsdaten abgelehnt.';
	@override String get wrongLogin => 'Falscher Benutzername oder falsches Passwort.';
	@override String get unnamed => 'Ohne Namen';
	@override String get episode => 'Folge';
	@override String get noPassword => 'Für diesen Zugang ist kein Passwort gespeichert. Entferne ihn und füge ihn erneut hinzu.';
}

// Path: xtream.series
class _Translations$xtream$series$de extends Translations$xtream$series$en {
	_Translations$xtream$series$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Serie';
	@override String get noEpisodes => 'Das Panel hat für diese Serie keine Folgen geliefert.';
	@override String season({required Object n}) => 'Staffel ${n}';
}

// Path: xtream.addLine
class _Translations$xtream$addLine$de extends Translations$xtream$addLine$en {
	_Translations$xtream$addLine$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get discardTitle => 'Diesen Zugang verwerfen?';
	@override String get discardBody => 'Was du hier eingegeben hast, wurde nicht gespeichert.';
	@override String get discard => 'Verwerfen';
	@override String get keepEditing => 'Weiter bearbeiten';
	@override String inactive({required Object status}) => 'Laut Panel ist dieser Zugang „${status}“.';
	@override String get noContent => 'Subnext Player stellt keine Inhalte oder Anbieter bereit, hostet sie nicht und unterstützt sie nicht. Du gibst Adresse und Anmeldung an, und die App spielt ab, was diese Adresse liefert.';
	@override String get host => 'Serveradresse';
	@override String get name => 'Name (optional)';
	@override String get nameHint => 'Wie du diesen Zugang nennen möchtest';
	@override String get checking => 'Wird geprüft…';
	@override String get verify => 'Prüfen und hinzufügen';
	@override String connected({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: 'Verbunden. ${n} gleichzeitiger Stream erlaubt.',
		other: 'Verbunden. ${n} gleichzeitige Streams erlaubt.',
	);
}

// Path: xtream.picker
class _Translations$xtream$picker$de extends Translations$xtream$picker$en {
	_Translations$xtream$picker$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get patternNone => 'Dieses Muster hat nichts gefunden.';
	@override String title({required Object catalogue}) => 'Kategorien: ${catalogue}';
	@override String get save => 'Speichern';
	@override String noMatch({required Object query}) => 'Nichts passt zu „${query}“.';
	@override String get noneChosen => 'Noch nichts ausgewählt.';
	@override String get search => 'Alle Kategorien durchsuchen';
	@override String chosen({required Object n}) => 'Ausgewählt ${n}';
	@override String get hideWords => 'Wörter ausblenden';
	@override String hideCount({required Object n}) => 'Ausgeblendet ${n}';
	@override String get pattern => 'Muster';
	@override String untickedOne({required Object name, required Object word}) => '„${name}“ wurde abgewählt, weil „${word}“ es ausblendet. Speichern, um das zu behalten.';
	@override String untickedMany({required Object n, required Object word}) => '${n} ausgewählte Kategorien, die „${word}“ ausblendet, wurden abgewählt. Speichern, um das zu behalten.';
	@override String get showingHidden => 'Angezeigt werden die Kategorien, die deine ausgeblendeten Wörter auslassen.';
	@override String hiddenCount({required Object n}) => '${n} durch deine Wörter ausgeblendet.';
	@override String get hideAgain => 'Wieder ausblenden';
	@override String get showThem => 'Anzeigen';
	@override String get patternHint => 'Alle Kategorien auswählen oder abwählen, die zu einem Wort oder Muster passen';
	@override String get selectMatching => 'Treffer auswählen';
	@override String get deselectMatching => 'Treffer abwählen';
	@override String get groups => 'Gruppen';
	@override String get clearAll => 'Alle abwählen';
	@override String get selectAll => 'Alle auswählen';
	@override String channelsPicked({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${n} Sender',
		other: '${n} Sender',
	);
	@override String pickedChosen({required Object n}) => '${n} ausgewählt';
	@override String categories({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${n} Kategorie',
		other: '${n} Kategorien',
	);
	@override String get channels => 'Sender';
}

// Path: xtream.channels
class _Translations$xtream$channels$de extends Translations$xtream$channels$en {
	_Translations$xtream$channels$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get done => 'Fertig';
	@override String get search => 'Diese Kategorie durchsuchen';
	@override String pickedOf({required Object picked, required Object total}) => '${picked} von ${total}';
	@override String get whole => 'Ganze Kategorie';
	@override String get selectShown => 'Angezeigte auswählen';
	@override String get clear => 'Abwählen';
	@override String get clearShown => 'Angezeigte abwählen';
	@override String get none => 'Das Panel listet in dieser Kategorie keine Sender.';
}

// Path: xtream.hidden
class _Translations$xtream$hidden$de extends Translations$xtream$hidden$en {
	_Translations$xtream$hidden$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Wörter ausblenden';
	@override String get explain => 'Eine Kategorie oder ein Sender, der eines dieser Wörter als ganzes Wort enthält, wird aus den Listen ausgelassen. „UK“ blendet „UK News“ aus, aber nicht „Ukraine“. Füge eine Wortgruppe wie „south indian“ hinzu, um sie als Ganzes auszublenden. Groß- und Kleinschreibung spielt keine Rolle.';
	@override String get hint => 'Ein Land, eine Sprache, ein Wort';
	@override String get add => 'Hinzufügen';
	@override String get none => 'Noch nichts ausgeblendet.';
	@override String get tapToRemove => 'Wähle ein Wort aus, um es nicht mehr auszublenden.';
}

// Path: transfer.receive
class _Translations$transfer$receive$de extends Translations$transfer$receive$en {
	_Translations$transfer$receive$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String cannotSave({required Object error}) => 'Die Einstellungen konnten nicht gespeichert werden: ${error}';
	@override String get title => 'Einstellungen empfangen';
	@override String get asking => 'Das andere Gerät wird gefragt…';
	@override String get awaitingPush => 'Warte, bis das andere Gerät sendet. Stimm dort zu, wenn es fragt.';
	@override String get saving => 'Wird gespeichert…';
	@override String get waitingInstructions => 'Öffne auf dem Gerät mit deinen Einstellungen Einstellungen, Auf ein anderes Gerät übertragen, und wähle Senden. Scanne dann diesen Code.';
	@override String get scanInstructions => 'Öffne auf dem Gerät mit deinen Einstellungen Einstellungen, Auf ein anderes Gerät übertragen, und wähle Senden und dann Code anzeigen. Richte die Kamera darauf.';
	@override String get showMine => 'Stattdessen meinen Code anzeigen';
	@override String get typeInstructions => 'Öffne auf dem Gerät mit deinen Einstellungen Einstellungen, Auf ein anderes Gerät übertragen, und wähle Senden und dann Code anzeigen. Gib dann ein, was es anzeigt.';
	@override String get connect => 'Verbinden';
	@override String get review => 'Ein anderes Gerät möchte dir das hier senden. Was hier schon unter demselben Namen existiert, wird ersetzt; sonst wird nichts entfernt.';
	@override String get saveThese => 'Speichern';
	@override String get decline => 'Ablehnen';
	@override String get saved => 'Fertig. Deine Einstellungen sind auf diesem Gerät.';
}

// Path: transfer.pairing
class _Translations$transfer$pairing$de extends Translations$transfer$pairing$en {
	_Translations$transfer$pairing$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get noCamera => 'Keine Kamera? Wähle dort Code eingeben und gib ein:';
	@override String get qrLabel => 'Code zum Scannen vom anderen Gerät';
	@override String get cameraOff => 'Die Kamera ist für diese App ausgeschaltet. Gib stattdessen den Code ein oder erlaube die Kamera in den Einstellungen deines Handys.';
	@override String get cameraFailed => 'Die Kamera konnte nicht starten. Gib stattdessen den Code ein.';
	@override String get foreign => 'Das ist kein Code aus dieser App.';
	@override String get checkEntry => 'Prüfe die Adresse (etwa 192.168.1.20:41234) und den 16-stelligen Code.';
	@override String get address => 'Adresse';
	@override String get code => 'Code';
}

// Path: transfer.pane
class _Translations$transfer$pane$de extends Translations$transfer$pane$en {
	_Translations$transfer$pane$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get explain => 'Kopiere deine Quellen, Schlüssel und Einstellungen auf ein anderes Gerät im selben WLAN, damit du sie nicht noch einmal eintippen musst. Es geht direkt von einem Gerät zum anderen, verschlüsselt mit einem Code, den nur die beiden Bildschirme kennen, und das empfangende Gerät fragt, bevor es etwas speichert.';
	@override String get notCopied => 'Nicht kopiert: Plex (verknüpfe es auf dem anderen Gerät mit dessen eigenem Code), Verlauf, Favoriten und die Einwilligung für Erweiterte Quellen und KI-Funktionen, die jedes Gerät selbst einholt.';
	@override String get receive => 'Von einem anderen Gerät empfangen';
	@override String get send => 'An ein anderes Gerät senden';
}

// Path: transfer.notes
class _Translations$transfer$notes$de extends Translations$transfer$notes$en {
	_Translations$transfer$notes$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get aiLocal => 'Dein KI-Anbieter läuft auf diesem Gerät, deshalb wird er nicht gesendet. Richte ihn dort mit der Adresse dieses Geräts in deinem Netzwerk neu ein.';
	@override String get xtreamHidden => 'Die IPTV-Konten sind gespeichert, aber ausgeblendet. Schalte Erweiterte Quellen in den Einstellungen ein, um sie zu nutzen.';
	@override String get aiAsks => 'KI-Funktionen fragen, bevor sie etwas an den Anbieter senden.';
	@override String partial({required Object failed}) => 'Nicht gespeichert: ${failed}. Der Rest wurde gespeichert.';
}

// Path: transfer.send
class _Translations$transfer$send$de extends Translations$transfer$send$en {
	_Translations$transfer$send$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String cannotRead({required Object error}) => 'Die Einstellungen dieses Geräts konnten nicht gelesen werden: ${error}';
	@override String askTitle({required Object host}) => 'An ${host} senden?';
	@override String askBody({required Object summary}) => 'Ein Gerät in deinem Netzwerk hat diesen Code gescannt und fragt nach:\n\n${summary}\n\nStimm nur zu, wenn du das gerade auf diesem Gerät angefordert hast.';
	@override String get notNow => 'Nicht jetzt';
	@override String get send => 'Senden';
	@override String get title => 'Einstellungen senden';
	@override String get reading => 'Deine Einstellungen werden gelesen…';
	@override String get sending => 'Wird gesendet. Das andere Gerät fragt, bevor es etwas speichert.';
	@override String get explain => 'Kopiert das hier auf ein anderes Gerät im selben WLAN, damit du es nicht noch einmal eintippen musst. Es geht direkt dorthin und ist verschlüsselt; nichts läuft über uns.';
	@override String get nothing => 'Auf diesem Gerät ist noch nichts eingerichtet, das gesendet werden könnte.';
	@override String get proceed => 'Weiter';
	@override String get showInstead => 'Stattdessen einen Code anzeigen';
	@override String get typeInstead => 'Stattdessen den Code eingeben';
	@override String get scanInstructions => 'Öffne auf dem anderen Gerät Einstellungen, Auf ein anderes Gerät übertragen, und wähle Empfangen. Richte die Kamera auf den Code, den es anzeigt.';
	@override String get showInstructions => 'Öffne auf dem anderen Gerät Einstellungen, Auf ein anderes Gerät übertragen, und wähle Empfangen und dann Seinen Code scannen, und richte seine Kamera hierher. Du wirst gefragt, bevor etwas gesendet wird.';
	@override String get typeInstructions => 'Öffne auf dem anderen Gerät Einstellungen, Auf ein anderes Gerät übertragen, und wähle Empfangen. Gib dann ein, was es anzeigt.';
	@override String get sent => 'Gesendet. Das andere Gerät hat deine Einstellungen gespeichert.';
}

// Path: transfer.item
class _Translations$transfer$item$de extends Translations$transfer$item$en {
	_Translations$transfer$item$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get preferences => 'Einstellungen';
	@override String get preferencesSub => 'Wiedergabe- und Untertitelwahl, ausgeblendete Wörter und Platzierung in der Mediathek.';
	@override String get xtream => 'IPTV-Konten';
	@override String get xtreamSub => 'Anmeldungen und die gewählten Kategorien und Sender.';
	@override String get smb => 'Netzwerkfreigaben';
	@override String get smbSub => 'SMB-Freigaben und ihre Passwörter.';
	@override String get tmdb => 'TMDB-Schlüssel';
	@override String get tmdbSub => 'Dein eigener Schlüssel für die Filter nach Genre, Bewertung und Sprache.';
	@override String get ai => 'KI-Anbieter';
	@override String get aiSub => 'Der Anbieter, sein Modell und dein Schlüssel.';
	@override String settings({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${n} Einstellung',
		other: '${n} Einstellungen',
	);
	@override String accounts({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${n} Konto',
		other: '${n} Konten',
	);
	@override String shares({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${n} Freigabe',
		other: '${n} Freigaben',
	);
	@override String get notBundle => 'Das war kein Einstellungspaket.';
	@override String get newer => 'Dieses Paket stammt aus einer neueren Version der App. Aktualisiere dieses Gerät und versuch es erneut.';
	@override String get trackers => 'Wiedergabe-Tracking';
	@override String get trackersSub => 'Deine Anmeldungen bei Trakt, Simkl, AniList und MyAnimeList. Sie hier anzunehmen heißt zuzustimmen, dass auch auf diesem Gerät Gesehenes gesendet wird.';
	@override String services({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${n} Dienst',
		other: '${n} Dienste',
	);
}

// Path: transfer.client
class _Translations$transfer$client$de extends Translations$transfer$client$en {
	_Translations$transfer$client$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get declined => 'Das andere Gerät hat die Einstellungen nicht angenommen.';
	@override String get wrongCode => 'Der Code war nicht richtig. Vergleich ihn mit dem anderen Bildschirm.';
	@override String get used => 'Das andere Gerät hat schon etwas empfangen. Öffne dort Empfangen erneut, um einen neuen Code zu bekommen.';
	@override String get tooBig => 'Das war zu viel zum Senden.';
	@override String get unreadable => 'Das andere Gerät konnte das nicht lesen.';
	@override String unexpected({required Object status}) => 'Das andere Gerät hat unerwartet geantwortet (${status}).';
	@override String get refusedToSend => 'Das andere Gerät hat dem Senden seiner Einstellungen nicht zugestimmt.';
	@override String get busy => 'Das andere Gerät antwortet bereits jemand anderem. Bitte es um einen neuen Code.';
	@override String unreachable({required Object address}) => '${address} war nicht erreichbar. Beide Geräte müssen im selben WLAN sein, und das andere muss seinen Code noch anzeigen.';
	@override String get dropped => 'Die Verbindung ist zwischendurch abgebrochen.';
	@override String noAnswer({required Object address}) => 'Keine Antwort von ${address}. Prüfe den anderen Bildschirm.';
}

// Path: mediaBrowser.errors
class _Translations$mediaBrowser$errors$de extends Translations$mediaBrowser$errors$en {
	_Translations$mediaBrowser$errors$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String signedOut({required Object server}) => '${server} akzeptiert diese Anmeldung nicht mehr. Entferne ihn unter Einstellungen, Quellen und füge ihn erneut hinzu.';
	@override String status({required Object server, required Object code}) => '${server} hat mit ${code} geantwortet.';
	@override String unreachable({required Object server}) => '${server} war nicht erreichbar. Er ist vielleicht im Ruhezustand oder nicht im Netzwerk.';
	@override String get notAServer => 'Unter dieser Adresse hat kein Jellyfin- oder Emby-Server geantwortet. Prüfe sie, auch den Port (meist 8096).';
	@override String get badAnswer => 'Der Server hat auf eine Weise geantwortet, die diese App nicht versteht.';
	@override String get wrongLogin => 'Falscher Benutzername oder falsches Passwort.';
}

// Path: trackers.errors
class _Translations$trackers$errors$de extends Translations$trackers$errors$en {
	_Translations$trackers$errors$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String unavailable({required Object service}) => '${service} war nicht erreichbar. Es wird erneut versucht.';
	@override String get denied => 'Die Anmeldung wurde abgelehnt.';
	@override String get expired => 'Dieser Code ist abgelaufen. Starte neu, um einen neuen zu bekommen.';
	@override String get badPaste => 'Das ist nicht, was die Anmeldeseite angezeigt hat. Kopiere es erneut und füge alles ein.';
}

// Path: seerr.errors
class _Translations$seerr$errors$de extends Translations$seerr$errors$en {
	_Translations$seerr$errors$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get notASeerr => 'Unter dieser Adresse hat kein Overseerr-, Jellyseerr- oder Seerr-Server geantwortet. Prüfe sie, auch den Port (meist 5055).';
	@override String get badKey => 'Der Server hat diesen API-Schlüssel nicht angenommen.';
	@override String get refused => 'Der Server hat diese Anmeldung nicht angenommen.';
	@override String status({required Object code}) => 'Der Server hat mit ${code} geantwortet.';
	@override String get unreachable => 'Der Anfrage-Server war nicht erreichbar.';
	@override String get signedOut => 'Der Anfrage-Server akzeptiert diese Anmeldung nicht mehr. Verbinde ihn erneut unter Einstellungen, Anfragen.';
	@override String get alreadyRequested => 'Das wurde bereits angefragt.';
}

// Path: settings.metadata.errors
class _Translations$settings$metadata$errors$de extends Translations$settings$metadata$errors$en {
	_Translations$settings$metadata$errors$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get rejected => 'TMDB hat diesen Schlüssel abgelehnt.';
	@override String get rateLimited => 'TMDB drosselt die Anfragen dieses Geräts.';
	@override String unreachable({required Object type}) => 'TMDB war nicht erreichbar (${type}).';
}

// Path: settings.appearance.palette
class _Translations$settings$appearance$palette$de extends Translations$settings$appearance$palette$en {
	_Translations$settings$appearance$palette$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get system => 'System';
	@override String get midnight => 'Mitternacht';
	@override String get slate => 'Schiefer';
	@override String get daylight => 'Tageslicht';
	@override String get amber => 'Bernstein';
}

/// The flat map containing all translations for locale <de>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsDe {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'common.back' => 'Zurück',
			'common.tryAgain' => 'Erneut versuchen',
			'common.cancel' => 'Abbrechen',
			'common.noDrm' => 'Kein DRM. Geschützte kommerzielle Kataloge wie Netflix oder Disney+ können nicht abgespielt werden.',
			'player.shareGone' => 'Diese Freigabe ist nicht mehr eingerichtet.',
			'player.shareFileGone' => 'Diese Datei liegt nicht mehr auf der Freigabe.',
			'player.deviceFileGone' => 'Diese Datei ist nicht mehr auf diesem Gerät.',
			'player.lineGone' => 'Dieser Zugang ist nicht mehr eingerichtet.',
			'player.untitledVideo' => 'Video',
			'player.untitledEpisode' => 'Folge',
			'player.untitledFilm' => 'Film',
			'player.untitledLive' => 'Live',
			'player.channelFroze' => 'Dieser Sender ist stehen geblieben und nicht zurückgekommen.',
			'player.channelNotResponding' => 'Dieser Sender antwortet nicht. Die Listen eines Panels sind der Wirklichkeit oft voraus, also versuch einen anderen oder denselben noch einmal.',
			'player.didNotStart' => 'Die Wiedergabe ist nicht gestartet. Der Server ist vielleicht ausgelastet, oder die Datei muss transkodiert werden, was noch nicht unterstützt wird.',
			'player.released' => 'Angehalten, während die App im Hintergrund war, damit die Verbindung für andere Geräte frei ist.',
			'player.rejoin' => 'Wieder einsteigen',
			'player.live' => 'LIVE',
			'player.skipBack' => ({required Object seconds}) => '${seconds} Sekunden zurück',
			'player.skipForward' => ({required Object seconds}) => '${seconds} Sekunden vor',
			'player.pause' => 'Pause',
			'player.play' => 'Abspielen',
			'player.tracks' => 'Audio und Untertitel',
			'player.audio' => 'Audio',
			'player.subtitles' => 'Untertitel',
			'player.off' => 'Aus',
			'player.trackNumber' => ({required Object n}) => 'Spur ${n}',
			'languages.en' => 'Englisch',
			'languages.es' => 'Spanisch',
			'languages.fr' => 'Französisch',
			'languages.de' => 'Deutsch',
			'languages.it' => 'Italienisch',
			'languages.pt' => 'Portugiesisch',
			'languages.nl' => 'Niederländisch',
			'languages.sv' => 'Schwedisch',
			'languages.no' => 'Norwegisch',
			'languages.da' => 'Dänisch',
			'languages.fi' => 'Finnisch',
			'languages.pl' => 'Polnisch',
			'languages.cs' => 'Tschechisch',
			'languages.hu' => 'Ungarisch',
			'languages.ro' => 'Rumänisch',
			'languages.el' => 'Griechisch',
			'languages.ru' => 'Russisch',
			'languages.uk' => 'Ukrainisch',
			'languages.tr' => 'Türkisch',
			'languages.ar' => 'Arabisch',
			'languages.he' => 'Hebräisch',
			'languages.hi' => 'Hindi',
			'languages.bn' => 'Bengalisch',
			'languages.pa' => 'Panjabi',
			'languages.ta' => 'Tamil',
			'languages.te' => 'Telugu',
			'languages.ur' => 'Urdu',
			'languages.th' => 'Thailändisch',
			'languages.vi' => 'Vietnamesisch',
			'languages.id' => 'Indonesisch',
			'languages.zh' => 'Chinesisch',
			'languages.ja' => 'Japanisch',
			'languages.ko' => 'Koreanisch',
			'subtitleSize.small' => 'Klein',
			'subtitleSize.medium' => 'Mittel',
			'subtitleSize.large' => 'Groß',
			'units.minutes' => ({required Object m}) => '${m} Min.',
			'units.hours' => ({required Object h}) => '${h} Std.',
			'units.hoursMinutes' => ({required Object h, required Object m}) => '${h} Std. ${m} Min.',
			'units.minutesLeft' => ({required Object m}) => 'Noch ${m} Min.',
			'units.seconds' => ({required Object s}) => '${s} s',
			'downloads.empty' => 'Noch nichts heruntergeladen. Halte einen Film oder eine Folge aus deiner Plex-Mediathek gedrückt und wähle Herunterladen, dann schau es hier ohne Netz.',
			'downloads.title' => 'Downloads',
			'downloads.summary' => ({required num n, required Object size}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${n} Eintrag · ${size} auf diesem Gerät', other: '${n} Einträge · ${size} auf diesem Gerät', ), 
			'downloads.pendingWatches' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '1 Wiedergabe von hier wartet darauf, an Plex gesendet zu werden.', other: '${n} Wiedergaben von hier warten darauf, an Plex gesendet zu werden.', ), 
			'downloads.foregroundOnly' => 'Downloads laufen weiter, solange die App geöffnet ist. Beim Schließen werden sie pausiert, und nichts bereits Gespeichertes geht verloren.',
			'downloads.downloadingBytes' => ({required Object received}) => 'Wird heruntergeladen, ${received}',
			'downloads.downloadingPercent' => ({required Object percent, required Object received, required Object total}) => 'Wird heruntergeladen: ${percent} % · ${received} von ${total}',
			'downloads.queued' => 'Wartet, bis es an der Reihe ist',
			'downloads.paused' => 'Pausiert',
			'downloads.pausedAt' => ({required Object percent}) => 'Bei ${percent} % pausiert · zum Fortsetzen auswählen',
			'downloads.failed' => ({required Object error}) => '${error} Zum erneuten Versuchen auswählen.',
			'downloads.failedUnknown' => 'Es wurde nicht fertig.',
			'downloads.deleteTitle' => 'Diesen Download löschen?',
			'downloads.cancelTitle' => 'Diesen Download abbrechen?',
			'downloads.removeBody' => ({required Object title}) => '„${title}“ wird von diesem Gerät entfernt. Auf deinem Plex-Server bleibt es erhalten.',
			'downloads.removeBodyFreeing' => ({required Object title, required Object size}) => '„${title}“ wird von diesem Gerät entfernt, dadurch werden ${size} frei. Auf deinem Plex-Server bleibt es erhalten.',
			'downloads.keepIt' => 'Behalten',
			'downloads.delete' => 'Löschen',
			'downloads.errors.serverNotConnected' => 'Dieser Server ist nicht verbunden. Verbinde ihn in den Einstellungen neu und setze dann fort.',
			'downloads.errors.sizeMismatch' => 'Die Datei hat nicht die Größe, die der Server gemeldet hat. Versuch es erneut.',
			'downloads.errors.cannotWrite' => 'Die Datei konnte nicht geschrieben werden. Vielleicht ist der Speicher des Geräts voll.',
			'downloads.errors.changedOnServer' => 'Die Datei hat sich auf dem Server geändert. Starte den Download neu.',
			'downloads.errors.refused' => 'Der Server erlaubt diesem Gerät nicht, das herunterzuladen.',
			'downloads.errors.status' => ({required Object code}) => 'Der Server hat mit ${code} geantwortet.',
			'downloads.errors.dropped' => 'Die Verbindung ist zwischendurch abgebrochen. Zum Weitermachen fortsetzen.',
			'downloads.errors.unreachable' => 'Der Server war nicht erreichbar. Prüfe die Verbindung und setze fort.',
			'downloads.errors.timeout' => 'Der Server hat zu lange nicht geantwortet.',
			'downloads.rule.off' => 'Folgen heruntergeladen halten',
			'downloads.rule.keeping' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: 'Die nächste Folge bleibt heruntergeladen', other: 'Die nächsten ${n} Folgen bleiben heruntergeladen', ), 
			'downloads.rule.explain' => 'Lädt die nächsten ungesehenen Folgen herunter und füllt sie beim Anschauen nach, solange die App geöffnet ist. Gesehene Folgen, die es heruntergeladen hat, werden entfernt.',
			'downloads.rule.choiceOff' => 'Aus',
			'downloads.rule.choice' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: 'Nächste Folge', other: 'Nächste ${n} Folgen', ), 
			'watchActions.everyEpisode' => ' (alle Folgen)',
			'watchActions.markWatched' => ({required Object scope}) => 'Als gesehen markieren${scope}',
			'watchActions.markUnwatched' => ({required Object scope}) => 'Als ungesehen markieren${scope}',
			'watchActions.download' => 'Auf dieses Gerät herunterladen',
			'watchActions.deleteDownload' => 'Download löschen',
			'watchActions.cancelDownload' => 'Download abbrechen',
			'watchActions.removeFavourite' => 'Aus Favoriten entfernen',
			'watchActions.addFavourite' => 'Zu Favoriten hinzufügen',
			'watchActions.removeResume' => 'Aus Weiterschauen entfernen',
			'watchActions.downloading' => 'Wird heruntergeladen. Siehe Tab Downloads.',
			'watchActions.markedOffline' => 'Hier als gesehen markiert. Plex erfährt es, sobald es erreichbar ist.',
			'watchActions.plexRefused' => 'Plex hat das nicht angenommen. Der Server ist vielleicht offline.',
			'show.noEpisodes' => 'Diese Serie hat keine Folgen auf dem Server.',
			'shell.library' => 'Mediathek',
			'shell.search' => 'Suche',
			'shell.downloads' => 'Downloads',
			'shell.settings' => 'Einstellungen',
			'shell.exitTitle' => 'Subnext Player beenden?',
			'shell.exit' => 'Beenden',
			'shell.stay' => 'Bleiben',
			'resume.upNext' => 'Als Nächstes',
			'resume.title' => 'Weiterschauen',
			'resume.remove' => 'Aus Weiterschauen entfernen',
			'library.placement.movies' => 'Filme',
			'library.placement.series' => 'Serien',
			'library.placement.hidden' => 'Ausgeblendet',
			'library.tab.movies' => 'Filme',
			'library.tab.series' => 'Serien',
			'library.tab.localNetwork' => 'Lokal & Netzwerk',
			'library.tab.liveTv' => 'Live-TV',
			'library.tab.emptyMovies' => 'Keine Filme auf diesem Server.',
			'library.tab.emptySeries' => 'Keine Serien auf diesem Server.',
			'library.tab.emptyLocalNetwork' => 'Noch keine Ordner oder Netzwerkfreigaben.\nGerätespeicher und SMB-Freigaben lassen sich in dieser Version nicht verbinden.',
			'library.tab.emptyLiveTv' => 'Keine Playlist und kein Panel eingerichtet.\nFüge eines in den Einstellungen hinzu, sobald Erweiterte Quellen aktiviert ist.',
			'library.tab.countMovies' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${n} Film', other: '${n} Filme', ), 
			'library.tab.countSeries' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${n} Serie', other: '${n} Serien', ), 
			'library.tab.countItems' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${n} Eintrag', other: '${n} Einträge', ), 
			'library.tab.countChannels' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${n} Sender', other: '${n} Sender', ), 
			'library.serverTimeout' => ({required Object server, required Object seconds}) => '${server} hat nicht innerhalb von ${seconds} Sekunden geantwortet. Er ist vielleicht im Ruhezustand oder nicht im Netzwerk.',
			'library.allWatched' => 'In Filme ist alles gesehen.',
			'library.showAll' => 'Alle anzeigen',
			'library.noSources' => 'Noch keine Quellen verbunden.',
			'library.nothingIn' => ({required Object tab}) => 'Noch nichts in ${tab}.',
			'library.addSource' => 'Quelle hinzufügen',
			'library.sortFiltered' => ({required Object sort}) => '${sort} · Ungesehen',
			'library.sortBy' => 'Sortieren nach',
			'library.unwatchedOnly' => 'Nur ungesehene',
			'library.shelf.seeAll' => 'Alle ansehen',
			'library.shelf.titles' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${n} Titel', other: '${n} Titel', ), 
			'library.shelf.gone' => 'Hier ist nichts mehr.',
			'library.sort.title' => 'Titel',
			'library.sort.recentlyAdded' => 'Zuletzt hinzugefügt',
			'library.sort.year' => 'Jahr',
			'library.sort.releaseDate' => 'Erscheinungsdatum',
			'library.tile.series' => 'Serie',
			'library.tile.movie' => 'Film',
			'library.tile.watched' => 'Gesehen',
			'library.tile.percentWatched' => ({required Object percent}) => '${percent} % gesehen',
			'liveTv.group.favourites' => 'Favoriten',
			'liveTv.group.numbered' => ({required Object n}) => 'Kategorie ${n}',
			'liveTv.group.other' => 'Sonstige',
			'liveTv.noPanel' => 'Keine Playlist und kein Panel eingerichtet.',
			'liveTv.addOne' => 'Hinzufügen',
			'liveTv.noCategories' => 'Noch keine Kategorien ausgewählt.\nPanels haben Zehntausende Sender, deshalb lädt Subnext Player nur die, die du auswählst.',
			'liveTv.chooseCategories' => 'Kategorien auswählen',
			'liveTv.noChannels' => 'Diese Kategorien haben keine Sender geliefert.',
			'liveTv.noMatch' => ({required Object query}) => 'Kein Sender passt zu „${query}“.',
			'liveTv.searchHint' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${n} Sender durchsuchen', other: '${n} Sender durchsuchen', ), 
			'liveTv.all' => 'Alle',
			'ai.picks.yourProvider' => 'deinen Anbieter',
			'ai.picks.ask' => 'Was soll ich schauen?',
			'ai.picks.askExplain' => ({required Object provider}) => 'Lass ${provider} aus deiner eigenen Mediathek auswählen.',
			'ai.picks.pickedBy' => 'Für dich ausgewählt von ',
			'ai.picks.updating' => 'Wird aktualisiert',
			'ai.picks.again' => 'Noch mal',
			'ai.picks.preparing' => 'Deine Vorschläge werden vorbereitet...',
			'ai.search.asking' => ({required Object provider}) => '${provider} wird gefragt...',
			'ai.search.searching' => ({required Object searched, required Object covered}) => 'Deine Mediathek wird durchsucht... ${searched} von ${covered} Titeln',
			'ai.search.emptyLibrary' => 'In deiner Mediathek gibt es noch nichts zu durchsuchen.',
			'ai.search.notFound' => ({required Object total}) => 'Das Modell hat unter ${total} Titeln nichts Passendes gefunden. Beschreib es mal anders.',
			'ai.search.notFoundFirst' => ({required Object covered, required Object total}) => 'Das Modell hat unter den ersten ${covered} von ${total} Titeln nichts Passendes gefunden. Beschreib es mal anders.',
			'ai.search.stillSearching' => ({required Object searched, required Object covered}) => 'Suche läuft noch: ${searched} von ${covered} Titeln',
			'ai.search.searchedFirst' => ({required Object covered, required Object total}) => 'Die ersten ${covered} von ${total} Titeln wurden durchsucht',
			'ai.search.pickedFor' => ({required Object provider, required Object query}) => 'Von ${provider} ausgewählt für „${query}“',
			'ai.search.searchAgain' => 'Erneut suchen',
			'ai.search.partsFailed' => ({required Object failed, required Object parts}) => '${failed} von ${parts} Teilen konnten nicht durchsucht werden, daher wurde ein Teil deiner Mediathek nicht angesehen. Der Anbieter begrenzt vielleicht die Anfragen',
			'ai.presetOther' => 'Andere',
			'ai.hintOpenRouter' => 'Modell-IDs stehen unter openrouter.ai/models. Kostenlose enden auf ":free".',
			'ai.hintOllama' => 'Verwende die Adresse deines Computers in diesem Netzwerk, zum Beispiel http://192.168.1.20:11434/v1. Nichts verlässt dein Netzwerk.',
			'ai.hintCustom' => 'Jeder Dienst, der das Chat-Format von OpenAI spricht.',
			'ai.feature.naturalSearch' => 'Suche in natürlicher Sprache',
			'ai.feature.naturalSearchSends' => 'Dein Suchtext sowie die Titel und Jahre in deiner Mediathek.',
			'ai.feature.naturalSearchTiming' => 'Eine große Mediathek wird in mehreren Anfragen mit je einigen hundert Titeln gesendet, eine Suche stellt also mehr als eine.',
			'ai.feature.recommendations' => 'Empfehlungen',
			'ai.feature.recommendationsSends' => 'Die Filme, die du zuletzt gesehen hast, sowie Titel und Jahre dessen, was du in deiner Mediathek noch nicht gesehen hast.',
			'ai.feature.recommendationsTiming' => 'Vorschläge werden kurz nach dem Öffnen der App im Hintergrund vorbereitet, aber nur, wenn sich geändert hat, was du gesehen hast, oder sie älter als einen Tag sind, also nicht bei jedem Start.',
			'ai.errors.ranOutThinking' => 'Dem Modell ist beim Nachdenken der Platz für die Antwort ausgegangen, und es hat nie geantwortet. Ein Modell, das nicht erst „nachdenkt“, funktioniert besser.',
			'ai.errors.empty' => 'Das Modell hat eine leere Antwort geschickt.',
			'ai.errors.rejectedKey' => ({required Object suffix}) => 'Der Anbieter hat diesen Schlüssel abgelehnt${suffix}.',
			'ai.errors.noCredit' => ({required Object suffix}) => 'Der Anbieter meldet, dass dieses Konto kein Guthaben mehr hat${suffix}.',
			'ai.errors.unknownModel' => ({required Object suffix}) => 'Der Anbieter kennt dieses Modell oder diese Adresse nicht${suffix}.',
			'ai.errors.rateLimited' => ({required Object suffix}) => 'Der Anbieter drosselt diesen Schlüssel. Versuch es gleich noch einmal${suffix}.',
			'ai.errors.serverError' => ({required Object status, required Object suffix}) => 'Beim Anbieter ist ein Problem aufgetreten (HTTP ${status})${suffix}.',
			'ai.errors.timeout' => 'Der Anbieter hat zu lange nicht geantwortet.',
			'ai.errors.unreachable' => 'Der Anbieter war nicht erreichbar. Prüfe die Adresse.',
			'ai.errors.failed' => ({required Object suffix}) => 'Die Anfrage ist fehlgeschlagen${suffix}.',
			'ai.errors.failedStatus' => ({required Object status, required Object suffix}) => 'Die Anfrage ist fehlgeschlagen (HTTP ${status})${suffix}.',
			'ai.errors.fillIn' => 'Gib die Adresse und das Modell an.',
			'ai.errors.needsKey' => 'Dieser Anbieter braucht einen API-Schlüssel.',
			'ai.errors.notSetUp' => 'Es ist kein KI-Anbieter eingerichtet.',
			'ai.errors.searchOff' => 'Die Suche in natürlicher Sprache ist für diesen Anbieter ausgeschaltet.',
			'ai.errors.searchFailed' => 'Die Suche ist fehlgeschlagen.',
			'ai.errors.noSignal' => 'Schau zuerst einen Film, damit es etwas gibt, worauf Vorschläge aufbauen können.',
			'ai.errors.noPicks' => 'Das Modell hat diesmal nichts ausgewählt.',
			'ai.consentTitle' => ({required Object provider}) => 'Daten an ${provider} senden?',
			'ai.consentBody' => ({required Object feature, required Object provider, required Object sends}) => '${feature} sendet Folgendes an ${provider}: ${sends}',
			'ai.consentTail' => 'Es geht direkt von diesem Gerät dorthin, nie über uns. Du kannst das in Einstellungen, KI-Funktionen wieder ausschalten.',
			'ai.notNow' => 'Nicht jetzt',
			'ai.allow' => 'Erlauben',
			'search.filters.decadeOldest' => ({required Object decade}) => '${decade}er und früher',
			'search.filters.decade' => ({required Object decade}) => '${decade}er',
			'search.filters.type' => 'Art',
			'search.filters.movies' => 'Filme',
			'search.filters.series' => 'Serien',
			'search.filters.source' => 'Quelle',
			'search.filters.unknownSource' => 'Unbekannte Quelle',
			'search.filters.year' => 'Jahr',
			'search.filters.language' => 'Sprache',
			'search.filters.languageNote' => 'Aus IPTV-Kategorienamen erraten. Plex-Titel haben hier keine Sprache.',
			'search.filters.genre' => 'Genre',
			'search.filters.rating' => 'Bewertung',
			'search.filters.ratingNote' => 'TMDB-Nutzerbewertung von 10. Titel ohne TMDB-Bewertung werden ausgelassen.',
			'search.filters.originalLanguage' => 'Originalsprache',
			'search.filters.originalLanguageNote' => 'Die Sprache, in der der Titel gedreht wurde, laut TMDB. Eine synchronisierte Fassung behält hier ihre Originalsprache.',
			'search.filters.clear' => 'Zurücksetzen',
			'search.filters.noMatches' => 'Nichts passt zu diesen Filtern.',
			'search.filters.clearAll' => 'Filter zurücksetzen',
			'search.filters.chip' => ({required Object label, required Object value}) => '${label}: ${value}',
			'search.filters.any' => 'Beliebig',
			'search.hint' => 'Deine Quellen durchsuchen',
			'search.prompt' => 'Durchsuche Filme und Serien auf deinem Server.',
			'search.keepTyping' => 'Weiter tippen…',
			'search.noMatch' => ({required Object query}) => 'Nichts passt zu „${query}“.',
			'search.backToResults' => 'Zurück zu den Ergebnissen',
			'search.askAi' => 'KI fragen',
			'search.becauseYouWatched' => 'Weil du gesehen hast: ',
			'settings.about.versionLoading' => 'Version …',
			'settings.about.version' => ({required Object version, required Object build}) => 'Version ${version} (${build})',
			'settings.about.privacyPolicy' => 'Datenschutzerklärung',
			'settings.about.privacySummary' => 'Kein Konto, kein eigener Server und keine Analyse. Die vollständige Erklärung steht unter:',
			'settings.about.licences' => 'Open-Source-Lizenzen',
			'settings.privacy.summary' => 'Subnext Player hat keinen eigenen Server und keine Analyse. Was es speichert, bleibt auf diesem Gerät, und Daten gehen nur an die Quellen, an TMDB und an den KI-Anbieter, die du selbst verbindest.',
			'settings.privacy.cachedData' => 'Zwischengespeicherte Daten',
			'settings.privacy.cachedExplain' => 'Deine Mediathekslisten, TMDB-Abfragen und KI-Vorschläge werden gespeichert, damit die App schnell öffnet. Alte Einträge löschen sich selbst, nach 30 Tagen bei einer Mediathek und nach 90 bei einer Abfrage, und die Daten einer Quelle verschwinden, wenn du sie entfernst. Jetzt zu leeren lässt deine Quellen, Schlüssel, Einstellungen und deinen Verlauf unberührt, und alles wird bei Bedarf neu geladen.',
			'settings.privacy.clearing' => 'Wird geleert...',
			'settings.privacy.clear' => 'Zwischenspeicher leeren',
			'settings.privacy.cleared' => 'Geleert. Deine Mediathek wird neu geladen.',
			'settings.playback.skip' => 'Zurück- und vorspringen',
			'settings.playback.skipExplain' => 'Die Sprungtasten, die Vor- und Rückspultasten einer Fernbedienung und der erste Schritt beim Bewegen auf der Zeitleiste.',
			'settings.playback.audioLanguage' => 'Bevorzugte Audiosprache',
			'settings.playback.audioLanguageExplain' => 'Wird verwendet, wenn eine Datei mehr als eine Audiospur hat. Sonst läuft die Standardspur der Datei.',
			'settings.playback.fileDefault' => 'Standard der Datei',
			'settings.playback.showSubtitles' => 'Untertitel anzeigen',
			'settings.playback.showSubtitlesExplain' => 'Einschalten, wenn eine Datei welche hat. Im Player kannst du jederzeit wechseln.',
			'settings.playback.subtitleLanguage' => 'Bevorzugte Untertitelsprache',
			'settings.playback.subtitleLanguageExplain' => 'Hat eine Datei keine Untertitel in dieser Sprache, werden keine angezeigt.',
			'settings.playback.any' => 'Beliebig',
			'settings.playback.size' => 'Größe',
			'settings.playback.sizeExplain' => 'Für Textuntertitel wie SRT und ASS.',
			'settings.metadata.consent' => 'Dabei wird bei TMDB das Erscheinungsdatum jedes Films und jeder Serie in deiner Mediathek abgefragt, im Hintergrund und immer nur ein paar auf einmal. Dazu wird von jedem der Titel (und das Jahr, falls vorhanden) von diesem Gerät an TMDB gesendet, und an niemanden sonst, nicht nur die, nach denen du suchst. Außerdem werden Genre und Bewertung für die Filter ergänzt. Die Ergebnisse bleiben 90 Tage auf diesem Gerät, und bereits abgefragte Titel werden nicht noch einmal abgefragt.\n\nDu kannst das jederzeit ausschalten. Wenn du deinen TMDB-Schlüssel entfernst, wird es ebenfalls ausgeschaltet.',
			'settings.metadata.consentTitle' => 'Titel deiner Mediathek an TMDB senden?',
			'settings.metadata.notNow' => 'Nicht jetzt',
			'settings.metadata.lookThemUp' => 'Abfragen',
			'settings.metadata.waiting' => 'Warte, bis deine Mediathek geladen ist.',
			'settings.metadata.stopped' => 'Pausiert: TMDB antwortet nicht mehr. Es geht beim nächsten Öffnen der App weiter, und was gefunden wurde, bleibt erhalten.',
			'settings.metadata.running' => ({required Object settled, required Object total}) => '${settled} von ${total} Titeln abgefragt.',
			'settings.metadata.partial' => ({required Object settled, required Object total}) => '${settled} von ${total} Titeln abgefragt. Der Rest folgt beim nächsten Öffnen der App.',
			'settings.metadata.done' => ({required Object found, required Object total}) => 'Fertig: ${found} Erscheinungsdaten für ${total} Titel gefunden.',
			'settings.metadata.releaseDates' => 'Erscheinungsdaten für deine Mediathek',
			'settings.metadata.releaseDatesExplain' => 'Ergänzt im Hintergrund genaue Erscheinungsdaten, damit Sortieren nach Erscheinungsdatum deine Mediathek richtig ordnen kann, auch Titel ohne Jahr. Sendet jeden Titel deiner Mediathek an TMDB.',
			'settings.metadata.intro' => 'Verbinde deinen eigenen TMDB-Schlüssel, um Suchergebnisse um Genre, Bewertung und Originalsprache zu ergänzen und Vorschläge auf Basis dessen zu erhalten, was du gesehen hast. Das ist optional, und nichts ändert sich, bis du einen hinzufügst.',
			'settings.metadata.keyExplain' => 'Die abgefragten Titel werden von diesem Gerät an TMDB gesendet, und an niemanden sonst. Erstelle einen kostenlosen Schlüssel in deinem TMDB-Konto unter Einstellungen, API. Der kurze Schlüssel und das lange Lesezugriffstoken funktionieren beide. Auf einem Fernseher ist es einfacher, ihn zuerst auf einem Handy oder Computer einzufügen oder einzutippen.',
			'settings.metadata.keySaved' => 'TMDB-Schlüssel gespeichert',
			'settings.metadata.removeKey' => 'Schlüssel entfernen',
			'settings.metadata.keyLabel' => 'TMDB-API-Schlüssel',
			'settings.metadata.checking' => 'Wird geprüft...',
			'settings.metadata.verify' => 'Prüfen und speichern',
			'settings.metadata.errors.rejected' => 'TMDB hat diesen Schlüssel abgelehnt.',
			'settings.metadata.errors.rateLimited' => 'TMDB drosselt die Anfragen dieses Geräts.',
			'settings.metadata.errors.unreachable' => ({required Object type}) => 'TMDB war nicht erreichbar (${type}).',
			'settings.ai.intro' => 'Verbinde deinen eigenen Anbieter und deinen eigenen Schlüssel. Anfragen gehen direkt von diesem Gerät an den gewählten Anbieter, nie über uns, denn dazwischen gibt es keinen Server von uns. Es wird nichts gesendet, bevor du unten eine Funktion erlaubst.',
			'settings.ai.address' => 'Adresse',
			'settings.ai.model' => 'Modell',
			'settings.ai.keyOptional' => 'API-Schlüssel (optional bei einem lokalen Server)',
			'settings.ai.key' => 'API-Schlüssel',
			'settings.ai.trying' => 'Wird ausprobiert...',
			'settings.ai.testAndSave' => 'Testen und speichern',
			'settings.ai.onNetwork' => 'In deinem Netzwerk',
			'settings.ai.keySaved' => 'Schlüssel gespeichert',
			'settings.ai.remove' => 'Anbieter entfernen',
			'settings.ai.maySend' => 'Was gesendet werden darf',
			'settings.ai.localNoConsent' => 'Dieser Anbieter ist in deinem eigenen Netzwerk, also erreicht nichts Dritte, und es ist keine Einwilligung nötig.',
			'settings.ai.sendsTo' => ({required Object provider, required Object sends}) => 'Sendet an ${provider}: ${sends}',
			'settings.ai.allowedOn' => ({required Object date}) => 'Erlaubt am ${date}',
			'settings.ai.notAllowed' => 'Noch nicht erlaubt. Du wirst beim ersten Mal gefragt.',
			'settings.ai.switchOff' => 'Ausschalten',
			'settings.ai.allow' => 'Erlauben',
			'settings.appearance.palette.system' => 'System',
			'settings.appearance.palette.midnight' => 'Mitternacht',
			'settings.appearance.palette.slate' => 'Schiefer',
			'settings.appearance.palette.daylight' => 'Tageslicht',
			'settings.appearance.palette.amber' => 'Bernstein',
			'settings.appearance.theme' => 'Design',
			'settings.appearance.accent' => 'Akzentfarbe',
			'settings.section.sources' => 'Quellen',
			'settings.section.appearance' => 'Darstellung',
			'settings.section.playback' => 'Wiedergabe',
			'settings.section.subtitles' => 'Untertitel',
			'settings.section.metadata' => 'Metadaten',
			'settings.section.aiFeatures' => 'KI-Funktionen',
			'settings.section.advancedSources' => 'Erweiterte Quellen',
			'settings.section.transfer' => 'Auf ein anderes Gerät übertragen',
			'settings.section.privacy' => 'Datenschutz und Daten',
			'settings.section.about' => 'Über',
			'settings.section.trackers' => 'Wiedergabe-Tracking',
			'settings.section.requests' => 'Anfragen',
			'settings.advanced.dialogTitle' => 'Erweiterte Quellen einschalten',
			'settings.advanced.dialogLead' => 'Du bist dabei, einen Drittanbieter mit deinen eigenen Zugangsdaten zu verbinden.',
			'settings.advanced.dialogNoContent' => 'Subnext Player stellt keine Inhalte oder Anbieter bereit, hostet sie nicht und unterstützt sie nicht. Du gibst Adresse und Anmeldung an, und die App spielt ab, was diese Adresse liefert.',
			'settings.advanced.dialogRights' => 'Du bist dafür verantwortlich, die Rechte an allem zu haben, womit du dich verbindest.',
			'settings.advanced.dialogConfirm' => 'Verstanden, einschalten',
			'settings.advanced.toggle' => 'IPTV-Anbieter oder Playlist',
			'settings.advanced.toggleExplain' => 'Fügt Live-TV und Xtream-Codes-Anmeldungen hinzu.',
			'settings.advanced.offKeeps' => 'Später ausschalten blendet Live-TV aus, behält aber hinzugefügte Konten.',
			'settings.sources.noServers' => 'Keine Plex-Server verbunden.',
			'settings.sources.remove' => 'Entfernen',
			'settings.sources.loadFailed' => ({required Object error}) => 'Mediatheken dieses Servers konnten nicht geladen werden.\n\n${error}',
			'settings.sources.lookForMore' => 'Nach weiteren Servern suchen',
			'settings.sources.addAnother' => 'Weiteren Server hinzufügen',
			'settings.sources.yours' => 'Deiner',
			'settings.sources.shared' => 'Mit dir geteilt',
			'settings.sources.viaRelay' => 'über Relay',
			'settings.sources.plexType' => ({required Object type}) => 'Plex-Typ: ${type}',
			'settings.sources.changedByYou' => 'von dir geändert',
			'settings.sources.localTab' => 'Lokal & Netzwerk anzeigen',
			'settings.sources.localTabSub' => 'Ein Tab auf der Startseite für Videos auf diesem Gerät und in Netzwerkfreigaben. Er schaltet sich von selbst ein, wenn du eine hinzufügst.',
			'onboarding.tagline' => 'Spiel ab, was deine verbundenen Quellen bieten.',
			'onboarding.blurb' => 'Subnext Player spielt aus Quellen ab, die du selbst verbindest: einem Plex-Server, einem NAS zu Hause oder lokalen Dateien, oder optional einem IPTV-Anbieter oder einer Playlist. Wir hosten keine Inhalte.',
			'onboarding.localDesktop' => 'Dateien auf diesem PC oder ein Ordner auf einem NAS zu Hause oder einer SMB-Freigabe.',
			'onboarding.localTv' => 'Ein Ordner auf einem NAS zu Hause oder einer SMB-Freigabe.',
			'onboarding.local' => 'Videos auf diesem Gerät oder ein Ordner auf einem NAS zu Hause oder einer SMB-Freigabe.',
			'onboarding.plexTv' => 'Melde dich auf diesem Fernseher mit deinem eigenen Konto an.',
			'onboarding.plex' => 'Deine persönliche Mediathek, mit deinem eigenen Konto.',
			'onboarding.advancedTv' => 'Standardmäßig aus. In den Einstellungen einschalten.',
			'onboarding.advanced' => 'Standardmäßig aus. In den Einstellungen einschalten, um einen IPTV-Anbieter oder eine Playlist zu nutzen.',
			'onboarding.localTitle' => 'Lokal & Netzwerk',
			'onboarding.advancedTitle' => 'Erweiterte Quellen',
			'onboarding.addFirst' => 'Erste Quelle hinzufügen',
			'onboarding.notNow' => 'Nicht jetzt',
			'onboarding.connect' => 'Quelle verbinden',
			'onboarding.addSource' => 'Quelle hinzufügen',
			'onboarding.okKey' => 'OK',
			'onboarding.toSelect' => 'zum Auswählen',
			'addSource.privacy' => 'Zugangsdaten bleiben auf diesem Gerät. Nichts wird an uns gesendet: Es gibt kein Konto und keinen Server dazwischen.',
			'addSource.kind.plex' => 'Plex-Server',
			'addSource.kind.plexShort' => 'Mit Code verknüpfen',
			'addSource.kind.plexLong' => 'Gib dieses Gerät in deinem Browser frei. Dein eigener Server und alles, was mit dir geteilt wird.',
			'addSource.kind.localFiles' => 'Videos auf diesem Gerät',
			'addSource.kind.localFilesSub' => 'Durchsuche deine Medienbibliothek oder wähle einen einzelnen Ordner, auf den der Zugriff bleiben soll.',
			'addSource.kind.localFilesIos' => 'Spiel die Videos aus deiner Fotomediathek ab.',
			'addSource.kind.smb' => 'Netzwerkfreigabe (SMB)',
			'addSource.kind.smbSub' => 'Ein NAS oder eine Windows-Freigabe in deinem Heimnetz.',
			'addSource.kind.xtream' => 'Xtream-Codes-Anmeldung',
			'addSource.kind.xtreamSub' => 'Host, Benutzername und Passwort von deinem Anbieter.',
			'addSource.kind.mediaBrowser' => 'Jellyfin- oder Emby-Server',
			'addSource.kind.mediaBrowserSub' => 'Dein eigener Server, mit deinem eigenen Konto.',
			'addSource.copyFromDevice' => 'Von einem anderen Gerät kopieren',
			'addSource.copyFromDeviceSub' => 'Schon auf deinem Handy eingerichtet? Schick es hierher, statt alles neu einzutippen.',
			'addSource.title' => 'Quelle hinzufügen',
			'addSource.advanced' => 'Erweiterte Quellen',
			'addSource.or' => 'Oder',
			'addSource.advancedHintLead' => 'Suchst du einen IPTV-Anbieter oder eine Playlist? Schalte ',
			'addSource.advancedHintTail' => ' in den Einstellungen ein.',
			'addSource.sourceType' => 'Art der Quelle',
			'addSource.plexRail' => 'Mit einem Code verknüpfen',
			'addSource.pcFiles' => 'Dateien auf diesem PC',
			'addSource.pcFilesSub' => 'Ordner auswählen',
			'addSource.smbRail' => 'NAS oder Windows-Freigabe',
			'addSource.copyRail' => 'Vom Handy aus senden',
			'addSource.keystore' => 'Zugangsdaten werden im Schlüsselspeicher des Geräts abgelegt, nie in der Datenbank der App.',
			'addSource.pick' => 'Wähle zum Start eine Art von Quelle.',
			'plex.connected' => 'Plex verbunden.',
			'plex.connectedTo' => ({required Object name}) => 'Mit ${name} verbunden.',
			'plex.opening' => 'Verbunden. Deine Mediathek wird geöffnet…',
			'plex.connect' => 'Mit Plex verbinden',
			'plex.explain' => 'Subnext Player spielt ab, was dein eigener Plex-Server bereits hat. Es wird nichts hochgeladen, und deine Kontodaten erreichen niemanden außer Plex.',
			'plex.contacting' => 'Plex wird kontaktiert…',
			'plex.enterCode' => 'Öffne auf einem beliebigen Gerät plex.tv/link und gib ein:',
			'plex.waiting' => 'Warte auf Freigabe…',
			'plex.copyCode' => 'Code kopieren',
			'plex.chooseServer' => 'Server auswählen',
			'plex.allConnected' => 'Alle Server dieses Kontos sind bereits verbunden.',
			'plex.yourServers' => 'Deine Server',
			'plex.sharedWithYou' => 'Mit dir geteilt',
			'plex.connecting' => 'Wird verbunden… das kann ein paar Sekunden dauern',
			'plex.offline' => 'Offline',
			'plex.relayOnly' => 'Nur über Plex Relay, die Wiedergabe kann eingeschränkt sein',
			'plex.codeExpired' => 'Dieser Code ist abgelaufen. Versuch es erneut.',
			'plex.noServers' => 'Dieses Konto hat keine Plex-Server.',
			'plex.errors.noAnswer' => ({required Object server, required Object count}) => '„${server}“ hat unter keiner seiner ${count} angegebenen Adressen geantwortet.',
			'plex.errors.itemGone' => 'Dieser Eintrag ist nicht mehr auf dem Server.',
			'plex.errors.noFile' => 'Keine abspielbare Datei für diesen Eintrag. Quellen, die nur transkodiert abspielbar sind, werden noch nicht unterstützt.',
			'plex.errors.notConnected' => 'Nicht mit einem Plex-Server verbunden.',
			'local.noAccess' => ({required Object where}) => 'Subnext Player kann deine Videos ohne Medienzugriff nicht sehen. Du kannst ihn in ${where} erteilen.',
			'local.settingsIos' => 'der App Einstellungen',
			'local.settingsAndroid' => 'den Android-Einstellungen',
			'local.intro' => 'Spiel Videos ab, die auf diesem Gerät gespeichert sind.\nSubnext Player fragt nur nach Zugriff auf Videos, nie auf alle Dateien.',
			'local.allowAccess' => 'Zugriff auf Videos erlauben',
			'local.pickFolderInstead' => 'Oder stattdessen einen Ordner wählen',
			'local.addShare' => 'Netzwerkfreigabe hinzufügen',
			'local.shares' => 'Netzwerkfreigaben',
			'local.pickedFolders' => 'Ausgewählte Ordner',
			'local.onDevice' => 'Auf diesem Gerät',
			'local.noVideos' => 'Keine Videos auf diesem Gerät gefunden.',
			'local.addFolderShort' => 'Ordner hinzufügen',
			'local.addShareShort' => 'Freigabe hinzufügen',
			'local.scanDevice' => 'Dieses Gerät durchsuchen',
			'local.forgetFolder' => 'Diesen Ordner vergessen',
			'local.folder' => 'Ordner',
			'local.safUnreadable' => ({required Object error}) => 'Dieser Ordner ist nicht mehr lesbar. Vielleicht hat Android die Berechtigung entzogen, also entferne ihn und wähle ihn erneut.\n\n${error}',
			'local.safEmpty' => 'Hier sind keine Videos oder Unterordner.',
			'smb.connectFailed' => ({required Object error}) => 'Verbindung fehlgeschlagen: ${error}',
			'smb.title' => 'Netzwerkfreigabe hinzufügen',
			'smb.explain' => 'Ein NAS oder ein freigegebener Ordner auf einem anderen Computer in deinem Netzwerk.',
			'smb.host' => 'Serveradresse',
			'smb.hostHint' => 'z. B. nas',
			'smb.username' => 'Benutzername',
			'smb.password' => 'Passwort',
			'smb.domain' => 'Domäne (optional)',
			'smb.name' => 'Name (optional)',
			'smb.connectAndAdd' => 'Verbinden und hinzufügen',
			'smb.gone' => 'Diese Freigabe ist nicht mehr eingerichtet.',
			'smb.unreachable' => ({required Object error}) => 'Diese Freigabe war nicht erreichbar. Der Server ist vielleicht im Ruhezustand oder nicht im Netzwerk.\n\n${error}',
			'smb.empty' => 'Hier sind keine Videos oder Ordner.',
			'xtream.lineGone' => 'Dieser Zugang ist nicht mehr eingerichtet.',
			'xtream.catalogue.live' => 'Live-TV',
			'xtream.catalogue.vod' => 'Filme',
			'xtream.catalogue.series' => 'Serien',
			'xtream.errors.status' => ({required Object code}) => 'Das Panel hat ${code} geliefert. Versuch es später noch einmal.',
			'xtream.errors.timeout' => 'Das Panel hat nicht rechtzeitig geantwortet.',
			'xtream.errors.unreachable' => 'Diese Adresse war nicht erreichbar. Prüfe Host und Port.',
			'xtream.errors.other' => ({required Object type}) => 'Keine Verbindung zum Panel möglich (${type}).',
			'xtream.errors.notXtream' => 'Diese Adresse hat nicht wie ein Xtream-Panel geantwortet.',
			'xtream.errors.rejected' => 'Das Panel hat diese Zugangsdaten abgelehnt.',
			'xtream.errors.wrongLogin' => 'Falscher Benutzername oder falsches Passwort.',
			'xtream.errors.unnamed' => 'Ohne Namen',
			'xtream.errors.episode' => 'Folge',
			'xtream.errors.noPassword' => 'Für diesen Zugang ist kein Passwort gespeichert. Entferne ihn und füge ihn erneut hinzu.',
			'xtream.everythingElse' => 'Alles andere',
			'xtream.series.title' => 'Serie',
			'xtream.series.noEpisodes' => 'Das Panel hat für diese Serie keine Folgen geliefert.',
			'xtream.series.season' => ({required Object n}) => 'Staffel ${n}',
			'xtream.remove' => 'Entfernen',
			'xtream.add' => 'Playlist oder Panel hinzufügen',
			'xtream.addLine.discardTitle' => 'Diesen Zugang verwerfen?',
			'xtream.addLine.discardBody' => 'Was du hier eingegeben hast, wurde nicht gespeichert.',
			'xtream.addLine.discard' => 'Verwerfen',
			'xtream.addLine.keepEditing' => 'Weiter bearbeiten',
			'xtream.addLine.inactive' => ({required Object status}) => 'Laut Panel ist dieser Zugang „${status}“.',
			'xtream.addLine.noContent' => 'Subnext Player stellt keine Inhalte oder Anbieter bereit, hostet sie nicht und unterstützt sie nicht. Du gibst Adresse und Anmeldung an, und die App spielt ab, was diese Adresse liefert.',
			'xtream.addLine.host' => 'Serveradresse',
			'xtream.addLine.name' => 'Name (optional)',
			'xtream.addLine.nameHint' => 'Wie du diesen Zugang nennen möchtest',
			'xtream.addLine.checking' => 'Wird geprüft…',
			'xtream.addLine.verify' => 'Prüfen und hinzufügen',
			'xtream.addLine.connected' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: 'Verbunden. ${n} gleichzeitiger Stream erlaubt.', other: 'Verbunden. ${n} gleichzeitige Streams erlaubt.', ), 
			'xtream.picker.patternNone' => 'Dieses Muster hat nichts gefunden.',
			'xtream.picker.title' => ({required Object catalogue}) => 'Kategorien: ${catalogue}',
			'xtream.picker.save' => 'Speichern',
			'xtream.picker.noMatch' => ({required Object query}) => 'Nichts passt zu „${query}“.',
			'xtream.picker.noneChosen' => 'Noch nichts ausgewählt.',
			'xtream.picker.search' => 'Alle Kategorien durchsuchen',
			'xtream.picker.chosen' => ({required Object n}) => 'Ausgewählt ${n}',
			'xtream.picker.hideWords' => 'Wörter ausblenden',
			'xtream.picker.hideCount' => ({required Object n}) => 'Ausgeblendet ${n}',
			'xtream.picker.pattern' => 'Muster',
			'xtream.picker.untickedOne' => ({required Object name, required Object word}) => '„${name}“ wurde abgewählt, weil „${word}“ es ausblendet. Speichern, um das zu behalten.',
			'xtream.picker.untickedMany' => ({required Object n, required Object word}) => '${n} ausgewählte Kategorien, die „${word}“ ausblendet, wurden abgewählt. Speichern, um das zu behalten.',
			'xtream.picker.showingHidden' => 'Angezeigt werden die Kategorien, die deine ausgeblendeten Wörter auslassen.',
			'xtream.picker.hiddenCount' => ({required Object n}) => '${n} durch deine Wörter ausgeblendet.',
			'xtream.picker.hideAgain' => 'Wieder ausblenden',
			'xtream.picker.showThem' => 'Anzeigen',
			'xtream.picker.patternHint' => 'Alle Kategorien auswählen oder abwählen, die zu einem Wort oder Muster passen',
			'xtream.picker.selectMatching' => 'Treffer auswählen',
			'xtream.picker.deselectMatching' => 'Treffer abwählen',
			'xtream.picker.groups' => 'Gruppen',
			'xtream.picker.clearAll' => 'Alle abwählen',
			'xtream.picker.selectAll' => 'Alle auswählen',
			'xtream.picker.channelsPicked' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${n} Sender', other: '${n} Sender', ), 
			'xtream.picker.pickedChosen' => ({required Object n}) => '${n} ausgewählt',
			'xtream.picker.categories' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${n} Kategorie', other: '${n} Kategorien', ), 
			'xtream.picker.channels' => 'Sender',
			'xtream.channels.done' => 'Fertig',
			'xtream.channels.search' => 'Diese Kategorie durchsuchen',
			'xtream.channels.pickedOf' => ({required Object picked, required Object total}) => '${picked} von ${total}',
			'xtream.channels.whole' => 'Ganze Kategorie',
			'xtream.channels.selectShown' => 'Angezeigte auswählen',
			'xtream.channels.clear' => 'Abwählen',
			'xtream.channels.clearShown' => 'Angezeigte abwählen',
			'xtream.channels.none' => 'Das Panel listet in dieser Kategorie keine Sender.',
			'xtream.hidden.title' => 'Wörter ausblenden',
			'xtream.hidden.explain' => 'Eine Kategorie oder ein Sender, der eines dieser Wörter als ganzes Wort enthält, wird aus den Listen ausgelassen. „UK“ blendet „UK News“ aus, aber nicht „Ukraine“. Füge eine Wortgruppe wie „south indian“ hinzu, um sie als Ganzes auszublenden. Groß- und Kleinschreibung spielt keine Rolle.',
			_ => null,
		} ?? switch (path) {
			'xtream.hidden.hint' => 'Ein Land, eine Sprache, ein Wort',
			'xtream.hidden.add' => 'Hinzufügen',
			'xtream.hidden.none' => 'Noch nichts ausgeblendet.',
			'xtream.hidden.tapToRemove' => 'Wähle ein Wort aus, um es nicht mehr auszublenden.',
			'transfer.noNetwork' => 'Dieses Gerät ist in keinem WLAN- oder Ethernet-Netzwerk. Verbinde es mit demselben Netzwerk wie das andere Gerät und versuch es erneut.',
			'transfer.cannotListen' => ({required Object error}) => 'Empfang konnte nicht gestartet werden: ${error}',
			'transfer.expired' => 'Dieser Code ist abgelaufen. Starte neu, um einen neuen zu bekommen.',
			'transfer.wentWrong' => ({required Object error}) => 'Etwas ist schiefgelaufen: ${error}',
			'transfer.wentWrongPlain' => 'Etwas ist schiefgelaufen.',
			'transfer.gettingReady' => 'Wird vorbereitet…',
			'transfer.waitingOther' => 'Warte auf das andere Gerät…',
			'transfer.copyCode' => 'Code kopieren',
			'transfer.scanInstead' => 'Stattdessen seinen Code scannen',
			'transfer.typeInstead' => 'Stattdessen seinen Code eingeben',
			'transfer.done' => 'Fertig',
			'transfer.close' => 'Schließen',
			'transfer.receive.cannotSave' => ({required Object error}) => 'Die Einstellungen konnten nicht gespeichert werden: ${error}',
			'transfer.receive.title' => 'Einstellungen empfangen',
			'transfer.receive.asking' => 'Das andere Gerät wird gefragt…',
			'transfer.receive.awaitingPush' => 'Warte, bis das andere Gerät sendet. Stimm dort zu, wenn es fragt.',
			'transfer.receive.saving' => 'Wird gespeichert…',
			'transfer.receive.waitingInstructions' => 'Öffne auf dem Gerät mit deinen Einstellungen Einstellungen, Auf ein anderes Gerät übertragen, und wähle Senden. Scanne dann diesen Code.',
			'transfer.receive.scanInstructions' => 'Öffne auf dem Gerät mit deinen Einstellungen Einstellungen, Auf ein anderes Gerät übertragen, und wähle Senden und dann Code anzeigen. Richte die Kamera darauf.',
			'transfer.receive.showMine' => 'Stattdessen meinen Code anzeigen',
			'transfer.receive.typeInstructions' => 'Öffne auf dem Gerät mit deinen Einstellungen Einstellungen, Auf ein anderes Gerät übertragen, und wähle Senden und dann Code anzeigen. Gib dann ein, was es anzeigt.',
			'transfer.receive.connect' => 'Verbinden',
			'transfer.receive.review' => 'Ein anderes Gerät möchte dir das hier senden. Was hier schon unter demselben Namen existiert, wird ersetzt; sonst wird nichts entfernt.',
			'transfer.receive.saveThese' => 'Speichern',
			'transfer.receive.decline' => 'Ablehnen',
			'transfer.receive.saved' => 'Fertig. Deine Einstellungen sind auf diesem Gerät.',
			'transfer.pairing.noCamera' => 'Keine Kamera? Wähle dort Code eingeben und gib ein:',
			'transfer.pairing.qrLabel' => 'Code zum Scannen vom anderen Gerät',
			'transfer.pairing.cameraOff' => 'Die Kamera ist für diese App ausgeschaltet. Gib stattdessen den Code ein oder erlaube die Kamera in den Einstellungen deines Handys.',
			'transfer.pairing.cameraFailed' => 'Die Kamera konnte nicht starten. Gib stattdessen den Code ein.',
			'transfer.pairing.foreign' => 'Das ist kein Code aus dieser App.',
			'transfer.pairing.checkEntry' => 'Prüfe die Adresse (etwa 192.168.1.20:41234) und den 16-stelligen Code.',
			'transfer.pairing.address' => 'Adresse',
			'transfer.pairing.code' => 'Code',
			'transfer.pane.explain' => 'Kopiere deine Quellen, Schlüssel und Einstellungen auf ein anderes Gerät im selben WLAN, damit du sie nicht noch einmal eintippen musst. Es geht direkt von einem Gerät zum anderen, verschlüsselt mit einem Code, den nur die beiden Bildschirme kennen, und das empfangende Gerät fragt, bevor es etwas speichert.',
			'transfer.pane.notCopied' => 'Nicht kopiert: Plex (verknüpfe es auf dem anderen Gerät mit dessen eigenem Code), Verlauf, Favoriten und die Einwilligung für Erweiterte Quellen und KI-Funktionen, die jedes Gerät selbst einholt.',
			'transfer.pane.receive' => 'Von einem anderen Gerät empfangen',
			'transfer.pane.send' => 'An ein anderes Gerät senden',
			'transfer.notes.aiLocal' => 'Dein KI-Anbieter läuft auf diesem Gerät, deshalb wird er nicht gesendet. Richte ihn dort mit der Adresse dieses Geräts in deinem Netzwerk neu ein.',
			'transfer.notes.xtreamHidden' => 'Die IPTV-Konten sind gespeichert, aber ausgeblendet. Schalte Erweiterte Quellen in den Einstellungen ein, um sie zu nutzen.',
			'transfer.notes.aiAsks' => 'KI-Funktionen fragen, bevor sie etwas an den Anbieter senden.',
			'transfer.notes.partial' => ({required Object failed}) => 'Nicht gespeichert: ${failed}. Der Rest wurde gespeichert.',
			'transfer.send.cannotRead' => ({required Object error}) => 'Die Einstellungen dieses Geräts konnten nicht gelesen werden: ${error}',
			'transfer.send.askTitle' => ({required Object host}) => 'An ${host} senden?',
			'transfer.send.askBody' => ({required Object summary}) => 'Ein Gerät in deinem Netzwerk hat diesen Code gescannt und fragt nach:\n\n${summary}\n\nStimm nur zu, wenn du das gerade auf diesem Gerät angefordert hast.',
			'transfer.send.notNow' => 'Nicht jetzt',
			'transfer.send.send' => 'Senden',
			'transfer.send.title' => 'Einstellungen senden',
			'transfer.send.reading' => 'Deine Einstellungen werden gelesen…',
			'transfer.send.sending' => 'Wird gesendet. Das andere Gerät fragt, bevor es etwas speichert.',
			'transfer.send.explain' => 'Kopiert das hier auf ein anderes Gerät im selben WLAN, damit du es nicht noch einmal eintippen musst. Es geht direkt dorthin und ist verschlüsselt; nichts läuft über uns.',
			'transfer.send.nothing' => 'Auf diesem Gerät ist noch nichts eingerichtet, das gesendet werden könnte.',
			'transfer.send.proceed' => 'Weiter',
			'transfer.send.showInstead' => 'Stattdessen einen Code anzeigen',
			'transfer.send.typeInstead' => 'Stattdessen den Code eingeben',
			'transfer.send.scanInstructions' => 'Öffne auf dem anderen Gerät Einstellungen, Auf ein anderes Gerät übertragen, und wähle Empfangen. Richte die Kamera auf den Code, den es anzeigt.',
			'transfer.send.showInstructions' => 'Öffne auf dem anderen Gerät Einstellungen, Auf ein anderes Gerät übertragen, und wähle Empfangen und dann Seinen Code scannen, und richte seine Kamera hierher. Du wirst gefragt, bevor etwas gesendet wird.',
			'transfer.send.typeInstructions' => 'Öffne auf dem anderen Gerät Einstellungen, Auf ein anderes Gerät übertragen, und wähle Empfangen. Gib dann ein, was es anzeigt.',
			'transfer.send.sent' => 'Gesendet. Das andere Gerät hat deine Einstellungen gespeichert.',
			'transfer.item.preferences' => 'Einstellungen',
			'transfer.item.preferencesSub' => 'Wiedergabe- und Untertitelwahl, ausgeblendete Wörter und Platzierung in der Mediathek.',
			'transfer.item.xtream' => 'IPTV-Konten',
			'transfer.item.xtreamSub' => 'Anmeldungen und die gewählten Kategorien und Sender.',
			'transfer.item.smb' => 'Netzwerkfreigaben',
			'transfer.item.smbSub' => 'SMB-Freigaben und ihre Passwörter.',
			'transfer.item.tmdb' => 'TMDB-Schlüssel',
			'transfer.item.tmdbSub' => 'Dein eigener Schlüssel für die Filter nach Genre, Bewertung und Sprache.',
			'transfer.item.ai' => 'KI-Anbieter',
			'transfer.item.aiSub' => 'Der Anbieter, sein Modell und dein Schlüssel.',
			'transfer.item.settings' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${n} Einstellung', other: '${n} Einstellungen', ), 
			'transfer.item.accounts' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${n} Konto', other: '${n} Konten', ), 
			'transfer.item.shares' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${n} Freigabe', other: '${n} Freigaben', ), 
			'transfer.item.notBundle' => 'Das war kein Einstellungspaket.',
			'transfer.item.newer' => 'Dieses Paket stammt aus einer neueren Version der App. Aktualisiere dieses Gerät und versuch es erneut.',
			'transfer.item.trackers' => 'Wiedergabe-Tracking',
			'transfer.item.trackersSub' => 'Deine Anmeldungen bei Trakt, Simkl, AniList und MyAnimeList. Sie hier anzunehmen heißt zuzustimmen, dass auch auf diesem Gerät Gesehenes gesendet wird.',
			'transfer.item.services' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${n} Dienst', other: '${n} Dienste', ), 
			'transfer.client.declined' => 'Das andere Gerät hat die Einstellungen nicht angenommen.',
			'transfer.client.wrongCode' => 'Der Code war nicht richtig. Vergleich ihn mit dem anderen Bildschirm.',
			'transfer.client.used' => 'Das andere Gerät hat schon etwas empfangen. Öffne dort Empfangen erneut, um einen neuen Code zu bekommen.',
			'transfer.client.tooBig' => 'Das war zu viel zum Senden.',
			'transfer.client.unreadable' => 'Das andere Gerät konnte das nicht lesen.',
			'transfer.client.unexpected' => ({required Object status}) => 'Das andere Gerät hat unerwartet geantwortet (${status}).',
			'transfer.client.refusedToSend' => 'Das andere Gerät hat dem Senden seiner Einstellungen nicht zugestimmt.',
			'transfer.client.busy' => 'Das andere Gerät antwortet bereits jemand anderem. Bitte es um einen neuen Code.',
			'transfer.client.unreachable' => ({required Object address}) => '${address} war nicht erreichbar. Beide Geräte müssen im selben WLAN sein, und das andere muss seinen Code noch anzeigen.',
			'transfer.client.dropped' => 'Die Verbindung ist zwischendurch abgebrochen.',
			'transfer.client.noAnswer' => ({required Object address}) => 'Keine Antwort von ${address}. Prüfe den anderen Bildschirm.',
			'mediaBrowser.errors.signedOut' => ({required Object server}) => '${server} akzeptiert diese Anmeldung nicht mehr. Entferne ihn unter Einstellungen, Quellen und füge ihn erneut hinzu.',
			'mediaBrowser.errors.status' => ({required Object server, required Object code}) => '${server} hat mit ${code} geantwortet.',
			'mediaBrowser.errors.unreachable' => ({required Object server}) => '${server} war nicht erreichbar. Er ist vielleicht im Ruhezustand oder nicht im Netzwerk.',
			'mediaBrowser.errors.notAServer' => 'Unter dieser Adresse hat kein Jellyfin- oder Emby-Server geantwortet. Prüfe sie, auch den Port (meist 8096).',
			'mediaBrowser.errors.badAnswer' => 'Der Server hat auf eine Weise geantwortet, die diese App nicht versteht.',
			'mediaBrowser.errors.wrongLogin' => 'Falscher Benutzername oder falsches Passwort.',
			'mediaBrowser.title' => 'Mit Jellyfin oder Emby verbinden',
			'mediaBrowser.explain' => 'Subnext Player spielt ab, was dein eigener Server bereits hat. Deine Anmeldung bleibt auf diesem Gerät und erreicht niemanden außer deinem Server.',
			'mediaBrowser.address' => 'Serveradresse',
			'mediaBrowser.addressHint' => 'z. B. 192.168.1.20:8096',
			'mediaBrowser.find' => 'Server suchen',
			'mediaBrowser.finding' => 'Server wird gesucht…',
			'mediaBrowser.found' => ({required Object name, required Object kind, required Object version}) => '${name} · ${kind} ${version}',
			'mediaBrowser.username' => 'Benutzername',
			'mediaBrowser.password' => 'Passwort',
			'mediaBrowser.signIn' => 'Anmelden',
			'mediaBrowser.signingIn' => 'Wird angemeldet…',
			'mediaBrowser.useQuickConnect' => 'Stattdessen Quick Connect verwenden',
			'mediaBrowser.usePassword' => 'Stattdessen Benutzername und Passwort verwenden',
			'mediaBrowser.quickConnectExplain' => 'Öffne auf einem Handy oder Computer, der schon bei Jellyfin angemeldet ist, dein Profil, Quick Connect, und gib ein:',
			'mediaBrowser.waiting' => 'Warte auf Freigabe…',
			'mediaBrowser.otherAddress' => 'Andere Adresse verwenden',
			'mediaBrowser.connected' => ({required Object name}) => 'Mit ${name} verbunden.',
			'trackers.errors.unavailable' => ({required Object service}) => '${service} war nicht erreichbar. Es wird erneut versucht.',
			'trackers.errors.denied' => 'Die Anmeldung wurde abgelehnt.',
			'trackers.errors.expired' => 'Dieser Code ist abgelaufen. Starte neu, um einen neuen zu bekommen.',
			'trackers.errors.badPaste' => 'Das ist nicht, was die Anmeldeseite angezeigt hat. Kopiere es erneut und füge alles ein.',
			'trackers.malCaught' => 'Angemeldet. Du kannst dieses Fenster schließen und zu Subnext Player zurückkehren.',
			'trackers.intro' => 'Sende, was du auf deinen eigenen Servern zu Ende schaust, an einen Verlaufsdienst. Nichts aus IPTV wird gesendet, und nichts geht an uns.',
			'trackers.animeNote' => 'AniList und MyAnimeList bekommen nur Titel, die dein Server als Anime kennzeichnet, gesucht nach Namen.',
			'trackers.signedInAs' => ({required Object name}) => 'Angemeldet als ${name}',
			'trackers.signedIn' => 'Angemeldet',
			'trackers.notConnected' => 'Nicht verbunden',
			'trackers.signIn' => 'Anmelden',
			'trackers.signOut' => 'Abmelden',
			'trackers.pending' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '1 Wiedergabe wartet darauf, gesendet zu werden.', other: '${n} Wiedergaben warten darauf, gesendet zu werden.', ), 
			'trackers.consentTitle' => ({required Object service}) => 'Deine Wiedergaben an ${service} senden?',
			'trackers.consentBody' => ({required Object service}) => 'Wenn du einen Film oder eine Folge von deinem eigenen Plex-, Jellyfin- oder Emby-Server zu Ende schaust, sendet Subnext Player an ${service} den Titel, das Jahr, die IMDb-, TMDB- oder TVDB-ID und wann du es gesehen hast. Es geht direkt von diesem Gerät an ${service}, nie über uns. Nichts aus IPTV wird gesendet. Du kannst dich jederzeit unter Einstellungen, Wiedergabe-Tracking abmelden.',
			'trackers.consentAnime' => ({required Object service}) => 'An ${service} gehen nur Titel, die dein Server als Anime kennzeichnet, und sie werden über eine Suche nach ihrem Namen bei ${service} gefunden.',
			'trackers.agree' => 'Weiter',
			'trackers.notNow' => 'Nicht jetzt',
			'trackers.signInTitle' => ({required Object service}) => 'Bei ${service} anmelden',
			'trackers.deviceCodeExplain' => ({required Object url}) => 'Öffne auf einem beliebigen Gerät ${url} und gib ein:',
			'trackers.waiting' => 'Warte auf Freigabe…',
			'trackers.browserExplain' => ({required Object service}) => 'Öffne diese Adresse in einem Browser, melde dich bei ${service} an und erlaube Subnext Player. Füge dann unten ein, was ${service} dir gibt.',
			'trackers.anilistPaste' => 'AniList zeigt nach der Freigabe ein langes Token an. Kopiere es vollständig.',
			'trackers.malPaste' => 'Auf diesem Gerät schließt die App die Anmeldung selbst ab. War der Browser woanders, endet er auf einer Seite, die nicht lädt: Kopiere deren vollständige Adresse.',
			'trackers.tvHint' => 'Auf einem Fernseher melde dich auf dem Handy an und übertrage es mit Auf ein anderes Gerät übertragen hierher.',
			'trackers.pasteLabel' => 'Hier einfügen',
			'trackers.finish' => 'Anmeldung abschließen',
			'trackers.copyAddress' => 'Adresse kopieren',
			'trackers.connected' => ({required Object service}) => 'Mit ${service} verbunden.',
			'seerr.errors.notASeerr' => 'Unter dieser Adresse hat kein Overseerr-, Jellyseerr- oder Seerr-Server geantwortet. Prüfe sie, auch den Port (meist 5055).',
			'seerr.errors.badKey' => 'Der Server hat diesen API-Schlüssel nicht angenommen.',
			'seerr.errors.refused' => 'Der Server hat diese Anmeldung nicht angenommen.',
			'seerr.errors.status' => ({required Object code}) => 'Der Server hat mit ${code} geantwortet.',
			'seerr.errors.unreachable' => 'Der Anfrage-Server war nicht erreichbar.',
			'seerr.errors.signedOut' => 'Der Anfrage-Server akzeptiert diese Anmeldung nicht mehr. Verbinde ihn erneut unter Einstellungen, Anfragen.',
			'seerr.errors.alreadyRequested' => 'Das wurde bereits angefragt.',
			'seerr.intro' => 'Verbinde deinen eigenen Overseerr-, Jellyseerr- oder Seerr-Server, um Filme und Serien anzufragen, die deine Mediathek noch nicht hat. Anfragen gehen an deinen Server und nirgendwo sonst; wer ihn betreibt, entscheidet über den Rest.',
			'seerr.address' => 'Serveradresse',
			'seerr.addressHint' => 'z. B. 192.168.1.20:5055',
			'seerr.find' => 'Server suchen',
			'seerr.withPlex' => 'Mit meinem Plex-Konto anmelden',
			'seerr.withPassword' => 'Mit Benutzername und Passwort anmelden',
			'seerr.withKey' => 'API-Schlüssel verwenden',
			'seerr.username' => 'Benutzername oder E-Mail',
			'seerr.password' => 'Passwort',
			'seerr.apiKey' => 'API-Schlüssel',
			'seerr.keyNote' => 'Ein API-Schlüssel handelt als Administrator des Servers, Anfragen damit laufen also nicht unter deinem Namen. Melde dich lieber an.',
			'seerr.connect' => 'Verbinden',
			'seerr.connecting' => 'Wird verbunden…',
			'seerr.connected' => ({required Object title, required Object name}) => 'Mit ${title} verbunden als ${name}',
			'seerr.disconnect' => 'Trennen',
			'seerr.myRequests' => 'Deine letzten Anfragen',
			'seerr.none' => 'Noch keine Anfragen.',
			'seerr.statusPending' => 'Wartet auf Freigabe',
			'seerr.statusApproved' => 'Freigegeben',
			'seerr.statusDeclined' => 'Abgelehnt',
			'seerr.statusAvailable' => 'Verfügbar',
			'seerr.rowTitle' => ({required Object title}) => 'Bei ${title} anfragen',
			'seerr.requested' => 'Angefragt',
			'seerr.partial' => 'Teilweise verfügbar',
			'seerr.askTitle' => ({required Object title}) => '${title} anfragen?',
			'seerr.askMovie' => ({required Object server}) => 'Damit bittest du ${server}, den Film hinzuzufügen. Wer ihn betreibt, entscheidet darüber.',
			'seerr.askShow' => ({required Object server}) => 'Damit bittest du ${server}, alle Staffeln hinzuzufügen. Wer ihn betreibt, entscheidet darüber.',
			'seerr.request' => 'Anfragen',
			'seerr.sent' => ({required Object title}) => '${title} angefragt.',
			_ => null,
		};
	}
}
