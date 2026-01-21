#!/usr/bin/env python3
# Simple structure counter for Lua

with open('Communication.lua', 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

# Count occurrences
function_count = content.count('function')
end_count = content.count(' end')
end_count += content.count('\nend')
end_count += content.count('end)')

print(f"Total 'function' keywords: {function_count}")
print(f"Total 'end' keywords (approx): {end_count}")
print(f"Difference: {end_count - function_count}")

# Now let's find which function might be missing an end
lines = content.split('\n')
stack = []
unclosed = []

for i, line in enumerate(lines, 1):
    stripped = line.strip()
    
    # Skip comments
    if stripped.startswith('--'):
        continue
    
    # Track function starts
    if 'function' in line and not '--' in line.split('function')[0]:
        # Extract function name
        func_name = line.strip()[:80]
        stack.append((i, func_name))
    
    # Track ends
    if stripped.startswith('end') or ' end' in line or 'end)' in line:
        if stack:
            stack.pop()

print(f"\n{'='*60}")
print("UNCLOSED FUNCTIONS:")
print('='*60)
for line_num, func_name in stack:
    print(f"Line {line_num}: {func_name}")

print(f"\nTotal unclosed functions: {len(stack)}")
