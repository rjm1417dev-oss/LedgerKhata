# AI Register Capture & Digital Khata Import

**Technical Specification and Implementation Plan**
**Target platform:** Flutter mobile application + Supabase/PostgreSQL. The feature is designed around Pakistani
shopkeeper workflows, including handwritten registers using Urdu, Roman Urdu, English, mixed language,
numbers, abbreviations, and informal Khata terminology.
## 1. Problem and Business Context
During busy hours, Pakistani shopkeepers often write customer credit transactions directly into a physical register
because entering every transaction into a mobile application can slow down the counter. Customers leave, and
later—when the shopkeeper has time—the register can be photographed and imported into the digital Khata
system.

The proposed feature allows the shopkeeper to capture a register page, have AI/OCR extract the handwritten
information, match customers and items against the existing tenant database, review and correct the extracted
information, and finally confirm the import into the same Khata business logic used by normal digital entry.
## 2. Existing Khata Business Model
Each customer has a Khata history. Every credit purchase is represented as a separate transaction/row. Multiple
transactions can accumulate over 10, 15, 30 days or longer without rewriting previous rows. A customer may make
a partial payment, leaving an outstanding balance, or pay the full amount and settle the current Khata cycle. After
settlement, a later credit purchase starts a new Khata cycle while historical records remain available.

Example: total outstanding PKR 20,000; customer pays PKR 10,000; remaining PKR 10,000 stays outstanding. If
the customer pays PKR 20,000, the current outstanding cycle is settled. A later purchase starts a new cycle.
## 3. Current Database Context
 | Table | Purpose |
|---|---|
| `tenants` | Shop/tenant information and tenant isolation. |
| `users` | Authenticated users linked to a tenant. |
| `customers` | Tenant customers with name and phone. |
| `items` | Tenant products/items with name, price and unit. |
| `khatas` | Customer Khata transaction/cycle with total, discount, paid and remaining values. |
| `khata_items` | Line items belonging to a Khata, preserving item name/price/quantity/unit. |

The AI feature should extend this model rather than create a second financial system. AI should be an
input/extraction layer; application business logic must remain authoritative for financial calculations and database
writes.
## 4. Recommended Architecture
           Physical Register
                 ↓
           Flutter Camera
                 ↓
           Crop / Rotate / Image Quality Check
                 ↓
           Supabase Storage

              ↓
        AI/OCR Processing Layer
              ↓
        Multilingual Handwriting + Document Understanding
              ↓
        Structured JSON
              ↓
        Validation + Customer/Item Matching
              ↓
        Review & Correction Screen
              ↓
        Shopkeeper Confirmation
              ↓
        Transactional Database Write
              ↓
        `khatas` + `khata_items` + payment records
## 5. Multilingual Pakistani Register Requirement
The recognition pipeline must support Urdu, Roman Urdu, English, mixed-language writing, Arabic/Pakistani
numerals where applicable, dates, abbreviations, and informal shopkeeper terminology. A single row may mix
languages—for example, “2 bori سیمنٹ”, “Ahmed bhai 5 cement bags”, or “جمع 2000”.

Do not translate away the original text. Preserve the original handwritten/extracted text, then create
normalized/semantic representations for matching and business logic.

Examples of semantic normalization include: جمع / jama / jma / paid / payment → payment; ■■■■■ / udhaar /
udhar / credit → credit; باقی / baqi / outstanding → outstanding. This should be contextual normalization, not
blind replacement.
## 6. ML Kit and AI Strategy
Google ML Kit can be useful for on-device text recognition, preprocessing and reducing network dependency, but it
should not be treated as the complete Khata-understanding solution. Handwritten Pakistani registers require
semantic understanding, customer matching, row interpretation, and financial validation.

Recommended strategy: use a provider-agnostic OCR/vision abstraction. ML Kit can be tested as one recognition
layer. A vision-capable AI model can be used where handwriting/document understanding requires it. The rest of
the architecture should not depend tightly on one AI vendor.

Do not fine-tune initially. First collect real register samples, measure recognition accuracy, preserve human
corrections, and only then evaluate whether specialized fine-tuning/custom OCR is justified.
## 7. Import Data Model
Add an import layer separate from the financial tables. A recommended starting point is:
        `register_imports`
        - id
        - tenant_id
        - image_url
        - status
        - ai_model
        - ai_confidence
        - raw_ai_response
        - created_by
        - created_at
        - updated_at

        `register_import_rows`
        - id
        - register_import_id
        - tenant_id
        - row_number
        - customer_name
        - customer_id

        - transaction_date
        - description
        - amount
        - row_type: credit | payment | unknown
        - detected_language: urdu | roman_urdu | english | mixed | unknown
        - ai_confidence
        - extracted_data
        - review_status: pending | approved | edited | rejected
        - created_at
        - updated_at

For a robust payment history, add a `khata_payments` table so multiple partial payments can be recorded as
separate events rather than overwriting one paid_amount value. The existing paid_amount can be retained for
compatibility during migration, but the payment ledger should become the authoritative source.
        `khata_payments`
        - id
        - tenant_id
        - khata_id
        - amount
        - payment_date
        - note
        - created_by
        - created_at
