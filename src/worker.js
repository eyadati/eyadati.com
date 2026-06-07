export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // SMS Hook endpoint for Supabase Send SMS Hook
    if (url.pathname === '/api/sms-hook' && request.method === 'POST') {
      return handleSmsHook(request, env);
    }

    const response = await env.ASSETS.fetch(request);

    if (response.status === 404) {
      const index = await env.ASSETS.fetch(`${url.origin}/index.html`);
      return new Response(index.body, {
        status: 200,
        headers: {
          'content-type': 'text/html; charset=utf-8',
          'cache-control': 'no-cache, no-store, must-revalidate',
        },
      });
    }

    const path = url.pathname;
    if (path === '/' || path === '/index.html') {
      const text = await response.text();
      return new Response(text, {
        status: 200,
        headers: {
          'content-type': 'text/html; charset=utf-8',
          'cache-control': 'no-cache, no-store, must-revalidate',
        },
      });
    }

    if (/\.(js|wasm|png|css|ttf|otf|bin|json|svg|ico)$/i.test(path)) {
      return new Response(response.body, {
        status: response.status,
        headers: {
          ...Object.fromEntries(response.headers),
          'cache-control': 'public, max-age=31536000, immutable',
        },
      });
    }

    return response;
  }
};

async function handleSmsHook(request, env) {
  // Verify hook secret
  const authHeader = request.headers.get('Authorization') || '';
  const expectedToken = env.SMS_HOOK_SECRET;
  if (expectedToken && authHeader !== `Bearer ${expectedToken}`) {
    return new Response('Unauthorized', { status: 401 });
  }

  let body;
  try {
    body = await request.json();
  } catch {
    return new Response('Invalid JSON', { status: 400 });
  }

  const phone = body?.user?.phone;
  const otp = body?.sms?.otp;

  if (!phone || !otp) {
    return new Response('Missing phone or otp', { status: 400 });
  }

  const username = env.BUDGETSMS_USERNAME;
  const userid = env.BUDGETSMS_USERID;
  const handle = env.BUDGETSMS_HANDLE;

  if (!username || !userid || !handle) {
    console.error('Missing BudgetSMS credentials');
    return new Response('Server configuration error', { status: 500 });
  }

  const message = `Votre code Eyadati : ${otp}`;
  const smsUrl = `https://api.budgetsms.net/sendsms/?username=${encodeURIComponent(username)}&userid=${encodeURIComponent(userid)}&handle=${encodeURIComponent(handle)}&msg=${encodeURIComponent(message)}&from=${encodeURIComponent('Eyadati')}&to=${encodeURIComponent(phone)}`;

  try {
    const smsResponse = await fetch(smsUrl);
    const text = await smsResponse.text();

    if (!smsResponse.ok) {
      console.error('BudgetSMS error:', text);
      return new Response('SMS send failed', { status: 502 });
    }

    return new Response('{}', {
      status: 200,
      headers: { 'content-type': 'application/json' },
    });
  } catch (err) {
    console.error('BudgetSMS fetch error:', err);
    return new Response('SMS send error', { status: 502 });
  }
}
