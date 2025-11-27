import os
import re
import csv

# --- Конфигурация ---
# Имя файла, в который будут сохранены пары ключ-текст
OUTPUT_FILENAME = "cli_translations_for_csv.txt"

# --- Глобальные переменные ---
# Список для хранения всех найденных пар [ключ, текст]
key_text_pairs = []
# Глобальный счетчик для обеспечения уникальности ключей
key_counter = 1

def sanitize_for_key(text):
    """Превращает имя файла в безопасную часть ключа."""
    return re.sub(r'[^a-zA-Z0-9_]+', '', text.lower())

def process_level_file(filepath):
    """
    Обрабатывает один файл уровня: находит секции [cli],
    извлекает текст, генерирует ключи и готовит новые строки файла.
    """
    global key_counter
    
    # Создаем базовое имя для ключей из имени файла
    base_filename = sanitize_for_key(os.path.splitext(os.path.basename(filepath))[0])
    
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"  ОШИБКА: Не удалось прочитать файл {filepath}. Пропуск. {e}")
        return

    new_lines = []
    in_cli_section = False
    file_changed = False

    for line in lines:
        stripped_line = line.strip()

        # Проверяем, не находимся ли мы в новой секции
        if stripped_line.startswith('[') and stripped_line.endswith(']'):
            in_cli_section = (stripped_line == '[cli]')
            new_lines.append(line)
            continue

        # Если мы в секции [cli] и строка не пустая
        if in_cli_section and stripped_line:
            original_text = stripped_line
            
            # Генерируем новый ключ
            key = f"cli_{base_filename}_{str(key_counter).zfill(3)}"
            key_counter += 1
            
            # Сохраняем пару для будущего TXT-файла
            key_text_pairs.append([key, original_text])
            
            # Заменяем оригинальную строку на ключ
            # Сохраняем исходные отступы, заменяя только текст
            indentation = line[:len(line) - len(line.lstrip())]
            new_lines.append(f"{indentation}{key}\n")
            
            file_changed = True
            print(f"  Найден текст в {os.path.basename(filepath)}: \"{original_text[:60]}...\" -> {key}")
        else:
            # Если мы не в секции [cli] или строка пустая, оставляем ее как есть
            new_lines.append(line)

    # Если в файле были изменения, перезаписываем его
    if file_changed:
        try:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.writelines(new_lines)
            print(f"  -> Файл {os.path.basename(filepath)} успешно изменен.")
        except Exception as e:
            print(f"  ОШИБКА: Не удалось записать в файл {filepath}. {e}")

def main():
    """Главная функция скрипта."""
    print("Запуск скрипта для перевода секций [cli]...")
    print(f"Рабочая директория: {os.getcwd()}")
    print("ВАЖНО: Убедитесь, что вы сделали резервную копию (коммит в Git)!")
    input("Нажмите Enter для продолжения...")

    # Рекурсивно обходим все файлы и папки, начиная с текущей ('.')
    for root, _, files in os.walk('.'):
        for filename in files:
            # Пропускаем файлы 'sequence'
            if filename == 'sequence':
                continue
            
            filepath = os.path.join(root, filename)
            process_level_file(filepath)
            
    # Если мы нашли хотя бы один текст для перевода
    if key_text_pairs:
        print(f"\nНайдено {len(key_text_pairs)} строк текста.")
        print(f"Сохранение пар ключ-текст в файл '{OUTPUT_FILENAME}'...")
        try:
            with open(OUTPUT_FILENAME, 'w', newline='', encoding='utf-8') as f:
                # Используем csv.writer для корректной обработки кавычек и запятых
                writer = csv.writer(f, quoting=csv.QUOTE_ALL)
                for key, text in key_text_pairs:
                    # Записываем в формате: "ключ","английский текст",
                    # Пустая строка в конце добавляет ту самую висячую запятую
                    writer.writerow([key, text, ''])
            print(f"  Файл '{OUTPUT_FILENAME}' успешно создан.")
            print("\nТеперь скопируйте содержимое этого файла и вставьте в конец вашего основного translations.csv")
        except Exception as e:
            print(f"  ОШИБКА: Не удалось создать файл '{OUTPUT_FILENAME}'. {e}")
    else:
        print("\nТекст в секциях [cli] для перевода не найден.")
        
    print("\nСкрипт завершил работу.")

if __name__ == "__main__":
    main()
