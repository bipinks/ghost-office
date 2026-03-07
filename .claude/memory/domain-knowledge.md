# Domain Knowledge — Business Rules & Modules

> **Current Specialty**: Enterprise Resource Planning (ERP). This document serves as the domain knowledge base for ERP projects. For other project types, extend or replace with relevant domain knowledge.

## Core Business Concepts

### Multi-Branch Operations
- A **company** has one or more **branches** (locations, outlets, warehouses)
- Each branch operates semi-independently with its own users, data, and settings
- Company-level admins can view consolidated reports across all branches
- Data isolation is enforced: Branch A users cannot see Branch B data
- Inter-branch transfers are explicit operations with audit trails

### Financial Year
- Configurable per company (Jan-Dec, Apr-Mar, Jul-Jun, etc.)
- Opening balances set at financial year start
- Year-end closing generates carry-forward entries
- Historical periods can be locked to prevent edits

### Currency & Tax
- Multi-currency support with exchange rates
- Tax configurations per jurisdiction (VAT, GST, sales tax)
- Tax-exempt items and customers
- Tax reports per period and jurisdiction

---

## ERP Modules (Built-in Specialty)

### 1. Accounting & Finance
**Entities**: Account, Journal Entry, Ledger, Bank Account, Bank Transaction
**Key Rules**:
- Double-entry bookkeeping (every debit has a credit)
- Chart of accounts follows a hierarchical structure
- Journal entries must balance (total debits = total credits)
- Bank reconciliation matches bank transactions to journal entries
- Financial statements: Balance Sheet, P&L, Cash Flow, Trial Balance
- Period closing locks transactions for that period

### 2. Inventory Management
**Entities**: Product, Warehouse, Stock Movement, Stock Adjustment, Purchase Order
**Key Rules**:
- Stock levels tracked per product per warehouse per branch
- FIFO/LIFO/Weighted Average costing methods
- Stock movements: purchase receipt, sales delivery, transfer, adjustment
- Minimum stock alerts when below reorder level
- Batch/serial number tracking (optional per product)
- Stock valuation reports per costing method

### 3. Sales & CRM
**Entities**: Customer, Quotation, Sales Order, Invoice, Payment, Credit Note
**Key Rules**:
- Workflow: Quotation → Sales Order → Delivery → Invoice → Payment
- Quotations have expiry dates
- Sales orders reserve stock
- Invoices generate accounting entries automatically
- Partial payments and payment plans supported
- Credit notes for returns and adjustments
- Customer aging reports (30/60/90 days)

### 4. Procurement
**Entities**: Vendor, Purchase Request, Purchase Order, Bill, Payment
**Key Rules**:
- Workflow: Purchase Request → Approval → Purchase Order → Receipt → Bill → Payment
- Approval workflows based on amount thresholds
- Three-way matching: PO vs Receipt vs Bill
- Vendor evaluation and preferred vendor management
- Purchase price tracking and variance analysis

### 5. Human Resources & Payroll
**Entities**: Employee, Department, Attendance, Leave, Payroll, Salary Component
**Key Rules**:
- Employee lifecycle: hire → active → on leave → resigned → terminated
- Attendance tracking with check-in/check-out
- Leave types: annual, sick, casual, maternity, etc.
- Leave balance accrual and carry-forward rules
- Payroll components: basic, allowances, deductions, taxes
- Payroll runs per branch per pay period
- Statutory compliance (tax, social security, etc.)

### 6. Manufacturing (Optional)
**Entities**: BOM (Bill of Materials), Work Order, Production Order, Quality Check
**Key Rules**:
- BOM defines raw materials needed for finished goods
- Work orders consume raw materials and produce finished goods
- Production stages with time tracking
- Quality checks at defined stages
- Scrap and rework tracking

### 7. Project Management (Optional)
**Entities**: Project, Task, Timesheet, Milestone, Resource Allocation
**Key Rules**:
- Projects linked to customers for billing
- Tasks with dependencies and deadlines
- Timesheet entries for billing and payroll
- Milestone-based billing
- Resource utilization reports

---

## Cross-Cutting Concerns

### Audit Trail
Every data change records:
- **Who**: User ID and name
- **When**: Timestamp (UTC)
- **What**: Table, record ID, field name
- **Before/After**: Old value and new value
- Audit logs are immutable (append-only, never delete)

### Approval Workflows
Configurable per operation type:
- Single approver or multi-level approval
- Amount-based thresholds (e.g., PO > $10,000 needs director approval)
- Auto-approve below threshold
- Rejection with reason (mandatory)

### Notifications
Triggered by events:
- Approval required/granted/rejected
- Stock below reorder level
- Invoice overdue
- Leave request submitted/approved
- Payroll processed
- System alerts (backup, disk space, errors)

### Reports
Standard reports per module:
- Filterable by date range, branch, department
- Exportable to PDF, Excel, CSV
- Printable with company letterhead
- Scheduled report delivery via email
- Custom report builder for ad-hoc queries

### Document Numbering
Auto-generated, configurable per document type per branch:
- Pattern: `{PREFIX}-{BRANCH_CODE}-{YEAR}-{SEQUENCE}`
- Example: `INV-DXB-2026-00001`
- Sequences are branch-specific (no gaps in numbering)
- Prefix and pattern configurable per company
