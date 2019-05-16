@echo off
if [%2%]==[] (
    python C256Mgt\c256mgr.py -p COM9 -a %1%
) ELSE (
    python C256Mgt\c256mgr.py -p COM9 -a %1% -c %2%
)