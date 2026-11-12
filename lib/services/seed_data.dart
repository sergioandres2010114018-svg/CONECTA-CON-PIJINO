import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config.dart';

/// Contenido inicial de la base de datos de APP-Conecta con Pijiño.
///
/// Criterio de validación:
///  - `validado: true`  → dato respaldado por un documento oficial (ANT, plan
///    municipal, DANE) o por al menos dos fuentes independientes.
///  - `validado: false` → dato con una sola fuente publicada o sin fuente;
///    el equipo de contenidos debe confirmarlo con la comunidad.
/// Cada publicación indica su fuente y, cuando existe, el enlace para consultarla.
class SeedData {
  static Future<int> cargar({bool forzar = false}) async {
    final db = FirebaseFirestore.instance;
    if (!forzar) {
      final existe = await db.collection('contenidos').limit(1).get();
      if (existe.docs.isNotEmpty) return 0;
    }
    final user = FirebaseAuth.instance.currentUser!;
    var n = 0;
    // Firestore admite máximo 500 operaciones por lote; se usan varios lotes.
    var batch = db.batch();
    var enLote = 0;
    Future<void> agregar(DocumentReference<Map<String, dynamic>> ref, Map<String, dynamic> data) async {
      batch.set(ref, data);
      n++;
      enLote++;
      if (enLote >= 400) {
        await batch.commit();
        batch = db.batch();
        enLote = 0;
      }
    }

    for (final c in contenidos) {
      final data = Map<String, dynamic>.from(c)..remove('slug');
      data['creadoEn'] = FieldValue.serverTimestamp();
      await agregar(db.collection('contenidos').doc(c['slug'] as String), data);
    }
    for (final g in galeria) {
      final data = Map<String, dynamic>.from(g)..remove('slug');
      await agregar(db.collection('galeria').doc(g['slug'] as String), <String, dynamic>{
        ...data,
        'autorUid': user.uid,
        'aprobado': true,
        'creadoEn': FieldValue.serverTimestamp(),
      });
    }
    for (final d in negocios) {
      final data = Map<String, dynamic>.from(d)..remove('slug');
      await agregar(db.collection('negocios').doc(d['slug'] as String), data);
    }
    await batch.commit();
    return n;
  }

  // ------------------------------------------------------------------ Fuentes
  static const String fOspino = 'Raúl Ospino Rangel, “Pijiño del Carmen, Magdalena”, Historias del Magdalena (2019) y crónica en Opinión Caribe (2015).';
  static const String uOspino = 'https://historiasdelmagdalena1.blogspot.com/2019/05/pijino-del-carmenmagdalena-pueblo.html';
  static const String uOspino2015 = 'https://www.opinioncaribe.com/2015/08/27/pijino-del-carmen-un-pueblo-ecologico-cronica/';
  static const String fAnt = 'Agencia Nacional de Tierras, Plan de Ordenamiento Social de la Propiedad Rural – Pijiño del Carmen (2024).';
  static const String uAnt = 'https://geoportal.ant.gov.co/visor_otr_pospr/47545/47545_POSPR.pdf';
  static const String fPlan2000 = 'Municipio de Pijiño del Carmen, documento de planeación municipal (marzo de 2000), repositorio ESAP.';
  static const String uPlan2000 = 'https://repositoriocdim.esap.edu.co/server/api/core/bitstreams/1fbe45e4-bf46-47c3-9497-c49c162e0204/content';
  static const String fWikiEs = 'Wikipedia en español, “Pijiño del Carmen”.';
  static const String uWikiEs = 'https://es.wikipedia.org/wiki/Piji%C3%B1o_del_Carmen';
  static const String fGuia = 'La Guía Turística, “Pijiño del Carmen y su riqueza hidrográfica” (2017).';
  static const String uGuia = 'https://www.laguiaturistica.com/index.php/magdalena/sitios-turisticos/258-pijino-del-carmen-y-su-riqueza-hidrografica';
  static const String fViajar = 'Viajar en Verano, “Pijiño del Carmen (Magdalena), una región rica en lagunas y fauna” (2021).';
  static const String uViajar = 'https://www.viajarenverano.com/pijino-del-carmen-magdalena/';
  static const String fNiko = 'Nomadic Niko, “Ciénaga de Pijiño” (crónica de viaje).';
  static const String uNiko = 'https://nomadicniko.com/colombia/cienaga-de-pijino';
  static const String fOpinion2017 = 'Opinión Caribe, “El potencial turístico del Sur del Magdalena” (2017).';
  static const String uOpinion2017 = 'https://www.opinioncaribe.com/2017/06/21/el-potencial-turistico-del-sur-del-magdalena/';

  /// Ruta base de las imágenes incluidas en la app.
  static const String A = 'asset:assets/images/';
  static const String fFotosEquipo = 'Fotografías aportadas por el equipo Conecta con Pijiño (documento de imágenes, noviembre de 2026).';
  static const String fTananeos = 'Tananeos, “Pijiño (Sapium glandulosum)”.';
  static const String uTananeos = 'https://www.tananeos.org/post/piji%C3%B1o-sapium-glandulosum';

  static Map<String, dynamic> _g(String slug, String archivo, String titulo, String descripcion, String autor) =>
      <String, dynamic>{
        'slug': slug,
        'tipo': 'foto',
        'url': '$A$archivo',
        'titulo': titulo,
        'descripcion': descripcion,
        'autorNombre': autor,
      };

  static Map<String, dynamic> _c(
    String slug,
    String categoria,
    int orden,
    String titulo,
    String resumen,
    String cuerpo, {
    bool validado = false,
    String fuente = '',
    String fuenteUrl = '',
    DateTime? fecha,
    String lugar = '',
    double? lat,
    double? lng,
    String imagenUrl = '',
    String videoUrl = '',
    List<String> imagenes = const <String>[],
  }) =>
      <String, dynamic>{
        'slug': slug,
        'categoria': categoria,
        'orden': orden,
        'titulo': titulo,
        'resumen': resumen,
        'cuerpo': cuerpo,
        'validado': validado,
        'fuente': fuente,
        'fuenteUrl': fuenteUrl,
        'fecha': fecha == null ? null : Timestamp.fromDate(fecha),
        'lugar': lugar,
        'lat': lat,
        'lng': lng,
        'imagenUrl': imagenUrl,
        'videoUrl': videoUrl,
        'imagenes': imagenes,
      };

