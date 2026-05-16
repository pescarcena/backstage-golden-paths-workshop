// =============================================================================
// Politica de permisos para Backstage (New Backend System)
// Define quien puede hacer que en la plataforma
// =============================================================================
//
// Para usarlo, necesitas:
// 1. Instalar @backstage/plugin-permission-backend
// 2. Agregar este modulo al backend de Backstage
// 3. Habilitar permisos en app-config.yaml: permission.enabled: true

import { createBackendModule } from '@backstage/backend-plugin-api';
import {
  PolicyDecision,
  AuthorizeResult,
} from '@backstage/plugin-permission-common';
import {
  PermissionPolicy,
  PolicyQuery,
  PolicyQueryUser,
} from '@backstage/plugin-permission-node';
import { policyExtensionPoint } from '@backstage/plugin-permission-node/alpha';

// Permisos del catalogo
import {
  catalogEntityCreatePermission,
  catalogEntityDeletePermission,
  catalogEntityRefreshPermission,
  catalogLocationCreatePermission,
  catalogLocationDeletePermission,
} from '@backstage/plugin-catalog-common/alpha';

class WorkshopPermissionPolicy implements PermissionPolicy {
  async handle(
    request: PolicyQuery,
    user?: PolicyQueryUser,
  ): Promise<PolicyDecision> {
    // Si no hay usuario autenticado, denegar todo
    if (!user) {
      return { result: AuthorizeResult.DENY };
    }

    // Obtener los grupos del usuario desde su identidad
    const userGroups = user.info.ownershipEntityRefs.filter(ref =>
      ref.startsWith('group:'),
    );

    // --- REGLA 1: Admins pueden hacer todo ---
    if (userGroups.includes('group:default/platform-team')) {
      return { result: AuthorizeResult.ALLOW };
    }

    // --- REGLA 2: Solo admins pueden eliminar entidades del catalogo ---
    if (request.permission.name === catalogEntityDeletePermission.name) {
      return { result: AuthorizeResult.DENY };
    }

    // --- REGLA 3: Solo admins pueden eliminar locations ---
    if (request.permission.name === catalogLocationDeletePermission.name) {
      return { result: AuthorizeResult.DENY };
    }

    // --- REGLA 4: Todos pueden crear entidades y locations ---
    if (
      request.permission.name === catalogEntityCreatePermission.name ||
      request.permission.name === catalogLocationCreatePermission.name
    ) {
      return { result: AuthorizeResult.ALLOW };
    }

    // --- REGLA 5: Todos pueden refrescar entidades ---
    if (request.permission.name === catalogEntityRefreshPermission.name) {
      return { result: AuthorizeResult.ALLOW };
    }

    // --- Por defecto: permitir (fail-open) ---
    // En produccion, considera cambiar a AuthorizeResult.DENY (fail-close)
    return { result: AuthorizeResult.ALLOW };
  }
}

// Registrar la politica como modulo del backend (New Backend System)
export default createBackendModule({
  pluginId: 'permission',
  moduleId: 'permission-policy',
  register(reg) {
    reg.registerInit({
      deps: { policy: policyExtensionPoint },
      async init({ policy }) {
        policy.setPolicy(new WorkshopPermissionPolicy());
      },
    });
  },
});

// Uso en packages/backend/src/index.ts:
//
// import { createBackend } from '@backstage/backend-defaults';
// import permissionPolicy from './plugins/permission-policy';
//
// const backend = createBackend();
// backend.add(import('@backstage/plugin-permission-backend'));
// backend.add(permissionPolicy);
// backend.start();
