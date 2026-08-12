# Reseller360 CRM

A modern React + Supabase reseller CRM and partner-operations platform. It gives each reseller a private CRM while exposing a controlled shared company directory, and connects won business to clients, locations, licences, renewals, invoices, payment schedules, payments, receipts, statements of account and consolidated reseller reporting.

## What is included

- **Authentication & roles:** platform admin, finance, reseller admin and reseller user.
- **Shared Market Directory:** all resellers can see company identity, contacted/not-contacted, current stage, reseller and active-client indicator. Private CRM details stay private.
- **Private CRM:** companies, contacts, leads, deals and activities scoped to each reseller.
- **Client portfolio:** active clients, locations, licences, subscription dates and billing terms.
- **Requests:** reseller submits a new-client or add-location request; admin approval creates the operational records and an invoice.
- **Renewals:** upcoming renewals, reseller requests, admin invoice issuance, and automatic next-cycle creation after full payment.
- **Finance:** invoices, installment schedules, cash forecast, partial payments, receipts and reseller statements of account.
- **Admin views:** Reseller 360 and consolidated finance overview.
- **RLS:** privacy boundaries are enforced in Postgres/Supabase, not only in React.
- **Responsive UI:** desktop/mobile navigation plus light and dark themes.

## Tech stack

- React + TypeScript
- Vite
- Supabase Auth + Postgres + Row Level Security
- React Router
- Lucide icons
- date-fns
- Plain responsive CSS (no UI framework required)

## 1. Create the Supabase project

Create a new Supabase project, then run:

```sql
-- supabase/migrations/001_reseller360.sql
```

You can paste the migration into the Supabase SQL Editor, or use the Supabase CLI migration workflow.

The migration creates the full schema, RLS policies, helper views and these business RPCs:

- `create_or_claim_company`
- `approve_service_request`
- `issue_renewal_invoice`
- `record_invoice_payment`

## 2. Configure the frontend

Copy the environment file:

```bash
cp .env.example .env
```

Then set:

```env
VITE_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
VITE_SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

Use the **anon/publishable browser key**, never the Supabase service-role key in the React app.

## 3. Install and run

```bash
npm install
npm run dev
```

Production build:

```bash
npm run build
```

## 4. Create the first admin

Create a user in **Supabase Authentication → Users**. The database trigger automatically creates a matching `profiles` row.

Then promote that user:

```sql
update public.profiles
set role = 'admin'
where email = 'admin@yourcompany.com';
```

Admin/finance users do not need a `reseller_id`.

## 5. Create a reseller and assign users

Create a reseller:

```sql
insert into public.resellers
  (code, name, legal_name, country, currency, payment_term_days)
values
  ('RSL-001', 'Example Reseller', 'Example Reseller LLC', 'United Arab Emirates', 'USD', 30)
returning id;
```

After creating the reseller's Auth user, assign the profile:

```sql
update public.profiles
set
  reseller_id = 'RESELLER_UUID_HERE',
  role = 'reseller_admin'
where email = 'partner@example.com';
```

Additional team members can use `reseller_user`.

## Privacy model

### Shared across authenticated resellers

- Company name
- Website
- Country/city
- Industry
- Whether a reseller has contacted the company
- Current shared pipeline stage
- Which reseller is handling it
- Whether it is already an active client

### Private to owning reseller + platform admin

- Contacts and their email/phone
- Notes
- Leads
- Deal values and commercial details
- Activities
- Client/location/licence records
- Renewal commercial values
- Requests
- Invoices and schedules
- Payments
- Receipts
- Statements of account

## Commercial flow

```text
Company
  ↓
Lead
  ↓
Deal
  ↓
Won
  ↓
New Client Request / Add Location Request
  ↓
Admin Approval
  ↓
Client + Location + Licence
  ↓
Invoice
  ↓
Payment Schedule
  ↓
Payment
  ↓
Receipt
  ↓
Renewal
  ↓
Renewal Invoice
  ↓
Payment + Receipt
  ↓
Licence extended + next renewal generated
```

## Billing frequency vs payment term

They are deliberately separated:

- **Billing frequency:** annual, semi-annual, quarterly or monthly. This determines how many scheduled installments are created.
- **Payment term:** Due immediately / Net 7 / 14 / 21 / 30. This determines the first installment due date.

For example, a USD 1,200 annual licence billed quarterly on Net 14 produces four USD 300 installments, with the first due 14 days after invoice issuance and the next three at 3-month intervals.

## Receipts and partial payments

`record_invoice_payment` accepts partial payments. Each payment:

1. Creates a payment record.
2. Allocates the amount to the invoice.
3. Issues an `RV/YYYY/00000` receipt.
4. Updates forecast balances automatically through the reporting views.
5. If a renewal invoice becomes fully paid, the licence dates roll forward and the next renewal record is created.

The included UI prevents overpaying an individual invoice. The schema also contains `payment_allocations`, so it can later be extended to allocate one bank transfer across several invoices.

## Request approval behavior

When an admin approves a request, the included RPC currently creates/activates the client/location/licence and issues the invoice immediately. If your commercial rule is **"activate only after payment"**, move the activation step from `approve_service_request` into the full-payment branch of `record_invoice_payment`. The rest of the data model already supports that workflow.

## Document numbering

- Requests: `REQ/YYYY/00001`
- Invoices: `INV/YYYY/00001`
- Receipts: `RV/YYYY/00001`

Counters are stored transactionally in `document_counters`.

## Optional demo data

`supabase/seed.sql` contains two sample resellers and two sample companies. It does not create Auth users. Do not run it in production unless you want demo rows.

## GitHub / CI

A GitHub Actions workflow is included. It installs dependencies and runs the production build on pushes and pull requests.

## Recommended next production additions

The MVP is designed so the following can be added without restructuring the core schema:

- Reseller-specific price lists and product catalogue
- Territory/exclusivity and lead-protection expiry
- Approval levels for special pricing
- Invoice/receipt PDF templates and email delivery
- Credit notes / refunds
- Multi-currency FX handling
- VAT/tax configuration by reseller jurisdiction
- Proof-of-transfer file uploads using Supabase Storage
- Notifications and renewal reminders
- Reseller targets and commission/margin reporting
- One payment allocated across multiple invoices in the UI
- Audit-log viewer

## Security notes

- Never place the Supabase `service_role` key in frontend environment variables.
- Keep RLS enabled when adding new tables.
- For production, review tax, invoice numbering, retention, audit and accounting requirements for the jurisdictions where the platform operates.
