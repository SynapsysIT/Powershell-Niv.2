---
icon: project
order: 1
---

# Construire son code

## Tout commence par une commande

On identifira rapidement une ou deux commandes qui seront le coeur de notre code.

Celles qui récupéreront l'essentiel des données souhaités ou qui feront l'action finale voulue par notre code.

L’idée est de connaitre  précisément le fonctionnement de ces commandes et de savoir identifier les propriétés et les méthodes des objets renvoyés par ces commandes et ce que nous aurons à manipuler.


La construction de notre code consistera ensuite à entourer  ces commandes de validations, de logique, de contrôle d'erreur et de formatage des données renvoyées


## Définir un squelette

- [x] **Les Inputs** - A l'aide des paramètres, on valide, on nomme et on contrôle les entrées 
- [x] **Les Outputs** - On définit et on structure les données qui devront être renvoyés par notre code
- [x] **Les contrôles** - On traite les erreurs possible, et on rends notre code assez verbeux pour faciliter son debug.


#### Si on code une fonction

La fonction devra être le plus mono tâche et spécialisée possible. On doit pouvoir réutiliser cette fonction telle quelle, dans un contexte différent.

#### Si on code un script

Dans le cas d'un script, l'attention doit être portée sur la factorisation du code. Si on doit répéter un bloc de code plusieurs fois dans le script, c'est que ce bout de code doit devenir une fonction.