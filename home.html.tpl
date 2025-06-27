<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RESIZE APP</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>

<body class="bg-gray-100 min-h-screen p-8">

    <div class="min-h-screen z-[100] flex-col flex hidden loader fixed top-0 left-0 right-0 justify-center items-center bg-black/70">
        <div class="w-28 h-28 border-8 text-blue-400 text-4xl animate-spin border-gray-300 flex items-center justify-center border-t-blue-400 rounded-full">
        </div>
        <span class="text-4xl font-semibold text-blue-400 my-3">Processing...</span>
    </div>

    <div class="max-w-4xl mx-auto bg-white rounded-lg shadow-md p-6 box-user">
        <h1 class="text-3xl font-bold mb-6 text-center">Image Upload and Gallery
            <p onclick="logout()" class="text-red-500 hover:underline w-fit ml-auto inline-block cursor-pointer" id="logout">
                logout
            </p>
        </h1>
        <h3 id="email" class="text-2xl font-bold mb-6 ml-auto text-center text-cyan-500"></h3>

        <div class="mb-8">
            <h2 class="text-2xl font-semibold mb-4">Upload New Image</h2>
            <form class="flex items-center space-x-4">
                <input type="file" accept="image/*" id="file" class="block w-full text-sm text-gray-500
                    file:mr-4 file:py-2 file:px-4
                    file:rounded-full file:border-0
                    file:text-sm file:font-semibold
                    file:bg-blue-50 file:text-blue-700
                    hover:file:bg-blue-100
                ">
                <button type="submit" class="bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded">
                    Upload
                </button>
            </form>
        </div>

        <div>
            <h2 class="text-2xl font-semibold mb-4">Image Gallery</h2>
            <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4 images-container">
            </div>
        </div>
    </div>

