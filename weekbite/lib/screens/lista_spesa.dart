import 'package:google_fonts/google_fonts.dart';
import 'package:weekbite/main.dart';
import 'package:weekbite/screens/ingredienti_model.dart';
import 'package:weekbite/services/database_helper.dart'; 
import 'package:weekbite/screens/dispensa.dart'; 
import 'package:flutter/material.dart';
import 'package:weekbite/services/notification_service.dart'; 

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

List<Ingredienti> lista = [];

class ListaIngredientiScreen extends StatefulWidget{
  const ListaIngredientiScreen({super.key});

  @override
  State <ListaIngredientiScreen> createState() => _ListaIngredientiScreen();
}

class _ListaIngredientiScreen extends State<ListaIngredientiScreen>{ 
  @override
  void initState() {
    super.initState();
    _caricaDatiDalDatabase(); 
  }

  Future<void> _caricaDatiDalDatabase() async {
    final listaDb = await DatabaseHelper.instance.getIngredienti('lista_spesa');
    
    setState(() {
      lista = listaDb;
    });
  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Lista della spesa",
                    style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold, color:Colors.black,),
                  ),
                  //  const Spacer(),
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
                          final ingredienteSalvato = await DatabaseHelper.instance.addIngrediente('lista_spesa', risultato); // o 'lista_spesa'
                          
                          setState(() {
                            int index = lista.indexWhere((item) => item.id == ingredienteSalvato.id);
                              if (index != -1) {
                                lista[index] = ingredienteSalvato; // Aggiorna i pezzi a schermo
                              } else {
                                lista.add(ingredienteSalvato); // Aggiunge una nuova riga a schermo
                              }
                          });
                        }
                      },
                    icon: const Icon(Icons.playlist_add_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
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
                            lista.removeAt(i);
                            int indexDispensa = dispensa.indexWhere((item) => item.id == nuovoInDispensa.id);
                            if (indexDispensa != -1) {
                              dispensa[indexDispensa] = nuovoInDispensa;
                            } else {
                              dispensa.add(nuovoInDispensa);
                            }
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
      /*floatingActionButton: FloatingActionButton(
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
      ),*/
    );
  }
}
