export class AlertManager {
  constructor(state, env) {
    this.state = state;
    this.env = env;
    this.websockets = new Map();
    this.activeAlerts = new Map();
  }

  async fetch(request) {
    const url = new URL(request.url);
    
    switch (url.pathname) {
      case '/websocket':
        return this.handleWebSocket(request);
      case '/alert':
        return this.handleNewAlert(request);
      case '/acknowledge':
        return this.handleAcknowledge(request);
      case '/active':
        return this.getActiveAlerts();
      default:
        return new Response('Not Found', { status: 404 });
    }
  }

  async handleWebSocket(request) {
    if (request.headers.get('Upgrade') !== 'websocket') {
      return new Response('Expected WebSocket', { status: 400 });
    }

    const [client, server] = Object.values(new WebSocketPair());
    
    const sessionId = crypto.randomUUID();
    const userId = request.headers.get('X-User-Id');
    
    this.state.acceptWebSocket(server);
    
    // Store WebSocket session
    this.websockets.set(sessionId, {
      websocket: server,
      userId,
      connectedAt: new Date().toISOString()
    });
    
    // Send current alerts
    server.send(JSON.stringify({
      type: 'initial_alerts',
      alerts: Array.from(this.activeAlerts.values())
    }));
    
    server.addEventListener('close', () => {
      this.websockets.delete(sessionId);
    });
    
    server.addEventListener('error', () => {
      this.websockets.delete(sessionId);
    });
    
    return new Response(null, {
      status: 101,
      webSocket: client,
    });
  }

  async handleNewAlert(request) {
    const alert = await request.json();
    
    // Store alert
    this.activeAlerts.set(alert.alertId, {
      ...alert,
      created_at: new Date().toISOString(),
      acknowledged: false
    });
    
    // Save to durable storage
    await this.state.storage.put(`alert:${alert.alertId}`, alert);
    
    // Broadcast to all connected clients
    this.broadcast({
      type: 'new_alert',
      alert
    });
    
    // Send notifications
    await this.sendNotifications(alert);
    
    // Set auto-dismiss timer for low severity alerts
    if (alert.severity === 'low') {
      await this.state.storage.setAlarm(Date.now() + 300000, {
        type: 'auto_dismiss',
        alertId: alert.alertId
      });
    }
    
    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' }
    });
  }

  async handleAcknowledge(request) {
    const { alertId, userId } = await request.json();
    
    const alert = this.activeAlerts.get(alertId);
    if (!alert) {
      return new Response(JSON.stringify({ error: 'Alert not found' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // Update alert
    alert.acknowledged = true;
    alert.acknowledged_by = userId;
    alert.acknowledged_at = new Date().toISOString();
    
    // Update in storage
    await this.state.storage.put(`alert:${alertId}`, alert);
    
    // Update in database
    await this.env.DB.prepare(
      'UPDATE alerts SET status = ?, acknowledged_by = ?, acknowledged_at = ? WHERE id = ?'
    ).bind('acknowledged', userId, alert.acknowledged_at, alertId).run();
    
    // Broadcast update
    this.broadcast({
      type: 'alert_acknowledged',
      alertId,
      acknowledged_by: userId
    });
    
    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' }
    });
  }

  async getActiveAlerts() {
    const alerts = Array.from(this.activeAlerts.values())
      .filter(alert => !alert.acknowledged)
      .sort((a, b) => {
        // Sort by severity then by time
        const severityOrder = { high: 0, medium: 1, low: 2 };
        if (severityOrder[a.severity] !== severityOrder[b.severity]) {
          return severityOrder[a.severity] - severityOrder[b.severity];
        }
        return new Date(b.created_at) - new Date(a.created_at);
      });
    
    return new Response(JSON.stringify({ alerts }), {
      headers: { 'Content-Type': 'application/json' }
    });
  }

  async sendNotifications(alert) {
    // Get notification preferences from database
    const preferences = await this.env.DB.prepare(
      'SELECT * FROM notification_preferences WHERE enabled = 1'
    ).all();
    
    for (const pref of preferences.results) {
      // Check if user wants this type of alert
      const wantedTypes = JSON.parse(pref.alert_types || '[]');
      if (!wantedTypes.includes(alert.type)) continue;
      
      // Check severity threshold
      const severityLevels = { low: 1, medium: 2, high: 3 };
      if (severityLevels[alert.severity] < severityLevels[pref.min_severity || 'low']) continue;
      
      // Send notification based on preference
      switch (pref.channel) {
        case 'email':
          await this.sendEmailNotification(pref, alert);
          break;
        case 'sms':
          await this.sendSMSNotification(pref, alert);
          break;
        case 'push':
          await this.sendPushNotification(pref, alert);
          break;
      }
    }
  }

  async sendEmailNotification(pref, alert) {
    // Integrate with email service (e.g., SendGrid, Mailgun)
    console.log(`Sending email to ${pref.email} about ${alert.type}`);
    
    // Example with Workers Email
    try {
      await fetch('https://api.mailgun.net/v3/yourdomain.com/messages', {
        method: 'POST',
        headers: {
          'Authorization': `Basic ${btoa(`api:${this.env.MAILGUN_API_KEY}`)}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({
          from: 'Tesla Cam AI <alerts@yourdomain.com>',
          to: pref.email,
          subject: `[${alert.severity.toUpperCase()}] ${alert.message}`,
          html: this.generateEmailContent(alert)
        })
      });
    } catch (error) {
      console.error('Email notification error:', error);
    }
  }

  async sendSMSNotification(pref, alert) {
    // Integrate with SMS service (e.g., Twilio)
    console.log(`Sending SMS to ${pref.phone} about ${alert.type}`);
  }

  async sendPushNotification(pref, alert) {
    // Send to user's devices via FCM/APNS
    console.log(`Sending push notification for user ${pref.user_id}`);
  }

  generateEmailContent(alert) {
    return `
      <h2>Tesla Camera Alert</h2>
      <p><strong>Type:</strong> ${alert.type.replace(/_/g, ' ').toUpperCase()}</p>
      <p><strong>Severity:</strong> ${alert.severity.toUpperCase()}</p>
      <p><strong>Message:</strong> ${alert.message}</p>
      <p><strong>Time:</strong> ${new Date(alert.created_at).toLocaleString()}</p>
      <p><strong>Details:</strong> ${JSON.stringify(alert.details, null, 2)}</p>
      <hr>
      <p><a href="https://tesla-cam.yourdomain.com/events/${alert.eventId}">View Event</a></p>
    `;
  }

  broadcast(data) {
    const message = JSON.stringify(data);
    
    for (const [sessionId, session] of this.websockets) {
      try {
        session.websocket.send(message);
      } catch (error) {
        console.error(`Failed to send to session ${sessionId}:`, error);
        this.websockets.delete(sessionId);
      }
    }
  }

  async alarm(scheduled) {
    const { type, alertId } = scheduled;
    
    if (type === 'auto_dismiss') {
      const alert = this.activeAlerts.get(alertId);
      if (alert && !alert.acknowledged) {
        // Auto-dismiss low severity alert
        this.activeAlerts.delete(alertId);
        
        await this.env.DB.prepare(
          'UPDATE alerts SET status = ? WHERE id = ?'
        ).bind('auto_dismissed', alertId).run();
        
        this.broadcast({
          type: 'alert_dismissed',
          alertId,
          reason: 'auto_timeout'
        });
      }
    }
  }
}
