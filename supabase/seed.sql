-- Reseller360 complete demo/static dataset
-- Dates are centered around August 2026 so dashboards, renewals and forecasts look realistic.
-- Run AFTER supabase/migrations/001_reseller360.sql.
-- Create khaled.yakan@incheck360.nl in Supabase Authentication before running this file.

begin;

-- -----------------------------------------------------------------------------
-- Promote the existing Supabase Auth user to platform admin
-- -----------------------------------------------------------------------------
do $$
declare v_admin uuid;
begin
  select id into v_admin
  from public.profiles
  where lower(email)=lower('khaled.yakan@incheck360.nl')
  limit 1;

  if v_admin is null then
    raise exception 'Create khaled.yakan@incheck360.nl in Supabase Authentication first, then rerun supabase/seed.sql';
  end if;

  update public.profiles
  set full_name='Khaled Yakan', role='admin', reseller_id=null, is_active=true
  where id=v_admin;
end $$;

-- Keep auto-generated production numbers away from the demo range.
insert into public.document_counters(doc_type,doc_year,last_number)
values ('INV',2026,9099),('RV',2026,9099),('REQ',2026,9099)
on conflict (doc_type,doc_year)
do update set last_number=greatest(public.document_counters.last_number,excluded.last_number);

-- -----------------------------------------------------------------------------
-- Resellers
-- -----------------------------------------------------------------------------
insert into public.resellers
(id,code,name,legal_name,country,currency,billing_email,payment_term_days,status)
values
('00000000-0000-0000-0000-000000000101','RSL-001','GulfBridge Partners','GulfBridge Partners LLC','United Arab Emirates','USD','billing@gulfbridge.example',30,'active'),
('00000000-0000-0000-0000-000000000102','RSL-002','Cedar Peak Solutions','Cedar Peak Solutions SAL','Lebanon','USD','accounts@cedarpeak.example',14,'active'),
('00000000-0000-0000-0000-000000000103','RSL-003','Northstar Hospitality Tech','Northstar Hospitality Technology LLC','Saudi Arabia','USD','finance@northstar.example',30,'active'),
('00000000-0000-0000-0000-000000000104','RSL-004','Levant Digital Partners','Levant Digital Partners LLC','Jordan','USD','billing@levantdigital.example',21,'active')
on conflict (id) do update set
code=excluded.code,name=excluded.name,legal_name=excluded.legal_name,country=excluded.country,
currency=excluded.currency,billing_email=excluded.billing_email,payment_term_days=excluded.payment_term_days,status=excluded.status;

-- -----------------------------------------------------------------------------
-- Shared company directory
-- -----------------------------------------------------------------------------
insert into public.companies
(id,company_name,legal_name,website,country,city,industry,company_size,linkedin_url)
values
('00000000-0000-0000-0000-000000000201','Atlas Hospitality Group','Atlas Hospitality Group LLC','https://atlas-hospitality.example','United Arab Emirates','Dubai','Hospitality','201-500','https://linkedin.com/company/atlas-hospitality-demo'),
('00000000-0000-0000-0000-000000000202','Cedar Table Restaurants','Cedar Table Restaurants SAL','https://cedartable.example','Lebanon','Beirut','F&B','51-200','https://linkedin.com/company/cedar-table-demo'),
('00000000-0000-0000-0000-000000000203','Riyadh Eats Holding','Riyadh Eats Holding Co','https://riyadheats.example','Saudi Arabia','Riyadh','F&B','501-1000','https://linkedin.com/company/riyadh-eats-demo'),
('00000000-0000-0000-0000-000000000204','Palm Suites Management','Palm Suites Management LLC','https://palmsuites.example','United Arab Emirates','Abu Dhabi','Hospitality','51-200','https://linkedin.com/company/palm-suites-demo'),
('00000000-0000-0000-0000-000000000205','Urban Spoon Collective','Urban Spoon Collective LLC','https://urbanspooncollective.example','United Arab Emirates','Dubai','F&B','51-200','https://linkedin.com/company/urban-spoon-demo'),
('00000000-0000-0000-0000-000000000206','Amman Food Works','Amman Food Works LLC','https://ammanfoodworks.example','Jordan','Amman','F&B','11-50','https://linkedin.com/company/amman-food-works-demo'),
('00000000-0000-0000-0000-000000000207','Marina Leisure Group','Marina Leisure Group LLC','https://marinaleisure.example','United Arab Emirates','Dubai','Leisure','201-500','https://linkedin.com/company/marina-leisure-demo'),
('00000000-0000-0000-0000-000000000208','Desert Roastery Co','Desert Roastery Company','https://desertroastery.example','Saudi Arabia','Riyadh','Coffee','51-200','https://linkedin.com/company/desert-roastery-demo'),
('00000000-0000-0000-0000-000000000209','Coastal Catering Services','Coastal Catering Services Co','https://coastalcatering.example','Saudi Arabia','Jeddah','Catering','201-500','https://linkedin.com/company/coastal-catering-demo'),
('00000000-0000-0000-0000-000000000210','Beirut Boutique Hotels','Beirut Boutique Hotels SAL','https://beirutboutique.example','Lebanon','Beirut','Hospitality','51-200','https://linkedin.com/company/beirut-boutique-demo'),
('00000000-0000-0000-0000-000000000211','Falcon Facilities Management','Falcon Facilities Management LLC','https://falconfm.example','United Arab Emirates','Abu Dhabi','Facilities Management','201-500','https://linkedin.com/company/falcon-fm-demo'),
('00000000-0000-0000-0000-000000000212','Olive Branch Kitchens','Olive Branch Kitchens LLC','https://olivebranchkitchens.example','Jordan','Amman','Cloud Kitchen','11-50','https://linkedin.com/company/olive-branch-demo')
on conflict (id) do update set
company_name=excluded.company_name,legal_name=excluded.legal_name,website=excluded.website,country=excluded.country,
city=excluded.city,industry=excluded.industry,company_size=excluded.company_size,linkedin_url=excluded.linkedin_url;

