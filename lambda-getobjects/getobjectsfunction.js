const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { GetCommand, DynamoDBDocumentClient } = require("@aws-sdk/lib-dynamodb");

const dClient = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(dClient);

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Credentials": true,
  "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Requested-With",
  "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS"
};

const handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers: corsHeaders,
      body: ''
    };
  }
  try {
    console.log("start event handler");
    console.log("event data: " + JSON.stringify(event));
    
    const rawEmail = event?.pathParameters?.email || event?.email;
    const email = decodeURIComponent(rawEmail);
    
    const tableName = process.env.TABLE_NAME;
    
    if (!tableName) {
      throw new Error("TABLE_NAME environment variable is not set");
    }
    
    if (!email) {
      throw new Error("Email parameter is required");
    }
    
    console.log(`Fetching images for email: ${email} from table: ${tableName}`);
    
    const getCommand = new GetCommand({
      TableName: tableName, 
      Key: { email: email },
    });

    const getResponse = await docClient.send(getCommand);
    const user = getResponse.Item;

    if (!user) {
      return {
        statusCode: 404,
        headers: corsHeaders,
        body: JSON.stringify({
          message: "User not found",
          email: email
        }),
      };
    }
    
    const images = user.images || {};
    console.log("images found", images);
    
    return {
      statusCode: 200,
      headers: corsHeaders,
      body: JSON.stringify({
        email: email,
        images: images
      }),
    };
  } catch (error) {
    console.error("Error fetching images:", error);
    
    return {
      statusCode: 500,
      headers: corsHeaders,
      body: JSON.stringify({
        message: "Error fetching images",
        error: error.message
      }),
    };
  }
};

module.exports = { handler };