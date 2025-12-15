#!/bin/bash
echo "Test entrypoint - not for production"
exec .venv/bin/python src/main.py
