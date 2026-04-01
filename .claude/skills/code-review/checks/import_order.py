"""
Check import order: dart → flutter → package → relative
Based on: .claude/rules/code-style.md lines 15-31
"""

def check_import_order(file_content: str, file_path: str) -> dict | None:
    """
    Check that imports follow the correct order:
    1. dart: imports
    2. flutter: imports (blank line after)
    3. package: imports (blank line after)
    4. relative imports with ../ prefix

    Returns None if check passes, dict with issue details if fails.
    """
    lines = file_content.split('\n')
    imports = []
    import_indices = []

    # Extract all imports
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith('import '):
            imports.append({
                'line': i + 1,
                'content': stripped,
                'type': classify_import(stripped)
            })
            import_indices.append(i)

    if not imports:
        return None  # No imports to check

    # Verify order
    dart_imports = [imp for imp in imports if imp['type'] == 'dart']
    flutter_imports = [imp for imp in imports if imp['type'] == 'flutter']
    package_imports = [imp for imp in imports if imp['type'] == 'package' and imp['type'] != 'flutter']
    relative_imports = [imp for imp in imports if imp['type'] == 'relative']

    expected_order = dart_imports + flutter_imports + package_imports + relative_imports

    # Check if actual order matches expected
    if imports == expected_order:
        return None

    # Find the first violation
    for i, imp in enumerate(imports):
        if i < len(expected_order) and imp != expected_order[i]:
            return {
                'issue': 'Import order violation',
                'rule': 'code-style.md lines 15-31',
                'line': imp['line'],
                'file': file_path,
                'current': imp['content'],
                'expected_order': 'dart → flutter → package → relative',
                'fix': 'Reorganize imports to follow the correct order'
            }

    return None


def classify_import(import_statement: str) -> str:
    """Classify import statement by type."""
    statement = import_statement.strip()

    if statement.startswith('import \'dart:'):
        return 'dart'
    elif statement.startswith('import \'package:flutter/'):
        return 'flutter'
    elif statement.startswith('import \'package:'):
        return 'package'
    else:
        return 'relative'
