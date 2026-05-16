#!/usr/bin/env python3
import sys

if len(sys.argv) < 2:
    print("Uso: register-templates.py <app-config-path>")
    sys.exit(1)

config_path = sys.argv[1]

with open(config_path, 'r') as f:
    lines = f.readlines()

# 1. Agregar Template a catalog.rules
for i, line in enumerate(lines):
    if 'allow: [Component, System, API, Resource, Location]' in line:
        lines[i] = line.replace(
            'allow: [Component, System, API, Resource, Location]',
            'allow: [Component, System, API, Resource, Location, Template]'
        )
        break

# 2. Insertar templates y org.yaml después de '        - allow: [User, Group]'
insert_lines = []
if not any('nodejs-service/template.yaml' in l for l in lines):
    insert_lines.extend([
        '\n',
        '    # Workshop Golden Paths template - Node.js Service\n',
        '    - type: file\n',
        '      target: ../../templates/nodejs-service/template.yaml\n',
        '      rules:\n',
        '        - allow: [Template]\n',
    ])
if not any('backstage-skeleton/template.yaml' in l for l in lines):
    insert_lines.extend([
        '\n',
        '    # Workshop Golden Paths template - Backstage Skeleton\n',
        '    - type: file\n',
        '      target: ../../templates/backstage-skeleton/template.yaml\n',
        '      rules:\n',
        '        - allow: [Template]\n',
    ])
if not any('../../org.yaml' in l for l in lines):
    insert_lines.extend([
        '\n',
        '    # Workshop org data (groups and users)\n',
        '    - type: file\n',
        '      target: ../../org.yaml\n',
        '      rules:\n',
        '        - allow: [Group, User]\n',
    ])

if insert_lines:
    for i in range(len(lines) - 1, -1, -1):
        if lines[i].strip() == '- allow: [User, Group]':
            lines = lines[:i+1] + insert_lines + lines[i+1:]
            break
    with open(config_path, 'w') as f:
        f.writelines(lines)
    print('Templates y org data registrados en app-config.yaml')
else:
    print('Todos los templates ya estaban registrados')