-- -----------------------------------------------------------------------------
-- Shared market / reseller ownership links
-- -----------------------------------------------------------------------------
insert into public.reseller_company_links
(id,reseller_id,company_id,stage,contacted,is_active_client)
values
('00000000-0000-0000-0000-000000001701','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000201','won',true,true),
('00000000-0000-0000-0000-000000001702','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000204','won',true,true),
('00000000-0000-0000-0000-000000001703','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000205','proposal',true,false),
('00000000-0000-0000-0000-000000001704','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000207','qualified',true,false),
('00000000-0000-0000-0000-000000001705','00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000202','won',true,true),
('00000000-0000-0000-0000-000000001706','00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000210','negotiation',true,false),
('00000000-0000-0000-0000-000000001707','00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000211','contacted',true,false),
('00000000-0000-0000-0000-000000001708','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000203','won',true,true),
('00000000-0000-0000-0000-000000001709','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000208','won',true,true),
('00000000-0000-0000-0000-000000001710','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000209','won',true,true),
('00000000-0000-0000-0000-000000001711','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000205','engaged',true,false),
('00000000-0000-0000-0000-000000001712','00000000-0000-0000-0000-000000000104','00000000-0000-0000-0000-000000000206','qualified',true,false),
('00000000-0000-0000-0000-000000001713','00000000-0000-0000-0000-000000000104','00000000-0000-0000-0000-000000000212','not_contacted',false,false),
('00000000-0000-0000-0000-000000001714','00000000-0000-0000-0000-000000000104','00000000-0000-0000-0000-000000000210','contacted',true,false)
on conflict (id) do update set
reseller_id=excluded.reseller_id,company_id=excluded.company_id,stage=excluded.stage,contacted=excluded.contacted,is_active_client=excluded.is_active_client;

-- -----------------------------------------------------------------------------
-- Contacts
-- -----------------------------------------------------------------------------
do $$
declare v_admin uuid;
begin
select id into v_admin from public.profiles where lower(email)=lower('khaled.yakan@incheck360.nl') limit 1;
insert into public.contacts
(id,reseller_id,company_id,first_name,last_name,job_title,email,phone,is_decision_maker,notes,created_by)
values
('00000000-0000-0000-0000-000000000301','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000201','Maya','Haddad','Group Operations Director','maya.haddad@atlas-demo.example','+971 50 555 0101',true,'Primary operations decision maker.',v_admin),
('00000000-0000-0000-0000-000000000302','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000205','Omar','Rahman','COO','omar.rahman@urbanspoon-demo.example','+971 50 555 0102',true,'Interested in a multi-location rollout.',v_admin),
('00000000-0000-0000-0000-000000000303','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000207','Sarah','Nasser','Quality Manager','sarah.nasser@marinaleisure-demo.example','+971 50 555 0103',false,'Requested operations discovery.',v_admin),
('00000000-0000-0000-0000-000000000304','00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000202','Rami','Khoury','Managing Director','rami.khoury@cedartable-demo.example','+961 3 555 104',true,'Existing client contact.',v_admin),
('00000000-0000-0000-0000-000000000305','00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000210','Nadine','Saab','General Manager','nadine.saab@beirutboutique-demo.example','+961 3 555 105',true,'Commercial offer under review.',v_admin),
('00000000-0000-0000-0000-000000000306','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000203','Faisal','Al Saud','Head of Operations','faisal@riyadheats-demo.example','+966 55 555 0106',true,'Existing client discussing more branches.',v_admin),
('00000000-0000-0000-0000-000000000307','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000208','Lina','Mansour','Operations Manager','lina@desertroastery-demo.example','+966 55 555 0107',true,'Renewal discussion started.',v_admin),
('00000000-0000-0000-0000-000000000308','00000000-0000-0000-0000-000000000104','00000000-0000-0000-0000-000000000206','Yazan','Haddadin','Founder','yazan@ammanfoodworks-demo.example','+962 7 9555 0108',true,'Qualified for September launch.',v_admin)
on conflict (id) do update set
reseller_id=excluded.reseller_id,company_id=excluded.company_id,first_name=excluded.first_name,last_name=excluded.last_name,
job_title=excluded.job_title,email=excluded.email,phone=excluded.phone,is_decision_maker=excluded.is_decision_maker,notes=excluded.notes,created_by=excluded.created_by;
end $$;

