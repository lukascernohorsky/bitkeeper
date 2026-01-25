# Migrace na systémové Tcl/Tk

## Cíl
Upravit build proces tak, aby nepoužíval vestavěný balíček `tcltk`, ale místo toho používal systémové Tcl/Tk (minimální verze 8.6). Složka `tcltk` byla odstraněna. Postup je evidován pro případ restartu kontextu. Všechny testy musí projít na 100% bez použití dočasných řešení nebo stubů.

## Změny

### 1. Úprava `src/conf.mk`
- Přidány proměnné pro systémové Tcl/Tk.
- Přidána kontrola minimální verze Tcl/Tk (8.6).

### 2. Úprava `src/gui/tcltk/Makefile`
- Přidána logika pro použití systémového Tcl/Tk místo vestavěného.
- Přidána kontrola minimální verze Tcl/Tk.

### 3. Úprava `src/gui/Makefile`
- Upraven cíl `tcltk` tak, aby používal systémové Tcl/Tk.

### 4. Úprava `src/Makefile`
- Upraven cíl `PCRE` tak, aby nepoužíval vestavěný `tcltk/pcre`.

### 5. Odstranění vestavěného `tcltk`
- Odstraněna složka `src/gui/tcltk`.

### 6. Aktualizace testů
- Upraveny testy tak, aby používaly systémové Tcl/Tk.

## Postup

1. Upravit `src/conf.mk` pro použití systémového Tcl/Tk.
2. Upravit `src/gui/tcltk/Makefile` pro použití systémového Tcl/Tk.
3. Upravit `src/gui/Makefile` pro použití systémového Tcl/Tk.
4. Upravit `src/Makefile` pro použití systémového Tcl/Tk.
5. Odstranit složku `src/gui/tcltk`.
6. Aktualizovat testy a ověřit, že vše funguje správně.
7. Vytvořit soubor `MIGRATION_TCLTK.md` pro evidenci postupu.

## Ověření

- Spustit kompletní build a ověřit, že vše funguje správně.
- Spustit všechny testy a zajistit, že procházejí na 100%.
