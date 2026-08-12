-- OPTIONAL demo seed. Do not run in production unless you want sample resellers/companies.
insert into public.resellers(code,name,legal_name,country,currency,payment_term_days)
values
 ('RSL-A','Blue Horizon Partners','Blue Horizon Partners LLC','United Arab Emirates','USD',30),
 ('RSL-B','Northstar Solutions','Northstar Solutions Ltd','Saudi Arabia','USD',14)
on conflict(code) do nothing;

insert into public.companies(company_name,website,country,city,industry)
values
 ('Demo Hospitality Group','https://example.com','United Arab Emirates','Dubai','Hospitality'),
 ('Demo Restaurant Holdings','https://example.org','Saudi Arabia','Riyadh','F&B')
on conflict do nothing;
