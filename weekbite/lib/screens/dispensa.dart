import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:weekbite/main.dart';
import 'package:weekbite/screens/ingredienti_model.dart';
import 'package:weekbite/services/database_helper.dart'; 
import 'package:weekbite/screens/search_dispensa.dart'; 

final Map<String, String> categoriaM = {
  'Pasta': '🍝',
  'Frutta': '🍎',
  'Verdura': '🥦',
  'Carne': '🥩',
  'Pesce': '🐟',
  'Latticini': '🧀',
  'Bevande': '🥤',
  'Altro': '🛍️',
};

class DispensaScreen extends StatefulWidget{
  const DispensaScreen({super.key});

  @override
  State<DispensaScreen> createState() => _DispensaScreenState();
}

List<Ingredienti> dispensa = [];

class _DispensaScreenState extends State<DispensaScreen>{
  @override
  void initState() {
    super.initState();
    _caricaDatiDalDatabase(); 
  }

  Future<void> _caricaDatiDalDatabase() async {
    final dispensaDb = await DatabaseHelper.instance.getIngredienti('dispensa');
    //final listaDb = await DatabaseHelper.instance.getIngredienti('lista_spesa');
    
    setState(() {
      dispensa = dispensaDb;
      //lista = listaDb;
    });
  }

  @override 
  Widget build(BuildContext context){
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              "La mia Dispensa",
              style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold, color:Colors.black,),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchDispensaScreen(),
                        ),
                      );
                      setState(() {}); 
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 255, 255, 255),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const[
                          BoxShadow(color: Color.fromARGB(31, 0, 0, 0), blurRadius: 4,offset: Offset(0,2))
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color:primaryGreen, size:20),
                          const SizedBox(width: 12), 
                          Text(
                            "Cerca ingredienti...",
                            style: GoogleFonts.montserrat(color: Colors.grey, fontSize: 15)
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const[
                      BoxShadow(color: Color.fromARGB(31, 0, 0, 0), blurRadius: 4,offset: Offset(0,2))
                    ],
                  ),
                  child: IconButton(
                    onPressed: () async { 
                      final risultato = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FormIngredientiScreen(), 
                        ),
                      );
                      if (risultato != null && risultato is Ingredienti) {
                        final ingredienteSalvato = await DatabaseHelper.instance.addIngrediente('dispensa', risultato);
                        setState(() {
                          dispensa.add(ingredienteSalvato);
                        });
                      }
                    },
                    icon: const Icon(Icons.playlist_add_rounded, color: Colors.white),
                  ),
                ),
              ],
            ), 
          ),
          SizedBox(width: 12),
          Padding( 
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              "Ingredienti nella dispensa: ${dispensa.length}",
              style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color:Colors.grey),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(
                left: 20, 
                right: 20, 
                top: 10, 
                bottom: 80, 
              ),
              itemCount: categoriaM.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,     
                crossAxisSpacing: 16,  
                mainAxisSpacing: 16,   
                childAspectRatio: 1.0, 
              ),
              itemBuilder: (context, i) {
                final categoria = categoriaM.keys.elementAt(i);
                final emoji = categoriaM.values.elementAt(i);
                return GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (context) => ViewDispensaCategoria(
                          categoria: categoria,
                          emoji: emoji,         
                        ),
                      ),
                    );
                    setState(() {});
                  },
                  //borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: primaryGreen.withOpacity(0.1), 
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            emoji,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                            )
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        Text(
                          categoria, 
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ), 
        ],
      )
    );
  }
}

class IngredientiCard extends StatelessWidget {
  final Ingredienti ingrediente;
  final VoidCallback onTap;
  final VoidCallback? onElimina;
  final VoidCallback? onModifica;
  final Widget? leadingWidget;

  const IngredientiCard({required this.ingrediente, 
    required this.onTap, 
    required this.onElimina, 
    required this.onModifica,
    this.leadingWidget,
    });

