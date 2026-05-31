-- ============================================================
--   ASSIGNMENT 04 — SET OPERATORS, CTEs, CONSTRAINTS & CASES
--   Database  : BikeStores
-- ============================================================


-- ============================================================
--  SECTION A — SET OPERATORS
-- ============================================================

-- Q1. Unified list of staff and customers without duplicates (UNION removes duplicates).
SELECT first_name + ' ' + last_name AS full_name, email FROM sales.staffs
UNION
SELECT first_name + ' ' + last_name AS full_name, email FROM sales.customers;


-- Q2. States that have BOTH store locations AND customers (INTERSECT finds common values).
SELECT state FROM sales.stores
INTERSECT
SELECT state FROM sales.customers;


-- Q3. Stores that received zero orders in 2018 (EXCEPT removes matching rows).
SELECT store_id FROM sales.stores
EXCEPT
SELECT store_id FROM sales.orders WHERE YEAR(order_date) = 2018;


-- ============================================================
--  SECTION B — CTEs
-- ============================================================

-- Q4. Products whose list_price is higher than their category's average price.
WITH CategoryAvgCTE AS (
    SELECT category_id, AVG(list_price) AS avg_price
    FROM production.products
    GROUP BY category_id
)
SELECT p.category_id, p.product_name, p.list_price, ROUND(c.avg_price, 2) AS category_average
FROM production.products p
JOIN CategoryAvgCTE c ON p.category_id = c.category_id
WHERE p.list_price > c.avg_price;


-- Q5. Staff members whose order count is higher than the average order count.
WITH StaffOrderCountCTE AS (
    SELECT staff_id, COUNT(order_id) AS order_count
    FROM sales.orders
    GROUP BY staff_id
)
SELECT staff_id, order_count
FROM StaffOrderCountCTE
WHERE order_count > (SELECT AVG(order_count) FROM StaffOrderCountCTE);


-- Q6. Store performance where yearly revenue exceeded $1,000,000.
WITH StoreRevenueCTE AS (
    SELECT o.store_id, YEAR(o.order_date) AS order_year,
           SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_revenue
    FROM sales.orders o
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    GROUP BY o.store_id, YEAR(o.order_date)
)
SELECT store_id, order_year, total_revenue
FROM StoreRevenueCTE
WHERE total_revenue > 1000000;


-- ============================================================
--  SECTION C — CONSTRAINTS (DDL)
-- ============================================================

-- Q7. Starter table with required constraints added directly.
CREATE TABLE sales.loyalty_cards (
    card_number   INT PRIMARY KEY, -- Unique & Not Null
    customer_id   INT NOT NULL,
    points        INT DEFAULT 0 CHECK (points >= 0), -- Cannot be negative
    tier          VARCHAR(10) CHECK (tier IN ('Bronze', 'Silver', 'Gold')), -- Specific values only
    join_date     DATE NOT NULL, -- Required
    CONSTRAINT FK_Loyalty_Customers FOREIGN KEY (customer_id) 
        REFERENCES sales.customers(customer_id) ON DELETE CASCADE -- Delete card if customer deleted
);

-- Verification Inserts (Will PASS):
INSERT INTO sales.loyalty_cards VALUES (1001, 1,  500,  'Gold',   '2024-01-15');
INSERT INTO sales.loyalty_cards VALUES (1002, 2,  150,  'Silver', '2024-03-22');
INSERT INTO sales.loyalty_cards VALUES (1003, 3,  0,    'Bronze', '2024-06-01');


-- Q8. Run setup table first.
CREATE TABLE test_orders (
     order_id      INT PRIMARY KEY,
     order_date    DATE NOT NULL,
     shipped_date  DATE
);

INSERT INTO test_orders VALUES (1, '2024-01-10', '2024-01-13');
INSERT INTO test_orders VALUES (2, '2024-02-05', '2024-02-07');
INSERT INTO test_orders VALUES (3, '2024-03-01', NULL);

-- Adding the CHECK constraint via ALTER TABLE:
ALTER TABLE test_orders
ADD CONSTRAINT CHK_ShippedDate CHECK (shipped_date >= order_date OR shipped_date IS NULL);


-- ============================================================
--  SECTION D — CASE EXPRESSIONS
-- ============================================================

-- Q9. Shipping speed analysis using CASE.
SELECT order_id, order_date, shipped_date,
       CASE 
           WHEN shipped_date IS NULL THEN 'Pending'
           WHEN DATEDIFF(day, order_date, shipped_date) <= 2 THEN 'Fast'
           WHEN DATEDIFF(day, order_date, shipped_date) BETWEEN 3 AND 5 THEN 'Normal'
           ELSE 'Delayed'
       END AS shipping_speed
FROM sales.orders;


-- Q10. Stock levels label setup using CASE.
SELECT store_id, product_id, quantity,
       CASE 
           WHEN quantity = 0 THEN 'Out of Stock'
           WHEN quantity BETWEEN 1 AND 10 THEN 'Low Stock'
           WHEN quantity BETWEEN 11 AND 50 THEN 'Sufficient'
           ELSE 'Well Stocked'
       END AS stock