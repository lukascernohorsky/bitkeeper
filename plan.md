# Plán migrace na systémové Tcl/Tk

## Cíl
Upravit build proces tak, aby nepoužíval vestavěný balíček `tcltk`, ale místo toho používal systémové Tcl/Tk (minimální verze 8.6). Složka `tcltk` bude odstraněna. Postup bude evidován pro případ restartu kontextu. Všechny testy musí projít na 100% bez použití dočasných řešení nebo stubů.

## Analýza současného stavu

### Vestavěný `tcltk`
- Složka `src/gui/tcltk` obsahuje vestavěný Tcl/Tk, který je používán pro build.
- `src/gui/tcltk/Makefile` obsahuje logiku pro build Tcl/Tk z zdrojových kódů.
- `src/gui/Makefile` závisí na `tcltk` pro build GUI nástrojů.

### Závislosti
- `src/Makefile` obsahuje cíl `PCRE`, který závisí na `src/gui/tcltk/pcre`.
- `src/gui/Makefile` obsahuje cíl `tcltk`, který builduje vestavěný Tcl/Tk.

### Systémové Tcl/Tk
- Současný build systém nepoužívá systémové Tcl/Tk, ale místo toho builduje vestavěný Tcl/Tk.

## Plán

### 1. Úprava `src/conf.mk`
- Přidat proměnné pro systémové Tcl/Tk.
- Přidat kontrolu minimální verze Tcl/Tk (8.6).

### 2. Úprava `src/gui/tcltk/Makefile`
- Přidat logiku pro použití systémového Tcl/Tk místo vestavěného.
- Přidat kontrolu minimální verze Tcl/Tk.

### 3. Úprava `src/gui/Makefile`
- Upravit cíl `tcltk` tak, aby používal systémové Tcl/Tk.

### 4. Úprava `src/Makefile`
- Upravit cíl `PCRE` tak, aby nepoužíval vestavěný `tcltk/pcre`.

### 5. Odstranění vestavěného `tcltk`
- Odstranit složku `src/gui/tcltk`.

### 6. Aktualizace testů
- Zajistit, aby všechny testy používaly systémové Tcl/Tk.

### 7. Evidování postupu
- Vytvořit soubor `MIGRATION_TCLTK.md` pro evidenci postupu.

### 8. Ověření a testování
- Spustit kompletní build a ověřit, že vše funguje správně.
- Spustit všechny testy a zajistit, že procházejí na 100%.

## Následující kroky

1. Upravit `src/conf.mk` pro použití systémového Tcl/Tk.
2. Upravit `src/gui/tcltk/Makefile` pro použití systémového Tcl/Tk.
3. Upravit `src/gui/Makefile` pro použití systémového Tcl/Tk.
4. Upravit `src/Makefile` pro použití systémového Tcl/Tk.
5. Odstranit složku `src/gui/tcltk`.
6. Aktualizovat testy a ověřit, že vše funguje správně.
7. Vytvořit soubor `MIGRATION_TCLTK.md` pro evidenci postupu.
