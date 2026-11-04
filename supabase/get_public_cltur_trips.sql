-- CL TUR: leitura pública e segura das excursões publicadas
-- Execute este script no SQL Editor do Supabase do projeto CL TUR.

create or replace function public.get_public_cltur_trips()
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
    'trips',
    coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', t->'id',
          'destination', t->'destination',
          'origin', t->'origin',
          'departure', t->'departure',
          'returnDate', t->'returnDate',
          'time', t->'time',
          'price', t->'price',
          'notes', t->'notes',
          'image', t->'image',
          'vehicles', coalesce(t->'vehicles', '[]'::jsonb),
          'published', true,
          'childRuleEnabled', t->'childRuleEnabled',
          'childFreeTransportAge', t->'childFreeTransportAge',
          'childExtraPrice', t->'childExtraPrice'
        )
      )
      from jsonb_array_elements(coalesce(s.state->'trips', '[]'::jsonb)) as x(t)
      where lower(coalesce(t->>'published', 'false')) = 'true'
    ), '[]'::jsonb),
    'people',
    coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'tripId', p->'tripId',
          'vehicleIndex', coalesce(p->'vehicleIndex', '0'::jsonb),
          'seat', p->'seat'
        )
      )
      from jsonb_array_elements(coalesce(s.state->'people', '[]'::jsonb)) as y(p)
      where nullif(p->>'seat', '') is not null
    ), '[]'::jsonb)
  )
  from public.cltur_app_state as s
  where s.id = 'main'
  limit 1;
$$;

revoke all on function public.get_public_cltur_trips() from public;
grant execute on function public.get_public_cltur_trips() to anon, authenticated;
