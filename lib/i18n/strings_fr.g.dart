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
class TranslationsFr extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsFr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.fr,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <fr>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsFr _root = this; // ignore: unused_field

	@override 
	TranslationsFr $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsFr(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$common$fr common = _Translations$common$fr._(_root);
	@override late final _Translations$player$fr player = _Translations$player$fr._(_root);
	@override Map<String, String> get languages => {
		'en': 'Anglais',
		'es': 'Espagnol',
		'fr': 'Français',
		'de': 'Allemand',
		'it': 'Italien',
		'pt': 'Portugais',
		'nl': 'Néerlandais',
		'sv': 'Suédois',
		'no': 'Norvégien',
		'da': 'Danois',
		'fi': 'Finnois',
		'pl': 'Polonais',
		'cs': 'Tchèque',
		'hu': 'Hongrois',
		'ro': 'Roumain',
		'el': 'Grec',
		'ru': 'Russe',
		'uk': 'Ukrainien',
		'tr': 'Turc',
		'ar': 'Arabe',
		'he': 'Hébreu',
		'hi': 'Hindi',
		'bn': 'Bengali',
		'pa': 'Pendjabi',
		'ta': 'Tamoul',
		'te': 'Télougou',
		'ur': 'Ourdou',
		'th': 'Thaï',
		'vi': 'Vietnamien',
		'id': 'Indonésien',
		'zh': 'Chinois',
		'ja': 'Japonais',
		'ko': 'Coréen',
	};
	@override late final _Translations$subtitleSize$fr subtitleSize = _Translations$subtitleSize$fr._(_root);
	@override late final _Translations$units$fr units = _Translations$units$fr._(_root);
	@override late final _Translations$downloads$fr downloads = _Translations$downloads$fr._(_root);
	@override late final _Translations$watchActions$fr watchActions = _Translations$watchActions$fr._(_root);
	@override late final _Translations$show$fr show = _Translations$show$fr._(_root);
	@override late final _Translations$shell$fr shell = _Translations$shell$fr._(_root);
	@override late final _Translations$resume$fr resume = _Translations$resume$fr._(_root);
	@override late final _Translations$library$fr library = _Translations$library$fr._(_root);
	@override late final _Translations$liveTv$fr liveTv = _Translations$liveTv$fr._(_root);
	@override late final _Translations$ai$fr ai = _Translations$ai$fr._(_root);
	@override late final _Translations$search$fr search = _Translations$search$fr._(_root);
	@override late final _Translations$settings$fr settings = _Translations$settings$fr._(_root);
	@override late final _Translations$onboarding$fr onboarding = _Translations$onboarding$fr._(_root);
	@override late final _Translations$addSource$fr addSource = _Translations$addSource$fr._(_root);
	@override late final _Translations$plex$fr plex = _Translations$plex$fr._(_root);
	@override late final _Translations$local$fr local = _Translations$local$fr._(_root);
	@override late final _Translations$smb$fr smb = _Translations$smb$fr._(_root);
	@override late final _Translations$xtream$fr xtream = _Translations$xtream$fr._(_root);
	@override late final _Translations$transfer$fr transfer = _Translations$transfer$fr._(_root);
	@override late final _Translations$mediaBrowser$fr mediaBrowser = _Translations$mediaBrowser$fr._(_root);
	@override late final _Translations$trackers$fr trackers = _Translations$trackers$fr._(_root);
	@override late final _Translations$seerr$fr seerr = _Translations$seerr$fr._(_root);
	@override late final _Translations$film$fr film = _Translations$film$fr._(_root);
	@override late final _Translations$errors$fr errors = _Translations$errors$fr._(_root);
}

// Path: common
class _Translations$common$fr extends Translations$common$en {
	_Translations$common$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get back => 'Retour';
	@override String get tryAgain => 'Réessayer';
	@override String get cancel => 'Annuler';
	@override String get noDrm => 'Pas de DRM. Les catalogues commerciaux protégés comme Netflix ou Disney+ ne peuvent pas être lus.';
}

// Path: player
class _Translations$player$fr extends Translations$player$en {
	_Translations$player$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get shareGone => 'Ce partage n\'est plus configuré.';
	@override String get shareFileGone => 'Ce fichier n\'est plus sur le partage.';
	@override String get deviceFileGone => 'Ce fichier n\'est plus sur cet appareil.';
	@override String get lineGone => 'Cette ligne n\'est plus configurée.';
	@override String get untitledVideo => 'Vidéo';
	@override String get untitledEpisode => 'Épisode';
	@override String get untitledFilm => 'Film';
	@override String get untitledLive => 'En direct';
	@override String get channelFroze => 'Cette chaîne s\'est arrêtée et n\'est pas revenue.';
	@override String get channelNotResponding => 'Cette chaîne ne répond pas. Les listes d\'un panel sont souvent en avance sur la réalité, alors essayez-en une autre, ou la même à nouveau.';
	@override String get didNotStart => 'La lecture n\'a pas démarré. Le serveur est peut-être occupé, ou le fichier doit être transcodé, ce qui n\'est pas encore pris en charge.';
	@override String get released => 'Arrêté pendant que l\'appli était en arrière-plan, pour libérer la connexion pour d\'autres appareils.';
	@override String get rejoin => 'Reprendre';
	@override String get live => 'EN DIRECT';
	@override String skipBack({required Object seconds}) => 'Reculer de ${seconds} secondes';
	@override String skipForward({required Object seconds}) => 'Avancer de ${seconds} secondes';
	@override String get pause => 'Pause';
	@override String get play => 'Lecture';
	@override String get tracks => 'Audio et sous-titres';
	@override String get audio => 'Audio';
	@override String get subtitles => 'Sous-titres';
	@override String get off => 'Désactivés';
	@override String trackNumber({required Object n}) => 'Piste ${n}';
	@override late final _Translations$player$upNext$fr upNext = _Translations$player$upNext$fr._(_root);
}

// Path: subtitleSize
class _Translations$subtitleSize$fr extends Translations$subtitleSize$en {
	_Translations$subtitleSize$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get small => 'Petite';
	@override String get medium => 'Moyenne';
	@override String get large => 'Grande';
}

// Path: units
class _Translations$units$fr extends Translations$units$en {
	_Translations$units$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String minutes({required Object m}) => '${m} min';
	@override String hours({required Object h}) => '${h} h';
	@override String hoursMinutes({required Object h, required Object m}) => '${h} h ${m} min';
	@override String minutesLeft({required Object m}) => '${m} min restantes';
	@override String seconds({required Object s}) => '${s} s';
}