  @override
  Widget build(BuildContext context) {
    final oggi = DateTime.now();
    final soloOggi = DateTime(oggi.year, oggi.month, oggi.day);
    final soloScadenza = DateTime(ingrediente.dataScadenza.year, ingrediente.dataScadenza.month, ingrediente.dataScadenza.day);
    
    final differenzaGiorni = soloScadenza.difference(soloOggi).inDays;
    
    final bool scadeAbreve = differenzaGiorni <= 3;
    
    final Color coloreData = scadeAbreve ? Colors.red : Colors.grey[600]!;
    final FontWeight pesoData = scadeAbreve ? FontWeight.bold : FontWeight.normal;

    String infoTesto = "";
    if(ingrediente.unitaMisura =='pz' || ingrediente.unitaMisura == 'q.b.'){
      infoTesto = "${ingrediente.pezzi} pz • ${ingrediente.categoria} • ";
    }else{
      infoTesto = "${ingrediente.quantita} ${ingrediente.unitaMisura} • ${ingrediente.pezzi} pz • ${ingrediente.categoria} • ";
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  ListTile(
                    leading: leadingWidget,
                    title: Text(
                      ingrediente.nome, 
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)
                    ),
                    subtitle: Text.rich(
                      TextSpan(
                        style: GoogleFonts.montserrat(color: Colors.grey[600], fontSize: 13),
                        children: [
                          TextSpan(text: infoTesto),
                          TextSpan(
                            text: "${ingrediente.dataScadenza.day.toString().padLeft(2, '0')}/${ingrediente.dataScadenza.month.toString().padLeft(2, '0')}/${ingrediente.dataScadenza.year}",
                            style: TextStyle(color: coloreData, fontWeight: pesoData),
                          ),
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onModifica != null)
                          IconButton(
                            icon: const Icon(Icons.edit, color: primaryGreen),
                            onPressed: onModifica,
                          ),
                        if (onElimina != null)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: onElimina,
                          ),
                      ],
                    )
                  ),
                  SizedBox(width: 20,)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
/*
class ListaIngredientiScreen extends StatefulWidget{
  const ListaIngredientiScreen({super.key});

  @override
  State <ListaIngredientiScreen> createState() => _ListaIngredientiScreen();
}

class _ListaIngredientiScreen extends State<ListaIngredientiScreen>{ 
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: primaryGreen),
          onPressed: () => Navigator.pop(context, false), 
        ),
        title: Text("Lista della spesa", style: GoogleFonts.montserrat(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding( 
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Text(
                "Ingredienti nella lista spesa: ${lista.length}",
               style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color:Colors.grey),
              ),
            ),
            SizedBox(width: 20), 
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                itemCount: lista.length,
                separatorBuilder: (_, __) => const SizedBox(height: 20),
                itemBuilder: (context, i) {
                  final listaspesa = lista[i];
                  return IngredientiCard(
                    ingrediente: listaspesa,
                    onTap: () { /* ... */ },
                    onModifica: () async {
                      final ingredienteModificato = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FormIngredientiScreen(ingredienteEsistente: listaspesa),
                        ),
                      );
                      if (ingredienteModificato != null) {
                        await DatabaseHelper.instance.updateIngrediente('lista_spesa', ingredienteModificato);
                        setState(() {
                          lista[i] = ingredienteModificato;
                        });
                      }
                    },
                    onElimina: () async {
                      await DatabaseHelper.instance.deleteIngrediente('lista_spesa', listaspesa.id!);
                      setState(() {
                        lista.removeAt(i);
                      });
                    },
                    leadingWidget: Checkbox(
                      value: false, 
                      activeColor: primaryGreen,
                      shape: const CircleBorder(), 
                      onChanged: (bool? completato) async {
                        if (completato == true) {
                          await DatabaseHelper.instance.deleteIngrediente('lista_spesa', listaspesa.id!);

                          final nuovoInDispensa = await DatabaseHelper.instance.addIngrediente('dispensa', listaspesa);
                          setState(() {
                            dispensa.add(nuovoInDispensa);
                            lista.removeAt(i);
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            )  
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async { 
          final risultato = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FormIngredientiScreen(), 
            ),
          );
          if (risultato != null && risultato is Ingredienti) {
            final ingredienteSalvato = await DatabaseHelper.instance.addIngrediente('lista_spesa', risultato);
            setState(() {
              lista.add(ingredienteSalvato);
            });
          }
        },
        child: const Icon(Icons.playlist_add_rounded, color: primaryGreen),
        backgroundColor: Colors.white,
      ),
    );
  }
}
*/
class FormIngredientiScreen extends StatefulWidget{
  final Ingredienti? ingredienteEsistente; 

