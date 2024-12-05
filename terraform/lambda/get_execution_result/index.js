const AWS = require('aws-sdk');
const stepfunctions = new AWS.StepFunctions();

exports.handler = async (event) => {
  try {
    // Get the execution ARN from the event
    const { executionArn } = event.pathParameters;

    // Get the execution result
    const params = {
      executionArn: executionArn
    };

    const execution = await stepfunctions.describeExecution(params).promise();
    
    if (execution.status === 'RUNNING') {
      return {
        statusCode: 202,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        body: JSON.stringify({
          status: 'running',
          message: 'Execution still in progress'
        })
      };
    }

    if (execution.status === 'SUCCEEDED') {
      const output = JSON.parse(execution.output);
      return {
        statusCode: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        body: JSON.stringify({
          status: 'success',
          uploadUrl: output.uploadResult.uploadUrl,
          fileId: output.uploadResult.fileId,
          fileName: output.uploadResult.fileName
        })
      };
    }

    return {
      statusCode: 400,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({
        status: 'failed',
        message: `Execution failed with status: ${execution.status}`
      })
    };
    
  } catch (error) {
    console.error('Error getting execution result:', error);
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({
        status: 'error',
        message: error.message
      })
    };
  }
};
