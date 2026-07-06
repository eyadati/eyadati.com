import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')
const SUPABASE_SECRET_KEYS = JSON.parse(Deno.env.get('SUPABASE_SECRET_KEYS') || '{}')
const SECRET_KEY = SUPABASE_SECRET_KEYS['default'] || ''
const FIREBASE_SERVICE_ACCOUNT = (() => {
  try {
    return JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') || '{}')
  } catch {
    return {}
  }
})()

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, content-type, x-client-info, apikey',
}

function pemToBinary(pem: string): Uint8Array {
  const b64 = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\n/g, '')
    .replace(/\r/g, '')
  const binary = atob(b64)
  const bytes = new Uint8Array(binary.length)
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i)
  }
  return bytes
}

function base64url(src: Uint8Array): string {
  return btoa(String.fromCharCode(...src))
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
}

async function getFcmAccessToken(): Promise<string | null> {
  const sa = FIREBASE_SERVICE_ACCOUNT
  if (!sa.private_key || !sa.client_email || !sa.token_uri) return null

  const header = { alg: 'RS256', typ: 'JWT' }
  const now = Math.floor(Date.now() / 1000)
  const payload = {
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: sa.token_uri,
    exp: now + 3600,
    iat: now,
  }

  const encoder = new TextEncoder()
  const headerB64 = base64url(encoder.encode(JSON.stringify(header)))
  const payloadB64 = base64url(encoder.encode(JSON.stringify(payload)))
  const signingInput = `${headerB64}.${payloadB64}`

  const keyData = pemToBinary(sa.private_key)
  const key = await crypto.subtle.importKey(
    'pkcs8',
    keyData,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    encoder.encode(signingInput),
  )

  const jwt = `${signingInput}.${base64url(new Uint8Array(signature))}`

  const response = await fetch(sa.token_uri, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })

  const data = await response.json()
  return data.access_token || null
}

async function sendFcmReminder(
  accessToken: string,
  token: string,
  doctorName: string,
  appointmentTime: string,
  projectId: string,
): Promise<boolean> {
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          data: {
            type: 'appointment_reminder',
          },
          notification: {
            title: 'Rappel de rendez-vous',
            body: `Vous avez rendez-vous avec Dr. ${doctorName} à ${appointmentTime}`,
          },
          webpush: {
            notification: {
              title: 'Rappel de rendez-vous',
              body: `Vous avez rendez-vous avec Dr. ${doctorName} à ${appointmentTime}`,
              icon: '/icons/Icon-192.png',
            },
          },
        },
      }),
    },
  )
  return response.ok
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

  if (!SUPABASE_URL || !SECRET_KEY) {
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

  const bearerToken = authHeader.replace('Bearer ', '')

  let appointmentId: string

  try {
    const body = await req.json()
    appointmentId = body.appointment_id
    if (!appointmentId) {
      return new Response(JSON.stringify({ error: 'appointment_id is required' }), {
        status: 400,
        headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
      })
    }
  } catch (e) {
    return new Response(JSON.stringify({ error: 'Invalid request' }), {
      status: 400,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    })
  }

  try {
    const supabase = createClient(SUPABASE_URL, SECRET_KEY)

    const { data: appointment, error: aptError } = await supabase
      .from('appointments')
      .select(`
        id, scheduled_at, patient_id,
        doctor:doctors!doctor_id (
          id,
          profile:profiles!doctor_id ( full_name )
        )
      `)
      .eq('id', appointmentId)
      .single()

    if (aptError || !appointment) {
      return new Response(JSON.stringify({ error: 'Appointment not found' }), {
        status: 404,
        headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
      })
    }

    const patientId = appointment.patient_id as string
    const doctorProfile = (appointment.doctor as any)?.profile
    const doctorName = doctorProfile?.full_name || 'Médecin'

    const scheduledAt = new Date(appointment.scheduled_at as string)
    const hours = scheduledAt.getHours().toString().padStart(2, '0')
    const minutes = scheduledAt.getMinutes().toString().padStart(2, '0')
    const day = scheduledAt.getDate().toString().padStart(2, '0')
    const month = (scheduledAt.getMonth() + 1).toString().padStart(2, '0')
    const timeFormatted = `${hours}:${minutes}`
    const dateFormatted = `${day}/${month}`

    const { data: tokens, error: tokensError } = await supabase
      .from('push_tokens')
      .select('token')
      .eq('user_id', patientId)

    if (tokensError) throw tokensError
    if (!tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ sent: 0, message: 'No push tokens found' }), {
        status: 200,
        headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
      })
    }

    const accessToken = await getFcmAccessToken()
    if (!accessToken) {
      return new Response(JSON.stringify({ error: 'Failed to get FCM access token' }), {
        status: 500,
        headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
      })
    }

    const notificationBody = `Rappel: Dr. ${doctorName} à ${timeFormatted} le ${dateFormatted}`

    const results = await Promise.all(
      tokens.map((t) =>
        sendFcmReminder(
          accessToken,
          t.token,
          doctorName,
          `${timeFormatted} le ${dateFormatted}`,
          FIREBASE_SERVICE_ACCOUNT.project_id || 'eydati-fcd79',
        )
          .then((ok) => ok ? 'sent' : 'failed')
          .catch(() => 'failed'),
      ),
    )

    const sent = results.filter((r) => r === 'sent').length
    const failed = results.filter((r) => r === 'failed').length

    await supabase
      .from('appointments')
      .update({ fcm_reminder_sent: true })
      .eq('id', appointmentId)

    console.log(`Appointment reminder: ${sent} sent, ${failed} failed for appointment ${appointmentId}`)

    return new Response(JSON.stringify({ sent, failed }), {
      status: 200,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('Send reminder error:', error.message)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    })
  }
})
