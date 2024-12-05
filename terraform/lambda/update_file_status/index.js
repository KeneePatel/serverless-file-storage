const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
  try {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    // Get the uploaded file details from the S3 event
    const record = event.Records[0];
    const key = decodeURIComponent(record.s3.object.key);
    const [userId, fileId] = key.split('/');

    if (!userId || !fileId) {
      throw new Error('Invalid file path structure');
    }

    // Update DynamoDB status
    const params = {
      TableName: process.env.TABLE_NAME,
      Key: {
        userId: userId,
        fileId: fileId
      },
      UpdateExpression: 'SET #status = :status, lastModified = :time',
      ExpressionAttributeNames: {
        '#status': 'status'
      },
      ExpressionAttributeValues: {
        ':status': 'uploaded',
        ':time': new Date().toISOString()
      }
    };

    await dynamodb.update(params).promise();
    console.log('Updated file status to uploaded');
    
    return {
      statusCode: 200,
      body: 'File status updated successfully'
    };
    
  } catch (error) {
    console.error('Error updating file status:', error);
    throw error;
  }
};
