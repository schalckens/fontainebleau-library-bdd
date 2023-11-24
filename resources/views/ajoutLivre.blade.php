<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <title>Ajouter un Livre</title>
</head>
<body>
<h1>Ajouter un Livre</h1>

<form method="POST" action="#route succes livre ajouter">
    @csrf

    <div>
        <label for="identifiant">Identifiant Unique</label>
        <input type="text" id="identifiant" name="identifiant" value="{{ uniqid() }}" readonly>
    </div>

    <div>
        <label for="titre">Titre</label>
        <input type="text" id="titre" name="titre" required>
    </div>

    <div>
        <label for="auteurs">Auteur(s)</label>
        <input type="text" id="auteurs" name="auteurs" required>
    </div>

    <div>
        <label for="edition">Édition</label>
        <input type="text" id="edition" name="edition" required>
    </div>

    <div>
        <label for="pages">Nombre de Pages</label>
        <input type="number" id="pages" name="pages" required>
    </div>

    <div>
        <label for="tags">Tags</label>
        <input type="text" id="tags" name="tags" required>
    </div>

    <div>
        <button type="submit">Ajouter le Livre</button>
    </div>
</form>
</body>
</html>