-- -----------------------------------------------------------------------------
-- Leads
-- -----------------------------------------------------------------------------
do $$
declare v_admin uuid;
begin
select id into v_admin from public.profiles where lower(email)=lower('khaled.yakan@incheck360.nl') limit 1;
insert into public.leads
(id,reseller_id,company_id,contact_id,title,source,status,priority,estimated_value,currency,next_follow_up,notes,created_by)
values
('00000000-0000-0000-0000-000000000401','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000205','00000000-0000-0000-0000-000000000302','Urban Spoon rollout','LinkedIn','qualified','high',4200,'USD','2026-08-14','Potential five-location rollout.',v_admin),
('00000000-0000-0000-0000-000000000402','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000207','00000000-0000-0000-0000-000000000303','Marina Leisure digitisation','Referral','contacted','medium',2750,'USD','2026-08-18','Awaiting detailed requirements.',v_admin),
('00000000-0000-0000-0000-000000000403','00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000210','00000000-0000-0000-0000-000000000305','Boutique Hotels quality platform','Event','qualified','high',3600,'USD','2026-08-13','Three hotels in phase one.',v_admin),
('00000000-0000-0000-0000-000000000404','00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000211',null,'Falcon FM inspection workflow','Outbound','contacting','medium',5100,'USD','2026-08-20','Initial outreach completed.',v_admin),
('00000000-0000-0000-0000-000000000405','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000205',null,'Urban Spoon KSA opportunity','Partner referral','contacted','medium',3000,'USD','2026-08-22','Separate KSA opportunity.',v_admin),
('00000000-0000-0000-0000-000000000406','00000000-0000-0000-0000-000000000104','00000000-0000-0000-0000-000000000206','00000000-0000-0000-0000-000000000308','Amman Food Works launch','Website','qualified','urgent',1900,'USD','2026-08-13','Target launch in September.',v_admin),
('00000000-0000-0000-0000-000000000407','00000000-0000-0000-0000-000000000104','00000000-0000-0000-0000-000000000212',null,'Olive Branch prospect','Outbound','new','low',1400,'USD','2026-08-28','Not contacted yet.',v_admin)
on conflict (id) do update set
status=excluded.status,priority=excluded.priority,estimated_value=excluded.estimated_value,next_follow_up=excluded.next_follow_up,notes=excluded.notes,created_by=excluded.created_by;
end $$;

-- -----------------------------------------------------------------------------
-- Deals
-- -----------------------------------------------------------------------------
do $$
declare v_admin uuid;
begin
select id into v_admin from public.profiles where lower(email)=lower('khaled.yakan@incheck360.nl') limit 1;
insert into public.deals
(id,reseller_id,company_id,contact_id,lead_id,name,stage,value,currency,probability,expected_close_date,product_name,location_count,next_action,notes,created_by)
values
('00000000-0000-0000-0000-000000000501','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000205','00000000-0000-0000-0000-000000000302','00000000-0000-0000-0000-000000000401','Urban Spoon - 5 locations','proposal',4200,'USD',70,'2026-08-25','InCheck Full',5,'Follow up on proposal approval','Demo completed.',v_admin),
('00000000-0000-0000-0000-000000000502','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000207','00000000-0000-0000-0000-000000000303','00000000-0000-0000-0000-000000000402','Marina Leisure pilot','qualified',2750,'USD',45,'2026-09-10','InCheck Full',3,'Schedule discovery workshop','Pilot scope being defined.',v_admin),
('00000000-0000-0000-0000-000000000503','00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000210','00000000-0000-0000-0000-000000000305','00000000-0000-0000-0000-000000000403','Beirut Boutique Hotels','negotiation',3600,'USD',80,'2026-08-21','InCheck Full',3,'Confirm commercial terms','Final pricing requested.',v_admin),
('00000000-0000-0000-0000-000000000504','00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000211',null,'00000000-0000-0000-0000-000000000404','Falcon FM inspection solution','discovery',5100,'USD',25,'2026-10-01','InCheck Full',6,'Identify decision maker','Early-stage facilities use case.',v_admin),
('00000000-0000-0000-0000-000000000505','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000205',null,'00000000-0000-0000-0000-000000000405','Urban Spoon KSA expansion','demo',3000,'USD',55,'2026-09-05','InCheck Full',4,'Run product demo','Demo booked.',v_admin),
('00000000-0000-0000-0000-000000000506','00000000-0000-0000-0000-000000000104','00000000-0000-0000-0000-000000000206','00000000-0000-0000-0000-000000000308','00000000-0000-0000-0000-000000000406','Amman Food Works launch','qualified',1900,'USD',65,'2026-08-28','InCheck Basic',2,'Send proposal','Two-location starting package.',v_admin),
('00000000-0000-0000-0000-000000000507','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000201','00000000-0000-0000-0000-000000000301',null,'Atlas initial rollout','won',2475,'USD',100,'2026-06-15','InCheck Full',3,'Client activated','Historical won deal.',v_admin),
('00000000-0000-0000-0000-000000000508','00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000202','00000000-0000-0000-0000-000000000304',null,'Cedar Table annual renewal','won',1400,'USD',100,'2026-07-01','InCheck Full',2,'Monitor renewal','Historical won deal.',v_admin)
on conflict (id) do update set
stage=excluded.stage,value=excluded.value,probability=excluded.probability,expected_close_date=excluded.expected_close_date,next_action=excluded.next_action,notes=excluded.notes,created_by=excluded.created_by;
end $$;

