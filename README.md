SQL Inventory Control System
-------------------------------------------

A MySQL project demonstrating advanced database programming through a real-world inventory management use case. This project implements stored functions, stored procedures, and triggers that work together to enforce business rules at the database level.

Project Overview
-------------------------------------------
This project simulates the backend logic of an order management system, where inventory availability and customer credit must be validated before any order is processed. All business rules are enforced within the database layer — no application code required.
 
Database
---------------
Schema: inventory _db (retail/inventory domain)
Key Tables:
•	customer — stores customer records including credit limits
•	merchandise_item — product catalog with quantity-on-hand (qoh)
•	customer_order_line_item — individual line items within customer orders
 
Components
-----------------
1. Stored Function — check_credit
Validates whether a customer's credit limit covers a requested order amount.
Returns TRUE if approved, FALSE if not.

SET @approved = check_credit('C000000001', 4000000);
SELECT @approved;
 
2. Stored Procedure — get_qoh_stp
Looks up the current quantity on hand for a given merchandise item.
Used internally by the inventory validation trigger.

SET @qty = 0;
CALL get_qoh_stp('ITALYPASTA', @qty);
SELECT @qty;
 
3. Triggers
inventory_check_tgr (BEFORE INSERT)
Fires before a new order line item is inserted. Calls get_qoh_stp to check available stock. If the requested quantity exceeds inventory, the insert is blocked and an error is raised:
SIGNAL SQLSTATE '45000': 'Insufficient inventory'
decrease_inventory_tgr (AFTER INSERT)
Fires after a successful insert. Automatically decrements the qoh in merchandise_item by the ordered quantity — keeping inventory counts accurate in real time.


How the Components Work Together
----------
Customer places order
        │
        ▼
[BEFORE INSERT trigger]
  → calls get_qoh_stp()
  → checks available inventory
  → blocks insert if insufficient
        │
        ▼ (if stock available)
  Order line item inserted
        │
        ▼
[AFTER INSERT trigger]
  → decrements qoh in merchandise_item

 
Skills Demonstrated
---------
•	Stored functions with conditional return logic
•	Stored procedures with IN/OUT parameters
•	BEFORE and AFTER triggers with cross-table logic
•	Error handling using SIGNAL SQLSTATE
•	Modular design: procedure reused inside a trigger
 
How to Run
--------
1.	Set up a MySQL instance and create the world_peace schema with the required tables.
2.	Run SQL_Project.sql to create all objects.
3.	Use the test blocks at the bottom of each section to verify behavior.

 
Author
Tannaz Fard


