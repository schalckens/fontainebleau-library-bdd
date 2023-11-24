<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <title>Accueil</title>
</head>
<body>
<h1>Accueil</h1>

<div>
    <a href="#route ajout-livre" class="btn btn-primary">Ajouter un livre</a>
</div>

<div>
    <a href="#route ajout-membre" class="btn btn-success">Ajouter un membre</a>
</div>

<div>
    <a href="#route emprunt-livre" class="btn btn-primary">Emprunter un livre</a>
</div>

<div>
    <a href="#route sanction-membre" class="btn btn-danger">Mettre une sanction à un membre</a>
</div>

<div>
    <a href="#route consulter-livres" class="btn btn-primary">Consulter les livres</a>
</div>

<div>
    <a href="#route consulter-membres" class="btn btn-info">Consulter les informations des membres</a>
</div>
</body>
</html>
