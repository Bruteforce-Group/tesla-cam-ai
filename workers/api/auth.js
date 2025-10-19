// Authentication middleware

export async function validateApiKey(request) {
  const apiKey = request.headers.get('Authorization');
  
  if (!apiKey || !apiKey.startsWith('Bearer ')) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' }
    });
  }
  
  const token = apiKey.substring(7);
  const { WORKER_API_KEY } = request.env;
  
  if (token !== WORKER_API_KEY) {
    return new Response(JSON.stringify({ error: 'Invalid API key' }), {
      status: 403,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

export async function handleAuth(request) {
  // Simple auth for dashboard access
  const authHeader = request.headers.get('Authorization');
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { 
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      }
    });
  }
  
  // For now, accept any bearer token for dashboard access
  // In production, validate against user database
  return null;
}
