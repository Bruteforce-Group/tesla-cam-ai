// WebSocket handler for real-time updates

export function handleWebSocket(request, env) {
  const upgradeHeader = request.headers.get('Upgrade');
  
  if (!upgradeHeader || upgradeHeader !== 'websocket') {
    return new Response('Expected Upgrade: websocket', { status: 426 });
  }

  const [client, server] = Object.values(new WebSocketPair());

  // Get alert manager instance
  const alertManager = env.ALERT_MANAGER.get(
    env.ALERT_MANAGER.idFromName('global')
  );

  // Forward the WebSocket to the alert manager
  return alertManager.fetch(new Request('http://internal/websocket', {
    headers: {
      'Upgrade': 'websocket',
      'X-User-Id': request.headers.get('X-User-Id') || 'anonymous',
    }
  })).then(response => {
    return new Response(null, {
      status: 101,
      webSocket: client,
    });
  }).catch(error => {
    return new Response('WebSocket connection failed', { status: 500 });
  });
}