  static final List<Map<String, dynamic>> contenidos = <Map<String, dynamic>>[
    // ================================================================ HISTORIA
    _c('historia-datos-generales', 'historia', 1, 'Pijiño del Carmen en datos',
        'Municipio ganadero y pesquero del sur del Magdalena, en la Depresión Momposina.',
        'Pijiño del Carmen es un municipio del sur del departamento del Magdalena, en la región Caribe colombiana. '
            'Está en la Depresión Momposina, en la parte baja del río Magdalena, sobre la margen oriental del brazo de Mompox.\n\n'
            '• Gentilicio: pijiñero(a).\n'
            '• Código DANE: 47545.\n'
            '• Cabecera: 9°20′ N, 74°27′ O; unos 80 m sobre el nivel del mar.\n'
            '• Temperatura media anual: cerca de 27,9 °C (marzo es el mes más caluroso y octubre el más fresco).\n'
            '• Población: 11.071 habitantes en el Censo DANE 2018; las proyecciones del DANE estiman unos 14.400 para 2026.\n'
            '• Extensión: el Esquema de Ordenamiento Territorial (2002) registra 52.607 ha (unos 526 km²), mientras la cartografía del IGAC registra 66.076 ha (unos 661 km²). Otras fuentes citan 739 km². La diferencia se debe a límites aún pendientes de deslinde.\n'
            '• Distancia a Santa Marta: unos 325 km por carretera.\n'
            '• Creado como municipio: Ordenanza 001 del 26 de marzo de 1996 de la Asamblea del Magdalena, segregado de Santa Ana.',
        validado: true,
        fuente: '$fAnt $fWikiEs DANE, Censo 2018 y proyecciones de población.',
        fuenteUrl: uAnt,
        lugar: 'Pijiño del Carmen, Magdalena',
        lat: AppConfig.latCentro,
        lng: AppConfig.lngCentro,
        imagenUrl: 'asset:assets/images/logo.png'),
    _c('historia-nombre', 'historia', 2, 'El origen del nombre',
        'Del “Hatillo de Pijiño” a la leyenda de la Virgen del Carmen.',
        'El primer nombre del lugar fue “Hatillo de Pijiño”: un sitio donde se reunía el ganado bajo los árboles de pijiño, '
            'abundantes en los humedales del sector conocido como La Baizana.\n\n'
            'El apellido “del Carmen” viene de una leyenda: de las aguas de la ciénaga salió flotando una tabla con la imagen de la Virgen del Carmen, '
            'que desde entonces es la patrona del pueblo.\n\n'
            'El árbol de pijiño aparece en el escudo municipal: en la franja verde se ven sus flores, que representan el nombre del pueblo.\n\n'
            'En las fotos: ramas, hojas y frutos del árbol de pijiño. Más información en “El árbol de pijiño” (sección Medio ambiente).',
        validado: true,
        fuente: '$fOspino $fViajar $fFotosEquipo',
        fuenteUrl: uOspino,
        imagenUrl: '${A}pijino_arbol_2.jpg',
        imagenes: <String>['${A}pijino_arbol_1.jpg', '${A}pijino_arbol_2.jpg', '${A}pijino_arbol_3.jpg', '${A}escudo.jpg']),
    _c('historia-colonia', 'historia', 3, 'Época colonial (siglo XVIII)',
        'Chimilas, mulatos y el hatillo ganadero de Mier y Guerra.',
        'Antes de ser pueblo, Pijiño hacía parte de las tierras de San Zenón, donde vivían indígenas chimila, mulatos y personas esclavizadas a orillas de la ciénaga, dedicados a la agricultura, la pesca y la cría de ganado.\n\n'
            '• 1750: el Maestre de Campo José Fernando de Mier y Guerra, encargado por el gobierno colonial de poblar la ribera del bajo Magdalena, fundó San Zenón de Navarro '
            'y reservó los playones y la ciénaga de Pijiño para cultivos de pancoger y cría de ganado. Ese “hatillo” dio origen al pueblo actual.\n'
            '• Desde 1760: sacerdotes de Santa Ana y San Zenón evangelizaron a la población indígena.\n'
            '• 1825: ya existía una iglesia.\n'
            '• 1871: la iglesia atendía unas 200 almas, pertenecía al curato de Santa Ana y tenía como patrona a la Virgen del Carmen.\n\n'
            'Los chimila, que se llaman a sí mismos ette ennaka, son un pueblo indígena del Magdalena que habitó las selvas y sabanas entre la Sierra Nevada y el río Magdalena. '
            'Hoy viven en resguardos del centro del departamento. Las fotos históricas de esta publicación los muestran a comienzos del siglo XX: '
            'el etnógrafo sueco Gustaf Bolinder los fotografió en sus expediciones a la región.',
        validado: true,
        fuente: '$fPlan2000 $fOspino Imágenes: Gustaf Bolinder (1916), publicadas en “Chimila: los indios de la selva virgen”; grabado de autor por identificar. $fFotosEquipo',
        fuenteUrl: uPlan2000,
        imagenUrl: '${A}chimila_2.jpg',
        imagenes: <String>['${A}chimila_1.jpg', '${A}chimila_2.jpg', '${A}chimila_3.jpg']),
    _c('historia-independencia', 'historia', 4, 'Pijiño en la Independencia',
        'En 1812 tropas patriotas expulsaron a los españoles del territorio.',
        'Durante la guerra de Independencia, el capitán español Antonio Garnier ocupó el territorio en 1811.\n\n'
            'En octubre de 1812, tropas patriotas al mando de Vicente Gutiérrez de Piñeres y del coronel Pantaleón Germán Ribón incendiaron la población '
            'y expulsaron a las fuerzas españolas.\n\n'
            'PENDIENTE: contrastar este episodio con la bibliografía que cita el autor (Orlando Fals Borda, “Historia doble de la Costa”; José C. Alarcón, “Compendio de historia del Magdalena”).',
        fuente: fOspino,
        fuenteUrl: uOspino),
    _c('historia-municipio', 'historia', 5, 'De corregimiento a municipio (1996)',
        'La Ordenanza 001 del 26 de marzo de 1996 creó el municipio.',
        'Durante los siglos XIX y XX Pijiño fue corregimiento de Santa Ana. '
            'Mediante la Ordenanza n.º 001 del 26 de marzo de 1996, la Asamblea Departamental del Magdalena creó el municipio de Pijiño del Carmen, segregando su territorio de Santa Ana.\n\n'
            'Ramiro Machado Machado fue el primer alcalde elegido por voto popular; un busto suyo está en la Plaza Central Deportiva.\n\n'
            'En 2021 el municipio celebró 25 años de vida municipal.\n\n'
            'Las fotos de esta publicación pertenecen al archivo fotográfico de Antonio Eljadue y muestran a la comunidad en la época de la creación del municipio (una de ellas está fechada el 13 de abril de 1996) y una calle del pueblo de entonces.',
        validado: true,
        fuente: '$fAnt $fWikiEs $fOspino Fotos: archivo fotográfico de Antonio Eljadue.',
        fuenteUrl: uAnt,
        imagenUrl: '${A}archivo_1996_1.jpg',
        imagenes: <String>['${A}archivo_1996_1.jpg', '${A}archivo_1996_2.jpg', '${A}archivo_1996_3.jpg']),
    _c('historia-territorio', 'historia', 6, 'Corregimientos y veredas',
        'Siete corregimientos y más de 30 veredas.',
        'Según el Esquema de Ordenamiento Territorial (Acuerdo 006 de 2002), el municipio tiene 7 corregimientos:\n'
            'Cabrera, Casa Blanca, El Dividivi, Filadelfia, La Lucha, Las Planadas y San José de Prevención.\n\n'
            'Veredas (EOT 2002): Todos los Santos, Misuri, Nueva Holanda, El Olivo, El Tamaco, El Purgatorio, Buenos Aires, El Delirio, Ganímedes, '
            'El Hotel, Santa Fe, Tierra Morena, La Candelaria, El Brillante, Las Verduras, El Cariño, Las Tecas, El Laberinto, El Paraver, La Espiga, '
            'Las Marías, La Salsita, Nueva Estación, La Dicha, El Muñeco, Santa Teresa, Tolima, Las Flores, Maya Sola y Peladero.\n\n'
            'La cartografía social hecha con la comunidad reconoce 11 corregimientos y 31 veredas, con algunos nombres distintos. '
            'En la cabecera se mencionan barrios como La Baizana y El Retablo, y a orillas de la ciénaga está el caserío de Pita.\n\n'
            'Límites: al norte y al oeste, Santa Ana; al este, El Paso (Cesar); al sur, San Sebastián de Buenavista, San Zenón (Magdalena) y Astrea (Cesar).\n\n'
            'En las fotos: el corregimiento de Casa Blanca y un acto cívico frente a la iglesia de Cabrera.',
        validado: true,
        fuente: '$fAnt $fPlan2000 Fotos: Casa Blanca Magdalena; Cabrera Magdalena (@cabreramagdalena, Facebook).',
        fuenteUrl: uAnt,
        imagenUrl: '${A}cabrera.jpg',
        imagenes: <String>['${A}casa_blanca.jpg', '${A}cabrera.jpg']),
    _c('historia-economia', 'historia', 7, 'Economía: ganado, pesca y campo',
        'Cerca del 76 % del suelo productivo son pastos para ganadería.',
        'La base de la economía de Pijiño es la ganadería, seguida de la pesca artesanal y la agricultura.\n\n'
            '• Ganadería: de unas 55.800 ha dedicadas a la producción agropecuaria, cerca del 76 % son pastos para ganado bovino, con un inventario de unas 86.000 unidades de gran ganado. '
            'El ganado es de doble propósito (leche y cría); parte de la leche se convierte en queso costeño y el ganado en pie se vende en Magangué, Barranquilla, Santa Marta, Bucaramanga y Medellín.\n'
            '• Pesca: la ciénaga es la despensa del pueblo; el bocachico es la especie emblemática.\n'
            '• Agricultura (en su mayoría para autoconsumo): yuca, maíz, fríjol, plátano, ñame, batata, ajonjolí, patilla, melón, caña, hortalizas y frutales como mango, limón, papaya y guayaba.\n'
            '• Gas natural: en la zona de El Brillante se ha explorado gas natural (prospecto “Brillante Sureste”).\n\n'
            'La Central Ganadera Pijiño, presente en redes sociales, promociona ejemplares de razas lecheras como Gyr y Guzerat.',
        validado: true,
        fuente: '$fAnt $fGuia $fWikiEs Fotos: $fViajar Central Ganadera Pijiño (@central_ganadera_pijino); Alcaldía Municipal de Pijiño del Carmen.',
        fuenteUrl: uAnt,
        imagenUrl: '${A}ganado.jpg',
        imagenes: <String>['${A}ganado.jpg', '${A}central_ganadera.jpg', '${A}pesca_3.jpg', '${A}pesca_2.jpg']),
    _c('historia-simbolos', 'historia', 8, 'Símbolos municipales',
        'Bandera, escudo e himno de Pijiño del Carmen.',
        '• Escudo: blasón con borde dorado y una cinta en la parte superior, dividido en tres franjas: amarilla, con una garza blanca en vuelo; '
            'verde, con flores de pijiño, que representan el nombre del pueblo; y azul, con la ciénaga, una isla y un pescador en su canoa.\n'
            '• Bandera: tres franjas horizontales iguales con los mismos colores del escudo: amarilla arriba, verde en el centro y azul abajo.\n'
            '• Himno: letra de Luis Cipriano Oliveros Palomino. Narra el nacimiento del pueblo en La Baizana, el milagro de la tabla con la Virgen que flotó en la ciénaga, '
            'la vida del ganadero, el agricultor y el pescador, y los atardeceres de Pijiño. Su letra completa está en la publicación “Himno de Pijiño del Carmen”.\n\n'
            'PENDIENTE: confirmar con la Alcaldía el acuerdo que adoptó los símbolos, el significado oficial de sus colores, el texto de la cinta del escudo y la imagen oficial de la bandera '
            '(la imagen de bandera que circula en internet lleva en el centro un escudo distinto al municipal).',
        fuente: 'Documentos de símbolos aportados por el equipo Conecta con Pijiño; $fOspino',
        fuenteUrl: uOspino,
        imagenUrl: '${A}escudo.jpg',
        imagenes: <String>['${A}escudo.jpg', '${A}bandera.jpg']),
    _c('historia-himno', 'historia', 9, 'Himno de Pijiño del Carmen',
        'Letra de Luis Cipriano Oliveros Palomino.',
        'CORO\n'
            'Es Pijiño soberano y señorial\n'
            'Tus historias las venimos a contar\n'
            'Tus paisajes que contagian de alegría\n'
            'A todo aquel que te viene a visitar\n\n'
            'La Baizana fue quien dio tu nacimiento\n'
            'Cuenta la historia que fue por un pescador\n'
            'Que inspirado por sus grandes pijiñales\n'
            'Fue Pijiño como así te bautizó\n\n'
            'ESTROFA I\n'
            'Pijiño tiene bellos atardeceres\n'
            'Sol rojizo que lo quiere contemplar\n'
            'De mañana suave brisa te acaricia\n'
            'Te susurra como queriéndole hablar\n\n'
            'La cultura de Pijiño es resaltada\n'
            'Con la base de una buena educación\n'
            'El cristal del recuerdo es el espejo\n'
            'De esa historia que contamos con amor\n\n'
            'ESTROFA II\n'
            'Es Pijiño la cuna del ganadero\n'
            'Es emporio y es tierra de agricultor\n'
            'Va sembrando su semilla alegremente\n'
            'De su frente va saliendo su sudor\n\n'
            'La mañana despejada le va dando\n'
            'La esperanza al humilde pescador\n'
            'Que remando su canoa va cantando\n'
            'Y en sus redes lleva puesta su ilusión\n\n'
            'ESTROFA III\n'
            'De tus aguas salió el milagro más grande\n'
            'Fue una tabla que en tu ciénaga flotó\n'
            'Y una imagen que en ella se reflejaba\n'
            'Fue la Virgen que en tu suelo apareció\n\n'
            'El Descanso y Chingalé guardan historias\n'
            'De la gente que a sus orillas pasó\n'
            'Malos ratos por culpa de sus crecientes\n'
            'Aquel arriero que bastante padeció\n\n'
            'Autor: Luis Cipriano Oliveros Palomino.',
        validado: true,
        fuente: 'Documento de símbolos aportado por el equipo Conecta con Pijiño.',
        imagenUrl: '${A}escudo.jpg'),

    // ================================================================ CULTURA
    _c('cultura-atarraya', 'cultura', 1, 'La pesca con atarraya',
        'El oficio que inspira nuestro logo y nuestro slogan.',
        'La atarraya es la red circular que los pescadores de Pijiño lanzan desde la canoa con un movimiento amplio de brazos y cintura. '
            'Al caer al agua se abre como una flor y, al recogerla, atrapa los peces.\n\n'
            'Lanzar bien la atarraya es un saber que se aprende desde niño. El oficio incluye tejer y remendar la red, conocer los tiempos de subienda y respetar las tallas mínimas de captura.\n\n'
            'En el Festival del Bocachico se premia al mejor atarrayero.\n\n'
            '“El corazón de Pijiño en cada atarraya” expresa que la esencia del pueblo —su gente, su trabajo y sus tradiciones— está presente en cada lance.',
        validado: true,
        fuente: 'Documento del proyecto APP-Conecta con Pijiño; Viaja por Colombia, “Inician preparativos para el Festival del Bocachico”. Fotos: Alcaldía Municipal de Pijiño del Carmen.',
        imagenUrl: '${A}pesca_1.jpg',
        imagenes: <String>['${A}pesca_1.jpg', '${A}pesca_5.jpg', '${A}pesca_4.jpg', '${A}logo.png']),
    _c('cultura-retablo', 'cultura', 2, 'La Virgen del Retablo',
        'La procesión del 3 de mayo, “la conmemoración más auténtica” del pueblo.',
        'Cada 3 de mayo sale en procesión el retablo de la Virgen de Pijiño: una imagen impresa en un tablón que, según la tradición, un lugareño encontró en la ciénaga.\n\n'
            'Las familias sacan a la calle altares caseros con velas para que la Virgen los bendiga a su paso, acompañada por la banda de vientos.\n\n'
            'Es distinta de la fiesta patronal de la Virgen del Carmen (16 de julio), aunque ambas tradiciones están ligadas a la leyenda de la imagen salida del agua.',
        validado: true,
        fuente: '$fViajar El Heraldo, 5 de mayo de 2020. $fGuia',
        fuenteUrl: uViajar,
        lugar: 'Iglesia y calles de la cabecera'),
    _c('cultura-bailes', 'cultura', 3, 'Bailes cantaos: chandé y pajarito',
        'Tambor, palmas y canto de la ribera.',
        'Los bailes cantaos son parte de la identidad pijiñera, en especial el chandé y el pajarito, propios de los pueblos ribereños de la Depresión Momposina.\n\n'
            'Agrupaciones mencionadas: Los Negritos de Pijiño, Son Pijiñero y el Grupo Renacer de Cabrera, iniciado con la llegada de la familia Dávila a comienzos de los años cincuenta.\n\n'
            'PENDIENTE: entrevistar a las agrupaciones y a sus cantadoras, y grabar con autorización fragmentos de sus presentaciones para la galería.',
        fuente: fOspino,
        fuenteUrl: uOspino,
        videoUrl: 'https://www.youtube.com/watch?v=yCpBmrhGaBE'),
    _c('cultura-banda', 'cultura', 4, 'Banda 16 de Julio, “La Remendá”',
        'Banda de vientos fundada en 1937.',
        'La Banda 16 de Julio, conocida popularmente como “La Remendá”, surgió en 1937, después de que la banda de Santa Ana se desintegrara por la situación política de la época. '
            'La dirigió el trompetista Trinidad Jiménez.\n\n'
            'Su nombre recuerda el 16 de julio, día de la Virgen del Carmen, patrona del pueblo.',
        fuente: fOspino,
        fuenteUrl: uOspino2015,
        videoUrl: 'https://www.youtube.com/watch?v=u3DOiZ9ilK8'),
    _c('cultura-letras', 'cultura', 5, 'Tradición oral y literatura',
        'Mitos, leyendas, crónicas y hasta un periódico propio.',
        'Pijiño tiene una tradición literaria propia:\n\n'
            '• Esginio Arrieta López escribió “Pijiño, sus mitos y sus leyendas” y es considerado el principal referente literario local.\n'
            '• Ángel Cáceres escribió “Pijiño 500 años”.\n'
            '• Elías Abad Palomino Jiménez (1917–1951) escribió la novela “El cristal de los recuerdos”; la Casa de la Cultura lleva su nombre.\n'
            '• En 1957 circulaba en Pijiño el periódico “Linterna”, editado por Miguel Aguilar Amarís.\n\n'
            'PENDIENTE: conseguir ejemplares de estos libros para la biblioteca de la institución y transcribir, con autorización, algunos mitos y leyendas.',
        fuente: '$fOspino Enlace de literatura sugerido por el equipo: Otraparte, “Somos”.',
        fuenteUrl: 'https://www.otraparte.org/agenda-cultural/literatura/somos/'),
    _c('cultura-cesta-movil', 'cultura', 6, 'La cesta móvil, un deporte nacido en Pijiño',
        'Un juego tipo baloncesto que se puede jugar hasta en el agua.',
        'La cesta móvil es un deporte creado en Pijiño por el docente de educación física Álvaro Vásquez Oñate. '
            'Se juega entre 12 personas (6 por equipo), la cesta es portátil y se puede practicar casi en cualquier lugar, incluso dentro del agua.\n\n'
            'PENDIENTE: grabar un partido y documentar el reglamento con su creador.',
        fuente: fOspino,
        fuenteUrl: uOspino2015),
    _c('cultura-artesania', 'cultura', 7, 'Cucharas de pijiño y casas de bahareque',
        'Oficios y saberes que nacen del territorio.',
        '• La madera del árbol de pijiño, de color rosado y aspecto vidrioso, se ha usado tradicionalmente para tallar cucharas de palo.\n'
            '• En el pueblo aún se ven casas de bahareque, con muros de barro y caña brava, una técnica de construcción tradicional del Caribe ribereño.\n\n'
            'PENDIENTE: identificar artesanos y maestros de obra que conserven estos saberes.',
        fuente: '$fOspino $fViajar',
        fuenteUrl: uViajar),

    // ================================================================ PERSONAJES
    _c('personaje-elias-abad', 'personajes', 1, 'Elías Abad Palomino Jiménez',
        'Escritor pijiñero (1917–1951).',
        'Nació en Pijiño el 20 de julio de 1917 y murió en El Difícil (Magdalena) el 4 de agosto de 1951. '
            'Escritor autodidacta de novela y poesía, autor de “El cristal de los recuerdos”.\n\n'
            'La Casa de la Cultura de Pijiño, restaurada por la administración municipal, lleva su nombre.',
        fuente: fOspino,
        fuenteUrl: uOspino2015),
    _c('personaje-duque-palomino', 'personajes', 2, 'Duque Palomino',
        'Compositor e intérprete; da nombre al festival de la canción.',
        'Compositor e intérprete pijiñero, director del Combo de Duque Palomino, que en 1968 grabó un éxito en larga duración con la voz de Gustavo Barros. '
            'Entre sus composiciones se mencionan “Recuerdos de Alicia” y “Cumbia de amores”.\n\n'
            'En su honor se realiza cada año en Pijiño el Festival de la Canción Duque Palomino.',
        fuente: fOspino,
        fuenteUrl: uOspino2015),
    _c('personaje-garizao', 'personajes', 3, 'Carmelo Garizao Tobías',
        'Acordeonero y juglar vallenato.',
        'Acordeonero y juglar nacido en 1936. Recibió su primer acordeón a los 18 años y llegó a tocar junto a Calixto Ochoa.\n\n'
            'La Plaza Garizao, en el barrio El Retablo, lleva su apellido; allí se realizó en 2019 el primer Festival de la Integración Pijiñera.',
        fuente: fOspino,
        fuenteUrl: uOspino),
    _c('personaje-compositores', 'personajes', 4, 'Compositores pijiñeros',
        'Las canciones que le cantan al pueblo.',
        '• Luis Oliveros Palomino: autor de la letra del himno municipal.\n'
            '• Martín Alonso Arrieta López: autor de “El pijiñero”.\n'
            '• Gerardo Oliveros: autor de “El salao”.\n'
            '• Martín Mendoza: compositor.\n\n'
            'PENDIENTE: recopilar letras y grabaciones con autorización de los autores o sus familias.',
        fuente: fOspino,
        fuenteUrl: uOspino2015),
    _c('personaje-edgar-jimenez', 'personajes', 5, 'Edgar Francisco Jiménez López',
        'Pintor pijiñero con trayectoria internacional.',
        'Pintor nacido en Pijiño en 1951. Estudió en Bogotá, París, Barcelona y Hong Kong, vivió doce años en Asia y luego en Toronto (1995–2006), y reside en Bogotá.\n\n'
            'PENDIENTE: contactar al artista o a su familia para incluir imágenes de su obra con autorización.',
        fuente: fOspino,
        fuenteUrl: uOspino2015),
    _c('personaje-otros', 'personajes', 6, 'Otros personajes',
        'Músicos, médicos y deportistas que marcaron al pueblo.',
        '• Trinidad Jiménez: trompetista y director de la Banda 16 de Julio (1937).\n'
            '• Alejandro Durán Gómez: nacido en Pijiño en 1955, hijo del maestro vallenato Alejo Durán; actor en la serie “Rey de reyes” de Telecaribe.\n'
            '• Alberto Arturo Hernández Reyes (1927–2010): médico de la Universidad de Cartagena que ejerció en Pijiño.\n'
            '• Álvaro Vásquez Oñate: docente creador de la cesta móvil.\n\n'
            'PENDIENTE: ampliar esta lista con la comunidad (cantadoras, pescadores, parteras, docentes y líderes).',
        fuente: fOspino,
        fuenteUrl: uOspino),

    // ================================================================ GASTRONOMÍA
    _c('gastro-bocachico', 'gastronomia', 1, 'Bocachico: el rey de la mesa',
        'Frito, en sancocho o como protagonista del festival.',
        'El bocachico es el pescado emblemático de la ciénaga y tiene su propio festival cada julio, donde se premia el plato de pescado mejor preparado.\n\n'
            'Frito: se limpia, se le hacen cortes a los lados para ablandar la espina, se sazona con sal y limón y se fríe hasta dorar. '
            'Se acompaña con patacón, arroz, yuca y suero costeño.\n\n'
            'PENDIENTE: registrar la receta de una cocinera ganadora del concurso del Festival del Bocachico, con su nombre y foto.',
        validado: true,
        fuente: '$fOpinion2017 $fOspino',
        fuenteUrl: uOpinion2017),
    _c('gastro-platos', 'gastronomia', 2, 'Platos típicos de Pijiño',
        'Sancochos, sopa de arroz, mafufo y más.',
        'Platos representativos del municipio:\n\n'
            '• Sancocho de pescado y sancocho de coroncoro.\n'
            '• Sancocho de pavo.\n'
            '• Sopa de arroz.\n'
            '• Chicharrón.\n'
            '• Bollo limpio y yuca.\n'
            '• Mafufo.\n'
            '• Desmechado de conejo.\n'
            '• Queso costeño y suero.\n\n'
            'PENDIENTE: escribir la receta de cada plato con una cocinera tradicional.',
        validado: true,
        fuente: '$fGuia $fWikiEs',
        fuenteUrl: uGuia),
    _c('gastro-dulces-bebidas', 'gastronomia', 3, 'Dulces y bebidas',
        'Dulces de fríjol, ñame y papaya; chicha de arroz y piña.',
        'Dulces: de fríjol, de leche, de ñame y de papaya.\n\n'
            'Bebidas: ponche, mazamorra de maíz y chicha de arroz con piña (preparada aprovechando también la cáscara de la piña).',
        validado: true,
        fuente: '$fGuia $fViajar',
        fuenteUrl: uGuia),
    _c('gastro-queso', 'gastronomia', 4, 'Queso costeño',
        'La leche de los hatos pijiñeros convertida en queso.',
        'Como municipio ganadero de doble propósito, parte de la leche de Pijiño se transforma en queso costeño, que acompaña el bollo, la yuca y el pescado en la mesa diaria.\n\n'
            'PENDIENTE: identificar productores locales de queso para el directorio.',
        validado: true,
        fuente: '$fWikiEs $fAnt',
        fuenteUrl: uWikiEs),
    _c('gastro-memoria', 'gastronomia', 5, 'Recetas de la memoria',
        'Pebres de galápago y morrocoyo, y el ñeque: tradición y conservación.',
        'Entre los platos tradicionales que recuerdan los mayores están el pebre de galápago, el pebre de morrocoyo y el ñeque.\n\n'
            'Hoy, las tortugas como el morrocoyo y el galápago están amenazadas, y su caza y comercio están restringidos por la ley colombiana. '
            'Por eso estas recetas se conservan como memoria cultural y no como invitación a consumirlas: la mejor manera de honrarlas es contarlas y proteger a las especies.',
        validado: true,
        fuente: '$fGuia Normativa ambiental colombiana sobre fauna silvestre.',
        fuenteUrl: uGuia),

    // ================================================================ TURISMO
    _c('turismo-cienaga', 'turismo', 1, 'Ciénaga de Pijiño',
        'Unos 56 km de espejo de agua, aves e iguanas.',
        'La ciénaga de Pijiño, de unos 56 km de longitud, es la base de la economía y el gran atractivo natural de la región. '
            'Se comunica con el brazo de Mompox del río Magdalena por los caños Pijiño, La Ceiba, Sacabuche y Trapiche, y recibe las aguas del arroyo Cubalibre, '
            'el arroyo Chingalé (o quebrada Culebra) y el caño Camargo.\n\n'
            'En lancha se observan martín pescadores, gavilanes, halcones, cormoranes y muchas otras aves, iguanas en las orillas y pescadores en sus canoas.\n\n'
            'Desde Mompox salen paseos en lancha por el río Magdalena hasta la ciénaga y el pueblo, con regreso al atardecer.',
        validado: true,
        fuente: '$fOspino $fNiko Procolombia (colombia.travel), “Take a day trip to Pijiño”. Fotos: Alcaldía Municipal de Pijiño del Carmen.',
        fuenteUrl: uNiko,
        lugar: 'Ciénaga de Pijiño',
        imagenUrl: '${A}pesca_2.jpg',
        imagenes: <String>['${A}pesca_2.jpg', '${A}pesca_1.jpg', '${A}pesca_4.jpg']),
    _c('turismo-malecon', 'turismo', 2, 'Malecón y ciénaga El Palmar',
        'Plaza y paseo frente al agua para ver el atardecer.',
        'La ciénaga El Palmar, de aguas limpias y plantas acuáticas de flores violeta, es uno de los atractivos más importantes del municipio.\n\n'
            'Frente a ella se construyó el malecón turístico, un proyecto pensado junto con el jarillón para proteger y revitalizar el centro histórico, afectado por las inundaciones. '
            'Incluye plazoleta, escaleras y rampa, puerto, puente, zonas verdes, baños públicos y un restaurante en la isla de arena.\n\n'
            'Es punto de encuentro para caminar, bañarse y ver el atardecer.',
        validado: true,
        fuente: '$fOpinion2017 $fViajar $fOspino Video “Plaza y malecón turístico en el municipio de Pijiño del Carmen” (2018).',
        fuenteUrl: 'https://www.youtube.com/watch?v=k7QvwMrswA4',
        lugar: 'Cabecera municipal, frente a la ciénaga El Palmar',
        videoUrl: 'https://www.youtube.com/watch?v=k7QvwMrswA4',
        imagenUrl: 'asset:assets/images/fondo_login.jpg'),
    _c('turismo-isla-verde', 'turismo', 3, 'Isla Verde',
        'Islote recreativo al que se llega en chalupa.',
        'En una pequeña isla de la ciénaga El Palmar, cerca de Filadelfia, está Isla Verde, un lugar de recreación al que se llega en chalupa. '
            'De día es un plan familiar y de noche un sitio de fiesta.',
        validado: true,
        fuente: '$fOspino $fGuia',
        fuenteUrl: uOspino2015,
        lugar: 'Ciénaga El Palmar, cerca de Filadelfia'),
    _c('turismo-arenada', 'turismo', 4, 'Isla La Arenada',
        'La isla de arena frente al pueblo, sede del Festival del Bocachico.',
        'Frente al barrio La Baizana está la isla La Arenada (también llamada El Arenal o La Arená), escenario del Festival del Bocachico y lugar con mucha presencia de aves.',
        validado: true,
        fuente: '$fOspino $fViajar $fGuia',
        fuenteUrl: uViajar,
        lugar: 'Frente al barrio La Baizana'),
    _c('turismo-balnearios', 'turismo', 5, 'Balnearios de la ciénaga',
        'La Puntica del Pozo, La Vizcaína y más.',
        'Además de Isla Verde y La Arenada, la ciénaga ofrece balnearios tradicionales como La Puntica del Pozo y La Vizcaína.\n\n'
            'Recomendaciones: báñate solo en zonas poco profundas y conocidas, no vayas solo y usa chaleco en las lanchas.\n\n'
            'PENDIENTE: ubicar cada balneario en el mapa con sus coordenadas.',
        validado: true,
        fuente: '$fGuia $fWikiEs',
        fuenteUrl: uGuia),
    _c('turismo-iglesia', 'turismo', 6, 'Parroquia Nuestra Señora del Carmen',
        'El templo de la patrona, sobre una plataforma de un metro.',
        'La iglesia de Nuestra Señora del Carmen, considerada patrimonio de la localidad, es el principal lugar de oración del pueblo. '
            'Está construida sobre una plataforma de un metro de altura y no tiene torre; antes era blanca y hoy luce colores llamativos. En su plaza está la imagen de la Virgen del Carmen.',
        validado: true,
        fuente: '$fGuia $fViajar',
        fuenteUrl: uGuia,
        lugar: 'Plaza principal',
        lat: AppConfig.latCentro,
        lng: AppConfig.lngCentro),
    _c('turismo-plazas', 'turismo', 7, 'Plazas y Casa de la Cultura',
        'Plaza Central Deportiva, Plaza Garizao y Casa de la Cultura Elías Abad Palomino.',
        '• Plaza Central Deportiva: remodelada e inaugurada en mayo de 2019; tiene un busto de Ramiro Machado Machado, primer alcalde popular.\n'
            '• Plaza Garizao: en el barrio El Retablo, construida en una zona antes pantanosa; sede del Festival de la Integración Pijiñera.\n'
            '• Casa de la Cultura Elías Abad Palomino: restaurada por la administración municipal.\n'
            '• Cementerio municipal: con un amplio parque al frente y mausoleos antiguos.',
        fuente: '$fOspino $fViajar',
        fuenteUrl: uOspino),
    _c('turismo-como-llegar', 'turismo', 8, 'Cómo llegar a Pijiño',
        'Por aire, tierra y agua.',
        '• Por aire: el aeropuerto San Bernardo de Mompox está a unos 20 minutos.\n'
            '• Por tierra: por la vía La Gloria–Bosconia y por Santa Ana–San Zenón. Desde Santa Ana son unos 10 km de vía pavimentada.\n'
            '• Por agua: hay conexión fluvial con El Banco, Mompox, Magangué y Santa Bárbara de Pinto. Desde Mompox salen paseos en lancha por el río Magdalena y los caños.\n\n'
            'Santa Marta, la capital del departamento, está a unos 325 km por carretera.',
        validado: true,
        fuente: '$fWikiEs $fGuia $fViajar',
        fuenteUrl: uGuia),

    // ================================================================ EVENTOS (próximas fechas)
    _c('evento-inmaculada', 'eventos', 1, 'Inmaculada Concepción en Casa Blanca',
        'Fiesta patronal del corregimiento de Casa Blanca.',
        'El corregimiento de Casa Blanca celebra cada 8 de diciembre las fiestas patronales de la Inmaculada Concepción.',
        validado: true,
        fuente: '$fGuia $fOpinion2017',
        fuenteUrl: uGuia,
        lugar: 'Casa Blanca',
        fecha: DateTime(2026, 12, 8, 9)),
    _c('evento-novenas', 'eventos', 2, 'Novenas de aguinaldos',
        'Del 16 al 24 de diciembre.',
        'Las familias y los barrios se reúnen a rezar la novena, cantar villancicos y compartir.\n\nPENDIENTE: confirmar las actividades propias del municipio.',
        fuente: 'Tradición nacional. Por validar.',
        lugar: 'Barrios del municipio',
        fecha: DateTime(2026, 12, 16, 18)),
    _c('evento-divino-nino', 'eventos', 3, 'Divino Niño en Nueva Holanda',
        'Fiesta del 25 de diciembre en la vereda Nueva Holanda.',
        'La vereda Nueva Holanda celebra cada 25 de diciembre la fiesta del Divino Niño.',
        validado: true,
        fuente: '$fGuia $fWikiEs',
        fuenteUrl: uGuia,
        lugar: 'Nueva Holanda',
        fecha: DateTime(2026, 12, 25, 10)),
    _c('evento-carnavales', 'eventos', 4, 'Carnavales',
        'Música, disfraces y verbenas antes del Miércoles de Ceniza.',
        'Pijiño celebra sus carnavales en los días previos al Miércoles de Ceniza. En 2027 el Miércoles de Ceniza es el 10 de febrero.\n\n'
            'PENDIENTE: confirmar la programación con la Casa de la Cultura.',
        validado: true,
        fuente: '$fGuia $fViajar',
        fuenteUrl: uGuia,
        lugar: 'Cabecera municipal',
        fecha: DateTime(2027, 2, 6, 15)),
    _c('evento-semana-santa', 'eventos', 5, 'Semana Santa',
        'Una de las celebraciones más concurridas del pueblo.',
        'Pijiño es el municipio con más celebraciones religiosas de la región, y la Semana Santa es de las más concurridas. En 2027 va del 21 (Domingo de Ramos) al 28 de marzo (Domingo de Resurrección).',
        validado: true,
        fuente: '$fOpinion2017 $fViajar',
        fuenteUrl: uOpinion2017,
        lugar: 'Parroquia Nuestra Señora del Carmen',
        fecha: DateTime(2027, 3, 21, 8)),
    _c('evento-retablo', 'eventos', 6, 'Virgen del Retablo',
        'Procesión del 3 de mayo.',
        'Sale en procesión el retablo de la Virgen de Pijiño, la imagen que según la tradición se encontró en la ciénaga. Las familias la reciben con altares y velas.',
        validado: true,
        fuente: '$fGuia $fViajar El Heraldo (2020).',
        fuenteUrl: uViajar,
        lugar: 'Calles de la cabecera',
        fecha: DateTime(2027, 5, 3, 16)),
    _c('evento-fiestas-carmen', 'eventos', 7, 'Fiestas patronales de la Virgen del Carmen',
        '16 de julio: la fiesta mayor de Pijiño.',
        'El 16 de julio se celebra a Nuestra Señora del Carmen, patrona del municipio, con misas, procesión, música de banda y encuentro de la comunidad. '
            'En las mismas fechas se realizan la Feria Ganadera y el Festival del Bocachico.',
        validado: true,
        fuente: '$fWikiEs $fGuia $fOspino',
        fuenteUrl: uWikiEs,
        lugar: 'Plaza principal',
        fecha: DateTime(2027, 7, 16, 9)),
    _c('evento-bocachico', 'eventos', 8, 'Festival del Bocachico',
        'Desde 2002, el homenaje a los pescadores (17 de julio).',
        'Se realiza desde julio de 2002 en honor a los pescadores, en la isla La Arenada frente al barrio La Baizana. Es el principal atractivo turístico del municipio.\n\n'
            'Concursos y actividades:\n'
            '• Mejor atarrayero.\n'
            '• Pez más grande.\n'
            '• Plato de pescado mejor preparado.\n'
            '• Canotaje.\n'
            '• Reinado del Bocachico (en algunas ediciones, intermunicipal, con candidatas de pueblos ribereños del Magdalena y Bolívar).\n'
            '• Muestras culturales y folclóricas, y corralejas.',
        validado: true,
        fuente: '$fOpinion2017 $fGuia $fOspino Viaja por Colombia.',
        fuenteUrl: uOpinion2017,
        lugar: 'Isla La Arenada',
        fecha: DateTime(2027, 7, 17, 10)),
    _c('evento-transito', 'eventos', 9, 'Nuestra Señora del Tránsito en Cabrera',
        'Fiesta patronal del 15 de agosto.',
        'El corregimiento de Cabrera celebra cada 15 de agosto a Nuestra Señora del Tránsito.',
        validado: true,
        fuente: '$fGuia $fWikiEs $fOpinion2017',
        fuenteUrl: uGuia,
        lugar: 'Cabrera',
        fecha: DateTime(2027, 8, 15, 9)),
    _c('evento-duque-palomino', 'eventos', 10, 'Festival de la Canción Duque Palomino',
        'Concurso anual de canción en honor al compositor pijiñero.',
        'Festival anual que rinde homenaje al compositor Duque Palomino.\n\nPENDIENTE: confirmar fecha y bases del concurso.',
        fuente: fOspino,
        fuenteUrl: uOspino2015,
        lugar: 'Cabecera municipal'),
    _c('evento-maiz', 'eventos', 11, 'Festival del Maíz',
        'Canciones inéditas en San José de Prevención.',
        'En el corregimiento de San José de Prevención se realiza el Festival del Maíz, dedicado a canciones inéditas de compositores de la región.\n\nPENDIENTE: confirmar fecha.',
        fuente: fOspino,
        fuenteUrl: uOspino2015,
        lugar: 'San José de Prevención'),
    _c('evento-integracion', 'eventos', 12, 'Festival de la Integración Pijiñera',
        'Encuentro de pijiñeros iniciado en 2019.',
        'Su primera versión se realizó en 2019 en la Plaza Garizao.\n\nPENDIENTE: confirmar si continúa y en qué fecha.',
        fuente: fOspino,
        fuenteUrl: uOspino,
        lugar: 'Plaza Garizao'),

    // ================================================================ AMBIENTE
    _c('ambiente-cienaga', 'ambiente', 1, 'Cuidemos la ciénaga',
        'Sin ciénaga no hay pesca, ni comida, ni pueblo.',
        'En mayo de 2020, durante una fuerte sequía, el nivel de la ciénaga bajó a menos de una cuarta y murieron miles de peces —entre ellos bocachicos y albacoras— y algunas rayas, '
            'por la falta de oxígeno y el recalentamiento del agua. Los habitantes pidieron construir una compuerta en el caño para retener el agua.\n\n'
            'Para protegerla:\n'
            '• No arrojes basuras, plásticos ni aceites al agua.\n'
            '• Respeta las vedas y tallas mínimas de captura establecidas por la AUNAP.\n'
            '• Usa redes con el tamaño de malla permitido.\n'
            '• No quemes ni deforestes las orillas.\n'
            '• Reporta mortandades de peces a la autoridad ambiental (Corpamag).',
        validado: true,
        fuente: 'El Informador, “Denuncian desastre ambiental en la Ciénaga de Pijiño del Carmen” (11 de mayo de 2020); Diario La Libertad (13 de mayo de 2020).',
        fuenteUrl: 'https://www.elinformador.com.co/index.php/el-magdalena/83-departamento/231989-denuncian-desastre-ambiental-en-la-cienaga-de-pijino-del-carmen-magdalena'),
    _c('ambiente-fauna', 'ambiente', 2, 'Fauna de la ciénaga',
        'Aves, iguanas, rayas y peces.',
        'En la ciénaga y sus caños se observan martín pescadores, gavilanes, halcones, cormoranes y bandadas de aves que vuelan sobre las canoas en busca de alimento; '
            'iguanas en las orillas; y peces como el bocachico y la albacora, además de rayas.\n\n'
            '• Observa a los animales sin perseguirlos ni alimentarlos.\n'
            '• No compres aves cantoras en jaula ni huevos o carne de iguana o tortuga.\n\n'
            'PENDIENTE: elaborar con la comunidad un inventario fotográfico de especies.',
        validado: true,
        fuente: '$fNiko $fViajar El Informador (2020).',
        fuenteUrl: uNiko),
    _c('ambiente-pijino-arbol', 'ambiente', 3, 'El árbol de pijiño',
        'El árbol que le da nombre al pueblo y florece en su escudo.',
        'Los árboles de pijiño abundaban en los humedales de La Baizana; por eso el primer asentamiento se llamó “Hatillo de Pijiño”, y sus flores aparecen en el escudo municipal.\n\n'
            'El equipo identificó el pijiño como Sapium glandulosum, de la familia de las euforbiáceas (la misma del caucho y el lechero):\n'
            '• Árbol mediano, que puede llegar a unos 20 m de altura, de tronco recto y corteza lisa y grisácea.\n'
            '• Al cortarlo suelta un látex blanco que irrita los ojos: no lo toques y luego te frotes la cara.\n'
            '• Hojas simples, alternas, alargadas y con el borde finamente aserrado.\n'
            '• Flores pequeñas y verdosas en espigas al final de las ramas; frutos en cápsula que se abren al madurar.\n'
            '• Sus semillas alimentan aves y pequeños mamíferos, y sirve para reforestar zonas degradadas.\n'
            '• Según la tradición local, su madera rosada se usaba para tallar cucharas de palo.\n\n'
            'Sembrar pijiños es una forma de recuperar la memoria y la sombra del pueblo.\n\n'
            'PENDIENTE: algunas fuentes identifican el pijiño como Genipa americana (jagua). Enviar fotos de hojas, flores y frutos de un árbol de Pijiño al herbario del Jardín Botánico de Bogotá o a una universidad para confirmar la especie.',
        fuente: '$fTananeos Wikipedia, “Sapium glandulosum”. $fOspino Fotos: Portal Tudo Sobre Plantas; Árvores do Bioma Cerrado; aporte del equipo.',
        fuenteUrl: uTananeos,
        imagenUrl: '${A}pijino_arbol_1.jpg',
        imagenes: <String>['${A}pijino_arbol_1.jpg', '${A}pijino_arbol_2.jpg', '${A}pijino_arbol_3.jpg', '${A}escudo.jpg']),
    _c('ambiente-bosque', 'ambiente', 4, 'Bosque y deforestación',
        'El bosque tropical seco ha disminuido para abrir potreros.',
        'El municipio tiene clima tropical con dos temporadas de lluvias y dos secas, y una precipitación media cercana a 1.266 mm al año.\n\n'
            'Su vegetación original de bosque tropical seco se ha reducido mucho por la tala para establecer hatos ganaderos. '
            'Entre los problemas ambientales identificados están la deforestación, la erosión, los incendios forestales, la contaminación del agua y el manejo inadecuado de residuos.',
        validado: true,
        fuente: '$fPlan2000 $fAnt',
        fuenteUrl: uPlan2000),
    _c('ambiente-riesgo', 'ambiente', 5, 'Inundaciones y sequías',
        'Vivir con el agua: prevención del riesgo.',
        'Buena parte del territorio es plano e inundable, y el centro histórico ha sufrido inundaciones repetidas; por eso se construyó un jarillón (dique) junto al malecón. '
            'En temporada seca, en cambio, la ciénaga puede bajar tanto que mueren los peces.\n\n'
            '• Conoce las rutas de evacuación y el plan de gestión del riesgo del municipio.\n'
            '• En temporada de lluvias, mantén documentos y medicamentos en bolsas impermeables.\n'
            '• En temporada seca, ahorra agua y evita quemas.',
        validado: true,
        fuente: '$fPlan2000 $fWikiEs Video del proyecto del malecón (2018); Plan Municipal de Gestión del Riesgo (UNGRD, 2012).',
        fuenteUrl: 'https://repositorio.gestiondelriesgo.gov.co/handle/20.500.11762/28347'),
    _c('ambiente-visitantes', 'ambiente', 6, 'Guía del visitante responsable',
        'Disfruta Pijiño dejando solo huellas.',
        '• Lleva de vuelta tu basura.\n'
            '• Usa chaleco salvavidas en los recorridos por el agua.\n'
            '• Compra productos locales y contrata guías del pueblo.\n'
            '• Pide permiso antes de fotografiar a las personas.\n'
            '• No compres animales silvestres ni productos hechos con ellos.',
        validado: true,
        fuente: 'Equipo Conecta con Pijiño.'),
  ];

