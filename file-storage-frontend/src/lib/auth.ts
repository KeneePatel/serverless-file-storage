import { CognitoUser, CognitoUserPool, AuthenticationDetails, CognitoUserAttribute } from 'amazon-cognito-identity-js';
import { authConfig } from './auth-config';

const userPool = new CognitoUserPool({
  UserPoolId: authConfig.userPoolId,
  ClientId: authConfig.userPoolClientId
});

interface AuthResponse {
  success: boolean;
  message?: string;
  token?: string;
}

export const signUp = async (email: string, password: string): Promise<AuthResponse> => {
  return new Promise((resolve) => {
    const attributeList = [
      new CognitoUserAttribute({
        Name: 'email',
        Value: email
      })
    ];

    userPool.signUp(email, password, attributeList, [], (err) => {
      if (err) {
        resolve({
          success: false,
          message: err.message
        });
        return;
      }
      resolve({
        success: true,
        message: 'User registered successfully'
      });
    });
  });
};

export const confirmSignUp = async (email: string, code: string): Promise<AuthResponse> => {
  return new Promise((resolve) => {
    const cognitoUser = new CognitoUser({
      Username: email,
      Pool: userPool
    });

    cognitoUser.confirmRegistration(code, true, (err) => {
      if (err) {
        resolve({ success: false, message: err.message });
        return;
      }
      resolve({ success: true, message: 'User confirmed successfully' });
    });
  });
};

export const resendConfirmationCode = async (email: string): Promise<AuthResponse> => {
  return new Promise((resolve) => {
    const cognitoUser = new CognitoUser({
      Username: email,
      Pool: userPool
    });

    cognitoUser.resendConfirmationCode((err) => {
      if (err) {
        resolve({ success: false, message: err.message });
        return;
      }
      resolve({ success: true, message: 'Confirmation code resent successfully' });
    });
  });
};

export const signIn = async (email: string, password: string): Promise<AuthResponse> => {
  return new Promise((resolve) => {
    const authenticationDetails = new AuthenticationDetails({
      Username: email,
      Password: password
    });

    const cognitoUser = new CognitoUser({
      Username: email,
      Pool: userPool
    });

    cognitoUser.setAuthenticationFlowType('USER_PASSWORD_AUTH');

    cognitoUser.authenticateUser(authenticationDetails, {
      onSuccess: (session) => {
        resolve({
          success: true,
          token: session.getIdToken().getJwtToken()
        });
      },
      onFailure: (err) => {
        resolve({
          success: false,
          message: err.message
        });
      }
    });
  });
};

export const signOut = async (): Promise<void> => {
  const currentUser = userPool.getCurrentUser();
  if (currentUser) {
    currentUser.signOut();
  }
  localStorage.removeItem('token');
  localStorage.removeItem('userEmail');
};
