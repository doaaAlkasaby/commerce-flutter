# Task 06.11 — Add Two Luma Test Products Plan

Prepare targeted seed module `prisma/seeds/task11-products.seed.ts` for Product A (Luma Premium Linen Shirt with 8 sparse variants and 20% discount) and Product B (Luma Leather Travel Organizer with tax category assignment).

## Summary of Prepared Changes

### Product A — Luma Premium Linen Shirt
- **Slug**: `luma-premium-linen-shirt`
- **Category**: `Clothing` (`development-clothing`, ID: `763118e8-ed73-45a1-a4db-206cd4fdc445`)
- **Attributes**: `Color` (White, Beige, Navy), `Size` (S, M, L, XL), `Fit` (Slim, Regular)
- **Sparse Variant Matrix (Exactly 8 active variants)**:
  1. White | S | Slim | Base: 18.000 KWD | Stock: 8 | 20% Discount
  2. White | M | Slim | Base: 19.000 KWD | Stock: 6 | 20% Discount *(Default Variant)*
  3. White | L | Regular | Base: 21.000 KWD | Stock: 5 | 20% Discount
  4. Beige | M | Regular | Base: 20.000 KWD | Stock: 7 | 20% Discount
  5. Beige | L | Regular | Base: 22.000 KWD | Stock: 4 | 20% Discount
  6. Navy | M | Slim | Base: 23.000 KWD | Stock: 3 | 20% Discount
  7. Navy | XL | Regular | Base: 26.000 KWD | Stock: 2 | 20% Discount
  8. Navy | L | Slim | Base: 24.000 KWD | Stock: 0 | 20% Discount *(Out of Stock)*

### Product B — Luma Leather Travel Organizer
- **Slug**: `luma-leather-travel-organizer`
- **Category**: `Luxury Handbags` (`handbags`, ID: `7a9b9bdf-f4d4-4466-a8aa-3a8c73638b16`)
- **Base Price**: 30.000 KWD
- **Tax Category**: Assigned to Luma's `Development standard tax` (`e7636baa-53dd-4e44-abb5-bb695a8e2de4`)
- **Variant**: Single default variant `LUMA-ORGANIZER-STD` with 10 stock units.

### Backend Code & Test Architecture
- **Seed Module ([`task11-products.seed.ts`](file:///Users/doaaalkasaby/Desktop/NodeFolder/projects/e-commerce/commerce-api/prisma/seeds/task11-products.seed.ts))**: Implemented `seedTask11Products(prisma)` with deterministic `developmentId(...)` upserts.
- **Media Download Script ([`download-task11-media.ts`](file:///Users/doaaalkasaby/Desktop/NodeFolder/projects/e-commerce/commerce-api/scripts/download-task11-media.ts))**: Downloaded studio WebP photographs.
- **Runner Script ([`seed-task11-products-dev.ts`](file:///Users/doaaalkasaby/Desktop/NodeFolder/projects/e-commerce/commerce-api/scripts/seed-task11-products-dev.ts))**: Controlled runner with `commerce_api_dev` target check.
- **Integration Test ([`task11-products.test.ts`](file:///Users/doaaalkasaby/Desktop/NodeFolder/projects/e-commerce/commerce-api/tests/products/task11-products.test.ts))**: Vitest integration test suite testing sparse variant creation, discounts, and tax category assignment on `commerce_api_test`.

## Verification Plan
- Run `npm run build` & `npm test tests/products/task11-products.test.ts`
- Run `flutter analyze` & `flutter test`
- Stop for explicit user approval before running `seed-task11-products-dev.ts` against `commerce_api_dev`.