  static final List<Map<String, dynamic>> galeria = <Map<String, dynamic>>[
    <String, dynamic>{
      'slug': 'galeria-logo',
      'tipo': 'foto',
      'url': 'asset:assets/images/logo.png',
      'titulo': 'Logo de APP-Conecta con Pijiño',
      'descripcion': 'Pescador lanzando la atarraya desde la canoa, palmera y sol: símbolos de nuestro pueblo.',
      'autorNombre': 'Equipo Conecta con Pijiño',
    },
    <String, dynamic>{
      'slug': 'galeria-organigrama',
      'tipo': 'foto',
      'url': 'asset:assets/images/organigrama.jpg',
      'titulo': 'Organigrama del proyecto',
      'descripcion': 'Estructura jerárquico-funcional del equipo Conecta con Pijiño.',
      'autorNombre': 'Equipo Conecta con Pijiño',
    },
    <String, dynamic>{
      'slug': 'galeria-malecon',
      'tipo': 'foto',
      'url': 'asset:assets/images/fondo_login.jpg',
      'titulo': 'Malecón de Pijiño',
      'descripcion': 'Pasarela del malecón frente a la ciénaga El Palmar, con sus barandas amarillas y piso de colores.',
      'autorNombre': 'Equipo Conecta con Pijiño',
    },
    <String, dynamic>{
      'slug': 'galeria-bandera',
      'tipo': 'foto',
      'url': 'asset:assets/images/bandera.jpg',
      'titulo': 'Bandera de Pijiño del Carmen',
      'descripcion': 'Franjas amarilla, verde y azul. Imagen por confirmar con la Alcaldía: el escudo del centro no coincide con el escudo municipal.',
      'autorNombre': 'Equipo Conecta con Pijiño',
    },
    <String, dynamic>{
      'slug': 'galeria-emblema-iedt',
      'tipo': 'foto',
      'url': 'asset:assets/images/emblema_iedt.jpg',
      'titulo': 'Emblema de la IE Pijiño del Carmen',
      'descripcion': '“Educación y Actitud Positiva”: libro, antorcha, la ciénaga y el pescador con su atarraya.',
      'autorNombre': 'Equipo Conecta con Pijiño',
    },
    _g('galeria-escudo', 'escudo.jpg', 'Escudo de Pijiño del Carmen', 'Garza blanca, flores de pijiño y la ciénaga con un pescador en su canoa.', 'Equipo Conecta con Pijiño'),
    _g('galeria-pesca-1', 'pesca_1.jpg', 'Lance de atarraya', 'Pescadores lanzando la atarraya desde la canoa en la ciénaga.', 'Alcaldía Municipal de Pijiño del Carmen'),
    _g('galeria-pesca-2', 'pesca_2.jpg', 'Canoas en la ciénaga', 'Pescadores en sus canoas sobre la ciénaga de Pijiño.', 'Alcaldía Municipal de Pijiño del Carmen'),
    _g('galeria-pesca-3', 'pesca_3.jpg', 'La pesca del día', 'Pescado fresco de la ciénaga listo para la venta.', 'Alcaldía Municipal de Pijiño del Carmen'),
    _g('galeria-pesca-4', 'pesca_4.jpg', 'Pescador en su canoa', 'Pescador remando en la ciénaga.', 'Alcaldía Municipal de Pijiño del Carmen'),
    _g('galeria-pesca-5', 'pesca_5.jpg', 'La atarraya abierta', 'La red se abre como una flor al caer al agua.', 'Alcaldía Municipal de Pijiño del Carmen'),
    _g('galeria-ganado', 'ganado.jpg', 'Ganado en los potreros', 'La ganadería es la base de la economía del municipio.', 'Viajar en Verano'),
    _g('galeria-central-ganadera', 'central_ganadera.jpg', 'Central Ganadera Pijiño', 'Ejemplares de razas Gyr y Guzerat (2025).', 'Central Ganadera Pijiño'),
    _g('galeria-casa-blanca', 'casa_blanca.jpg', 'Corregimiento de Casa Blanca', 'Vista del corregimiento de Casa Blanca.', 'Casa Blanca Magdalena'),
    _g('galeria-cabrera', 'cabrera.jpg', 'Corregimiento de Cabrera', 'Acto cívico frente a la iglesia de Cabrera.', 'Cabrera Magdalena (Facebook)'),
    _g('galeria-archivo-1996-1', 'archivo_1996_1.jpg', 'Pijiñeros en 1996', 'Comunidad reunida el 13 de abril de 1996, año de la creación del municipio.', 'Archivo fotográfico de Antonio Eljadue'),
    _g('galeria-archivo-1996-2', 'archivo_1996_2.jpg', 'Multitud en la plaza (años noventa)', 'La comunidad reunida en la época de la creación del municipio.', 'Archivo fotográfico de Antonio Eljadue'),
    _g('galeria-archivo-1996-3', 'archivo_1996_3.jpg', 'Calle del Pijiño de antes', 'Casas y calle de tierra del pueblo en otra época.', 'Archivo fotográfico de Antonio Eljadue'),
    _g('galeria-pijino-1', 'pijino_arbol_1.jpg', 'Árbol de pijiño', 'Ramas y frutos del árbol que da nombre al pueblo.', 'Portal Tudo Sobre Plantas'),
    _g('galeria-pijino-2', 'pijino_arbol_2.jpg', 'Frutos del pijiño', 'Hojas y frutos verdes del pijiño.', 'Aporte del equipo'),
    _g('galeria-pijino-3', 'pijino_arbol_3.jpg', 'Rama de pijiño', 'Rama con hojas y espiga de frutos.', 'Árvores do Bioma Cerrado'),
    _g('galeria-chimila-1', 'chimila_1.jpg', 'Indígena chimila', 'Fotografía histórica de un hombre chimila (comienzos del siglo XX).', 'Gustaf Bolinder'),
    _g('galeria-chimila-2', 'chimila_2.jpg', 'Familia chimila', 'Grabado histórico de una familia chimila junto a su vivienda.', 'Autor por identificar'),
    _g('galeria-chimila-3', 'chimila_3.jpg', 'Familia chimila (1916)', 'Fotografía de una familia chimila.', 'Gustaf Bolinder, 1916'),
    // Videos públicos en YouTube (se abren en la app de YouTube).
    <String, dynamic>{
      'slug': 'yt-bailes-cantaos',
      'tipo': 'video',
      'url': 'https://www.youtube.com/watch?v=yCpBmrhGaBE',
      'titulo': 'Bailes cantaos: chandé y pajarito',
      'descripcion': 'Video de bailes cantaos aportado por el equipo.',
      'autorNombre': 'YouTube',
    },
    <String, dynamic>{
      'slug': 'yt-banda-16-julio',
      'tipo': 'video',
      'url': 'https://www.youtube.com/watch?v=u3DOiZ9ilK8',
      'titulo': 'Banda 16 de Julio',
      'descripcion': 'La banda de vientos “La Remendá”, fundada en 1937.',
      'autorNombre': 'YouTube',
    },
    <String, dynamic>{
      'slug': 'yt-malecon',
      'tipo': 'video',
      'url': 'https://www.youtube.com/watch?v=k7QvwMrswA4',
      'titulo': 'Plaza y malecón turístico de Pijiño del Carmen',
      'descripcion': 'Presentación del proyecto de plaza y malecón frente a la ciénaga El Palmar, junto al jarillón (2018).',
      'autorNombre': 'YouTube · Luis Machado',
    },
    <String, dynamic>{
      'slug': 'yt-documental',
      'tipo': 'video',
      'url': 'https://www.youtube.com/watch?v=-P_BIu1KCOQ',
      'titulo': 'Documental de Pijiño del Carmen, Magdalena',
      'descripcion': 'Documental publicado en YouTube sobre el municipio.',
      'autorNombre': 'YouTube',
    },
    <String, dynamic>{
      'slug': 'yt-somos-todos',
      'tipo': 'video',
      'url': 'https://www.youtube.com/watch?v=u40UcfYLodw',
      'titulo': 'Pijiño somos todos',
      'descripcion': 'Video publicado en YouTube.',
      'autorNombre': 'YouTube',
    },
    <String, dynamic>{
      'slug': 'yt-pijino',
      'tipo': 'video',
      'url': 'https://www.youtube.com/watch?v=WBT61vYY4I8',
      'titulo': 'Pijiño del Carmen',
      'descripcion': 'Video publicado en YouTube.',
      'autorNombre': 'YouTube',
    },
    <String, dynamic>{
      'slug': 'yt-imaginar-paz',
      'tipo': 'video',
      'url': 'https://www.youtube.com/watch?v=iHdsBAICoOQ',
      'titulo': 'Laboratorio de la Imaginación: Imaginar la paz',
      'descripcion': 'Experiencia del Laboratorio de la Imaginación en Pijiño del Carmen.',
      'autorNombre': 'YouTube',
    },
    <String, dynamic>{
      'slug': 'yt-carnaval-2025',
      'tipo': 'video',
      'url': 'https://www.youtube.com/watch?v=vCNc_766XvU',
      'titulo': 'Concierto en vivo en Pijiño del Carmen 2025',
      'descripcion': 'Peter Manjarrés y Luis José Villa en vivo en Pijiño del Carmen (2025).',
      'autorNombre': 'YouTube',
    },
  ];

