# Delivery Challan Types Implementation Plan

## Overview
Implement 4 distinct types of Delivery Challans with different behaviors and invoice requirements.

## Delivery Challan Types

### 1. Internal Delivery Challan (Vendor to Vendor)
**Purpose:** Transfer materials between vendors/subcontractors  
**Invoice:** ❌ No invoice raised  
**Behavior:** Shows details only, tracks material movement  
**Use Case:** Sending raw materials to subcontractor for processing, then receiving back

**Fields:**
- DC Number, Date
- From Vendor, To Vendor
- Material details (code, description, quantity, unit)
- Job Number (optional)
- Note/Remarks
- Returnable flag

**Navigation:** Stores → Internal Delivery Challan (Vendor to Vendor)

---

### 2. Regular Delivery Challan
**Purpose:** Deliver finished goods to customers  
**Invoice:** ✅ Invoice IS raised  
**Behavior:** Links to invoice generation, tracks payment  
**Use Case:** Delivering finished products to customer with invoice

**Fields:**
- DC Number, Date
- Customer Name, Email, GSTIN
- Material details
- Invoice Number (linked)
- Invoice Amount
- Payment status
- Job Number (optional)

**Navigation:** Stores → Delivery Challan (existing, enhanced)

---

### 3. Job Order Delivery Challan
**Purpose:** Deliver materials for specific job orders  
**Invoice:** ❌ No invoice raised  
**Behavior:** Tracks job-specific deliveries, links to job order  
**Use Case:** Delivering materials to customer's site for installation/assembly job

**Fields:**
- DC Number, Date
- Customer Name
- Job Order Number (required)
- Material details
- Site Address
- Expected Return Date (if returnable)
- Note/Remarks

**Navigation:** Stores → Job Order Delivery Challan

---

### 4. Material Return Delivery Challan
**Purpose:** Return rejected materials to vendor  
**Invoice:** ❌ No invoice raised  
**Behavior:** Based on incoming inspection rejections, debit note  
**Use Case:** Returning defective materials identified during quality inspection

**Fields:**
- DC Number, Date
- Vendor Name, GSTIN
- Inspection Number (source)
- GRN Number (source)
- Material details (from rejected items)
- Rejection Reason
- Debit Note Number
- Return Status

**Navigation:** Stores → Material Return Delivery Challan

---

## Implementation Plan

### Step 1: Update DeliveryChallan Model

Add new fields to support all types:

```dart
@HiveField(8)
String dcType; // 'internal', 'regular', 'job_order', 'material_return'

@HiveField(9)
String? invoiceNumber; // For regular DC

@HiveField(10)
double? invoiceAmount; // For regular DC

@HiveField(11)
String? paymentStatus; // For regular DC

@HiveField(12)
String? jobOrderNumber; // For job order DC

@HiveField(13)
String? inspectionNumber; // For material return DC

@HiveField(14)
String? grnNumber; // For material return DC

@HiveField(15)
String? rejectionReason; // For material return DC

@HiveField(16)
String? debitNoteNumber; // For material return DC

@HiveField(17)
String? fromVendor; // For internal DC

@HiveField(18)
String? toVendor; // For internal DC

@HiveField(19)
String? siteAddress; // For job order DC

@HiveField(20)
String? expectedReturnDate; // For job order DC

@HiveField(21)
String? returnStatus; // For material return DC
```

### Step 2: Create Separate Pages

#### Internal DC Pages
- `internal_delivery_challan_list_page.dart`
- `add_internal_delivery_challan_page.dart`

#### Regular DC Pages  
- Update existing `delivery_challan_list_page.dart` to filter `dcType == 'regular'`
- Update existing `add_delivery_challan_page.dart` to include invoice fields

#### Job Order DC Pages
- `job_order_delivery_challan_list_page.dart`
- `add_job_order_delivery_challan_page.dart`

#### Material Return DC Pages
- `material_return_delivery_challan_list_page.dart`
- `add_material_return_delivery_challan_page.dart`
  - Auto-populate from inspection rejections
  - Select inspection → Load rejected items → Create DC

### Step 3: Update Navigation

```dart
8: [
  'GR',
  'Purchased Material Request',
  'Purchased Material Issue',
  'Customer Scope GR',
  'Customer Scope Issue',
  'Stock Maintenance & Display',
  'Customer Scope Stock Maintenance',
  'Delivery Challan',                    // Regular (with invoice)
  'Internal Delivery Challan',           // Vendor to Vendor (no invoice)
  'Job Order Delivery Challan',          // Job specific (no invoice)
  'Material Return Delivery Challan',    // Return to vendor (no invoice)
  'Invoice Generation',
],
```

### Step 4: Provider Updates

Update `delivery_challan_provider.dart`:
- Add methods to filter by type
- Add invoice generation integration for regular DC
- Add inspection integration for material return DC
- Add job order validation for job order DC

### Step 5: UI Differences

**Internal DC:**
- From/To Vendor dropdowns
- No invoice section
- Simple material list
- Returnable checkbox

**Regular DC:**
- Customer dropdown
- Invoice section (number, amount, status)
- Payment tracking
- Link to invoice generation

**Job Order DC:**
- Customer dropdown
- Job Order dropdown (required)
- Site address field
- Expected return date
- No invoice section

**Material Return DC:**
- Inspection dropdown (filters rejected items)
- Auto-populate materials from inspection
- Vendor auto-filled from GRN
- Rejection reason display
- Debit note field
- Return status tracking

## Database Schema

### Hive Type IDs
- DeliveryChallanItem: 40 (existing)
- DeliveryChallan: 41 (existing, will add new fields)

### Firestore Collections
- `deliveryChallans` - All types stored here with `dcType` field for filtering

## Benefits

1. **Clear Separation** - Each type has specific purpose and fields
2. **Invoice Control** - Only regular DC can have invoice
3. **Traceability** - Material returns linked to inspections
4. **Job Tracking** - Job order DCs linked to specific jobs
5. **Vendor Management** - Internal DCs track vendor-to-vendor transfers

## Testing Checklist

- [ ] Create internal DC (vendor to vendor)
- [ ] Verify no invoice fields shown
- [ ] Create regular DC with invoice
- [ ] Verify invoice generation link works
- [ ] Create job order DC
- [ ] Verify job order is required
- [ ] Create material return DC from inspection
- [ ] Verify rejected items auto-populate
- [ ] Verify all types filter correctly in lists
- [ ] Test Firestore sync for all types

---

**Status:** Ready for implementation  
**Priority:** High  
**Estimated Effort:** 4-6 pages + model updates
