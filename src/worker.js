export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
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
