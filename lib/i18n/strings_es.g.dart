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
class TranslationsEs extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEs({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.es,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <es>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsEs _root = this; // ignore: unused_field

	@override 
	TranslationsEs $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEs(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$common$es common = _Translations$common$es._(_root);
	@override late final _Translations$player$es player = _Translations$player$es._(_root);
	@override Map<String, String> get languages => {
		'en': 'Inglés',
		'es': 'Español',
		'fr': 'Francés',
		'de': 'Alemán',
		'it': 'Italiano',
		'pt': 'Portugués',
		'nl': 'Neerlandés',
		'sv': 'Sueco',
		'no': 'Noruego',
		'da': 'Danés',
		'fi': 'Finés',
		'pl': 'Polaco',
		'cs': 'Checo',
		'hu': 'Húngaro',
		'ro': 'Rumano',
		'el': 'Griego',
		'ru': 'Ruso',
		'uk': 'Ucraniano',
		'tr': 'Turco',
		'ar': 'Árabe',
		'he': 'Hebreo',
		'hi': 'Hindi',
		'bn': 'Bengalí',
		'pa': 'Panyabí',
		'ta': 'Tamil',
		'te': 'Telugu',
		'ur': 'Urdu',
		'th': 'Tailandés',
		'vi': 'Vietnamita',
		'id': 'Indonesio',
		'zh': 'Chino',
		'ja': 'Japonés',
		'ko': 'Coreano',
	};
	@override late final _Translations$subtitleSize$es subtitleSize = _Translations$subtitleSize$es._(_root);
	@override late final _Translations$units$es units = _Translations$units$es._(_root);
	@override late final _Translations$downloads$es downloads = _Translations$downloads$es._(_root);
	@override late final _Translations$watchActions$es watchActions = _Translations$watchActions$es._(_root);
	@override late final _Translations$show$es show = _Translations$show$es._(_root);
	@override late final _Translations$shell$es shell = _Translations$shell$es._(_root);
	@override late final _Translations$resume$es resume = _Translations$resume$es._(_root);
	@override late final _Translations$library$es library = _Translations$library$es._(_root);
	@override late final _Translations$liveTv$es liveTv = _Translations$liveTv$es._(_root);
	@override late final _Translations$ai$es ai = _Translations$ai$es._(_root);
	@override late final _Translations$search$es search = _Translations$search$es._(_root);
	@override late final _Translations$settings$es settings = _Translations$settings$es._(_root);
	@override late final _Translations$onboarding$es onboarding = _Translations$onboarding$es._(_root);
	@override late final _Translations$addSource$es addSource = _Translations$addSource$es._(_root);
	@override late final _Translations$plex$es plex = _Translations$plex$es._(_root);
	@override late final _Translations$local$es local = _Translations$local$es._(_root);
	@override late final _Translations$smb$es smb = _Translations$smb$es._(_root);
	@override late final _Translations$xtream$es xtream = _Translations$xtream$es._(_root);
	@override late final _Translations$transfer$es transfer = _Translations$transfer$es._(_root);
	@override late final _Translations$mediaBrowser$es mediaBrowser = _Translations$mediaBrowser$es._(_root);
	@override late final _Translations$trackers$es trackers = _Translations$trackers$es._(_root);
	@override late final _Translations$seerr$es seerr = _Translations$seerr$es._(_root);
	@override late final _Translations$film$es film = _Translations$film$es._(_root);
	@override late final _Translations$errors$es errors = _Translations$errors$es._(_root);
}

// Path: common
class _Translations$common$es extends Translations$common$en {
	_Translations$common$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get back => 'Atrás';
	@override String get tryAgain => 'Reintentar';
	@override String get cancel => 'Cancelar';
	@override String get noDrm => 'Sin DRM. No se pueden reproducir catálogos comerciales protegidos como Netflix o Disney+.';
}

// Path: player
class _Translations$player$es extends Translations$player$en {
	_Translations$player$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get shareGone => 'Esa carpeta compartida ya no está configurada.';
	@override String get shareFileGone => 'Ese archivo ya no está en la carpeta compartida.';
	@override String get deviceFileGone => 'Ese archivo ya no está en este dispositivo.';
	@override String get lineGone => 'Esa suscripción ya no está configurada.';
	@override String get untitledVideo => 'Vídeo';
	@override String get untitledEpisode => 'Episodio';
	@override String get untitledFilm => 'Película';
	@override String get untitledLive => 'En directo';
	@override String get channelFroze => 'Este canal se detuvo y no ha vuelto.';
	@override String get channelNotResponding => 'Este canal no responde. Los proveedores suelen listar canales que no están emitiendo, así que prueba otro o vuelve a probar el mismo.';
	@override String get didNotStart => 'No ha empezado a reproducirse. Puede que el servidor esté ocupado o que el archivo necesite transcodificación, que aún no está disponible.';
	@override String get released => 'Se detuvo mientras la app estaba en segundo plano, así que la conexión queda libre para otros dispositivos.';
	@override String get rejoin => 'Volver a entrar';
	@override String get live => 'EN DIRECTO';
	@override String skipBack({required Object seconds}) => 'Atrás ${seconds} segundos';
	@override String skipForward({required Object seconds}) => 'Adelante ${seconds} segundos';
	@override String get pause => 'Pausa';
	@override String get play => 'Reproducir';
	@override String get tracks => 'Audio y subtítulos';
	@override String get audio => 'Audio';
	@override String get subtitles => 'Subtítulos';
	@override String get off => 'Desactivados';
	@override String trackNumber({required Object n}) => 'Pista ${n}';
	@override late final _Translations$player$upNext$es upNext = _Translations$player$upNext$es._(_root);
}

// Path: subtitleSize
class _Translations$subtitleSize$es extends Translations$subtitleSize$en {
	_Translations$subtitleSize$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get small => 'Pequeño';
	@override String get medium => 'Mediano';
	@override String get large => 'Grande';
}

// Path: units
class _Translations$units$es extends Translations$units$en {
	_Translations$units$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String minutes({required Object m}) => '${m} min';
	@override String hours({required Object h}) => '${h} h';
	@override String hoursMinutes({required Object h, required Object m}) => '${h} h ${m} min';
	@override String minutesLeft({required Object m}) => 'Quedan ${m} min';
	@override String seconds({required Object s}) => '${s} s';
}

// Path: downloads
class _Translations$downloads$es extends Translations$downloads$en {
	_Translations$downloads$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get empty => 'Aún no hay descargas. Mantén pulsada una película o un episodio de tu biblioteca de Plex y elige Descargar; luego míralo aquí sin conexión.';
	@override String get title => 'Descargas';
	@override String summary({required num n, required Object size}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${n} elemento · ${size} en este dispositivo',
		other: '${n} elementos · ${size} en este dispositivo',
	);
	@override String pendingWatches({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '1 visionado de aquí está pendiente de enviarse a Plex.',
		other: '${n} visionados de aquí están pendientes de enviarse a Plex.',
	);
	@override String get foregroundOnly => 'Las descargas continúan mientras la app está abierta. Al cerrarla se pausan, y no se pierde nada de lo ya guardado.';
	@override String downloadingBytes({required Object received}) => 'Descargando, ${received}';
	@override String downloadingPercent({required Object percent, required Object received, required Object total}) => 'Descargando ${percent} % · ${received} de ${total}';
	@override String get queued => 'Esperando su turno';
	@override String get paused => 'En pausa';
	@override String pausedAt({required Object percent}) => 'En pausa al ${percent} % · selecciona para reanudar';
	@override String failed({required Object error}) => '${error} Selecciona para reintentar.';
	@override String get failedUnknown => 'No terminó.';
	@override String get deleteTitle => '¿Eliminar esta descarga?';
	@override String get cancelTitle => '¿Cancelar esta descarga?';
	@override String removeBody({required Object title}) => 'Se eliminará «${title}» de este dispositivo. Seguirá en tu servidor Plex.';
	@override String removeBodyFreeing({required Object title, required Object size}) => 'Se eliminará «${title}» de este dispositivo y se liberarán ${size}. Seguirá en tu servidor Plex.';
	@override String get keepIt => 'Conservarla';
	@override String get delete => 'Eliminar';
	@override late final _Translations$downloads$errors$es errors = _Translations$downloads$errors$es._(_root);
	@override late final _Translations$downloads$rule$es rule = _Translations$downloads$rule$es._(_root);
}

// Path: watchActions
class _Translations$watchActions$es extends Translations$watchActions$en {
	_Translations$watchActions$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get everyEpisode => ' (todos los episodios)';
	@override String markWatched({required Object scope}) => 'Marcar como visto${scope}';
	@override String markUnwatched({required Object scope}) => 'Marcar como no visto${scope}';
	@override String get download => 'Descargar en este dispositivo';
	@override String get deleteDownload => 'Eliminar descarga';
	@override String get cancelDownload => 'Cancelar descarga';
	@override String get removeFavourite => 'Quitar de favoritos';
	@override String get addFavourite => 'Añadir a favoritos';
	@override String get removeResume => 'Quitar de Seguir viendo';
	@override String get downloading => 'Descargando. Consulta la pestaña Descargas.';
	@override String get markedOffline => 'Marcado como visto aquí. Se avisará a Plex cuando se pueda contactar con él.';
	@override String get plexRefused => 'Plex no lo aceptó. Puede que el servidor esté desconectado.';
	@override String get details => 'Detalles';
}

// Path: show
class _Translations$show$es extends Translations$show$en {
	_Translations$show$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get noEpisodes => 'Esta serie no tiene episodios en el servidor.';
}

// Path: shell
class _Translations$shell$es extends Translations$shell$en {
	_Translations$shell$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get library => 'Biblioteca';
	@override String get search => 'Buscar';
	@override String get downloads => 'Descargas';
	@override String get settings => 'Ajustes';
	@override String get exitTitle => '¿Salir de Subnext Player?';
	@override String get exit => 'Salir';
	@override String get stay => 'Quedarse';
}

// Path: resume
class _Translations$resume$es extends Translations$resume$en {
	_Translations$resume$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get upNext => 'A continuación';
	@override String get title => 'Seguir viendo';
	@override String get remove => 'Quitar de Seguir viendo';
}

// Path: library
class _Translations$library$es extends Translations$library$en {
	_Translations$library$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$library$placement$es placement = _Translations$library$placement$es._(_root);
	@override late final _Translations$library$tab$es tab = _Translations$library$tab$es._(_root);
	@override String serverTimeout({required Object server, required Object seconds}) => '${server} no respondió en ${seconds} segundos. Puede que esté en reposo o fuera de la red.';
	@override String get allWatched => 'Ya has visto todo lo de Películas.';
	@override String get showAll => 'Mostrar todo';
	@override String get noSources => 'Aún no hay fuentes conectadas.';
	@override String nothingIn({required Object tab}) => 'Aún no hay nada en ${tab}.';
	@override String get addSource => 'Añadir una fuente';
	@override String sortFiltered({required Object sort}) => '${sort} · Sin ver';
	@override String get sortBy => 'Ordenar por';
	@override String get unwatchedOnly => 'Solo sin ver';
	@override late final _Translations$library$shelf$es shelf = _Translations$library$shelf$es._(_root);
	@override late final _Translations$library$sort$es sort = _Translations$library$sort$es._(_root);
	@override late final _Translations$library$tile$es tile = _Translations$library$tile$es._(_root);
}

// Path: liveTv
class _Translations$liveTv$es extends Translations$liveTv$en {
	_Translations$liveTv$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$liveTv$group$es group = _Translations$liveTv$group$es._(_root);
	@override String get noPanel => 'Aún no hay ninguna suscripción de IPTV.';
	@override String get addOne => 'Añadir uno';
	@override String get noCategories => 'Aún no has elegido canales.\nTu proveedor tiene decenas de miles, así que Subnext Player solo carga los que eliges.';
	@override String get chooseCategories => 'Elegir categorías';
	@override String get noChannels => 'Esas categorías no devolvieron canales.';
	@override String get refresh => 'Actualizar canales';
	@override String get refreshFailed => 'No se pudo actualizar la lista de canales. Se muestra la anterior.';
	@override String noMatch({required Object query}) => 'Ningún canal coincide con «${query}».';
	@override String searchHint({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: 'Buscar en ${n} canal',
		other: 'Buscar en ${n} canales',
	);
	@override String get all => 'Todos';
}

// Path: ai
class _Translations$ai$es extends Translations$ai$en {
	_Translations$ai$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$ai$picks$es picks = _Translations$ai$picks$es._(_root);
	@override late final _Translations$ai$search$es search = _Translations$ai$search$es._(_root);
	@override String get presetOther => 'Otro';
	@override String get hintOpenRouter => 'Los identificadores de modelo están en openrouter.ai/models. Los gratuitos terminan en ":free".';
	@override String get hintOllama => 'Usa la dirección de tu ordenador en esta red, por ejemplo http://192.168.1.20:11434/v1. Nada sale de tu red.';
	@override String get hintCustom => 'Cualquier servicio que use el formato de chat de OpenAI.';
	@override late final _Translations$ai$feature$es feature = _Translations$ai$feature$es._(_root);
	@override late final _Translations$ai$errors$es errors = _Translations$ai$errors$es._(_root);
	@override String consentTitle({required Object provider}) => '¿Enviar datos a ${provider}?';
	@override String consentBody({required Object feature, required Object provider, required Object sends}) => '${feature} enviará esto a ${provider}: ${sends}';
	@override String get consentTail => 'Va directamente de este dispositivo a ellos, nunca a través de nosotros. Puedes volver a desactivarlo en Ajustes, Funciones de IA.';
	@override String get notNow => 'Ahora no';
	@override String get allow => 'Permitir';
}

// Path: search
class _Translations$search$es extends Translations$search$en {
	_Translations$search$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$search$filters$es filters = _Translations$search$filters$es._(_root);
	@override String get hint => 'Busca en tus fuentes';
	@override String get prompt => 'Busca películas y series en tu servidor.';
	@override String get keepTyping => 'Sigue escribiendo…';
	@override String noMatch({required Object query}) => 'Nada coincide con «${query}».';
	@override String get backToResults => 'Volver a los resultados';
	@override String get askAi => 'Preguntar a la IA';
	@override String get becauseYouWatched => 'Porque viste ';
}

// Path: settings
class _Translations$settings$es extends Translations$settings$en {
	_Translations$settings$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$settings$about$es about = _Translations$settings$about$es._(_root);
	@override late final _Translations$settings$privacy$es privacy = _Translations$settings$privacy$es._(_root);
	@override late final _Translations$settings$playback$es playback = _Translations$settings$playback$es._(_root);
	@override late final _Translations$settings$metadata$es metadata = _Translations$settings$metadata$es._(_root);
	@override late final _Translations$settings$ai$es ai = _Translations$settings$ai$es._(_root);
	@override late final _Translations$settings$appearance$es appearance = _Translations$settings$appearance$es._(_root);
	@override late final _Translations$settings$section$es section = _Translations$settings$section$es._(_root);
	@override late final _Translations$settings$advanced$es advanced = _Translations$settings$advanced$es._(_root);
	@override late final _Translations$settings$sources$es sources = _Translations$settings$sources$es._(_root);
}

// Path: onboarding
class _Translations$onboarding$es extends Translations$onboarding$en {
	_Translations$onboarding$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get tagline => 'Reproduce desde las fuentes que conectas.';
	@override String get blurb => 'Subnext Player reproduce desde fuentes que conectas tú: un servidor Plex, un NAS doméstico o archivos locales, u opcionalmente un proveedor o una lista de IPTV. No alojamos ningún contenido.';
	@override String get localDesktop => 'Archivos de este PC, o una carpeta de un NAS doméstico o un recurso SMB.';
	@override String get localTv => 'Una carpeta de un NAS doméstico o un recurso SMB.';
	@override String get local => 'Vídeos de este dispositivo, o una carpeta de un NAS doméstico o un recurso SMB.';
	@override String get plexTv => 'Inicia sesión con tu propia cuenta en esta TV.';
	@override String get plex => 'Tu biblioteca personal, con tu propia cuenta.';
	@override String get advancedTv => 'Desactivado por defecto. Actívalo en Ajustes.';
	@override String get advanced => 'Desactivado por defecto. Actívalo desde Añadir fuente o Ajustes para usar una suscripción de IPTV.';
	@override String get localTitle => 'Local y red';
	@override String get advancedTitle => 'Fuentes avanzadas';
	@override String get addFirst => 'Añade tu primera fuente';
	@override String get notNow => 'Ahora no';
	@override String get connect => 'Conecta una fuente';
	@override String get addSource => 'Añadir fuente';
	@override String get okKey => 'OK';
	@override String get toSelect => 'para seleccionar';
}

// Path: addSource
class _Translations$addSource$es extends Translations$addSource$en {
	_Translations$addSource$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get privacy => 'Las credenciales se quedan en este dispositivo. No se nos envía nada: no hay cuenta ni ningún servidor en medio.';
	@override late final _Translations$addSource$kind$es kind = _Translations$addSource$kind$es._(_root);
	@override String get copyFromDevice => 'Copiar de otro dispositivo';
	@override String get copyFromDeviceSub => '¿Ya lo tienes configurado en el móvil? Envíalo aquí en vez de volver a escribirlo.';
	@override String get title => 'Añadir una fuente';
	@override String get advanced => 'Fuentes avanzadas';
	@override String get or => 'O';
	@override String get advancedHint => '¿Tienes una suscripción de IPTV?';
	@override String get advancedSetUp => 'Configurar TV en directo';
	@override String get sourceType => 'Tipo de fuente';
	@override String get plexRail => 'Vincular con un código';
	@override String get pcFiles => 'Archivos de este PC';
	@override String get pcFilesSub => 'Elige una carpeta';
	@override String get smbRail => 'NAS o carpeta compartida de Windows';
	@override String get copyRail => 'Envíalo desde tu móvil';
	@override String get keystore => 'Las credenciales se guardan en el almacén de claves del dispositivo, nunca en la base de datos de la app.';
	@override String get pick => 'Elige un tipo de fuente para empezar.';
}

// Path: plex
class _Translations$plex$es extends Translations$plex$en {
	_Translations$plex$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get connected => 'Plex conectado.';
	@override String connectedTo({required Object name}) => 'Conectado a ${name}.';
	@override String get opening => 'Conectado. Abriendo tu biblioteca…';
	@override String get connect => 'Conectar con Plex';
	@override String get explain => 'Subnext Player reproduce lo que ya tiene tu propio servidor Plex. No se sube nada, y los datos de tu cuenta no llegan a nadie más que a Plex.';
	@override String get contacting => 'Contactando con Plex…';
	@override String get enterCode => 'En cualquier dispositivo, abre plex.tv/link e introduce:';
	@override String get waiting => 'Esperando la aprobación…';
	@override String get copyCode => 'Copiar código';
	@override String get chooseServer => 'Elige un servidor';
	@override String get allConnected => 'Todos los servidores de esta cuenta ya están conectados.';
	@override String get yourServers => 'Tus servidores';
	@override String get sharedWithYou => 'Compartidos contigo';
	@override String get connecting => 'Conectando… puede tardar unos segundos';
	@override String get offline => 'Sin conexión';
	@override String get relayOnly => 'Solo mediante Plex Relay, la reproducción puede verse limitada';
	@override String get codeExpired => 'Ese código ha caducado. Inténtalo de nuevo.';
	@override String get noServers => 'Esa cuenta no tiene servidores Plex.';
	@override late final _Translations$plex$errors$es errors = _Translations$plex$errors$es._(_root);
}

// Path: local
class _Translations$local$es extends Translations$local$en {
	_Translations$local$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String noAccess({required Object where}) => 'Subnext Player no puede ver tus vídeos sin acceso multimedia. Puedes concederlo en ${where}.';
	@override String get settingsIos => 'la app Ajustes';
	@override String get settingsAndroid => 'los ajustes de Android';
	@override String get intro => 'Reproduce vídeos guardados en este dispositivo.\nSubnext Player solo pide acceso a los vídeos, nunca a todos los archivos.';
	@override String get allowAccess => 'Permitir acceso a los vídeos';
	@override String get pickFolderInstead => 'O elige una carpeta';
	@override String get addShare => 'Añadir un recurso de red';
	@override String get shares => 'Recursos de red';
	@override String get pickedFolders => 'Carpetas que elegiste';
	@override String get onDevice => 'En este dispositivo';
	@override String get noVideos => 'No se encontraron vídeos en este dispositivo.';
	@override String get addFolderShort => 'Añadir una carpeta';
	@override String get addShareShort => 'Añadir un recurso';
	@override String get scanDevice => 'Explorar este dispositivo';
	@override String get forgetFolder => 'Olvidar esta carpeta';
	@override String get folder => 'Carpeta';
	@override String safUnreadable({required Object error}) => 'Ya no se puede leer esta carpeta. Puede que Android haya retirado el permiso, así que quítala y vuelve a elegirla.\n\n${error}';
	@override String get safEmpty => 'Aquí no hay vídeos ni subcarpetas.';
}

// Path: smb
class _Translations$smb$es extends Translations$smb$en {
	_Translations$smb$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String connectFailed({required Object error}) => 'No se pudo conectar: ${error}';
	@override String get title => 'Añadir un recurso de red';
	@override String get explain => 'Un NAS o una carpeta compartida en otro ordenador de tu red.';
	@override String get host => 'Dirección del servidor';
	@override String get hostHint => 'p. ej., nas';
	@override String get username => 'Usuario';
	@override String get password => 'Contraseña';
	@override String get domain => 'Dominio (opcional)';
	@override String get name => 'Nombre (opcional)';
	@override String get connectAndAdd => 'Conectar y añadir';
	@override String get gone => 'Ese recurso ya no está configurado.';
	@override String unreachable({required Object error}) => 'No se pudo contactar con este recurso. Puede que el servidor esté en reposo o fuera de la red.\n\n${error}';
	@override String get empty => 'Aquí no hay vídeos ni carpetas.';
}

// Path: xtream
class _Translations$xtream$es extends Translations$xtream$en {
	_Translations$xtream$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get lineGone => 'Esa suscripción ya no está configurada.';
	@override late final _Translations$xtream$catalogue$es catalogue = _Translations$xtream$catalogue$es._(_root);
	@override late final _Translations$xtream$errors$es errors = _Translations$xtream$errors$es._(_root);
	@override String get everythingElse => 'Todo lo demás';
	@override late final _Translations$xtream$series$es series = _Translations$xtream$series$es._(_root);
	@override String get remove => 'Quitar';
	@override String get add => 'Añadir una suscripción de IPTV';
	@override late final _Translations$xtream$addLine$es addLine = _Translations$xtream$addLine$es._(_root);
	@override late final _Translations$xtream$picker$es picker = _Translations$xtream$picker$es._(_root);
	@override late final _Translations$xtream$channels$es channels = _Translations$xtream$channels$es._(_root);
	@override late final _Translations$xtream$hidden$es hidden = _Translations$xtream$hidden$es._(_root);
	@override late final _Translations$xtream$setup$es setup = _Translations$xtream$setup$es._(_root);
	@override late final _Translations$xtream$connected$es connected = _Translations$xtream$connected$es._(_root);
	@override Map<String, String> get regions => {
		'uk': 'Reino Unido',
		'us': 'EE. UU.',
		'ca': 'Canadá',
		'au': 'Australia',
		'en': 'Inglés',
		'de': 'Alemania',
		'at': 'Austria',
		'ch': 'Suiza',
		'fr': 'Francia',
		'be': 'Bélgica',
		'nl': 'Países Bajos',
		'es': 'España',
		'latam': 'Latinoamérica',
		'pt': 'Portugal',
		'br': 'Brasil',
		'it': 'Italia',
		'pl': 'Polonia',
		'tr': 'Turquía',
		'gr': 'Grecia',
		'ro': 'Rumanía',
		'ru': 'Rusia',
		'ar': 'Árabe',
		'in': 'India',
		'pk': 'Pakistán',
		'af': 'África',
		'jp': 'Japón',
		'kr': 'Corea',
		'cn': 'China',
	};
	@override Map<String, String> get kinds => {
		'news': 'Noticias',
		'sport': 'Deportes',
		'kids': 'Infantil',
		'films': 'Películas',
		'docs': 'Documentales',
		'music': 'Música',
		'entertainment': 'Entretenimiento',
	};
	@override late final _Translations$xtream$watch$es watch = _Translations$xtream$watch$es._(_root);
	@override late final _Translations$xtream$review$es review = _Translations$xtream$review$es._(_root);
}

// Path: transfer
class _Translations$transfer$es extends Translations$transfer$en {
	_Translations$transfer$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get noNetwork => 'Este dispositivo no está en una red Wi-Fi ni Ethernet. Conéctalo a la misma red que el otro dispositivo e inténtalo de nuevo.';
	@override String cannotListen({required Object error}) => 'No se pudo empezar a escuchar: ${error}';
	@override String get expired => 'Ese código ha caducado. Vuelve a empezar para obtener uno nuevo.';
	@override String wentWrong({required Object error}) => 'Algo salió mal: ${error}';
	@override String get wentWrongPlain => 'Algo salió mal.';
	@override String get gettingReady => 'Preparando…';
	@override String get waitingOther => 'Esperando al otro dispositivo…';
	@override String get copyCode => 'Copiar código';
	@override String get scanInstead => 'Escanear su código';
	@override String get typeInstead => 'Escribir su código';
	@override String get done => 'Listo';
	@override String get close => 'Cerrar';
	@override late final _Translations$transfer$receive$es receive = _Translations$transfer$receive$es._(_root);
	@override late final _Translations$transfer$pairing$es pairing = _Translations$transfer$pairing$es._(_root);
	@override late final _Translations$transfer$pane$es pane = _Translations$transfer$pane$es._(_root);
	@override late final _Translations$transfer$notes$es notes = _Translations$transfer$notes$es._(_root);
	@override late final _Translations$transfer$send$es send = _Translations$transfer$send$es._(_root);
	@override late final _Translations$transfer$item$es item = _Translations$transfer$item$es._(_root);
	@override late final _Translations$transfer$client$es client = _Translations$transfer$client$es._(_root);
}

// Path: mediaBrowser
class _Translations$mediaBrowser$es extends Translations$mediaBrowser$en {
	_Translations$mediaBrowser$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$mediaBrowser$errors$es errors = _Translations$mediaBrowser$errors$es._(_root);
	@override String get title => 'Conectar con Jellyfin o Emby';
	@override String get explain => 'Subnext Player reproduce lo que ya tiene tu propio servidor. Tu inicio de sesión se queda en este dispositivo y no llega a nadie más que a tu servidor.';
	@override String get address => 'Dirección del servidor';
	@override String get addressHint => 'p. ej., 192.168.1.20:8096';
	@override String get find => 'Buscar servidor';
	@override String get finding => 'Buscando el servidor…';
	@override String found({required Object name, required Object kind, required Object version}) => '${name} · ${kind} ${version}';
	@override String get username => 'Usuario';
	@override String get password => 'Contraseña';
	@override String get signIn => 'Iniciar sesión';
	@override String get signingIn => 'Iniciando sesión…';
	@override String get useQuickConnect => 'Usar Quick Connect';
	@override String get usePassword => 'Usar usuario y contraseña';
	@override String get quickConnectExplain => 'En un móvil u ordenador que ya tenga la sesión iniciada en Jellyfin, abre tu perfil, Quick Connect, e introduce:';
	@override String get waiting => 'Esperando la aprobación…';
	@override String get otherAddress => 'Usar otra dirección';
	@override String connected({required Object name}) => 'Conectado a ${name}.';
}

// Path: trackers
class _Translations$trackers$es extends Translations$trackers$en {
	_Translations$trackers$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$trackers$errors$es errors = _Translations$trackers$errors$es._(_root);
	@override String get malCaught => 'Sesión iniciada. Puedes cerrar esta ventana y volver a Subnext Player.';
	@override String get intro => 'Envía lo que terminas de ver en tus propios servidores a un servicio de historial. No se envía nada de IPTV, y nada llega a nosotros.';
	@override String get animeNote => 'AniList y MyAnimeList solo reciben títulos que tu servidor marca como anime, buscados por nombre.';
	@override String signedInAs({required Object name}) => 'Sesión iniciada como ${name}';
	@override String get signedIn => 'Sesión iniciada';
	@override String get notConnected => 'Sin conectar';
	@override String get signIn => 'Iniciar sesión';
	@override String get signOut => 'Cerrar sesión';
	@override String pending({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '1 visionado está pendiente de enviarse.',
		other: '${n} visionados están pendientes de enviarse.',
	);
	@override String consentTitle({required Object service}) => '¿Enviar lo que ves a ${service}?';
	@override String consentBody({required Object service}) => 'Cuando terminas una película o un episodio de tu propio servidor Plex, Jellyfin o Emby, Subnext Player envía a ${service} su título, año, su identificador de IMDb, TMDB o TVDB, y cuándo lo viste. Va directamente de este dispositivo a ${service}, nunca a través de nosotros. No se envía nada de IPTV. Puedes cerrar sesión cuando quieras en Ajustes, Seguimiento de lo visto.';
	@override String consentAnime({required Object service}) => 'A ${service} solo se envían títulos que tu servidor marca como anime, y se buscan en ${service} por su nombre.';
	@override String get agree => 'Continuar';
	@override String get notNow => 'Ahora no';
	@override String signInTitle({required Object service}) => 'Iniciar sesión en ${service}';
	@override String deviceCodeExplain({required Object url}) => 'En cualquier dispositivo, abre ${url} e introduce:';
	@override String get waiting => 'Esperando la aprobación…';
	@override String browserExplain({required Object service}) => 'Abre esta dirección en un navegador, inicia sesión en ${service} y aprueba Subnext Player. Luego pega abajo lo que te dé ${service}.';
	@override String get anilistPaste => 'AniList muestra un token largo al aprobar. Cópialo entero.';
	@override String get malPaste => 'En este dispositivo la app termina sola. Si el navegador estaba en otro, acaba en una página que no carga: copia la dirección completa de esa página.';
	@override String get tvHint => 'En una TV, inicia sesión en el móvil y usa Pasar a otro dispositivo para traerlo aquí.';
	@override String get pasteLabel => 'Pega aquí';
	@override String get finish => 'Terminar de iniciar sesión';
	@override String get copyAddress => 'Copiar dirección';
	@override String connected({required Object service}) => 'Conectado a ${service}.';
}

// Path: seerr
class _Translations$seerr$es extends Translations$seerr$en {
	_Translations$seerr$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$seerr$errors$es errors = _Translations$seerr$errors$es._(_root);
	@override String get intro => 'Conecta tu propio servidor Overseerr, Jellyseerr o Seerr para pedir películas y series que tu biblioteca aún no tiene. Las solicitudes van a tu servidor y a ningún otro sitio; quien lo administra decide qué pasa después.';
	@override String get address => 'Dirección del servidor';
	@override String get addressHint => 'p. ej., 192.168.1.20:5055';
	@override String get find => 'Buscar servidor';
	@override String get withPlex => 'Iniciar sesión con mi cuenta de Plex';
	@override String get withPassword => 'Iniciar sesión con usuario y contraseña';
	@override String get withKey => 'Usar una clave de API';
	@override String get username => 'Usuario o correo';
	@override String get password => 'Contraseña';
	@override String get apiKey => 'Clave de API';
	@override String get keyNote => 'Una clave de API actúa como administrador del servidor, así que las solicitudes hechas con ella no constan como tuyas. Mejor inicia sesión.';
	@override String get connect => 'Conectar';
	@override String get connecting => 'Conectando…';
	@override String connected({required Object title, required Object name}) => 'Conectado a ${title} como ${name}';
	@override String get disconnect => 'Desconectar';
	@override String get myRequests => 'Tus solicitudes recientes';
	@override String get none => 'Aún no hay solicitudes.';
	@override String get statusPending => 'Esperando aprobación';
	@override String get statusApproved => 'Aprobada';
	@override String get statusDeclined => 'Rechazada';
	@override String get statusAvailable => 'Disponible';
	@override String rowTitle({required Object title}) => 'Solicitar a ${title}';
	@override String get requested => 'Solicitado';
	@override String get partial => 'Disponible en parte';
	@override String askTitle({required Object title}) => '¿Solicitar ${title}?';
	@override String askMovie({required Object server}) => 'Esto pide a ${server} que añada la película. Quien lo administra decide si lo hace.';
	@override String askShow({required Object server}) => 'Esto pide a ${server} que añada todas las temporadas. Quien lo administra decide si lo hace.';
	@override String get request => 'Solicitar';
	@override String sent({required Object title}) => 'Se solicitó ${title}.';
}

// Path: film
class _Translations$film$es extends Translations$film$en {
	_Translations$film$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get play => 'Reproducir';
	@override String resume({required Object time}) => 'Reanudar desde ${time}';
	@override String get fromStart => 'Reproducir desde el principio';
	@override String get gone => 'Esta película ya no está en el servidor, o no se puede contactar con el servidor.';
	@override String get trailer => 'Tráiler';
	@override String get trailerNoApp => 'Nada en este dispositivo puede abrir el tráiler.';
	@override String rtAudience({required Object pct}) => 'RT público ${pct} %';
}

// Path: errors
class _Translations$errors$es extends Translations$errors$en {
	_Translations$errors$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get addressHidden => '(dirección oculta)';
}

// Path: player.upNext
class _Translations$player$upNext$es extends Translations$player$upNext$en {
	_Translations$player$upNext$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'A continuación';
	@override String playingIn({required Object seconds}) => 'Se reproduce en ${seconds} s';
	@override String get playNow => 'Reproducir ahora';
}

// Path: downloads.errors
class _Translations$downloads$errors$es extends Translations$downloads$errors$en {
	_Translations$downloads$errors$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get serverNotConnected => 'Ese servidor no está conectado. Vuelve a conectarlo en Ajustes y reanuda.';
	@override String get sizeMismatch => 'El archivo no coincide con el tamaño que indicó el servidor. Inténtalo de nuevo.';
	@override String get cannotWrite => 'No se pudo escribir el archivo. Puede que el dispositivo no tenga espacio.';
	@override String get changedOnServer => 'El archivo cambió en el servidor. Vuelve a empezar la descarga.';
	@override String get refused => 'El servidor no permite que este dispositivo lo descargue.';
	@override String status({required Object code}) => 'El servidor respondió ${code}.';
	@override String get dropped => 'La conexión se cortó a medias. Reanuda para continuar.';
	@override String get unreachable => 'No se pudo contactar con el servidor. Comprueba la conexión y reanuda.';
	@override String get timeout => 'El servidor tardó demasiado en responder.';
}

// Path: downloads.rule
class _Translations$downloads$rule$es extends Translations$downloads$rule$en {
	_Translations$downloads$rule$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get off => 'Mantener episodios descargados';
	@override String keeping({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: 'Se mantiene descargado el siguiente episodio',
		other: 'Se mantienen descargados los ${n} siguientes episodios',
	);
	@override String get explain => 'Descarga los siguientes episodios sin ver y los repone a medida que los ves, mientras la app está abierta. Se eliminan los que descargó y ya has visto.';
	@override String get choiceOff => 'Desactivado';
	@override String choice({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: 'Siguiente episodio',
		other: '${n} siguientes episodios',
	);
}

// Path: library.placement
class _Translations$library$placement$es extends Translations$library$placement$en {
	_Translations$library$placement$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get movies => 'Películas';
	@override String get series => 'Series';
	@override String get hidden => 'Oculto';
}

// Path: library.tab
class _Translations$library$tab$es extends Translations$library$tab$en {
	_Translations$library$tab$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get movies => 'Películas';
	@override String get series => 'Series';
	@override String get localNetwork => 'Local y red';
	@override String get liveTv => 'TV en directo';
	@override String get emptyMovies => 'No hay películas en este servidor.';
	@override String get emptySeries => 'No hay series en este servidor.';
	@override String get emptyLocalNetwork => 'Aún no hay carpetas ni recursos de red.\nEl almacenamiento del dispositivo y las carpetas SMB no se pueden conectar en esta versión.';
	@override String get emptyLiveTv => 'Aún no hay ninguna suscripción de IPTV.\nAñade una desde Añadir fuente.';
	@override String countMovies({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${n} película',
		other: '${n} películas',
	);
	@override String countSeries({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${n} serie',
		other: '${n} series',
	);
	@override String countItems({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${n} elemento',
		other: '${n} elementos',
	);
	@override String countChannels({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${n} canal',
		other: '${n} canales',
	);
}

// Path: library.shelf
class _Translations$library$shelf$es extends Translations$library$shelf$en {
	_Translations$library$shelf$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get seeAll => 'Ver todo';
	@override String titles({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${n} título',
		other: '${n} títulos',
	);
	@override String get gone => 'Aquí ya no hay nada.';
}

// Path: library.sort
class _Translations$library$sort$es extends Translations$library$sort$en {
	_Translations$library$sort$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Título';
	@override String get recentlyAdded => 'Añadido recientemente';
	@override String get year => 'Año';
	@override String get releaseDate => 'Fecha de estreno';
}

// Path: library.tile
class _Translations$library$tile$es extends Translations$library$tile$en {
	_Translations$library$tile$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get series => 'Serie';
	@override String get movie => 'Película';
	@override String get watched => 'Visto';
	@override String percentWatched({required Object percent}) => '${percent} % visto';
	@override String unwatchedEpisodes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${n} episodio sin ver',
		other: '${n} episodios sin ver',
	);
}

// Path: liveTv.group
class _Translations$liveTv$group$es extends Translations$liveTv$group$en {
	_Translations$liveTv$group$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get favourites => 'Favoritos';
	@override String numbered({required Object n}) => 'Categoría ${n}';
	@override String get other => 'Otros';
}

// Path: ai.picks
class _Translations$ai$picks$es extends Translations$ai$picks$en {
	_Translations$ai$picks$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get yourProvider => 'tu proveedor';
	@override String get ask => '¿Qué veo?';
	@override String askExplain({required Object provider}) => 'Pide a ${provider} que elija de tu propia biblioteca.';
	@override String get pickedBy => 'Elegido para ti por ';
	@override String get updating => 'Actualizando';
	@override String get again => 'Otra vez';
	@override String get preparing => 'Preparando tus sugerencias...';
}

// Path: ai.search
class _Translations$ai$search$es extends Translations$ai$search$en {
	_Translations$ai$search$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String asking({required Object provider}) => 'Preguntando a ${provider}...';
	@override String searching({required Object searched, required Object covered}) => 'Buscando en tu biblioteca... ${searched} de ${covered} títulos';
	@override String get emptyLibrary => 'Aún no hay nada en tu biblioteca en lo que buscar.';
	@override String notFound({required Object total}) => 'El modelo no encontró nada que encaje entre ${total} títulos. Prueba a describirlo de otra forma.';
	@override String notFoundFirst({required Object covered, required Object total}) => 'El modelo no encontró nada que encaje entre los primeros ${covered} de ${total} títulos. Prueba a describirlo de otra forma.';
	@override String stillSearching({required Object searched, required Object covered}) => 'Todavía buscando: ${searched} de ${covered} títulos';
	@override String searchedFirst({required Object covered, required Object total}) => 'Se buscó en los primeros ${covered} de ${total} títulos';
	@override String pickedFor({required Object provider, required Object query}) => 'Elegido por ${provider} para «${query}»';
	@override String get searchAgain => 'Buscar de nuevo';
	@override String partsFailed({required Object failed, required Object parts}) => 'No se pudieron buscar ${failed} de ${parts} partes, así que parte de tu biblioteca no se revisó. Puede que el proveedor esté limitando las solicitudes';
}

// Path: ai.feature
class _Translations$ai$feature$es extends Translations$ai$feature$en {
	_Translations$ai$feature$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get naturalSearch => 'Búsqueda en lenguaje natural';
	@override String get naturalSearchSends => 'El texto que buscas, y los títulos y años de tu biblioteca.';
	@override String get naturalSearchTiming => 'Una biblioteca grande se envía en varias solicitudes de unos cientos de títulos cada una, así que una búsqueda hace más de una.';
	@override String get recommendations => 'Recomendaciones';
	@override String get recommendationsSends => 'Las películas que has visto recientemente, y los títulos y años de lo que aún no has visto en tu biblioteca.';
	@override String get recommendationsTiming => 'Las sugerencias se preparan en segundo plano poco después de abrir la app, pero solo cuando ha cambiado lo que has visto o tienen más de un día, así que no hay una solicitud en cada inicio.';
}

// Path: ai.errors
class _Translations$ai$errors$es extends Translations$ai$errors$en {
	_Translations$ai$errors$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get ranOutThinking => 'El modelo se quedó sin espacio de respuesta mientras pensaba y nunca dio una respuesta. Funcionará mejor un modelo que no «piense» antes.';
	@override String get empty => 'El modelo devolvió una respuesta vacía.';
	@override String rejectedKey({required Object suffix}) => 'El proveedor rechazó esa clave${suffix}.';
	@override String noCredit({required Object suffix}) => 'El proveedor dice que esta cuenta no tiene crédito${suffix}.';
	@override String unknownModel({required Object suffix}) => 'El proveedor no conoce ese modelo o esa dirección${suffix}.';
	@override String rateLimited({required Object suffix}) => 'El proveedor está limitando esta clave. Inténtalo dentro de un momento${suffix}.';
	@override String serverError({required Object status, required Object suffix}) => 'El proveedor tuvo un problema (HTTP ${status})${suffix}.';
	@override String get timeout => 'El proveedor tardó demasiado en responder.';
	@override String get unreachable => 'No se pudo contactar con el proveedor. Comprueba la dirección.';
	@override String failed({required Object suffix}) => 'La solicitud falló${suffix}.';
	@override String failedStatus({required Object status, required Object suffix}) => 'La solicitud falló (HTTP ${status})${suffix}.';
	@override String get fillIn => 'Rellena la dirección y el modelo.';
	@override String get needsKey => 'Este proveedor necesita una clave de API.';
	@override String get notSetUp => 'No hay ningún proveedor de IA configurado.';
	@override String get searchOff => 'La búsqueda en lenguaje natural está desactivada para este proveedor.';
	@override String get searchFailed => 'La búsqueda falló.';
	@override String get noSignal => 'Mira antes una película, para que haya algo en lo que basar las sugerencias.';
	@override String get noPicks => 'Esta vez el modelo no eligió nada.';
}

// Path: search.filters
class _Translations$search$filters$es extends Translations$search$filters$en {
	_Translations$search$filters$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String decadeOldest({required Object decade}) => 'Años ${decade} y anteriores';
	@override String decade({required Object decade}) => 'Años ${decade}';
	@override String get type => 'Tipo';
	@override String get movies => 'Películas';
	@override String get series => 'Series';
	@override String get source => 'Fuente';
	@override String get unknownSource => 'Fuente desconocida';
	@override String get year => 'Año';
	@override String get language => 'Idioma';
	@override String get languageNote => 'Deducido de los nombres de las categorías de IPTV. Los títulos de Plex no tienen idioma aquí.';
	@override String get genre => 'Género';
	@override String get rating => 'Valoración';
	@override String get ratingNote => 'Valoración de los usuarios de TMDB sobre 10. Se excluyen los títulos sin valoración en TMDB.';
	@override String get originalLanguage => 'Idioma original';
	@override String get originalLanguageNote => 'El idioma en que se rodó el título, según TMDB. Una copia doblada conserva aquí su idioma original.';
	@override String get clear => 'Borrar';
	@override String get noMatches => 'Nada coincide con esos filtros.';
	@override String get clearAll => 'Borrar filtros';
	@override String chip({required Object label, required Object value}) => '${label}: ${value}';
	@override String get any => 'Cualquiera';
}

// Path: settings.about
class _Translations$settings$about$es extends Translations$settings$about$en {
	_Translations$settings$about$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get versionLoading => 'Versión …';
	@override String version({required Object version, required Object build}) => 'Versión ${version} (${build})';
	@override String get privacyPolicy => 'Política de privacidad';
	@override String get privacySummary => 'Sin cuenta, sin servidor propio y sin analíticas. La política completa está en:';
	@override String get licences => 'Licencias de código abierto';
}

// Path: settings.privacy
class _Translations$settings$privacy$es extends Translations$settings$privacy$en {
	_Translations$settings$privacy$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get summary => 'Subnext Player no tiene servidor propio ni analíticas. Lo que guarda está en este dispositivo, y los únicos sitios a los que se envían datos son las fuentes, TMDB y el proveedor de IA que tú mismo conectas.';
	@override String get cachedData => 'Datos en caché';
	@override String get cachedExplain => 'Las listas de tu biblioteca, las consultas a TMDB y las sugerencias de la IA se guardan para que la app abra rápido. Las antiguas se borran solas, a los 30 días las de una biblioteca y a los 90 las de una consulta, y los datos de una fuente desaparecen al quitarla. Borrar ahora no toca tus fuentes, claves, ajustes ni historial, y todo se vuelve a obtener cuando haga falta.';
	@override String get clearing => 'Borrando...';
	@override String get clear => 'Borrar datos en caché';
	@override String get cleared => 'Borrado. Tu biblioteca se está volviendo a cargar.';
}

// Path: settings.playback
class _Translations$settings$playback$es extends Translations$settings$playback$en {
	_Translations$settings$playback$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get skip => 'Saltar atrás y adelante';
	@override String get skipExplain => 'Los botones de salto, las teclas de avance y retroceso de un mando, y el primer paso al moverse por la barra de progreso.';
	@override String get audioLanguage => 'Idioma de audio preferido';
	@override String get audioLanguageExplain => 'Se usa cuando un archivo tiene más de una pista de audio. Si no, suena la pista predeterminada del archivo.';
	@override String get fileDefault => 'Predeterminado del archivo';
	@override String get showSubtitles => 'Mostrar subtítulos';
	@override String get showSubtitlesExplain => 'Actívalos cuando un archivo los tenga. Siempre puedes cambiarlos en el reproductor.';
	@override String get subtitleLanguage => 'Idioma de subtítulos preferido';
	@override String get subtitleLanguageExplain => 'Si un archivo no tiene subtítulos en este idioma, no se muestra ninguno.';
	@override String get any => 'Cualquiera';
	@override String get size => 'Tamaño';
	@override String get sizeExplain => 'Para subtítulos de texto, como SRT y ASS.';
}

// Path: settings.metadata
class _Translations$settings$metadata$es extends Translations$settings$metadata$en {
	_Translations$settings$metadata$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get consent => 'Esto consulta en TMDB la fecha de estreno de cada película y serie de tu biblioteca, en segundo plano y unas pocas cada vez. Para ello envía el título (y el año, si lo hay) de cada una desde este dispositivo a TMDB, y a nadie más, no solo las que buscas. También rellena el género y la valoración para los filtros. Los resultados se guardan en este dispositivo durante 90 días, y no se vuelve a preguntar por los títulos ya consultados.\n\nPuedes desactivarlo cuando quieras. Al quitar tu clave de TMDB también se desactiva.';
	@override String get consentTitle => '¿Enviar los títulos de tu biblioteca a TMDB?';
	@override String get notNow => 'Ahora no';
	@override String get lookThemUp => 'Consultarlas';
	@override String get waiting => 'Esperando a que se cargue tu biblioteca.';
	@override String get stopped => 'En pausa: TMDB dejó de responder. Continuará la próxima vez que se abra la app, y se conserva lo que encontró.';
	@override String running({required Object settled, required Object total}) => 'Consultados ${settled} de ${total} títulos.';
	@override String partial({required Object settled, required Object total}) => 'Consultados ${settled} de ${total} títulos. El resto continuará la próxima vez que se abra la app.';
	@override String done({required Object found, required Object total}) => 'Listo: se encontraron ${found} fechas de estreno para ${total} títulos.';
	@override String get releaseDates => 'Fechas de estreno de tu biblioteca';
	@override String get releaseDatesExplain => 'Añade fechas de estreno exactas en segundo plano, para que Ordenar por fecha de estreno ordene bien tu biblioteca, incluidos los títulos sin año. Envía todos los títulos de tu biblioteca a TMDB.';
	@override String get intro => 'Conecta tu propia clave de TMDB para añadir género, valoración e idioma original a los resultados de búsqueda, y sugerencias basadas en lo que has visto. Es opcional, y nada cambia hasta que añadas una.';
	@override String get keyExplain => 'Los títulos que se consultan se envían desde este dispositivo a TMDB, y a nadie más. Crea una clave gratuita en tu cuenta de TMDB, en Ajustes, API. Sirve tanto la clave corta como el token de acceso de lectura largo. En una TV es más fácil pegarla o escribirla primero en un móvil o un ordenador.';
	@override String get keySaved => 'Clave de TMDB guardada';
	@override String get removeKey => 'Quitar clave';
	@override String get keyLabel => 'Clave de API de TMDB';
	@override String get checking => 'Comprobando...';
	@override String get verify => 'Verificar y guardar';
	@override late final _Translations$settings$metadata$errors$es errors = _Translations$settings$metadata$errors$es._(_root);
}

// Path: settings.ai
class _Translations$settings$ai$es extends Translations$settings$ai$en {
	_Translations$settings$ai$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get intro => 'Conecta tu propio proveedor y tu propia clave. Las solicitudes van directamente de este dispositivo al proveedor que elijas, nunca a través de nosotros, porque no hay ningún servidor nuestro en medio. No se envía nada hasta que permitas una de las funciones de abajo.';
	@override String get address => 'Dirección';
	@override String get model => 'Modelo';
	@override String get keyOptional => 'Clave de API (opcional para un servidor local)';
	@override String get key => 'Clave de API';
	@override String get trying => 'Probando...';
	@override String get testAndSave => 'Probar y guardar';
	@override String get onNetwork => 'En tu red';
	@override String get keySaved => 'Clave guardada';
	@override String get remove => 'Quitar proveedor';
	@override String get maySend => 'Qué puede enviar';
	@override String get localNoConsent => 'Este proveedor está en tu propia red, así que nada llega a terceros y no hace falta consentimiento.';
	@override String sendsTo({required Object provider, required Object sends}) => 'Envía a ${provider}: ${sends}';
	@override String allowedOn({required Object date}) => 'Permitido el ${date}';
	@override String get notAllowed => 'Aún no está permitido. Se te preguntará la primera vez.';
	@override String get switchOff => 'Desactivar';
	@override String get allow => 'Permitir';
}

// Path: settings.appearance
class _Translations$settings$appearance$es extends Translations$settings$appearance$en {
	_Translations$settings$appearance$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$settings$appearance$palette$es palette = _Translations$settings$appearance$palette$es._(_root);
	@override String get theme => 'Tema';
	@override String get accent => 'Color de acento';
}

// Path: settings.section
class _Translations$settings$section$es extends Translations$settings$section$en {
	_Translations$settings$section$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get sources => 'Fuentes';
	@override String get appearance => 'Apariencia';
	@override String get playback => 'Reproducción';
	@override String get subtitles => 'Subtítulos';
	@override String get metadata => 'Metadatos';
	@override String get aiFeatures => 'Funciones de IA';
	@override String get advancedSources => 'Fuentes avanzadas';
	@override String get transfer => 'Pasar a otro dispositivo';
	@override String get privacy => 'Privacidad y datos';
	@override String get about => 'Acerca de';
	@override String get trackers => 'Seguimiento de lo visto';
	@override String get requests => 'Solicitudes';
}

// Path: settings.advanced
class _Translations$settings$advanced$es extends Translations$settings$advanced$en {
	_Translations$settings$advanced$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get dialogTitle => 'Antes de activar la TV en directo';
	@override String get dialogLead => 'Vas a conectar un proveedor externo con tus propias credenciales.';
	@override String get dialogNoContent => 'Subnext Player no proporciona, aloja ni respalda ningún contenido ni proveedor. Tú indicas la dirección y el inicio de sesión, y la app reproduce lo que devuelva esa dirección.';
	@override String get dialogRights => 'Eres responsable de tener los derechos de aquello a lo que te conectes.';
	@override String get dialogLogin => 'Se guarda en el almacenamiento seguro de este dispositivo y solo se envía a la dirección que indiques.';
	@override String get pointNoContent => 'No ofrecemos ni recomendamos ningún proveedor';
	@override String get pointRights => 'Los derechos son cosa tuya';
	@override String get pointLogin => 'Tu inicio de sesión se queda en este dispositivo';
	@override String get dialogConfirm => 'Lo entiendo, activar';
	@override String get toggle => 'TV en directo de una suscripción de IPTV';
	@override String get toggleExplain => 'Añade la pestaña TV en directo y las suscripciones de IPTV en Añadir fuente.';
	@override String get offKeeps => 'Si lo desactivas más tarde, se oculta la TV en directo, pero se conservan tus suscripciones.';
}

// Path: settings.sources
class _Translations$settings$sources$es extends Translations$settings$sources$en {
	_Translations$settings$sources$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get noServers => 'No hay servidores Plex conectados.';
	@override String get remove => 'Quitar';
	@override String loadFailed({required Object error}) => 'No se pudieron cargar las bibliotecas de este servidor.\n\n${error}';
	@override String get lookForMore => 'Buscar más servidores';
	@override String get addAnother => 'Añadir otro servidor';
	@override String get yours => 'Tuyo';
	@override String get shared => 'Compartido contigo';
	@override String get viaRelay => 'mediante relé';
	@override String plexType({required Object type}) => 'Tipo en Plex: ${type}';
	@override String get changedByYou => 'cambiado por ti';
	@override String get localTab => 'Mostrar Local y red';
	@override String get localTabSub => 'Una pestaña en Inicio para vídeos de este dispositivo y de carpetas de red. Se activa sola cuando añades una.';
}

// Path: addSource.kind
class _Translations$addSource$kind$es extends Translations$addSource$kind$en {
	_Translations$addSource$kind$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get plex => 'Servidor Plex';
	@override String get plexShort => 'Vincular con código';
	@override String get plexLong => 'Aprueba este dispositivo en tu navegador. Tu propio servidor y todo lo que compartan contigo.';
	@override String get localFiles => 'Vídeos de este dispositivo';
	@override String get localFilesSub => 'Explora tu biblioteca multimedia o elige una carpeta concreta a la que mantener acceso.';
	@override String get localFilesIos => 'Reproduce los vídeos de tu fototeca.';
	@override String get smb => 'Recurso de red (SMB)';
	@override String get smbSub => 'Un NAS o una carpeta compartida de Windows en tu red doméstica.';
	@override String get xtream => 'Suscripción de IPTV';
	@override String get xtreamSub => 'El enlace o el inicio de sesión que te envió tu proveedor. También se llama Xtream Codes.';
	@override String get mediaBrowser => 'Servidor Jellyfin o Emby';
	@override String get mediaBrowserSub => 'Tu propio servidor, con tu propia cuenta.';
}

// Path: plex.errors
class _Translations$plex$errors$es extends Translations$plex$errors$en {
	_Translations$plex$errors$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String noAnswer({required Object server, required Object count}) => '«${server}» no respondió en ninguna de sus ${count} direcciones anunciadas.';
	@override String get itemGone => 'Ese elemento ya no está en el servidor.';
	@override String get noFile => 'Este elemento no tiene ningún archivo reproducible. Las fuentes que solo admiten transcodificación aún no están disponibles.';
	@override String get notConnected => 'No hay conexión con ningún servidor Plex.';
}

// Path: xtream.catalogue
class _Translations$xtream$catalogue$es extends Translations$xtream$catalogue$en {
	_Translations$xtream$catalogue$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get live => 'TV en directo';
	@override String get vod => 'Películas';
	@override String get series => 'Series';
}

// Path: xtream.errors
class _Translations$xtream$errors$es extends Translations$xtream$errors$en {
	_Translations$xtream$errors$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String status({required Object code}) => 'El servidor de tu proveedor respondió ${code}. Inténtalo más tarde.';
	@override String get timeout => 'El servidor de tu proveedor no respondió a tiempo.';
	@override String get unreachable => 'No se pudo acceder a esa dirección. Revisa el enlace, o la dirección del servidor y el puerto.';
	@override String other({required Object type}) => 'No se pudo hablar con el servidor de tu proveedor (${type}).';
	@override String get notXtream => 'Esa dirección no respondió como un servidor de IPTV. Revisa el enlace o la dirección del servidor.';
	@override String get rejected => 'Tu proveedor no aceptó ese inicio de sesión.';
	@override String get wrongLogin => 'Usuario o contraseña incorrectos.';
	@override String get unnamed => 'Sin nombre';
	@override String get episode => 'Episodio';
	@override String get noPassword => 'Esa suscripción no tiene contraseña guardada. Quítala y vuelve a añadirla.';
}

// Path: xtream.series
class _Translations$xtream$series$es extends Translations$xtream$series$en {
	_Translations$xtream$series$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Serie';
	@override String get noEpisodes => 'Tu proveedor no devolvió episodios de esta serie.';
	@override String season({required Object n}) => 'Temporada ${n}';
}

// Path: xtream.addLine
class _Translations$xtream$addLine$es extends Translations$xtream$addLine$en {
	_Translations$xtream$addLine$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get discardTitle => '¿Descartar lo que escribiste?';
	@override String get discardBody => 'Lo que has escrito aquí no se ha guardado.';
	@override String get discard => 'Descartar';
	@override String get keepEditing => 'Seguir editando';
	@override String inactive({required Object status}) => 'Tu proveedor dice que esta suscripción está "${status}".';
	@override String get noContent => 'Subnext Player no proporciona, aloja ni respalda ningún contenido ni proveedor. Tú indicas la dirección y el inicio de sesión, y la app reproduce lo que devuelva esa dirección.';
	@override String get host => 'Dirección del servidor';
	@override String get name => 'Nombre (opcional)';
	@override String get nameHint => 'Cómo quieres llamar a esta suscripción';
	@override String get checking => 'Comprobando…';
	@override String get verify => 'Conectar';
	@override String get hostHint => 'example.com:8080';
	@override String get how => '¿Cómo te envió tu proveedor el inicio de sesión?';
	@override String get howHint => 'Busca en el correo o mensaje que recibiste al suscribirte.';
	@override String get modeLink => 'Un enlace largo';
	@override String get modeLinkSub => 'Suele llamarse enlace M3U o URL de lista.';
	@override String get modeLogin => 'Un usuario y una contraseña';
	@override String get modeLoginSub => 'Con una dirección de servidor como example.com:8080. A veces se llama inicio de sesión Xtream Codes.';
	@override String get modeDevice => 'Ya está en otro dispositivo';
	@override String get modeDeviceSub => 'Envíalo desde tu móvil en lugar de escribirlo aquí.';
	@override String get link => 'Enlace de tu proveedor';
	@override String get paste => 'Pegar';
	@override String get found => 'Hemos encontrado tu inicio de sesión en este enlace';
	@override String get notALink => 'No parece un enlace con un inicio de sesión. Revísalo o escribe los datos tú mismo.';
	@override String get server => 'Servidor';
	@override String get show => 'Mostrar';
	@override String get hide => 'Ocultar';
	@override String get defaultName => 'Suscripción de TV';
}

// Path: xtream.picker
class _Translations$xtream$picker$es extends Translations$xtream$picker$en {
	_Translations$xtream$picker$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get patternNone => 'Ese patrón no coincidió con nada.';
	@override String title({required Object catalogue}) => 'Categorías de ${catalogue}';
	@override String get save => 'Guardar';
	@override String noMatch({required Object query}) => 'Nada coincide con «${query}».';
	@override String get noneChosen => 'Aún no has elegido nada.';
	@override String get search => 'Buscar en todas las categorías';
	@override String chosen({required Object n}) => 'Elegidas ${n}';
	@override String get hideWords => 'Ocultar palabras';
	@override String hideCount({required Object n}) => 'Ocultas ${n}';
	@override String get pattern => 'Patrón';
	@override String untickedOne({required Object name, required Object word}) => 'Se desmarcó «${name}», que oculta «${word}». Guarda para conservarlo.';
	@override String untickedMany({required Object n, required Object word}) => 'Se desmarcaron ${n} categorías elegidas que oculta «${word}». Guarda para conservarlo.';
	@override String get showingHidden => 'Se muestran las categorías que dejan fuera tus palabras ocultas.';
	@override String hiddenCount({required Object n}) => '${n} ocultas por tus palabras.';
	@override String get hideAgain => 'Volver a ocultar';
	@override String get showThem => 'Mostrarlas';
	@override String get patternHint => 'Marca o desmarca todas las categorías que coincidan con una palabra o un patrón';
	@override String get selectMatching => 'Marcar coincidencias';
	@override String get deselectMatching => 'Desmarcar coincidencias';
	@override String get groups => 'Grupos';
	@override String get clearAll => 'Desmarcar todo';
	@override String get selectAll => 'Marcar todo';
	@override String channelsPicked({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${n} canal',
		other: '${n} canales',
	);
	@override String pickedChosen({required Object n}) => '${n} elegidos';
	@override String categories({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${n} categoría',
		other: '${n} categorías',
	);
	@override String get channels => 'Canales';
}

// Path: xtream.channels
class _Translations$xtream$channels$es extends Translations$xtream$channels$en {
	_Translations$xtream$channels$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get done => 'Listo';
	@override String get search => 'Buscar en esta categoría';
	@override String pickedOf({required Object picked, required Object total}) => '${picked} de ${total}';
	@override String get whole => 'Toda la categoría';
	@override String get selectShown => 'Marcar los mostrados';
	@override String get clear => 'Desmarcar';
	@override String get clearShown => 'Desmarcar los mostrados';
	@override String get none => 'Tu proveedor no tiene canales en esta categoría.';
	@override String wholeTitle({required Object n}) => 'Categoría completa · ${n} canales';
	@override String get wholeSub => 'Los canales nuevos que añada tu proveedor aparecen solos.';
	@override String someTitle({required Object picked, required Object total}) => 'Solo los que marque · ${picked} de ${total}';
	@override String get someSub => 'Los canales añadidos más tarde quedan ocultos hasta que los marques.';
}

// Path: xtream.hidden
class _Translations$xtream$hidden$es extends Translations$xtream$hidden$en {
	_Translations$xtream$hidden$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ocultar palabras';
	@override String get explain => 'Las categorías o canales que contengan cualquiera de estas como palabra completa quedan fuera de las listas. «UK» oculta «UK News» pero no «Ukraine». Añade una frase como «south indian» para ocultarla como un todo. No distingue mayúsculas.';
	@override String get hint => 'Un país, un idioma, una palabra';
	@override String get add => 'Añadir';
	@override String get none => 'Aún no hay nada oculto.';
	@override String get tapToRemove => 'Selecciona una palabra para dejar de ocultarla.';
}

// Path: xtream.setup
class _Translations$xtream$setup$es extends Translations$xtream$setup$en {
	_Translations$xtream$setup$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String step({required Object n}) => 'Paso ${n} de 3';
}

// Path: xtream.connected
class _Translations$xtream$connected$es extends Translations$xtream$connected$en {
	_Translations$xtream$connected$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Estás conectado';
	@override String get status => 'Estado';
	@override String get active => 'Activa';
	@override String get trial => 'Activa, de prueba';
	@override String get ends => 'Termina';
	@override String get noEnd => 'Sin fecha de fin';
	@override String get screens => 'Pantallas a la vez';
	@override String get oneScreen => 'Tu suscripción se reproduce en una pantalla a la vez. Si está en marcha en otro sitio, aquí no empezará hasta que se detenga.';
	@override String liveCategories({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${n} categoría de canales',
		other: '${n} categorías de canales',
	);
	@override String get available => 'Canales';
	@override String get next => 'Es más de lo que nadie ve, así que ahora eliges los países y tipos de canal que quieres. Solo se cargan esos.';
	@override String get choose => 'Elegir lo que ves';
}

// Path: xtream.watch
class _Translations$xtream$watch$es extends Translations$xtream$watch$en {
	_Translations$xtream$watch$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => '¿Qué ves?';
	@override String get sub => 'Elige unos cuantos. Puedes cambiarlo cuando quieras.';
	@override String get regions => 'Países e idiomas';
	@override String get kinds => 'Tipos de canal';
	@override String more({required Object n}) => 'Ver los ${n}';
	@override String get fewer => 'Ver menos';
	@override String count({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${n} categoría elegida',
		other: '${n} categorías elegidas',
	);
	@override String get none => 'Elige un país, un idioma o un tipo de canal.';
	@override String unplaced({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: 'Ordenado por los nombres que usa tu proveedor. ${n} categoría no encaja en ninguno: la encontrarás en Ajuste fino.',
		other: 'Ordenado por los nombres que usa tu proveedor. ${n} categorías no encajan en ninguno: las encontrarás en Ajuste fino.',
	);
	@override String get fineTune => 'Ajuste fino';
	@override String get chips => 'Volver a las opciones';
	@override String get replaceTitle => '¿Sustituir tu selección hecha a mano?';
	@override String get replaceBody => 'Cambiaste la selección a mano en Ajuste fino. Esto la sustituye por lo que abarcan estas opciones.';
	@override String get replace => 'Sustituir';
	@override String get keep => 'Mantener la mía';
	@override String get next => 'Continuar';
}

// Path: xtream.review
class _Translations$xtream$review$es extends Translations$xtream$review$en {
	_Translations$xtream$review$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Esto es lo que verás';
	@override String get live => 'TV en directo';
	@override String get movies => 'Películas';
	@override String get series => 'Series';
	@override String chosen({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${n} categoría',
		other: '${n} categorías',
	);
	@override String get notAdded => 'Aún no añadido';
	@override String get add => 'Añadir';
	@override String get change => 'Cambiar';
	@override String get neverShow => 'No mostrar nunca';
	@override String get neverShowSub => 'Ocultar todo lo que tenga estas palabras';
	@override String get neverShowNone => 'Nada oculto';
	@override String get edit => 'Editar';
	@override String get later => 'Puedes cambiar todo esto más tarde en Ajustes, Fuentes avanzadas.';
	@override String get open => 'Abrir TV en directo';
	@override String get link => 'Lo que ves';
}

// Path: transfer.receive
class _Translations$transfer$receive$es extends Translations$transfer$receive$en {
	_Translations$transfer$receive$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String cannotSave({required Object error}) => 'No se pudieron guardar los ajustes: ${error}';
	@override String get title => 'Recibir ajustes';
	@override String get asking => 'Preguntando al otro dispositivo…';
	@override String get awaitingPush => 'Esperando a que el otro dispositivo envíe. Di que sí allí cuando lo pregunte.';
	@override String get saving => 'Guardando…';
	@override String get waitingInstructions => 'En el dispositivo que tiene tus ajustes, abre Ajustes, Pasar a otro dispositivo, y elige Enviar. Luego escanea este código.';
	@override String get scanInstructions => 'En el dispositivo que tiene tus ajustes, abre Ajustes, Pasar a otro dispositivo, y elige Enviar y después Mostrar un código. Apunta la cámara hacia él.';
	@override String get showMine => 'Mostrar mi código';
	@override String get typeInstructions => 'En el dispositivo que tiene tus ajustes, abre Ajustes, Pasar a otro dispositivo, y elige Enviar y después Mostrar un código. Luego introduce lo que muestre.';
	@override String get connect => 'Conectar';
	@override String get review => 'Otro dispositivo quiere enviarte esto. Lo que ya esté aquí con el mismo nombre se sustituye; no se quita nada más.';
	@override String get saveThese => 'Guardar esto';
	@override String get decline => 'Rechazar';
	@override String get saved => 'Listo. Tus ajustes ya están en este dispositivo.';
}

// Path: transfer.pairing
class _Translations$transfer$pairing$es extends Translations$transfer$pairing$en {
	_Translations$transfer$pairing$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get noCamera => '¿Sin cámara? Elige allí Escribir el código e introduce:';
	@override String get qrLabel => 'Código para escanear desde el otro dispositivo';
	@override String get cameraOff => 'La cámara está desactivada para esta app. Escribe el código o permite la cámara en los ajustes del móvil.';
	@override String get cameraFailed => 'No se pudo iniciar la cámara. Escribe el código.';
	@override String get foreign => 'Ese código no es de esta app.';
	@override String get checkEntry => 'Comprueba la dirección (como 192.168.1.20:41234) y el código de 16 caracteres.';
	@override String get address => 'Dirección';
	@override String get code => 'Código';
}

// Path: transfer.pane
class _Translations$transfer$pane$es extends Translations$transfer$pane$en {
	_Translations$transfer$pane$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get explain => 'Copia tus fuentes, claves y preferencias a otro dispositivo de la misma red Wi-Fi, para no tener que volver a escribirlas. Va directamente de un dispositivo al otro, cifrado con un código que solo comparten las dos pantallas, y el dispositivo que recibe pregunta antes de guardar nada.';
	@override String get notCopied => 'No se copia: Plex (vincúlalo en el otro dispositivo con su propio código), el historial, los favoritos, ni el consentimiento que diste para Fuentes avanzadas y Funciones de IA, que cada dispositivo pide por su cuenta.';
	@override String get receive => 'Recibir de otro dispositivo';
	@override String get send => 'Enviar a otro dispositivo';
}

// Path: transfer.notes
class _Translations$transfer$notes$es extends Translations$transfer$notes$en {
	_Translations$transfer$notes$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get aiLocal => 'Tu proveedor de IA funciona en este dispositivo, así que no se envía. Vuelve a configurarlo allí con la dirección de este dispositivo en tu red.';
	@override String get xtreamHidden => 'Las cuentas de IPTV se han guardado pero están ocultas. Activa Fuentes avanzadas en Ajustes para usarlas.';
	@override String get aiAsks => 'Las funciones de IA preguntarán antes de enviar nada al proveedor.';
	@override String partial({required Object failed}) => 'No se pudo guardar: ${failed}. El resto se guardó.';
}

// Path: transfer.send
class _Translations$transfer$send$es extends Translations$transfer$send$en {
	_Translations$transfer$send$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String cannotRead({required Object error}) => 'No se pudieron leer los ajustes de este dispositivo: ${error}';
	@override String askTitle({required Object host}) => '¿Enviar a ${host}?';
	@override String askBody({required Object summary}) => 'Un dispositivo de tu red ha escaneado este código y pide:\n\n${summary}\n\nAcepta solo si acabas de pedirlo en ese dispositivo.';
	@override String get notNow => 'Ahora no';
	@override String get send => 'Enviar';
	@override String get title => 'Enviar ajustes';
	@override String get reading => 'Leyendo tus ajustes…';
	@override String get sending => 'Enviando. El otro dispositivo preguntará antes de guardar nada.';
	@override String get explain => 'Copia esto a otro dispositivo de la misma red Wi-Fi, para no tener que volver a escribirlo. Va directamente allí y cifrado; nada pasa por nosotros.';
	@override String get nothing => 'Aún no hay nada configurado en este dispositivo que enviar.';
	@override String get proceed => 'Continuar';
	@override String get showInstead => 'Mostrar un código';
	@override String get typeInstead => 'Escribir el código';
	@override String get scanInstructions => 'En el otro dispositivo, abre Ajustes, Pasar a otro dispositivo, y elige Recibir. Apunta la cámara al código que muestre.';
	@override String get showInstructions => 'En el otro dispositivo, abre Ajustes, Pasar a otro dispositivo, y elige Recibir y después Escanear su código, y apunta su cámara aquí. Se te preguntará antes de enviar nada.';
	@override String get typeInstructions => 'En el otro dispositivo, abre Ajustes, Pasar a otro dispositivo, y elige Recibir. Luego introduce lo que muestre.';
	@override String get sent => 'Enviado. El otro dispositivo ha guardado tus ajustes.';
}

// Path: transfer.item
class _Translations$transfer$item$es extends Translations$transfer$item$en {
	_Translations$transfer$item$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get preferences => 'Preferencias';
	@override String get preferencesSub => 'Opciones de reproducción y subtítulos, palabras ocultas y ubicación en la biblioteca.';
	@override String get xtream => 'Cuentas de IPTV';
	@override String get xtreamSub => 'Inicios de sesión y las categorías y canales que elegiste.';
	@override String get smb => 'Recursos de red';
	@override String get smbSub => 'Recursos SMB y sus contraseñas.';
	@override String get tmdb => 'Clave de TMDB';
	@override String get tmdbSub => 'Tu propia clave para los filtros de género, valoración e idioma.';
	@override String get ai => 'Proveedor de IA';
	@override String get aiSub => 'El proveedor, su modelo y tu clave.';
	@override String settings({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${n} ajuste',
		other: '${n} ajustes',
	);
	@override String accounts({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${n} cuenta',
		other: '${n} cuentas',
	);
	@override String shares({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${n} recurso',
		other: '${n} recursos',
	);
	@override String get notBundle => 'Eso no era un paquete de ajustes.';
	@override String get newer => 'Ese paquete es de una versión más reciente de la app. Actualiza este dispositivo e inténtalo de nuevo.';
	@override String get trackers => 'Seguimiento de lo visto';
	@override String get trackersSub => 'Tus inicios de sesión en Trakt, Simkl, AniList y MyAnimeList. Aceptarlos aquí es aceptar enviar también lo que veas en este dispositivo.';
	@override String services({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${n} servicio',
		other: '${n} servicios',
	);
}

// Path: transfer.client
class _Translations$transfer$client$es extends Translations$transfer$client$en {
	_Translations$transfer$client$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get declined => 'El otro dispositivo no aceptó los ajustes.';
	@override String get wrongCode => 'El código no era correcto. Compruébalo con la otra pantalla.';
	@override String get used => 'El otro dispositivo ya recibió algo. Vuelve a abrir Recibir allí para obtener un código nuevo.';
	@override String get tooBig => 'Era demasiado para enviar.';
	@override String get unreadable => 'El otro dispositivo no pudo leerlo.';
	@override String unexpected({required Object status}) => 'El otro dispositivo respondió de forma inesperada (${status}).';
	@override String get refusedToSend => 'El otro dispositivo no aceptó enviar sus ajustes.';
	@override String get busy => 'El otro dispositivo ya está atendiendo a otro. Pídele un código nuevo.';
	@override String unreachable({required Object address}) => 'No se pudo contactar con ${address}. Los dos dispositivos deben estar en la misma red Wi-Fi, y el otro tiene que seguir mostrando su código.';
	@override String get dropped => 'La conexión se cortó a medias.';
	@override String noAnswer({required Object address}) => 'Sin respuesta de ${address}. Revisa la otra pantalla.';
}

// Path: mediaBrowser.errors
class _Translations$mediaBrowser$errors$es extends Translations$mediaBrowser$errors$en {
	_Translations$mediaBrowser$errors$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String signedOut({required Object server}) => '${server} ya no acepta este inicio de sesión. Quítalo en Ajustes, Fuentes y vuelve a añadirlo.';
	@override String status({required Object server, required Object code}) => '${server} respondió ${code}.';
	@override String unreachable({required Object server}) => 'No se pudo contactar con ${server}. Puede que esté en reposo o fuera de la red.';
	@override String get notAServer => 'Ningún servidor Jellyfin o Emby respondió en esa dirección. Compruébala, incluido el puerto (normalmente 8096).';
	@override String get badAnswer => 'El servidor respondió de una forma que esta app no entiende.';
	@override String get wrongLogin => 'Usuario o contraseña incorrectos.';
}

// Path: trackers.errors
class _Translations$trackers$errors$es extends Translations$trackers$errors$en {
	_Translations$trackers$errors$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String unavailable({required Object service}) => 'No se pudo contactar con ${service}. Se volverá a intentar.';
	@override String get denied => 'Se rechazó el inicio de sesión.';
	@override String get expired => 'Ese código ha caducado. Vuelve a empezar para obtener uno nuevo.';
	@override String get badPaste => 'Eso no es lo que dio la página de inicio de sesión. Vuelve a copiarlo y pégalo entero.';
}

// Path: seerr.errors
class _Translations$seerr$errors$es extends Translations$seerr$errors$en {
	_Translations$seerr$errors$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get notASeerr => 'Ningún servidor Overseerr, Jellyseerr o Seerr respondió en esa dirección. Compruébala, incluido el puerto (normalmente 5055).';
	@override String get behindAccess => 'Esa dirección está detrás de Cloudflare Access, que envía la app a una página de inicio de sesión que no puede usar. Quien la gestiona puede añadir una política de Access que omita /api/*, ya que Seerr ya pide iniciar sesión.';
	@override String get badKey => 'El servidor no aceptó esa clave de API.';
	@override String get refused => 'El servidor no aceptó ese inicio de sesión.';
	@override String status({required Object code}) => 'El servidor respondió ${code}.';
	@override String get unreachable => 'No se pudo contactar con el servidor de solicitudes.';
	@override String get signedOut => 'El servidor de solicitudes ya no acepta este inicio de sesión. Vuelve a conectarlo en Ajustes, Solicitudes.';
	@override String get alreadyRequested => 'Eso ya se ha solicitado.';
}

// Path: settings.metadata.errors
class _Translations$settings$metadata$errors$es extends Translations$settings$metadata$errors$en {
	_Translations$settings$metadata$errors$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get rejected => 'TMDB rechazó esa clave.';
	@override String get rateLimited => 'TMDB está limitando las solicitudes de este dispositivo.';
	@override String unreachable({required Object type}) => 'No se pudo contactar con TMDB (${type}).';
}

// Path: settings.appearance.palette
class _Translations$settings$appearance$palette$es extends Translations$settings$appearance$palette$en {
	_Translations$settings$appearance$palette$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get system => 'Sistema';
	@override String get midnight => 'Medianoche';
	@override String get slate => 'Pizarra';
	@override String get daylight => 'Día';
	@override String get amber => 'Ámbar';
}

/// The flat map containing all translations for locale <es>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEs {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'common.back' => 'Atrás',
			'common.tryAgain' => 'Reintentar',
			'common.cancel' => 'Cancelar',
			'common.noDrm' => 'Sin DRM. No se pueden reproducir catálogos comerciales protegidos como Netflix o Disney+.',
			'player.shareGone' => 'Esa carpeta compartida ya no está configurada.',
			'player.shareFileGone' => 'Ese archivo ya no está en la carpeta compartida.',
			'player.deviceFileGone' => 'Ese archivo ya no está en este dispositivo.',
			'player.lineGone' => 'Esa suscripción ya no está configurada.',
			'player.untitledVideo' => 'Vídeo',
			'player.untitledEpisode' => 'Episodio',
			'player.untitledFilm' => 'Película',
			'player.untitledLive' => 'En directo',
			'player.channelFroze' => 'Este canal se detuvo y no ha vuelto.',
			'player.channelNotResponding' => 'Este canal no responde. Los proveedores suelen listar canales que no están emitiendo, así que prueba otro o vuelve a probar el mismo.',
			'player.didNotStart' => 'No ha empezado a reproducirse. Puede que el servidor esté ocupado o que el archivo necesite transcodificación, que aún no está disponible.',
			'player.released' => 'Se detuvo mientras la app estaba en segundo plano, así que la conexión queda libre para otros dispositivos.',
			'player.rejoin' => 'Volver a entrar',
			'player.live' => 'EN DIRECTO',
			'player.skipBack' => ({required Object seconds}) => 'Atrás ${seconds} segundos',
			'player.skipForward' => ({required Object seconds}) => 'Adelante ${seconds} segundos',
			'player.pause' => 'Pausa',
			'player.play' => 'Reproducir',
			'player.tracks' => 'Audio y subtítulos',
			'player.audio' => 'Audio',
			'player.subtitles' => 'Subtítulos',
			'player.off' => 'Desactivados',
			'player.trackNumber' => ({required Object n}) => 'Pista ${n}',
			'player.upNext.title' => 'A continuación',
			'player.upNext.playingIn' => ({required Object seconds}) => 'Se reproduce en ${seconds} s',
			'player.upNext.playNow' => 'Reproducir ahora',
			'languages.en' => 'Inglés',
			'languages.es' => 'Español',
			'languages.fr' => 'Francés',
			'languages.de' => 'Alemán',
			'languages.it' => 'Italiano',
			'languages.pt' => 'Portugués',
			'languages.nl' => 'Neerlandés',
			'languages.sv' => 'Sueco',
			'languages.no' => 'Noruego',
			'languages.da' => 'Danés',
			'languages.fi' => 'Finés',
			'languages.pl' => 'Polaco',
			'languages.cs' => 'Checo',
			'languages.hu' => 'Húngaro',
			'languages.ro' => 'Rumano',
			'languages.el' => 'Griego',
			'languages.ru' => 'Ruso',
			'languages.uk' => 'Ucraniano',
			'languages.tr' => 'Turco',
			'languages.ar' => 'Árabe',
			'languages.he' => 'Hebreo',
			'languages.hi' => 'Hindi',
			'languages.bn' => 'Bengalí',
			'languages.pa' => 'Panyabí',
			'languages.ta' => 'Tamil',
			'languages.te' => 'Telugu',
			'languages.ur' => 'Urdu',
			'languages.th' => 'Tailandés',
			'languages.vi' => 'Vietnamita',
			'languages.id' => 'Indonesio',
			'languages.zh' => 'Chino',
			'languages.ja' => 'Japonés',
			'languages.ko' => 'Coreano',
			'subtitleSize.small' => 'Pequeño',
			'subtitleSize.medium' => 'Mediano',
			'subtitleSize.large' => 'Grande',
			'units.minutes' => ({required Object m}) => '${m} min',
			'units.hours' => ({required Object h}) => '${h} h',
			'units.hoursMinutes' => ({required Object h, required Object m}) => '${h} h ${m} min',
			'units.minutesLeft' => ({required Object m}) => 'Quedan ${m} min',
			'units.seconds' => ({required Object s}) => '${s} s',
			'downloads.empty' => 'Aún no hay descargas. Mantén pulsada una película o un episodio de tu biblioteca de Plex y elige Descargar; luego míralo aquí sin conexión.',
			'downloads.title' => 'Descargas',
			'downloads.summary' => ({required num n, required Object size}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${n} elemento · ${size} en este dispositivo', other: '${n} elementos · ${size} en este dispositivo', ), 
			'downloads.pendingWatches' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '1 visionado de aquí está pendiente de enviarse a Plex.', other: '${n} visionados de aquí están pendientes de enviarse a Plex.', ), 
			'downloads.foregroundOnly' => 'Las descargas continúan mientras la app está abierta. Al cerrarla se pausan, y no se pierde nada de lo ya guardado.',
			'downloads.downloadingBytes' => ({required Object received}) => 'Descargando, ${received}',
			'downloads.downloadingPercent' => ({required Object percent, required Object received, required Object total}) => 'Descargando ${percent} % · ${received} de ${total}',
			'downloads.queued' => 'Esperando su turno',
			'downloads.paused' => 'En pausa',
			'downloads.pausedAt' => ({required Object percent}) => 'En pausa al ${percent} % · selecciona para reanudar',
			'downloads.failed' => ({required Object error}) => '${error} Selecciona para reintentar.',
			'downloads.failedUnknown' => 'No terminó.',
			'downloads.deleteTitle' => '¿Eliminar esta descarga?',
			'downloads.cancelTitle' => '¿Cancelar esta descarga?',
			'downloads.removeBody' => ({required Object title}) => 'Se eliminará «${title}» de este dispositivo. Seguirá en tu servidor Plex.',
			'downloads.removeBodyFreeing' => ({required Object title, required Object size}) => 'Se eliminará «${title}» de este dispositivo y se liberarán ${size}. Seguirá en tu servidor Plex.',
			'downloads.keepIt' => 'Conservarla',
			'downloads.delete' => 'Eliminar',
			'downloads.errors.serverNotConnected' => 'Ese servidor no está conectado. Vuelve a conectarlo en Ajustes y reanuda.',
			'downloads.errors.sizeMismatch' => 'El archivo no coincide con el tamaño que indicó el servidor. Inténtalo de nuevo.',
			'downloads.errors.cannotWrite' => 'No se pudo escribir el archivo. Puede que el dispositivo no tenga espacio.',
			'downloads.errors.changedOnServer' => 'El archivo cambió en el servidor. Vuelve a empezar la descarga.',
			'downloads.errors.refused' => 'El servidor no permite que este dispositivo lo descargue.',
			'downloads.errors.status' => ({required Object code}) => 'El servidor respondió ${code}.',
			'downloads.errors.dropped' => 'La conexión se cortó a medias. Reanuda para continuar.',
			'downloads.errors.unreachable' => 'No se pudo contactar con el servidor. Comprueba la conexión y reanuda.',
			'downloads.errors.timeout' => 'El servidor tardó demasiado en responder.',
			'downloads.rule.off' => 'Mantener episodios descargados',
			'downloads.rule.keeping' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: 'Se mantiene descargado el siguiente episodio', other: 'Se mantienen descargados los ${n} siguientes episodios', ), 
			'downloads.rule.explain' => 'Descarga los siguientes episodios sin ver y los repone a medida que los ves, mientras la app está abierta. Se eliminan los que descargó y ya has visto.',
			'downloads.rule.choiceOff' => 'Desactivado',
			'downloads.rule.choice' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: 'Siguiente episodio', other: '${n} siguientes episodios', ), 
			'watchActions.everyEpisode' => ' (todos los episodios)',
			'watchActions.markWatched' => ({required Object scope}) => 'Marcar como visto${scope}',
			'watchActions.markUnwatched' => ({required Object scope}) => 'Marcar como no visto${scope}',
			'watchActions.download' => 'Descargar en este dispositivo',
			'watchActions.deleteDownload' => 'Eliminar descarga',
			'watchActions.cancelDownload' => 'Cancelar descarga',
			'watchActions.removeFavourite' => 'Quitar de favoritos',
			'watchActions.addFavourite' => 'Añadir a favoritos',
			'watchActions.removeResume' => 'Quitar de Seguir viendo',
			'watchActions.downloading' => 'Descargando. Consulta la pestaña Descargas.',
			'watchActions.markedOffline' => 'Marcado como visto aquí. Se avisará a Plex cuando se pueda contactar con él.',
			'watchActions.plexRefused' => 'Plex no lo aceptó. Puede que el servidor esté desconectado.',
			'watchActions.details' => 'Detalles',
			'show.noEpisodes' => 'Esta serie no tiene episodios en el servidor.',
			'shell.library' => 'Biblioteca',
			'shell.search' => 'Buscar',
			'shell.downloads' => 'Descargas',
			'shell.settings' => 'Ajustes',
			'shell.exitTitle' => '¿Salir de Subnext Player?',
			'shell.exit' => 'Salir',
			'shell.stay' => 'Quedarse',
			'resume.upNext' => 'A continuación',
			'resume.title' => 'Seguir viendo',
			'resume.remove' => 'Quitar de Seguir viendo',
			'library.placement.movies' => 'Películas',
			'library.placement.series' => 'Series',
			'library.placement.hidden' => 'Oculto',
			'library.tab.movies' => 'Películas',
			'library.tab.series' => 'Series',
			'library.tab.localNetwork' => 'Local y red',
			'library.tab.liveTv' => 'TV en directo',
			'library.tab.emptyMovies' => 'No hay películas en este servidor.',
			'library.tab.emptySeries' => 'No hay series en este servidor.',
			'library.tab.emptyLocalNetwork' => 'Aún no hay carpetas ni recursos de red.\nEl almacenamiento del dispositivo y las carpetas SMB no se pueden conectar en esta versión.',
			'library.tab.emptyLiveTv' => 'Aún no hay ninguna suscripción de IPTV.\nAñade una desde Añadir fuente.',
			'library.tab.countMovies' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${n} película', other: '${n} películas', ), 
			'library.tab.countSeries' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${n} serie', other: '${n} series', ), 
			'library.tab.countItems' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${n} elemento', other: '${n} elementos', ), 
			'library.tab.countChannels' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${n} canal', other: '${n} canales', ), 
			'library.serverTimeout' => ({required Object server, required Object seconds}) => '${server} no respondió en ${seconds} segundos. Puede que esté en reposo o fuera de la red.',
			'library.allWatched' => 'Ya has visto todo lo de Películas.',
			'library.showAll' => 'Mostrar todo',
			'library.noSources' => 'Aún no hay fuentes conectadas.',
			'library.nothingIn' => ({required Object tab}) => 'Aún no hay nada en ${tab}.',
			'library.addSource' => 'Añadir una fuente',
			'library.sortFiltered' => ({required Object sort}) => '${sort} · Sin ver',
			'library.sortBy' => 'Ordenar por',
			'library.unwatchedOnly' => 'Solo sin ver',
			'library.shelf.seeAll' => 'Ver todo',
			'library.shelf.titles' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${n} título', other: '${n} títulos', ), 
			'library.shelf.gone' => 'Aquí ya no hay nada.',
			'library.sort.title' => 'Título',
			'library.sort.recentlyAdded' => 'Añadido recientemente',
			'library.sort.year' => 'Año',
			'library.sort.releaseDate' => 'Fecha de estreno',
			'library.tile.series' => 'Serie',
			'library.tile.movie' => 'Película',
			'library.tile.watched' => 'Visto',
			'library.tile.percentWatched' => ({required Object percent}) => '${percent} % visto',
			'library.tile.unwatchedEpisodes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${n} episodio sin ver', other: '${n} episodios sin ver', ), 
			'liveTv.group.favourites' => 'Favoritos',
			'liveTv.group.numbered' => ({required Object n}) => 'Categoría ${n}',
			'liveTv.group.other' => 'Otros',
			'liveTv.noPanel' => 'Aún no hay ninguna suscripción de IPTV.',
			'liveTv.addOne' => 'Añadir uno',
			'liveTv.noCategories' => 'Aún no has elegido canales.\nTu proveedor tiene decenas de miles, así que Subnext Player solo carga los que eliges.',
			'liveTv.chooseCategories' => 'Elegir categorías',
			'liveTv.noChannels' => 'Esas categorías no devolvieron canales.',
			'liveTv.refresh' => 'Actualizar canales',
			'liveTv.refreshFailed' => 'No se pudo actualizar la lista de canales. Se muestra la anterior.',
			'liveTv.noMatch' => ({required Object query}) => 'Ningún canal coincide con «${query}».',
			'liveTv.searchHint' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: 'Buscar en ${n} canal', other: 'Buscar en ${n} canales', ), 
			'liveTv.all' => 'Todos',
			'ai.picks.yourProvider' => 'tu proveedor',
			'ai.picks.ask' => '¿Qué veo?',
			'ai.picks.askExplain' => ({required Object provider}) => 'Pide a ${provider} que elija de tu propia biblioteca.',
			'ai.picks.pickedBy' => 'Elegido para ti por ',
			'ai.picks.updating' => 'Actualizando',
			'ai.picks.again' => 'Otra vez',
			'ai.picks.preparing' => 'Preparando tus sugerencias...',
			'ai.search.asking' => ({required Object provider}) => 'Preguntando a ${provider}...',
			'ai.search.searching' => ({required Object searched, required Object covered}) => 'Buscando en tu biblioteca... ${searched} de ${covered} títulos',
			'ai.search.emptyLibrary' => 'Aún no hay nada en tu biblioteca en lo que buscar.',
			'ai.search.notFound' => ({required Object total}) => 'El modelo no encontró nada que encaje entre ${total} títulos. Prueba a describirlo de otra forma.',
			'ai.search.notFoundFirst' => ({required Object covered, required Object total}) => 'El modelo no encontró nada que encaje entre los primeros ${covered} de ${total} títulos. Prueba a describirlo de otra forma.',
			'ai.search.stillSearching' => ({required Object searched, required Object covered}) => 'Todavía buscando: ${searched} de ${covered} títulos',
			'ai.search.searchedFirst' => ({required Object covered, required Object total}) => 'Se buscó en los primeros ${covered} de ${total} títulos',
			'ai.search.pickedFor' => ({required Object provider, required Object query}) => 'Elegido por ${provider} para «${query}»',
			'ai.search.searchAgain' => 'Buscar de nuevo',
			'ai.search.partsFailed' => ({required Object failed, required Object parts}) => 'No se pudieron buscar ${failed} de ${parts} partes, así que parte de tu biblioteca no se revisó. Puede que el proveedor esté limitando las solicitudes',
			'ai.presetOther' => 'Otro',
			'ai.hintOpenRouter' => 'Los identificadores de modelo están en openrouter.ai/models. Los gratuitos terminan en ":free".',
			'ai.hintOllama' => 'Usa la dirección de tu ordenador en esta red, por ejemplo http://192.168.1.20:11434/v1. Nada sale de tu red.',
			'ai.hintCustom' => 'Cualquier servicio que use el formato de chat de OpenAI.',
			'ai.feature.naturalSearch' => 'Búsqueda en lenguaje natural',
			'ai.feature.naturalSearchSends' => 'El texto que buscas, y los títulos y años de tu biblioteca.',
			'ai.feature.naturalSearchTiming' => 'Una biblioteca grande se envía en varias solicitudes de unos cientos de títulos cada una, así que una búsqueda hace más de una.',
			'ai.feature.recommendations' => 'Recomendaciones',
			'ai.feature.recommendationsSends' => 'Las películas que has visto recientemente, y los títulos y años de lo que aún no has visto en tu biblioteca.',
			'ai.feature.recommendationsTiming' => 'Las sugerencias se preparan en segundo plano poco después de abrir la app, pero solo cuando ha cambiado lo que has visto o tienen más de un día, así que no hay una solicitud en cada inicio.',
			'ai.errors.ranOutThinking' => 'El modelo se quedó sin espacio de respuesta mientras pensaba y nunca dio una respuesta. Funcionará mejor un modelo que no «piense» antes.',
			'ai.errors.empty' => 'El modelo devolvió una respuesta vacía.',
			'ai.errors.rejectedKey' => ({required Object suffix}) => 'El proveedor rechazó esa clave${suffix}.',
			'ai.errors.noCredit' => ({required Object suffix}) => 'El proveedor dice que esta cuenta no tiene crédito${suffix}.',
			'ai.errors.unknownModel' => ({required Object suffix}) => 'El proveedor no conoce ese modelo o esa dirección${suffix}.',
			'ai.errors.rateLimited' => ({required Object suffix}) => 'El proveedor está limitando esta clave. Inténtalo dentro de un momento${suffix}.',
			'ai.errors.serverError' => ({required Object status, required Object suffix}) => 'El proveedor tuvo un problema (HTTP ${status})${suffix}.',
			'ai.errors.timeout' => 'El proveedor tardó demasiado en responder.',
			'ai.errors.unreachable' => 'No se pudo contactar con el proveedor. Comprueba la dirección.',
			'ai.errors.failed' => ({required Object suffix}) => 'La solicitud falló${suffix}.',
			'ai.errors.failedStatus' => ({required Object status, required Object suffix}) => 'La solicitud falló (HTTP ${status})${suffix}.',
			'ai.errors.fillIn' => 'Rellena la dirección y el modelo.',
			'ai.errors.needsKey' => 'Este proveedor necesita una clave de API.',
			'ai.errors.notSetUp' => 'No hay ningún proveedor de IA configurado.',
			'ai.errors.searchOff' => 'La búsqueda en lenguaje natural está desactivada para este proveedor.',
			'ai.errors.searchFailed' => 'La búsqueda falló.',
			'ai.errors.noSignal' => 'Mira antes una película, para que haya algo en lo que basar las sugerencias.',
			'ai.errors.noPicks' => 'Esta vez el modelo no eligió nada.',
			'ai.consentTitle' => ({required Object provider}) => '¿Enviar datos a ${provider}?',
			'ai.consentBody' => ({required Object feature, required Object provider, required Object sends}) => '${feature} enviará esto a ${provider}: ${sends}',
			'ai.consentTail' => 'Va directamente de este dispositivo a ellos, nunca a través de nosotros. Puedes volver a desactivarlo en Ajustes, Funciones de IA.',
			'ai.notNow' => 'Ahora no',
			'ai.allow' => 'Permitir',
			'search.filters.decadeOldest' => ({required Object decade}) => 'Años ${decade} y anteriores',
			'search.filters.decade' => ({required Object decade}) => 'Años ${decade}',
			'search.filters.type' => 'Tipo',
			'search.filters.movies' => 'Películas',
			'search.filters.series' => 'Series',
			'search.filters.source' => 'Fuente',
			'search.filters.unknownSource' => 'Fuente desconocida',
			'search.filters.year' => 'Año',
			'search.filters.language' => 'Idioma',
			'search.filters.languageNote' => 'Deducido de los nombres de las categorías de IPTV. Los títulos de Plex no tienen idioma aquí.',
			'search.filters.genre' => 'Género',
			'search.filters.rating' => 'Valoración',
			'search.filters.ratingNote' => 'Valoración de los usuarios de TMDB sobre 10. Se excluyen los títulos sin valoración en TMDB.',
			'search.filters.originalLanguage' => 'Idioma original',
			'search.filters.originalLanguageNote' => 'El idioma en que se rodó el título, según TMDB. Una copia doblada conserva aquí su idioma original.',
			'search.filters.clear' => 'Borrar',
			'search.filters.noMatches' => 'Nada coincide con esos filtros.',
			'search.filters.clearAll' => 'Borrar filtros',
			'search.filters.chip' => ({required Object label, required Object value}) => '${label}: ${value}',
			'search.filters.any' => 'Cualquiera',
			'search.hint' => 'Busca en tus fuentes',
			'search.prompt' => 'Busca películas y series en tu servidor.',
			'search.keepTyping' => 'Sigue escribiendo…',
			'search.noMatch' => ({required Object query}) => 'Nada coincide con «${query}».',
			'search.backToResults' => 'Volver a los resultados',
			'search.askAi' => 'Preguntar a la IA',
			'search.becauseYouWatched' => 'Porque viste ',
			'settings.about.versionLoading' => 'Versión …',
			'settings.about.version' => ({required Object version, required Object build}) => 'Versión ${version} (${build})',
			'settings.about.privacyPolicy' => 'Política de privacidad',
			'settings.about.privacySummary' => 'Sin cuenta, sin servidor propio y sin analíticas. La política completa está en:',
			'settings.about.licences' => 'Licencias de código abierto',
			'settings.privacy.summary' => 'Subnext Player no tiene servidor propio ni analíticas. Lo que guarda está en este dispositivo, y los únicos sitios a los que se envían datos son las fuentes, TMDB y el proveedor de IA que tú mismo conectas.',
			'settings.privacy.cachedData' => 'Datos en caché',
			'settings.privacy.cachedExplain' => 'Las listas de tu biblioteca, las consultas a TMDB y las sugerencias de la IA se guardan para que la app abra rápido. Las antiguas se borran solas, a los 30 días las de una biblioteca y a los 90 las de una consulta, y los datos de una fuente desaparecen al quitarla. Borrar ahora no toca tus fuentes, claves, ajustes ni historial, y todo se vuelve a obtener cuando haga falta.',
			'settings.privacy.clearing' => 'Borrando...',
			'settings.privacy.clear' => 'Borrar datos en caché',
			'settings.privacy.cleared' => 'Borrado. Tu biblioteca se está volviendo a cargar.',
			'settings.playback.skip' => 'Saltar atrás y adelante',
			'settings.playback.skipExplain' => 'Los botones de salto, las teclas de avance y retroceso de un mando, y el primer paso al moverse por la barra de progreso.',
			'settings.playback.audioLanguage' => 'Idioma de audio preferido',
			'settings.playback.audioLanguageExplain' => 'Se usa cuando un archivo tiene más de una pista de audio. Si no, suena la pista predeterminada del archivo.',
			'settings.playback.fileDefault' => 'Predeterminado del archivo',
			'settings.playback.showSubtitles' => 'Mostrar subtítulos',
			'settings.playback.showSubtitlesExplain' => 'Actívalos cuando un archivo los tenga. Siempre puedes cambiarlos en el reproductor.',
			'settings.playback.subtitleLanguage' => 'Idioma de subtítulos preferido',
			'settings.playback.subtitleLanguageExplain' => 'Si un archivo no tiene subtítulos en este idioma, no se muestra ninguno.',
			'settings.playback.any' => 'Cualquiera',
			'settings.playback.size' => 'Tamaño',
			'settings.playback.sizeExplain' => 'Para subtítulos de texto, como SRT y ASS.',
			'settings.metadata.consent' => 'Esto consulta en TMDB la fecha de estreno de cada película y serie de tu biblioteca, en segundo plano y unas pocas cada vez. Para ello envía el título (y el año, si lo hay) de cada una desde este dispositivo a TMDB, y a nadie más, no solo las que buscas. También rellena el género y la valoración para los filtros. Los resultados se guardan en este dispositivo durante 90 días, y no se vuelve a preguntar por los títulos ya consultados.\n\nPuedes desactivarlo cuando quieras. Al quitar tu clave de TMDB también se desactiva.',
			'settings.metadata.consentTitle' => '¿Enviar los títulos de tu biblioteca a TMDB?',
			'settings.metadata.notNow' => 'Ahora no',
			'settings.metadata.lookThemUp' => 'Consultarlas',
			'settings.metadata.waiting' => 'Esperando a que se cargue tu biblioteca.',
			'settings.metadata.stopped' => 'En pausa: TMDB dejó de responder. Continuará la próxima vez que se abra la app, y se conserva lo que encontró.',
			'settings.metadata.running' => ({required Object settled, required Object total}) => 'Consultados ${settled} de ${total} títulos.',
			'settings.metadata.partial' => ({required Object settled, required Object total}) => 'Consultados ${settled} de ${total} títulos. El resto continuará la próxima vez que se abra la app.',
			'settings.metadata.done' => ({required Object found, required Object total}) => 'Listo: se encontraron ${found} fechas de estreno para ${total} títulos.',
			'settings.metadata.releaseDates' => 'Fechas de estreno de tu biblioteca',
			'settings.metadata.releaseDatesExplain' => 'Añade fechas de estreno exactas en segundo plano, para que Ordenar por fecha de estreno ordene bien tu biblioteca, incluidos los títulos sin año. Envía todos los títulos de tu biblioteca a TMDB.',
			'settings.metadata.intro' => 'Conecta tu propia clave de TMDB para añadir género, valoración e idioma original a los resultados de búsqueda, y sugerencias basadas en lo que has visto. Es opcional, y nada cambia hasta que añadas una.',
			'settings.metadata.keyExplain' => 'Los títulos que se consultan se envían desde este dispositivo a TMDB, y a nadie más. Crea una clave gratuita en tu cuenta de TMDB, en Ajustes, API. Sirve tanto la clave corta como el token de acceso de lectura largo. En una TV es más fácil pegarla o escribirla primero en un móvil o un ordenador.',
			'settings.metadata.keySaved' => 'Clave de TMDB guardada',
			'settings.metadata.removeKey' => 'Quitar clave',
			'settings.metadata.keyLabel' => 'Clave de API de TMDB',
			'settings.metadata.checking' => 'Comprobando...',
			'settings.metadata.verify' => 'Verificar y guardar',
			'settings.metadata.errors.rejected' => 'TMDB rechazó esa clave.',
			'settings.metadata.errors.rateLimited' => 'TMDB está limitando las solicitudes de este dispositivo.',
			'settings.metadata.errors.unreachable' => ({required Object type}) => 'No se pudo contactar con TMDB (${type}).',
			'settings.ai.intro' => 'Conecta tu propio proveedor y tu propia clave. Las solicitudes van directamente de este dispositivo al proveedor que elijas, nunca a través de nosotros, porque no hay ningún servidor nuestro en medio. No se envía nada hasta que permitas una de las funciones de abajo.',
			'settings.ai.address' => 'Dirección',
			'settings.ai.model' => 'Modelo',
			'settings.ai.keyOptional' => 'Clave de API (opcional para un servidor local)',
			'settings.ai.key' => 'Clave de API',
			'settings.ai.trying' => 'Probando...',
			'settings.ai.testAndSave' => 'Probar y guardar',
			'settings.ai.onNetwork' => 'En tu red',
			'settings.ai.keySaved' => 'Clave guardada',
			'settings.ai.remove' => 'Quitar proveedor',
			'settings.ai.maySend' => 'Qué puede enviar',
			'settings.ai.localNoConsent' => 'Este proveedor está en tu propia red, así que nada llega a terceros y no hace falta consentimiento.',
			'settings.ai.sendsTo' => ({required Object provider, required Object sends}) => 'Envía a ${provider}: ${sends}',
			'settings.ai.allowedOn' => ({required Object date}) => 'Permitido el ${date}',
			'settings.ai.notAllowed' => 'Aún no está permitido. Se te preguntará la primera vez.',
			'settings.ai.switchOff' => 'Desactivar',
			'settings.ai.allow' => 'Permitir',
			'settings.appearance.palette.system' => 'Sistema',
			'settings.appearance.palette.midnight' => 'Medianoche',
			'settings.appearance.palette.slate' => 'Pizarra',
			'settings.appearance.palette.daylight' => 'Día',
			'settings.appearance.palette.amber' => 'Ámbar',
			'settings.appearance.theme' => 'Tema',
			'settings.appearance.accent' => 'Color de acento',
			'settings.section.sources' => 'Fuentes',
			'settings.section.appearance' => 'Apariencia',
			'settings.section.playback' => 'Reproducción',
			'settings.section.subtitles' => 'Subtítulos',
			'settings.section.metadata' => 'Metadatos',
			'settings.section.aiFeatures' => 'Funciones de IA',
			'settings.section.advancedSources' => 'Fuentes avanzadas',
			'settings.section.transfer' => 'Pasar a otro dispositivo',
			'settings.section.privacy' => 'Privacidad y datos',
			'settings.section.about' => 'Acerca de',
			'settings.section.trackers' => 'Seguimiento de lo visto',
			'settings.section.requests' => 'Solicitudes',
			'settings.advanced.dialogTitle' => 'Antes de activar la TV en directo',
			'settings.advanced.dialogLead' => 'Vas a conectar un proveedor externo con tus propias credenciales.',
			'settings.advanced.dialogNoContent' => 'Subnext Player no proporciona, aloja ni respalda ningún contenido ni proveedor. Tú indicas la dirección y el inicio de sesión, y la app reproduce lo que devuelva esa dirección.',
			'settings.advanced.dialogRights' => 'Eres responsable de tener los derechos de aquello a lo que te conectes.',
			'settings.advanced.dialogLogin' => 'Se guarda en el almacenamiento seguro de este dispositivo y solo se envía a la dirección que indiques.',
			'settings.advanced.pointNoContent' => 'No ofrecemos ni recomendamos ningún proveedor',
			'settings.advanced.pointRights' => 'Los derechos son cosa tuya',
			'settings.advanced.pointLogin' => 'Tu inicio de sesión se queda en este dispositivo',
			'settings.advanced.dialogConfirm' => 'Lo entiendo, activar',
			'settings.advanced.toggle' => 'TV en directo de una suscripción de IPTV',
			'settings.advanced.toggleExplain' => 'Añade la pestaña TV en directo y las suscripciones de IPTV en Añadir fuente.',
			'settings.advanced.offKeeps' => 'Si lo desactivas más tarde, se oculta la TV en directo, pero se conservan tus suscripciones.',
			'settings.sources.noServers' => 'No hay servidores Plex conectados.',
			'settings.sources.remove' => 'Quitar',
			'settings.sources.loadFailed' => ({required Object error}) => 'No se pudieron cargar las bibliotecas de este servidor.\n\n${error}',
			'settings.sources.lookForMore' => 'Buscar más servidores',
			'settings.sources.addAnother' => 'Añadir otro servidor',
			'settings.sources.yours' => 'Tuyo',
			'settings.sources.shared' => 'Compartido contigo',
			'settings.sources.viaRelay' => 'mediante relé',
			'settings.sources.plexType' => ({required Object type}) => 'Tipo en Plex: ${type}',
			'settings.sources.changedByYou' => 'cambiado por ti',
			'settings.sources.localTab' => 'Mostrar Local y red',
			'settings.sources.localTabSub' => 'Una pestaña en Inicio para vídeos de este dispositivo y de carpetas de red. Se activa sola cuando añades una.',
			'onboarding.tagline' => 'Reproduce desde las fuentes que conectas.',
			'onboarding.blurb' => 'Subnext Player reproduce desde fuentes que conectas tú: un servidor Plex, un NAS doméstico o archivos locales, u opcionalmente un proveedor o una lista de IPTV. No alojamos ningún contenido.',
			'onboarding.localDesktop' => 'Archivos de este PC, o una carpeta de un NAS doméstico o un recurso SMB.',
			'onboarding.localTv' => 'Una carpeta de un NAS doméstico o un recurso SMB.',
			'onboarding.local' => 'Vídeos de este dispositivo, o una carpeta de un NAS doméstico o un recurso SMB.',
			'onboarding.plexTv' => 'Inicia sesión con tu propia cuenta en esta TV.',
			'onboarding.plex' => 'Tu biblioteca personal, con tu propia cuenta.',
			'onboarding.advancedTv' => 'Desactivado por defecto. Actívalo en Ajustes.',
			'onboarding.advanced' => 'Desactivado por defecto. Actívalo desde Añadir fuente o Ajustes para usar una suscripción de IPTV.',
			'onboarding.localTitle' => 'Local y red',
			'onboarding.advancedTitle' => 'Fuentes avanzadas',
			'onboarding.addFirst' => 'Añade tu primera fuente',
			'onboarding.notNow' => 'Ahora no',
			'onboarding.connect' => 'Conecta una fuente',
			'onboarding.addSource' => 'Añadir fuente',
			'onboarding.okKey' => 'OK',
			'onboarding.toSelect' => 'para seleccionar',
			'addSource.privacy' => 'Las credenciales se quedan en este dispositivo. No se nos envía nada: no hay cuenta ni ningún servidor en medio.',
			'addSource.kind.plex' => 'Servidor Plex',
			'addSource.kind.plexShort' => 'Vincular con código',
			'addSource.kind.plexLong' => 'Aprueba este dispositivo en tu navegador. Tu propio servidor y todo lo que compartan contigo.',
			'addSource.kind.localFiles' => 'Vídeos de este dispositivo',
			'addSource.kind.localFilesSub' => 'Explora tu biblioteca multimedia o elige una carpeta concreta a la que mantener acceso.',
			'addSource.kind.localFilesIos' => 'Reproduce los vídeos de tu fototeca.',
			'addSource.kind.smb' => 'Recurso de red (SMB)',
			'addSource.kind.smbSub' => 'Un NAS o una carpeta compartida de Windows en tu red doméstica.',
			'addSource.kind.xtream' => 'Suscripción de IPTV',
			'addSource.kind.xtreamSub' => 'El enlace o el inicio de sesión que te envió tu proveedor. También se llama Xtream Codes.',
			'addSource.kind.mediaBrowser' => 'Servidor Jellyfin o Emby',
			'addSource.kind.mediaBrowserSub' => 'Tu propio servidor, con tu propia cuenta.',
			'addSource.copyFromDevice' => 'Copiar de otro dispositivo',
			'addSource.copyFromDeviceSub' => '¿Ya lo tienes configurado en el móvil? Envíalo aquí en vez de volver a escribirlo.',
			'addSource.title' => 'Añadir una fuente',
			'addSource.advanced' => 'Fuentes avanzadas',
			'addSource.or' => 'O',
			'addSource.advancedHint' => '¿Tienes una suscripción de IPTV?',
			'addSource.advancedSetUp' => 'Configurar TV en directo',
			'addSource.sourceType' => 'Tipo de fuente',
			'addSource.plexRail' => 'Vincular con un código',
			'addSource.pcFiles' => 'Archivos de este PC',
			'addSource.pcFilesSub' => 'Elige una carpeta',
			'addSource.smbRail' => 'NAS o carpeta compartida de Windows',
			'addSource.copyRail' => 'Envíalo desde tu móvil',
			'addSource.keystore' => 'Las credenciales se guardan en el almacén de claves del dispositivo, nunca en la base de datos de la app.',
			'addSource.pick' => 'Elige un tipo de fuente para empezar.',
			'plex.connected' => 'Plex conectado.',
			'plex.connectedTo' => ({required Object name}) => 'Conectado a ${name}.',
			'plex.opening' => 'Conectado. Abriendo tu biblioteca…',
			'plex.connect' => 'Conectar con Plex',
			'plex.explain' => 'Subnext Player reproduce lo que ya tiene tu propio servidor Plex. No se sube nada, y los datos de tu cuenta no llegan a nadie más que a Plex.',
			'plex.contacting' => 'Contactando con Plex…',
			'plex.enterCode' => 'En cualquier dispositivo, abre plex.tv/link e introduce:',
			'plex.waiting' => 'Esperando la aprobación…',
			'plex.copyCode' => 'Copiar código',
			'plex.chooseServer' => 'Elige un servidor',
			'plex.allConnected' => 'Todos los servidores de esta cuenta ya están conectados.',
			'plex.yourServers' => 'Tus servidores',
			'plex.sharedWithYou' => 'Compartidos contigo',
			'plex.connecting' => 'Conectando… puede tardar unos segundos',
			'plex.offline' => 'Sin conexión',
			'plex.relayOnly' => 'Solo mediante Plex Relay, la reproducción puede verse limitada',
			'plex.codeExpired' => 'Ese código ha caducado. Inténtalo de nuevo.',
			'plex.noServers' => 'Esa cuenta no tiene servidores Plex.',
			'plex.errors.noAnswer' => ({required Object server, required Object count}) => '«${server}» no respondió en ninguna de sus ${count} direcciones anunciadas.',
			'plex.errors.itemGone' => 'Ese elemento ya no está en el servidor.',
			'plex.errors.noFile' => 'Este elemento no tiene ningún archivo reproducible. Las fuentes que solo admiten transcodificación aún no están disponibles.',
			'plex.errors.notConnected' => 'No hay conexión con ningún servidor Plex.',
			'local.noAccess' => ({required Object where}) => 'Subnext Player no puede ver tus vídeos sin acceso multimedia. Puedes concederlo en ${where}.',
			'local.settingsIos' => 'la app Ajustes',
			'local.settingsAndroid' => 'los ajustes de Android',
			'local.intro' => 'Reproduce vídeos guardados en este dispositivo.\nSubnext Player solo pide acceso a los vídeos, nunca a todos los archivos.',
			'local.allowAccess' => 'Permitir acceso a los vídeos',
			'local.pickFolderInstead' => 'O elige una carpeta',
			'local.addShare' => 'Añadir un recurso de red',
			'local.shares' => 'Recursos de red',
			'local.pickedFolders' => 'Carpetas que elegiste',
			'local.onDevice' => 'En este dispositivo',
			'local.noVideos' => 'No se encontraron vídeos en este dispositivo.',
			'local.addFolderShort' => 'Añadir una carpeta',
			'local.addShareShort' => 'Añadir un recurso',
			'local.scanDevice' => 'Explorar este dispositivo',
			'local.forgetFolder' => 'Olvidar esta carpeta',
			'local.folder' => 'Carpeta',
			'local.safUnreadable' => ({required Object error}) => 'Ya no se puede leer esta carpeta. Puede que Android haya retirado el permiso, así que quítala y vuelve a elegirla.\n\n${error}',
			'local.safEmpty' => 'Aquí no hay vídeos ni subcarpetas.',
			'smb.connectFailed' => ({required Object error}) => 'No se pudo conectar: ${error}',
			'smb.title' => 'Añadir un recurso de red',
			'smb.explain' => 'Un NAS o una carpeta compartida en otro ordenador de tu red.',
			'smb.host' => 'Dirección del servidor',
			'smb.hostHint' => 'p. ej., nas',
			'smb.username' => 'Usuario',
			'smb.password' => 'Contraseña',
			'smb.domain' => 'Dominio (opcional)',
			'smb.name' => 'Nombre (opcional)',
			'smb.connectAndAdd' => 'Conectar y añadir',
			'smb.gone' => 'Ese recurso ya no está configurado.',
			'smb.unreachable' => ({required Object error}) => 'No se pudo contactar con este recurso. Puede que el servidor esté en reposo o fuera de la red.\n\n${error}',
			'smb.empty' => 'Aquí no hay vídeos ni carpetas.',
			'xtream.lineGone' => 'Esa suscripción ya no está configurada.',
			'xtream.catalogue.live' => 'TV en directo',
			'xtream.catalogue.vod' => 'Películas',
			'xtream.catalogue.series' => 'Series',
			'xtream.errors.status' => ({required Object code}) => 'El servidor de tu proveedor respondió ${code}. Inténtalo más tarde.',
			'xtream.errors.timeout' => 'El servidor de tu proveedor no respondió a tiempo.',
			'xtream.errors.unreachable' => 'No se pudo acceder a esa dirección. Revisa el enlace, o la dirección del servidor y el puerto.',
			'xtream.errors.other' => ({required Object type}) => 'No se pudo hablar con el servidor de tu proveedor (${type}).',
			'xtream.errors.notXtream' => 'Esa dirección no respondió como un servidor de IPTV. Revisa el enlace o la dirección del servidor.',
			'xtream.errors.rejected' => 'Tu proveedor no aceptó ese inicio de sesión.',
			'xtream.errors.wrongLogin' => 'Usuario o contraseña incorrectos.',
			'xtream.errors.unnamed' => 'Sin nombre',
			'xtream.errors.episode' => 'Episodio',
			'xtream.errors.noPassword' => 'Esa suscripción no tiene contraseña guardada. Quítala y vuelve a añadirla.',
			'xtream.everythingElse' => 'Todo lo demás',
			'xtream.series.title' => 'Serie',
			'xtream.series.noEpisodes' => 'Tu proveedor no devolvió episodios de esta serie.',
			'xtream.series.season' => ({required Object n}) => 'Temporada ${n}',
			'xtream.remove' => 'Quitar',
			'xtream.add' => 'Añadir una suscripción de IPTV',
			'xtream.addLine.discardTitle' => '¿Descartar lo que escribiste?',
			'xtream.addLine.discardBody' => 'Lo que has escrito aquí no se ha guardado.',
			'xtream.addLine.discard' => 'Descartar',
			'xtream.addLine.keepEditing' => 'Seguir editando',
			'xtream.addLine.inactive' => ({required Object status}) => 'Tu proveedor dice que esta suscripción está "${status}".',
			'xtream.addLine.noContent' => 'Subnext Player no proporciona, aloja ni respalda ningún contenido ni proveedor. Tú indicas la dirección y el inicio de sesión, y la app reproduce lo que devuelva esa dirección.',
			'xtream.addLine.host' => 'Dirección del servidor',
			'xtream.addLine.name' => 'Nombre (opcional)',
			'xtream.addLine.nameHint' => 'Cómo quieres llamar a esta suscripción',
			'xtream.addLine.checking' => 'Comprobando…',
			'xtream.addLine.verify' => 'Conectar',
			'xtream.addLine.hostHint' => 'example.com:8080',
			'xtream.addLine.how' => '¿Cómo te envió tu proveedor el inicio de sesión?',
			'xtream.addLine.howHint' => 'Busca en el correo o mensaje que recibiste al suscribirte.',
			'xtream.addLine.modeLink' => 'Un enlace largo',
			'xtream.addLine.modeLinkSub' => 'Suele llamarse enlace M3U o URL de lista.',
			'xtream.addLine.modeLogin' => 'Un usuario y una contraseña',
			'xtream.addLine.modeLoginSub' => 'Con una dirección de servidor como example.com:8080. A veces se llama inicio de sesión Xtream Codes.',
			'xtream.addLine.modeDevice' => 'Ya está en otro dispositivo',
			'xtream.addLine.modeDeviceSub' => 'Envíalo desde tu móvil en lugar de escribirlo aquí.',
			'xtream.addLine.link' => 'Enlace de tu proveedor',
			'xtream.addLine.paste' => 'Pegar',
			'xtream.addLine.found' => 'Hemos encontrado tu inicio de sesión en este enlace',
			'xtream.addLine.notALink' => 'No parece un enlace con un inicio de sesión. Revísalo o escribe los datos tú mismo.',
			'xtream.addLine.server' => 'Servidor',
			'xtream.addLine.show' => 'Mostrar',
			'xtream.addLine.hide' => 'Ocultar',
			'xtream.addLine.defaultName' => 'Suscripción de TV',
			'xtream.picker.patternNone' => 'Ese patrón no coincidió con nada.',
			'xtream.picker.title' => ({required Object catalogue}) => 'Categorías de ${catalogue}',
			'xtream.picker.save' => 'Guardar',
			'xtream.picker.noMatch' => ({required Object query}) => 'Nada coincide con «${query}».',
			'xtream.picker.noneChosen' => 'Aún no has elegido nada.',
			'xtream.picker.search' => 'Buscar en todas las categorías',
			'xtream.picker.chosen' => ({required Object n}) => 'Elegidas ${n}',
			'xtream.picker.hideWords' => 'Ocultar palabras',
			'xtream.picker.hideCount' => ({required Object n}) => 'Ocultas ${n}',
			_ => null,
		} ?? switch (path) {
			'xtream.picker.pattern' => 'Patrón',
			'xtream.picker.untickedOne' => ({required Object name, required Object word}) => 'Se desmarcó «${name}», que oculta «${word}». Guarda para conservarlo.',
			'xtream.picker.untickedMany' => ({required Object n, required Object word}) => 'Se desmarcaron ${n} categorías elegidas que oculta «${word}». Guarda para conservarlo.',
			'xtream.picker.showingHidden' => 'Se muestran las categorías que dejan fuera tus palabras ocultas.',
			'xtream.picker.hiddenCount' => ({required Object n}) => '${n} ocultas por tus palabras.',
			'xtream.picker.hideAgain' => 'Volver a ocultar',
			'xtream.picker.showThem' => 'Mostrarlas',
			'xtream.picker.patternHint' => 'Marca o desmarca todas las categorías que coincidan con una palabra o un patrón',
			'xtream.picker.selectMatching' => 'Marcar coincidencias',
			'xtream.picker.deselectMatching' => 'Desmarcar coincidencias',
			'xtream.picker.groups' => 'Grupos',
			'xtream.picker.clearAll' => 'Desmarcar todo',
			'xtream.picker.selectAll' => 'Marcar todo',
			'xtream.picker.channelsPicked' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${n} canal', other: '${n} canales', ), 
			'xtream.picker.pickedChosen' => ({required Object n}) => '${n} elegidos',
			'xtream.picker.categories' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${n} categoría', other: '${n} categorías', ), 
			'xtream.picker.channels' => 'Canales',
			'xtream.channels.done' => 'Listo',
			'xtream.channels.search' => 'Buscar en esta categoría',
			'xtream.channels.pickedOf' => ({required Object picked, required Object total}) => '${picked} de ${total}',
			'xtream.channels.whole' => 'Toda la categoría',
			'xtream.channels.selectShown' => 'Marcar los mostrados',
			'xtream.channels.clear' => 'Desmarcar',
			'xtream.channels.clearShown' => 'Desmarcar los mostrados',
			'xtream.channels.none' => 'Tu proveedor no tiene canales en esta categoría.',
			'xtream.channels.wholeTitle' => ({required Object n}) => 'Categoría completa · ${n} canales',
			'xtream.channels.wholeSub' => 'Los canales nuevos que añada tu proveedor aparecen solos.',
			'xtream.channels.someTitle' => ({required Object picked, required Object total}) => 'Solo los que marque · ${picked} de ${total}',
			'xtream.channels.someSub' => 'Los canales añadidos más tarde quedan ocultos hasta que los marques.',
			'xtream.hidden.title' => 'Ocultar palabras',
			'xtream.hidden.explain' => 'Las categorías o canales que contengan cualquiera de estas como palabra completa quedan fuera de las listas. «UK» oculta «UK News» pero no «Ukraine». Añade una frase como «south indian» para ocultarla como un todo. No distingue mayúsculas.',
			'xtream.hidden.hint' => 'Un país, un idioma, una palabra',
			'xtream.hidden.add' => 'Añadir',
			'xtream.hidden.none' => 'Aún no hay nada oculto.',
			'xtream.hidden.tapToRemove' => 'Selecciona una palabra para dejar de ocultarla.',
			'xtream.setup.step' => ({required Object n}) => 'Paso ${n} de 3',
			'xtream.connected.title' => 'Estás conectado',
			'xtream.connected.status' => 'Estado',
			'xtream.connected.active' => 'Activa',
			'xtream.connected.trial' => 'Activa, de prueba',
			'xtream.connected.ends' => 'Termina',
			'xtream.connected.noEnd' => 'Sin fecha de fin',
			'xtream.connected.screens' => 'Pantallas a la vez',
			'xtream.connected.oneScreen' => 'Tu suscripción se reproduce en una pantalla a la vez. Si está en marcha en otro sitio, aquí no empezará hasta que se detenga.',
			'xtream.connected.liveCategories' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${n} categoría de canales', other: '${n} categorías de canales', ), 
			'xtream.connected.available' => 'Canales',
			'xtream.connected.next' => 'Es más de lo que nadie ve, así que ahora eliges los países y tipos de canal que quieres. Solo se cargan esos.',
			'xtream.connected.choose' => 'Elegir lo que ves',
			'xtream.regions.uk' => 'Reino Unido',
			'xtream.regions.us' => 'EE. UU.',
			'xtream.regions.ca' => 'Canadá',
			'xtream.regions.au' => 'Australia',
			'xtream.regions.en' => 'Inglés',
			'xtream.regions.de' => 'Alemania',
			'xtream.regions.at' => 'Austria',
			'xtream.regions.ch' => 'Suiza',
			'xtream.regions.fr' => 'Francia',
			'xtream.regions.be' => 'Bélgica',
			'xtream.regions.nl' => 'Países Bajos',
			'xtream.regions.es' => 'España',
			'xtream.regions.latam' => 'Latinoamérica',
			'xtream.regions.pt' => 'Portugal',
			'xtream.regions.br' => 'Brasil',
			'xtream.regions.it' => 'Italia',
			'xtream.regions.pl' => 'Polonia',
			'xtream.regions.tr' => 'Turquía',
			'xtream.regions.gr' => 'Grecia',
			'xtream.regions.ro' => 'Rumanía',
			'xtream.regions.ru' => 'Rusia',
			'xtream.regions.ar' => 'Árabe',
			'xtream.regions.in' => 'India',
			'xtream.regions.pk' => 'Pakistán',
			'xtream.regions.af' => 'África',
			'xtream.regions.jp' => 'Japón',
			'xtream.regions.kr' => 'Corea',
			'xtream.regions.cn' => 'China',
			'xtream.kinds.news' => 'Noticias',
			'xtream.kinds.sport' => 'Deportes',
			'xtream.kinds.kids' => 'Infantil',
			'xtream.kinds.films' => 'Películas',
			'xtream.kinds.docs' => 'Documentales',
			'xtream.kinds.music' => 'Música',
			'xtream.kinds.entertainment' => 'Entretenimiento',
			'xtream.watch.title' => '¿Qué ves?',
			'xtream.watch.sub' => 'Elige unos cuantos. Puedes cambiarlo cuando quieras.',
			'xtream.watch.regions' => 'Países e idiomas',
			'xtream.watch.kinds' => 'Tipos de canal',
			'xtream.watch.more' => ({required Object n}) => 'Ver los ${n}',
			'xtream.watch.fewer' => 'Ver menos',
			'xtream.watch.count' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${n} categoría elegida', other: '${n} categorías elegidas', ), 
			'xtream.watch.none' => 'Elige un país, un idioma o un tipo de canal.',
			'xtream.watch.unplaced' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: 'Ordenado por los nombres que usa tu proveedor. ${n} categoría no encaja en ninguno: la encontrarás en Ajuste fino.', other: 'Ordenado por los nombres que usa tu proveedor. ${n} categorías no encajan en ninguno: las encontrarás en Ajuste fino.', ), 
			'xtream.watch.fineTune' => 'Ajuste fino',
			'xtream.watch.chips' => 'Volver a las opciones',
			'xtream.watch.replaceTitle' => '¿Sustituir tu selección hecha a mano?',
			'xtream.watch.replaceBody' => 'Cambiaste la selección a mano en Ajuste fino. Esto la sustituye por lo que abarcan estas opciones.',
			'xtream.watch.replace' => 'Sustituir',
			'xtream.watch.keep' => 'Mantener la mía',
			'xtream.watch.next' => 'Continuar',
			'xtream.review.title' => 'Esto es lo que verás',
			'xtream.review.live' => 'TV en directo',
			'xtream.review.movies' => 'Películas',
			'xtream.review.series' => 'Series',
			'xtream.review.chosen' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${n} categoría', other: '${n} categorías', ), 
			'xtream.review.notAdded' => 'Aún no añadido',
			'xtream.review.add' => 'Añadir',
			'xtream.review.change' => 'Cambiar',
			'xtream.review.neverShow' => 'No mostrar nunca',
			'xtream.review.neverShowSub' => 'Ocultar todo lo que tenga estas palabras',
			'xtream.review.neverShowNone' => 'Nada oculto',
			'xtream.review.edit' => 'Editar',
			'xtream.review.later' => 'Puedes cambiar todo esto más tarde en Ajustes, Fuentes avanzadas.',
			'xtream.review.open' => 'Abrir TV en directo',
			'xtream.review.link' => 'Lo que ves',
			'transfer.noNetwork' => 'Este dispositivo no está en una red Wi-Fi ni Ethernet. Conéctalo a la misma red que el otro dispositivo e inténtalo de nuevo.',
			'transfer.cannotListen' => ({required Object error}) => 'No se pudo empezar a escuchar: ${error}',
			'transfer.expired' => 'Ese código ha caducado. Vuelve a empezar para obtener uno nuevo.',
			'transfer.wentWrong' => ({required Object error}) => 'Algo salió mal: ${error}',
			'transfer.wentWrongPlain' => 'Algo salió mal.',
			'transfer.gettingReady' => 'Preparando…',
			'transfer.waitingOther' => 'Esperando al otro dispositivo…',
			'transfer.copyCode' => 'Copiar código',
			'transfer.scanInstead' => 'Escanear su código',
			'transfer.typeInstead' => 'Escribir su código',
			'transfer.done' => 'Listo',
			'transfer.close' => 'Cerrar',
			'transfer.receive.cannotSave' => ({required Object error}) => 'No se pudieron guardar los ajustes: ${error}',
			'transfer.receive.title' => 'Recibir ajustes',
			'transfer.receive.asking' => 'Preguntando al otro dispositivo…',
			'transfer.receive.awaitingPush' => 'Esperando a que el otro dispositivo envíe. Di que sí allí cuando lo pregunte.',
			'transfer.receive.saving' => 'Guardando…',
			'transfer.receive.waitingInstructions' => 'En el dispositivo que tiene tus ajustes, abre Ajustes, Pasar a otro dispositivo, y elige Enviar. Luego escanea este código.',
			'transfer.receive.scanInstructions' => 'En el dispositivo que tiene tus ajustes, abre Ajustes, Pasar a otro dispositivo, y elige Enviar y después Mostrar un código. Apunta la cámara hacia él.',
			'transfer.receive.showMine' => 'Mostrar mi código',
			'transfer.receive.typeInstructions' => 'En el dispositivo que tiene tus ajustes, abre Ajustes, Pasar a otro dispositivo, y elige Enviar y después Mostrar un código. Luego introduce lo que muestre.',
			'transfer.receive.connect' => 'Conectar',
			'transfer.receive.review' => 'Otro dispositivo quiere enviarte esto. Lo que ya esté aquí con el mismo nombre se sustituye; no se quita nada más.',
			'transfer.receive.saveThese' => 'Guardar esto',
			'transfer.receive.decline' => 'Rechazar',
			'transfer.receive.saved' => 'Listo. Tus ajustes ya están en este dispositivo.',
			'transfer.pairing.noCamera' => '¿Sin cámara? Elige allí Escribir el código e introduce:',
			'transfer.pairing.qrLabel' => 'Código para escanear desde el otro dispositivo',
			'transfer.pairing.cameraOff' => 'La cámara está desactivada para esta app. Escribe el código o permite la cámara en los ajustes del móvil.',
			'transfer.pairing.cameraFailed' => 'No se pudo iniciar la cámara. Escribe el código.',
			'transfer.pairing.foreign' => 'Ese código no es de esta app.',
			'transfer.pairing.checkEntry' => 'Comprueba la dirección (como 192.168.1.20:41234) y el código de 16 caracteres.',
			'transfer.pairing.address' => 'Dirección',
			'transfer.pairing.code' => 'Código',
			'transfer.pane.explain' => 'Copia tus fuentes, claves y preferencias a otro dispositivo de la misma red Wi-Fi, para no tener que volver a escribirlas. Va directamente de un dispositivo al otro, cifrado con un código que solo comparten las dos pantallas, y el dispositivo que recibe pregunta antes de guardar nada.',
			'transfer.pane.notCopied' => 'No se copia: Plex (vincúlalo en el otro dispositivo con su propio código), el historial, los favoritos, ni el consentimiento que diste para Fuentes avanzadas y Funciones de IA, que cada dispositivo pide por su cuenta.',
			'transfer.pane.receive' => 'Recibir de otro dispositivo',
			'transfer.pane.send' => 'Enviar a otro dispositivo',
			'transfer.notes.aiLocal' => 'Tu proveedor de IA funciona en este dispositivo, así que no se envía. Vuelve a configurarlo allí con la dirección de este dispositivo en tu red.',
			'transfer.notes.xtreamHidden' => 'Las cuentas de IPTV se han guardado pero están ocultas. Activa Fuentes avanzadas en Ajustes para usarlas.',
			'transfer.notes.aiAsks' => 'Las funciones de IA preguntarán antes de enviar nada al proveedor.',
			'transfer.notes.partial' => ({required Object failed}) => 'No se pudo guardar: ${failed}. El resto se guardó.',
			'transfer.send.cannotRead' => ({required Object error}) => 'No se pudieron leer los ajustes de este dispositivo: ${error}',
			'transfer.send.askTitle' => ({required Object host}) => '¿Enviar a ${host}?',
			'transfer.send.askBody' => ({required Object summary}) => 'Un dispositivo de tu red ha escaneado este código y pide:\n\n${summary}\n\nAcepta solo si acabas de pedirlo en ese dispositivo.',
			'transfer.send.notNow' => 'Ahora no',
			'transfer.send.send' => 'Enviar',
			'transfer.send.title' => 'Enviar ajustes',
			'transfer.send.reading' => 'Leyendo tus ajustes…',
			'transfer.send.sending' => 'Enviando. El otro dispositivo preguntará antes de guardar nada.',
			'transfer.send.explain' => 'Copia esto a otro dispositivo de la misma red Wi-Fi, para no tener que volver a escribirlo. Va directamente allí y cifrado; nada pasa por nosotros.',
			'transfer.send.nothing' => 'Aún no hay nada configurado en este dispositivo que enviar.',
			'transfer.send.proceed' => 'Continuar',
			'transfer.send.showInstead' => 'Mostrar un código',
			'transfer.send.typeInstead' => 'Escribir el código',
			'transfer.send.scanInstructions' => 'En el otro dispositivo, abre Ajustes, Pasar a otro dispositivo, y elige Recibir. Apunta la cámara al código que muestre.',
			'transfer.send.showInstructions' => 'En el otro dispositivo, abre Ajustes, Pasar a otro dispositivo, y elige Recibir y después Escanear su código, y apunta su cámara aquí. Se te preguntará antes de enviar nada.',
			'transfer.send.typeInstructions' => 'En el otro dispositivo, abre Ajustes, Pasar a otro dispositivo, y elige Recibir. Luego introduce lo que muestre.',
			'transfer.send.sent' => 'Enviado. El otro dispositivo ha guardado tus ajustes.',
			'transfer.item.preferences' => 'Preferencias',
			'transfer.item.preferencesSub' => 'Opciones de reproducción y subtítulos, palabras ocultas y ubicación en la biblioteca.',
			'transfer.item.xtream' => 'Cuentas de IPTV',
			'transfer.item.xtreamSub' => 'Inicios de sesión y las categorías y canales que elegiste.',
			'transfer.item.smb' => 'Recursos de red',
			'transfer.item.smbSub' => 'Recursos SMB y sus contraseñas.',
			'transfer.item.tmdb' => 'Clave de TMDB',
			'transfer.item.tmdbSub' => 'Tu propia clave para los filtros de género, valoración e idioma.',
			'transfer.item.ai' => 'Proveedor de IA',
			'transfer.item.aiSub' => 'El proveedor, su modelo y tu clave.',
			'transfer.item.settings' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${n} ajuste', other: '${n} ajustes', ), 
			'transfer.item.accounts' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${n} cuenta', other: '${n} cuentas', ), 
			'transfer.item.shares' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${n} recurso', other: '${n} recursos', ), 
			'transfer.item.notBundle' => 'Eso no era un paquete de ajustes.',
			'transfer.item.newer' => 'Ese paquete es de una versión más reciente de la app. Actualiza este dispositivo e inténtalo de nuevo.',
			'transfer.item.trackers' => 'Seguimiento de lo visto',
			'transfer.item.trackersSub' => 'Tus inicios de sesión en Trakt, Simkl, AniList y MyAnimeList. Aceptarlos aquí es aceptar enviar también lo que veas en este dispositivo.',
			'transfer.item.services' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${n} servicio', other: '${n} servicios', ), 
			'transfer.client.declined' => 'El otro dispositivo no aceptó los ajustes.',
			'transfer.client.wrongCode' => 'El código no era correcto. Compruébalo con la otra pantalla.',
			'transfer.client.used' => 'El otro dispositivo ya recibió algo. Vuelve a abrir Recibir allí para obtener un código nuevo.',
			'transfer.client.tooBig' => 'Era demasiado para enviar.',
			'transfer.client.unreadable' => 'El otro dispositivo no pudo leerlo.',
			'transfer.client.unexpected' => ({required Object status}) => 'El otro dispositivo respondió de forma inesperada (${status}).',
			'transfer.client.refusedToSend' => 'El otro dispositivo no aceptó enviar sus ajustes.',
			'transfer.client.busy' => 'El otro dispositivo ya está atendiendo a otro. Pídele un código nuevo.',
			'transfer.client.unreachable' => ({required Object address}) => 'No se pudo contactar con ${address}. Los dos dispositivos deben estar en la misma red Wi-Fi, y el otro tiene que seguir mostrando su código.',
			'transfer.client.dropped' => 'La conexión se cortó a medias.',
			'transfer.client.noAnswer' => ({required Object address}) => 'Sin respuesta de ${address}. Revisa la otra pantalla.',
			'mediaBrowser.errors.signedOut' => ({required Object server}) => '${server} ya no acepta este inicio de sesión. Quítalo en Ajustes, Fuentes y vuelve a añadirlo.',
			'mediaBrowser.errors.status' => ({required Object server, required Object code}) => '${server} respondió ${code}.',
			'mediaBrowser.errors.unreachable' => ({required Object server}) => 'No se pudo contactar con ${server}. Puede que esté en reposo o fuera de la red.',
			'mediaBrowser.errors.notAServer' => 'Ningún servidor Jellyfin o Emby respondió en esa dirección. Compruébala, incluido el puerto (normalmente 8096).',
			'mediaBrowser.errors.badAnswer' => 'El servidor respondió de una forma que esta app no entiende.',
			'mediaBrowser.errors.wrongLogin' => 'Usuario o contraseña incorrectos.',
			'mediaBrowser.title' => 'Conectar con Jellyfin o Emby',
			'mediaBrowser.explain' => 'Subnext Player reproduce lo que ya tiene tu propio servidor. Tu inicio de sesión se queda en este dispositivo y no llega a nadie más que a tu servidor.',
			'mediaBrowser.address' => 'Dirección del servidor',
			'mediaBrowser.addressHint' => 'p. ej., 192.168.1.20:8096',
			'mediaBrowser.find' => 'Buscar servidor',
			'mediaBrowser.finding' => 'Buscando el servidor…',
			'mediaBrowser.found' => ({required Object name, required Object kind, required Object version}) => '${name} · ${kind} ${version}',
			'mediaBrowser.username' => 'Usuario',
			'mediaBrowser.password' => 'Contraseña',
			'mediaBrowser.signIn' => 'Iniciar sesión',
			'mediaBrowser.signingIn' => 'Iniciando sesión…',
			'mediaBrowser.useQuickConnect' => 'Usar Quick Connect',
			'mediaBrowser.usePassword' => 'Usar usuario y contraseña',
			'mediaBrowser.quickConnectExplain' => 'En un móvil u ordenador que ya tenga la sesión iniciada en Jellyfin, abre tu perfil, Quick Connect, e introduce:',
			'mediaBrowser.waiting' => 'Esperando la aprobación…',
			'mediaBrowser.otherAddress' => 'Usar otra dirección',
			'mediaBrowser.connected' => ({required Object name}) => 'Conectado a ${name}.',
			'trackers.errors.unavailable' => ({required Object service}) => 'No se pudo contactar con ${service}. Se volverá a intentar.',
			'trackers.errors.denied' => 'Se rechazó el inicio de sesión.',
			'trackers.errors.expired' => 'Ese código ha caducado. Vuelve a empezar para obtener uno nuevo.',
			'trackers.errors.badPaste' => 'Eso no es lo que dio la página de inicio de sesión. Vuelve a copiarlo y pégalo entero.',
			'trackers.malCaught' => 'Sesión iniciada. Puedes cerrar esta ventana y volver a Subnext Player.',
			'trackers.intro' => 'Envía lo que terminas de ver en tus propios servidores a un servicio de historial. No se envía nada de IPTV, y nada llega a nosotros.',
			'trackers.animeNote' => 'AniList y MyAnimeList solo reciben títulos que tu servidor marca como anime, buscados por nombre.',
			'trackers.signedInAs' => ({required Object name}) => 'Sesión iniciada como ${name}',
			'trackers.signedIn' => 'Sesión iniciada',
			'trackers.notConnected' => 'Sin conectar',
			'trackers.signIn' => 'Iniciar sesión',
			'trackers.signOut' => 'Cerrar sesión',
			'trackers.pending' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '1 visionado está pendiente de enviarse.', other: '${n} visionados están pendientes de enviarse.', ), 
			'trackers.consentTitle' => ({required Object service}) => '¿Enviar lo que ves a ${service}?',
			'trackers.consentBody' => ({required Object service}) => 'Cuando terminas una película o un episodio de tu propio servidor Plex, Jellyfin o Emby, Subnext Player envía a ${service} su título, año, su identificador de IMDb, TMDB o TVDB, y cuándo lo viste. Va directamente de este dispositivo a ${service}, nunca a través de nosotros. No se envía nada de IPTV. Puedes cerrar sesión cuando quieras en Ajustes, Seguimiento de lo visto.',
			'trackers.consentAnime' => ({required Object service}) => 'A ${service} solo se envían títulos que tu servidor marca como anime, y se buscan en ${service} por su nombre.',
			'trackers.agree' => 'Continuar',
			'trackers.notNow' => 'Ahora no',
			'trackers.signInTitle' => ({required Object service}) => 'Iniciar sesión en ${service}',
			'trackers.deviceCodeExplain' => ({required Object url}) => 'En cualquier dispositivo, abre ${url} e introduce:',
			'trackers.waiting' => 'Esperando la aprobación…',
			'trackers.browserExplain' => ({required Object service}) => 'Abre esta dirección en un navegador, inicia sesión en ${service} y aprueba Subnext Player. Luego pega abajo lo que te dé ${service}.',
			'trackers.anilistPaste' => 'AniList muestra un token largo al aprobar. Cópialo entero.',
			'trackers.malPaste' => 'En este dispositivo la app termina sola. Si el navegador estaba en otro, acaba en una página que no carga: copia la dirección completa de esa página.',
			'trackers.tvHint' => 'En una TV, inicia sesión en el móvil y usa Pasar a otro dispositivo para traerlo aquí.',
			'trackers.pasteLabel' => 'Pega aquí',
			'trackers.finish' => 'Terminar de iniciar sesión',
			'trackers.copyAddress' => 'Copiar dirección',
			'trackers.connected' => ({required Object service}) => 'Conectado a ${service}.',
			'seerr.errors.notASeerr' => 'Ningún servidor Overseerr, Jellyseerr o Seerr respondió en esa dirección. Compruébala, incluido el puerto (normalmente 5055).',
			'seerr.errors.behindAccess' => 'Esa dirección está detrás de Cloudflare Access, que envía la app a una página de inicio de sesión que no puede usar. Quien la gestiona puede añadir una política de Access que omita /api/*, ya que Seerr ya pide iniciar sesión.',
			'seerr.errors.badKey' => 'El servidor no aceptó esa clave de API.',
			'seerr.errors.refused' => 'El servidor no aceptó ese inicio de sesión.',
			'seerr.errors.status' => ({required Object code}) => 'El servidor respondió ${code}.',
			'seerr.errors.unreachable' => 'No se pudo contactar con el servidor de solicitudes.',
			'seerr.errors.signedOut' => 'El servidor de solicitudes ya no acepta este inicio de sesión. Vuelve a conectarlo en Ajustes, Solicitudes.',
			'seerr.errors.alreadyRequested' => 'Eso ya se ha solicitado.',
			'seerr.intro' => 'Conecta tu propio servidor Overseerr, Jellyseerr o Seerr para pedir películas y series que tu biblioteca aún no tiene. Las solicitudes van a tu servidor y a ningún otro sitio; quien lo administra decide qué pasa después.',
			'seerr.address' => 'Dirección del servidor',
			'seerr.addressHint' => 'p. ej., 192.168.1.20:5055',
			'seerr.find' => 'Buscar servidor',
			'seerr.withPlex' => 'Iniciar sesión con mi cuenta de Plex',
			'seerr.withPassword' => 'Iniciar sesión con usuario y contraseña',
			'seerr.withKey' => 'Usar una clave de API',
			'seerr.username' => 'Usuario o correo',
			'seerr.password' => 'Contraseña',
			'seerr.apiKey' => 'Clave de API',
			'seerr.keyNote' => 'Una clave de API actúa como administrador del servidor, así que las solicitudes hechas con ella no constan como tuyas. Mejor inicia sesión.',
			'seerr.connect' => 'Conectar',
			'seerr.connecting' => 'Conectando…',
			'seerr.connected' => ({required Object title, required Object name}) => 'Conectado a ${title} como ${name}',
			'seerr.disconnect' => 'Desconectar',
			'seerr.myRequests' => 'Tus solicitudes recientes',
			'seerr.none' => 'Aún no hay solicitudes.',
			'seerr.statusPending' => 'Esperando aprobación',
			'seerr.statusApproved' => 'Aprobada',
			'seerr.statusDeclined' => 'Rechazada',
			'seerr.statusAvailable' => 'Disponible',
			'seerr.rowTitle' => ({required Object title}) => 'Solicitar a ${title}',
			'seerr.requested' => 'Solicitado',
			'seerr.partial' => 'Disponible en parte',
			'seerr.askTitle' => ({required Object title}) => '¿Solicitar ${title}?',
			'seerr.askMovie' => ({required Object server}) => 'Esto pide a ${server} que añada la película. Quien lo administra decide si lo hace.',
			'seerr.askShow' => ({required Object server}) => 'Esto pide a ${server} que añada todas las temporadas. Quien lo administra decide si lo hace.',
			'seerr.request' => 'Solicitar',
			'seerr.sent' => ({required Object title}) => 'Se solicitó ${title}.',
			'film.play' => 'Reproducir',
			'film.resume' => ({required Object time}) => 'Reanudar desde ${time}',
			'film.fromStart' => 'Reproducir desde el principio',
			'film.gone' => 'Esta película ya no está en el servidor, o no se puede contactar con el servidor.',
			'film.trailer' => 'Tráiler',
			'film.trailerNoApp' => 'Nada en este dispositivo puede abrir el tráiler.',
			'film.rtAudience' => ({required Object pct}) => 'RT público ${pct} %',
			'errors.addressHidden' => '(dirección oculta)',
			_ => null,
		};
	}
}
