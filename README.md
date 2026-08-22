# Enigma & Bombe Simulator

Una aplicació en Flutter que recrea la fascinant història de la màquina Enigma i la seva criptoanàlisi amb la Bombe de Turing.

## Visió General

Aquesta aplicació no és només un simulador, sinó una eina educativa interactiva per entendre un dels capítols més importants de la història de la criptografia. L'aplicació es divideix en quatre pantalles principals:

*   **Enigma:** Permet a l'usuari xifrar i desxifrar missatges utilitzant una simulació de la màquina Enigma. Es poden configurar els rotors, les seves posicions inicials i el plugboard.
*   **Bombe:** Demostra com la Bombe de Turing podia trobar la configuració de l'Enigma a partir d'un "crib" (un fragment de text conegut).
*   **Història:** Explica el context històric i el funcionament de l'Enigma i la Bombe.
*   **Turing:** Un simulador de la Màquina de Turing per experimentar amb els fonaments de la computació.

## Funcionament

### La Màquina Enigma

La màquina Enigma era un dispositiu de xifratge electromecànic que utilitzava una sèrie de rotors per crear un xifratge polialfabètic. La seva seguretat es basava en el gran nombre de combinacions possibles, que superava els 150 bilions amb la configuració utilitzada per l'exèrcit alemany.

### La Bombe

La Bombe va ser una màquina electromecànica dissenyada per Alan Turing i Gordon Welchman a Bletchley Park. La seva funció era automatitzar la recerca de la configuració diària de l'Enigma. La Bombe no buscava la clau correcta, sinó que descartava les incorrectes a una velocitat de vertigen, aprofitant una debilitat de l'Enigma: una lletra mai no es podia xifrar com a ella mateixa.

### El "Crib"

El "crib" era un fragment de text que els criptoanalistes de Bletchley Park suposaven que apareixia al missatge. Aquests fragments es basaven en la naturalesa repetitiva de les comunicacions militars, com ara els informes meteorològics ("WETTERBERICHT") o els salutacions formals. Aquest "crib" era la clau per configurar la Bombe i començar el procés de desxifratge.

### El Tauler Diagonal de Welchman

La contribució de Gordon Welchman, el Tauler Diagonal, va ser una millora crucial per a la Bombe. Aquest component accelerava el procés de desxifratge en simular l'efecte del plugboard i detectar contradiccions lògiques en cadena. Si una hipòtesi de connexió portava a un resultat impossible, tota la configuració es descartava a l'instant.

### La Màquina de Turing

A més de l'Enigma i la Bombe, l'aplicació inclou un simulador de la Màquina de Turing. Aquesta pantalla permet als usuaris experimentar amb els conceptes fonamentals de la computació.

*   **Programes predefinits:** Inclou una varietat de programes clàssics, com un inversor binari, una suma unària i el "Castor Ocupat".
*   **Editor personalitzat:** Els usuaris poden crear i executar els seus propis programes, definint les regles de transició i la cinta inicial.
*   **Visualització pas a pas:** La cinta, la posició del capçal i l'estat actual es mostren visualment, permetent seguir l'execució del programa pas a pas.

## Captures de Pantalla

*(Properament s'afegiran captures de pantalla de l'aplicació)*

## Instal·lació

1.  Clona el repositori: `git clone <URL_DEL_REPOSITORI>`
2.  Navega al directori del projecte: `cd enigma_bombe_simulator`
3.  Instal·la les dependències: `flutter pub get`
4.  Executa l'aplicació: `flutter run`

## Contribucions

Les contribucions són benvingudes. Si tens alguna idea per millorar l'aplicació, no dubtis a obrir un "issue" o a enviar un "pull request".
