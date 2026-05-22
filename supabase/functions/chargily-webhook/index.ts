import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

const CHARGILY_SECRET_KEY = Deno.env.get('CHARGILY_SECRET_KEY')
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || 'https://erkldarqweehvwgpncrg.supabase.co'
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

const SUBSCRIPTION_DAYS = 30

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 })
  }

  if (!CHARGILY_SECRET_KEY) {
    console.error('CHARGILY_SECRET_KEY not set')
    return new Response('Server configuration error', { status: 500 })
  }

  const signature = req.headers.get('signature')
  if (!signature) {
    console.error('Missing signature header')
    return new Response('No signature header', { status: 400 })
  }

  const rawBody = await req.text()

  // Verify HMAC-SHA256 signature using crypto.subtle.verify (constant-time)
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(CHARGILY_SECRET_KEY),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['verify']
  )

  const signatureBytes = new Uint8Array(
    signature.match(/.{1,2}/g)!.map((byte) => parseInt(byte, 16))
  )

  const isValid = await crypto.subtle.verify(
    'HMAC',
    key,
    signatureBytes,
    new TextEncoder().encode(rawBody)
  )

  if (!isValid) {
    console.error('Webhook signature verification failed')
    return new Response('Invalid signature', { status: 403 })
  }

  // Parse event
  let event: any
  try {
    event = JSON.parse(rawBody)
  } catch {
    return new Response('Invalid JSON', { status: 400 })
  }

  console.log('Received webhook event:', event.type, 'id:', event.id)

  // Only process checkout.paid events
  if (event.type !== 'checkout.paid') {
    console.log('Ignoring event type:', event.type)
    return new Response('Unhandled event type', { status: 200 })
  }

  const checkoutData = event.data
  const doctorId = checkoutData.metadata?.doctor_id

  if (!doctorId) {
    console.error('Missing doctor_id in metadata')
    return new Response('Missing doctor_id', { status: 400 })
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

  try {
    // Idempotency: check if this event was already processed
    const { data: existingPayment } = await supabase
      .from('payment_history')
      .select('id')
      .eq('chargily_event_id', event.id)
      .maybeSingle()

    if (existingPayment) {
      console.log('Event already processed:', event.id)
      return new Response('Already processed', { status: 200 })
    }

    // Fetch current doctor subscription end date
    const { data: doctor, error: doctorError } = await supabase
      .from('doctors')
      .select('subscription_end')
      .eq('id', doctorId)
      .single()

    if (doctorError || !doctor) {
      console.error('Doctor not found:', doctorId, doctorError)
      return new Response('Doctor not found', { status: 404 })
    }

    const currentEndVal = doctor.subscription_end
    const currentEndDate = currentEndVal ? new Date(currentEndVal) : new Date()
    const now = new Date()

    // Calculate new end date
    let newEndDate: Date
    if (currentEndDate > now) {
      // Extend from current end
      newEndDate = new Date(currentEndDate)
      newEndDate.setDate(newEndDate.getDate() + SUBSCRIPTION_DAYS)
    } else {
      // Start new subscription from now
      newEndDate = new Date(now)
      newEndDate.setDate(now.getDate() + SUBSCRIPTION_DAYS)
    }

    const periodStart = currentEndDate > now ? currentEndDate : now

    console.log(
      `Doctor ${doctorId}: extending subscription to ${newEndDate.toISOString()}`
    )

    // Update doctor subscription
    const { error: updateError } = await supabase
      .from('doctors')
      .update({
        subscription_end: newEndDate.toISOString(),
        manual_pause: false,
      })
      .eq('id', doctorId)

    if (updateError) {
      console.error('Failed to update doctor:', updateError.message)
      return new Response('Failed to update doctor', { status: 500 })
    }

    // Record payment history
    const { error: insertError } = await supabase
      .from('payment_history')
      .insert({
        doctor_id: doctorId,
        amount: checkoutData.amount || 6000,
        currency: 'dzd',
        chargily_checkout_id: checkoutData.id,
        chargily_event_id: event.id,
        status: 'completed',
        period_start: periodStart.toISOString(),
        period_end: newEndDate.toISOString(),
      })

    if (insertError) {
      console.error('Failed to insert payment history:', insertError.message)
      // Don't fail the webhook — subscription was already updated
    }

    console.log('Subscription updated and payment recorded successfully')
    return new Response('Webhook processed successfully', { status: 200 })
  } catch (error) {
    console.error('Webhook processing error:', error.message)
    return new Response('Internal Server Error', { status: 500 })
  }
})
