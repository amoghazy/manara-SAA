const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const {
  UpdateCommand,
  GetCommand,

  DynamoDBDocumentClient,
} = require("@aws-sdk/lib-dynamodb");

const dClient = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(dClient);
const s3Client = new S3Client({});

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Credentials": true,
  "Access-Control-Allow-Headers":
    "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Requested-With",
  "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
  "Access-Control-Max-Age": "86400",
};

const createResponse = (statusCode, body, additionalHeaders = {}) => {
  return {
    statusCode,
    headers: {
      ...corsHeaders,
      ...additionalHeaders,
    },
    body: typeof body === "string" ? body : JSON.stringify(body),
  };
};

const handler = async (event) => {
  console.log("Event received:", JSON.stringify(event, null, 2));

  // Handle CORS preflight - this is crucial
  if (
    event.httpMethod === "OPTIONS" ||
    event.requestContext?.http?.method === "OPTIONS"
  ) {
    console.log("Handling CORS preflight request");
    return createResponse(200, "");
  }

  console.log("Processing main request");

  try {
    // Handle both direct invocation and API Gateway
    let body;
    if (typeof event.body === "string") {
      body = JSON.parse(event.body);
    } else {
      body = event.body || event;
    }

    const email = body.email;
    const filename = body.filename;
    const base64Image = body.image;

    console.log("Processing upload for:", {
      email,
      filename,
      imageSize: base64Image?.length,
    });

    if (!email || !filename || !base64Image) {
      return createResponse(400, {
        message: "Email, filename, and image must be provided",
      });
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return createResponse(400, {
        message: "Invalid email format",
      });
    }

    // Validate filename and extract extension
    const fileExtension = filename.split(".").pop()?.toLowerCase();
    const allowedExtensions = ["jpg", "jpeg", "png", "gif", "webp"];

    if (!fileExtension || !allowedExtensions.includes(fileExtension)) {
      return createResponse(400, {
        message: `Invalid file type. Allowed: ${allowedExtensions.join(", ")}`,
      });
    }

    // Convert base64 to buffer
    let imageBuffer;
    try {
      // Remove data URL prefix if present (data:image/jpeg;base64,...)
      const base64Data = base64Image.replace(/^data:image\/[a-z]+;base64,/, "");
      imageBuffer = Buffer.from(base64Data, "base64");
    } catch (bufferError) {
      console.error("Base64 conversion error:", bufferError);
      return createResponse(400, {
        message: "Invalid base64 image data",
      });
    }

    const sourceBucket = process.env.SOURCE_BUCKET;
    const destinationBucket = process.env.DESTINATION_BUCKET;
    const tableName = process.env.TABLE_NAME;

    if (!sourceBucket || !destinationBucket || !tableName) {
      console.error("Missing environment variables:", {
        sourceBucket,
        destinationBucket,
        tableName,
      });
      return createResponse(500, {
        message: "Server configuration error",
      });
    }

    // Create unique key with timestamp to avoid collisions
    const timestamp = Date.now();
    const key = `${email}-${timestamp}-${filename}`;

    console.log("Uploading to S3:", { bucket: sourceBucket, key });
    // get existing user
    const getCommand = new GetCommand({
      TableName: tableName,
      Key: { email: email },
    });
    const getResponse = await docClient.send(getCommand);
    const existingItem = getResponse.Item || {};

    // upload to S3
    const putObjectCommand = new PutObjectCommand({
      Bucket: sourceBucket,
      Key: key,
      Body: imageBuffer,
      ContentType: `image/${fileExtension}`,
      Metadata: {
        "original-filename": filename,
        "user-email": email,
        "upload-timestamp": timestamp.toString(),
      },
    });
    await s3Client.send(putObjectCommand);
    console.log("S3 upload successful");

    // build imageUrl
    const keyName = `resized-${key.replace("@", "%40")}`;
    const imageUrl = `https://${destinationBucket}.s3.amazonaws.com/${keyName}`;

    // update images object
    const currentImages = existingItem.images || {};
    currentImages[filename] = imageUrl;

    // update DynamoDB
    const updateCommand = new UpdateCommand({
      TableName: tableName,
      Key: { email: email },
      UpdateExpression: `
    SET images = :images,
        updatedAt = :timestamp
  `,
      ExpressionAttributeValues: {
        ":images": currentImages,
        ":timestamp": new Date().toISOString(),
      },
      ReturnValues: "ALL_NEW",
    });
    const result = await docClient.send(updateCommand);
    console.log("DynamoDB update successful:", result.Attributes);

    return createResponse(200, {
      message: "Image uploaded successfully",
      imageUrl: imageUrl,
      s3Key: key,
      email: email,
      filename: filename,
    });
  } catch (error) {
    console.error("Error uploading image:", error);
    console.error("Error stack:", error.stack);

    return createResponse(500, {
      message: "Error uploading image",
      error: error.message,
      ...(process.env.NODE_ENV === "development" && { stack: error.stack }),
    });
  }
};

module.exports = { handler };
