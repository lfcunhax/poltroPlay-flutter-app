/// Utilitários para normalização de strings e suporte a buscas eficientes.
library;

/// Remove acentos/diacríticos e converte o texto para minúsculas.
/// Também simplifica pontuações para facilitar correspondências como:
/// "Homem-Aranha" -> "homem aranha"
/// "Deadpool & Wolverine" -> "deadpool wolverine"
/// "Vingadores: Ultimato" -> "vingadores ultimato"
String normalizeSearchText(String input) {
  if (input.isEmpty) return '';

  var str = input.toLowerCase().trim();

  // Mapeamento de acentos comuns em português e outras línguas
  const withAccents = 'áàâãäéèêëíìîïóòôõöúùûüçñýÿ';
  const withoutAccents = 'aaaaaeeeeiiiiooooouuuucnyy';

  for (var i = 0; i < withAccents.length; i++) {
    str = str.replaceAll(withAccents[i], withoutAccents[i]);
  }

  // Remove pontuações e caracteres especiais comuns substituindo por espaço
  str = str.replaceAll(RegExp(r'[\-_:;,.!?/\\()&\[\]]'), ' ');

  // Reduz múltiplos espaços para um único espaço
  str = str.replaceAll(RegExp(r'\s+'), ' ').trim();

  return str;
}

/// Gera variações de prefixos para consultas range no Firestore,
/// compensando a sensibilidade a maiúsculas/minúsculas da ordenação lexicográfica.
List<String> generateSearchPrefixes(String query) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return [];

  final set = <String>{};

  // 1. Como digitado
  set.add(trimmed);

  // 2. Primeira letra maiúscula (ex: "deadpool" -> "Deadpool")
  if (trimmed.length == 1) {
    set.add(trimmed.toUpperCase());
    set.add(trimmed.toLowerCase());
  } else {
    set.add(trimmed[0].toUpperCase() + trimmed.substring(1));
    set.add(trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase());
  }

  // 3. Title Case de todas as palavras (ex: "homem aranha" -> "Homem Aranha")
  final words = trimmed.split(' ');
  if (words.length > 1) {
    final titleCased = words
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1).toLowerCase() : '')
        .join(' ');
    set.add(titleCased);

    // Variação com hífen (muito comum em filmes como Homem-Aranha)
    final hyphenCased = words
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1).toLowerCase() : '')
        .join('-');
    set.add(hyphenCased);
  }

  // 4. Toda maiúscula (ex: "lego", "cia")
  set.add(trimmed.toUpperCase());

  // 5. Toda minúscula
  set.add(trimmed.toLowerCase());

  return set.toList();
}
