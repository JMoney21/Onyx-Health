# Onyx Health — Complete Website

Full Next.js project, including the new family-health homepage, your selected logo, patient dashboard, patient sign-in, and the existing provider/EHR workspace. This is a complete project, not an update patch.

## What is included
- Public homepage: `/`
- Patient dashboard: `/portal`
- Patient sign-in: `/portal/login`
- Staff sign-in: `/login`
- Existing provider dashboard, schedule, patients, charts, and encounters
- Supabase client and existing SQL files
- All images, styles, package.json, TypeScript configuration, and Netlify settings

## Deploy on Netlify
This ZIP contains source code. Netlify Drop does not build a Next.js source project.

1. Extract this ZIP into a folder. `package.json`, `app`, `public`, `lib`, and `netlify.toml` should be at the folder root.
2. Upload the complete folder contents to a private GitHub repository. Include the project contents, not an extra enclosing folder.
3. In your existing Netlify project, connect that repository through its repository/build settings.
4. Use `npm run build` as the build command and `.next` as the publish directory. Node 20 is already specified in netlify.toml.
5. Preserve your existing Netlify environment variables and Supabase project. The supplied client retains the connection from your previous website package. If your current live connection differs, retain your current lib/supabase.ts instead.
6. Deploy, then check `/`, `/portal/login`, and `/portal`.

## Local use
Install Node.js, open a terminal in this folder, then run:

```sh
npm install
npm run dev
```

To verify a production build locally:

```sh
npm run build
```

## Existing accounts and patient charts
This project does not include patient records. Data remains in your existing Supabase database. Do not rerun the old SQL files or reset your database. For the new visit-vitals feature, run ONLY `supabase/v6_portal_vitals.sql` once in your existing Supabase SQL Editor after the existing v5 migration is installed. It adds patient read access to vitals for their own signed encounters; it does not delete records. The previously reported patient-authentication-to-chart linking problem is not fixed by the visual redesign.

## Validation
The homepage and interactive sample portal preview were published separately. Preview JavaScript syntax, assets, internal destinations, and archive contents were checked. A full Next.js build and live Supabase sign-in were not verified in this workspace.

## Expanded patient portal
- Open appointments for date/time, status, visit type, duration, location, and reason.
- Open signed visits for blood pressure, pulse, temperature, oxygen saturation, respiratory rate, weight, and height.
- View all measurement sets recorded for a visit, plus the clinician’s history, review of symptoms, exam, assessment, care plan, and follow-up.
- Print a visit summary.
- Dark green/gold headers, interactive cards, and responsive care timeline.
- Empty values say “Not recorded”; no sample values are added to real patient charts.

Deployment validation: source structure, field mappings, patient-scoped queries, and ZIP integrity checked. Production build, live patient permissions, and browser layout still need verification in your connected environment. Verify with two separate patient accounts that each sees only their own signed visits/vitals, that draft visits remain unavailable, and that a signed visit without measurements shows its empty state.

## Matching provider workspace
Provider/staff sign-in and all existing provider screens now match the patient portal’s ivory, sage, dark green, and gold design. Includes mobile navigation, sign-out, staff-role verification, matching charts, schedule, encounters, and clinical forms. Existing Supabase row-level policies remain responsible for data authorization. No additional SQL is needed for these provider styling changes.

Check after deployment: provider/staff login, patient-account rejection at staff login, sign-out, mobile navigation, patient search, schedule actions, encounter save/sign, and chart tabs. Full build and live authentication still require verification in the connected deployment environment.

## Visit and note templates
The encounter editor includes Primary care, Acute concern, Follow-up, Annual wellness/preventive, Chronic condition follow-up, Medication management, Telehealth, and Results review templates. Choose a template and click Insert into empty sections. Existing text is preserved. Choose Custom/free text to write your own structured note. Templates are editable prompts, not prefilled clinical findings. Replace unused prompts before saving/signing.

Save draft persists edits. Save & sign saves the current note before signing. Saving vitals does not reset unsaved note edits. An unsaved-changes indicator and browser close/reload warning are included. Signed notes remain locked. No new SQL or dependencies are needed for templates. Template insertion and note-preservation logic were checked; production build and live save/sign still require verification.

## Send-out laboratory workflow
NEW REQUIRED SETUP: Run ONLY `supabase/v7_sendout_labs.sql` in your existing Supabase SQL Editor before using the new Labs workspace. Existing v5 patient identity functions are required. This adds lab_sendouts, patient access policies, review permissions, timestamps, and released-result locking; it does not remove patient records or replace existing lab_orders/lab_results.

