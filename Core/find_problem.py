#!/usr/bin/env python3

with open('Communication.lua', 'r', encoding='utf-8') as f:
    lines = f.readlines()

stack = []

for i, line in enumerate(lines, 1):
    stripped = line.strip()
    
    # Skip comments
    if stripped.startswith('--'):
        continue
    
    # Count function
    if 'function' in line:
        stack.append(('function', i))
    
    # Count if...then
    if ' then' in line or stripped.startswith('if '):
        if 'then' in line:
            stack.append(('if', i))
    
    # Count for...do
    if stripped.startswith('for ') and ' do' in line:
        stack.append(('for', i))
    
    # Count while...do  
    if stripped.startswith('while ') and ' do' in line:
        stack.append(('while', i))
    
    # Count end
    if stripped == 'end' or stripped.startswith('end)') or stripped.startswith('end '):
        if stack:
            popped = stack.pop()
            print(f"L{i}: end closes {popped[0]} from L{popped[1]}")
        else:
            print(f"L{i}: EXTRA end without opening!")

print("\n" + "="*60)
print("UNCLOSED STRUCTURES:")
print("="*60)
for item in stack:
    print(f"L{item[1]}: {item[0]} NOT CLOSED")

print(f"\nTotal unclosed: {len(stack)}")
