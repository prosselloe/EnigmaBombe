# Blueprint: Simulador Criptogràfic Enigma & Bombe

## Visió General

Aquesta aplicació Flutter té com a objectiu proporcionar una eina educativa i interactiva per entendre el funcionament de la màquina de xifratge alemanya "Enigma", el dispositiu criptoanalític britànic "Bombe" durant la Segona Guerra Mundial, i els fonaments de la computació amb la Màquina de Turing.

## Disseny i Característiques Implementades

### Fase 1-7: Desenvolupament Inicial i Correccions
- Es va crear l'estructura de l'aplicació, els simuladors de l'Enigma i la Bombe, i es va refinar la interfície. Una correcció crítica (Fase 7) va alinear la lògica de la Bombe amb el moviment real dels rotors.

### Fase 8 (Revisada): Emulació del Flux de Criptoanàlisi de Bletchley Park
- **Objectiu:** Reestructurar el simulador de la Bombe per emular el procés de treball real dels criptoanalistes. La Bombe ara troba configuracions de rotors candidates sense conèixer el `plugboard`, presentant un informe que permet a l'usuari deduir les connexions manualment.

### Fase 9: Automatització de la Cerca Multi-Reflector
- **Objectiu:** Si no es troben resultats, la Bombe prova automàticament amb l'altre reflector disponible ('B' o 'C').

### Fase 10: Implementació del "Diagonal Board" de Welchman
- **Objectiu:** Refactoritzar el nucli del simulador de la Bombe per incorporar la lògica del "Diagonal Board", millorant dràsticament la precisió històrica i l'eficiència de la simulació en descartar configuracions invàlides del `plugboard` mitjançant la detecció de contradiccions lògiques.

---

## Pla de Desenvolupament Actual: Addició del Simulador de la Màquina de Turing

### Fase 11: Implementació del Simulador de la Màquina de Turing

**Objectiu:** Crear una nova secció a l'aplicació dedicada a la Màquina de Turing, el model abstracte de computació que va formalitzar el concepte d'algorisme i va ser fonamental en el desenvolupament de la informàtica.

**Justificació:** Aquesta pantalla amplia el valor educatiu de l'aplicació més enllà de la criptografia de la Segona Guerra Mundial, introduint els usuaris als principis bàsics de la ciència de la computació d'una manera interactiva.

#### 11.1 Passos de la Implementació

1.  **Creació de la Lògica (`lib/turing_logic/turing_machine.dart`):**
    *   Desenvolupament d'una classe `TuringMachine` que gestiona l'estat de la màquina (cinta, posició del capçal, estat actual).
    *   Implementació d'un parser per a les regles de transició definides per l'usuari.
    *   Creació de mètodes per inicialitzar la màquina, executar un sol pas (`step`), i córrer el programa contínuament.

2.  **Desenvolupament de la Interfície (`lib/turing_screen.dart`):**
    *   Disseny d'una interfície clara que inclou:
        *   **Selector de Programes:** Un menú desplegable amb programes predefinits (Inversor Binari, Suma Unària, Castor Ocupat, Generador de Palíndroms) per a una demostració ràpida.
        *   **Editor de Cinta i Regles:** Camps de text on els usuaris poden introduir la seva pròpia cinta inicial i definir les regles per a un programa personalitzat.
        *   **Controls d'Execució:** Botons per `Executar`, `Parar`, fer un sol `Pas` i `Reiniciar` la simulació.
        *   **Visualització de la Cinta:** Una representació gràfica de la cinta que ressalta la posició actual del capçal.
        *   **Panell d'Estat:** Targetes informatives que mostren l'estat actual, la posició del capçal i si la màquina s'ha aturat.
        *   **Taula de Transicions:** Una taula que mostra les regles actives del programa carregat.

3.  **Integració a l'Aplicació Principal (`lib/main.dart`):**
    *   S'ha afegit una nova pestanya a la barra de navegació inferior per accedir a la pantalla de la Màquina de Turing.
    *   S'ha creat una nova icona (`Icons.computer`) per representar aquesta secció.

---

## Futur Desenvolupament

*   **Optimització del Rendiment de la Bombe:** La lògica del "Diagonal Board" podria ser computacionalment intensiva. S'exploraran optimitzacions, possiblement executant els càlculs en un `Isolate` separat per no bloquejar el fil de la UI.
*   **Visualització del Procés de la Bombe:** Afegir una visualització animada del flux de corrent i la detecció de contradiccions per a una parada específica, millorant encara més el valor educatiu de l'eina.
*   **Millores al Simulador de Turing:**
    *   Permetre una velocitat d'execució variable.
    *   Afegir més programes d'exemple complexos.
    *   Implementar un sistema de ressaltat de la regla de transició que s'està aplicant en cada pas.
