@echo off
IF [%2]==[] (
    python C256Mgr\c256mgr.py -p COM9 -a %1
) ELSE (
    python C256Mgr\c256mgr.py -p COM9 -a %1 -c %2
)