exports.handler = async (event) => {
  const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB
  const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'application/pdf'];
  
  try {
    console.log('Validation event:', JSON.stringify(event, null, 2));

    // Get the input data
    const body = typeof event.body === 'string' ? JSON.parse(event.body) : event;
    const { fileSize, fileType, fileName } = body;
    
    // Get userId from either the authorizer or the input
    const userId = event.requestContext?.authorizer?.claims?.sub || 
                  event.userId || 
                  body.userId;

    if (!userId) {
      throw new Error('User ID is required');
    }

    // Validate file size
    const fileSizeNumber = Number(fileSize);
    if (isNaN(fileSizeNumber)) {
      throw new Error('Invalid file size provided');
    }

    if (fileSizeNumber > MAX_FILE_SIZE) {
      throw new Error(`File size ${fileSizeNumber} bytes exceeds maximum allowed size of ${MAX_FILE_SIZE} bytes`);
    }

    // Validate file type
    if (!fileType || !ALLOWED_TYPES.includes(fileType.toLowerCase())) {
      throw new Error(`Invalid file type. Allowed types: ${ALLOWED_TYPES.join(', ')}`);
    }

    // Return the validated data for next step
    return {
      fileSize: fileSizeNumber,
      fileType: fileType.toLowerCase(),
      fileName: fileName.trim(),
      userId: userId,
      validationPassed: true,
      timestamp: new Date().toISOString()
    };
    
  } catch (error) {
    console.error('Validation error:', error);
    throw error;
  }
};
