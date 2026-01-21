# Deep analysis of Lua file structure
import re

file_path = r'E:\Turtle Wow\Interface\AddOns\TurtleLoot\Core\Communication.lua'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

stack = []  # Stack to track open structures
errors = []

for i, line in enumerate(lines, 1):
    stripped = line.strip()
    
    # Skip comments
    if stripped.startswith('--'):
        continue
    
    # Remove inline comments
    if '--' in stripped:
        stripped = stripped[:stripped.index('--')].strip()
    
    # Check for function declarations
    if re.search(r'\bfunction\b', stripped):
        stack.append(('function', i, stripped[:50]))
    
    # Check for if statements
    if re.search(r'\bif\b', stripped) and re.search(r'\bthen\b', stripped):
        stack.append(('if', i, stripped[:50]))
    
    # Check for for loops
    if re.search(r'\bfor\b', stripped) and re.search(r'\bdo\b', stripped):
        stack.append(('for', i, stripped[:50]))
    
    # Check for while loops
    if re.search(r'\bwhile\b', stripped) and re.search(r'\bdo\b', stripped):
        stack.append(('while', i, stripped[:50]))
    
    # Check for end keywords
    if re.search(r'\bend\b', stripped):
        if stack:
            closed = stack.pop()
            print(f"Line {i}: Closed {closed[0]} from line {closed[1]}")
        else:
            errors.append(f"Line {i}: Found 'end' but no structure to close!")

print("\n" + "="*60)
print("REMAINING OPEN STRUCTURES:")
print("="*60)

if stack:
    for struct_type, line_num, code in stack:
        print(f"Line {line_num}: Unclosed {struct_type} - {code}")
        errors.append(f"Line {line_num}: Unclosed {struct_type}")
else:
    print("All structures are properly closed!")

print("\n" + "="*60)
print("ERRORS FOUND:")
print("="*60)

if errors:
    for error in errors:
        print(error)
else:
    print("No errors found!")

print(f"\nTotal lines: {len(lines)}")
print(f"Structures still open: {len(stack)}")