  static final List<Map<String, dynamic>> negocios = <Map<String, dynamic>>[
    <String, dynamic>{
      'slug': 'dir-alcaldia',
      'nombre': 'Alcaldía Municipal de Pijiño del Carmen',
      'tipo': 'Institucional',
      'descripcion': 'Administración municipal. Sitio web oficial y página de Facebook con noticias y trámites.',
      'telefono': '',
      'direccion': 'Cabecera municipal',
      'enlace': 'http://www.pijinodelcarmen-magdalena.gov.co',
    },
    <String, dynamic>{
      'slug': 'dir-alcaldia-fb',
      'nombre': 'Alcaldía Pijiño del Carmen en Facebook',
      'tipo': 'Redes oficiales',
      'descripcion': 'Página oficial de la Alcaldía con noticias, eventos y transmisiones.',
      'telefono': '',
      'direccion': '',
      'enlace': 'https://www.facebook.com/alcaldiapijinodelcarmen/',
    },
    <String, dynamic>{
      'slug': 'dir-personeria',
      'nombre': 'Personería Municipal',
      'tipo': 'Institucional',
      'descripcion': 'Defensa de los derechos humanos y atención al ciudadano.',
      'telefono': '',
      'direccion': 'Cabecera municipal',
      'enlace': 'http://www.personeria-pijinodelcarmen.gov.co/',
    },
    <String, dynamic>{
      'slug': 'dir-iedt',
      'nombre': 'IEDT Pijiño del Carmen',
      'tipo': 'Educación',
      'descripcion': 'Institución Educativa Técnica Departamental Pijiño del Carmen. Sede del proyecto Conecta con Pijiño.',
      'telefono': '',
      'direccion': 'Pijiño del Carmen, Magdalena',
      'enlace': 'https://www.facebook.com/iepijino.delcarmen.7/',
    },
    <String, dynamic>{
      'slug': 'dir-casa-cultura',
      'nombre': 'Casa de la Cultura Elías Abad Palomino',
      'tipo': 'Cultura',
      'descripcion': 'Espacio cultural del municipio. PENDIENTE: horario y contacto.',
      'telefono': '',
      'direccion': 'Cabecera municipal',
      'enlace': '',
    },
    <String, dynamic>{
      'slug': 'dir-parroquia',
      'nombre': 'Parroquia Nuestra Señora del Carmen',
      'tipo': 'Religioso',
      'descripcion': 'Iglesia principal del municipio. PENDIENTE: horario de misas.',
      'telefono': '',
      'direccion': 'Plaza principal',
      'enlace': '',
    },
    <String, dynamic>{
      'slug': 'dir-central-ganadera',
      'nombre': 'Central Ganadera Pijiño',
      'tipo': 'Ganadería',
      'descripcion': 'Ganadería de razas lecheras Gyr y Guzerat.',
      'telefono': '',
      'direccion': 'Pijiño del Carmen',
      'enlace': 'https://www.instagram.com/central_ganadera_pijino/',
    },
    <String, dynamic>{
      'slug': 'dir-cabrera-fb',
      'nombre': 'Cabrera Magdalena en Facebook',
      'tipo': 'Comunidad',
      'descripcion': 'Página comunitaria del corregimiento de Cabrera.',
      'telefono': '',
      'direccion': 'Cabrera',
      'enlace': 'https://www.facebook.com/cabreramagdalena/',
    },
    <String, dynamic>{
      'slug': 'dir-emergencias',
      'nombre': 'Línea de emergencias',
      'tipo': 'Emergencias',
      'descripcion': 'Línea única nacional de emergencias (Policía, Bomberos, atención médica).',
      'telefono': '123',
      'direccion': 'Nacional',
      'enlace': '',
    },
  ];
}
