const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const dynamodb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
  try {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    // Get fileId from path parameters
    const fileId = event.pathParameters.fileId;
    // Get userId from Cognito claims
    const userId = event.requestContext.authorizer.claims.sub;

    if (!fileId || !userId) {
      throw new Error('Missing required parameters');
    }

    // Verify file exists in DynamoDB
    const dbParams = {
      TableName: process.env.TABLE_NAME,
      Key: {
        userId: userId,
        fileId: fileId
      }
    };

    console.log('DynamoDB Params:', dbParams);
    const result = await dynamodb.get(dbParams).promise();
    
    if (!result.Item) {
      return {
        statusCode: 404,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        body: JSON.stringify({ error: 'File not found' })
      };
    }

    // Generate pre-signed URL for download
    const s3Params = {
      Bucket: process.env.BUCKET_NAME,
      Key: `${userId}/${fileId}`,
      Expires: 3600 // URL expires in 1 hour
    };

    const downloadUrl = await s3.getSignedUrl('getObject', s3Params);

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({
        downloadUrl,
        fileName: result.Item.fileName,
        fileType: result.Item.fileType
      })
    };
    
  } catch (error) {
    console.error('Download error:', error);
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({ 
        error: 'Failed to generate download URL',
        details: error.message
      })
    };
  }
};