-- -----------------------------------------------------------------------------
-- Activities
-- -----------------------------------------------------------------------------
do $$
declare v_admin uuid;
begin
select id into v_admin from public.profiles where lower(email)=lower('khaled.yakan@incheck360.nl') limit 1;
insert into public.activities
(id,reseller_id,company_id,contact_id,lead_id,deal_id,activity_type,subject,details,activity_at,next_follow_up,created_by)
values
('00000000-0000-0000-0000-000000000601','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000205','00000000-0000-0000-0000-000000000302','00000000-0000-0000-0000-000000000401','00000000-0000-0000-0000-000000000501','demo','Product demo completed','Covered dashboards and multi-location reporting.','2026-08-10 10:00:00+03','2026-08-14 10:00:00+03',v_admin),
('00000000-0000-0000-0000-000000000602','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000207','00000000-0000-0000-0000-000000000303','00000000-0000-0000-0000-000000000402','00000000-0000-0000-0000-000000000502','call','Discovery call','Discussed quality checks and three sites.','2026-08-09 15:30:00+03','2026-08-18 11:00:00+03',v_admin),
('00000000-0000-0000-0000-000000000603','00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000210','00000000-0000-0000-0000-000000000305','00000000-0000-0000-0000-000000000403','00000000-0000-0000-0000-000000000503','email','Final pricing shared','Revised commercial offer sent.','2026-08-11 09:15:00+03','2026-08-13 12:00:00+03',v_admin),
('00000000-0000-0000-0000-000000000604','00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000211',null,'00000000-0000-0000-0000-000000000404','00000000-0000-0000-0000-000000000504','linkedin','Initial outreach sent','Introductory LinkedIn message sent.','2026-08-08 14:00:00+03','2026-08-20 10:00:00+03',v_admin),
('00000000-0000-0000-0000-000000000605','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000205',null,'00000000-0000-0000-0000-000000000405','00000000-0000-0000-0000-000000000505','meeting','KSA discovery meeting','KSA team requested a dedicated demo.','2026-08-11 13:00:00+03','2026-08-22 13:00:00+03',v_admin),
('00000000-0000-0000-0000-000000000606','00000000-0000-0000-0000-000000000104','00000000-0000-0000-0000-000000000206','00000000-0000-0000-0000-000000000308','00000000-0000-0000-0000-000000000406','00000000-0000-0000-0000-000000000506','whatsapp','Launch timing confirmed','Client wants September implementation.','2026-08-12 09:00:00+03','2026-08-13 09:00:00+03',v_admin),
('00000000-0000-0000-0000-000000000607','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000208','00000000-0000-0000-0000-000000000307',null,null,'follow_up','Renewal follow-up','Renewal confirmation requested.','2026-08-12 10:30:00+03','2026-08-17 10:30:00+03',v_admin)
on conflict (id) do update set
activity_type=excluded.activity_type,subject=excluded.subject,details=excluded.details,activity_at=excluded.activity_at,next_follow_up=excluded.next_follow_up,created_by=excluded.created_by;
end $$;

-- -----------------------------------------------------------------------------
-- Clients
-- -----------------------------------------------------------------------------
insert into public.clients(id,reseller_id,company_id,status,activated_at)
values
('00000000-0000-0000-0000-000000000701','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000201','active','2025-09-01'),
('00000000-0000-0000-0000-000000000702','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000204','active','2026-01-01'),
('00000000-0000-0000-0000-000000000703','00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000202','active','2025-08-21'),
('00000000-0000-0000-0000-000000000704','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000203','active','2025-10-01'),
('00000000-0000-0000-0000-000000000705','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000208','active','2025-09-16'),
('00000000-0000-0000-0000-000000000706','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000209','active','2025-07-31')
on conflict (id) do update set status=excluded.status,activated_at=excluded.activated_at;

-- -----------------------------------------------------------------------------
-- Client locations
-- -----------------------------------------------------------------------------
insert into public.client_locations
(id,reseller_id,client_id,location_name,country,city,address,status,activated_at)
values
('00000000-0000-0000-0000-000000000801','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000701','Atlas Downtown','United Arab Emirates','Dubai','Downtown Dubai','active','2025-09-01'),
('00000000-0000-0000-0000-000000000802','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000701','Atlas Marina','United Arab Emirates','Dubai','Dubai Marina','active','2025-09-01'),
('00000000-0000-0000-0000-000000000803','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000701','Atlas Business Bay','United Arab Emirates','Dubai','Business Bay','active','2026-02-01'),
('00000000-0000-0000-0000-000000000804','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000702','Palm Suites Corniche','United Arab Emirates','Abu Dhabi','Corniche Road','active','2026-01-01'),
('00000000-0000-0000-0000-000000000805','00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000703','Cedar Table Downtown','Lebanon','Beirut','Beirut Central District','active','2025-08-21'),
('00000000-0000-0000-0000-000000000806','00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000703','Cedar Table Hazmieh','Lebanon','Baabda','Hazmieh','active','2025-11-01'),
('00000000-0000-0000-0000-000000000807','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000704','Riyadh Eats Olaya','Saudi Arabia','Riyadh','Olaya District','active','2025-10-01'),
('00000000-0000-0000-0000-000000000808','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000704','Riyadh Eats KAFD','Saudi Arabia','Riyadh','KAFD','active','2026-03-01'),
('00000000-0000-0000-0000-000000000809','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000705','Desert Roastery Tahlia','Saudi Arabia','Riyadh','Tahlia Street','active','2025-09-16'),
('00000000-0000-0000-0000-000000000810','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000706','Coastal Catering Jeddah','Saudi Arabia','Jeddah','Al Rawdah','active','2025-07-31')
on conflict (id) do update set
reseller_id=excluded.reseller_id,client_id=excluded.client_id,location_name=excluded.location_name,country=excluded.country,city=excluded.city,address=excluded.address,status=excluded.status,activated_at=excluded.activated_at;

