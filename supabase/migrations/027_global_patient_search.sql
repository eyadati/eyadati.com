-- Global patient search by phone number for doctors
-- Returns patient name, phone, and reliability score across all doctors

create or replace function public.search_patients(search_term text)
returns table (
  patient_id uuid,
  full_name text,
  phone text,
  total_visits bigint,
  no_show_count bigint,
  reliability_pct numeric
)
language sql
security definer
set search_path = public
as $$
  select
    p.id,
    p.full_name,
    p.phone,
    count(*)::bigint as total_visits,
    count(*) filter (where a.attendance_status = 'no_show')::bigint as no_show_count,
    case
      when count(*) >= 3
      then round(
        ((count(*) - count(*) filter (where a.attendance_status = 'no_show'))::numeric /
         nullif(count(*)::numeric, 0)) * 100
      )
    end as reliability_pct
  from public.profiles p
  left join public.appointments a on a.patient_id = p.id
  where p.role = 'patient'
    and (p.phone ilike '%' || search_term || '%' or p.full_name ilike '%' || search_term || '%')
  group by p.id
  order by
    case when p.phone ilike search_term || '%' then 0 else 1 end,
    p.full_name
  limit 20;
$$;

grant execute on function public.search_patients to authenticated;

-- Index for phone-based searches
create index if not exists idx_profiles_phone on public.profiles(phone);
