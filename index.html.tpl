<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Redirect to Cognito</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      color: #333;
    }

    .container {
      padding: 3rem 2rem;
      text-align: center;
      max-width: 500px;
      width: 90%;
      border: 1px solid rgba(255, 255, 255, 0.2);
    }

    .logo {
      width: 80px;
      height: 80px;
      background: linear-gradient(135deg, #ff6b6b, #ee5a24);
      border-radius: 50%;
      margin: 0 auto 2rem;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 2rem;
      color: white;
      font-weight: bold;
      box-shadow: 0 10px 30px rgba(255, 107, 107, 0.3);
    }

    h1 {
      font-size: 2.5rem;
      font-weight: 700;
      margin-bottom: 1rem;
      background: linear-gradient(135deg, rgb(11, 210, 245), rgb(0, 255, 200));
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
    }

    p {
      font-size: 1.1rem;
      color: #666;
      margin-bottom: 2.5rem;
      line-height: 1.6;
    }

    .login-button {
      background: linear-gradient(135deg, rgb(11, 210, 245) 0%,rgb(0, 255, 200) 100%);
      color: white;
      border: none;
      padding: 1rem 2.5rem;
      font-size: 1.1rem;
      font-weight: 600;
      border-radius: 50px;
      cursor: pointer;
      transition: all 0.3s ease;
      box-shadow: 0 10px 30px rgba(102, 126, 234, 0.3);
      position: relative;
      overflow: hidden;
    }

    .login-button::before {
      content: '';
      position: absolute;
      top: 0;
      left: -100%;
      width: 100%;
      height: 100%;
      background: linear-gradient(135deg, rgba(255, 255, 255, 0.2), transparent);
      transition: left 0.5s ease;
    }

    .login-button:hover::before {
      left: 100%;
    }

    .login-button:hover {
      transform: translateY(-2px);
      box-shadow: 0 15px 40px rgba(102, 126, 234, 0.4);
    }

    .login-button:active {
      transform: translateY(0);
    }

    .security-note {
      margin-top: 2rem;
      padding: 1rem;
      background: rgba(102, 126, 234, 0.1);
      border-radius: 10px;
      border-left: 4px solid rgb(11, 210, 245);
    }

    .security-note p {
      margin: 0;
      font-size: 0.9rem;
      color: #555;
    }

    .features {
      display: flex;
      justify-content: space-around;
      margin-top: 2rem;
      gap: 1rem;
    }

    .feature {
      text-align: center;
      flex: 1;
    }

    .feature-icon {
      width: 40px;
      height: 40px;
      background: linear-gradient(135deg, rgb(11, 210, 245), rgb(0, 255, 200));
      border-radius: 50%;
      margin: 0 auto 0.5rem;
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
      font-weight: bold;
    }

    .feature-text {
      font-size: 0.8rem;
      color: #666;
    }

    @media (max-width: 600px) {
      .container {
        padding: 2rem 1.5rem;
      }
      
      h1 {
        font-size: 2rem;
      }
      
     
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">AM</div>
    <h1>Welcome</h1>
    <p>Access your secure account through AWS Cognito authentication</p>
    
    <button class="login-button" onclick="goToCognito()">
      Sign In Securely
    </button>
    
    
    <div class="security-note">
      <p> Your login is protected by AWS <b>Cognito</b></p>
    </div>
  </div>
  <script>
  function goToCognito() {
    const domain = "${cognito_user_pool_domain}.auth.${aws_region}.amazoncognito.com";
    const clientId = "${cognito_user_pool_client_id}";
    const redirectUri = "https://${website_url}/home.html";
    const responseType = "code";
    const scope = "email openid profile";

    const cognitoUrl = `https://$${domain}/login?client_id=$${clientId}&response_type=$${responseType}&scope=$${encodeURIComponent(scope)}&redirect_uri=$${encodeURIComponent(redirectUri)}`;

    window.location.href = cognitoUrl;
  }
</script>

</body>
</html>
