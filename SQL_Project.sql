-- Stored Functions, for customer credit checks

USE inventory _db;

DROP FUNCTION IF EXISTS check_credit;

DELIMITER $$

CREATE FUNCTION check_credit(
    requesting_customer_id CHAR(10),
    request_amount INT
)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    RETURN (
        SELECT credit_limit
        FROM customer
        WHERE customer_id = requesting_customer_id
    ) >= request_amount;
END $$

DELIMITER ;

-- Test: check_credit
SET @approved = check_credit('C000000001', 4000000);
SELECT @approved;

---------------------------------------------------
/*Stored Procedure, for quantity-on-hand lookup and use it to create a trigger in 
the next steps, to prevent order line items from being inserted when the requested 
quantity exceeds available inventory.*/

DROP PROCEDURE IF EXISTS get_qoh_stp;

DELIMITER $$

CREATE PROCEDURE get_qoh_stp(
    IN request_item_id CHAR(10),
    OUT qoh_to_return INT
)
BEGIN
    SELECT qoh
    INTO qoh_to_return
    FROM merchandise_item
    WHERE merchandise_item_id = request_item_id;
END $$

DELIMITER ;

-- Test: get_qoh_stp
SET @qty = 0;
CALL get_qoh_stp('ITALYPASTA', @qty);
SELECT @qty;

---------------------------------------------------
--Triggers, Decrease quantity on hand after inserting a new order line item.

USE inventory _db;

DROP TRIGGER IF EXISTS decrease_inventory_tgr;

DELIMITER $$

CREATE TRIGGER decrease_inventory_tgr
AFTER INSERT ON customer_order_line_item
FOR EACH ROW
BEGIN
    UPDATE merchandise_item
    SET qoh = qoh - NEW.quantity
    WHERE merchandise_item_id = NEW.merchandise_item_id;
END $$

DELIMITER ;


---------------------------------------------------
--Triggers, Validate available inventory before inserting a new order line item.

DROP TRIGGER IF EXISTS inventory_check_tgr;

DELIMITER $$

CREATE TRIGGER inventory_check_tgr
BEFORE INSERT ON customer_order_line_item
FOR EACH ROW
BEGIN
    DECLARE inventory INT;

    CALL get_qoh_stp(NEW.merchandise_item_id, inventory);

    IF inventory < NEW.quantity THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient inventory';
    END IF;
END $$

DELIMITER ;

-- Test: inventory_check_tgr
UPDATE merchandise_item
SET qoh = 10
WHERE merchandise_item_id = 'ITALYPASTA';

DELETE FROM customer_order_line_item
WHERE customer_order_id = 'D000000003'
  AND merchandise_item_id = 'ITALYPASTA';

INSERT INTO customer_order_line_item
SET customer_order_id = 'D000000003',
    merchandise_item_id = 'ITALYPASTA',
    quantity = 20;