-- -----------------------------------------------------------------------------
-- Licences
-- -----------------------------------------------------------------------------
insert into public.licenses
(id,reseller_id,client_id,location_id,product_name,quantity,annual_value,currency,start_date,expiry_date,billing_frequency,payment_term_days,status)
values
('00000000-0000-0000-0000-000000000901','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000701','00000000-0000-0000-0000-000000000801','InCheck Full',1,825,'USD','2025-09-01','2026-08-31','annual',30,'active'),
('00000000-0000-0000-0000-000000000902','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000701','00000000-0000-0000-0000-000000000802','InCheck Full',1,900,'USD','2025-08-21','2026-08-20','quarterly',14,'active'),
('00000000-0000-0000-0000-000000000903','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000701','00000000-0000-0000-0000-000000000803','InCheck Basic',1,450,'USD','2026-02-01','2027-01-31','annual',30,'active'),
('00000000-0000-0000-0000-000000000904','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000702','00000000-0000-0000-0000-000000000804','InCheck Full',1,800,'USD','2025-09-01','2026-08-31','annual',30,'active'),
('00000000-0000-0000-0000-000000000905','00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000703','00000000-0000-0000-0000-000000000805','InCheck Full',1,700,'USD','2025-08-21','2026-08-20','semi_annual',14,'active'),
('00000000-0000-0000-0000-000000000906','00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000703','00000000-0000-0000-0000-000000000806','InCheck Basic',1,350,'USD','2025-11-01','2026-10-31','annual',14,'active'),
('00000000-0000-0000-0000-000000000907','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000704','00000000-0000-0000-0000-000000000807','InCheck Full',1,1200,'USD','2025-10-01','2026-09-30','monthly',30,'active'),
('00000000-0000-0000-0000-000000000908','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000704','00000000-0000-0000-0000-000000000808','InCheck Basic',1,500,'USD','2026-03-01','2027-02-28','annual',30,'active'),
('00000000-0000-0000-0000-000000000909','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000705','00000000-0000-0000-0000-000000000809','InCheck Full',1,750,'USD','2025-09-16','2026-09-15','quarterly',30,'active'),
('00000000-0000-0000-0000-000000000910','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000706','00000000-0000-0000-0000-000000000810','InCheck Full',1,1100,'USD','2025-07-31','2026-07-30','annual',30,'expired')
on conflict (id) do update set
product_name=excluded.product_name,quantity=excluded.quantity,annual_value=excluded.annual_value,start_date=excluded.start_date,
expiry_date=excluded.expiry_date,billing_frequency=excluded.billing_frequency,payment_term_days=excluded.payment_term_days,status=excluded.status;

-- -----------------------------------------------------------------------------
-- Renewals are inserted BEFORE renewal invoices, without invoice FK populated yet
-- -----------------------------------------------------------------------------
insert into public.renewals
(id,reseller_id,license_id,expiry_date,renewal_start_date,renewal_expiry_date,renewal_value,currency,billing_frequency,payment_term_days,status,requested_at,invoice_id)
values
('00000000-0000-0000-0000-000000001001','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000901','2026-08-31','2026-09-01','2027-08-31',825,'USD','annual',30,'upcoming',null,null),
('00000000-0000-0000-0000-000000001002','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000902','2026-08-20','2026-08-21','2027-08-20',900,'USD','quarterly',14,'requested','2026-08-10 09:00:00+03',null),
('00000000-0000-0000-0000-000000001003','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000903','2027-01-31','2027-02-01','2028-01-31',450,'USD','annual',30,'upcoming',null,null),
('00000000-0000-0000-0000-000000001004','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000904','2026-08-31','2026-09-01','2027-08-31',800,'USD','annual',30,'invoiced','2026-08-01 10:00:00+03',null),
('00000000-0000-0000-0000-000000001005','00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000905','2026-08-20','2026-08-21','2027-08-20',700,'USD','semi_annual',14,'requested','2026-08-08 11:00:00+03',null),
('00000000-0000-0000-0000-000000001006','00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000906','2026-10-31','2026-11-01','2027-10-31',350,'USD','annual',14,'upcoming',null,null),
('00000000-0000-0000-0000-000000001007','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000907','2026-09-30','2026-10-01','2027-09-30',1200,'USD','monthly',30,'upcoming',null,null),
('00000000-0000-0000-0000-000000001008','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000908','2027-02-28','2027-03-01','2028-02-29',500,'USD','annual',30,'upcoming',null,null),
('00000000-0000-0000-0000-000000001009','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000909','2026-09-15','2026-09-16','2027-09-15',750,'USD','quarterly',30,'invoiced','2026-08-02 10:00:00+03',null),
('00000000-0000-0000-0000-000000001010','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000910','2026-07-30','2026-07-31','2027-07-30',1100,'USD','annual',30,'not_renewing','2026-07-15 10:00:00+03',null)
on conflict (id) do update set
renewal_value=excluded.renewal_value,status=excluded.status,requested_at=excluded.requested_at,renewal_start_date=excluded.renewal_start_date,renewal_expiry_date=excluded.renewal_expiry_date;

-- -----------------------------------------------------------------------------
-- Invoices
-- -----------------------------------------------------------------------------
do $$
declare v_admin uuid;
begin
select id into v_admin from public.profiles where lower(email)=lower('khaled.yakan@incheck360.nl') limit 1;
insert into public.invoices
(id,invoice_number,reseller_id,client_id,location_id,source_type,source_id,reference,currency,subtotal,tax,total,issued_at,due_date,billing_frequency,payment_term_days,status,notes,created_by)
values
('00000000-0000-0000-0000-000000001101','INV/2026/09001','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000701','00000000-0000-0000-0000-000000000801','manual',null,'Atlas Downtown annual licence','USD',825,0,825,'2026-07-01','2026-07-31','annual',30,'issued','Paid in full demo invoice.',v_admin),
('00000000-0000-0000-0000-000000001102','INV/2026/09002','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000701','00000000-0000-0000-0000-000000000802','manual',null,'Atlas Marina quarterly billing','USD',900,0,900,'2026-08-01','2026-08-15','quarterly',14,'issued','First installment received.',v_admin),
('00000000-0000-0000-0000-000000001103','INV/2026/09003','00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000703','00000000-0000-0000-0000-000000000805','manual',null,'Cedar Table semi-annual licence','USD',700,0,700,'2026-07-20','2026-08-03','semi_annual',14,'issued','First installment received.',v_admin),
('00000000-0000-0000-0000-000000001104','INV/2026/09004','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000704','00000000-0000-0000-0000-000000000807','manual',null,'Riyadh Eats monthly subscription','USD',1200,0,1200,'2026-07-11','2026-08-10','monthly',30,'issued','Monthly schedule example.',v_admin),
('00000000-0000-0000-0000-000000001105','INV/2026/09005','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000702','00000000-0000-0000-0000-000000000804','renewal','00000000-0000-0000-0000-000000001004','Palm Suites renewal','USD',800,0,800,'2026-07-26','2026-08-25','annual',30,'issued','Renewal awaiting payment.',v_admin),
('00000000-0000-0000-0000-000000001106','INV/2026/09006','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000705','00000000-0000-0000-0000-000000000809','renewal','00000000-0000-0000-0000-000000001009','Desert Roastery renewal','USD',750,0,750,'2026-08-02','2026-09-01','quarterly',30,'issued','Quarterly renewal billing.',v_admin),
('00000000-0000-0000-0000-000000001107','INV/2026/09007','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000706','00000000-0000-0000-0000-000000000810','manual',null,'Coastal Catering annual licence','USD',1100,0,1100,'2026-06-30','2026-07-30','annual',30,'issued','Partial payment received.',v_admin),
('00000000-0000-0000-0000-000000001108','INV/2026/09008','00000000-0000-0000-0000-000000000104',null,null,'manual',null,'Reseller onboarding and enablement','USD',500,0,500,'2026-08-15','2026-09-05','annual',21,'issued','Direct reseller invoice.',v_admin)
on conflict (id) do update set
invoice_number=excluded.invoice_number,reseller_id=excluded.reseller_id,client_id=excluded.client_id,location_id=excluded.location_id,
source_type=excluded.source_type,source_id=excluded.source_id,reference=excluded.reference,subtotal=excluded.subtotal,tax=excluded.tax,total=excluded.total,
issued_at=excluded.issued_at,due_date=excluded.due_date,billing_frequency=excluded.billing_frequency,payment_term_days=excluded.payment_term_days,status=excluded.status,notes=excluded.notes,created_by=excluded.created_by;
end $$;

