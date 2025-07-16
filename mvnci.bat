@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

rem Определение папки скрипта
set "scriptDir=%~dp0"

rem Папка cfg внутри папки скрипта
set "configDir=%scriptDir%cfg\"
set "configFile=%configDir%config.ini"

rem Проверка наличия cfg
if not exist "%configDir%" (
    echo Ошибка: Отсутствует папка %configDir%
    echo Создайте папку "cfg" и добавьте файл "config.ini" с переменной CURRENT_PROJECT_HOME
    echo Пример содержимого файла:
    echo CURRENT_PROJECT_HOME=D:\Projects\ВашПуть
    pause
    exit /b 1
)

rem Чтение переменной CURRENT_PROJECT_HOME из файла
if exist "%configFile%" (
    for /f "usebackq tokens=1* delims==" %%A in ("%configFile%") do (
        if /i "%%A"=="CURRENT_PROJECT_HOME" (
            set "CURRENT_PROJECT_HOME=%%B"
        )
    )
)

rem Проверка существования пути
if not defined CURRENT_PROJECT_HOME (
    echo Ошибка: Не найдена переменная CURRENT_PROJECT_HOME в файле %configFile%
    pause
    exit /b 1
)
if not exist "%CURRENT_PROJECT_HOME%" (
    echo Ошибка: Путь из config.ini не существует: %CURRENT_PROJECT_HOME%
    pause
    exit /b 1
)

:main
cls
echo ==============================================
echo            Выбор проекта для сборки
echo ==============================================
echo.
echo Текущий путь к проекту: %CURRENT_PROJECT_HOME%
echo.
echo Получение списка папок...

rem Создаем список проектов
set "projects_list="
set /a index=0

for /d %%D in ("%CURRENT_PROJECT_HOME%\*") do (
    set "folderName=%%~nxD"
    set "firstChar=!folderName:~0,1!"
    rem Пропускаем папки, начинающиеся на точку
    if "!firstChar!"=="." (
        rem пропускаем
    ) else (
        set /a index+=1
        set "project_!index!=%%~nxD"
    )
)

rem Проверка наличия подходящих папок
if %index% equ 0 (
    echo Нет доступных папок в %CURRENT_PROJECT_HOME%
    pause
    goto main
)

rem Вывод списка
echo.
for /l %%i in (1,1,%index%) do (
    rem Получаем имя проекта
    set "projName=!project_%%i!"
    echo %%i. !projName!
)

rem Ввод выбора
echo.
set /p choice=Введите номер проекта (1-%index%): 

rem Проверка корректности
set "validChoice="
for /l %%i in (1,1,%index%) do (
    if "%%i"=="%choice%" set "validChoice=1"
)
if not defined validChoice (
    echo Неверный выбор. Попробуйте снова.
    pause
    goto main
)

rem Получаем выбранный проект
set "selected=!project_%choice%!"

echo.
echo Вы выбрали: !selected!
echo.

rem Проверка существования папки проекта
if not exist "%CURRENT_PROJECT_HOME%\!selected!" (
    echo Ошибка: Папка проекта !selected! не найдена.
    pause
    goto main
)

rem Вопрос о git pull
set /p gitPull=Выполнить 'git pull' перед сборкой? (Y/N): 
if /i "%gitPull%"=="" set "gitPull=Y"

if /i "%gitPull%"=="Y" (
    echo Выполняется git pull в папке проекта...
    pushd "%CURRENT_PROJECT_HOME%\!selected!"
    git pull
    popd
) else (
    echo Пропуск выполнения git pull.
)

echo Выполняется команда Maven...
set "pomPath=%CURRENT_PROJECT_HOME%\!selected!\pom.xml"
if not exist "%pomPath%" (
    echo Ошибка: файл pom.xml не найден по пути: %pomPath%
    pause
    goto main
)

echo.
echo "%pomPath%"

mvn -f "%pomPath%" clean install -DskipTests

echo.
pause
goto main