## 8. AI Output Contract
AI must return strict structured JSON, not free-form prose. The server must validate the output against a schema
before using it.
```json
{
            "customer": {
               "name_original": "محمد اسلم",
               "name_normalized": "Muhammad Aslam"
            },
            "transactions": [
               {
                  "date": "2026-10-02",
                  "description_original": "2 bori سیمنٹ",
                  "transaction_type": "credit",
                  "quantity": 2,
                  "unit": "bag",
                  "amount": 5000,
                  "confidence": 0.94
               },
               {
                  "date": "2026-10-03",
                  "description_original": "جمع",
                  "transaction_type": "payment",
                  "amount": 2000,
                  "confidence": 0.97
               }
            ]
        }
```
## 9. Customer and Item Matching
Use a hybrid matching pipeline: exact match → normalized text match → phone match where available → fuzzy
matching → semantic matching → human selection when ambiguous. Matching must always be tenant-scoped.

Do not automatically create or select an ambiguous customer. If “Aslam” matches several customers, the review
screen must ask the shopkeeper to select the correct customer or create a new one.

Use the same principle for items. AI may suggest an existing item, but the shopkeeper should be able to correct it
or explicitly create a new item.
## 10. Human-in-the-Loop Review
The initial production workflow should always be: AI extraction → review → confirmation → database write. Do not
let AI directly post financial transactions.

The review screen should show the detected customer, dates, descriptions, quantities, items, amounts, payment
rows, confidence warnings, calculated total, paid amount and remaining balance. Every extracted field should be
editable.
## 11. Deterministic Financial Logic
AI extracts facts. The backend calculates money. For example, if AI extracts credits totaling PKR 20,000 and
payments totaling PKR 10,000, the backend calculates PKR 10,000 remaining. The backend must not trust an
AI-provided balance.

Use database transactions for confirmation. Creating a Khata, its items, payments, and finalizing the import must
succeed as one atomic operation. If any part fails, roll back the whole operation.
## 12. Duplicate and Idempotency Protection
A shopkeeper may photograph the same page twice or press Confirm more than once. The import workflow must
be idempotent and detect possible duplicates using tenant, image similarity/fingerprint, customer, dates, and
transaction similarity. Confirmation must not create duplicate financial records.
## 13. Image Processing
The capture pipeline should handle perspective distortion, rotation, cropping, shadows, low light, blur warnings and
image quality. Flutter can provide capture/crop/retake controls; server-side processing can standardize the image
before AI extraction.
## 14. Multi-Page Future Support
Design the import model so one import session can eventually contain multiple register pages. The initial
implementation may support one image per import, but the architecture should allow a register_import_pages child
table later without redesigning the financial layer.
## 15. Auditability and AI Improvement
Preserve original image, raw AI response, normalized extraction, human corrections, final confirmed values,
timestamps, user identity and AI model/version. Human corrections become valuable evaluation/training data. Do
not fine-tune from unverified AI output.
## 16. End-to-End User Flow
1. Shopkeeper writes transactions normally in the physical register during busy hours.
2. Later, opens Khata → Import from Register.
3. Captures or selects a register page photo.
4. App checks image quality and lets the user crop/rotate/retake.
5. Image is uploaded to secure tenant-scoped storage.
6. AI/OCR extracts multilingual handwritten content into strict JSON.
7. Backend validates schema, normalizes terms, matches customers/items and detects possible duplicates.
8. Flutter displays a review screen with confidence warnings.
9. Shopkeeper edits anything incorrect and confirms.
10. Backend starts a database transaction and posts the confirmed Khata data.
11. Payment records are stored separately where applicable; balance is calculated by application/database logic.
12. Import is marked confirmed and remains auditable.
## 17. Engineering Standards
 | Area | Practice |
|---|---|
| Mobile | Flutter |
| Database | PostgreSQL / Supabase |
| Storage | Supabase Storage with tenant-scoped access |
| API | REST/JSON or equivalent typed API boundary |
| AI output | Strict structured JSON with schema validation |
| Recognition | Provider-agnostic OCR/vision abstraction |
| Languages | Urdu, Roman Urdu, English, mixed-language |
| Financial calculations | Deterministic backend/database logic |
| Matching | Hybrid matching with human fallback |
| Review | Human-in-the-loop |
| Duplicates | Fingerprint/similarity + idempotency |
| Database writes | Atomic PostgreSQL transactions |
| Security | Tenant isolation and RLS/authorization |
| Audit | Import, AI response, corrections and confirmation history |
| Model improvement | Human-corrected dataset + evaluation before fine-tuning |
## 18. Recommended Implementation Phases
Phase 1 — Foundation: Add import tables, secure image storage, import status lifecycle, and Flutter
capture/review screens.

Phase 2 — Extraction: Integrate ML Kit and/or a vision AI provider behind a replaceable recognition interface;
implement strict JSON schema.

Phase 3 — Understanding: Add multilingual normalization, Pakistani Khata vocabulary, customer/item matching
and confidence handling.

Phase 4 — Review: Build editable review UI, duplicate warnings and explicit confirmation.

Phase 5 — Financial Posting: Implement transactional creation of Khata, items and payments; enforce
idempotency.

Phase 6 — Evaluation: Collect real register samples, measure field-level accuracy, identify failure modes and
improve prompts/preprocessing.

Phase 7 — Scale: Add multi-page imports, asynchronous processing, queues/retries, monitoring and optional
model specialization.
## 19. Key Design Decision
The most adaptable design is not “ML Kit versus AI”. It is a layered pipeline where OCR/vision is replaceable. ML
Kit can be used where it performs well; a stronger vision model can handle difficult handwriting/document
understanding. The financial database remains independent from the AI provider.

Final principle: AI extracts; deterministic application logic validates and calculates; the shopkeeper
confirms; PostgreSQL records the final transaction.