-- Link renewal rows to their now-existing invoices.
update public.renewals set invoice_id='00000000-0000-0000-0000-000000001105' where id='00000000-0000-0000-0000-000000001004';
update public.renewals set invoice_id='00000000-0000-0000-0000-000000001106' where id='00000000-0000-0000-0000-000000001009';

-- Invoice items
insert into public.invoice_items(id,invoice_id,description,quantity,unit_price)
values
('00000000-0000-0000-0000-000000001201','00000000-0000-0000-0000-000000001101','InCheck Full - Atlas Downtown',1,825),
('00000000-0000-0000-0000-000000001202','00000000-0000-0000-0000-000000001102','InCheck Full - Atlas Marina',1,900),
('00000000-0000-0000-0000-000000001203','00000000-0000-0000-0000-000000001103','InCheck Full - Cedar Table Downtown',1,700),
('00000000-0000-0000-0000-000000001204','00000000-0000-0000-0000-000000001104','InCheck Full - Riyadh Eats Olaya',1,1200),
('00000000-0000-0000-0000-000000001205','00000000-0000-0000-0000-000000001105','Renewal - Palm Suites Corniche',1,800),
('00000000-0000-0000-0000-000000001206','00000000-0000-0000-0000-000000001106','Renewal - Desert Roastery Tahlia',1,750),
('00000000-0000-0000-0000-000000001207','00000000-0000-0000-0000-000000001107','InCheck Full - Coastal Catering Jeddah',1,1100),
('00000000-0000-0000-0000-000000001208','00000000-0000-0000-0000-000000001108','Reseller onboarding & enablement',1,500)
on conflict (id) do update set description=excluded.description,quantity=excluded.quantity,unit_price=excluded.unit_price;

-- -----------------------------------------------------------------------------
-- Payment schedules
-- -----------------------------------------------------------------------------
insert into public.payment_schedules(id,invoice_id,installment_number,installment_count,due_date,amount_due)
values
('00000000-0000-0000-0000-000000001301','00000000-0000-0000-0000-000000001101',1,1,'2026-07-31',825),
('00000000-0000-0000-0000-000000001302','00000000-0000-0000-0000-000000001102',1,4,'2026-08-15',225),
('00000000-0000-0000-0000-000000001303','00000000-0000-0000-0000-000000001102',2,4,'2026-11-15',225),
('00000000-0000-0000-0000-000000001304','00000000-0000-0000-0000-000000001102',3,4,'2027-02-15',225),
('00000000-0000-0000-0000-000000001305','00000000-0000-0000-0000-000000001102',4,4,'2027-05-15',225),
('00000000-0000-0000-0000-000000001306','00000000-0000-0000-0000-000000001103',1,2,'2026-08-03',350),
('00000000-0000-0000-0000-000000001307','00000000-0000-0000-0000-000000001103',2,2,'2027-02-03',350),
('00000000-0000-0000-0000-000000001308','00000000-0000-0000-0000-000000001104',1,12,'2026-08-10',100),
('00000000-0000-0000-0000-000000001309','00000000-0000-0000-0000-000000001104',2,12,'2026-09-10',100),
('00000000-0000-0000-0000-000000001310','00000000-0000-0000-0000-000000001104',3,12,'2026-10-10',100),
('00000000-0000-0000-0000-000000001311','00000000-0000-0000-0000-000000001104',4,12,'2026-11-10',100),
('00000000-0000-0000-0000-000000001312','00000000-0000-0000-0000-000000001104',5,12,'2026-12-10',100),
('00000000-0000-0000-0000-000000001313','00000000-0000-0000-0000-000000001104',6,12,'2027-01-10',100),
('00000000-0000-0000-0000-000000001314','00000000-0000-0000-0000-000000001104',7,12,'2027-02-10',100),
('00000000-0000-0000-0000-000000001315','00000000-0000-0000-0000-000000001104',8,12,'2027-03-10',100),
('00000000-0000-0000-0000-000000001316','00000000-0000-0000-0000-000000001104',9,12,'2027-04-10',100),
('00000000-0000-0000-0000-000000001317','00000000-0000-0000-0000-000000001104',10,12,'2027-05-10',100),
('00000000-0000-0000-0000-000000001318','00000000-0000-0000-0000-000000001104',11,12,'2027-06-10',100),
('00000000-0000-0000-0000-000000001319','00000000-0000-0000-0000-000000001104',12,12,'2027-07-10',100),
('00000000-0000-0000-0000-000000001320','00000000-0000-0000-0000-000000001105',1,1,'2026-08-25',800),
('00000000-0000-0000-0000-000000001321','00000000-0000-0000-0000-000000001106',1,4,'2026-09-01',187.50),
('00000000-0000-0000-0000-000000001322','00000000-0000-0000-0000-000000001106',2,4,'2026-12-01',187.50),
('00000000-0000-0000-0000-000000001323','00000000-0000-0000-0000-000000001106',3,4,'2027-03-01',187.50),
('00000000-0000-0000-0000-000000001324','00000000-0000-0000-0000-000000001106',4,4,'2027-06-01',187.50),
('00000000-0000-0000-0000-000000001325','00000000-0000-0000-0000-000000001107',1,1,'2026-07-30',1100),
('00000000-0000-0000-0000-000000001326','00000000-0000-0000-0000-000000001108',1,1,'2026-09-05',500)
on conflict (id) do update set due_date=excluded.due_date,amount_due=excluded.amount_due,installment_number=excluded.installment_number,installment_count=excluded.installment_count;

