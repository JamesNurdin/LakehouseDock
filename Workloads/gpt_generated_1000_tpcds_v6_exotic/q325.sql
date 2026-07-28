/* Goal: Identify top stores by on‑hand inventory for customers born in 2001, filtered by address and demographic criteria, and compute various inventory metrics */
WITH
  d_cust AS (
    SELECT *
    FROM date_dim
    WHERE d_year = 2001
  ),
  d_inv AS (
    SELECT *
    FROM date_dim
    WHERE d_month_seq BETWEEN 1200 AND 1300
  ),
  d_store AS (
    SELECT *
    FROM date_dim
    WHERE d_year = 2001
  )
SELECT
  s.s_store_name,
  ca.ca_state,
  d_cust.d_year,
  COUNT(DISTINCT c.c_customer_id) AS unique_customers,
  SUM(i.inv_quantity_on_hand) AS total_qty_on_hand,
  AVG(CASE WHEN hd.hd_buy_potential = 'HIGH' THEN i.inv_quantity_on_hand END) AS avg_qty_high_potential,
  MAX(CASE WHEN i.inv_warehouse_sk = 16 THEN i.inv_quantity_on_hand END) AS max_qty_warehouse_16
FROM customer c
JOIN customer_address ca
  ON c.c_current_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN d_cust
  ON c.c_first_sales_date_sk = d_cust.d_date_sk
JOIN inventory i
  ON 1 = 1
JOIN d_inv
  ON i.inv_date_sk = d_inv.d_date_sk
JOIN store s
  ON 1 = 1
JOIN d_store
  ON s.s_closed_date_sk = d_store.d_date_sk
WHERE
  ca.ca_state = 'TX'
  AND s.s_state = 'CA'
  AND i.inv_warehouse_sk IN (15, 16, 18)
  AND hd.hd_income_band_sk = 3
  AND i.inv_quantity_on_hand > 0
  AND EXISTS (
    SELECT 1
    FROM inventory i2
    WHERE i2.inv_item_sk = i.inv_item_sk
      AND i2.inv_quantity_on_hand > 100
  )
GROUP BY
  s.s_store_name,
  ca.ca_state,
  d_cust.d_year
ORDER BY
  total_qty_on_hand DESC
LIMIT 100
