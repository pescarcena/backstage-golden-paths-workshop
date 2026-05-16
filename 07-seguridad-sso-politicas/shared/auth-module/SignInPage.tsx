import { SignInPageBlueprint } from '@backstage/plugin-app-react';
import { SignInPage } from '@backstage/core-components';
import { oidcAuthApiRef } from './oidcAuth';

export const oidcSignInPage = SignInPageBlueprint.make({
  params: {
    loader: async () => props => (
      <SignInPage
        {...props}
        provider={{
          id: 'oidc-auth-provider',
          title: 'Keycloak',
          message: 'Sign in with your Keycloak account',
          apiRef: oidcAuthApiRef,
        }}
      />
    ),
  },
});
