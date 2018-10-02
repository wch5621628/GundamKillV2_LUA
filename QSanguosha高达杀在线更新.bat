:: Update LUA and AI from GitHub
:: Author: wch5621628
:: Declaration: This is NOT a virus. You can use it safely.
:: Instruction: Drag this bat file into the root directory of QSanguosha, execute it and wait until the program finishes.
:: For Developers: You may "set" your own url and file list in order to fulfill your QSanguosha MOD requirement.

@echo off
set "url=https://github.com/wch5621628/GundamKillV2_LUA/raw/master/"

:: Update LUA
set "lua_list=gaoda.lua gaodacard.lua gaodaexcard.lua boss.lua zabing.lua"
for %%i in (%lua_list%) do (
 :: download lua
 certutil.exe -urlcache -split -f %url%%%i extensions\%%i
 :: delete cache
 certutil -urlcache %url%%%i delete
)

:: Update AI
set "ai_list=gaoda-ai.lua gaodacard-ai.lua"
for %%i in (%ai_list%) do (
 :: download ai
 certutil.exe -urlcache -split -f %url%%%i lua\ai\%%i
 :: delete cache
 certutil -urlcache %url%%%i delete
)

:: Execute QSanguosha.exe after update
echo "Update Completed!"
start QSanguosha.exe

:: Reference: https://www.dostips.com/forum/viewtopic.php?t=8485
