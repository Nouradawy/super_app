class Compound{
final int id;
final String name;
final String? developer;
final String? city;
final String? pictureUrl;

Compound({
  required this.id,
  required this.name,
  this.developer,
  this.city,
  this.pictureUrl

});

Map<String, dynamic> toJson() {
  return {
    'id': id,
    'name': name,
    'developer': developer,

    'city': city,
    'picture_url': pictureUrl,
  };
}

factory Compound.fromJson(Map<String, dynamic> json){
  return Compound(
    id:json['id'] as int,
    name:json['name'] as String,
    developer: json['developer'] as String?,
    city: json['city'] as String?,
    pictureUrl: json['picture_url'] as String?
  );
}
}

class Category {
  final int id;
  final String name;
  final List<Compound> compounds; // This is the nested list!

  Category({
    required this.id,
    required this.name,
    required this.compounds,
  });


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      // This maps the list of Compound objects into a list of JSON maps
      'compounds': compounds.map((compound) => compound.toJson()).toList(),
    };
  }
  // A factory constructor to build the full Category WITH its nested compounds
  factory Category.fromJson(Map<String, dynamic> json) {
    // Supabase will return the nested compounds under the 'compounds' table name
    var compoundsList = json['compounds'] as List;

    // We map that raw list into a List<Compound> using the Compound.fromJson factory
    List<Compound> parsedCompounds = compoundsList
        .map((compoundJson) => Compound.fromJson(compoundJson))
        .toList();

    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      compounds: parsedCompounds,
    );
  }
}