-- -----------------------------------------------------------------------------
-- Payments
-- -----------------------------------------------------------------------------
do $$
declare v_admin uuid;
begin
select id into v_admin from public.profiles where lower(email)=lower('khaled.yakan@incheck360.nl') limit 1;
insert into public.payments(id,reseller_id,amount,currency,paid_at,method,reference,notes,created_by)
values
('00000000-0000-0000-0000-000000001401','00000000-0000-0000-0000-000000000101',825,'USD','2026-08-02','bank_transfer','GB-TRX-0802-01','Full settlement of Atlas Downtown.',v_admin),
('00000000-0000-0000-0000-000000001402','00000000-0000-0000-0000-000000000101',225,'USD','2026-08-11','bank_transfer','GB-TRX-0811-02','First quarterly installment.',v_admin),
('00000000-0000-0000-0000-000000001403','00000000-0000-0000-0000-000000000102',350,'USD','2026-08-03','bank_transfer','CP-TRX-0803-01','First semi-annual installment.',v_admin),
('00000000-0000-0000-0000-000000001404','00000000-0000-0000-0000-000000000103',600,'USD','2026-07-25','bank_transfer','NS-TRX-0725-03','Partial payment against Coastal Catering.',v_admin),
('00000000-0000-0000-0000-000000001405','00000000-0000-0000-0000-000000000103',100,'USD','2026-08-10','bank_transfer','NS-TRX-0810-04','First monthly installment for Riyadh Eats.',v_admin)
on conflict (id) do update set amount=excluded.amount,paid_at=excluded.paid_at,method=excluded.method,reference=excluded.reference,notes=excluded.notes,created_by=excluded.created_by;
end $$;

insert into public.payment_allocations(id,payment_id,invoice_id,amount)
values
('00000000-0000-0000-0000-000000001451','00000000-0000-0000-0000-000000001401','00000000-0000-0000-0000-000000001101',825),
('00000000-0000-0000-0000-000000001452','00000000-0000-0000-0000-000000001402','00000000-0000-0000-0000-000000001102',225),
('00000000-0000-0000-0000-000000001453','00000000-0000-0000-0000-000000001403','00000000-0000-0000-0000-000000001103',350),
('00000000-0000-0000-0000-000000001454','00000000-0000-0000-0000-000000001404','00000000-0000-0000-0000-000000001107',600),
('00000000-0000-0000-0000-000000001455','00000000-0000-0000-0000-000000001405','00000000-0000-0000-0000-000000001104',100)
on conflict (id) do update set amount=excluded.amount;

-- Receipts

do $$
declare v_admin uuid;
begin
select id into v_admin from public.profiles where lower(email)=lower('khaled.yakan@incheck360.nl') limit 1;
insert into public.receipts(id,receipt_number,payment_id,reseller_id,amount,currency,issued_at,status,created_by)
values
('00000000-0000-0000-0000-000000001501','RV/2026/09001','00000000-0000-0000-0000-000000001401','00000000-0000-0000-0000-000000000101',825,'USD','2026-08-02','issued',v_admin),
('00000000-0000-0000-0000-000000001502','RV/2026/09002','00000000-0000-0000-0000-000000001402','00000000-0000-0000-0000-000000000101',225,'USD','2026-08-11','issued',v_admin),
('00000000-0000-0000-0000-000000001503','RV/2026/09003','00000000-0000-0000-0000-000000001403','00000000-0000-0000-0000-000000000102',350,'USD','2026-08-03','issued',v_admin),
('00000000-0000-0000-0000-000000001504','RV/2026/09004','00000000-0000-0000-0000-000000001404','00000000-0000-0000-0000-000000000103',600,'USD','2026-07-25','issued',v_admin),
('00000000-0000-0000-0000-000000001505','RV/2026/09005','00000000-0000-0000-0000-000000001405','00000000-0000-0000-0000-000000000103',100,'USD','2026-08-10','issued',v_admin)
on conflict (id) do update set receipt_number=excluded.receipt_number,amount=excluded.amount,issued_at=excluded.issued_at,status=excluded.status,created_by=excluded.created_by;
end $$;

