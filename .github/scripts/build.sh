#!/bin/bash

w_dir=$1

game_files_dir="$w_dir/WuWaGameFiles"
make_pak_from_dir="$game_files_dir/Russian"

unreal_pak="$w_dir/UnrealPak/Engine/Binaries/Linux/UnrealPak"

cs_files_map_gen="$w_dir/WuWaTools/UeFilesMapGen/UeFilesMapGen.csproj"
py_csv_import="$w_dir/WuWaTransHelper/import.py"

pak_map_file="$w_dir/files.txt"
pak_file="$w_dir/pakchunk0-1.0.0-1.1.0-WindowsNoEditor_10000_P.pak"

export DIR_ORIGINAL="$game_files_dir/English/Client/Content/Aki/ConfigDB/en"
export DIR_TRANSLATED="$make_pak_from_dir/Client/Content/Aki/ConfigDB/en"
export FILE_CSV="$w_dir/Translations.csv"

echo "Copying EN files instead of DE..."
mkdir -p "$make_pak_from_dir/Client/Content/Aki/ConfigDB/de"
cp -r "$DIR_ORIGINAL/." "$make_pak_from_dir/Client/Content/Aki/ConfigDB/de/"

echo "Importing CSV to game files..."
python3 "$py_csv_import"

echo "Generating files map..."
dotnet run "$make_pak_from_dir" -c Release --project "$cs_files_map_gen"

echo "Building .pak file..."

echo "{" \
	 "  \"\$types\": {" \
     "    \"UnrealBuildTool.EncryptionAndSigning+CryptoSettings, UnrealBuildTool, Version=4.0.0.0, Culture=neutral, PublicKeyToken=null\": \"1\"," \
     "    \"UnrealBuildTool.EncryptionAndSigning+EncryptionKey, UnrealBuildTool, Version=4.0.0.0, Culture=neutral, PublicKeyToken=null\": \"2\"" \
     "  }," \
     "  \"\$type\": \"1\"," \
     "  \"EncryptionKey\": {" \
     "    \"\$type\": \"2\"," \
     "    \"Name\": null," \
     "    \"Guid\": null," \
     "    \"Key\": \"$PAK_KEY\""\
     "  },"\
     "  \"SigningKey\": null," \
     "  \"bEnablePakSigning\": false," \
     "  \"bEnablePakIndexEncryption\": true," \
     "  \"bEnablePakIniEncryption\": true," \
     "  \"bEnablePakUAssetEncryption\": false," \
     "  \"bEnablePakFullAssetEncryption\": false," \
     "  \"bDataCryptoRequired\": false," \
     "  \"SecondaryEncryptionKeys\": []" \
     "}" > "$w_dir/crypto.json"

chmod +x "$unreal_pak"
"$unreal_pak" "$pak_file" "-Create=$pak_map_file" -compress "-cryptokeys=$w_dir/crypto.json" -encrypt -encryptindex

sha256sum "$pak_file" | awk '{ print $1 }' > "$pak_file.sha256"