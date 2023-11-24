<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <title>Connexion</title>
</head>
<body>
<h1>Connexion</h1>

<form >
    @csrf

    <div>v
        <label for="email">Adresse e-mail</label>
        <input type="email" id="email" name="email" value="{{ old('email') }}" required autofocus>
    </div>

    <div>
        <label for="password">Mot de passe</label>
        <input type="password" id="password" name="password" required>
    </div>

    <div>
        <button type="submit">Connexion</button>
    </div>
</form>
</body>
</html>