<script>
    const WEBSITE_URL = "${WEBSITE_URL}";
    const API_URL = "${API_URL}";
    const COGNITO_CLIENT_ID = "${COGNITO_USER_POOL_CLIENT_ID}";
    const COGNITO_DOMAIN = "${COGNITO_USER_POOL_DOMAIN}";
    const AWS_REGION = "${AWS_REGION}";
    
    // Global variables
    let currentUserEmail = null;
    const loader = document.querySelector('.loader');
    const emailDisplay = document.getElementById('email');
    
    // URL parameters for OAuth
    const urlParams = new URLSearchParams(window.location.search);
    const code = urlParams.get("code");

    // Main initialization function
    async function main() {
        loader.classList.remove('hidden');
        
        try {
            if (code) {
                // Handle OAuth callback
                const tokens = await exchangeCodeForToken(code);
                localStorage.setItem("id_token", tokens.id_token);
                const user = parseJwt(tokens.id_token);
                await showUser(user);
            } else {
                // Check for existing token
                const token = localStorage.getItem("id_token");
                if (token) {
                    const user = parseJwt(token);
                    await showUser(user);
                } else {
                    document.querySelector('.box-user').classList.add('blur-lg');
                    redirectToLogin();
                    return;
                }
            }
            
            // Load images after user is authenticated
            await getImages();
            
        } catch (error) {
            console.error('Initialization error:', error);
            redirectToLogin();
        } finally {
            loader.classList.add('hidden');
        }
    }

    // OAuth functions
    function redirectToLogin() {
        const loginUrl = `https://${WEBSITE_URL}/`;
        window.location.href = loginUrl;
    }

    async function exchangeCodeForToken(code) {
        const redirectUri = `https://${WEBSITE_URL}/home.html`;
        const tokenUrl = `https://$${COGNITO_DOMAIN}.auth.${AWS_REGION}.amazoncognito.com/oauth2/token`;

        const body = new URLSearchParams({
            grant_type: "authorization_code",
            client_id: COGNITO_CLIENT_ID,
            code: code,
            redirect_uri: redirectUri
        });

        const response = await fetch(tokenUrl, {
            method: "POST",
            headers: {
                "Content-Type": "application/x-www-form-urlencoded"
            },
            body: body.toString()
        });

        if (!response.ok) {
            throw new Error('Token exchange failed');
        }

        return await response.json();
    }

    function parseJwt(token) {
        const base64Url = token.split('.')[1];
        const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
        const jsonPayload = decodeURIComponent(atob(base64).split('').map(function(c) {
            return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
        }).join(''));
        return JSON.parse(jsonPayload);
    }

    async function showUser(user) {
        currentUserEmail = user.email;
        emailDisplay.textContent = currentUserEmail;
        // Store email for consistency
        localStorage.setItem('email', currentUserEmail);
    }

    // Image upload functionality
    const form = document.querySelector('form');
    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        if (!currentUserEmail) {
            alert('Please log in first');
            return;
        }
        
        const file = document.getElementById('file').files[0];
        if (!file) {
            alert('Please select a file');
            return;
        }

        const reader = new FileReader();
        reader.onloadend = async () => {
            const base64Image = reader.result.split(',')[1];
            try {
                console.log('Uploading image...');
                loader.classList.remove('hidden');
                
                const response = await fetch(`${API_URL}/upload`, {
                    method: 'POST',
                    body: JSON.stringify({
                        email: currentUserEmail,
                        filename: file.name,
                        image: base64Image
                    }),
                    headers: {
                        'Content-Type': "application/json",
                    }
                });

                if (!response.ok) {
                    console.log(response);
                    const errorData = await response.text();
                    throw new Error(`Upload failed: $${response.status} - $${errorData}`);
                }

                const responseData = await response.json();
                console.log('Upload successful:', responseData);
                
                // Clear the file input
                document.getElementById('file').value = '';
                
                // Reload images after successful upload
                setTimeout(async () => {
                    await getImages();
                    loader.classList.add('hidden');
                }, 2000);
                
            } catch (error) {
                console.error('Error uploading image:', error);
                alert('Upload failed: ' + error.message);
                loader.classList.add('hidden');
            }
        };
        reader.readAsDataURL(file);
    });

    // Get and display images
    async function getImages() {
        if (!currentUserEmail) return;
        
        const imagesContainer = document.querySelector('.images-container');
        imagesContainer.innerHTML = ''; // Clear existing images
        
        try {
            const response = await fetch(`${API_URL}/getobjects/$${encodeURIComponent(currentUserEmail)}`);
            
            if (!response.ok) {
                if (response.status === 404) {
                    imagesContainer.innerHTML = '<p class="text-gray-500 col-span-full text-center">No images found. Upload your first image!</p>';
                    return;
                }
                throw new Error(`Failed to fetch images: $${response.status}`);
            }
            
            const data = await response.json();
            console.log('Images data:', data);
            
            // Handle the response structure from your Lambda function
            const images = data.images || data;
            
            if (Object.keys(images).length === 0) {
                imagesContainer.innerHTML = '<p class="text-gray-500 col-span-full text-center">No images found. Upload your first image!</p>';
                return;
            }
            
            for (const [filename, imageUrl] of Object.entries(images)) {
                const imageElement = document.createElement('div');
                imageElement.innerHTML = `
                    <div class="relative group">
                        <img src="$${imageUrl}" alt="$${filename}" class="w-full h-48 object-cover rounded-lg" 
                             onerror="this.parentElement.innerHTML='<div class=\\'w-full h-48 bg-gray-200 rounded-lg flex items-center justify-center\\'>Image not available</div>'">
                        <div class="absolute inset-0 bg-black bg-opacity-50 opacity-0 group-hover:opacity-100 transition-opacity duration-300 flex items-center justify-center rounded-lg">
                            <a href="$${imageUrl}" download="$${filename}" class="bg-cyan-500 hover:bg-cyan-600 text-white font-bold py-2 px-4 rounded mr-2">
                                Download
                            </a>
                        </div>
                        <div class="absolute bottom-2 left-2 bg-black bg-opacity-70 text-white text-xs px-2 py-1 rounded">
                            $${filename}
                        </div>
                    </div>
                `;
                imagesContainer.appendChild(imageElement);
            }
            
        } catch (error) {
            console.error('Error fetching images:', error);
            imagesContainer.innerHTML = '<p class="text-red-500 col-span-full text-center">Error loading images. Please try again.</p>';
        }
    }

    // Logout function
    function logout() {
        localStorage.removeItem("id_token");
        localStorage.removeItem("email");
        redirectToLogin();
    }

    // Initialize the app
    main();
</script>

</body>
</html>