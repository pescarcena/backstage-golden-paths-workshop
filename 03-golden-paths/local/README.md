# Paso 03: Golden Paths - Modo Local

En modo local, los templates se copian al directorio del proyecto Backstage y se registran directamente en `app-config.yaml`.

## Modo automatico

```bash
make all
# Reinicia Backstage (Ctrl+C y vuelve a ejecutar make start-backstage desde el root)
```

## Pasos manuales

### 1. Copiar templates al proyecto Backstage

```bash
mkdir -p ../../02-deploy-backstage/local/backstage-app/templates
cp -r ../shared/templates/nodejs-service ../../02-deploy-backstage/local/backstage-app/templates/
```

### 2. Registrar el template en app-config.yaml

Agrega la siguiente entrada en la seccion `catalog.locations` del `app-config.yaml` del proyecto Backstage:

```yaml
    # Workshop Golden Paths template
    - type: file
      target: ../../templates/nodejs-service/template.yaml
      rules:
        - allow: [Template]
```

Asegurate tambien que `Template` este en `catalog.rules`:

```yaml
  rules:
    - allow: [Component, System, API, Resource, Location, Template]
```

### 3. Reiniciar Backstage

```bash
# Desde el root del workshop
make start-backstage
```

### 4. Verificar

Abre http://localhost:3000/create y verifica que el template "Servicio Node.js" aparece.

## Diferencias con modo Kubernetes

| Aspecto | Local | Kubernetes |
|---------|-------|------------|
| Templates | Copiados a backstage-app/templates/ | Montados via ConfigMap + init container |
| Config | Registrados en app-config.yaml | ConfigMap backstage-app-config actualizado |
| Hot reload | Si (reiniciar yarn start) | Requiere rollout restart |
