import { Router } from 'itty-router';
import { processAIAnalysis } from './ai-processor';
import { handleWebSocket } from './websocket';
import { handleAuth, validateApiKey } from './auth';

// Export Durable Objects
export { TeslaEventProcessor } from '../durable-objects/TeslaEventProcessor';
export { AlertManager } from '../durable-objects/AlertManager';

const router = Router();

// CORS middleware
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

router.all('*', (request) => {
  if (request.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }
});

// Public endpoints
router.get('/api/health', () => 
  new Response(JSON.stringify({ status: 'healthy', timestamp: new Date().toISOString() }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  })
);

// Device API (for RPi5)
router.post('/api/device/status', validateApiKey, async (request, env) => {
  const data = await request.json();
  
  // Store device status in KV
  await env.DEVICE_STATUS.put(
    `device:${data.device_id}`,
    JSON.stringify({
      ...data.status,
      last_seen: new Date().toISOString()
    }),
    { expirationTtl: 300 } // 5 minutes
  );
  
  return new Response(JSON.stringify({ success: true }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
});

// AI Analysis endpoint
router.post('/api/ai/analyze', validateApiKey, async (request, env) => {
  const data = await request.json();
  
  try {
    // Queue AI processing
    await env.AI_QUEUE.send({
      type: 'analyze_video',
      ...data,
      queued_at: new Date().toISOString()
    });
    
    // Get or create event processor
    const eventId = `${data.timestamp}-${data.camera}`;
    const eventProcessor = env.EVENT_PROCESSOR.get(
      env.EVENT_PROCESSOR.idFromName(eventId)
    );
    
    // Initialize event
    await eventProcessor.fetch(new Request('http://internal/init', {
      method: 'POST',
      body: JSON.stringify(data)
    }));
    
    return new Response(JSON.stringify({ 
      success: true, 
      event_id: eventId,
      message: 'Analysis queued'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('AI analysis error:', error);
    return new Response(JSON.stringify({ error: 'Failed to queue analysis' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Get video events
router.get('/api/events', handleAuth, async (request, env) => {
  const url = new URL(request.url);
  const page = parseInt(url.searchParams.get('page') || '1');
  const limit = parseInt(url.searchParams.get('limit') || '20');
  const eventType = url.searchParams.get('type');
  const startDate = url.searchParams.get('start_date');
  const endDate = url.searchParams.get('end_date');
  
  try {
    let query = `
      SELECT e.*, 
             COUNT(DISTINCT d.id) as detection_count,
             GROUP_CONCAT(DISTINCT d.object_type) as detected_objects
      FROM events e
      LEFT JOIN detections d ON e.id = d.event_id
      WHERE 1=1
    `;
    
    const params = [];
    
    if (eventType) {
      query += ' AND e.event_type = ?';
      params.push(eventType);
    }
    
    if (startDate) {
      query += ' AND e.timestamp >= ?';
      params.push(startDate);
    }
    
    if (endDate) {
      query += ' AND e.timestamp <= ?';
      params.push(endDate);
    }
    
    query += ' GROUP BY e.id ORDER BY e.timestamp DESC LIMIT ? OFFSET ?';
    params.push(limit, (page - 1) * limit);
    
    const result = await env.DB.prepare(query).bind(...params).all();
    
    return new Response(JSON.stringify({
      events: result.results,
      pagination: {
        page,
        limit,
        total: result.meta.total_rows
      }
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Get events error:', error);
    return new Response(JSON.stringify({ error: 'Failed to fetch events' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Get specific event details
router.get('/api/events/:id', handleAuth, async (request, env) => {
  const eventId = request.params.id;
  
  try {
    // Get event details
    const event = await env.DB.prepare(
      'SELECT * FROM events WHERE id = ?'
    ).bind(eventId).first();
    
    if (!event) {
      return new Response(JSON.stringify({ error: 'Event not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Get detections
    const detections = await env.DB.prepare(
      'SELECT * FROM detections WHERE event_id = ? ORDER BY confidence DESC'
    ).bind(eventId).all();
    
    // Get AI analysis results
    const aiResults = await env.DB.prepare(
      'SELECT * FROM ai_analysis WHERE event_id = ?'
    ).bind(eventId).all();
    
    return new Response(JSON.stringify({
      event,
      detections: detections.results,
      ai_analysis: aiResults.results
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Get event error:', error);
    return new Response(JSON.stringify({ error: 'Failed to fetch event' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Real-time updates WebSocket
router.get('/api/ws', handleAuth, (request, env) => {
  return handleWebSocket(request, env);
});

// Get alerts
router.get('/api/alerts', handleAuth, async (request, env) => {
  const url = new URL(request.url);
  const status = url.searchParams.get('status') || 'active';
  
  try {
    const alerts = await env.DB.prepare(
      'SELECT * FROM alerts WHERE status = ? ORDER BY created_at DESC LIMIT 50'
    ).bind(status).all();
    
    return new Response(JSON.stringify({
      alerts: alerts.results
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Get alerts error:', error);
    return new Response(JSON.stringify({ error: 'Failed to fetch alerts' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Analytics endpoint
router.get('/api/analytics', handleAuth, async (request, env) => {
  try {
    const stats = await env.DB.prepare(`
      SELECT 
        COUNT(DISTINCT e.id) as total_events,
        COUNT(DISTINCT CASE WHEN e.event_type = 'sentry' THEN e.id END) as sentry_events,
        COUNT(DISTINCT CASE WHEN e.event_type = 'dashcam' THEN e.id END) as dashcam_events,
        COUNT(DISTINCT d.id) as total_detections,
        COUNT(DISTINCT CASE WHEN d.object_type = 'person' THEN d.id END) as person_detections,
        COUNT(DISTINCT CASE WHEN d.object_type = 'vehicle' THEN d.id END) as vehicle_detections,
        COUNT(DISTINCT CASE WHEN a.severity = 'high' THEN a.id END) as high_severity_alerts
      FROM events e
      LEFT JOIN detections d ON e.id = d.event_id
      LEFT JOIN alerts a ON e.id = a.event_id
      WHERE e.timestamp >= datetime('now', '-30 days')
    `).first();
    
    const dailyEvents = await env.DB.prepare(`
      SELECT 
        DATE(timestamp) as date,
        COUNT(*) as count,
        event_type
      FROM events
      WHERE timestamp >= datetime('now', '-7 days')
      GROUP BY DATE(timestamp), event_type
      ORDER BY date
    `).all();
    
    return new Response(JSON.stringify({
      stats,
      daily_events: dailyEvents.results
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error) {
    console.error('Analytics error:', error);
    return new Response(JSON.stringify({ error: 'Failed to fetch analytics' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// 404 handler
router.all('*', () => 
  new Response('Not Found', { 
    status: 404,
    headers: corsHeaders 
  })
);

export default {
  async fetch(request, env, ctx) {
    return router.handle(request, { env, ctx });
  },
  
  // Queue handler for AI processing
  async queue(batch, env) {
    for (const message of batch.messages) {
      try {
        const job = message.body;
        
        if (job.type === 'analyze_video') {
          await processAIAnalysis(job, env);
        }
        
        message.ack();
      } catch (error) {
        console.error('Queue processing error:', error);
        message.retry();
      }
    }
  }
};
