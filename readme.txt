Для работы необходимо скачать и установить xml-редактор, например, Komodo Edit

На маке гит-проект нужно разместить в пользовательской папке Sites

Обычно, папки с файлами системы называются XML
Внутри нее требуется создать папку для локальных данных с именем data
и дать права на запись туда всем (достаточно только апачу)

Еще нужно рядом с папкой системы положить папку libs:
скачав и распаковав этот файл: https://github.com/downloads/Unact/xmlinterface/libs.zip
чтобы получилась папка ~/Sites/libs

В libs должны быть: jquery, плагин к нему и HTTPRetriever.php


Вот так можно в командной строке инициализировать файлы инстанса системы:

cd ~/Sites

mkdir XML

cd XML

git init

git remote add origin git@github.com:Unact/xmlinterface.git

git pull origin master

mkdir data

chmod data a+w

Дальше нужно читать вики