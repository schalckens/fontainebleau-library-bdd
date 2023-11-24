<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "web" middleware group. Make something great!
|
*/

Route::get('/', function () {
    return view('connexion');
});

Route::get('/accueil', function () {
    return view('accueil');
});

Route::get('/ajout-livre', function () {
    return view('ajoutLivre');
});

Route::get('/emprunt-livre', function () {
    return view('emprunt');
});

Route::get('/sanction-membre', function () {
    return view('penalty');
});
Route::get('/ajout-membre', function () {
    return view('ajoutMembre');
});
Route::get('/consulter-livres', function () {
    return view('consultLivre');
});
Route::get('/consulter-membres', function () {
    return view('consultMembre');
});

