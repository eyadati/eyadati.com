-- Atomic clinic appointment creation for double-booking prevention
-- The entire check + insert runs in a single transaction via this SECURITY DEFINER function.

create or replace function public.create_clinic_appointment(
  p_doctor_id uuid,
  p_scheduled_at timestamptz,
  p_duration integer,
  p_patient_name text,
  p_patient_phone text default '',
  p_is_consultation boolean default false
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_user_id uuid;
  v_available boolean;
  v_appointment_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    return jsonb_build_object('success', false, 'error', 'Non connecté');
  end if;

  -- Validate inputs
  if p_patient_name is null or length(trim(p_patient_name)) = 0 then
    return jsonb_build_object('success', false, 'error', 'Le nom du patient est requis');
  end if;

  if p_duration < 5 or p_duration > 180 then
    return jsonb_build_object('success', false, 'error', 'Durée invalide');
  end if;

  -- Verify clinic membership (current user is in same group as target doctor)
  if not public.is_same_clinic_group(v_user_id, p_doctor_id) then
    return jsonb_build_object('success', false, 'error', 'Accès refusé');
  end if;

  -- Atomic availability check (runs in same transaction)
  select public.check_slot_availability(p_doctor_id, p_scheduled_at, p_duration) into v_available;
  if not v_available then
    return jsonb_build_object('success', false, 'error', 'Ce créneau est déjà occupé');
  end if;

  -- Create the appointment
  insert into public.appointments (
    doctor_id,
    scheduled_at,
    duration,
    status,
    booking_type,
    is_consultation,
    patient_name_snapshot,
    patient_phone_snapshot
  ) values (
    p_doctor_id,
    p_scheduled_at,
    p_duration,
    'upcoming',
    'manual',
    p_is_consultation,
    trim(p_patient_name),
    trim(coalesce(p_patient_phone, ''))
  )
  returning id into v_appointment_id;

  return jsonb_build_object('success', true, 'appointment_id', v_appointment_id);
end;
$$;

-- Grant execute to authenticated users
revoke execute on function public.create_clinic_appointment from public;
grant execute on function public.create_clinic_appointment to authenticated;