  const FormIngredientiScreen({super.key, this.ingredienteEsistente});  

  @override
  State <FormIngredientiScreen> createState() => _FormIngredientiScreen();
}

class _FormIngredientiScreen extends State<FormIngredientiScreen>{ 
  final _nomeController = TextEditingController();
  final _quantitaController = TextEditingController();
  final _unitaController = TextEditingController();
  final _pezziController = TextEditingController();

  final List<String> _unitaDiMisura = ['g', 'kg', 'ml', 'l', 'pz', 'q.b.'];
  String _unitaSelezionata = 'g';
  final List<String> _categoria = ['Pasta', 'Frutta', 'Verdura', 'Carne', 'Pesce', 'Latticini', 'Bevande', 'Altro'];
  String _categoriaSelezionata= 'Altro';

  DateTime? _dataSelezionata; 

  Future<void> _scegliData(BuildContext context) async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), 
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryGreen, 
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (data != null && data != _dataSelezionata) {
      setState(() {
        _dataSelezionata = data;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.ingredienteEsistente != null) {
      final ing = widget.ingredienteEsistente!;
      
      _nomeController.text = ing.nome;
      _quantitaController.text = ing.quantita.toString(); 
      _pezziController.text = ing.pezzi.toString();
      
      _unitaSelezionata = ing.unitaMisura;
      _categoriaSelezionata = ing.categoria;
      _dataSelezionata = ing.dataScadenza;
    }
  }

  @override
  Widget build(BuildContext context){    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: primaryGreen),
          onPressed: () => Navigator.pop(context), 
        ),
        title: Text(
          widget.ingredienteEsistente == null ? "Aggiunta ingrediente" : "Modifica ingrediente",
          style: GoogleFonts.montserrat(color: Colors.black87, fontWeight: FontWeight.bold)
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FORM NOME
              TextField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: "Nome ingrediente", border: OutlineInputBorder(),),
              ),
              
              const SizedBox(height: 20),
              // FORM QUANTITÀ
            if (_unitaSelezionata != 'pz' && _unitaSelezionata != 'q.b.')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: TextFormField(
                  controller: _quantitaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Quantità (es. 500)",border: OutlineInputBorder(),),
                ),
              ),

              const SizedBox(height: 20),

              // FORM UNITÀ DI MISURA
              DropdownMenu<String>(
                initialSelection: _unitaSelezionata,
                label: const Text("Unità di misura"),
                
                expandedInsets: EdgeInsets.zero, 
                menuHeight: 200, 
                dropdownMenuEntries: _unitaDiMisura.map((String unita) {
                  return DropdownMenuEntry<String>(
                    value: unita,
                    label: unita,
                    style: MenuItemButton.styleFrom(
                      textStyle: GoogleFonts.montserrat(), 
                    ),
                  );
                }).toList(),
                onSelected: (String? nuovoValore) {
                  setState(() {
                    if (nuovoValore != null) {
                      _unitaSelezionata = nuovoValore;
                      if (_unitaSelezionata == 'pz' || _unitaSelezionata == 'q.b.') {
                        _quantitaController.text = '0'; // Usa il nome del tuo controller
                      }
                    }
                  });
                },
              ),
              const SizedBox(height: 20),
              DropdownMenu<String>(
                initialSelection: _categoriaSelezionata,
                label: const Text("Categoria"),
                expandedInsets: EdgeInsets.zero, 
                menuHeight: 200,
                dropdownMenuEntries: _categoria.map((String categoria) {
                  return DropdownMenuEntry<String>(
                    value: categoria,
                    label: categoria,
                    style: MenuItemButton.styleFrom(
                      textStyle: GoogleFonts.montserrat(), 
                    ),
                  );
                }).toList(),
                onSelected: (String? nuovoValore) {
                  setState(() {
                    if (nuovoValore != null) {
                      _categoriaSelezionata = nuovoValore;
                    }
                  });
                },
              ),
              const SizedBox(height: 20),

              // FORM PEZZI
              TextField(
                controller: _pezziController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Pezzi (es. 1)", border: OutlineInputBorder(),),
              ),

              const SizedBox(height: 20),

              // --- NUOVO: FORM DATA ---
              InkWell(
                onTap: () => _scegliData(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Data di scadenza",
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _dataSelezionata == null
                            ? "Tocca per scegliere la data"
                            // Formattazione base (gg/mm/aaaa)
                            : "${_dataSelezionata!.day.toString().padLeft(2, '0')}/${_dataSelezionata!.month.toString().padLeft(2, '0')}/${_dataSelezionata!.year}",
                        style: GoogleFonts.montserrat(
                          color: _dataSelezionata == null ? Colors.grey[600] : Colors.black87,
                        ),
                      ),
                      const Icon(Icons.calendar_today, color: primaryGreen),
                    ],
                  ),
                ),
              ),

              const Spacer(), 
        
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const[
                        BoxShadow(color: Color.fromARGB(31, 0, 0, 0), blurRadius: 4,offset: Offset(0,2))
                      ],
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Annulla",
                        style: GoogleFonts.montserrat(
                          color: primaryGreen, 
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: primaryGreen,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const[
                        BoxShadow(color: Color.fromARGB(31, 0, 0, 0), blurRadius: 4,offset: Offset(0,2))
                      ],
                    ),
                    child: TextButton(
                      onPressed: () {
                        final nuovoIngrediente = Ingredienti(
                          id: widget.ingredienteEsistente?.id,
                          nome: _nomeController.text,
                          quantita: double.tryParse(_quantitaController.text) ?? 0,
                          unitaMisura: _unitaSelezionata,
                          pezzi: int.tryParse(_pezziController.text) ?? 1,
                          categoria: _categoriaSelezionata,
                          dataScadenza: _dataSelezionata ?? DateTime.now(),
                        );

                        Navigator.pop(context, nuovoIngrediente);
                      },
                      child: Text(
                        "Conferma",
                        style: GoogleFonts.montserrat(
                          color: Colors.white, 
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _quantitaController.dispose();
    _pezziController.dispose();
    super.dispose();
  }
}

class ViewDispensaCategoria extends StatefulWidget {
  final String categoria;
  final String emoji; 

  const ViewDispensaCategoria({
    Key? key, 
    required this.categoria,
    required this.emoji,
  }) : super(key: key);

  @override
  State<ViewDispensaCategoria> createState() => _ViewDispensaCategoriaState();
}

class _ViewDispensaCategoriaState extends State<ViewDispensaCategoria> {
  @override
  Widget build(BuildContext context) {
    final ingredientiFiltrati = dispensa
        .where((ing) => ing.categoria == widget.categoria)
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: primaryGreen),
          onPressed: () => Navigator.pop(context), 
        ),
        title: Text(
          "${widget.emoji} ${widget.categoria}", 
          style: GoogleFonts.montserrat(color: Colors.black87, fontWeight: FontWeight.bold)
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding( 
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Text(
                "Elementi in dispensa: ${ingredientiFiltrati.length}",
                style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
                itemCount: ingredientiFiltrati.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final ingrediente = ingredientiFiltrati[i];
                  return IngredientiCard(
                    ingrediente: ingrediente,
                    onTap: () {
                    },
                    onElimina: () async {
                      await DatabaseHelper.instance.deleteIngrediente('dispensa', ingrediente.id!);
                      setState(() {
                        dispensa.removeWhere((item) => item.id == ingrediente.id);
                      });
                    },
                    onModifica: () async {
                      final ingredienteModificato = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FormIngredientiScreen(ingredienteEsistente: ingrediente),
                        ),
                      );

                      if (ingredienteModificato != null) {
                        await DatabaseHelper.instance.updateIngrediente('dispensa', ingredienteModificato);
                        setState(() {
                          int indexGlobale = dispensa.indexWhere((item) => item.id == ingrediente.id);
                          if (indexGlobale != -1) {
                            dispensa[indexGlobale] = ingredienteModificato;
                          }
                        });
                      }
                    },
                  );
                },
              ),
            )  
          ],
        ),
      ),
    );
  }
}