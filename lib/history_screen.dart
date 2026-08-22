import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('No s\'ha pogut obrir l\'URL: $url');
    }
  }

  void _showImageDialog(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              child: PhotoView(
                imageProvider: AssetImage(imagePath),
                backgroundDecoration:
                    const BoxDecoration(color: Colors.transparent),
                heroAttributes: PhotoViewHeroAttributes(tag: imagePath),
              ),
            ),
          ),
        );
      },
    ).then((_) => FocusManager.instance.primaryFocus?.unfocus());
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: <Widget>[
        _buildSection(
          context,
          title: 'Què va ser la Màquina Enigma?',
          content:
              'La màquina Enigma va ser un dispositiu de xifratge electromecànic utilitzat per l\'Alemanya nazi durant la Segona Guerra Mundial per a les seves comunicacions militars. La seva complexitat la feia, teòricament, indesxifrable, la qual cosa proporcionava un gran avantatge estratègic.',
          imagePath: 'assets/images/Enigma.jpg',
          url: 'https://ca.wikipedia.org/wiki/M%C3%A0quina_Enigma',
        ),
        const Divider(height: 30, color: Colors.white24),
        _buildSection(
          context,
          title: 'Components i Funcionament de l\'Enigma',
          content:
              'El cor de l\'Enigma eren els seus rotors, uns discs cablejats que giraven amb cada pulsació de tecla. Un missatge passava a través de diversos rotors, un reflector que el retornava, i finalment un panell de connexions (plugboard) que intercanviava lletres abans del resultat final. Aquesta combinació creava un xifratge polialfabètic extremadament complex per a l\'època. Una de les seves debilitats clau era que una lletra mai no es podia xifrar com a ella mateixa.',
          imagePath: 'assets/images/Enigma_Components.jpg',
        ),
        const Divider(height: 30, color: Colors.white24),
        _buildSection(
          context,
          title: 'El Repte de les Combinacions',
          content:
              'La seguretat de l\'Enigma no requeia en el seu disseny, que era conegut, sinó en la quantitat de claus possibles. Amb 3 rotors escollits entre 5, les seves posicions inicials i els 10 parells de cables del plugboard, el nombre de combinacions superava els 150 bilions, fent impossible un atac de força bruta manual.',
          imagePath: 'assets/images/Repte_Combinacions.png',
        ),
        const Divider(height: 30, color: Colors.white24),
        _buildSection(
          context,
          title: 'Bletchley Park i la Bombe',
          content:
              'Bletchley Park va ser el centre secret britànic on un equip de criptoanalistes, liderat per figures com Alan Turing, va treballar per trencar el codi Enigma. La \'Bombe\', dissenyada per Turing i Gordon Welchman, era una màquina electromecànica que automatitzava la cerca de les configuracions diàries de l\'Enigma, provant milers de possibilitats a una velocitat impensable per a un humà.',
          imagePath: 'assets/images/Bombe.jpg',
          url: 'https://ca.wikipedia.org/wiki/Bombe',
        ),
        const Divider(height: 30, color: Colors.white24),
        _buildSection(
          context,
          title: 'Alan Turing i la Màquina de Turing',
          content:
              'Alan Turing no només va ser clau a Bletchley Park, sinó que és considerat un dels pares de la informàtica teòrica. Abans de la guerra, va formalitzar el concepte d\'algorisme i computació amb la seva \'Màquina de Turing\', un model matemàtic abstracte que va establir les bases teòriques de què pot ser computat. Aquesta idea fonamental va ser crucial per al desenvolupament dels ordinadors moderns i la intel·ligència artificial.',
          imagePath: 'assets/images/Alan_Turing.jpg',
          url: 'https://ca.wikipedia.org/wiki/M%C3%A0quina_de_Turing',
        ),
        const Divider(height: 30, color: Colors.white24),
        _buildSection(
          context,
          title: 'El Mètode de la Bombe: El "Crib"',
          content:
              'La Bombe no buscava la clau correcta, sinó que descartava les incorrectes. Això ho aconseguia a partir d\'un "crib", un fragment de text que se suposava que apareixia al missatge. Exemples comuns eren "WETTERBERICHT" (informe del temps) o "AN DEN CHEF" (al cap). Aquesta tècnica explotava la debilitat de l\'Enigma que una lletra mai es xifrava a si mateixa.',
          extraContent: _buildCribTable(context),
          imagePath: 'assets/images/Crib_Ciphertext_Pairings.gif',
        ),
        const Divider(height: 30, color: Colors.white24),
        _buildSection(
          context,
          title: 'El Tauler Diagonal de Welchman',
          content:
              'L\'aportació crucial de Gordon Welchman va ser el "Tauler Diagonal", una millora que accelerava exponencialment el procés. Aquest component simulava l\'efecte del plugboard i permetia a la Bombe detectar contradiccions lògiques en cadena. Si una hipòtesi de connexió portava a una impossible (com una lletra connectada a dues altres a la vegada), tota la configuració es descartava en mil·lisegons.',
          imagePath: 'assets/images/Gordon-Welchman.jpg',
        ),
        const Divider(height: 30, color: Colors.white24),
        _buildSection(
          context,
          title: 'L\'Impacte Històric',
          content:
              'El desxifratge de l\'Enigma va ser un dels majors èxits d\'intel·ligència de la guerra. Va proporcionar als Aliats informació vital sobre les operacions alemanyes, especialment a la Batalla de l\'Atlàntic. Els historiadors estimen que aquest èxit va escurçar la guerra en almenys dos anys i va salvar milions de vides, demostrant el poder decisiu de la criptografia.',
          imagePath: 'assets/images/Segona_Guerra_Mundial.jpg',
          url: 'https://ca.wikipedia.org/wiki/Segona_Guerra_Mundial',
        ),
      ],
    );
  }

  Widget _buildCribTable(BuildContext context) {
    final header = [
      '01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21','22','23'
    ];
    final cipher = [
      'R','W','I','V','T','Y','R','E','S','X','B','F','O','G','K','U','H','Q','B','A','I','S','E'
    ];
    final crib = [
      'W','E','T','T','E','R','V','O','R','H','E','R','S','A','G','E','B','I','S','K','A','Y','A'
    ];

    Widget buildRow(String label, List<String> items,
        {FontWeight fontWeight = FontWeight.normal,
        Color labelColor = Colors.yellow}) {
      return Row(
        children: [
          Container(
            width: 70, // Label width
            padding: const EdgeInsets.only(right: 12),
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: labelColor, fontSize: 14)),
          ),
          ...items.map((item) => SizedBox(
                width: 28, // Cell width
                child: Text(
                  item,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: fontWeight,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ))
        ],
      );
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Exemple de relació entre text xifrat i el "crib" (text pla suposat):',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildRow('Posició', header, fontWeight: FontWeight.bold),
                const Divider(color: Colors.white24, height: 10),
                buildRow('Xifrat', cipher, labelColor: Colors.white),
                const SizedBox(height: 4),
                buildRow('Crib', crib, labelColor: Colors.white),
              ],
            ),
          )
        ]);
  }

  Widget _buildSection(BuildContext context,
      {required String title,
      required String content,
      String? imagePath,
      String? url,
      Widget? extraContent}) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: textTheme.headlineSmall?.copyWith(color: Colors.yellow)),
            const SizedBox(height: 12),
            if (imagePath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: GestureDetector(
                  onTap: () => _showImageDialog(context, imagePath),
                  child: Hero(
                    tag: imagePath,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.asset(imagePath,
                          fit: BoxFit.cover, width: double.infinity, height: 180),
                    ),
                  ),
                ),
              ),
            Text(content, style: textTheme.bodyLarge?.copyWith(height: 1.5)),
            if (extraContent != null) extraContent,
            if (url != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.public),
                  label: const Text('Saber-ne més a la Viquipèdia'),
                  onPressed: () => _launchUrl(url),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.yellow,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