// Path: downloads
class _Translations$downloads$fr extends Translations$downloads$en {
	_Translations$downloads$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get empty => 'Rien n\'est encore téléchargé. Appuyez longuement sur un film ou un épisode de votre bibliothèque Plex et choisissez Télécharger, puis regardez-le ici sans réseau.';
	@override String get title => 'Téléchargements';
	@override String summary({required num n, required Object size}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${n} élément · ${size} sur cet appareil',
		other: '${n} éléments · ${size} sur cet appareil',
	);
	@override String pendingWatches({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '1 visionnage d\'ici attend d\'être envoyé à Plex.',
		other: '${n} visionnages d\'ici attendent d\'être envoyés à Plex.',
	);
	@override String get foregroundOnly => 'Les téléchargements continuent tant que l\'appli est ouverte. La fermer les met en pause, et rien de ce qui est déjà enregistré n\'est perdu.';
	@override String downloadingBytes({required Object received}) => 'Téléchargement, ${received}';
	@override String downloadingPercent({required Object percent, required Object received, required Object total}) => 'Téléchargement ${percent} % · ${received} sur ${total}';
	@override String get queued => 'En attente de son tour';
	@override String get paused => 'En pause';
	@override String pausedAt({required Object percent}) => 'En pause à ${percent} % · sélectionnez pour reprendre';
	@override String failed({required Object error}) => '${error} Sélectionnez pour réessayer.';
	@override String get failedUnknown => 'Il ne s\'est pas terminé.';
	@override String get deleteTitle => 'Supprimer ce téléchargement ?';
	@override String get cancelTitle => 'Annuler ce téléchargement ?';
	@override String removeBody({required Object title}) => '« ${title} » sera supprimé de cet appareil. Il reste sur votre serveur Plex.';
	@override String removeBodyFreeing({required Object title, required Object size}) => '« ${title} » sera supprimé de cet appareil, ce qui libère ${size}. Il reste sur votre serveur Plex.';
	@override String get keepIt => 'Le garder';
	@override String get delete => 'Supprimer';
	@override late final _Translations$downloads$errors$fr errors = _Translations$downloads$errors$fr._(_root);
	@override late final _Translations$downloads$rule$fr rule = _Translations$downloads$rule$fr._(_root);
}

// Path: watchActions
class _Translations$watchActions$fr extends Translations$watchActions$en {
	_Translations$watchActions$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get everyEpisode => ' (tous les épisodes)';
	@override String markWatched({required Object scope}) => 'Marquer comme vu${scope}';
	@override String markUnwatched({required Object scope}) => 'Marquer comme non vu${scope}';
	@override String get download => 'Télécharger sur cet appareil';
	@override String get deleteDownload => 'Supprimer le téléchargement';
	@override String get cancelDownload => 'Annuler le téléchargement';
	@override String get removeFavourite => 'Retirer des favoris';
	@override String get addFavourite => 'Ajouter aux favoris';
	@override String get removeResume => 'Retirer de Reprendre la lecture';
	@override String get downloading => 'Téléchargement en cours. Voir l\'onglet Téléchargements.';
	@override String get markedOffline => 'Marqué comme vu ici. Plex en sera informé dès qu\'il sera joignable.';
	@override String get plexRefused => 'Plex ne l\'a pas accepté. Le serveur est peut-être hors ligne.';
	@override String get details => 'Détails';
}

// Path: show
class _Translations$show$fr extends Translations$show$en {
	_Translations$show$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get noEpisodes => 'Cette série n\'a aucun épisode sur le serveur.';
}

// Path: shell
class _Translations$shell$fr extends Translations$shell$en {
	_Translations$shell$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get library => 'Bibliothèque';
	@override String get search => 'Recherche';
	@override String get downloads => 'Téléchargements';
	@override String get settings => 'Réglages';
	@override String get exitTitle => 'Quitter Subnext Player ?';
	@override String get exit => 'Quitter';
	@override String get stay => 'Rester';
}

// Path: resume
class _Translations$resume$fr extends Translations$resume$en {
	_Translations$resume$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get upNext => 'À suivre';
	@override String get title => 'Reprendre la lecture';
	@override String get remove => 'Retirer de Reprendre la lecture';
}

// Path: library
class _Translations$library$fr extends Translations$library$en {
	_Translations$library$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$library$placement$fr placement = _Translations$library$placement$fr._(_root);
	@override late final _Translations$library$tab$fr tab = _Translations$library$tab$fr._(_root);
	@override String serverTimeout({required Object server, required Object seconds}) => '${server} n\'a pas répondu en ${seconds} secondes. Il est peut-être en veille ou hors du réseau.';
	@override String get allWatched => 'Vous avez tout vu dans Films.';
	@override String get showAll => 'Tout afficher';
	@override String get noSources => 'Aucune source connectée pour l\'instant.';
	@override String nothingIn({required Object tab}) => 'Rien dans ${tab} pour l\'instant.';
	@override String get addSource => 'Ajouter une source';
	@override String sortFiltered({required Object sort}) => '${sort} · Non vus';
	@override String get sortBy => 'Trier par';
	@override String get unwatchedOnly => 'Non vus seulement';
	@override late final _Translations$library$shelf$fr shelf = _Translations$library$shelf$fr._(_root);
	@override late final _Translations$library$sort$fr sort = _Translations$library$sort$fr._(_root);
	@override late final _Translations$library$tile$fr tile = _Translations$library$tile$fr._(_root);
}

// Path: liveTv
class _Translations$liveTv$fr extends Translations$liveTv$en {
	_Translations$liveTv$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$liveTv$group$fr group = _Translations$liveTv$group$fr._(_root);
	@override String get noPanel => 'Aucune playlist ni aucun panel configuré.';
	@override String get addOne => 'En ajouter un';
	@override String get noCategories => 'Aucune catégorie choisie pour l\'instant.\nLes panels comptent des dizaines de milliers de chaînes, alors Subnext Player ne récupère que celles que vous choisissez.';
	@override String get chooseCategories => 'Choisir des catégories';
	@override String get noChannels => 'Ces catégories n\'ont renvoyé aucune chaîne.';
	@override String noMatch({required Object query}) => 'Aucune chaîne ne correspond à « ${query} ».';
	@override String searchHint({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: 'Rechercher parmi ${n} chaîne',
		other: 'Rechercher parmi ${n} chaînes',
	);
	@override String get all => 'Toutes';
}

// Path: ai
class _Translations$ai$fr extends Translations$ai$en {
	_Translations$ai$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$ai$picks$fr picks = _Translations$ai$picks$fr._(_root);
	@override late final _Translations$ai$search$fr search = _Translations$ai$search$fr._(_root);
	@override String get presetOther => 'Autre';
	@override String get hintOpenRouter => 'Les identifiants de modèle sont listés sur openrouter.ai/models. Les gratuits se terminent par ":free".';
	@override String get hintOllama => 'Utilisez l\'adresse de votre ordinateur sur ce réseau, par exemple http://192.168.1.20:11434/v1. Rien ne quitte votre réseau.';
	@override String get hintCustom => 'Tout service qui parle le format de chat d\'OpenAI.';
	@override late final _Translations$ai$feature$fr feature = _Translations$ai$feature$fr._(_root);
	@override late final _Translations$ai$errors$fr errors = _Translations$ai$errors$fr._(_root);
	@override String consentTitle({required Object provider}) => 'Envoyer des données à ${provider} ?';
	@override String consentBody({required Object feature, required Object provider, required Object sends}) => '${feature} enverra ceci à ${provider} : ${sends}';
	@override String get consentTail => 'Cela va directement de cet appareil vers eux, jamais par nous. Vous pouvez le désactiver à nouveau dans Réglages, Fonctions d\'IA.';
	@override String get notNow => 'Pas maintenant';
	@override String get allow => 'Autoriser';
}

// Path: search
class _Translations$search$fr extends Translations$search$en {
	_Translations$search$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$search$filters$fr filters = _Translations$search$filters$fr._(_root);
	@override String get hint => 'Rechercher dans vos sources';
	@override String get prompt => 'Recherchez des films et des séries sur votre serveur.';
	@override String get keepTyping => 'Continuez à taper…';
	@override String noMatch({required Object query}) => 'Rien ne correspond à « ${query} ».';
	@override String get backToResults => 'Retour aux résultats';
	@override String get askAi => 'Demander à l\'IA';
	@override String get becauseYouWatched => 'Parce que vous avez regardé ';
}

// Path: settings
class _Translations$settings$fr extends Translations$settings$en {
	_Translations$settings$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$settings$about$fr about = _Translations$settings$about$fr._(_root);
	@override late final _Translations$settings$privacy$fr privacy = _Translations$settings$privacy$fr._(_root);
	@override late final _Translations$settings$playback$fr playback = _Translations$settings$playback$fr._(_root);
	@override late final _Translations$settings$metadata$fr metadata = _Translations$settings$metadata$fr._(_root);
	@override late final _Translations$settings$ai$fr ai = _Translations$settings$ai$fr._(_root);
	@override late final _Translations$settings$appearance$fr appearance = _Translations$settings$appearance$fr._(_root);
	@override late final _Translations$settings$section$fr section = _Translations$settings$section$fr._(_root);
	@override late final _Translations$settings$advanced$fr advanced = _Translations$settings$advanced$fr._(_root);
	@override late final _Translations$settings$sources$fr sources = _Translations$settings$sources$fr._(_root);
}

// Path: onboarding
class _Translations$onboarding$fr extends Translations$onboarding$en {
	_Translations$onboarding$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get tagline => 'Lisez depuis les sources que vous connectez.';
	@override String get blurb => 'Subnext Player lit depuis des sources que vous connectez vous-même : un serveur Plex, un NAS domestique ou des fichiers locaux, ou en option un fournisseur ou une playlist IPTV. Nous n\'hébergeons aucun contenu.';
	@override String get localDesktop => 'Des fichiers sur ce PC, ou un dossier sur un NAS domestique ou un partage SMB.';
	@override String get localTv => 'Un dossier sur un NAS domestique ou un partage SMB.';
	@override String get local => 'Des vidéos sur cet appareil, ou un dossier sur un NAS domestique ou un partage SMB.';
	@override String get plexTv => 'Connectez-vous avec votre propre compte sur cette TV.';
	@override String get plex => 'Votre bibliothèque personnelle, avec votre propre compte.';
	@override String get advancedTv => 'Désactivé par défaut. À activer dans Réglages.';
	@override String get advanced => 'Désactivé par défaut. À activer dans Réglages pour utiliser un fournisseur ou une playlist IPTV.';
	@override String get localTitle => 'Local et réseau';
	@override String get advancedTitle => 'Sources avancées';
	@override String get addFirst => 'Ajouter votre première source';
	@override String get notNow => 'Pas maintenant';
	@override String get connect => 'Connecter une source';
	@override String get addSource => 'Ajouter une source';
	@override String get okKey => 'OK';
	@override String get toSelect => 'pour sélectionner';
}

// Path: addSource
class _Translations$addSource$fr extends Translations$addSource$en {
	_Translations$addSource$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get privacy => 'Les identifiants restent sur cet appareil. Rien ne nous est envoyé : il n\'y a ni compte ni serveur entre les deux.';
	@override late final _Translations$addSource$kind$fr kind = _Translations$addSource$kind$fr._(_root);
	@override String get copyFromDevice => 'Copier depuis un autre appareil';
	@override String get copyFromDeviceSub => 'Déjà configuré sur votre téléphone ? Envoyez-le ici au lieu de tout retaper.';
	@override String get title => 'Ajouter une source';
	@override String get advanced => 'Sources avancées';
	@override String get or => 'Ou';
	@override String get advancedHintLead => 'Vous cherchez un fournisseur ou une playlist IPTV ? Activez ';
	@override String get advancedHintTail => ' dans Réglages.';
	@override String get sourceType => 'Type de source';
	@override String get plexRail => 'Associer avec un code';
	@override String get pcFiles => 'Fichiers sur ce PC';
	@override String get pcFilesSub => 'Choisir un dossier';
	@override String get smbRail => 'NAS ou partage Windows';
	@override String get copyRail => 'Envoyez-le depuis votre téléphone';
	@override String get keystore => 'Les identifiants sont stockés dans le trousseau de l\'appareil, jamais dans la base de données de l\'appli.';
	@override String get pick => 'Choisissez un type de source pour commencer.';
}

// Path: plex
class _Translations$plex$fr extends Translations$plex$en {
	_Translations$plex$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get connected => 'Plex connecté.';
	@override String connectedTo({required Object name}) => 'Connecté à ${name}.';
	@override String get opening => 'Connecté. Ouverture de votre bibliothèque…';
	@override String get connect => 'Se connecter à Plex';
	@override String get explain => 'Subnext Player lit ce que votre propre serveur Plex contient déjà. Rien n\'est envoyé en ligne, et vos informations de compte ne parviennent à personne d\'autre que Plex.';
	@override String get contacting => 'Contact de Plex…';
	@override String get enterCode => 'Sur n\'importe quel appareil, ouvrez plex.tv/link et saisissez :';
	@override String get waiting => 'En attente d\'approbation…';
	@override String get copyCode => 'Copier le code';
	@override String get chooseServer => 'Choisir un serveur';
	@override String get allConnected => 'Tous les serveurs de ce compte sont déjà connectés.';
	@override String get yourServers => 'Vos serveurs';
	@override String get sharedWithYou => 'Partagés avec vous';
	@override String get connecting => 'Connexion… cela peut prendre quelques secondes';
	@override String get offline => 'Hors ligne';
	@override String get relayOnly => 'Plex Relay uniquement, la lecture peut être limitée';
	@override String get codeExpired => 'Ce code a expiré. Réessayez.';
	@override String get noServers => 'Ce compte n\'a aucun serveur Plex.';
	@override late final _Translations$plex$errors$fr errors = _Translations$plex$errors$fr._(_root);
}

// Path: local
class _Translations$local$fr extends Translations$local$en {
	_Translations$local$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String noAccess({required Object where}) => 'Subnext Player ne peut pas voir vos vidéos sans accès aux médias. Vous pouvez l\'accorder dans ${where}.';
	@override String get settingsIos => 'l\'app Réglages';
	@override String get settingsAndroid => 'les paramètres Android';
	@override String get intro => 'Lisez les vidéos stockées sur cet appareil.\nSubnext Player ne demande que l\'accès aux vidéos, jamais à tous les fichiers.';
	@override String get allowAccess => 'Autoriser l\'accès aux vidéos';
	@override String get pickFolderInstead => 'Ou choisir un dossier';
	@override String get addShare => 'Ajouter un partage réseau';
	@override String get shares => 'Partages réseau';
	@override String get pickedFolders => 'Dossiers choisis';
	@override String get onDevice => 'Sur cet appareil';
	@override String get noVideos => 'Aucune vidéo trouvée sur cet appareil.';
	@override String get addFolderShort => 'Ajouter un dossier';
	@override String get addShareShort => 'Ajouter un partage';
	@override String get scanDevice => 'Analyser cet appareil';
	@override String get forgetFolder => 'Oublier ce dossier';
	@override String get folder => 'Dossier';
	@override String safUnreadable({required Object error}) => 'Ce dossier n\'est plus lisible. Android a peut-être retiré l\'autorisation, alors retirez-le et choisissez-le à nouveau.\n\n${error}';
	@override String get safEmpty => 'Aucune vidéo ni sous-dossier ici.';
}

// Path: smb
class _Translations$smb$fr extends Translations$smb$en {
	_Translations$smb$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String connectFailed({required Object error}) => 'Connexion impossible : ${error}';
	@override String get title => 'Ajouter un partage réseau';
	@override String get explain => 'Un NAS ou un dossier partagé sur un autre ordinateur de votre réseau.';
	@override String get host => 'Adresse du serveur';
	@override String get hostHint => 'p. ex. nas';
	@override String get username => 'Nom d\'utilisateur';
	@override String get password => 'Mot de passe';
	@override String get domain => 'Domaine (facultatif)';
	@override String get name => 'Nom (facultatif)';
	@override String get connectAndAdd => 'Se connecter et ajouter';
	@override String get gone => 'Ce partage n\'est plus configuré.';
	@override String unreachable({required Object error}) => 'Impossible de joindre ce partage. Le serveur est peut-être en veille ou hors du réseau.\n\n${error}';
	@override String get empty => 'Aucune vidéo ni dossier ici.';
}

// Path: xtream
class _Translations$xtream$fr extends Translations$xtream$en {
	_Translations$xtream$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get lineGone => 'Cette ligne n\'est plus configurée.';
	@override late final _Translations$xtream$catalogue$fr catalogue = _Translations$xtream$catalogue$fr._(_root);
	@override late final _Translations$xtream$errors$fr errors = _Translations$xtream$errors$fr._(_root);
	@override String get everythingElse => 'Tout le reste';
	@override late final _Translations$xtream$series$fr series = _Translations$xtream$series$fr._(_root);
	@override String get remove => 'Retirer';
	@override String get add => 'Ajouter une playlist ou un panel';
	@override late final _Translations$xtream$addLine$fr addLine = _Translations$xtream$addLine$fr._(_root);
	@override late final _Translations$xtream$picker$fr picker = _Translations$xtream$picker$fr._(_root);
	@override late final _Translations$xtream$channels$fr channels = _Translations$xtream$channels$fr._(_root);
	@override late final _Translations$xtream$hidden$fr hidden = _Translations$xtream$hidden$fr._(_root);
}

// Path: transfer
class _Translations$transfer$fr extends Translations$transfer$en {
	_Translations$transfer$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get noNetwork => 'Cet appareil n\'est pas sur un réseau Wi-Fi ou Ethernet. Connectez-le au même réseau que l\'autre appareil et réessayez.';
	@override String cannotListen({required Object error}) => 'Impossible de commencer l\'écoute : ${error}';
	@override String get expired => 'Ce code a expiré. Recommencez pour en obtenir un nouveau.';
	@override String wentWrong({required Object error}) => 'Un problème est survenu : ${error}';
	@override String get wentWrongPlain => 'Un problème est survenu.';
	@override String get gettingReady => 'Préparation…';
	@override String get waitingOther => 'En attente de l\'autre appareil…';
	@override String get copyCode => 'Copier le code';
	@override String get scanInstead => 'Scanner son code';
	@override String get typeInstead => 'Saisir son code';
	@override String get done => 'Terminé';
	@override String get close => 'Fermer';
	@override late final _Translations$transfer$receive$fr receive = _Translations$transfer$receive$fr._(_root);
	@override late final _Translations$transfer$pairing$fr pairing = _Translations$transfer$pairing$fr._(_root);
	@override late final _Translations$transfer$pane$fr pane = _Translations$transfer$pane$fr._(_root);
	@override late final _Translations$transfer$notes$fr notes = _Translations$transfer$notes$fr._(_root);
	@override late final _Translations$transfer$send$fr send = _Translations$transfer$send$fr._(_root);
	@override late final _Translations$transfer$item$fr item = _Translations$transfer$item$fr._(_root);
	@override late final _Translations$transfer$client$fr client = _Translations$transfer$client$fr._(_root);
}

// Path: mediaBrowser
class _Translations$mediaBrowser$fr extends Translations$mediaBrowser$en {
	_Translations$mediaBrowser$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$mediaBrowser$errors$fr errors = _Translations$mediaBrowser$errors$fr._(_root);
	@override String get title => 'Se connecter à Jellyfin ou Emby';
	@override String get explain => 'Subnext Player lit ce que votre propre serveur contient déjà. Votre connexion reste sur cet appareil et ne parvient qu\'à votre serveur.';
	@override String get address => 'Adresse du serveur';
	@override String get addressHint => 'p. ex. 192.168.1.20:8096';
	@override String get find => 'Trouver le serveur';
	@override String get finding => 'Recherche du serveur…';
	@override String found({required Object name, required Object kind, required Object version}) => '${name} · ${kind} ${version}';
	@override String get username => 'Nom d\'utilisateur';
	@override String get password => 'Mot de passe';
	@override String get signIn => 'Se connecter';
	@override String get signingIn => 'Connexion…';
	@override String get useQuickConnect => 'Utiliser Quick Connect';
	@override String get usePassword => 'Utiliser le nom d\'utilisateur et le mot de passe';
	@override String get quickConnectExplain => 'Sur un téléphone ou un ordinateur déjà connecté à Jellyfin, ouvrez votre profil, Quick Connect, et saisissez :';
	@override String get waiting => 'En attente d\'approbation…';
	@override String get otherAddress => 'Utiliser une autre adresse';
	@override String connected({required Object name}) => 'Connecté à ${name}.';
}

// Path: trackers
class _Translations$trackers$fr extends Translations$trackers$en {
	_Translations$trackers$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$trackers$errors$fr errors = _Translations$trackers$errors$fr._(_root);
	@override String get malCaught => 'Connecté. Vous pouvez fermer cette fenêtre et revenir à Subnext Player.';
	@override String get intro => 'Envoyez ce que vous finissez de regarder sur vos propres serveurs à un service d\'historique. Rien ne vient de l\'IPTV, et rien ne nous parvient.';
	@override String get animeNote => 'AniList et MyAnimeList ne reçoivent que les titres que votre serveur marque comme anime, retrouvés par leur nom.';
	@override String signedInAs({required Object name}) => 'Connecté en tant que ${name}';
	@override String get signedIn => 'Connecté';
	@override String get notConnected => 'Non connecté';
	@override String get signIn => 'Se connecter';
	@override String get signOut => 'Se déconnecter';
	@override String pending({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '1 visionnage attend d\'être envoyé.',
		other: '${n} visionnages attendent d\'être envoyés.',
	);
	@override String consentTitle({required Object service}) => 'Envoyer vos visionnages à ${service} ?';
	@override String consentBody({required Object service}) => 'Quand vous finissez un film ou un épisode de votre propre serveur Plex, Jellyfin ou Emby, Subnext Player envoie à ${service} son titre, son année, son identifiant IMDb, TMDB ou TVDB, et le moment où vous l\'avez regardé. Cela va directement de cet appareil à ${service}, jamais par nous. Rien ne vient de l\'IPTV. Vous pouvez vous déconnecter à tout moment dans Réglages, Suivi des visionnages.';
	@override String consentAnime({required Object service}) => 'Pour ${service}, seuls les titres que votre serveur marque comme anime sont envoyés, et ils sont retrouvés en cherchant leur nom sur ${service}.';
	@override String get agree => 'Continuer';
	@override String get notNow => 'Pas maintenant';
	@override String signInTitle({required Object service}) => 'Se connecter à ${service}';
	@override String deviceCodeExplain({required Object url}) => 'Sur n\'importe quel appareil, ouvrez ${url} et saisissez :';
	@override String get waiting => 'En attente d\'approbation…';
	@override String browserExplain({required Object service}) => 'Ouvrez cette adresse dans un navigateur, connectez-vous à ${service} et autorisez Subnext Player. Collez ensuite ci-dessous ce que ${service} vous donne.';
	@override String get anilistPaste => 'AniList affiche un long jeton après l\'autorisation. Copiez-le en entier.';
	@override String get malPaste => 'Sur cet appareil, l\'appli termine seule. Si le navigateur était ailleurs, il finit sur une page qui ne se charge pas : copiez l\'adresse complète de cette page.';
	@override String get tvHint => 'Sur une TV, connectez-vous sur votre téléphone et utilisez Transférer vers un autre appareil pour le ramener ici.';
	@override String get pasteLabel => 'Collez ici';
	@override String get finish => 'Terminer la connexion';
	@override String get copyAddress => 'Copier l\'adresse';
	@override String connected({required Object service}) => 'Connecté à ${service}.';
}

// Path: seerr
class _Translations$seerr$fr extends Translations$seerr$en {
	_Translations$seerr$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$seerr$errors$fr errors = _Translations$seerr$errors$fr._(_root);
	@override String get intro => 'Connectez votre propre serveur Overseerr, Jellyseerr ou Seerr pour demander des films et séries que votre bibliothèque n\'a pas encore. Les demandes vont à votre serveur et nulle part ailleurs ; son administrateur décide de la suite.';
	@override String get address => 'Adresse du serveur';
	@override String get addressHint => 'p. ex. 192.168.1.20:5055';
	@override String get find => 'Trouver le serveur';
	@override String get withPlex => 'Se connecter avec mon compte Plex';
	@override String get withPassword => 'Se connecter avec nom d\'utilisateur et mot de passe';
	@override String get withKey => 'Utiliser une clé d\'API';
	@override String get username => 'Nom d\'utilisateur ou e-mail';
	@override String get password => 'Mot de passe';
	@override String get apiKey => 'Clé d\'API';
	@override String get keyNote => 'Une clé d\'API agit comme l\'administrateur du serveur, donc les demandes faites avec elle ne sont pas à votre nom. Préférez vous connecter.';
	@override String get connect => 'Se connecter';
	@override String get connecting => 'Connexion…';
	@override String connected({required Object title, required Object name}) => 'Connecté à ${title} en tant que ${name}';
	@override String get disconnect => 'Déconnecter';
	@override String get myRequests => 'Vos demandes récentes';
	@override String get none => 'Aucune demande pour le moment.';
	@override String get statusPending => 'En attente d\'approbation';
	@override String get statusApproved => 'Approuvée';
	@override String get statusDeclined => 'Refusée';
	@override String get statusAvailable => 'Disponible';
	@override String rowTitle({required Object title}) => 'Demander à ${title}';
	@override String get requested => 'Demandé';
	@override String get partial => 'En partie disponible';
	@override String askTitle({required Object title}) => 'Demander ${title} ?';
	@override String askMovie({required Object server}) => 'Cela demande à ${server} d\'ajouter le film. Son administrateur décide s\'il le fait.';
	@override String askShow({required Object server}) => 'Cela demande à ${server} d\'ajouter toutes les saisons. Son administrateur décide s\'il le fait.';
	@override String get request => 'Demander';
	@override String sent({required Object title}) => '${title} demandé.';
}

// Path: film
class _Translations$film$fr extends Translations$film$en {
	_Translations$film$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get play => 'Lire';
	@override String resume({required Object time}) => 'Reprendre à ${time}';
	@override String get fromStart => 'Lire depuis le début';
	@override String get gone => 'Ce film n\'est plus sur le serveur, ou le serveur est injoignable.';
}

// Path: errors
class _Translations$errors$fr extends Translations$errors$en {
	_Translations$errors$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get addressHidden => '(adresse masquée)';
}

// Path: player.upNext
class _Translations$player$upNext$fr extends Translations$player$upNext$en {
	_Translations$player$upNext$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'À suivre';
	@override String playingIn({required Object seconds}) => 'Lecture dans ${seconds} s';
	@override String get playNow => 'Lire maintenant';
}

// Path: downloads.errors
class _Translations$downloads$errors$fr extends Translations$downloads$errors$en {
	_Translations$downloads$errors$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get serverNotConnected => 'Ce serveur n\'est pas connecté. Reconnectez-le dans Réglages, puis reprenez.';
	@override String get sizeMismatch => 'Le fichier ne correspond pas à la taille indiquée par le serveur. Réessayez.';
	@override String get cannotWrite => 'Impossible d\'écrire le fichier. L\'appareil manque peut-être d\'espace.';
	@override String get changedOnServer => 'Le fichier a changé sur le serveur. Relancez le téléchargement.';
	@override String get refused => 'Le serveur n\'autorise pas cet appareil à télécharger cela.';
	@override String status({required Object code}) => 'Le serveur a répondu ${code}.';
	@override String get dropped => 'La connexion a été coupée en cours de route. Reprenez pour continuer.';
	@override String get unreachable => 'Impossible de joindre le serveur. Vérifiez la connexion et reprenez.';
	@override String get timeout => 'Le serveur a mis trop de temps à répondre.';
}

// Path: downloads.rule
class _Translations$downloads$rule$fr extends Translations$downloads$rule$en {
	_Translations$downloads$rule$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get off => 'Garder des épisodes téléchargés';
	@override String keeping({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: 'L\'épisode suivant reste téléchargé',
		other: 'Les ${n} épisodes suivants restent téléchargés',
	);
	@override String get explain => 'Télécharge les prochains épisodes non vus et les remplace au fil de votre visionnage, tant que l\'appli est ouverte. Ceux qu\'il a téléchargés et que vous avez vus sont supprimés.';
	@override String get choiceOff => 'Désactivé';
	@override String choice({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: 'Épisode suivant',
		other: '${n} épisodes suivants',
	);
}

// Path: library.placement
class _Translations$library$placement$fr extends Translations$library$placement$en {
	_Translations$library$placement$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get movies => 'Films';
	@override String get series => 'Séries';
	@override String get hidden => 'Masqué';
}

// Path: library.tab
class _Translations$library$tab$fr extends Translations$library$tab$en {
	_Translations$library$tab$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get movies => 'Films';
	@override String get series => 'Séries';
	@override String get localNetwork => 'Local et réseau';
	@override String get liveTv => 'TV en direct';
	@override String get emptyMovies => 'Aucun film sur ce serveur.';
	@override String get emptySeries => 'Aucune série sur ce serveur.';
	@override String get emptyLocalNetwork => 'Aucun dossier ni partage réseau pour l\'instant.\nLe stockage de l\'appareil et les partages SMB ne sont pas connectables dans cette version.';
	@override String get emptyLiveTv => 'Aucune playlist ni aucun panel configuré.\nAjoutez-en un depuis Réglages une fois les Sources avancées activées.';
	@override String countMovies({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${n} film',
		other: '${n} films',
	);
	@override String countSeries({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${n} série',
		other: '${n} séries',
	);
	@override String countItems({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${n} élément',
		other: '${n} éléments',
	);
	@override String countChannels({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${n} chaîne',
		other: '${n} chaînes',
	);
}

// Path: library.shelf
class _Translations$library$shelf$fr extends Translations$library$shelf$en {
	_Translations$library$shelf$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get seeAll => 'Tout voir';
	@override String titles({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${n} titre',
		other: '${n} titres',
	);
	@override String get gone => 'Il n\'y a plus rien ici.';
}

// Path: library.sort
class _Translations$library$sort$fr extends Translations$library$sort$en {
	_Translations$library$sort$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titre';
	@override String get recentlyAdded => 'Ajout récent';
	@override String get year => 'Année';
	@override String get releaseDate => 'Date de sortie';
}

// Path: library.tile
class _Translations$library$tile$fr extends Translations$library$tile$en {
	_Translations$library$tile$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get series => 'Série';
	@override String get movie => 'Film';
	@override String get watched => 'Vu';
	@override String percentWatched({required Object percent}) => 'Vu à ${percent} %';
	@override String unwatchedEpisodes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${n} épisode non vu',
		other: '${n} épisodes non vus',
	);
}

// Path: liveTv.group
class _Translations$liveTv$group$fr extends Translations$liveTv$group$en {
	_Translations$liveTv$group$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get favourites => 'Favoris';
	@override String numbered({required Object n}) => 'Catégorie ${n}';
	@override String get other => 'Autres';
}

// Path: ai.picks
class _Translations$ai$picks$fr extends Translations$ai$picks$en {
	_Translations$ai$picks$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get yourProvider => 'votre fournisseur';
	@override String get ask => 'Que regarder ?';
	@override String askExplain({required Object provider}) => 'Demandez à ${provider} de choisir dans votre propre bibliothèque.';
	@override String get pickedBy => 'Choisi pour vous par ';
	@override String get updating => 'Mise à jour';
	@override String get again => 'Encore';
	@override String get preparing => 'Préparation de vos suggestions...';
}

// Path: ai.search
class _Translations$ai$search$fr extends Translations$ai$search$en {
	_Translations$ai$search$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String asking({required Object provider}) => 'Interrogation de ${provider}...';
	@override String searching({required Object searched, required Object covered}) => 'Recherche dans votre bibliothèque... ${searched} sur ${covered} titres';
	@override String get emptyLibrary => 'Il n\'y a encore rien à rechercher dans votre bibliothèque.';
	@override String notFound({required Object total}) => 'Le modèle n\'a rien trouvé qui corresponde parmi ${total} titres. Essayez de le décrire autrement.';
	@override String notFoundFirst({required Object covered, required Object total}) => 'Le modèle n\'a rien trouvé qui corresponde parmi les ${covered} premiers des ${total} titres. Essayez de le décrire autrement.';
	@override String stillSearching({required Object searched, required Object covered}) => 'Recherche en cours : ${searched} sur ${covered} titres';
	@override String searchedFirst({required Object covered, required Object total}) => 'Recherche dans les ${covered} premiers des ${total} titres';
	@override String pickedFor({required Object provider, required Object query}) => 'Choisi par ${provider} pour « ${query} »';
	@override String get searchAgain => 'Relancer la recherche';
	@override String partsFailed({required Object failed, required Object parts}) => '${failed} parties sur ${parts} n\'ont pas pu être recherchées, une partie de votre bibliothèque n\'a donc pas été examinée. Le fournisseur limite peut-être les requêtes';
}

// Path: ai.feature
class _Translations$ai$feature$fr extends Translations$ai$feature$en {
	_Translations$ai$feature$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get naturalSearch => 'Recherche en langage naturel';
	@override String get naturalSearchSends => 'Le texte de votre recherche, et les titres et années de votre bibliothèque.';
	@override String get naturalSearchTiming => 'Une grande bibliothèque est envoyée en plusieurs requêtes de quelques centaines de titres chacune, une recherche en fait donc plusieurs.';
	@override String get recommendations => 'Recommandations';
	@override String get recommendationsSends => 'Les films que vous avez vus récemment, et les titres et années de ce que vous n\'avez pas encore vu dans votre bibliothèque.';
	@override String get recommendationsTiming => 'Les suggestions sont préparées en arrière-plan peu après l\'ouverture de l\'appli, mais seulement si ce que vous avez vu a changé ou si elles datent de plus d\'un jour, il n\'y a donc pas de requête à chaque lancement.';
}

// Path: ai.errors
class _Translations$ai$errors$fr extends Translations$ai$errors$en {
	_Translations$ai$errors$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get ranOutThinking => 'Le modèle a manqué de place pour répondre pendant sa réflexion et n\'a jamais donné de réponse. Un modèle qui ne « réfléchit » pas d\'abord fonctionnera mieux.';
	@override String get empty => 'Le modèle a renvoyé une réponse vide.';
	@override String rejectedKey({required Object suffix}) => 'Le fournisseur a refusé cette clé${suffix}.';
	@override String noCredit({required Object suffix}) => 'Le fournisseur indique que ce compte n\'a plus de crédit${suffix}.';
	@override String unknownModel({required Object suffix}) => 'Le fournisseur ne connaît pas ce modèle ou cette adresse${suffix}.';
	@override String rateLimited({required Object suffix}) => 'Le fournisseur limite cette clé. Réessayez dans un instant${suffix}.';
	@override String serverError({required Object status, required Object suffix}) => 'Le fournisseur a rencontré un problème (HTTP ${status})${suffix}.';
	@override String get timeout => 'Le fournisseur a mis trop de temps à répondre.';
	@override String get unreachable => 'Impossible de joindre le fournisseur. Vérifiez l\'adresse.';
	@override String failed({required Object suffix}) => 'La requête a échoué${suffix}.';
	@override String failedStatus({required Object status, required Object suffix}) => 'La requête a échoué (HTTP ${status})${suffix}.';
	@override String get fillIn => 'Renseignez l\'adresse et le modèle.';
	@override String get needsKey => 'Ce fournisseur a besoin d\'une clé d\'API.';
	@override String get notSetUp => 'Aucun fournisseur d\'IA n\'est configuré.';
	@override String get searchOff => 'La recherche en langage naturel est désactivée pour ce fournisseur.';
	@override String get searchFailed => 'La recherche a échoué.';
	@override String get noSignal => 'Regardez d\'abord un film, pour qu\'il y ait de quoi baser les suggestions.';
	@override String get noPicks => 'Le modèle n\'a rien choisi cette fois-ci.';
}

// Path: search.filters
class _Translations$search$filters$fr extends Translations$search$filters$en {
	_Translations$search$filters$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String decadeOldest({required Object decade}) => 'Années ${decade} et avant';
	@override String decade({required Object decade}) => 'Années ${decade}';
	@override String get type => 'Type';
	@override String get movies => 'Films';
	@override String get series => 'Séries';
	@override String get source => 'Source';
	@override String get unknownSource => 'Source inconnue';
	@override String get year => 'Année';
	@override String get language => 'Langue';
	@override String get languageNote => 'Déduite des noms de catégories IPTV. Les titres Plex n\'ont pas de langue ici.';
	@override String get genre => 'Genre';
	@override String get rating => 'Note';
	@override String get ratingNote => 'Note des utilisateurs de TMDB sur 10. Les titres sans note sur TMDB sont exclus.';
	@override String get originalLanguage => 'Langue originale';
	@override String get originalLanguageNote => 'La langue dans laquelle le titre a été tourné, d\'après TMDB. Une copie doublée garde ici sa langue originale.';
	@override String get clear => 'Effacer';
	@override String get noMatches => 'Rien ne correspond à ces filtres.';
	@override String get clearAll => 'Effacer les filtres';
	@override String chip({required Object label, required Object value}) => '${label} : ${value}';
	@override String get any => 'Toutes';
}

// Path: settings.about
class _Translations$settings$about$fr extends Translations$settings$about$en {
	_Translations$settings$about$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get versionLoading => 'Version …';
	@override String version({required Object version, required Object build}) => 'Version ${version} (${build})';
	@override String get privacyPolicy => 'Politique de confidentialité';
	@override String get privacySummary => 'Pas de compte, pas de serveur à nous et pas de statistiques. La politique complète se trouve à :';
	@override String get licences => 'Licences open source';
}

// Path: settings.privacy
class _Translations$settings$privacy$fr extends Translations$settings$privacy$en {
	_Translations$settings$privacy$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get summary => 'Subnext Player n\'a ni serveur à nous ni statistiques. Ce qu\'il conserve reste sur cet appareil, et les seuls endroits où des données sont envoyées sont les sources, TMDB et le fournisseur d\'IA que vous connectez vous-même.';
	@override String get cachedData => 'Données en cache';
	@override String get cachedExplain => 'Les listes de votre bibliothèque, les recherches TMDB et les suggestions de l\'IA sont conservées pour que l\'appli s\'ouvre vite. Les anciennes s\'effacent d\'elles-mêmes, après 30 jours pour une bibliothèque et 90 pour une recherche, et les données d\'une source disparaissent quand vous la retirez. Effacer maintenant ne touche ni à vos sources, ni à vos clés, ni à vos réglages, ni à votre historique, et tout est récupéré à nouveau au besoin.';
	@override String get clearing => 'Effacement...';
	@override String get clear => 'Effacer les données en cache';
	@override String get cleared => 'Effacé. Votre bibliothèque se recharge.';
}

// Path: settings.playback
class _Translations$settings$playback$fr extends Translations$settings$playback$en {
	_Translations$settings$playback$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get skip => 'Reculer et avancer';
	@override String get skipExplain => 'Les boutons de saut, les touches d\'avance et de retour rapides d\'une télécommande, et le premier pas sur la barre de progression.';
	@override String get audioLanguage => 'Langue audio préférée';
	@override String get audioLanguageExplain => 'Utilisée quand un fichier a plusieurs pistes audio. Sinon, c\'est la piste par défaut du fichier qui est lue.';
	@override String get fileDefault => 'Par défaut du fichier';
	@override String get showSubtitles => 'Afficher les sous-titres';
	@override String get showSubtitlesExplain => 'Les activer quand un fichier en contient. Vous pouvez toujours changer dans le lecteur.';
	@override String get subtitleLanguage => 'Langue de sous-titres préférée';
	@override String get subtitleLanguageExplain => 'Si un fichier n\'a pas de sous-titres dans cette langue, aucun n\'est affiché.';
	@override String get any => 'Toutes';
	@override String get size => 'Taille';
	@override String get sizeExplain => 'Pour les sous-titres texte, comme SRT et ASS.';
}

// Path: settings.metadata
class _Translations$settings$metadata$fr extends Translations$settings$metadata$en {
	_Translations$settings$metadata$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get consent => 'Cela recherche sur TMDB la date de sortie de chaque film et série de votre bibliothèque, en arrière-plan, quelques-uns à la fois. Pour cela, le titre (et l\'année, s\'il y en a une) de chacun est envoyé depuis cet appareil à TMDB, et à personne d\'autre, pas seulement ceux que vous recherchez. Cela renseigne aussi le genre et la note pour les filtres. Les résultats sont conservés sur cet appareil pendant 90 jours, et les titres déjà recherchés ne sont pas redemandés.\n\nVous pouvez le désactiver à tout moment. Retirer votre clé TMDB le désactive aussi.';
	@override String get consentTitle => 'Envoyer les titres de votre bibliothèque à TMDB ?';
	@override String get notNow => 'Pas maintenant';
	@override String get lookThemUp => 'Les rechercher';
	@override String get waiting => 'En attente du chargement de votre bibliothèque.';
	@override String get stopped => 'En pause : TMDB ne répond plus. La recherche reprendra à la prochaine ouverture de l\'appli, et ce qui a été trouvé est conservé.';
	@override String running({required Object settled, required Object total}) => '${settled} titres recherchés sur ${total}.';
	@override String partial({required Object settled, required Object total}) => '${settled} titres recherchés sur ${total}. Le reste suivra à la prochaine ouverture de l\'appli.';
	@override String done({required Object found, required Object total}) => 'Terminé : ${found} dates de sortie trouvées pour ${total} titres.';
	@override String get releaseDates => 'Dates de sortie de votre bibliothèque';
	@override String get releaseDatesExplain => 'Ajoute des dates de sortie exactes en arrière-plan, pour que Trier par date de sortie classe correctement votre bibliothèque, y compris les titres sans année. Envoie tous les titres de votre bibliothèque à TMDB.';
	@override String get intro => 'Connectez votre propre clé TMDB pour ajouter le genre, la note et la langue originale aux résultats de recherche, ainsi que des suggestions basées sur ce que vous avez regardé. C\'est facultatif, et rien ne change tant que vous n\'en ajoutez pas.';
	@override String get keyExplain => 'Les titres recherchés sont envoyés depuis cet appareil à TMDB, et à personne d\'autre. Créez une clé gratuite dans votre compte TMDB, sous Paramètres, API. La clé courte comme le long jeton d\'accès en lecture fonctionnent. Sur une TV, il est plus simple de la coller ou de la taper d\'abord sur un téléphone ou un ordinateur.';
	@override String get keySaved => 'Clé TMDB enregistrée';
	@override String get removeKey => 'Retirer la clé';
	@override String get keyLabel => 'Clé d\'API TMDB';
	@override String get checking => 'Vérification...';
	@override String get verify => 'Vérifier et enregistrer';
	@override late final _Translations$settings$metadata$errors$fr errors = _Translations$settings$metadata$errors$fr._(_root);
}

// Path: settings.ai
class _Translations$settings$ai$fr extends Translations$settings$ai$en {
	_Translations$settings$ai$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get intro => 'Connectez votre propre fournisseur et votre propre clé. Les requêtes vont directement de cet appareil au fournisseur choisi, jamais par nous, car il n\'y a aucun serveur à nous entre les deux. Rien n\'est envoyé tant que vous n\'autorisez pas une fonction ci-dessous.';
	@override String get address => 'Adresse';
	@override String get model => 'Modèle';
	@override String get keyOptional => 'Clé d\'API (facultative pour un serveur local)';
	@override String get key => 'Clé d\'API';
	@override String get trying => 'Essai...';
	@override String get testAndSave => 'Tester et enregistrer';
	@override String get onNetwork => 'Sur votre réseau';
	@override String get keySaved => 'Clé enregistrée';
	@override String get remove => 'Retirer le fournisseur';
	@override String get maySend => 'Ce qu\'il peut envoyer';
	@override String get localNoConsent => 'Ce fournisseur est sur votre propre réseau, rien ne parvient donc à un tiers et aucun consentement n\'est nécessaire.';
	@override String sendsTo({required Object provider, required Object sends}) => 'Envoie à ${provider} : ${sends}';
	@override String allowedOn({required Object date}) => 'Autorisé le ${date}';
	@override String get notAllowed => 'Pas encore autorisé. Vous serez sollicité la première fois.';
	@override String get switchOff => 'Désactiver';
	@override String get allow => 'Autoriser';
}

// Path: settings.appearance
class _Translations$settings$appearance$fr extends Translations$settings$appearance$en {
	_Translations$settings$appearance$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$settings$appearance$palette$fr palette = _Translations$settings$appearance$palette$fr._(_root);
	@override String get theme => 'Thème';
	@override String get accent => 'Couleur d\'accent';
}

// Path: settings.section
class _Translations$settings$section$fr extends Translations$settings$section$en {
	_Translations$settings$section$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get sources => 'Sources';
	@override String get appearance => 'Apparence';
	@override String get playback => 'Lecture';
	@override String get subtitles => 'Sous-titres';
	@override String get metadata => 'Métadonnées';
	@override String get aiFeatures => 'Fonctions d\'IA';
	@override String get advancedSources => 'Sources avancées';
	@override String get transfer => 'Transférer vers un autre appareil';
	@override String get privacy => 'Confidentialité et données';
	@override String get about => 'À propos';
	@override String get trackers => 'Suivi des visionnages';
	@override String get requests => 'Demandes';
}

// Path: settings.advanced
class _Translations$settings$advanced$fr extends Translations$settings$advanced$en {
	_Translations$settings$advanced$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get dialogTitle => 'Activer les sources avancées';
	@override String get dialogLead => 'Vous allez connecter un fournisseur tiers avec vos propres identifiants.';
	@override String get dialogNoContent => 'Subnext Player ne fournit, n\'héberge ni ne cautionne aucun contenu ni aucun fournisseur. Vous indiquez l\'adresse et l\'identifiant, et l\'appli lit ce que renvoie cette adresse.';
	@override String get dialogRights => 'Il vous appartient de détenir les droits sur ce à quoi vous vous connectez.';
	@override String get dialogConfirm => 'Je comprends, activer';
	@override String get toggle => 'Fournisseur ou playlist IPTV';
	@override String get toggleExplain => 'Ajoute la TV en direct et les identifiants Xtream Codes.';
	@override String get offKeeps => 'Le désactiver plus tard masque la TV en direct mais conserve les comptes ajoutés.';
}

// Path: settings.sources
class _Translations$settings$sources$fr extends Translations$settings$sources$en {
	_Translations$settings$sources$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get noServers => 'Aucun serveur Plex connecté.';
	@override String get remove => 'Retirer';
	@override String loadFailed({required Object error}) => 'Impossible de charger les bibliothèques de ce serveur.\n\n${error}';
	@override String get lookForMore => 'Chercher d\'autres serveurs';
	@override String get addAnother => 'Ajouter un autre serveur';
	@override String get yours => 'À vous';
	@override String get shared => 'Partagé avec vous';
	@override String get viaRelay => 'via relais';
	@override String plexType({required Object type}) => 'Type Plex : ${type}';
	@override String get changedByYou => 'modifié par vous';
	@override String get localTab => 'Afficher Local et réseau';
	@override String get localTabSub => 'Un onglet de l\'accueil pour les vidéos de cet appareil et des partages réseau. Il s\'active tout seul quand vous en ajoutez un.';
}

// Path: addSource.kind
class _Translations$addSource$kind$fr extends Translations$addSource$kind$en {
	_Translations$addSource$kind$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get plex => 'Serveur Plex';
	@override String get plexShort => 'Associer avec un code';
	@override String get plexLong => 'Approuvez cet appareil dans votre navigateur. Votre propre serveur et tout ce qui est partagé avec vous.';
	@override String get localFiles => 'Vidéos sur cet appareil';
	@override String get localFilesSub => 'Parcourez votre médiathèque, ou choisissez un dossier précis auquel garder l\'accès.';
	@override String get localFilesIos => 'Lisez les vidéos de votre photothèque.';
	@override String get smb => 'Partage réseau (SMB)';
	@override String get smbSub => 'Un NAS ou un partage Windows sur votre réseau domestique.';
	@override String get xtream => 'Identifiant Xtream Codes';
	@override String get xtreamSub => 'Serveur, nom d\'utilisateur et mot de passe de votre fournisseur.';
	@override String get mediaBrowser => 'Serveur Jellyfin ou Emby';
	@override String get mediaBrowserSub => 'Votre propre serveur, avec votre propre compte.';
}

// Path: plex.errors
class _Translations$plex$errors$fr extends Translations$plex$errors$en {
	_Translations$plex$errors$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String noAnswer({required Object server, required Object count}) => '« ${server} » n\'a répondu sur aucune de ses ${count} adresses annoncées.';
	@override String get itemGone => 'Cet élément n\'est plus sur le serveur.';
	@override String get noFile => 'Aucun fichier lisible pour cet élément. Les sources uniquement transcodées ne sont pas encore prises en charge.';
	@override String get notConnected => 'Non connecté à un serveur Plex.';
}

// Path: xtream.catalogue
class _Translations$xtream$catalogue$fr extends Translations$xtream$catalogue$en {
	_Translations$xtream$catalogue$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get live => 'TV en direct';
	@override String get vod => 'Films';
	@override String get series => 'Séries';
}

// Path: xtream.errors
class _Translations$xtream$errors$fr extends Translations$xtream$errors$en {
	_Translations$xtream$errors$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String status({required Object code}) => 'Le panel a renvoyé ${code}. Réessayez plus tard.';
	@override String get timeout => 'Le panel n\'a pas répondu à temps.';
	@override String get unreachable => 'Impossible de joindre cette adresse. Vérifiez l\'hôte et le port.';
	@override String other({required Object type}) => 'Impossible de communiquer avec le panel (${type}).';
	@override String get notXtream => 'Cette adresse n\'a pas répondu comme un panel Xtream.';
	@override String get rejected => 'Le panel a refusé ces identifiants.';
	@override String get wrongLogin => 'Nom d\'utilisateur ou mot de passe incorrect.';
	@override String get unnamed => 'Sans nom';
	@override String get episode => 'Épisode';
	@override String get noPassword => 'Cette ligne n\'a pas de mot de passe enregistré. Retirez-la et ajoutez-la à nouveau.';
}

// Path: xtream.series
class _Translations$xtream$series$fr extends Translations$xtream$series$en {
	_Translations$xtream$series$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Série';
	@override String get noEpisodes => 'Le panel n\'a renvoyé aucun épisode pour cette série.';
	@override String season({required Object n}) => 'Saison ${n}';
}

// Path: xtream.addLine
class _Translations$xtream$addLine$fr extends Translations$xtream$addLine$en {
	_Translations$xtream$addLine$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get discardTitle => 'Abandonner cette ligne ?';
	@override String get discardBody => 'Ce que vous avez saisi ici n\'a pas été enregistré.';
	@override String get discard => 'Abandonner';
	@override String get keepEditing => 'Continuer la saisie';
	@override String inactive({required Object status}) => 'Le panel indique que cette ligne est « ${status} ».';
	@override String get noContent => 'Subnext Player ne fournit, n\'héberge ni ne cautionne aucun contenu ni aucun fournisseur. Vous indiquez l\'adresse et l\'identifiant, et l\'appli lit ce que renvoie cette adresse.';
	@override String get host => 'Adresse du serveur';
	@override String get name => 'Nom (facultatif)';
	@override String get nameHint => 'Le nom que vous voulez donner à cette ligne';
	@override String get checking => 'Vérification…';
	@override String get verify => 'Vérifier et ajouter';
	@override String connected({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: 'Connecté. ${n} flux simultané autorisé.',
		other: 'Connecté. ${n} flux simultanés autorisés.',
	);
}

// Path: xtream.picker
class _Translations$xtream$picker$fr extends Translations$xtream$picker$en {
	_Translations$xtream$picker$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get patternNone => 'Ce motif ne correspond à rien.';
	@override String title({required Object catalogue}) => 'Catégories ${catalogue}';
	@override String get save => 'Enregistrer';
	@override String noMatch({required Object query}) => 'Rien ne correspond à « ${query} ».';
	@override String get noneChosen => 'Rien de choisi pour l\'instant.';
	@override String get search => 'Rechercher dans toutes les catégories';
	@override String chosen({required Object n}) => 'Choisies ${n}';
	@override String get hideWords => 'Masquer des mots';
	@override String hideCount({required Object n}) => 'Masqués ${n}';
	@override String get pattern => 'Motif';
	@override String untickedOne({required Object name, required Object word}) => '« ${name} » a été décochée, car « ${word} » la masque. Enregistrez pour le conserver.';
	@override String untickedMany({required Object n, required Object word}) => '${n} catégories choisies que « ${word} » masque ont été décochées. Enregistrez pour le conserver.';
	@override String get showingHidden => 'Affichage des catégories que vos mots masqués excluent.';
	@override String hiddenCount({required Object n}) => '${n} masquées par vos mots.';
	@override String get hideAgain => 'Masquer à nouveau';
	@override String get showThem => 'Les afficher';
	@override String get patternHint => 'Cocher ou décocher toutes les catégories correspondant à un mot ou un motif';
	@override String get selectMatching => 'Cocher les correspondances';
	@override String get deselectMatching => 'Décocher les correspondances';
	@override String get groups => 'Groupes';
	@override String get clearAll => 'Tout décocher';
	@override String get selectAll => 'Tout cocher';
	@override String channelsPicked({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${n} chaîne',
		other: '${n} chaînes',
	);
	@override String pickedChosen({required Object n}) => '${n} choisies';
	@override String categories({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${n} catégorie',
		other: '${n} catégories',
	);
	@override String get channels => 'Chaînes';
}

// Path: xtream.channels
class _Translations$xtream$channels$fr extends Translations$xtream$channels$en {
	_Translations$xtream$channels$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get done => 'Terminé';
	@override String get search => 'Rechercher dans cette catégorie';
	@override String pickedOf({required Object picked, required Object total}) => '${picked} sur ${total}';
	@override String get whole => 'Toute la catégorie';
	@override String get selectShown => 'Cocher celles affichées';
	@override String get clear => 'Décocher';
	@override String get clearShown => 'Décocher celles affichées';
	@override String get none => 'Le panel ne liste aucune chaîne dans cette catégorie.';
}

// Path: xtream.hidden
class _Translations$xtream$hidden$fr extends Translations$xtream$hidden$en {
	_Translations$xtream$hidden$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Masquer des mots';
	@override String get explain => 'Une catégorie ou une chaîne contenant l\'un de ces mots en entier est exclue des listes. « UK » masque « UK News » mais pas « Ukraine ». Ajoutez une expression comme « south indian » pour la masquer d\'un bloc. La casse n\'a pas d\'importance.';
	@override String get hint => 'Un pays, une langue, un mot';
	@override String get add => 'Ajouter';
	@override String get none => 'Rien n\'est masqué pour l\'instant.';
	@override String get tapToRemove => 'Sélectionnez un mot pour ne plus le masquer.';
}

// Path: transfer.receive
class _Translations$transfer$receive$fr extends Translations$transfer$receive$en {
	_Translations$transfer$receive$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String cannotSave({required Object error}) => 'Impossible d\'enregistrer les réglages : ${error}';
	@override String get title => 'Recevoir des réglages';
	@override String get asking => 'Interrogation de l\'autre appareil…';
	@override String get awaitingPush => 'En attente de l\'envoi depuis l\'autre appareil. Acceptez là-bas quand il le demande.';
	@override String get saving => 'Enregistrement…';
	@override String get waitingInstructions => 'Sur l\'appareil qui a vos réglages, ouvrez Réglages, Transférer vers un autre appareil, et choisissez Envoyer. Puis scannez ce code.';
	@override String get scanInstructions => 'Sur l\'appareil qui a vos réglages, ouvrez Réglages, Transférer vers un autre appareil, et choisissez Envoyer, puis Afficher un code. Pointez la caméra dessus.';
	@override String get showMine => 'Afficher mon code';
	@override String get typeInstructions => 'Sur l\'appareil qui a vos réglages, ouvrez Réglages, Transférer vers un autre appareil, et choisissez Envoyer, puis Afficher un code. Saisissez ensuite ce qu\'il affiche.';
	@override String get connect => 'Connecter';
	@override String get review => 'Un autre appareil veut vous envoyer ceci. Ce qui est déjà ici sous le même nom est remplacé ; rien d\'autre n\'est retiré.';
	@override String get saveThese => 'Enregistrer';
	@override String get decline => 'Refuser';
	@override String get saved => 'Terminé. Vos réglages sont sur cet appareil.';
}

// Path: transfer.pairing
class _Translations$transfer$pairing$fr extends Translations$transfer$pairing$en {
	_Translations$transfer$pairing$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get noCamera => 'Pas de caméra ? Choisissez Saisir le code là-bas, et entrez :';
	@override String get qrLabel => 'Code à scanner depuis l\'autre appareil';
	@override String get cameraOff => 'La caméra est désactivée pour cette appli. Saisissez le code à la place, ou autorisez la caméra dans les réglages du téléphone.';
	@override String get cameraFailed => 'La caméra n\'a pas pu démarrer. Saisissez le code à la place.';
	@override String get foreign => 'Ce n\'est pas un code de cette appli.';
	@override String get checkEntry => 'Vérifiez l\'adresse (comme 192.168.1.20:41234) et le code à 16 caractères.';
	@override String get address => 'Adresse';
	@override String get code => 'Code';
}

// Path: transfer.pane
class _Translations$transfer$pane$fr extends Translations$transfer$pane$en {
	_Translations$transfer$pane$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get explain => 'Copiez vos sources, clés et préférences vers un autre appareil du même réseau Wi-Fi, pour ne pas avoir à tout retaper. Cela va directement d\'un appareil à l\'autre, chiffré avec un code que seuls les deux écrans partagent, et l\'appareil qui reçoit demande avant d\'enregistrer quoi que ce soit.';
	@override String get notCopied => 'Non copiés : Plex (associez-le sur l\'autre appareil avec son propre code), l\'historique, les favoris, et le consentement donné pour les Sources avancées et les Fonctions d\'IA, que chaque appareil demande lui-même.';
	@override String get receive => 'Recevoir depuis un autre appareil';
	@override String get send => 'Envoyer vers un autre appareil';
}

// Path: transfer.notes
class _Translations$transfer$notes$fr extends Translations$transfer$notes$en {
	_Translations$transfer$notes$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get aiLocal => 'Votre fournisseur d\'IA tourne sur cet appareil, il n\'est donc pas envoyé. Configurez-le à nouveau là-bas avec l\'adresse de cet appareil sur votre réseau.';
	@override String get xtreamHidden => 'Les comptes IPTV sont enregistrés mais masqués. Activez les Sources avancées dans Réglages pour les utiliser.';
	@override String get aiAsks => 'Les fonctions d\'IA demanderont avant d\'envoyer quoi que ce soit au fournisseur.';
	@override String partial({required Object failed}) => 'Impossible d\'enregistrer : ${failed}. Le reste a été enregistré.';
}

// Path: transfer.send
class _Translations$transfer$send$fr extends Translations$transfer$send$en {
	_Translations$transfer$send$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String cannotRead({required Object error}) => 'Impossible de lire les réglages de cet appareil : ${error}';
	@override String askTitle({required Object host}) => 'Envoyer à ${host} ?';
	@override String askBody({required Object summary}) => 'Un appareil de votre réseau a scanné ce code et demande :\n\n${summary}\n\nN\'acceptez que si vous venez de le demander sur cet appareil.';
	@override String get notNow => 'Pas maintenant';
	@override String get send => 'Envoyer';
	@override String get title => 'Envoyer des réglages';
	@override String get reading => 'Lecture de vos réglages…';
	@override String get sending => 'Envoi en cours. L\'autre appareil demandera avant d\'enregistrer quoi que ce soit.';
	@override String get explain => 'Copie ceci vers un autre appareil du même réseau Wi-Fi, pour ne pas avoir à tout retaper. Cela va directement là-bas, chiffré ; rien ne passe par nous.';
	@override String get nothing => 'Rien n\'est encore configuré sur cet appareil à envoyer.';
	@override String get proceed => 'Continuer';
	@override String get showInstead => 'Afficher un code';
	@override String get typeInstead => 'Saisir le code';
	@override String get scanInstructions => 'Sur l\'autre appareil, ouvrez Réglages, Transférer vers un autre appareil, et choisissez Recevoir. Pointez la caméra sur le code qu\'il affiche.';
	@override String get showInstructions => 'Sur l\'autre appareil, ouvrez Réglages, Transférer vers un autre appareil, et choisissez Recevoir, puis Scanner son code, et pointez sa caméra ici. Vous serez sollicité avant tout envoi.';
	@override String get typeInstructions => 'Sur l\'autre appareil, ouvrez Réglages, Transférer vers un autre appareil, et choisissez Recevoir. Saisissez ensuite ce qu\'il affiche.';
	@override String get sent => 'Envoyé. L\'autre appareil a enregistré vos réglages.';
}

// Path: transfer.item
class _Translations$transfer$item$fr extends Translations$transfer$item$en {
	_Translations$transfer$item$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get preferences => 'Préférences';
	@override String get preferencesSub => 'Choix de lecture et de sous-titres, mots masqués et emplacement dans la bibliothèque.';
	@override String get xtream => 'Comptes IPTV';
	@override String get xtreamSub => 'Identifiants, et les catégories et chaînes choisies.';
	@override String get smb => 'Partages réseau';
	@override String get smbSub => 'Partages SMB et leurs mots de passe.';
	@override String get tmdb => 'Clé TMDB';
	@override String get tmdbSub => 'Votre propre clé pour les filtres de genre, de note et de langue.';
	@override String get ai => 'Fournisseur d\'IA';
	@override String get aiSub => 'Le fournisseur, son modèle et votre clé.';
	@override String settings({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${n} réglage',
		other: '${n} réglages',
	);
	@override String accounts({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${n} compte',
		other: '${n} comptes',
	);
	@override String shares({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${n} partage',
		other: '${n} partages',
	);
	@override String get notBundle => 'Ce n\'était pas un paquet de réglages.';
	@override String get newer => 'Ce paquet vient d\'une version plus récente de l\'appli. Mettez à jour cet appareil et réessayez.';
	@override String get trackers => 'Suivi des visionnages';
	@override String get trackersSub => 'Vos connexions Trakt, Simkl, AniList et MyAnimeList. Les accepter ici, c\'est accepter d\'envoyer aussi ce que vous regardez sur cet appareil.';
	@override String services({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${n} service',
		other: '${n} services',
	);
}

// Path: transfer.client
class _Translations$transfer$client$fr extends Translations$transfer$client$en {
	_Translations$transfer$client$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get declined => 'L\'autre appareil n\'a pas accepté les réglages.';
	@override String get wrongCode => 'Le code n\'était pas bon. Comparez-le avec l\'autre écran.';
	@override String get used => 'L\'autre appareil a déjà reçu quelque chose. Rouvrez Recevoir là-bas pour un nouveau code.';
	@override String get tooBig => 'C\'était trop volumineux à envoyer.';
	@override String get unreadable => 'L\'autre appareil n\'a pas pu le lire.';
	@override String unexpected({required Object status}) => 'L\'autre appareil a répondu de façon inattendue (${status}).';
	@override String get refusedToSend => 'L\'autre appareil n\'a pas accepté d\'envoyer ses réglages.';
	@override String get busy => 'L\'autre appareil répond déjà à quelqu\'un d\'autre. Demandez-lui un nouveau code.';
	@override String unreachable({required Object address}) => 'Impossible de joindre ${address}. Les deux appareils doivent être sur le même Wi-Fi, et l\'autre doit encore afficher son code.';
	@override String get dropped => 'La connexion a été coupée en cours de route.';
	@override String noAnswer({required Object address}) => 'Pas de réponse de ${address}. Vérifiez l\'autre écran.';
}

// Path: mediaBrowser.errors
class _Translations$mediaBrowser$errors$fr extends Translations$mediaBrowser$errors$en {
	_Translations$mediaBrowser$errors$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String signedOut({required Object server}) => '${server} n\'accepte plus cette connexion. Retirez-le dans Réglages, Sources et ajoutez-le à nouveau.';
	@override String status({required Object server, required Object code}) => '${server} a répondu ${code}.';
	@override String unreachable({required Object server}) => 'Impossible de joindre ${server}. Il est peut-être en veille ou hors du réseau.';
	@override String get notAServer => 'Aucun serveur Jellyfin ou Emby n\'a répondu à cette adresse. Vérifiez-la, port compris (souvent 8096).';
	@override String get badAnswer => 'Le serveur a répondu d\'une façon que cette appli ne comprend pas.';
	@override String get wrongLogin => 'Nom d\'utilisateur ou mot de passe incorrect.';
}

// Path: trackers.errors
class _Translations$trackers$errors$fr extends Translations$trackers$errors$en {
	_Translations$trackers$errors$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String unavailable({required Object service}) => 'Impossible de joindre ${service}. Nouvel essai plus tard.';
	@override String get denied => 'La connexion a été refusée.';
	@override String get expired => 'Ce code a expiré. Recommencez pour en obtenir un nouveau.';
	@override String get badPaste => 'Ce n\'est pas ce qu\'a donné la page de connexion. Copiez-le à nouveau et collez-le en entier.';
}

// Path: seerr.errors
class _Translations$seerr$errors$fr extends Translations$seerr$errors$en {
	_Translations$seerr$errors$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get notASeerr => 'Aucun serveur Overseerr, Jellyseerr ou Seerr n\'a répondu à cette adresse. Vérifiez-la, port compris (souvent 5055).';
	@override String get badKey => 'Le serveur n\'a pas accepté cette clé d\'API.';
	@override String get refused => 'Le serveur n\'a pas accepté cette connexion.';
	@override String status({required Object code}) => 'Le serveur a répondu ${code}.';
	@override String get unreachable => 'Impossible de joindre le serveur de demandes.';
	@override String get signedOut => 'Le serveur de demandes n\'accepte plus cette connexion. Reconnectez-le dans Réglages, Demandes.';
	@override String get alreadyRequested => 'Cela a déjà été demandé.';
}

// Path: settings.metadata.errors
class _Translations$settings$metadata$errors$fr extends Translations$settings$metadata$errors$en {
	_Translations$settings$metadata$errors$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get rejected => 'TMDB a refusé cette clé.';
	@override String get rateLimited => 'TMDB limite les requêtes de cet appareil.';
	@override String unreachable({required Object type}) => 'Impossible de joindre TMDB (${type}).';
}

// Path: settings.appearance.palette
class _Translations$settings$appearance$palette$fr extends Translations$settings$appearance$palette$en {
	_Translations$settings$appearance$palette$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get system => 'Système';
	@override String get midnight => 'Minuit';
	@override String get slate => 'Ardoise';
	@override String get daylight => 'Jour';
	@override String get amber => 'Ambre';
}

/// The flat map containing all translations for locale <fr>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsFr {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'common.back' => 'Retour',
			'common.tryAgain' => 'Réessayer',
			'common.cancel' => 'Annuler',
			'common.noDrm' => 'Pas de DRM. Les catalogues commerciaux protégés comme Netflix ou Disney+ ne peuvent pas être lus.',
			'player.shareGone' => 'Ce partage n\'est plus configuré.',
			'player.shareFileGone' => 'Ce fichier n\'est plus sur le partage.',
			'player.deviceFileGone' => 'Ce fichier n\'est plus sur cet appareil.',
			'player.lineGone' => 'Cette ligne n\'est plus configurée.',
			'player.untitledVideo' => 'Vidéo',
			'player.untitledEpisode' => 'Épisode',
			'player.untitledFilm' => 'Film',
			'player.untitledLive' => 'En direct',
			'player.channelFroze' => 'Cette chaîne s\'est arrêtée et n\'est pas revenue.',
			'player.channelNotResponding' => 'Cette chaîne ne répond pas. Les listes d\'un panel sont souvent en avance sur la réalité, alors essayez-en une autre, ou la même à nouveau.',
			'player.didNotStart' => 'La lecture n\'a pas démarré. Le serveur est peut-être occupé, ou le fichier doit être transcodé, ce qui n\'est pas encore pris en charge.',
			'player.released' => 'Arrêté pendant que l\'appli était en arrière-plan, pour libérer la connexion pour d\'autres appareils.',
			'player.rejoin' => 'Reprendre',
			'player.live' => 'EN DIRECT',
			'player.skipBack' => ({required Object seconds}) => 'Reculer de ${seconds} secondes',
			'player.skipForward' => ({required Object seconds}) => 'Avancer de ${seconds} secondes',
			'player.pause' => 'Pause',
			'player.play' => 'Lecture',
			'player.tracks' => 'Audio et sous-titres',
			'player.audio' => 'Audio',
			'player.subtitles' => 'Sous-titres',
			'player.off' => 'Désactivés',
			'player.trackNumber' => ({required Object n}) => 'Piste ${n}',
			'player.upNext.title' => 'À suivre',
			'player.upNext.playingIn' => ({required Object seconds}) => 'Lecture dans ${seconds} s',
			'player.upNext.playNow' => 'Lire maintenant',
			'languages.en' => 'Anglais',
			'languages.es' => 'Espagnol',
			'languages.fr' => 'Français',
			'languages.de' => 'Allemand',
			'languages.it' => 'Italien',
			'languages.pt' => 'Portugais',
			'languages.nl' => 'Néerlandais',
			'languages.sv' => 'Suédois',
			'languages.no' => 'Norvégien',
			'languages.da' => 'Danois',
			'languages.fi' => 'Finnois',
			'languages.pl' => 'Polonais',
			'languages.cs' => 'Tchèque',
			'languages.hu' => 'Hongrois',
			'languages.ro' => 'Roumain',
			'languages.el' => 'Grec',
			'languages.ru' => 'Russe',
			'languages.uk' => 'Ukrainien',
			'languages.tr' => 'Turc',
			'languages.ar' => 'Arabe',
			'languages.he' => 'Hébreu',
			'languages.hi' => 'Hindi',
			'languages.bn' => 'Bengali',
			'languages.pa' => 'Pendjabi',
			'languages.ta' => 'Tamoul',
			'languages.te' => 'Télougou',
			'languages.ur' => 'Ourdou',
			'languages.th' => 'Thaï',
			'languages.vi' => 'Vietnamien',
			'languages.id' => 'Indonésien',
			'languages.zh' => 'Chinois',
			'languages.ja' => 'Japonais',
			'languages.ko' => 'Coréen',
			'subtitleSize.small' => 'Petite',
			'subtitleSize.medium' => 'Moyenne',
			'subtitleSize.large' => 'Grande',
			'units.minutes' => ({required Object m}) => '${m} min',
			'units.hours' => ({required Object h}) => '${h} h',
			'units.hoursMinutes' => ({required Object h, required Object m}) => '${h} h ${m} min',
			'units.minutesLeft' => ({required Object m}) => '${m} min restantes',
			'units.seconds' => ({required Object s}) => '${s} s',
			'downloads.empty' => 'Rien n\'est encore téléchargé. Appuyez longuement sur un film ou un épisode de votre bibliothèque Plex et choisissez Télécharger, puis regardez-le ici sans réseau.',
			'downloads.title' => 'Téléchargements',
			'downloads.summary' => ({required num n, required Object size}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${n} élément · ${size} sur cet appareil', other: '${n} éléments · ${size} sur cet appareil', ), 
			'downloads.pendingWatches' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '1 visionnage d\'ici attend d\'être envoyé à Plex.', other: '${n} visionnages d\'ici attendent d\'être envoyés à Plex.', ), 
			'downloads.foregroundOnly' => 'Les téléchargements continuent tant que l\'appli est ouverte. La fermer les met en pause, et rien de ce qui est déjà enregistré n\'est perdu.',
			'downloads.downloadingBytes' => ({required Object received}) => 'Téléchargement, ${received}',
			'downloads.downloadingPercent' => ({required Object percent, required Object received, required Object total}) => 'Téléchargement ${percent} % · ${received} sur ${total}',
			'downloads.queued' => 'En attente de son tour',
			'downloads.paused' => 'En pause',
			'downloads.pausedAt' => ({required Object percent}) => 'En pause à ${percent} % · sélectionnez pour reprendre',
			'downloads.failed' => ({required Object error}) => '${error} Sélectionnez pour réessayer.',
			'downloads.failedUnknown' => 'Il ne s\'est pas terminé.',
			'downloads.deleteTitle' => 'Supprimer ce téléchargement ?',
			'downloads.cancelTitle' => 'Annuler ce téléchargement ?',
			'downloads.removeBody' => ({required Object title}) => '« ${title} » sera supprimé de cet appareil. Il reste sur votre serveur Plex.',
			'downloads.removeBodyFreeing' => ({required Object title, required Object size}) => '« ${title} » sera supprimé de cet appareil, ce qui libère ${size}. Il reste sur votre serveur Plex.',
			'downloads.keepIt' => 'Le garder',
			'downloads.delete' => 'Supprimer',
			'downloads.errors.serverNotConnected' => 'Ce serveur n\'est pas connecté. Reconnectez-le dans Réglages, puis reprenez.',
			'downloads.errors.sizeMismatch' => 'Le fichier ne correspond pas à la taille indiquée par le serveur. Réessayez.',
			'downloads.errors.cannotWrite' => 'Impossible d\'écrire le fichier. L\'appareil manque peut-être d\'espace.',
			'downloads.errors.changedOnServer' => 'Le fichier a changé sur le serveur. Relancez le téléchargement.',
			'downloads.errors.refused' => 'Le serveur n\'autorise pas cet appareil à télécharger cela.',
			'downloads.errors.status' => ({required Object code}) => 'Le serveur a répondu ${code}.',
			'downloads.errors.dropped' => 'La connexion a été coupée en cours de route. Reprenez pour continuer.',
			'downloads.errors.unreachable' => 'Impossible de joindre le serveur. Vérifiez la connexion et reprenez.',
			'downloads.errors.timeout' => 'Le serveur a mis trop de temps à répondre.',
			'downloads.rule.off' => 'Garder des épisodes téléchargés',
			'downloads.rule.keeping' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: 'L\'épisode suivant reste téléchargé', other: 'Les ${n} épisodes suivants restent téléchargés', ), 
			'downloads.rule.explain' => 'Télécharge les prochains épisodes non vus et les remplace au fil de votre visionnage, tant que l\'appli est ouverte. Ceux qu\'il a téléchargés et que vous avez vus sont supprimés.',
			'downloads.rule.choiceOff' => 'Désactivé',
			'downloads.rule.choice' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: 'Épisode suivant', other: '${n} épisodes suivants', ), 
			'watchActions.everyEpisode' => ' (tous les épisodes)',
			'watchActions.markWatched' => ({required Object scope}) => 'Marquer comme vu${scope}',
			'watchActions.markUnwatched' => ({required Object scope}) => 'Marquer comme non vu${scope}',
			'watchActions.download' => 'Télécharger sur cet appareil',
			'watchActions.deleteDownload' => 'Supprimer le téléchargement',
			'watchActions.cancelDownload' => 'Annuler le téléchargement',
			'watchActions.removeFavourite' => 'Retirer des favoris',
			'watchActions.addFavourite' => 'Ajouter aux favoris',
			'watchActions.removeResume' => 'Retirer de Reprendre la lecture',
			'watchActions.downloading' => 'Téléchargement en cours. Voir l\'onglet Téléchargements.',
			'watchActions.markedOffline' => 'Marqué comme vu ici. Plex en sera informé dès qu\'il sera joignable.',
			'watchActions.plexRefused' => 'Plex ne l\'a pas accepté. Le serveur est peut-être hors ligne.',
			'watchActions.details' => 'Détails',
			'show.noEpisodes' => 'Cette série n\'a aucun épisode sur le serveur.',
			'shell.library' => 'Bibliothèque',
			'shell.search' => 'Recherche',
			'shell.downloads' => 'Téléchargements',
			'shell.settings' => 'Réglages',
			'shell.exitTitle' => 'Quitter Subnext Player ?',
			'shell.exit' => 'Quitter',
			'shell.stay' => 'Rester',
			'resume.upNext' => 'À suivre',
			'resume.title' => 'Reprendre la lecture',
			'resume.remove' => 'Retirer de Reprendre la lecture',
			'library.placement.movies' => 'Films',
			'library.placement.series' => 'Séries',
			'library.placement.hidden' => 'Masqué',
			'library.tab.movies' => 'Films',
			'library.tab.series' => 'Séries',
			'library.tab.localNetwork' => 'Local et réseau',
			'library.tab.liveTv' => 'TV en direct',
			'library.tab.emptyMovies' => 'Aucun film sur ce serveur.',
			'library.tab.emptySeries' => 'Aucune série sur ce serveur.',
			'library.tab.emptyLocalNetwork' => 'Aucun dossier ni partage réseau pour l\'instant.\nLe stockage de l\'appareil et les partages SMB ne sont pas connectables dans cette version.',
			'library.tab.emptyLiveTv' => 'Aucune playlist ni aucun panel configuré.\nAjoutez-en un depuis Réglages une fois les Sources avancées activées.',
			'library.tab.countMovies' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${n} film', other: '${n} films', ), 
			'library.tab.countSeries' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${n} série', other: '${n} séries', ), 
			'library.tab.countItems' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${n} élément', other: '${n} éléments', ), 
			'library.tab.countChannels' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${n} chaîne', other: '${n} chaînes', ), 
			'library.serverTimeout' => ({required Object server, required Object seconds}) => '${server} n\'a pas répondu en ${seconds} secondes. Il est peut-être en veille ou hors du réseau.',
			'library.allWatched' => 'Vous avez tout vu dans Films.',
			'library.showAll' => 'Tout afficher',
			'library.noSources' => 'Aucune source connectée pour l\'instant.',
			'library.nothingIn' => ({required Object tab}) => 'Rien dans ${tab} pour l\'instant.',
			'library.addSource' => 'Ajouter une source',
			'library.sortFiltered' => ({required Object sort}) => '${sort} · Non vus',
			'library.sortBy' => 'Trier par',
			'library.unwatchedOnly' => 'Non vus seulement',
			'library.shelf.seeAll' => 'Tout voir',
			'library.shelf.titles' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${n} titre', other: '${n} titres', ), 
			'library.shelf.gone' => 'Il n\'y a plus rien ici.',
			'library.sort.title' => 'Titre',
			'library.sort.recentlyAdded' => 'Ajout récent',
			'library.sort.year' => 'Année',
			'library.sort.releaseDate' => 'Date de sortie',
			'library.tile.series' => 'Série',
			'library.tile.movie' => 'Film',
			'library.tile.watched' => 'Vu',
			'library.tile.percentWatched' => ({required Object percent}) => 'Vu à ${percent} %',
			'library.tile.unwatchedEpisodes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${n} épisode non vu', other: '${n} épisodes non vus', ), 
			'liveTv.group.favourites' => 'Favoris',
			'liveTv.group.numbered' => ({required Object n}) => 'Catégorie ${n}',
			'liveTv.group.other' => 'Autres',
			'liveTv.noPanel' => 'Aucune playlist ni aucun panel configuré.',
			'liveTv.addOne' => 'En ajouter un',
			'liveTv.noCategories' => 'Aucune catégorie choisie pour l\'instant.\nLes panels comptent des dizaines de milliers de chaînes, alors Subnext Player ne récupère que celles que vous choisissez.',
			'liveTv.chooseCategories' => 'Choisir des catégories',
			'liveTv.noChannels' => 'Ces catégories n\'ont renvoyé aucune chaîne.',
			'liveTv.noMatch' => ({required Object query}) => 'Aucune chaîne ne correspond à « ${query} ».',
			'liveTv.searchHint' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: 'Rechercher parmi ${n} chaîne', other: 'Rechercher parmi ${n} chaînes', ), 
			'liveTv.all' => 'Toutes',
			'ai.picks.yourProvider' => 'votre fournisseur',
			'ai.picks.ask' => 'Que regarder ?',
			'ai.picks.askExplain' => ({required Object provider}) => 'Demandez à ${provider} de choisir dans votre propre bibliothèque.',
			'ai.picks.pickedBy' => 'Choisi pour vous par ',
			'ai.picks.updating' => 'Mise à jour',
			'ai.picks.again' => 'Encore',
			'ai.picks.preparing' => 'Préparation de vos suggestions...',
			'ai.search.asking' => ({required Object provider}) => 'Interrogation de ${provider}...',
			'ai.search.searching' => ({required Object searched, required Object covered}) => 'Recherche dans votre bibliothèque... ${searched} sur ${covered} titres',
			'ai.search.emptyLibrary' => 'Il n\'y a encore rien à rechercher dans votre bibliothèque.',
			'ai.search.notFound' => ({required Object total}) => 'Le modèle n\'a rien trouvé qui corresponde parmi ${total} titres. Essayez de le décrire autrement.',
			'ai.search.notFoundFirst' => ({required Object covered, required Object total}) => 'Le modèle n\'a rien trouvé qui corresponde parmi les ${covered} premiers des ${total} titres. Essayez de le décrire autrement.',
			'ai.search.stillSearching' => ({required Object searched, required Object covered}) => 'Recherche en cours : ${searched} sur ${covered} titres',
			'ai.search.searchedFirst' => ({required Object covered, required Object total}) => 'Recherche dans les ${covered} premiers des ${total} titres',
			'ai.search.pickedFor' => ({required Object provider, required Object query}) => 'Choisi par ${provider} pour « ${query} »',
			'ai.search.searchAgain' => 'Relancer la recherche',
			'ai.search.partsFailed' => ({required Object failed, required Object parts}) => '${failed} parties sur ${parts} n\'ont pas pu être recherchées, une partie de votre bibliothèque n\'a donc pas été examinée. Le fournisseur limite peut-être les requêtes',
			'ai.presetOther' => 'Autre',
			'ai.hintOpenRouter' => 'Les identifiants de modèle sont listés sur openrouter.ai/models. Les gratuits se terminent par ":free".',
			'ai.hintOllama' => 'Utilisez l\'adresse de votre ordinateur sur ce réseau, par exemple http://192.168.1.20:11434/v1. Rien ne quitte votre réseau.',
			'ai.hintCustom' => 'Tout service qui parle le format de chat d\'OpenAI.',
			'ai.feature.naturalSearch' => 'Recherche en langage naturel',
			'ai.feature.naturalSearchSends' => 'Le texte de votre recherche, et les titres et années de votre bibliothèque.',
			'ai.feature.naturalSearchTiming' => 'Une grande bibliothèque est envoyée en plusieurs requêtes de quelques centaines de titres chacune, une recherche en fait donc plusieurs.',
			'ai.feature.recommendations' => 'Recommandations',
			'ai.feature.recommendationsSends' => 'Les films que vous avez vus récemment, et les titres et années de ce que vous n\'avez pas encore vu dans votre bibliothèque.',
			'ai.feature.recommendationsTiming' => 'Les suggestions sont préparées en arrière-plan peu après l\'ouverture de l\'appli, mais seulement si ce que vous avez vu a changé ou si elles datent de plus d\'un jour, il n\'y a donc pas de requête à chaque lancement.',
			'ai.errors.ranOutThinking' => 'Le modèle a manqué de place pour répondre pendant sa réflexion et n\'a jamais donné de réponse. Un modèle qui ne « réfléchit » pas d\'abord fonctionnera mieux.',
			'ai.errors.empty' => 'Le modèle a renvoyé une réponse vide.',
			'ai.errors.rejectedKey' => ({required Object suffix}) => 'Le fournisseur a refusé cette clé${suffix}.',
			'ai.errors.noCredit' => ({required Object suffix}) => 'Le fournisseur indique que ce compte n\'a plus de crédit${suffix}.',
			'ai.errors.unknownModel' => ({required Object suffix}) => 'Le fournisseur ne connaît pas ce modèle ou cette adresse${suffix}.',
			'ai.errors.rateLimited' => ({required Object suffix}) => 'Le fournisseur limite cette clé. Réessayez dans un instant${suffix}.',
			'ai.errors.serverError' => ({required Object status, required Object suffix}) => 'Le fournisseur a rencontré un problème (HTTP ${status})${suffix}.',
			'ai.errors.timeout' => 'Le fournisseur a mis trop de temps à répondre.',
			'ai.errors.unreachable' => 'Impossible de joindre le fournisseur. Vérifiez l\'adresse.',
			'ai.errors.failed' => ({required Object suffix}) => 'La requête a échoué${suffix}.',
			'ai.errors.failedStatus' => ({required Object status, required Object suffix}) => 'La requête a échoué (HTTP ${status})${suffix}.',
			'ai.errors.fillIn' => 'Renseignez l\'adresse et le modèle.',
			'ai.errors.needsKey' => 'Ce fournisseur a besoin d\'une clé d\'API.',
			'ai.errors.notSetUp' => 'Aucun fournisseur d\'IA n\'est configuré.',
			'ai.errors.searchOff' => 'La recherche en langage naturel est désactivée pour ce fournisseur.',
			'ai.errors.searchFailed' => 'La recherche a échoué.',
			'ai.errors.noSignal' => 'Regardez d\'abord un film, pour qu\'il y ait de quoi baser les suggestions.',
			'ai.errors.noPicks' => 'Le modèle n\'a rien choisi cette fois-ci.',
			'ai.consentTitle' => ({required Object provider}) => 'Envoyer des données à ${provider} ?',
			'ai.consentBody' => ({required Object feature, required Object provider, required Object sends}) => '${feature} enverra ceci à ${provider} : ${sends}',
			'ai.consentTail' => 'Cela va directement de cet appareil vers eux, jamais par nous. Vous pouvez le désactiver à nouveau dans Réglages, Fonctions d\'IA.',
			'ai.notNow' => 'Pas maintenant',
			'ai.allow' => 'Autoriser',
			'search.filters.decadeOldest' => ({required Object decade}) => 'Années ${decade} et avant',
			'search.filters.decade' => ({required Object decade}) => 'Années ${decade}',
			'search.filters.type' => 'Type',
			'search.filters.movies' => 'Films',
			'search.filters.series' => 'Séries',
			'search.filters.source' => 'Source',
			'search.filters.unknownSource' => 'Source inconnue',
			'search.filters.year' => 'Année',
			'search.filters.language' => 'Langue',
			'search.filters.languageNote' => 'Déduite des noms de catégories IPTV. Les titres Plex n\'ont pas de langue ici.',
			'search.filters.genre' => 'Genre',
			'search.filters.rating' => 'Note',
			'search.filters.ratingNote' => 'Note des utilisateurs de TMDB sur 10. Les titres sans note sur TMDB sont exclus.',
			'search.filters.originalLanguage' => 'Langue originale',
			'search.filters.originalLanguageNote' => 'La langue dans laquelle le titre a été tourné, d\'après TMDB. Une copie doublée garde ici sa langue originale.',
			'search.filters.clear' => 'Effacer',
			'search.filters.noMatches' => 'Rien ne correspond à ces filtres.',
			'search.filters.clearAll' => 'Effacer les filtres',
			'search.filters.chip' => ({required Object label, required Object value}) => '${label} : ${value}',
			'search.filters.any' => 'Toutes',
			'search.hint' => 'Rechercher dans vos sources',
			'search.prompt' => 'Recherchez des films et des séries sur votre serveur.',
			'search.keepTyping' => 'Continuez à taper…',
			'search.noMatch' => ({required Object query}) => 'Rien ne correspond à « ${query} ».',
			'search.backToResults' => 'Retour aux résultats',
			'search.askAi' => 'Demander à l\'IA',
			'search.becauseYouWatched' => 'Parce que vous avez regardé ',
			'settings.about.versionLoading' => 'Version …',
			'settings.about.version' => ({required Object version, required Object build}) => 'Version ${version} (${build})',
			'settings.about.privacyPolicy' => 'Politique de confidentialité',
			'settings.about.privacySummary' => 'Pas de compte, pas de serveur à nous et pas de statistiques. La politique complète se trouve à :',
			'settings.about.licences' => 'Licences open source',
			'settings.privacy.summary' => 'Subnext Player n\'a ni serveur à nous ni statistiques. Ce qu\'il conserve reste sur cet appareil, et les seuls endroits où des données sont envoyées sont les sources, TMDB et le fournisseur d\'IA que vous connectez vous-même.',
			'settings.privacy.cachedData' => 'Données en cache',
			'settings.privacy.cachedExplain' => 'Les listes de votre bibliothèque, les recherches TMDB et les suggestions de l\'IA sont conservées pour que l\'appli s\'ouvre vite. Les anciennes s\'effacent d\'elles-mêmes, après 30 jours pour une bibliothèque et 90 pour une recherche, et les données d\'une source disparaissent quand vous la retirez. Effacer maintenant ne touche ni à vos sources, ni à vos clés, ni à vos réglages, ni à votre historique, et tout est récupéré à nouveau au besoin.',
			'settings.privacy.clearing' => 'Effacement...',
			'settings.privacy.clear' => 'Effacer les données en cache',
			'settings.privacy.cleared' => 'Effacé. Votre bibliothèque se recharge.',
			'settings.playback.skip' => 'Reculer et avancer',
			'settings.playback.skipExplain' => 'Les boutons de saut, les touches d\'avance et de retour rapides d\'une télécommande, et le premier pas sur la barre de progression.',
			'settings.playback.audioLanguage' => 'Langue audio préférée',
			'settings.playback.audioLanguageExplain' => 'Utilisée quand un fichier a plusieurs pistes audio. Sinon, c\'est la piste par défaut du fichier qui est lue.',
			'settings.playback.fileDefault' => 'Par défaut du fichier',
			'settings.playback.showSubtitles' => 'Afficher les sous-titres',
			'settings.playback.showSubtitlesExplain' => 'Les activer quand un fichier en contient. Vous pouvez toujours changer dans le lecteur.',
			'settings.playback.subtitleLanguage' => 'Langue de sous-titres préférée',
			'settings.playback.subtitleLanguageExplain' => 'Si un fichier n\'a pas de sous-titres dans cette langue, aucun n\'est affiché.',
			'settings.playback.any' => 'Toutes',
			'settings.playback.size' => 'Taille',
			'settings.playback.sizeExplain' => 'Pour les sous-titres texte, comme SRT et ASS.',
			'settings.metadata.consent' => 'Cela recherche sur TMDB la date de sortie de chaque film et série de votre bibliothèque, en arrière-plan, quelques-uns à la fois. Pour cela, le titre (et l\'année, s\'il y en a une) de chacun est envoyé depuis cet appareil à TMDB, et à personne d\'autre, pas seulement ceux que vous recherchez. Cela renseigne aussi le genre et la note pour les filtres. Les résultats sont conservés sur cet appareil pendant 90 jours, et les titres déjà recherchés ne sont pas redemandés.\n\nVous pouvez le désactiver à tout moment. Retirer votre clé TMDB le désactive aussi.',
			'settings.metadata.consentTitle' => 'Envoyer les titres de votre bibliothèque à TMDB ?',
			'settings.metadata.notNow' => 'Pas maintenant',
			'settings.metadata.lookThemUp' => 'Les rechercher',
			'settings.metadata.waiting' => 'En attente du chargement de votre bibliothèque.',
			'settings.metadata.stopped' => 'En pause : TMDB ne répond plus. La recherche reprendra à la prochaine ouverture de l\'appli, et ce qui a été trouvé est conservé.',
			'settings.metadata.running' => ({required Object settled, required Object total}) => '${settled} titres recherchés sur ${total}.',
			'settings.metadata.partial' => ({required Object settled, required Object total}) => '${settled} titres recherchés sur ${total}. Le reste suivra à la prochaine ouverture de l\'appli.',
			'settings.metadata.done' => ({required Object found, required Object total}) => 'Terminé : ${found} dates de sortie trouvées pour ${total} titres.',
			'settings.metadata.releaseDates' => 'Dates de sortie de votre bibliothèque',
			'settings.metadata.releaseDatesExplain' => 'Ajoute des dates de sortie exactes en arrière-plan, pour que Trier par date de sortie classe correctement votre bibliothèque, y compris les titres sans année. Envoie tous les titres de votre bibliothèque à TMDB.',
			'settings.metadata.intro' => 'Connectez votre propre clé TMDB pour ajouter le genre, la note et la langue originale aux résultats de recherche, ainsi que des suggestions basées sur ce que vous avez regardé. C\'est facultatif, et rien ne change tant que vous n\'en ajoutez pas.',
			'settings.metadata.keyExplain' => 'Les titres recherchés sont envoyés depuis cet appareil à TMDB, et à personne d\'autre. Créez une clé gratuite dans votre compte TMDB, sous Paramètres, API. La clé courte comme le long jeton d\'accès en lecture fonctionnent. Sur une TV, il est plus simple de la coller ou de la taper d\'abord sur un téléphone ou un ordinateur.',
			'settings.metadata.keySaved' => 'Clé TMDB enregistrée',
			'settings.metadata.removeKey' => 'Retirer la clé',
			'settings.metadata.keyLabel' => 'Clé d\'API TMDB',
			'settings.metadata.checking' => 'Vérification...',
			'settings.metadata.verify' => 'Vérifier et enregistrer',
			'settings.metadata.errors.rejected' => 'TMDB a refusé cette clé.',
			'settings.metadata.errors.rateLimited' => 'TMDB limite les requêtes de cet appareil.',
			'settings.metadata.errors.unreachable' => ({required Object type}) => 'Impossible de joindre TMDB (${type}).',
			'settings.ai.intro' => 'Connectez votre propre fournisseur et votre propre clé. Les requêtes vont directement de cet appareil au fournisseur choisi, jamais par nous, car il n\'y a aucun serveur à nous entre les deux. Rien n\'est envoyé tant que vous n\'autorisez pas une fonction ci-dessous.',
			'settings.ai.address' => 'Adresse',
			'settings.ai.model' => 'Modèle',
			'settings.ai.keyOptional' => 'Clé d\'API (facultative pour un serveur local)',
			'settings.ai.key' => 'Clé d\'API',
			'settings.ai.trying' => 'Essai...',
			'settings.ai.testAndSave' => 'Tester et enregistrer',
			'settings.ai.onNetwork' => 'Sur votre réseau',
			'settings.ai.keySaved' => 'Clé enregistrée',
			'settings.ai.remove' => 'Retirer le fournisseur',
			'settings.ai.maySend' => 'Ce qu\'il peut envoyer',
			'settings.ai.localNoConsent' => 'Ce fournisseur est sur votre propre réseau, rien ne parvient donc à un tiers et aucun consentement n\'est nécessaire.',
			'settings.ai.sendsTo' => ({required Object provider, required Object sends}) => 'Envoie à ${provider} : ${sends}',
			'settings.ai.allowedOn' => ({required Object date}) => 'Autorisé le ${date}',
			'settings.ai.notAllowed' => 'Pas encore autorisé. Vous serez sollicité la première fois.',
			'settings.ai.switchOff' => 'Désactiver',
			'settings.ai.allow' => 'Autoriser',
			'settings.appearance.palette.system' => 'Système',
			'settings.appearance.palette.midnight' => 'Minuit',
			'settings.appearance.palette.slate' => 'Ardoise',
			'settings.appearance.palette.daylight' => 'Jour',
			'settings.appearance.palette.amber' => 'Ambre',
			'settings.appearance.theme' => 'Thème',
			'settings.appearance.accent' => 'Couleur d\'accent',
			'settings.section.sources' => 'Sources',
			'settings.section.appearance' => 'Apparence',
			'settings.section.playback' => 'Lecture',
			'settings.section.subtitles' => 'Sous-titres',
			'settings.section.metadata' => 'Métadonnées',
			'settings.section.aiFeatures' => 'Fonctions d\'IA',
			'settings.section.advancedSources' => 'Sources avancées',
			'settings.section.transfer' => 'Transférer vers un autre appareil',
			'settings.section.privacy' => 'Confidentialité et données',
			'settings.section.about' => 'À propos',
			'settings.section.trackers' => 'Suivi des visionnages',
			'settings.section.requests' => 'Demandes',
			'settings.advanced.dialogTitle' => 'Activer les sources avancées',
			'settings.advanced.dialogLead' => 'Vous allez connecter un fournisseur tiers avec vos propres identifiants.',
			'settings.advanced.dialogNoContent' => 'Subnext Player ne fournit, n\'héberge ni ne cautionne aucun contenu ni aucun fournisseur. Vous indiquez l\'adresse et l\'identifiant, et l\'appli lit ce que renvoie cette adresse.',
			'settings.advanced.dialogRights' => 'Il vous appartient de détenir les droits sur ce à quoi vous vous connectez.',
			'settings.advanced.dialogConfirm' => 'Je comprends, activer',
			'settings.advanced.toggle' => 'Fournisseur ou playlist IPTV',
			'settings.advanced.toggleExplain' => 'Ajoute la TV en direct et les identifiants Xtream Codes.',
			'settings.advanced.offKeeps' => 'Le désactiver plus tard masque la TV en direct mais conserve les comptes ajoutés.',
			'settings.sources.noServers' => 'Aucun serveur Plex connecté.',
			'settings.sources.remove' => 'Retirer',
			'settings.sources.loadFailed' => ({required Object error}) => 'Impossible de charger les bibliothèques de ce serveur.\n\n${error}',
			'settings.sources.lookForMore' => 'Chercher d\'autres serveurs',
			'settings.sources.addAnother' => 'Ajouter un autre serveur',
			'settings.sources.yours' => 'À vous',
			'settings.sources.shared' => 'Partagé avec vous',
			'settings.sources.viaRelay' => 'via relais',
			'settings.sources.plexType' => ({required Object type}) => 'Type Plex : ${type}',
			'settings.sources.changedByYou' => 'modifié par vous',
			'settings.sources.localTab' => 'Afficher Local et réseau',
			'settings.sources.localTabSub' => 'Un onglet de l\'accueil pour les vidéos de cet appareil et des partages réseau. Il s\'active tout seul quand vous en ajoutez un.',
			'onboarding.tagline' => 'Lisez depuis les sources que vous connectez.',
			'onboarding.blurb' => 'Subnext Player lit depuis des sources que vous connectez vous-même : un serveur Plex, un NAS domestique ou des fichiers locaux, ou en option un fournisseur ou une playlist IPTV. Nous n\'hébergeons aucun contenu.',
			'onboarding.localDesktop' => 'Des fichiers sur ce PC, ou un dossier sur un NAS domestique ou un partage SMB.',
			'onboarding.localTv' => 'Un dossier sur un NAS domestique ou un partage SMB.',
			'onboarding.local' => 'Des vidéos sur cet appareil, ou un dossier sur un NAS domestique ou un partage SMB.',
			'onboarding.plexTv' => 'Connectez-vous avec votre propre compte sur cette TV.',
			'onboarding.plex' => 'Votre bibliothèque personnelle, avec votre propre compte.',
			'onboarding.advancedTv' => 'Désactivé par défaut. À activer dans Réglages.',
			'onboarding.advanced' => 'Désactivé par défaut. À activer dans Réglages pour utiliser un fournisseur ou une playlist IPTV.',
			'onboarding.localTitle' => 'Local et réseau',
			'onboarding.advancedTitle' => 'Sources avancées',
			'onboarding.addFirst' => 'Ajouter votre première source',
			'onboarding.notNow' => 'Pas maintenant',
			'onboarding.connect' => 'Connecter une source',
			'onboarding.addSource' => 'Ajouter une source',
			'onboarding.okKey' => 'OK',
			'onboarding.toSelect' => 'pour sélectionner',
			'addSource.privacy' => 'Les identifiants restent sur cet appareil. Rien ne nous est envoyé : il n\'y a ni compte ni serveur entre les deux.',
			'addSource.kind.plex' => 'Serveur Plex',
			'addSource.kind.plexShort' => 'Associer avec un code',
			'addSource.kind.plexLong' => 'Approuvez cet appareil dans votre navigateur. Votre propre serveur et tout ce qui est partagé avec vous.',
			'addSource.kind.localFiles' => 'Vidéos sur cet appareil',
			'addSource.kind.localFilesSub' => 'Parcourez votre médiathèque, ou choisissez un dossier précis auquel garder l\'accès.',
			'addSource.kind.localFilesIos' => 'Lisez les vidéos de votre photothèque.',
			'addSource.kind.smb' => 'Partage réseau (SMB)',
			'addSource.kind.smbSub' => 'Un NAS ou un partage Windows sur votre réseau domestique.',
			'addSource.kind.xtream' => 'Identifiant Xtream Codes',
			'addSource.kind.xtreamSub' => 'Serveur, nom d\'utilisateur et mot de passe de votre fournisseur.',
			'addSource.kind.mediaBrowser' => 'Serveur Jellyfin ou Emby',
			'addSource.kind.mediaBrowserSub' => 'Votre propre serveur, avec votre propre compte.',
			'addSource.copyFromDevice' => 'Copier depuis un autre appareil',
			'addSource.copyFromDeviceSub' => 'Déjà configuré sur votre téléphone ? Envoyez-le ici au lieu de tout retaper.',
			'addSource.title' => 'Ajouter une source',
			'addSource.advanced' => 'Sources avancées',
			'addSource.or' => 'Ou',
			'addSource.advancedHintLead' => 'Vous cherchez un fournisseur ou une playlist IPTV ? Activez ',
			'addSource.advancedHintTail' => ' dans Réglages.',
			'addSource.sourceType' => 'Type de source',
			'addSource.plexRail' => 'Associer avec un code',
			'addSource.pcFiles' => 'Fichiers sur ce PC',
			'addSource.pcFilesSub' => 'Choisir un dossier',
			'addSource.smbRail' => 'NAS ou partage Windows',
			'addSource.copyRail' => 'Envoyez-le depuis votre téléphone',
			'addSource.keystore' => 'Les identifiants sont stockés dans le trousseau de l\'appareil, jamais dans la base de données de l\'appli.',
			'addSource.pick' => 'Choisissez un type de source pour commencer.',
			'plex.connected' => 'Plex connecté.',
			'plex.connectedTo' => ({required Object name}) => 'Connecté à ${name}.',
			'plex.opening' => 'Connecté. Ouverture de votre bibliothèque…',
			'plex.connect' => 'Se connecter à Plex',
			'plex.explain' => 'Subnext Player lit ce que votre propre serveur Plex contient déjà. Rien n\'est envoyé en ligne, et vos informations de compte ne parviennent à personne d\'autre que Plex.',
			'plex.contacting' => 'Contact de Plex…',
			'plex.enterCode' => 'Sur n\'importe quel appareil, ouvrez plex.tv/link et saisissez :',
			'plex.waiting' => 'En attente d\'approbation…',
			'plex.copyCode' => 'Copier le code',
			'plex.chooseServer' => 'Choisir un serveur',
			'plex.allConnected' => 'Tous les serveurs de ce compte sont déjà connectés.',
			'plex.yourServers' => 'Vos serveurs',
			'plex.sharedWithYou' => 'Partagés avec vous',
			'plex.connecting' => 'Connexion… cela peut prendre quelques secondes',
			'plex.offline' => 'Hors ligne',
			'plex.relayOnly' => 'Plex Relay uniquement, la lecture peut être limitée',
			'plex.codeExpired' => 'Ce code a expiré. Réessayez.',
			'plex.noServers' => 'Ce compte n\'a aucun serveur Plex.',
			'plex.errors.noAnswer' => ({required Object server, required Object count}) => '« ${server} » n\'a répondu sur aucune de ses ${count} adresses annoncées.',
			'plex.errors.itemGone' => 'Cet élément n\'est plus sur le serveur.',
			'plex.errors.noFile' => 'Aucun fichier lisible pour cet élément. Les sources uniquement transcodées ne sont pas encore prises en charge.',
			'plex.errors.notConnected' => 'Non connecté à un serveur Plex.',
			'local.noAccess' => ({required Object where}) => 'Subnext Player ne peut pas voir vos vidéos sans accès aux médias. Vous pouvez l\'accorder dans ${where}.',
			'local.settingsIos' => 'l\'app Réglages',
			'local.settingsAndroid' => 'les paramètres Android',
			'local.intro' => 'Lisez les vidéos stockées sur cet appareil.\nSubnext Player ne demande que l\'accès aux vidéos, jamais à tous les fichiers.',
			'local.allowAccess' => 'Autoriser l\'accès aux vidéos',
			'local.pickFolderInstead' => 'Ou choisir un dossier',
			'local.addShare' => 'Ajouter un partage réseau',
			'local.shares' => 'Partages réseau',
			'local.pickedFolders' => 'Dossiers choisis',
			'local.onDevice' => 'Sur cet appareil',
			'local.noVideos' => 'Aucune vidéo trouvée sur cet appareil.',
			'local.addFolderShort' => 'Ajouter un dossier',
			'local.addShareShort' => 'Ajouter un partage',
			'local.scanDevice' => 'Analyser cet appareil',
			'local.forgetFolder' => 'Oublier ce dossier',
			'local.folder' => 'Dossier',
			'local.safUnreadable' => ({required Object error}) => 'Ce dossier n\'est plus lisible. Android a peut-être retiré l\'autorisation, alors retirez-le et choisissez-le à nouveau.\n\n${error}',
			'local.safEmpty' => 'Aucune vidéo ni sous-dossier ici.',
			'smb.connectFailed' => ({required Object error}) => 'Connexion impossible : ${error}',
			'smb.title' => 'Ajouter un partage réseau',
			'smb.explain' => 'Un NAS ou un dossier partagé sur un autre ordinateur de votre réseau.',
			'smb.host' => 'Adresse du serveur',
			'smb.hostHint' => 'p. ex. nas',
			'smb.username' => 'Nom d\'utilisateur',
			'smb.password' => 'Mot de passe',
			'smb.domain' => 'Domaine (facultatif)',
			'smb.name' => 'Nom (facultatif)',
			'smb.connectAndAdd' => 'Se connecter et ajouter',
			'smb.gone' => 'Ce partage n\'est plus configuré.',
			'smb.unreachable' => ({required Object error}) => 'Impossible de joindre ce partage. Le serveur est peut-être en veille ou hors du réseau.\n\n${error}',
			'smb.empty' => 'Aucune vidéo ni dossier ici.',
			'xtream.lineGone' => 'Cette ligne n\'est plus configurée.',
			'xtream.catalogue.live' => 'TV en direct',
			'xtream.catalogue.vod' => 'Films',
			'xtream.catalogue.series' => 'Séries',
			'xtream.errors.status' => ({required Object code}) => 'Le panel a renvoyé ${code}. Réessayez plus tard.',
			'xtream.errors.timeout' => 'Le panel n\'a pas répondu à temps.',
			'xtream.errors.unreachable' => 'Impossible de joindre cette adresse. Vérifiez l\'hôte et le port.',
			'xtream.errors.other' => ({required Object type}) => 'Impossible de communiquer avec le panel (${type}).',
			'xtream.errors.notXtream' => 'Cette adresse n\'a pas répondu comme un panel Xtream.',
			'xtream.errors.rejected' => 'Le panel a refusé ces identifiants.',
			'xtream.errors.wrongLogin' => 'Nom d\'utilisateur ou mot de passe incorrect.',
			'xtream.errors.unnamed' => 'Sans nom',
			'xtream.errors.episode' => 'Épisode',
			'xtream.errors.noPassword' => 'Cette ligne n\'a pas de mot de passe enregistré. Retirez-la et ajoutez-la à nouveau.',
			'xtream.everythingElse' => 'Tout le reste',
			'xtream.series.title' => 'Série',
			'xtream.series.noEpisodes' => 'Le panel n\'a renvoyé aucun épisode pour cette série.',
			'xtream.series.season' => ({required Object n}) => 'Saison ${n}',
			'xtream.remove' => 'Retirer',
			'xtream.add' => 'Ajouter une playlist ou un panel',
			'xtream.addLine.discardTitle' => 'Abandonner cette ligne ?',
			'xtream.addLine.discardBody' => 'Ce que vous avez saisi ici n\'a pas été enregistré.',
			'xtream.addLine.discard' => 'Abandonner',
			'xtream.addLine.keepEditing' => 'Continuer la saisie',
			'xtream.addLine.inactive' => ({required Object status}) => 'Le panel indique que cette ligne est « ${status} ».',
			'xtream.addLine.noContent' => 'Subnext Player ne fournit, n\'héberge ni ne cautionne aucun contenu ni aucun fournisseur. Vous indiquez l\'adresse et l\'identifiant, et l\'appli lit ce que renvoie cette adresse.',
			'xtream.addLine.host' => 'Adresse du serveur',
			'xtream.addLine.name' => 'Nom (facultatif)',
			'xtream.addLine.nameHint' => 'Le nom que vous voulez donner à cette ligne',
			'xtream.addLine.checking' => 'Vérification…',
			'xtream.addLine.verify' => 'Vérifier et ajouter',
			'xtream.addLine.connected' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: 'Connecté. ${n} flux simultané autorisé.', other: 'Connecté. ${n} flux simultanés autorisés.', ), 
			'xtream.picker.patternNone' => 'Ce motif ne correspond à rien.',
			'xtream.picker.title' => ({required Object catalogue}) => 'Catégories ${catalogue}',
			'xtream.picker.save' => 'Enregistrer',
			'xtream.picker.noMatch' => ({required Object query}) => 'Rien ne correspond à « ${query} ».',
			'xtream.picker.noneChosen' => 'Rien de choisi pour l\'instant.',
			'xtream.picker.search' => 'Rechercher dans toutes les catégories',
			'xtream.picker.chosen' => ({required Object n}) => 'Choisies ${n}',
			'xtream.picker.hideWords' => 'Masquer des mots',
			'xtream.picker.hideCount' => ({required Object n}) => 'Masqués ${n}',
			'xtream.picker.pattern' => 'Motif',
			'xtream.picker.untickedOne' => ({required Object name, required Object word}) => '« ${name} » a été décochée, car « ${word} » la masque. Enregistrez pour le conserver.',
			'xtream.picker.untickedMany' => ({required Object n, required Object word}) => '${n} catégories choisies que « ${word} » masque ont été décochées. Enregistrez pour le conserver.',
			'xtream.picker.showingHidden' => 'Affichage des catégories que vos mots masqués excluent.',
			'xtream.picker.hiddenCount' => ({required Object n}) => '${n} masquées par vos mots.',
			'xtream.picker.hideAgain' => 'Masquer à nouveau',
			'xtream.picker.showThem' => 'Les afficher',
			'xtream.picker.patternHint' => 'Cocher ou décocher toutes les catégories correspondant à un mot ou un motif',
			'xtream.picker.selectMatching' => 'Cocher les correspondances',
			'xtream.picker.deselectMatching' => 'Décocher les correspondances',
			'xtream.picker.groups' => 'Groupes',
			'xtream.picker.clearAll' => 'Tout décocher',
			'xtream.picker.selectAll' => 'Tout cocher',
			'xtream.picker.channelsPicked' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${n} chaîne', other: '${n} chaînes', ), 
			'xtream.picker.pickedChosen' => ({required Object n}) => '${n} choisies',
			'xtream.picker.categories' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${n} catégorie', other: '${n} catégories', ), 
			'xtream.picker.channels' => 'Chaînes',
			'xtream.channels.done' => 'Terminé',
			'xtream.channels.search' => 'Rechercher dans cette catégorie',
			'xtream.channels.pickedOf' => ({required Object picked, required Object total}) => '${picked} sur ${total}',
			'xtream.channels.whole' => 'Toute la catégorie',
			'xtream.channels.selectShown' => 'Cocher celles affichées',
			_ => null,
		} ?? switch (path) {
			'xtream.channels.clear' => 'Décocher',
			'xtream.channels.clearShown' => 'Décocher celles affichées',
			'xtream.channels.none' => 'Le panel ne liste aucune chaîne dans cette catégorie.',
			'xtream.hidden.title' => 'Masquer des mots',
			'xtream.hidden.explain' => 'Une catégorie ou une chaîne contenant l\'un de ces mots en entier est exclue des listes. « UK » masque « UK News » mais pas « Ukraine ». Ajoutez une expression comme « south indian » pour la masquer d\'un bloc. La casse n\'a pas d\'importance.',
			'xtream.hidden.hint' => 'Un pays, une langue, un mot',
			'xtream.hidden.add' => 'Ajouter',
			'xtream.hidden.none' => 'Rien n\'est masqué pour l\'instant.',
			'xtream.hidden.tapToRemove' => 'Sélectionnez un mot pour ne plus le masquer.',
			'transfer.noNetwork' => 'Cet appareil n\'est pas sur un réseau Wi-Fi ou Ethernet. Connectez-le au même réseau que l\'autre appareil et réessayez.',
			'transfer.cannotListen' => ({required Object error}) => 'Impossible de commencer l\'écoute : ${error}',
			'transfer.expired' => 'Ce code a expiré. Recommencez pour en obtenir un nouveau.',
			'transfer.wentWrong' => ({required Object error}) => 'Un problème est survenu : ${error}',
			'transfer.wentWrongPlain' => 'Un problème est survenu.',
			'transfer.gettingReady' => 'Préparation…',
			'transfer.waitingOther' => 'En attente de l\'autre appareil…',
			'transfer.copyCode' => 'Copier le code',
			'transfer.scanInstead' => 'Scanner son code',
			'transfer.typeInstead' => 'Saisir son code',
			'transfer.done' => 'Terminé',
			'transfer.close' => 'Fermer',
			'transfer.receive.cannotSave' => ({required Object error}) => 'Impossible d\'enregistrer les réglages : ${error}',
			'transfer.receive.title' => 'Recevoir des réglages',
			'transfer.receive.asking' => 'Interrogation de l\'autre appareil…',
			'transfer.receive.awaitingPush' => 'En attente de l\'envoi depuis l\'autre appareil. Acceptez là-bas quand il le demande.',
			'transfer.receive.saving' => 'Enregistrement…',
			'transfer.receive.waitingInstructions' => 'Sur l\'appareil qui a vos réglages, ouvrez Réglages, Transférer vers un autre appareil, et choisissez Envoyer. Puis scannez ce code.',
			'transfer.receive.scanInstructions' => 'Sur l\'appareil qui a vos réglages, ouvrez Réglages, Transférer vers un autre appareil, et choisissez Envoyer, puis Afficher un code. Pointez la caméra dessus.',
			'transfer.receive.showMine' => 'Afficher mon code',
			'transfer.receive.typeInstructions' => 'Sur l\'appareil qui a vos réglages, ouvrez Réglages, Transférer vers un autre appareil, et choisissez Envoyer, puis Afficher un code. Saisissez ensuite ce qu\'il affiche.',
			'transfer.receive.connect' => 'Connecter',
			'transfer.receive.review' => 'Un autre appareil veut vous envoyer ceci. Ce qui est déjà ici sous le même nom est remplacé ; rien d\'autre n\'est retiré.',
			'transfer.receive.saveThese' => 'Enregistrer',
			'transfer.receive.decline' => 'Refuser',
			'transfer.receive.saved' => 'Terminé. Vos réglages sont sur cet appareil.',
			'transfer.pairing.noCamera' => 'Pas de caméra ? Choisissez Saisir le code là-bas, et entrez :',
			'transfer.pairing.qrLabel' => 'Code à scanner depuis l\'autre appareil',
			'transfer.pairing.cameraOff' => 'La caméra est désactivée pour cette appli. Saisissez le code à la place, ou autorisez la caméra dans les réglages du téléphone.',
			'transfer.pairing.cameraFailed' => 'La caméra n\'a pas pu démarrer. Saisissez le code à la place.',
			'transfer.pairing.foreign' => 'Ce n\'est pas un code de cette appli.',
			'transfer.pairing.checkEntry' => 'Vérifiez l\'adresse (comme 192.168.1.20:41234) et le code à 16 caractères.',
			'transfer.pairing.address' => 'Adresse',
			'transfer.pairing.code' => 'Code',
			'transfer.pane.explain' => 'Copiez vos sources, clés et préférences vers un autre appareil du même réseau Wi-Fi, pour ne pas avoir à tout retaper. Cela va directement d\'un appareil à l\'autre, chiffré avec un code que seuls les deux écrans partagent, et l\'appareil qui reçoit demande avant d\'enregistrer quoi que ce soit.',
			'transfer.pane.notCopied' => 'Non copiés : Plex (associez-le sur l\'autre appareil avec son propre code), l\'historique, les favoris, et le consentement donné pour les Sources avancées et les Fonctions d\'IA, que chaque appareil demande lui-même.',
			'transfer.pane.receive' => 'Recevoir depuis un autre appareil',
			'transfer.pane.send' => 'Envoyer vers un autre appareil',
			'transfer.notes.aiLocal' => 'Votre fournisseur d\'IA tourne sur cet appareil, il n\'est donc pas envoyé. Configurez-le à nouveau là-bas avec l\'adresse de cet appareil sur votre réseau.',
			'transfer.notes.xtreamHidden' => 'Les comptes IPTV sont enregistrés mais masqués. Activez les Sources avancées dans Réglages pour les utiliser.',
			'transfer.notes.aiAsks' => 'Les fonctions d\'IA demanderont avant d\'envoyer quoi que ce soit au fournisseur.',
			'transfer.notes.partial' => ({required Object failed}) => 'Impossible d\'enregistrer : ${failed}. Le reste a été enregistré.',
			'transfer.send.cannotRead' => ({required Object error}) => 'Impossible de lire les réglages de cet appareil : ${error}',
			'transfer.send.askTitle' => ({required Object host}) => 'Envoyer à ${host} ?',
			'transfer.send.askBody' => ({required Object summary}) => 'Un appareil de votre réseau a scanné ce code et demande :\n\n${summary}\n\nN\'acceptez que si vous venez de le demander sur cet appareil.',
			'transfer.send.notNow' => 'Pas maintenant',
			'transfer.send.send' => 'Envoyer',
			'transfer.send.title' => 'Envoyer des réglages',
			'transfer.send.reading' => 'Lecture de vos réglages…',
			'transfer.send.sending' => 'Envoi en cours. L\'autre appareil demandera avant d\'enregistrer quoi que ce soit.',
			'transfer.send.explain' => 'Copie ceci vers un autre appareil du même réseau Wi-Fi, pour ne pas avoir à tout retaper. Cela va directement là-bas, chiffré ; rien ne passe par nous.',
			'transfer.send.nothing' => 'Rien n\'est encore configuré sur cet appareil à envoyer.',
			'transfer.send.proceed' => 'Continuer',
			'transfer.send.showInstead' => 'Afficher un code',
			'transfer.send.typeInstead' => 'Saisir le code',
			'transfer.send.scanInstructions' => 'Sur l\'autre appareil, ouvrez Réglages, Transférer vers un autre appareil, et choisissez Recevoir. Pointez la caméra sur le code qu\'il affiche.',
			'transfer.send.showInstructions' => 'Sur l\'autre appareil, ouvrez Réglages, Transférer vers un autre appareil, et choisissez Recevoir, puis Scanner son code, et pointez sa caméra ici. Vous serez sollicité avant tout envoi.',
			'transfer.send.typeInstructions' => 'Sur l\'autre appareil, ouvrez Réglages, Transférer vers un autre appareil, et choisissez Recevoir. Saisissez ensuite ce qu\'il affiche.',
			'transfer.send.sent' => 'Envoyé. L\'autre appareil a enregistré vos réglages.',
			'transfer.item.preferences' => 'Préférences',
			'transfer.item.preferencesSub' => 'Choix de lecture et de sous-titres, mots masqués et emplacement dans la bibliothèque.',
			'transfer.item.xtream' => 'Comptes IPTV',
			'transfer.item.xtreamSub' => 'Identifiants, et les catégories et chaînes choisies.',
			'transfer.item.smb' => 'Partages réseau',
			'transfer.item.smbSub' => 'Partages SMB et leurs mots de passe.',
			'transfer.item.tmdb' => 'Clé TMDB',
			'transfer.item.tmdbSub' => 'Votre propre clé pour les filtres de genre, de note et de langue.',
			'transfer.item.ai' => 'Fournisseur d\'IA',
			'transfer.item.aiSub' => 'Le fournisseur, son modèle et votre clé.',
			'transfer.item.settings' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${n} réglage', other: '${n} réglages', ), 
			'transfer.item.accounts' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${n} compte', other: '${n} comptes', ), 
			'transfer.item.shares' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${n} partage', other: '${n} partages', ), 
			'transfer.item.notBundle' => 'Ce n\'était pas un paquet de réglages.',
			'transfer.item.newer' => 'Ce paquet vient d\'une version plus récente de l\'appli. Mettez à jour cet appareil et réessayez.',
			'transfer.item.trackers' => 'Suivi des visionnages',
			'transfer.item.trackersSub' => 'Vos connexions Trakt, Simkl, AniList et MyAnimeList. Les accepter ici, c\'est accepter d\'envoyer aussi ce que vous regardez sur cet appareil.',
			'transfer.item.services' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${n} service', other: '${n} services', ), 
			'transfer.client.declined' => 'L\'autre appareil n\'a pas accepté les réglages.',
			'transfer.client.wrongCode' => 'Le code n\'était pas bon. Comparez-le avec l\'autre écran.',
			'transfer.client.used' => 'L\'autre appareil a déjà reçu quelque chose. Rouvrez Recevoir là-bas pour un nouveau code.',
			'transfer.client.tooBig' => 'C\'était trop volumineux à envoyer.',
			'transfer.client.unreadable' => 'L\'autre appareil n\'a pas pu le lire.',
			'transfer.client.unexpected' => ({required Object status}) => 'L\'autre appareil a répondu de façon inattendue (${status}).',
			'transfer.client.refusedToSend' => 'L\'autre appareil n\'a pas accepté d\'envoyer ses réglages.',
			'transfer.client.busy' => 'L\'autre appareil répond déjà à quelqu\'un d\'autre. Demandez-lui un nouveau code.',
			'transfer.client.unreachable' => ({required Object address}) => 'Impossible de joindre ${address}. Les deux appareils doivent être sur le même Wi-Fi, et l\'autre doit encore afficher son code.',
			'transfer.client.dropped' => 'La connexion a été coupée en cours de route.',
			'transfer.client.noAnswer' => ({required Object address}) => 'Pas de réponse de ${address}. Vérifiez l\'autre écran.',
			'mediaBrowser.errors.signedOut' => ({required Object server}) => '${server} n\'accepte plus cette connexion. Retirez-le dans Réglages, Sources et ajoutez-le à nouveau.',
			'mediaBrowser.errors.status' => ({required Object server, required Object code}) => '${server} a répondu ${code}.',
			'mediaBrowser.errors.unreachable' => ({required Object server}) => 'Impossible de joindre ${server}. Il est peut-être en veille ou hors du réseau.',
			'mediaBrowser.errors.notAServer' => 'Aucun serveur Jellyfin ou Emby n\'a répondu à cette adresse. Vérifiez-la, port compris (souvent 8096).',
			'mediaBrowser.errors.badAnswer' => 'Le serveur a répondu d\'une façon que cette appli ne comprend pas.',
			'mediaBrowser.errors.wrongLogin' => 'Nom d\'utilisateur ou mot de passe incorrect.',
			'mediaBrowser.title' => 'Se connecter à Jellyfin ou Emby',
			'mediaBrowser.explain' => 'Subnext Player lit ce que votre propre serveur contient déjà. Votre connexion reste sur cet appareil et ne parvient qu\'à votre serveur.',
			'mediaBrowser.address' => 'Adresse du serveur',
			'mediaBrowser.addressHint' => 'p. ex. 192.168.1.20:8096',
			'mediaBrowser.find' => 'Trouver le serveur',
			'mediaBrowser.finding' => 'Recherche du serveur…',
			'mediaBrowser.found' => ({required Object name, required Object kind, required Object version}) => '${name} · ${kind} ${version}',
			'mediaBrowser.username' => 'Nom d\'utilisateur',
			'mediaBrowser.password' => 'Mot de passe',
			'mediaBrowser.signIn' => 'Se connecter',
			'mediaBrowser.signingIn' => 'Connexion…',
			'mediaBrowser.useQuickConnect' => 'Utiliser Quick Connect',
			'mediaBrowser.usePassword' => 'Utiliser le nom d\'utilisateur et le mot de passe',
			'mediaBrowser.quickConnectExplain' => 'Sur un téléphone ou un ordinateur déjà connecté à Jellyfin, ouvrez votre profil, Quick Connect, et saisissez :',
			'mediaBrowser.waiting' => 'En attente d\'approbation…',
			'mediaBrowser.otherAddress' => 'Utiliser une autre adresse',
			'mediaBrowser.connected' => ({required Object name}) => 'Connecté à ${name}.',
			'trackers.errors.unavailable' => ({required Object service}) => 'Impossible de joindre ${service}. Nouvel essai plus tard.',
			'trackers.errors.denied' => 'La connexion a été refusée.',
			'trackers.errors.expired' => 'Ce code a expiré. Recommencez pour en obtenir un nouveau.',
			'trackers.errors.badPaste' => 'Ce n\'est pas ce qu\'a donné la page de connexion. Copiez-le à nouveau et collez-le en entier.',
			'trackers.malCaught' => 'Connecté. Vous pouvez fermer cette fenêtre et revenir à Subnext Player.',
			'trackers.intro' => 'Envoyez ce que vous finissez de regarder sur vos propres serveurs à un service d\'historique. Rien ne vient de l\'IPTV, et rien ne nous parvient.',
			'trackers.animeNote' => 'AniList et MyAnimeList ne reçoivent que les titres que votre serveur marque comme anime, retrouvés par leur nom.',
			'trackers.signedInAs' => ({required Object name}) => 'Connecté en tant que ${name}',
			'trackers.signedIn' => 'Connecté',
			'trackers.notConnected' => 'Non connecté',
			'trackers.signIn' => 'Se connecter',
			'trackers.signOut' => 'Se déconnecter',
			'trackers.pending' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '1 visionnage attend d\'être envoyé.', other: '${n} visionnages attendent d\'être envoyés.', ), 
			'trackers.consentTitle' => ({required Object service}) => 'Envoyer vos visionnages à ${service} ?',
			'trackers.consentBody' => ({required Object service}) => 'Quand vous finissez un film ou un épisode de votre propre serveur Plex, Jellyfin ou Emby, Subnext Player envoie à ${service} son titre, son année, son identifiant IMDb, TMDB ou TVDB, et le moment où vous l\'avez regardé. Cela va directement de cet appareil à ${service}, jamais par nous. Rien ne vient de l\'IPTV. Vous pouvez vous déconnecter à tout moment dans Réglages, Suivi des visionnages.',
			'trackers.consentAnime' => ({required Object service}) => 'Pour ${service}, seuls les titres que votre serveur marque comme anime sont envoyés, et ils sont retrouvés en cherchant leur nom sur ${service}.',
			'trackers.agree' => 'Continuer',
			'trackers.notNow' => 'Pas maintenant',
			'trackers.signInTitle' => ({required Object service}) => 'Se connecter à ${service}',
			'trackers.deviceCodeExplain' => ({required Object url}) => 'Sur n\'importe quel appareil, ouvrez ${url} et saisissez :',
			'trackers.waiting' => 'En attente d\'approbation…',
			'trackers.browserExplain' => ({required Object service}) => 'Ouvrez cette adresse dans un navigateur, connectez-vous à ${service} et autorisez Subnext Player. Collez ensuite ci-dessous ce que ${service} vous donne.',
			'trackers.anilistPaste' => 'AniList affiche un long jeton après l\'autorisation. Copiez-le en entier.',
			'trackers.malPaste' => 'Sur cet appareil, l\'appli termine seule. Si le navigateur était ailleurs, il finit sur une page qui ne se charge pas : copiez l\'adresse complète de cette page.',
			'trackers.tvHint' => 'Sur une TV, connectez-vous sur votre téléphone et utilisez Transférer vers un autre appareil pour le ramener ici.',
			'trackers.pasteLabel' => 'Collez ici',
			'trackers.finish' => 'Terminer la connexion',
			'trackers.copyAddress' => 'Copier l\'adresse',
			'trackers.connected' => ({required Object service}) => 'Connecté à ${service}.',
			'seerr.errors.notASeerr' => 'Aucun serveur Overseerr, Jellyseerr ou Seerr n\'a répondu à cette adresse. Vérifiez-la, port compris (souvent 5055).',
			'seerr.errors.badKey' => 'Le serveur n\'a pas accepté cette clé d\'API.',
			'seerr.errors.refused' => 'Le serveur n\'a pas accepté cette connexion.',
			'seerr.errors.status' => ({required Object code}) => 'Le serveur a répondu ${code}.',
			'seerr.errors.unreachable' => 'Impossible de joindre le serveur de demandes.',
			'seerr.errors.signedOut' => 'Le serveur de demandes n\'accepte plus cette connexion. Reconnectez-le dans Réglages, Demandes.',
			'seerr.errors.alreadyRequested' => 'Cela a déjà été demandé.',
			'seerr.intro' => 'Connectez votre propre serveur Overseerr, Jellyseerr ou Seerr pour demander des films et séries que votre bibliothèque n\'a pas encore. Les demandes vont à votre serveur et nulle part ailleurs ; son administrateur décide de la suite.',
			'seerr.address' => 'Adresse du serveur',
			'seerr.addressHint' => 'p. ex. 192.168.1.20:5055',
			'seerr.find' => 'Trouver le serveur',
			'seerr.withPlex' => 'Se connecter avec mon compte Plex',
			'seerr.withPassword' => 'Se connecter avec nom d\'utilisateur et mot de passe',
			'seerr.withKey' => 'Utiliser une clé d\'API',
			'seerr.username' => 'Nom d\'utilisateur ou e-mail',
			'seerr.password' => 'Mot de passe',
			'seerr.apiKey' => 'Clé d\'API',
			'seerr.keyNote' => 'Une clé d\'API agit comme l\'administrateur du serveur, donc les demandes faites avec elle ne sont pas à votre nom. Préférez vous connecter.',
			'seerr.connect' => 'Se connecter',
			'seerr.connecting' => 'Connexion…',
			'seerr.connected' => ({required Object title, required Object name}) => 'Connecté à ${title} en tant que ${name}',
			'seerr.disconnect' => 'Déconnecter',
			'seerr.myRequests' => 'Vos demandes récentes',
			'seerr.none' => 'Aucune demande pour le moment.',
			'seerr.statusPending' => 'En attente d\'approbation',
			'seerr.statusApproved' => 'Approuvée',
			'seerr.statusDeclined' => 'Refusée',
			'seerr.statusAvailable' => 'Disponible',
			'seerr.rowTitle' => ({required Object title}) => 'Demander à ${title}',
			'seerr.requested' => 'Demandé',
			'seerr.partial' => 'En partie disponible',
			'seerr.askTitle' => ({required Object title}) => 'Demander ${title} ?',
			'seerr.askMovie' => ({required Object server}) => 'Cela demande à ${server} d\'ajouter le film. Son administrateur décide s\'il le fait.',
			'seerr.askShow' => ({required Object server}) => 'Cela demande à ${server} d\'ajouter toutes les saisons. Son administrateur décide s\'il le fait.',
			'seerr.request' => 'Demander',
			'seerr.sent' => ({required Object title}) => '${title} demandé.',
			'film.play' => 'Lire',
			'film.resume' => ({required Object time}) => 'Reprendre à ${time}',
			'film.fromStart' => 'Lire depuis le début',
			'film.gone' => 'Ce film n\'est plus sur le serveur, ou le serveur est injoignable.',
			'errors.addressHidden' => '(adresse masquée)',
			_ => null,
		};
	}
}
