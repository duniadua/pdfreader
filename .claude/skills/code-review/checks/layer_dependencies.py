"""
Check architecture layer dependencies
Based on: .claude/rules/architecture.md
"""

def check_layer_dependencies(file_path: str, file_content: str) -> list:
    """
    Check that files follow Clean Architecture layer dependencies:
    - Presentation can depend on Domain
    - Domain can depend on nothing
    - Data can depend on nothing (except Core)
    - No data imports in presentation

    Returns list of issues found, empty list if all pass.
    """
    issues = []

    # Determine layer from file path
    if '/presentation/' in file_path:
        layer = 'presentation'
    elif '/domain/' in file_path:
        layer = 'domain'
    elif '/data/' in file_path:
        layer = 'data'
    elif '/models/' in file_path:
        layer = 'core'
    else:
        layer = 'unknown'

    if layer == 'unknown':
        return []  # Can't check unknown files

    # Check imports based on layer
    imports = extract_imports(file_content)

    if layer == 'presentation':
        # Should not import data layer
        for imp in imports:
            if is_data_import(imp):
                issues.append({
                    'issue': 'Presentation layer should not import Data layer directly',
                    'rule': 'architecture.md line 67-89',
                    'file': file_path,
                    'import': imp,
                    'fix': 'Import through Domain layer (use cases, repositories)'
                })

    elif layer == 'domain':
        # Should not import Flutter or presentation
        for imp in imports:
            if is_flutter_import(imp):
                issues.append({
                    'issue': 'Domain layer should not import Flutter',
                    'rule': 'architecture.md line 45-66',
                    'file': file_path,
                    'import': imp,
                    'fix': 'Move Flutter-dependent code to Presentation layer'
                })
            elif is_presentation_import(imp):
                issues.append({
                    'issue': 'Domain layer should not import Presentation layer',
                    'rule': 'architecture.md line 45-66',
                    'file': file_path,
                    'import': imp,
                    'fix': 'Remove circular dependency'
                })

    elif layer == 'data':
        # Should not import domain or presentation
        for imp in imports:
            if is_domain_import(imp) or is_presentation_import(imp):
                issues.append({
                    'issue': 'Data layer should not import Domain or Presentation',
                    'rule': 'architecture.md line 90-112',
                    'file': file_path,
                    'import': imp,
                    'fix': 'Data layer should be independent of upper layers'
                })

    return issues


def extract_imports(content: str) -> list:
    """Extract all import statements from content."""
    imports = []
    for line in content.split('\n'):
        stripped = line.strip()
        if stripped.startswith('import '):
            imports.append(stripped)
    return imports


def is_data_import(import_stmt: str) -> bool:
    """Check if import is from data layer."""
    return '/data/' in import_stmt or '/datasources/' in import_stmt


def is_domain_import(import_stmt: str) -> bool:
    """Check if import is from domain layer."""
    return '/domain/' in import_stmt


def is_presentation_import(import_stmt: str) -> bool:
    """Check if import is from presentation layer."""
    return '/presentation/' in import_stmt


def is_flutter_import(import_stmt: str) -> bool:
    """Check if import is from Flutter."""
    return import_stmt.startswith('import \'package:flutter/')
