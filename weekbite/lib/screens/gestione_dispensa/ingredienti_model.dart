class Ingredienti{
  int? id;
  final String nome; //nome del prodotto
  final double quantita; //quantità nominale del prodotto
  final String unitaMisura; //unità di misura del prodotto
  int pezzi; //pezzi del prodotto
  final String categoria;
  final DateTime dataScadenza;

  Ingredienti({
    this.id,
    required this.nome, 
    required this.quantita,
    required this.unitaMisura,
    required this.pezzi,
    required this.categoria,
    required this.dataScadenza,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'quantita': quantita,
      'unitaMisura': unitaMisura,
      'pezzi': pezzi,
      'categoria': categoria,
      'dataScadenza': dataScadenza.toIso8601String(), 
    };
  }

  factory Ingredienti.fromMap(Map<String, dynamic> map) {
    return Ingredienti(
      id: map['id'],
      nome: map['nome'],
      quantita: map['quantita'],
      unitaMisura: map['unitaMisura'],
      pezzi: map['pezzi'],
      categoria: map['categoria'],
      dataScadenza: DateTime.parse(map['dataScadenza']),
    );
  }
}