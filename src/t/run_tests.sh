#!/bin/bash

# Nastavíme PATH tak, aby obsahoval BitKeeper binární soubor
export PATH=/home/lukascernohorsky/Projects/bitkeeper/src:$PATH

# Přejdeme do adresáře s testy
cd /home/lukascernohorsky/Projects/bitkeeper/src/t

# Spustíme testy s verbose výstupem
exec ./doit -v
