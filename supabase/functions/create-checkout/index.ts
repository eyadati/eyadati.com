import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

const CHARGILY_SECRET_KEY = Deno.env.get('CHARGILY_SECRET_KEY')
const CHARGILY_MODE = Deno.env.get('CHARGILY_MODE') || 'test'
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')
const SUPABASE_SECRET_KEYS = JSON.parse(Deno.env.get('SUPABASE_SECRET_KEYS') || '{}')
const SECRET_KEY = SUPABASE_SECRET_KEYS['default'] || ''

const CHARGILY_BASE_URL = CHARGILY_MODE === 'live'
  ? 'https://pay.chargily.net/api/v2'
  : 'https://pay.chargily.net/test/api/v2'

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, content-type, x-client-info, apikey',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: CORS_HEADERS })
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    })
  }

  if (!CHARGILY_SECRET_KEY || !SUPABASE_URL || !SECRET_KEY) {
    console.error('Missing required environment variables')
    return new Response(JSON.stringify({ error: 'Server configuration error' }), {
      status: 500,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    })
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    })
  }

  const token = authHeader.replace('Bearer ', '')

  let doctorId: string
  let successUrl: string
  let failureUrl: string

  try {
    const supabase = createClient(SUPABASE_URL, SECRET_KEY, {
      global: { headers: { Authorization: `Bearer ${token}` } },
    })

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(token)

    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Invalid token' }), {
        status: 401,
        headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
      })
    }

    doctorId = user.id

    const body = await req.json()
    const origin = req.headers.get('Origin') || 'https://eyadati.eyadati-dz.workers.dev'
    successUrl = body.success_url || `${origin}/payment/success`
    failureUrl = body.failure_url || `${origin}/payment/failure`
  } catch (e) {
    console.error('Request parsing error:', e.message)
    return new Response(JSON.stringify({ error: 'Invalid request body' }), {
      status: 400,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    })
  }

  try {
    const checkoutBody = {
      amount: 6000,
      currency: 'dzd',
      success_url: successUrl,
      failure_url: failureUrl,
      webhook_endpoint: `${SUPABASE_URL}/functions/v1/chargily-webhook`,
      metadata: { doctor_id: doctorId },
      locale: 'fr',
      description: 'Abonnement mensuel Eyadati - Plan Pro',
    }

    console.log('Creating Chargily checkout for doctor:', doctorId)

    const response = await fetch(`${CHARGILY_BASE_URL}/checkouts`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${CHARGILY_SECRET_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(checkoutBody),
    })

    if (!response.ok) {
      const errorText = await response.text()
      console.error('Chargily API error:', errorText)
      return new Response(
        JSON.stringify({ error: 'Failed to create checkout', details: errorText }),
        { status: response.status, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } }
      )
    }

    const checkout = await response.json()

    console.log('Checkout created:', checkout.id)

    return new Response(
      JSON.stringify({
        checkout_url: checkout.checkout_url,
        checkout_id: checkout.id,
      }),
      {
        status: 200,
        headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
      }
    )
  } catch (error) {
    console.error('Checkout creation error:', error.message)
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: error.message }),
      { status: 500, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } }
    )
  }
})
