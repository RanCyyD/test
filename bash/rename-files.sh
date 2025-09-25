#!/bin/bash

# Farben für die Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Hilfsfunktion anzeigen
show_help() {
    echo "Verwendung: $0 [OPTIONEN] SUCHTEXT ERSETZTEXT [VERZEICHNIS]"
    echo ""
    echo "Benennt Dateien und Ordner um, indem SUCHTEXT durch ERSETZTEXT ersetzt wird."
    echo ""
    echo "Optionen:"
    echo "  -r, --recursive     Rekursiv in Unterverzeichnissen arbeiten"
    echo "  -d, --dirs-only     Nur Verzeichnisse umbenennen"
    echo "  -f, --files-only    Nur Dateien umbenennen"
    echo "  -i, --ignore-case   Groß-/Kleinschreibung ignorieren"
    echo "  -p, --preview       Vorschau-Modus (keine Änderungen durchführen)"
    echo "  -v, --verbose       Ausführliche Ausgabe"
    echo "  -h, --help          Diese Hilfe anzeigen"
    echo ""
    echo "Beispiele:"
    echo "  $0 'alt' 'neu' /pfad/zum/ordner"
    echo "  $0 -r -i 'Photo' 'Foto' ."
    echo "  $0 --preview --files-only '2023' '2024' ~/Bilder"
    echo ""
    echo "Hinweis: Verwenden Sie Anführungszeichen für Texte mit Leerzeichen."
}

# Standardwerte
RECURSIVE=false
DIRS_ONLY=false
FILES_ONLY=false
IGNORE_CASE=false
PREVIEW=false
VERBOSE=false
DIRECTORY="."

# Parameter verarbeiten
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--recursive)
            RECURSIVE=true
            shift
            ;;
        -d|--dirs-only)
            DIRS_ONLY=true
            shift
            ;;
        -f|--files-only)
            FILES_ONLY=true
            shift
            ;;
        -i|--ignore-case)
            IGNORE_CASE=true
            shift
            ;;
        -p|--preview)
            PREVIEW=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            echo "Unbekannte Option: $1" >&2
            show_help
            exit 1
            ;;
        *)
            if [[ -z "$SEARCH_TEXT" ]]; then
                SEARCH_TEXT="$1"
            elif [[ -z "$REPLACE_TEXT" ]]; then
                REPLACE_TEXT="$1"
            else
                DIRECTORY="$1"
            fi
            shift
            ;;
    esac
done

# Überprüfung der erforderlichen Parameter
if [[ -z "$SEARCH_TEXT" ]] || [[ -z "$REPLACE_TEXT" ]]; then
    echo -e "${RED}Fehler: Suchtext und Ersetztext sind erforderlich.${NC}" >&2
    show_help
    exit 1
fi

# Überprüfung, ob das Verzeichnis existiert
if [[ ! -d "$DIRECTORY" ]]; then
    echo -e "${RED}Fehler: Verzeichnis '$DIRECTORY' existiert nicht.${NC}" >&2
    exit 1
fi

# Konflikt zwischen --dirs-only und --files-only prüfen
if [[ "$DIRS_ONLY" == true ]] && [[ "$FILES_ONLY" == true ]]; then
    echo -e "${RED}Fehler: --dirs-only und --files-only können nicht gleichzeitig verwendet werden.${NC}" >&2
    exit 1
fi

# Vorschau-Modus Info
if [[ "$PREVIEW" == true ]]; then
    echo -e "${YELLOW}VORSCHAU-MODUS: Keine Änderungen werden durchgeführt.${NC}"
    echo ""
fi

# Statistiken
total_processed=0
total_renamed=0
total_errors=0

