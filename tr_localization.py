import os
import re
import csv
import json
from collections import OrderedDict

# ... (секция конфигурации и глобальных переменных остается той же) ...
CSV_FILENAME = 'translations.csv'
DIRS_TO_PROCESS = ['scenes', 'levels']
CARDS_JSON_PATH = 'resources/cards.json'
text_to_key_map = OrderedDict()
key_counter = 1

def sanitize_for_key(text):
    return re.sub(r'[^a-zA-Z0-9_]+', '', text.lower())

def generate_key(base_name):
    global key_counter
    key = f"{base_name}_{str(key_counter).zfill(3)}"
    key_counter += 1
    return key

def add_text(text, base_name):
    cleaned_text = text.strip()
    if not cleaned_text or cleaned_text in text_to_key_map:
        return cleaned_text
    key = generate_key(base_name)
    text_to_key_map[cleaned_text] = key
    print(f"  Найден текст: \"{cleaned_text[:60].replace(chr(10), ' ')}...\" -> Ключ: {key}")
    return cleaned_text

# --- ИСПРАВЛЕННАЯ ЛОГИКА СБОРА ДЛЯ УРОВНЕЙ ---
def collect_from_level_file(filepath, base_key):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    title_regex = re.compile(r'^\s*title\s*=\s*(.*)', re.MULTILINE)
    match = title_regex.search(content)
    if match: add_text(match.group(1), f"{base_key}_title")
    
    # Собираем description и congrats как единые блоки
    for section_name in ['description', 'congrats']:
        regex = re.compile(rf'\[{section_name}\]\n(.*?)(?=\n\[|$)', re.DOTALL)
        match = regex.search(content)
        if match: add_text(match.group(1), f"{base_key}_{section_name}")

    # Собираем подсказки из [win] построчно
    win_hint_regex = re.compile(r'^\s*#\s*(.*)', re.MULTILINE)
    win_regex = re.compile(r'\[win\]\n(.*?)(?=\n\[|$)', re.DOTALL)
    win_match = win_regex.search(content)
    if win_match:
        for match in win_hint_regex.finditer(win_match.group(1)):
            add_text(match.group(1), f"{base_key}_win_hint")

# --- ИСПРАВЛЕННАЯ ЛОГИКА ЗАМЕНЫ ДЛЯ УРОВНЕЙ ---
def replace_in_level_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    original_content = content

    # Заменяем в обратном порядке, чтобы избежать замены частей ключей
    for text, key in reversed(list(text_to_key_map.items())):
        # Используем re.escape для безопасной замены текста со спецсимволами
        escaped_text = re.escape(text)
        content = re.sub(f'^{escaped_text}$', key, content, flags=re.MULTILINE) # Для блоков
        content = re.sub(f'(?<=title = ){escaped_text}', key, content) # Для title
        content = re.sub(f'(?<=# ){escaped_text}', key, content) # Для win hints

    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f: f.write(content)
        print(f"  Замена в уровне: {filepath}")

# ... (остальной код скрипта, включая main, tscn, cards.json, остается таким же, как в localize_final.py)
# ... Я вставлю его целиком ниже для удобства.
def collect_from_tscn(filepath, base_key):
    node_name_regex = re.compile(r'^\[node name="([^"]+)"')
    text_regex = re.compile(r'^\s*(text|bbcode_text)\s*=\s*"((?:\\"|[^"])*)"')
    current_node_name = "node"
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            match = node_name_regex.match(line)
            if match: current_node_name = match.group(1)
            match = text_regex.match(line)
            if match: add_text(match.group(2).replace('\\"', '"'), f"{base_key}_{sanitize_for_key(current_node_name)}")

def collect_from_cards_json():
    if not os.path.exists(CARDS_JSON_PATH): return
    base_key = sanitize_for_key(os.path.splitext(os.path.basename(CARDS_JSON_PATH))[0])
    with open(CARDS_JSON_PATH, 'r', encoding='utf-8') as f: data = json.load(f)
    for card in data:
        card_id = card.get('id', 'card')
        add_text(card.get('description'), f"card_{sanitize_for_key(card_id)}_desc")

def replace_in_tscn(filepath):
    text_regex = re.compile(r'^\s*(text|bbcode_text)\s*=\s*"((?:\\"|[^"])*)"')
    with open(filepath, 'r', encoding='utf-8') as f: lines = f.readlines()
    new_lines, changed = [], False
    for line in lines:
        match = text_regex.match(line)
        if match:
            prop, text = match.group(1), match.group(2).replace('\\"', '"').strip()
            if text in text_to_key_map:
                key = text_to_key_map[text]
                indent = line[:line.find(prop)]
                new_lines.append(f'{indent}{prop} = "{key}"\n')
                changed = True
            else: new_lines.append(line)
        else: new_lines.append(line)
    if changed:
        with open(filepath, 'w', encoding='utf-8') as f: f.writelines(new_lines)
        print(f"  Замена в сцене: {filepath}")

def replace_in_cards_json():
    if not os.path.exists(CARDS_JSON_PATH): return
    with open(CARDS_JSON_PATH, 'r', encoding='utf-8') as f:
        data = json.load(f, object_pairs_hook=OrderedDict)
    changed = False
    for card in data:
        desc = card.get('description', "").strip()
        if desc in text_to_key_map:
            card['description'] = text_to_key_map[desc]
            changed = True
    if changed:
        with open(CARDS_JSON_PATH, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=4, ensure_ascii=False)
        print(f"  Замена в карточках: {CARDS_JSON_PATH}")

def main():
    print("--- Фаза 1: Сбор всего текста ---")
    for directory in DIRS_TO_PROCESS:
        for root, _, files in os.walk(directory):
            for filename in files:
                filepath = os.path.join(root, filename)
                base_key = sanitize_for_key(os.path.splitext(filename)[0])
                if filename.endswith('.tscn'):
                    collect_from_tscn(filepath, base_key)
                elif directory == 'levels' and filename != 'sequence':
                    collect_from_level_file(filepath, base_key)
    collect_from_cards_json()
    if not text_to_key_map:
        print("\nНовый текст для перевода не найден.")
        return
    print(f"\nНайдено {len(text_to_key_map)} уникальных строк. Запись в {CSV_FILENAME}...")
    with open(CSV_FILENAME, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['keys', 'en', 'ru'])
        for text, key in text_to_key_map.items():
            writer.writerow([key, text, ''])
    print("\n--- Фаза 2: Замена текста на ключи ---")
    for directory in DIRS_TO_PROCESS:
        for root, _, files in os.walk(directory):
            for filename in files:
                filepath = os.path.join(root, filename)
                if filename.endswith('.tscn'):
                    replace_in_tscn(filepath)
                elif directory == 'levels' and filename != 'sequence':
                    replace_in_level_file(filepath)
    replace_in_cards_json()
    print("\nСкрипт успешно завершил работу!")
    print("ВАЖНО: Теперь внесите ручные изменения в game.gd и level.gd, как было описано.")

if __name__ == '__main__':
    print("Запуск ИСПРАВЛЕННОГО v2 скрипта локализации.")
    print("ВАЖНО: Сделайте коммит или резервную копию перед запуском!")
    input("Нажмите Enter для продолжения...")
    main()