-- -----------------------------------------------------------------------------
-- Service requests: pending, approved, rejected and fulfilled examples
-- -----------------------------------------------------------------------------
do $$
declare v_admin uuid;
begin
select id into v_admin from public.profiles where lower(email)=lower('khaled.yakan@incheck360.nl') limit 1;
insert into public.service_requests
(id,request_number,reseller_id,requested_by,request_type,company_id,client_id,location_name,country,city,product_name,quantity,unit_price,setup_fee,currency,start_date,billing_frequency,payment_term_days,notes,admin_notes,status,invoice_id,reviewed_at)
values
('00000000-0000-0000-0000-000000001601','REQ/2026/09001','00000000-0000-0000-0000-000000000101',v_admin,'new_client','00000000-0000-0000-0000-000000000205',null,'Urban Spoon - Dubai Hills','United Arab Emirates','Dubai','InCheck Full',1,825,160,'USD','2026-09-01','annual',30,'New client request after successful demo.',null,'pending',null,null),
('00000000-0000-0000-0000-000000001602','REQ/2026/09002','00000000-0000-0000-0000-000000000101',v_admin,'add_location',null,'00000000-0000-0000-0000-000000000701','Atlas Jumeirah','United Arab Emirates','Dubai','InCheck Full',1,825,125,'USD','2026-09-15','annual',30,'Existing client expansion.',null,'pending',null,null),
('00000000-0000-0000-0000-000000001603','REQ/2026/09003','00000000-0000-0000-0000-000000000104',v_admin,'new_client','00000000-0000-0000-0000-000000000212',null,'Olive Branch - Abdoun','Jordan','Amman','InCheck Basic',1,350,75,'USD','2026-09-01','annual',21,'Submitted before qualification.','Further qualification required.','rejected',null,'2026-08-09 12:00:00+03'),
('00000000-0000-0000-0000-000000001604','REQ/2026/09004','00000000-0000-0000-0000-000000000102',v_admin,'add_location',null,'00000000-0000-0000-0000-000000000703','Cedar Table Hazmieh','Lebanon','Baabda','InCheck Basic',1,350,100,'USD','2025-11-01','annual',14,'Historical fulfilled request.','Approved and activated.','fulfilled','00000000-0000-0000-0000-000000001103','2025-10-20 10:00:00+03'),
('00000000-0000-0000-0000-000000001605','REQ/2026/09005','00000000-0000-0000-0000-000000000104',v_admin,'new_client','00000000-0000-0000-0000-000000000206',null,'Amman Food Works - Abdoun','Jordan','Amman','InCheck Basic',2,700,125,'USD','2026-09-01','annual',21,'Two-location starting package.',null,'pending',null,null),
('00000000-0000-0000-0000-000000001606','REQ/2026/09006','00000000-0000-0000-0000-000000000103',v_admin,'add_location',null,'00000000-0000-0000-0000-000000000704','Riyadh Eats - Nakheel Mall','Saudi Arabia','Riyadh','InCheck Full',1,1200,160,'USD','2026-09-01','monthly',30,'Expansion location request.','Commercials approved; invoice preparation pending.','approved',null,'2026-08-11 15:00:00+03')
on conflict (id) do update set
status=excluded.status,notes=excluded.notes,admin_notes=excluded.admin_notes,invoice_id=excluded.invoice_id,reviewed_at=excluded.reviewed_at,requested_by=excluded.requested_by;
end $$;

-- -----------------------------------------------------------------------------
-- Audit history
-- -----------------------------------------------------------------------------
delete from public.audit_logs where details->>'demo_seed'='true';

do $$
declare v_admin uuid;
begin
select id into v_admin from public.profiles where lower(email)=lower('khaled.yakan@incheck360.nl') limit 1;
insert into public.audit_logs(actor_id,reseller_id,action,entity_type,entity_id,details,created_at)
values
(v_admin,'00000000-0000-0000-0000-000000000101','create','deal','00000000-0000-0000-0000-000000000501','{"demo_seed":"true","summary":"Urban Spoon opportunity created"}'::jsonb,'2026-08-05 10:00:00+03'),
(v_admin,'00000000-0000-0000-0000-000000000102','update','deal','00000000-0000-0000-0000-000000000503','{"demo_seed":"true","summary":"Deal moved to negotiation"}'::jsonb,'2026-08-11 09:00:00+03'),
(v_admin,'00000000-0000-0000-0000-000000000101','record_payment','invoice','00000000-0000-0000-0000-000000001101','{"demo_seed":"true","amount":825}'::jsonb,'2026-08-02 12:00:00+03'),
(v_admin,'00000000-0000-0000-0000-000000000103','record_payment','invoice','00000000-0000-0000-0000-000000001107','{"demo_seed":"true","amount":600}'::jsonb,'2026-07-25 11:00:00+03'),
(v_admin,'00000000-0000-0000-0000-000000000104','reject','service_request','00000000-0000-0000-0000-000000001603','{"demo_seed":"true","reason":"Further qualification required"}'::jsonb,'2026-08-09 12:00:00+03');
end $$;

commit;

-- -----------------------------------------------------------------------------
-- Optional reseller login setup
-- -----------------------------------------------------------------------------
-- The seed does NOT create passwords directly in auth.users.
-- To test reseller-specific visibility, create an Auth user, then run for example:
--
-- update public.profiles
-- set full_name='Demo GulfBridge User', role='reseller_admin',
--     reseller_id='00000000-0000-0000-0000-000000000101'
-- where email='partner@example.com';
--
-- Demo reseller IDs:
-- GulfBridge Partners          00000000-0000-0000-0000-000000000101
-- Cedar Peak Solutions         00000000-0000-0000-0000-000000000102
-- Northstar Hospitality Tech   00000000-0000-0000-0000-000000000103
-- Levant Digital Partners      00000000-0000-0000-0000-000000000104