Open Provider > Labs, choose a patient, or open the patient chart > Labs. Save a local order with the contracted laboratory, its test code, ordering clinician, specimen type, and lab-provided handling instructions. Submit using the laboratory’s approved portal/requisition separately. Mark collection and courier handoff, enter results exactly as reported, then an authorized provider/owner/admin can review and release results to the patient portal. Nurse/MA staff can track collection and enter reported results; other staff can read.

Printing produces an Onyx collection worksheet and local specimen label, not a lab-approved electronic requisition or lab barcode. Use the lab’s approved requisitions and barcode labels where required. Critical-result communication is still handled by your clinical team and performing laboratory; this tracker does not automatically alert or notify anyone.

Quest/Labcorp electronic ordering, pickup booking, live result delivery, and insurance billing are NOT connected. No payment is processed by the selected billing-arrangement field. Vendor accounts, contracts and approved interfaces are needed for live integration.

Validation: source import checks, migration scope, patient-access predicates, review guards, released-result lock, concurrent-update guards, and ZIP integrity checked. Full Next.js build, browser layout, and live SQL/permissions were not verified here. After deployment test with synthetic data: create > collect > send > enter results > review > release; verify only the matching patient sees released results.

## Prescription drafting workspace
Run ONLY `supabase/v8_prescription_drafts.sql` in your existing Supabase SQL Editor before using Provider > Prescriptions or the patient chart > Prescriptions. It adds a separate draft table, staff policies, review guards and locks. No existing medications or requests are removed.

Create a draft with medication, strength, dose, route, frequency, directions, quantity, refills and pharmacy. Clinical staff can prepare drafts; provider/owner/admin roles can review. Verify that only appropriately authorized licensed prescribers receive those privileges in your organization. Edits to reviewed records require returning to draft and another review. Complete actual prescribing through your approved external prescribing system, then record the system name and confirmation reference locally. Recorded submissions are locked and do not verify pharmacy receipt.

This release does NOT electronically prescribe, cancel pharmacy prescriptions, provide interaction/allergy checks, verify drug products, query medication history/PDMP, or provide controlled-substance EPCS. DoseSpot or another approved prescribing integration must be contracted and configured for those capabilities. Patient medication lists/refill requests remain separate; drafts are not automatically treated as active medications.

Checked source imports, query scope, review guards, submission locks, concurrent-update guards and ZIP contents. Production build, browser layout and live database permissions remain to be verified. Test synthetic drafts with separate staff roles before live use.

## Telehealth appointment links
Run ONLY `supabase/v9_telehealth.sql` in your existing Supabase SQL Editor. It adds appointment-scoped participant links and patient read policies; no existing records are removed. Your existing appointments must have the visit_mode field used by the provider schedule and prior website.

A low-cost option is a Doxy.me Free provider account. Generate/download its BAA and confirm coverage for your organization; individual-provider agreements do not automatically cover multiple providers. Create virtual appointments in Schedule, then open Provider > Telehealth. Save your approved participant room URL and service name. Do not store host/admin links here. Open patient access when ready. Patients open Appointment details or the next-appointment dashboard card and click Refresh video access to see the join button. Their links open the external video service in a new tab.

Providers host and admit patients using their video-service dashboard. Onyx links do not create rooms, grant host privileges, provide waiting-room controls, or automatically start/end calls. Closing patient access hides the Onyx join link but does not terminate an existing call or revoke a link already copied. Cancelled/completed appointments are excluded by patient database policies. Use external waiting-room/admission controls, especially for reusable provider-room links.

Checked meeting URL validation (HTTPS, no embedded user credentials), source imports, appointment identity predicates, patient access predicates, and ZIP integrity. Production build, video-service connection, browser behavior, and live SQL policies require verification. Test separate patient accounts, disabled/enabled access, cancelled appointments, and an actual camera/microphone session with synthetic data.

## Production build verified October 12, 2026
`npm install` and `npm run build` completed successfully with Next.js 14.2.35, including TypeScript validation and all application routes. package-lock.json is included to retain those dependency versions. Live Netlify deployment and Supabase permissions still require verification. This is the complete source project, not a Netlify Drop output archive.

If Netlify shows a 404: inspect the exact deployment log. Connect the source repository, use npm run build and publish .next, and keep Netlify’s Next.js adapter enabled. Do not manually upload this source ZIP or upload .next alone through Drop. Preserve existing Supabase environment variables. Check the production domain and latest published deployment rather than an old deploy permalink.
