#!/bin/bash

# Функция для создания metadata.json
create_metadata() {
    local folder_name="$1"
    local file_number="$2"
    local metadata_file="$3"
    
    # Создаем красивое название (убираем лишние пробелы)
    clean_folder_name=$(echo "$folder_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Создаем title
    title="${clean_folder_name} №${file_number}"
    
    # Создаем IPFS путь (замените на ваш реальный CID)
    image_path="ipfs/QmYourCIDHere/${folder_name// /_}/${file_number}.jpeg"
    
    cat > "$metadata_file" << EOF
{
    "title": "$title",
    "type": "art",
    "external_url": "https://t.me/SomeSouvenir",
    "description": "test NFT example from project",
    "git": "https://github.com/LikeSouvenir",
    "image": "$image_path"
}
EOF
}

# Основной скрипт
echo "Начало преобразования структуры NFT..."

# Перебираем все папки (игнорируем файлы)
for folder in */; do
    # Убираем слеш в конце названия папки
    folder_name="${folder%/}"
    
    # Пропускаем если это не папка или папка пустая
    if [[ ! -d "$folder" ]] || [[ -z "$(ls -A "$folder")" ]]; then
        continue
    fi
    
    echo "Обрабатываю папку: $folder_name"
    
    # Перебираем все jpeg файлы в папке
    for file in "$folder"*.jpeg; do
        # Проверяем что файл существует (чтобы избежать ошибок при *.jpeg)
        if [[ ! -f "$file" ]]; then
            continue
        fi
        
        # Получаем номер файла из имени (убираем расширение)
        file_number=$(basename "$file" .jpeg)
        
        # Проверяем что номер валидный
        if ! [[ "$file_number" =~ ^[0-9]+$ ]]; then
            echo "  Пропускаю файл с нечисловым именем: $file"
            continue
        fi
        
        # Создаем папку для NFT
        nft_folder="${folder}${file_number}"
        mkdir -p "$nft_folder"
        
        # Перемещаем изображение в папку NFT
        new_image_path="${nft_folder}/${file_number}.jpeg"
        mv "$file" "$new_image_path"
        
        # Создаем metadata.json
        metadata_file="${nft_folder}/metadata.json"
        create_metadata "$folder_name" "$file_number" "$metadata_file"
        
        echo "  Создан NFT: $nft_folder"
    done
    
    echo "Завершено для папки: $folder_name"
    echo "---"
done

echo "Преобразование завершено!"