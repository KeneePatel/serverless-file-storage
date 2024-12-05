const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const dynamodb = new AWS.DynamoDB.DocumentClient();
const crypto = require('crypto');

exports.handler = async (event) => {
  try {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    const { fileName, fileType, userId } = event;
    const fileId = crypto.randomUUID();
    const timestamp = new Date().toISOString();

    // Generate pre-signed URL for upload
    const s3Params = {
      Bucket: process.env.BUCKET_NAME,
      Key: `${userId}/${fileId}`,
      ContentType: fileType,
      Expires: 3600
    };

    const uploadUrl = await s3.getSignedUrl('putObject', s3Params);

    // Store file metadata in DynamoDB
    const dbParams = {
      TableName: process.env.TABLE_NAME,
      Item: {
        userId: userId,
        fileId: fileId,
        fileName: fileName,
        fileType: fileType,
        uploadDate: timestamp,
        status: 'pending'
      }
    };

    await dynamodb.put(dbParams).promise();

    // Return directly without wrapping in statusCode/body
    return {
      uploadUrl: uploadUrl,
      fileId: fileId,
      fileName: fileName
    };
    
  } catch (error) {
    console.error('Upload preparation error:', error);
    throw error;
  }
};
