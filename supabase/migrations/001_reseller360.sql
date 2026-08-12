-- Reseller360 core schema
-- Run with Supabase CLI migrations or paste into the Supabase SQL editor.

create extension if not exists pgcrypto;

-- ---------- Core identities ----------
create table if not exists public.resellers (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  legal_name text,
  country text,
  currency text not null default 'USD',
  billing_email text,
  payment_term_days integer not null default 30 check (payment_term_days >= 0),
  status text not null default 'active' check (status in ('active','inactive','suspended')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text,
  role text not null default 'reseller_user' check (role in ('admin','finance','reseller_admin','reseller_user')),
  reseller_id uuid references public.resellers(id) on delete set null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.current_reseller_id()
returns uuid language sql stable security definer set search_path=public as $$
  select reseller_id from public.profiles where id = auth.uid() and is_active = true;
$$;

create or replace function public.current_app_role()
returns text language sql stable security definer set search_path=public as $$
  select role from public.profiles where id = auth.uid() and is_active = true;
$$;

create or replace function public.is_platform_admin()
returns boolean language sql stable security definer set search_path=public as $$
  select coalesce(public.current_app_role() in ('admin','finance'), false);
$$;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  insert into public.profiles(id,email,full_name)
  values(new.id,new.email,coalesce(new.raw_user_meta_data->>'full_name',split_part(new.email,'@',1)))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

-- ---------- Shared CRM identity ----------
create table if not exists public.companies (
  id uuid primary key default gen_random_uuid(),
  company_name text not null,
  legal_name text,
  website text,
  country text,
  city text,
  industry text,
  company_size text,
  linkedin_url text,
  normalized_name text generated always as (lower(regexp_replace(company_name,'[^a-zA-Z0-9]+','','g'))) stored,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index if not exists companies_normalized_name_uq on public.companies(normalized_name) where normalized_name <> '';

create table if not exists public.reseller_company_links (
  id uuid primary key default gen_random_uuid(),
  reseller_id uuid not null references public.resellers(id) on delete cascade,
  company_id uuid not null references public.companies(id) on delete cascade,
  stage text not null default 'not_contacted' check (stage in ('not_contacted','contacted','engaged','qualified','proposal','negotiation','won','lost')),
  contacted boolean not null default false,
  is_active_client boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(reseller_id,company_id)
);

create table if not exists public.contacts (
  id uuid primary key default gen_random_uuid(),
  reseller_id uuid not null default public.current_reseller_id() references public.resellers(id) on delete cascade,
  company_id uuid not null references public.companies(id) on delete cascade,
  first_name text not null,
  last_name text,
  job_title text,
  email text,
  phone text,
  linkedin_url text,
  is_decision_maker boolean not null default false,
  notes text,
  created_by uuid default auth.uid() references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.leads (
  id uuid primary key default gen_random_uuid(),
  reseller_id uuid not null default public.current_reseller_id() references public.resellers(id) on delete cascade,
  company_id uuid not null references public.companies(id) on delete cascade,
  contact_id uuid references public.contacts(id) on delete set null,
  title text not null,
  source text,
  status text not null default 'new' check(status in ('new','contacting','contacted','qualified','converted','disqualified')),
  priority text not null default 'medium' check(priority in ('low','medium','high','urgent')),
  estimated_value numeric(14,2) not null default 0,
  currency text not null default 'USD',
  next_follow_up date,
  notes text,
  created_by uuid default auth.uid() references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.deals (
  id uuid primary key default gen_random_uuid(),
  reseller_id uuid not null default public.current_reseller_id() references public.resellers(id) on delete cascade,
  company_id uuid not null references public.companies(id) on delete cascade,
  contact_id uuid references public.contacts(id) on delete set null,
  lead_id uuid references public.leads(id) on delete set null,
  name text not null,
  stage text not null default 'discovery' check(stage in ('discovery','qualified','demo','proposal','negotiation','won','lost')),
  value numeric(14,2) not null default 0,
  currency text not null default 'USD',
  probability integer not null default 20 check(probability between 0 and 100),
  expected_close_date date,
  product_name text,
  location_count integer not null default 1 check(location_count > 0),
  next_action text,
  notes text,
  created_by uuid default auth.uid() references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.activities (
  id uuid primary key default gen_random_uuid(),
  reseller_id uuid not null default public.current_reseller_id() references public.resellers(id) on delete cascade,
  company_id uuid references public.companies(id) on delete cascade,
  contact_id uuid references public.contacts(id) on delete set null,
  lead_id uuid references public.leads(id) on delete set null,
  deal_id uuid references public.deals(id) on delete set null,
  activity_type text not null check(activity_type in ('call','email','whatsapp','meeting','demo','linkedin','follow_up','note')),
  subject text not null,
  details text,
  activity_at timestamptz not null default now(),
  next_follow_up timestamptz,
  created_by uuid default auth.uid() references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

-- ---------- Client / licence lifecycle ----------
create table if not exists public.clients (
  id uuid primary key default gen_random_uuid(),
  reseller_id uuid not null references public.resellers(id) on delete cascade,
  company_id uuid not null references public.companies(id) on delete restrict,
  status text not null default 'active' check(status in ('active','on_hold','inactive','cancelled')),
  activated_at date not null default current_date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(reseller_id,company_id)
);

create table if not exists public.client_locations (
  id uuid primary key default gen_random_uuid(),
  reseller_id uuid not null references public.resellers(id) on delete cascade,
  client_id uuid not null references public.clients(id) on delete cascade,
  location_name text not null,
  country text,
  city text,
  address text,
  status text not null default 'active' check(status in ('active','pending','inactive','closed')),
  activated_at date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.licenses (
  id uuid primary key default gen_random_uuid(),
  reseller_id uuid not null references public.resellers(id) on delete cascade,
  client_id uuid not null references public.clients(id) on delete cascade,
  location_id uuid not null references public.client_locations(id) on delete cascade,
  product_name text not null,
  quantity integer not null default 1 check(quantity > 0),
  annual_value numeric(14,2) not null default 0,
  currency text not null default 'USD',
  start_date date not null,
  expiry_date date not null,
  billing_frequency text not null default 'annual' check(billing_frequency in ('annual','semi_annual','quarterly','monthly')),
  payment_term_days integer not null default 30 check(payment_term_days >= 0),
  status text not null default 'active' check(status in ('active','pending','expired','cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check(expiry_date >= start_date)
);

-- ---------- Finance ----------
create table if not exists public.document_counters (
  doc_type text not null,
  doc_year integer not null,
  last_number integer not null default 0,
  primary key(doc_type,doc_year)
);

create or replace function public.next_document_number(p_doc_type text, p_date date default current_date)
returns text language plpgsql security definer set search_path=public as $$
declare v_year integer := extract(year from p_date); v_num integer;
begin
  insert into public.document_counters(doc_type,doc_year,last_number)
  values(upper(p_doc_type),v_year,1)
  on conflict(doc_type,doc_year) do update set last_number=public.document_counters.last_number+1
  returning last_number into v_num;
  return upper(p_doc_type)||'/'||v_year||'/'||lpad(v_num::text,5,'0');
end;
$$;

create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  invoice_number text unique,
  reseller_id uuid not null references public.resellers(id) on delete restrict,
  client_id uuid references public.clients(id) on delete set null,
  location_id uuid references public.client_locations(id) on delete set null,
  source_type text check(source_type in ('request','renewal','manual')),
  source_id uuid,
  reference text,
  currency text not null default 'USD',
  subtotal numeric(14,2) not null default 0,
  tax numeric(14,2) not null default 0,
  total numeric(14,2) not null default 0,
  issued_at date not null default current_date,
  due_date date not null,
  billing_frequency text not null default 'annual' check(billing_frequency in ('annual','semi_annual','quarterly','monthly')),
  payment_term_days integer not null default 30,
  status text not null default 'issued' check(status in ('draft','issued','cancelled','credited')),
  notes text,
  created_by uuid default auth.uid() references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.invoice_items (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.invoices(id) on delete cascade,
  description text not null,
  quantity numeric(12,2) not null default 1,
  unit_price numeric(14,2) not null default 0,
  amount numeric(14,2) generated always as (quantity*unit_price) stored,
  created_at timestamptz not null default now()
);

create table if not exists public.payment_schedules (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.invoices(id) on delete cascade,
  installment_number integer not null,
  installment_count integer not null,
  due_date date not null,
  amount_due numeric(14,2) not null check(amount_due >= 0),
  created_at timestamptz not null default now(),
  unique(invoice_id,installment_number)
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  reseller_id uuid not null references public.resellers(id) on delete restrict,
  amount numeric(14,2) not null check(amount > 0),
  currency text not null default 'USD',
  paid_at date not null,
  method text not null default 'bank_transfer' check(method in ('bank_transfer','cash','card','cheque','other')),
  reference text,
  notes text,
  created_by uuid default auth.uid() references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.payment_allocations (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references public.payments(id) on delete cascade,
  invoice_id uuid not null references public.invoices(id) on delete restrict,
  amount numeric(14,2) not null check(amount > 0),
  created_at timestamptz not null default now(),
  unique(payment_id,invoice_id)
);

create table if not exists public.receipts (
  id uuid primary key default gen_random_uuid(),
  receipt_number text unique,
  payment_id uuid not null unique references public.payments(id) on delete restrict,
  reseller_id uuid not null references public.resellers(id) on delete restrict,
  amount numeric(14,2) not null,
  currency text not null default 'USD',
  issued_at date not null default current_date,
  status text not null default 'issued' check(status in ('draft','issued','voided')),
  created_by uuid default auth.uid() references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

-- ---------- Requests & renewals ----------
create table if not exists public.service_requests (
  id uuid primary key default gen_random_uuid(),
  request_number text unique,
  reseller_id uuid not null default public.current_reseller_id() references public.resellers(id) on delete restrict,
  requested_by uuid not null default auth.uid() references public.profiles(id) on delete restrict,
  request_type text not null check(request_type in ('new_client','add_location')),
  company_id uuid references public.companies(id) on delete set null,
  client_id uuid references public.clients(id) on delete set null,
  location_name text not null,
  country text,
  city text,
  product_name text not null,
  quantity integer not null default 1 check(quantity > 0),
  unit_price numeric(14,2) not null default 0,
  setup_fee numeric(14,2) not null default 0,
  total_amount numeric(14,2) generated always as ((quantity*unit_price)+setup_fee) stored,
  currency text not null default 'USD',
  start_date date not null,
  billing_frequency text not null default 'annual' check(billing_frequency in ('annual','semi_annual','quarterly','monthly')),
  payment_term_days integer not null default 30,
  notes text,
  admin_notes text,
  status text not null default 'pending' check(status in ('pending','approved','rejected','fulfilled','cancelled')),
  invoice_id uuid references public.invoices(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.renewals (
  id uuid primary key default gen_random_uuid(),
  reseller_id uuid not null references public.resellers(id) on delete cascade,
  license_id uuid not null references public.licenses(id) on delete cascade,
  expiry_date date not null,
  renewal_start_date date not null,
  renewal_expiry_date date not null,
  renewal_value numeric(14,2) not null,
  currency text not null default 'USD',
  billing_frequency text not null default 'annual' check(billing_frequency in ('annual','semi_annual','quarterly','monthly')),
  payment_term_days integer not null default 30,
  status text not null default 'upcoming' check(status in ('upcoming','requested','approved','invoiced','renewed','not_renewing','expired')),
  requested_at timestamptz,
  invoice_id uuid references public.invoices(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(license_id,expiry_date)
);

create table if not exists public.audit_logs (
  id bigint generated always as identity primary key,
  actor_id uuid,
  reseller_id uuid,
  action text not null,
  entity_type text not null,
  entity_id text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- ---------- Utility triggers ----------
create or replace function public.touch_updated_at() returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end $$;

do $$ declare t text; begin
  foreach t in array array['resellers','profiles','companies','reseller_company_links','contacts','leads','deals','clients','client_locations','licenses','invoices','service_requests','renewals']
  loop execute format('drop trigger if exists %I_touch_updated_at on public.%I',t,t); execute format('create trigger %I_touch_updated_at before update on public.%I for each row execute function public.touch_updated_at()',t,t); end loop;
end $$;

create or replace function public.set_request_number() returns trigger language plpgsql security definer set search_path=public as $$ begin if new.request_number is null then new.request_number:=public.next_document_number('REQ',current_date); end if; return new; end $$;
create or replace function public.set_invoice_number() returns trigger language plpgsql security definer set search_path=public as $$ begin if new.invoice_number is null then new.invoice_number:=public.next_document_number('INV',new.issued_at); end if; return new; end $$;
create or replace function public.set_receipt_number() returns trigger language plpgsql security definer set search_path=public as $$ begin if new.receipt_number is null then new.receipt_number:=public.next_document_number('RV',new.issued_at); end if; return new; end $$;
drop trigger if exists service_request_number on public.service_requests; create trigger service_request_number before insert on public.service_requests for each row execute function public.set_request_number();
drop trigger if exists invoice_number on public.invoices; create trigger invoice_number before insert on public.invoices for each row execute function public.set_invoice_number();
drop trigger if exists receipt_number on public.receipts; create trigger receipt_number before insert on public.receipts for each row execute function public.set_receipt_number();

-- ---------- Business functions ----------
create or replace function public.create_or_claim_company(
  p_name text,p_legal_name text default null,p_website text default null,p_country text default null,p_city text default null,p_industry text default null,p_stage text default 'not_contacted'
) returns uuid language plpgsql security definer set search_path=public as $$
declare v_company uuid; v_reseller uuid := public.current_reseller_id(); v_norm text;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if v_reseller is null then raise exception 'Your user is not assigned to a reseller'; end if;
  v_norm:=lower(regexp_replace(p_name,'[^a-zA-Z0-9]+','','g'));
  select id into v_company from public.companies where normalized_name=v_norm limit 1;
  if v_company is null then
    insert into public.companies(company_name,legal_name,website,country,city,industry)
    values(p_name,p_legal_name,p_website,p_country,p_city,p_industry) returning id into v_company;
  end if;
  insert into public.reseller_company_links(reseller_id,company_id,stage,contacted)
  values(v_reseller,v_company,p_stage,p_stage<>'not_contacted')
  on conflict(reseller_id,company_id) do update set updated_at=now();
  return v_company;
end;
$$;

create or replace function public.create_payment_schedule(p_invoice_id uuid,p_total numeric,p_frequency text,p_first_due date)
returns void language plpgsql security definer set search_path=public as $$
declare v_count int; v_step int; i int; v_base numeric(14,2); v_amount numeric(14,2); v_assigned numeric(14,2):=0;
begin
  v_count:=case p_frequency when 'monthly' then 12 when 'quarterly' then 4 when 'semi_annual' then 2 else 1 end;
  v_step:=case p_frequency when 'monthly' then 1 when 'quarterly' then 3 when 'semi_annual' then 6 else 12 end;
  v_base:=round(p_total/v_count,2);
  for i in 1..v_count loop
    v_amount:=case when i=v_count then p_total-v_assigned else v_base end;
    insert into public.payment_schedules(invoice_id,installment_number,installment_count,due_date,amount_due)
    values(p_invoice_id,i,v_count,(p_first_due + make_interval(months => (i-1)*v_step))::date,v_amount);
    v_assigned:=v_assigned+v_amount;
  end loop;
end;
$$;

create or replace function public.approve_service_request(p_request_id uuid)
returns uuid language plpgsql security definer set search_path=public as $$
declare r public.service_requests%rowtype; v_client uuid; v_location uuid; v_license uuid; v_invoice uuid; v_expiry date;
begin
  if not public.is_platform_admin() then raise exception 'Admin or finance role required'; end if;
  select * into r from public.service_requests where id=p_request_id for update;
  if not found then raise exception 'Request not found'; end if;
  if r.status<>'pending' then raise exception 'Only pending requests can be approved'; end if;

  if r.request_type='new_client' then
    if r.company_id is null then raise exception 'Company is required'; end if;
    insert into public.clients(reseller_id,company_id,status,activated_at) values(r.reseller_id,r.company_id,'active',r.start_date)
    on conflict(reseller_id,company_id) do update set status='active',updated_at=now() returning id into v_client;
    update public.reseller_company_links set stage='won',contacted=true,is_active_client=true where reseller_id=r.reseller_id and company_id=r.company_id;
  else
    v_client:=r.client_id;
    if v_client is null then raise exception 'Existing client is required'; end if;
  end if;

  insert into public.client_locations(reseller_id,client_id,location_name,country,city,status,activated_at)
  values(r.reseller_id,v_client,r.location_name,r.country,r.city,'active',r.start_date) returning id into v_location;
  v_expiry:=(r.start_date + interval '1 year' - interval '1 day')::date;
  insert into public.licenses(reseller_id,client_id,location_id,product_name,quantity,annual_value,currency,start_date,expiry_date,billing_frequency,payment_term_days,status)
  values(r.reseller_id,v_client,v_location,r.product_name,r.quantity,r.quantity*r.unit_price,r.currency,r.start_date,v_expiry,r.billing_frequency,r.payment_term_days,'active') returning id into v_license;
  insert into public.renewals(reseller_id,license_id,expiry_date,renewal_start_date,renewal_expiry_date,renewal_value,currency,billing_frequency,payment_term_days,status)
  values(r.reseller_id,v_license,v_expiry,v_expiry+1,(v_expiry+interval '1 year')::date,r.quantity*r.unit_price,r.currency,r.billing_frequency,r.payment_term_days,'upcoming');

  insert into public.invoices(reseller_id,client_id,location_id,source_type,source_id,reference,currency,subtotal,tax,total,issued_at,due_date,billing_frequency,payment_term_days,status)
  values(r.reseller_id,v_client,v_location,'request',r.id,r.request_number,r.currency,r.total_amount,0,r.total_amount,current_date,current_date+r.payment_term_days,r.billing_frequency,r.payment_term_days,'issued') returning id into v_invoice;
  insert into public.invoice_items(invoice_id,description,quantity,unit_price) values(v_invoice,r.product_name||' - '||r.location_name,r.quantity,r.unit_price);
  if r.setup_fee>0 then insert into public.invoice_items(invoice_id,description,quantity,unit_price) values(v_invoice,'Account / setup fee',1,r.setup_fee); end if;
  perform public.create_payment_schedule(v_invoice,r.total_amount,r.billing_frequency,current_date+r.payment_term_days);
  update public.service_requests set status='approved',invoice_id=v_invoice,reviewed_at=now() where id=r.id;
  insert into public.audit_logs(actor_id,reseller_id,action,entity_type,entity_id,details) values(auth.uid(),r.reseller_id,'approve','service_request',r.id::text,jsonb_build_object('invoice_id',v_invoice));
  return v_invoice;
end;
$$;

create or replace function public.issue_renewal_invoice(p_renewal_id uuid)
returns uuid language plpgsql security definer set search_path=public as $$
declare r public.renewals%rowtype; l public.licenses%rowtype; v_invoice uuid; v_client_name text; v_location_name text;
begin
  if not public.is_platform_admin() then raise exception 'Admin or finance role required'; end if;
  select * into r from public.renewals where id=p_renewal_id for update;
  if not found then raise exception 'Renewal not found'; end if;
  if r.status not in ('requested','approved','upcoming') then raise exception 'Renewal cannot be invoiced from current status'; end if;
  select * into l from public.licenses where id=r.license_id;
  select c.company_name,cl.location_name into v_client_name,v_location_name from public.clients x join public.companies c on c.id=x.company_id join public.client_locations cl on cl.id=l.location_id where x.id=l.client_id;
  insert into public.invoices(reseller_id,client_id,location_id,source_type,source_id,reference,currency,subtotal,tax,total,issued_at,due_date,billing_frequency,payment_term_days,status)
  values(r.reseller_id,l.client_id,l.location_id,'renewal',r.id,'Renewal - '||v_client_name||' / '||v_location_name,r.currency,r.renewal_value,0,r.renewal_value,current_date,current_date+r.payment_term_days,r.billing_frequency,r.payment_term_days,'issued') returning id into v_invoice;
  insert into public.invoice_items(invoice_id,description,quantity,unit_price) values(v_invoice,'Renewal - '||l.product_name||' - '||v_location_name,l.quantity,r.renewal_value/l.quantity);
  perform public.create_payment_schedule(v_invoice,r.renewal_value,r.billing_frequency,current_date+r.payment_term_days);
  update public.renewals set status='invoiced',invoice_id=v_invoice where id=r.id;
  return v_invoice;
end;
$$;

create or replace function public.record_invoice_payment(p_invoice_id uuid,p_amount numeric,p_paid_at date,p_method text default 'bank_transfer',p_reference text default null)
returns uuid language plpgsql security definer set search_path=public as $$
declare i public.invoices%rowtype; v_paid numeric; v_balance numeric; v_payment uuid; v_receipt uuid; v_renewal public.renewals%rowtype; v_license public.licenses%rowtype;
begin
  if not public.is_platform_admin() then raise exception 'Admin or finance role required'; end if;
  if p_amount<=0 then raise exception 'Payment amount must be positive'; end if;
  select * into i from public.invoices where id=p_invoice_id for update;
  if not found or i.status<>'issued' then raise exception 'Issued invoice not found'; end if;
  select coalesce(sum(amount),0) into v_paid from public.payment_allocations where invoice_id=i.id;
  v_balance:=i.total-v_paid;
  if p_amount>v_balance+0.005 then raise exception 'Payment exceeds invoice balance of %',v_balance; end if;
  insert into public.payments(reseller_id,amount,currency,paid_at,method,reference) values(i.reseller_id,p_amount,i.currency,p_paid_at,p_method,p_reference) returning id into v_payment;
  insert into public.payment_allocations(payment_id,invoice_id,amount) values(v_payment,i.id,p_amount);
  insert into public.receipts(payment_id,reseller_id,amount,currency,issued_at,status) values(v_payment,i.reseller_id,p_amount,i.currency,p_paid_at,'issued') returning id into v_receipt;

  if abs((v_paid+p_amount)-i.total)<0.01 then
    if i.source_type='renewal' then
      select * into v_renewal from public.renewals where id=i.source_id for update;
      if found then
        select * into v_license from public.licenses where id=v_renewal.license_id for update;
        update public.renewals set status='renewed' where id=v_renewal.id;
        update public.licenses set start_date=v_renewal.renewal_start_date,expiry_date=v_renewal.renewal_expiry_date,status='active' where id=v_license.id;
        insert into public.renewals(reseller_id,license_id,expiry_date,renewal_start_date,renewal_expiry_date,renewal_value,currency,billing_frequency,payment_term_days,status)
        values(v_renewal.reseller_id,v_license.id,v_renewal.renewal_expiry_date,v_renewal.renewal_expiry_date+1,(v_renewal.renewal_expiry_date+interval '1 year')::date,v_renewal.renewal_value,v_renewal.currency,v_renewal.billing_frequency,v_renewal.payment_term_days,'upcoming')
        on conflict(license_id,expiry_date) do nothing;
      end if;
    elsif i.source_type='request' then
      update public.service_requests set status='fulfilled' where id=i.source_id and status='approved';
    end if;
  end if;
  insert into public.audit_logs(actor_id,reseller_id,action,entity_type,entity_id,details) values(auth.uid(),i.reseller_id,'record_payment','invoice',i.id::text,jsonb_build_object('amount',p_amount,'payment_id',v_payment,'receipt_id',v_receipt));
  return v_receipt;
end;
$$;

create or replace function public.request_renewal(p_renewal_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare r public.renewals%rowtype;
begin
  select * into r from public.renewals where id=p_renewal_id for update;
  if not found then raise exception 'Renewal not found'; end if;
  if not (public.is_platform_admin() or r.reseller_id=public.current_reseller_id()) then raise exception 'Not allowed'; end if;
  if r.status<>'upcoming' then raise exception 'Only upcoming renewals can be requested'; end if;
  update public.renewals set status='requested',requested_at=now() where id=r.id;
end;
$$;

-- ---------- RLS ----------
alter table public.resellers enable row level security;
alter table public.profiles enable row level security;
alter table public.companies enable row level security;
alter table public.reseller_company_links enable row level security;
alter table public.contacts enable row level security;
alter table public.leads enable row level security;
alter table public.deals enable row level security;
alter table public.activities enable row level security;
alter table public.clients enable row level security;
alter table public.client_locations enable row level security;
alter table public.licenses enable row level security;
alter table public.renewals enable row level security;
alter table public.service_requests enable row level security;
alter table public.invoices enable row level security;
alter table public.invoice_items enable row level security;
alter table public.payment_schedules enable row level security;
alter table public.payments enable row level security;
alter table public.payment_allocations enable row level security;
alter table public.receipts enable row level security;
alter table public.audit_logs enable row level security;
alter table public.document_counters enable row level security;

-- Shared reseller/company identity is readable to authenticated users.
drop policy if exists resellers_read on public.resellers; create policy resellers_read on public.resellers for select to authenticated using(id=public.current_reseller_id() or public.is_platform_admin());
drop policy if exists resellers_admin_write on public.resellers; create policy resellers_admin_write on public.resellers for all to authenticated using(public.is_platform_admin()) with check(public.is_platform_admin());
drop policy if exists companies_read on public.companies; create policy companies_read on public.companies for select to authenticated using(true);
drop policy if exists companies_insert on public.companies; create policy companies_insert on public.companies for insert to authenticated with check(public.is_platform_admin());
drop policy if exists companies_admin_update on public.companies; create policy companies_admin_update on public.companies for update to authenticated using(public.is_platform_admin()) with check(public.is_platform_admin());
drop policy if exists links_read on public.reseller_company_links; create policy links_read on public.reseller_company_links for select to authenticated using(reseller_id=public.current_reseller_id() or public.is_platform_admin());
drop policy if exists links_own_insert on public.reseller_company_links; create policy links_own_insert on public.reseller_company_links for insert to authenticated with check(reseller_id=public.current_reseller_id() or public.is_platform_admin());
drop policy if exists links_own_update on public.reseller_company_links; create policy links_own_update on public.reseller_company_links for update to authenticated using(reseller_id=public.current_reseller_id() or public.is_platform_admin()) with check(reseller_id=public.current_reseller_id() or public.is_platform_admin());
drop policy if exists links_own_delete on public.reseller_company_links; create policy links_own_delete on public.reseller_company_links for delete to authenticated using(reseller_id=public.current_reseller_id() or public.is_platform_admin());

-- Profiles are visible inside the same reseller; admin sees all.
drop policy if exists profiles_read on public.profiles; create policy profiles_read on public.profiles for select to authenticated using(id=auth.uid() or reseller_id=public.current_reseller_id() or public.is_platform_admin());
drop policy if exists profiles_admin_update on public.profiles; create policy profiles_admin_update on public.profiles for update to authenticated using(public.is_platform_admin()) with check(public.is_platform_admin());

-- Private reseller-owned tables.
do $$ declare t text; begin
 foreach t in array array['contacts','leads','deals','activities','clients','client_locations','licenses','renewals','service_requests','invoices','payments','receipts'] loop
   execute format('drop policy if exists %I_read on public.%I',t,t);
   execute format('create policy %I_read on public.%I for select to authenticated using(reseller_id=public.current_reseller_id() or public.is_platform_admin())',t,t);
 end loop;
end $$;

drop policy if exists contacts_write on public.contacts; create policy contacts_write on public.contacts for all to authenticated using(reseller_id=public.current_reseller_id() or public.is_platform_admin()) with check(reseller_id=public.current_reseller_id() or public.is_platform_admin());
drop policy if exists leads_write on public.leads; create policy leads_write on public.leads for all to authenticated using(reseller_id=public.current_reseller_id() or public.is_platform_admin()) with check(reseller_id=public.current_reseller_id() or public.is_platform_admin());
drop policy if exists deals_write on public.deals; create policy deals_write on public.deals for all to authenticated using(reseller_id=public.current_reseller_id() or public.is_platform_admin()) with check(reseller_id=public.current_reseller_id() or public.is_platform_admin());
drop policy if exists activities_write on public.activities; create policy activities_write on public.activities for all to authenticated using(reseller_id=public.current_reseller_id() or public.is_platform_admin()) with check(reseller_id=public.current_reseller_id() or public.is_platform_admin());
-- Client/finance writes are admin-controlled; reseller requests are the write entry point.
drop policy if exists requests_insert on public.service_requests; create policy requests_insert on public.service_requests for insert to authenticated with check((reseller_id=public.current_reseller_id() and requested_by=auth.uid()) or public.is_platform_admin());
drop policy if exists requests_update on public.service_requests; create policy requests_update on public.service_requests for update to authenticated using(public.is_platform_admin()) with check(public.is_platform_admin());
drop policy if exists renewals_admin_update on public.renewals; create policy renewals_admin_update on public.renewals for update to authenticated using(public.is_platform_admin()) with check(public.is_platform_admin());

-- Child financial rows inherit access from their invoice/payment.
drop policy if exists invoice_items_read on public.invoice_items; create policy invoice_items_read on public.invoice_items for select to authenticated using(exists(select 1 from public.invoices i where i.id=invoice_id and (i.reseller_id=public.current_reseller_id() or public.is_platform_admin())));
drop policy if exists schedules_read on public.payment_schedules; create policy schedules_read on public.payment_schedules for select to authenticated using(exists(select 1 from public.invoices i where i.id=invoice_id and (i.reseller_id=public.current_reseller_id() or public.is_platform_admin())));
drop policy if exists allocations_read on public.payment_allocations; create policy allocations_read on public.payment_allocations for select to authenticated using(exists(select 1 from public.payments p where p.id=payment_id and (p.reseller_id=public.current_reseller_id() or public.is_platform_admin())));
drop policy if exists audit_admin_read on public.audit_logs; create policy audit_admin_read on public.audit_logs for select to authenticated using(public.is_platform_admin());
-- No direct client/invoice/payment inserts from browser: business functions are security definer.

-- ---------- Views ----------
-- Intentionally SECURITY DEFINER (the default) and exposes only safe shared columns.
-- Base reseller/link tables remain RLS-private to the owning reseller/admin.
create or replace view public.shared_company_directory as
select c.id company_id,c.company_name,c.legal_name,c.website,c.country,c.city,c.industry,c.updated_at,
       l.reseller_id,r.name reseller_name,coalesce(l.stage,'not_contacted') stage,coalesce(l.contacted,false) contacted,coalesce(l.is_active_client,false) is_active_client
from public.companies c left join public.reseller_company_links l on l.company_id=c.id left join public.resellers r on r.id=l.reseller_id;

create or replace view public.my_company_overview with (security_invoker=true) as
select l.id link_id,l.reseller_id,l.company_id,c.company_name,c.legal_name,c.website,c.country,c.city,c.industry,l.stage,l.contacted,l.is_active_client,l.updated_at
from public.reseller_company_links l join public.companies c on c.id=l.company_id
where l.reseller_id=public.current_reseller_id() or public.is_platform_admin();

create or replace view public.contact_overview with (security_invoker=true) as
select ct.*,concat_ws(' ',ct.first_name,ct.last_name) full_name,c.company_name from public.contacts ct join public.companies c on c.id=ct.company_id;

create or replace view public.lead_overview with (security_invoker=true) as
select l.*,c.company_name,concat_ws(' ',ct.first_name,ct.last_name) contact_name from public.leads l join public.companies c on c.id=l.company_id left join public.contacts ct on ct.id=l.contact_id;

create or replace view public.deal_overview with (security_invoker=true) as
select d.*,c.company_name,concat_ws(' ',ct.first_name,ct.last_name) contact_name from public.deals d join public.companies c on c.id=d.company_id left join public.contacts ct on ct.id=d.contact_id;

create or replace view public.activity_overview with (security_invoker=true) as
select a.*,c.company_name,concat_ws(' ',ct.first_name,ct.last_name) contact_name,d.name deal_name
from public.activities a left join public.companies c on c.id=a.company_id left join public.contacts ct on ct.id=a.contact_id left join public.deals d on d.id=a.deal_id;

create or replace view public.client_overview with (security_invoker=true) as
select cl.id,cl.reseller_id,c.company_name client_name,c.industry,c.country,cl.status,cl.activated_at,cl.created_at,r.name reseller_name,r.currency,
       (select count(*) from public.client_locations loc where loc.client_id=cl.id and loc.status='active') active_locations,
       coalesce((select sum(lic.annual_value) from public.licenses lic where lic.client_id=cl.id and lic.status='active'),0) active_value,
       (select min(ren.expiry_date) from public.renewals ren join public.licenses lic on lic.id=ren.license_id where lic.client_id=cl.id and ren.status in ('upcoming','requested','approved','invoiced')) next_renewal_date
from public.clients cl join public.companies c on c.id=cl.company_id join public.resellers r on r.id=cl.reseller_id;

create or replace view public.location_license_overview with (security_invoker=true) as
select lic.id license_id,loc.id location_id,lic.reseller_id,c.company_name client_name,loc.location_name,loc.city,loc.country,lic.product_name,lic.quantity,lic.annual_value,lic.currency,lic.start_date,lic.expiry_date,lic.billing_frequency,lic.payment_term_days,lic.status,lic.created_at
from public.licenses lic join public.client_locations loc on loc.id=lic.location_id join public.clients cl on cl.id=lic.client_id join public.companies c on c.id=cl.company_id;

create or replace view public.renewal_overview with (security_invoker=true) as
select ren.*,c.company_name client_name,loc.location_name,lic.product_name,r.name reseller_name,(ren.expiry_date-current_date) days_to_expiry
from public.renewals ren join public.licenses lic on lic.id=ren.license_id join public.client_locations loc on loc.id=lic.location_id join public.clients cl on cl.id=lic.client_id join public.companies c on c.id=cl.company_id join public.resellers r on r.id=ren.reseller_id;

create or replace view public.request_overview with (security_invoker=true) as
select sr.*,r.name reseller_name,c.company_name,cc.company_name client_name,i.invoice_number
from public.service_requests sr join public.resellers r on r.id=sr.reseller_id left join public.companies c on c.id=sr.company_id left join public.clients cl on cl.id=sr.client_id left join public.companies cc on cc.id=cl.company_id left join public.invoices i on i.id=sr.invoice_id;

create or replace view public.invoice_financials with (security_invoker=true) as
select i.*,r.name reseller_name,c.company_name client_name,loc.location_name,coalesce(p.paid_total,0) paid_total,(i.total-coalesce(p.paid_total,0)) balance,
case when i.status<>'issued' then i.status when coalesce(p.paid_total,0)>=i.total-0.005 then 'paid' when coalesce(p.paid_total,0)>0 then 'partially_paid' when i.due_date<current_date then 'overdue' else 'issued' end financial_status
from public.invoices i join public.resellers r on r.id=i.reseller_id left join public.clients cl on cl.id=i.client_id left join public.companies c on c.id=cl.company_id left join public.client_locations loc on loc.id=i.location_id
left join (select invoice_id,sum(amount) paid_total from public.payment_allocations group by invoice_id) p on p.invoice_id=i.id;

create or replace view public.payment_schedule_overview with (security_invoker=true) as
with paid as (select invoice_id,sum(amount) invoice_paid from public.payment_allocations group by invoice_id),
s as (select ps.*,coalesce(sum(ps.amount_due) over(partition by ps.invoice_id order by ps.installment_number rows between unbounded preceding and 1 preceding),0) prior_due from public.payment_schedules ps)
select s.*,i.invoice_number,i.reseller_id,r.name reseller_name,i.client_id,c.company_name client_name,loc.location_name,i.currency,
       greatest(least(coalesce(p.invoice_paid,0)-s.prior_due,s.amount_due),0)::numeric(14,2) paid_amount,
       (s.amount_due-greatest(least(coalesce(p.invoice_paid,0)-s.prior_due,s.amount_due),0))::numeric(14,2) balance,
       case when greatest(least(coalesce(p.invoice_paid,0)-s.prior_due,s.amount_due),0)>=s.amount_due-0.005 then 'paid'
            when greatest(least(coalesce(p.invoice_paid,0)-s.prior_due,s.amount_due),0)>0 then 'partially_paid'
            when s.due_date<current_date then 'overdue'
            when s.due_date=current_date then 'due' else 'upcoming' end status
from s join public.invoices i on i.id=s.invoice_id join public.resellers r on r.id=i.reseller_id left join paid p on p.invoice_id=i.id left join public.clients cl on cl.id=i.client_id left join public.companies c on c.id=cl.company_id left join public.client_locations loc on loc.id=i.location_id;

create or replace view public.receipt_overview with (security_invoker=true) as
select rc.*,p.paid_at,p.method,p.reference,r.name reseller_name,i.invoice_number
from public.receipts rc join public.payments p on p.id=rc.payment_id join public.resellers r on r.id=rc.reseller_id left join public.payment_allocations pa on pa.payment_id=p.id left join public.invoices i on i.id=pa.invoice_id;

create or replace view public.reseller_statement with (security_invoker=true) as
with entries as (
 select i.reseller_id,i.id entry_id,'invoice'::text entry_type,i.issued_at entry_date,i.invoice_number document_number,coalesce(i.reference,'Invoice') description,i.currency,i.total debit,0::numeric credit from public.invoices i where i.status='issued'
 union all
 select p.reseller_id,p.id,'receipt',p.paid_at,rc.receipt_number,coalesce('Payment - '||p.reference,'Payment'),p.currency,0::numeric,p.amount from public.payments p join public.receipts rc on rc.payment_id=p.id where rc.status='issued'
)
select e.*,r.name reseller_name,sum(e.debit-e.credit) over(partition by e.reseller_id order by e.entry_date,e.entry_type,e.document_number rows unbounded preceding) running_balance
from entries e join public.resellers r on r.id=e.reseller_id;

create or replace view public.reseller_360 with (security_invoker=true) as
select r.id,r.code,r.name,r.country,r.currency,r.status,
 (select count(*) from public.reseller_company_links l where l.reseller_id=r.id) companies,
 (select count(*) from public.clients c where c.reseller_id=r.id and c.status='active') active_clients,
 (select count(*) from public.client_locations l where l.reseller_id=r.id and l.status='active') active_locations,
 (select count(*) from public.renewals x where x.reseller_id=r.id and x.status in ('upcoming','requested','approved','invoiced') and x.expiry_date between current_date and current_date+30) renewals_30d,
 coalesce((select sum(i.total) from public.invoices i where i.reseller_id=r.id and i.status='issued'),0) total_invoiced,
 coalesce((select sum(p.amount) from public.payments p where p.reseller_id=r.id),0) total_paid,
 coalesce((select sum(f.balance) from public.invoice_financials f where f.reseller_id=r.id and f.status='issued'),0) outstanding,
 coalesce((select sum(f.balance) from public.invoice_financials f where f.reseller_id=r.id and f.financial_status='overdue'),0) overdue
from public.resellers r where public.is_platform_admin();

create or replace view public.reseller_finance_summary with (security_invoker=true) as
select r.id reseller_id,r.name reseller_name,r.currency,
 coalesce((select sum(i.total) from public.invoices i where i.reseller_id=r.id and i.status='issued'),0) invoiced,
 coalesce((select sum(p.amount) from public.payments p where p.reseller_id=r.id),0) paid,
 coalesce((select sum(f.balance) from public.invoice_financials f where f.reseller_id=r.id and f.status='issued'),0) outstanding,
 coalesce((select sum(f.balance) from public.invoice_financials f where f.reseller_id=r.id and f.financial_status='overdue'),0) overdue,
 coalesce((select sum(s.balance) from public.payment_schedule_overview s where s.reseller_id=r.id and s.due_date between current_date and current_date+30),0) expected_30d,
 coalesce((select sum(s.balance) from public.payment_schedule_overview s where s.reseller_id=r.id and s.due_date between current_date and current_date+90),0) expected_90d
from public.resellers r where public.is_platform_admin();

-- Helpful indexes
create index if not exists links_reseller_idx on public.reseller_company_links(reseller_id);
create index if not exists contacts_reseller_idx on public.contacts(reseller_id);
create index if not exists leads_reseller_idx on public.leads(reseller_id);
create index if not exists deals_reseller_idx on public.deals(reseller_id);
create index if not exists clients_reseller_idx on public.clients(reseller_id);
create index if not exists licenses_expiry_idx on public.licenses(expiry_date);
create index if not exists renewals_expiry_idx on public.renewals(expiry_date,status);
create index if not exists invoices_reseller_due_idx on public.invoices(reseller_id,due_date);
create index if not exists schedules_due_idx on public.payment_schedules(due_date);
create index if not exists payments_reseller_date_idx on public.payments(reseller_id,paid_at);

-- Function permissions
grant execute on function public.create_or_claim_company(text,text,text,text,text,text,text) to authenticated;
grant execute on function public.approve_service_request(uuid) to authenticated;
grant execute on function public.issue_renewal_invoice(uuid) to authenticated;
grant execute on function public.request_renewal(uuid) to authenticated;
grant execute on function public.record_invoice_payment(uuid,numeric,date,text,text) to authenticated;
grant execute on function public.current_reseller_id() to authenticated;
grant execute on function public.is_platform_admin() to authenticated;

-- View access
grant select on public.shared_company_directory,public.my_company_overview,public.contact_overview,public.lead_overview,public.deal_overview,public.activity_overview,public.client_overview,public.location_license_overview,public.renewal_overview,public.request_overview,public.invoice_financials,public.payment_schedule_overview,public.receipt_overview,public.reseller_statement,public.reseller_360,public.reseller_finance_summary to authenticated;
