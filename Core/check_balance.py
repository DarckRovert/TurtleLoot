#!/usr/bin/env python3
# Script to check Lua syntax balance

def check_lua_balance(filename):
    stack = []  # Stack to track open structures
    
    with open(filename, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    for line_num, line in enumerate(lines, 1):
        stripped = line.strip()
        
        # Skip comments and empty lines
        if stripped.startswith('--') or not stripped:
            continue
        
        # Remove inline comments
        if '--' in stripped:
            code_part = stripped.split('--')[0].strip()
        else:
            code_part = stripped
        
        # Check for opening keywords
        if code_part.startswith('function ') or ' function(' in code_part or ' function ' in code_part:
            stack.append(('function', line_num, code_part[:50]))
        elif code_part.startswith('if ') or ' if ' in code_part:
            if 'then' in code_part:
                stack.append(('if', line_num, code_part[:50]))
        elif code_part.startswith('for ') or ' for ' in code_part:
            if ' do' in code_part or code_part.endswith(' do'):
                stack.append(('for', line_num, code_part[:50]))
        elif code_part.startswith('while ') or ' while ' in code_part:
            if ' do' in code_part or code_part.endswith(' do'):
                stack.append(('while', line_num, code_part[:50]))
        elif code_part.startswith('repeat'):
            stack.append(('repeat', line_num, code_part[:50]))
        elif code_part.startswith('do') or code_part == 'do':
            stack.append(('do', line_num, code_part[:50]))
        
        # Check for closing keywords
        if code_part == 'end' or code_part.startswith('end ') or code_part.endswith(' end'):
            if stack:
                closed = stack.pop()
                print(f"Line {line_num}: 'end' closes {closed[0]} from line {closed[1]}")
            else:
                print(f"Line {line_num}: ERROR - 'end' without matching opening!")
        elif code_part == 'until' or code_part.startswith('until '):
            if stack and stack[-1][0] == 'repeat':
                closed = stack.pop()
                print(f"Line {line_num}: 'until' closes {closed[0]} from line {closed[1]}")
    
    print("\n" + "="*60)
    if stack:
        print("UNCLOSED STRUCTURES:")
        for item in stack:
            print(f"  Line {item[1]}: {item[0]} - {item[2]}")
    else:
        print("All structures are properly closed!")
    print("="*60)

if __name__ == '__main__':
    check_lua_balance('Communication.lua')
