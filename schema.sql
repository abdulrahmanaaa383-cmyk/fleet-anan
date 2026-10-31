-- شغّل الملف كله في Supabase > SQL Editor > Run
create extension if not exists pgcrypto;

create table vehicles (
  id uuid primary key default gen_random_uuid(), created_at timestamptz default now(),
  plate text not null unique, model text not null, year int,
  status text default 'عاملة', odometer int, notes text);

create table drivers (
  id uuid primary key default gen_random_uuid(), created_at timestamptz default now(),
  name text not null, iqama_no text, birth_date date, absher_phone text,
  iqama_img text, license_img text, auth_status text default 'قيد الاستكمال', notes text);

create table handovers (
  id uuid primary key default gen_random_uuid(), created_at timestamptz default now(),
  vehicle_id uuid references vehicles on delete cascade, driver_id uuid references drivers,
  kind text not null, date date default current_date, odometer int, fuel text,
  accessories text, damages text, photos_img text, signed text default 'لا', notes text);

create table incidents (
  id uuid primary key default gen_random_uuid(), created_at timestamptz default now(),
  vehicle_id uuid references vehicles on delete cascade, driver_id uuid references drivers,
  date date default current_date, najm_ref text, insurer text, status text default 'مفتوح',
  repair_cost numeric default 0, driver_share numeric default 0, report_img text, notes text);

create table invoices (
  id uuid primary key default gen_random_uuid(), created_at timestamptz default now(),
  vehicle_id uuid references vehicles on delete cascade, supplier text not null,
  category text, invoice_no text, date date default current_date,
  amount numeric default 0, status text default 'قيد المراجعة', file_img text, notes text);

create table fines (
  id uuid primary key default gen_random_uuid(), created_at timestamptz default now(),
  vehicle_id uuid references vehicles on delete cascade, driver_id uuid references drivers,
  date date default current_date, amount numeric default 0, status text default 'غير مسددة', notes text);

-- الأمان: أي مستخدم مسجّل دخول فقط يقدر يقرأ/يكتب
do $$ declare t text; begin
  foreach t in array array['vehicles','drivers','handovers','incidents','invoices','fines'] loop
    execute format('alter table %I enable row level security', t);
    execute format('create policy "auth_all" on %I for all to authenticated using (true) with check (true)', t);
  end loop; end $$;

-- مخزن الصور والمستندات
insert into storage.buckets (id, name, public) values ('docs','docs',true) on conflict do nothing;
create policy "docs_auth_write" on storage.objects for insert to authenticated with check (bucket_id='docs');
create policy "docs_auth_read" on storage.objects for select to authenticated using (bucket_id='docs');
