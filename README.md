# Project Pokemon

Aplicación Rails 8 que consume la [PokeAPI](https://pokeapi.co) para explorar la
Pokédex, capturar pokémon y compararlos.

## Stack

| Pieza | Versión |
| --- | --- |
| Ruby | 3.4 |
| Rails | 8.1 |
| Base de datos | MySQL 8.4 |
| Assets | Propshaft + importmap-rails + Dart Sass |
| UI | Bootstrap 5.3 + Font Awesome 6 |
| Paginación | Kaminari |

## Arranque con Docker (recomendado)

`compose.yaml` levanta la base de datos y el servidor. La primera vez el
contenedor `web` crea la base, aplica las migraciones y compila el CSS.

```bash
docker compose up --build
```

La aplicación queda en <http://localhost:3000> y MySQL en el puerto 3306.

Comandos útiles:

```bash
docker compose exec web ./bin/rails console
docker compose exec web ./bin/rails db:migrate
docker compose exec db mysql -uandres -ppokemon project_pokemon_dev
docker compose down -v          # borra también los volúmenes
```

Los datos de conexión se inyectan por entorno (`SETTINGS__DATABASE__*`), que la
gema `config` superpone sobre `config/settings/development.yml`.

## Arranque en local (sin Docker)

Requiere Ruby 3.2+, Node 20+ y un MySQL accesible según
`config/settings/development.yml`.

```bash
bundle install
npm install
bin/rails db:prepare
npm run build:css      # o `npm run watch:css` mientras se desarrolla
bin/rails server
```

### Credenciales

`config/master.key` no está versionado. La contraseña de la base de datos se lee
de las credenciales cifradas y, si están vacías, de la variable `DB_PASSWORD`:

```bash
bin/rails credentials:edit
```

## Assets

El CSS se compila con Dart Sass desde `app/assets/stylesheets/application.bootstrap.scss`
hacia `app/assets/builds/application.css`, que sirve Propshaft. El JavaScript se
gestiona con importmap (`config/importmap.rb`), sin empaquetador.

```bash
npm run build:css      # compilación única
npm run watch:css      # recompila al guardar
```

## Paginación

Todos los listados están paginados y aceptan `?page=` y `?per_page=`
(`per_page` está acotado a 60 para que nadie pueda pedir el catálogo entero).

* **Mis pokémon** (`/user/:user_id/pokemon`): Kaminari sobre Active Record, con
  `LIMIT`/`OFFSET` en SQL.
* **Pokédex** (`/user/:user_id/pokedex`): la paginación se delega en los
  parámetros `limit`/`offset` de la PokeAPI, así que cada página descarga sólo
  sus propios registros. `Pokeapi::SearchPokemons` envuelve el resultado en un
  `Kaminari.paginate_array` con el total real que devuelve la API.

Los enlaces de página usan las plantillas de `app/views/kaminari`, escritas con
el marcado de paginación de Bootstrap 5.

## API JSON

Bajo `/api/v1`. Usa la misma sesión de Devise que la parte web; sin sesión
responde `401` en JSON.

| Método | Ruta | Descripción |
| --- | --- | --- |
| GET | `/api/v1/pokemons` | Pokémon capturados por el usuario autenticado |
| GET | `/api/v1/pokemons/:id` | Detalle de un pokémon capturado |
| GET | `/api/v1/pokedex` | Catálogo de la PokeAPI |
| GET | `/api/v1/pokedex/:id` | Ficha de un pokémon de la PokeAPI |

Las colecciones aceptan `?page=` y `?per_page=` y devuelven los metadatos de
paginación en `meta`:

```json
{
  "data": [
    {
      "id": 3,
      "num_pokedex": 3,
      "name": "Venusaur",
      "type_of_pokemon": "Grass",
      "stats": { "hp": 80, "attack": 82, "special_attack": 100, "defense": 83, "special_defense": 100, "speed": 80 },
      "description": { "text": "…", "habitat": "Grassland", "capture_rate": 17, "base_happiness": 50 }
    }
  ],
  "meta": {
    "current_page": 2,
    "next_page": 3,
    "prev_page": 1,
    "total_pages": 676,
    "total_count": 1351,
    "per_page": 2
  }
}
```