# Hauptfunktion für das Umbenennen
rename_item() {
    local full_path="$1"
    local dir_path=$(dirname "$full_path")
    local basename=$(basename "$full_path")
    
    # Suchen und ersetzen
    local new_name
    if [[ "$IGNORE_CASE" == true ]]; then
        # Groß-/Kleinschreibung ignorieren
        new_name=$(echo "$basename" | sed "s/$SEARCH_TEXT/$REPLACE_TEXT/gi")
    else
        # Groß-/Kleinschreibung beachten
        new_name=$(echo "$basename" | sed "s/$SEARCH_TEXT/$REPLACE_TEXT/g")
    fi
    
    # Prüfen, ob eine Änderung stattgefunden hat
    if [[ "$basename" == "$new_name" ]]; then
        if [[ "$VERBOSE" == true ]]; then
            echo -e "${BLUE}Übersprungen:${NC} $full_path (keine Änderung)"
        fi
        return 0
    fi
    
    local new_full_path="$dir_path/$new_name"
    
    ((total_processed++))
    
    if [[ "$PREVIEW" == true ]]; then
        echo -e "${GREEN}Würde umbenennen:${NC} $basename → $new_name"
        ((total_renamed++))
    else
        # Prüfen, ob die Zieldatei bereits existiert
        if [[ -e "$new_full_path" ]]; then
            echo -e "${RED}Fehler:${NC} Ziel '$new_name' existiert bereits in '$dir_path'"
            ((total_errors++))
            return 1
        fi
        
        # Umbenennen durchführen
        if mv "$full_path" "$new_full_path" 2>/dev/null; then
            echo -e "${GREEN}Umbenannt:${NC} $basename → $new_name"
            ((total_renamed++))
        else
            echo -e "${RED}Fehler beim Umbenennen:${NC} $basename"
            ((total_errors++))
        fi
    fi
}

# Find-Optionen zusammenstellen
find_opts=()
if [[ "$RECURSIVE" == false ]]; then
    find_opts+=("-maxdepth" "1")
fi

if [[ "$DIRS_ONLY" == true ]]; then
    find_opts+=("-type" "d")
elif [[ "$FILES_ONLY" == true ]]; then
    find_opts+=("-type" "f")
fi

find_opts+=("-not" "-path" "$DIRECTORY")

echo "Suche nach Elementen, die '$SEARCH_TEXT' enthalten..."
echo "Ersetze durch: '$REPLACE_TEXT'"
echo "Verzeichnis: $DIRECTORY"
if [[ "$RECURSIVE" == true ]]; then
    echo "Modus: Rekursiv"
fi
if [[ "$DIRS_ONLY" == true ]]; then
    echo "Filter: Nur Verzeichnisse"
elif [[ "$FILES_ONLY" == true ]]; then
    echo "Filter: Nur Dateien"
fi
echo ""

# Temporäre Datei für die Ergebnisse
temp_file=$(mktemp)

# Find ausführen und Ergebnisse in temporärer Datei speichern
find "$DIRECTORY" "${find_opts[@]}" -print0 > "$temp_file"

# Überprüfen, ob Elemente gefunden wurden
if [[ ! -s "$temp_file" ]]; then
    echo -e "${YELLOW}Keine Elemente im angegebenen Verzeichnis gefunden.${NC}"
    rm "$temp_file"
    exit 0
fi

# Bei Verzeichnissen: Von tiefsten nach obersten sortieren (für korrekte Umbenennung)
if [[ "$FILES_ONLY" != true ]]; then
    # Sortiere nach Pfadtiefe (umgekehrt)
    sort -t'/' -k2 -nr "$temp_file" > "${temp_file}.sorted"
    mv "${temp_file}.sorted" "$temp_file"
fi

# Durch alle gefundenen Elemente iterieren
while IFS= read -r -d '' item; do
    # Prüfen, ob der Dateiname den Suchtext enthält
    basename_item=$(basename "$item")
    if [[ "$IGNORE_CASE" == true ]]; then
        if echo "$basename_item" | grep -qi "$SEARCH_TEXT"; then
            rename_item "$item"
        fi
    else
        if echo "$basename_item" | grep -q "$SEARCH_TEXT"; then
            rename_item "$item"
        fi
    fi
done < "$temp_file"

# Aufräumen
rm "$temp_file"

# Statistiken anzeigen
echo ""
echo "=== Zusammenfassung ==="
echo "Verarbeitete Elemente: $total_processed"
if [[ "$PREVIEW" == true ]]; then
    echo "Würden umbenannt werden: $total_renamed"
else
    echo "Erfolgreich umbenannt: $total_renamed"
fi
if [[ $total_errors -gt 0 ]]; then
    echo -e "${RED}Fehler: $total_errors${NC}"
fi
echo ""

exit 0
