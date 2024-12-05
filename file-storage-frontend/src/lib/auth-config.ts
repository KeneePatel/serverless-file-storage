export const authConfig = {
  region: process.env.NEXT_PUBLIC_REGION || 'us-east-1',
  userPoolId: process.env.NEXT_PUBLIC_USER_POOL_ID || '',
  userPoolClientId: process.env.NEXT_PUBLIC_USER_POOL_CLIENT_ID || '',
  apiUrl: process.env.NEXT_PUBLIC_API_URL || ''
};

// Validation
if (!authConfig.userPoolId || !authConfig.userPoolClientId) {
  console.warn('Missing required AWS Cognito configuration');
}
