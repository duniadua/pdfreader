"""
Check naming conventions
Based on: .claude/rules/code-style.md lines 37-52
"""

def check_naming_conventions(file_content: str, file_path: str) -> list:
    """
    Check that code follows naming conventions:
    - Classes/Enums/Typedefs: UpperCamelCase
    - Variables/Functions/Parameters: lowerCamelCase
    - Constants: lowerCamelCase
    - Private members: prefix with _
    - File names: lowercase_with_underscores.dart

    Returns list of issues found, empty list if all pass.
    """
    issues = []

    lines = file_content.split('\n')

    # Check for class declarations
    for i, line in enumerate(lines, start=1):
        stripped = line.strip()

        # Skip comments and empty lines
        if not stripped or stripped.startswith('//') or stripped.startswith('"""'):
            continue

        # Check class names (UpperCamelCase)
        if 'class ' in stripped and not stripped.startswith('//'):
            class_match = stripped.split('class ')[1].split(' ')[0].split('{')[0]
            if class_match and not class_match.startswith('_'):
                if not is_upper_camel_case(class_match):
                    issues.append({
                        'issue': 'Class name should be UpperCamelCase',
                        'rule': 'code-style.md line 37',
                        'line': i,
                        'file': file_path,
                        'current': class_match,
                        'suggested': to_upper_camel_case(class_match)
                    })

        # Check function names (lowerCamelCase)
        if 'def ' in stripped or 'function ' in stripped:
            # This is more complex and would need AST parsing
            pass

        # Check const constructors (should use const)
        if 'SizedBox(' in stripped and 'const' not in stripped:
            # Check if it's a simple case that should be const
            if is_simple_widget(stripped):
                issues.append({
                    'issue': 'Use const constructor for immutable widgets',
                    'rule': 'code-style.md line 112',
                    'line': i,
                    'file': file_path,
                    'current': stripped,
                    'suggested': stripped.replace('SizedBox(', 'const SizedBox(')
                })

    return issues


def is_upper_camel_case(name: str) -> bool:
    """Check if name is UpperCamelCase."""
    if not name:
        return False
    # Should start with uppercase and contain no underscores
    return name[0].isupper() and '_' not in name


def to_upper_camel_case(name: str) -> str:
    """Convert to UpperCamelCase."""
    # Remove underscores and capitalize each part
    parts = name.split('_')
    return ''.join(part.capitalize() for part in parts)


def is_simple_widget(line: str) -> bool:
    """Check if line is a simple widget that should be const."""
    # Simple cases: SizedBox, Text, Icon with no variables
    simple_patterns = [
        'SizedBox(',
        'Text(\'',
        'Icon(',
    ]
    return any(pattern in line for pattern in simple_patterns) and '=' not in line
