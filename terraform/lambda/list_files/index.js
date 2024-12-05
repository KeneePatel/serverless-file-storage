const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
  try {
    // Get userId from Cognito authorizer claims
    const userId = event.requestContext.authorizer.claims.sub;

    if (!userId) {
      throw new Error('User ID not found in token');
    }

    const params = {
      TableName: process.env.TABLE_NAME,
      KeyConditionExpression: 'userId = :userId',
      ExpressionAttributeValues: {
        ':userId': userId
      }
    };

    const result = await dynamodb.query(params).promise();

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({
        files: result.Items.map(item => ({
          fileId: item.fileId,
          fileName: item.fileName,
          fileType: item.fileType,
          uploadDate: item.uploadDate,
          status: item.status
        }))
      })
    };
    
  } catch (error) {
    console.error('List files error:', error);
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({ 
        error: 'Failed to list files',
        details: error.message 
      })
    };
  }
};