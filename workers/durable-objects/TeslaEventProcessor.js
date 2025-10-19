export class TeslaEventProcessor {
  constructor(state, env) {
    this.state = state;
    this.env = env;
    this.event = null;
  }

  async fetch(request) {
    const url = new URL(request.url);
    
    switch (url.pathname) {
      case '/init':
        return this.handleInit(request);
      case '/complete':
        return this.handleComplete(request);
      case '/status':
        return this.getStatus();
      default:
        return new Response('Not Found', { status: 404 });
    }
  }

  async handleInit(request) {
    const data = await request.json();
    
    this.event = {
      ...data,
      status: 'processing',
      started_at: new Date().toISOString()
    };
    
    await this.state.storage.put('event', this.event);
    
    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' }
    });
  }

  async handleComplete(request) {
    const { results } = await request.json();
    
    if (this.event) {
      this.event.status = 'completed';
      this.event.completed_at = new Date().toISOString();
      this.event.results = results;
      
      await this.state.storage.put('event', this.event);
    }
    
    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' }
    });
  }

  async getStatus() {
    const event = await this.state.storage.get('event') || this.event;
    
    return new Response(JSON.stringify({ event }), {
      headers: { 'Content-Type': 'application/json' }
    });
  }
}
