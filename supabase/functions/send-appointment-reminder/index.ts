import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
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

function formatDateForBody(d: Date): string {
  const hours = d.getHours().toString().padStart(2, '0')
  const minutes = d.getMinutes().toString().padStart(2, '0')
  const day = d.getDate().toString().padStart(2, '0')
  const month = (d.getMonth() + 1).toString().padStart(2, '0')
  return `Rendez-vous le ${day}/${month} \u00e0 ${hours}:${minutes}`
}

async function sendFcmNotification(
  accessToken: string,
  pushToken: string,
  title: string,
  body: string,
  projectId: string,
): Promise<'sent' | 'token_deleted' | 'failed'> {
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
          token: pushToken,
          data: { type: 'appointment_reminder' },
          notification: { title, body },
          webpush: {
            notification: { title, body, icon: '/icons/Icon-192.png' },
          },
        },
      }),
    },
  )

  if (response.status === 404) {
    return 'token_deleted'
  }

  return response.ok ? 'sent' : 'failed'
}

function calculateReminderAt(scheduledAt: Date, now: Date): Date | null {
  const deltaMs = scheduledAt.getTime() - now.getTime()
  if (deltaMs <= 0) return null

  const deltaHours = deltaMs / (1000 * 60 * 60)

  if (deltaHours > 6) {
    return new Date(scheduledAt.getTime() - 6 * 60 * 60 * 1000)
  }

  if (deltaHours > 2) {
    return new Date(scheduledAt.getTime() - 2 * 60 * 60 * 1000)
  }

  return now
}

async function processReminder(
  supabase: ReturnType<typeof createClient>,
  appointment: Record<string, unknown>,
  accessToken: string,
  projectId: string,
) {
  const appointmentId = appointment.id as string
  const patientId = appointment.patient_id as string
  const doctorData = appointment.doctor as Record<string, unknown> | undefined
  const profile = doctorData?.profile as Record<string, unknown> | undefined
  const doctorName = (profile?.full_name as string) || 'M\u00e9decin'

  const scheduledAt = new Date(appointment.scheduled_at as string)
  const title = `Dr. ${doctorName}`
  const body = formatDateForBody(scheduledAt)

  const { data: tokens } = await supabase
    .from('push_tokens')
    .select('token, id')
    .eq('user_id', patientId)

  if (!tokens || tokens.length === 0) {
    await supabase
      .from('appointments')
      .update({ reminder_sent: true })
      .eq('id', appointmentId)
    return { appointmentId, sent: 0, failed: 0, reason: 'no_tokens' }
  }

  let sent = 0
  let failed = 0

  for (const t of tokens) {
    const result = await sendFcmNotification(
      accessToken, t.token as string, title, body, projectId,
    )
    if (result === 'sent') sent++
    else if (result === 'token_deleted') {
      await supabase.from('push_tokens').delete().eq('id', t.id)
    } else failed++
  }

  await supabase
    .from('appointments')
    .update({ reminder_sent: true })
    .eq('id', appointmentId)

  return { appointmentId, sent, failed }
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

  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
    return new Response(JSON.stringify({ error: 'Server configuration error' }), {
      status: 500,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    })
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  const body = await req.json().catch(() => ({}))
  const appointmentId = body.appointment_id as string | undefined

  const accessToken = await getFcmAccessToken()
  if (!accessToken) {
    return new Response(JSON.stringify({ error: 'Failed to get FCM access token' }), {
      status: 500,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    })
  }

  const projectId = FIREBASE_SERVICE_ACCOUNT.project_id || 'eydati-fcd79'

  try {
    if (appointmentId) {
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

      const scheduledAt = new Date(appointment.scheduled_at as string)
      const now = new Date()
      const reminderAt = calculateReminderAt(scheduledAt, now)

      if (reminderAt) {
        await supabase
          .from('appointments')
          .update({ reminder_at: reminderAt.toISOString() })
          .eq('id', appointmentId)
      }

      return new Response(JSON.stringify({ appointmentId, reminder_at: reminderAt?.toISOString() ?? null }), {
        status: 200,
        headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
      })
    }

    const { data: appointments, error: fetchError } = await supabase
      .from('appointments')
      .select(`
        id, scheduled_at, patient_id,
        doctor:doctors!doctor_id (
          id,
          profile:profiles!doctor_id ( full_name )
        )
      `)
      .eq('status', 'upcoming')
      .eq('reminder_sent', false)
      .lte('reminder_at', new Date().toISOString())

    if (fetchError) throw fetchError
    if (!appointments || appointments.length === 0) {
      return new Response(JSON.stringify({ processed: 0 }), {
        status: 200,
        headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
      })
    }

    const results = await Promise.all(
      appointments.map((apt) =>
        processReminder(supabase, apt, accessToken, projectId),
      ),
    )

    console.log(`Batch reminder: processed ${results.length} appointments`)

    return new Response(JSON.stringify({ processed: results.length, results }), {
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
