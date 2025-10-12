# MyLastPrice

**MyLastPrice** je minimalistický World of Warcraft addon, který si pamatuje tvoji poslední cenu při vystavení itemu v aukčním domě a zobrazuje ji v tooltipu.

---

## ✨ Funkce
- Ukládá poslední cenu za kus při vystavení itemu nebo commodity.
- Zobrazuje uloženou cenu v tooltipu (batoh, aukční dům, pošta, chat odkazy).
- Funguje pro všechny typy itemů (equipy, rudy, bylinky, apod.).
- Nepotřebuje žádné další addony ani složité nastavení.
- Ukládá data mezi relogy pomocí `SavedVariables`.

---

## 📂 Instalace
1. Stáhni nebo vytvoř složku `MyLastPrice` v adresáři kde WoW ukládá adony
2. Ve složce `MyLastPrice` jsou dva soubory:
- `MyLastPrice.toc`
- `MyLastPrice.lua`
3. Ujisti se, že soubory mají správné přípony (`.toc`, `.lua`), ne `.txt`.
4. Spusť hru a na login screenu zkontroluj, že je addon zapnutý.

---

## ⚙️ Použití
- Vystav item v aukčním domě → addon uloží cenu za kus.
- Najetím myší na stejný item uvidíš v tooltipu řádek: 
Moje poslední cena: Xg Ys Zc
- Příkaz `/mlp reset` vymaže databázi cen.

---

## 🛠️ Kompatibilita
- Retail WoW, patch **11.2.5** (říjen 2025).
- Pokud Blizzard změní API, bude potřeba addon upravit (nejčastěji jen číslo `## Interface:` v `.toc`).

---

## 📜 Licence
Addon je volně k použití, i sdílení.
