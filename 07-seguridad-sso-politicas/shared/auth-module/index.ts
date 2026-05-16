import {
  createFrontendModule,
  ApiBlueprint,
} from '@backstage/frontend-plugin-api';
import {
  discoveryApiRef,
  oauthRequestApiRef,
  configApiRef,
} from '@backstage/core-plugin-api';
import { OAuth2 } from '@backstage/core-app-api';
import { oidcSignInPage } from './SignInPage';
import { oidcAuthApiRef } from './oidcAuth';

const oidcAuthApi = ApiBlueprint.make({
  name: 'oidc-auth',
  params: defineParams =>
    defineParams({
      api: oidcAuthApiRef,
      deps: {
        discoveryApi: discoveryApiRef,
        oauthRequestApi: oauthRequestApiRef,
        configApi: configApiRef,
      },
      factory: ({ discoveryApi, oauthRequestApi, configApi }) =>
        OAuth2.create({
          configApi,
          discoveryApi,
          oauthRequestApi,
          provider: {
            id: 'oidc',
            title: 'Keycloak',
            icon: () => null,
          },
          defaultScopes: ['openid', 'profile', 'email'],
        }),
    }),
});

export const authModule = createFrontendModule({
  pluginId: 'app',
  extensions: [oidcSignInPage, oidcAuthApi],
});
