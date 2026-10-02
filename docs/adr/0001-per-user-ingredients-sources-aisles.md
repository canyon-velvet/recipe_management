# Ingredients, sources and aisles are owned per user

Recipes, meal plans and grocery lists were already private, but ingredients and sources were a single shared catalog. Once anyone could sign up and imports created ingredients and sources automatically, one user's typos, duplicates and aisles would show up in everyone's autocomplete and grocery list, and nobody could clean them up without breaking someone else's recipes. So ingredients, sources and aisles belong to one user. New users get their own copy of the default aisles, which they can rename, reorder, extend or delete (except Other).

## Considered Options

- **One shared catalog:** no duplication, but every user's mistakes become everyone's, and there's no safe way to delete or rename anything.
- **A shared curated catalog plus each user's own additions:** keeps defaults deduplicated, but needs someone to curate it and makes every lookup merge two sources. Too much machinery for this app.

## Consequences

Each user has their own copy of the default aisles, and the same ingredient name ("Eggs") can exist once per user. That duplication is intentional, so don't merge it.
