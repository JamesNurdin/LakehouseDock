WITH
  sales_cte AS (
    SELECT
      'sales' AS activity_type,
      cust.c_customer_id AS c_customer_id,
      CASE WHEN SUM(cs.cs_ext_sales_price) > 50000 THEN 'HIGH' ELSE 'MEDIUM' END AS category,
      SUM(cs.cs_ext_sales_price) AS amount
    FROM catalog_sales cs
    JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_type = 'AIR'
      AND cs.cs_ext_sales_price > 1000
      AND EXISTS (
        SELECT 1
        FROM warehouse w
        JOIN customer_address ca ON w.w_state = ca.ca_state
        WHERE ca.ca_address_sk = cust.c_current_addr_sk
      )
    GROUP BY cust.c_customer_id
  ),
  returns_cte AS (
    SELECT
      'returns' AS activity_type,
      cust.c_customer_id AS c_customer_id,
      CASE WHEN SUM(sr.sr_return_amt_inc_tax) > 20000 THEN 'BIG' ELSE 'SMALL' END AS category,
      SUM(sr.sr_return_amt_inc_tax) AS amount
    FROM store_returns sr
    JOIN customer cust ON sr.sr_customer_sk = cust.c_customer_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE sr.sr_return_amt_inc_tax > 500
      AND s.s_state = 'CA'
    GROUP BY cust.c_customer_id
  )
SELECT DISTINCT
  activity_type,
  c_customer_id,
  category,
  amount
FROM (
  SELECT * FROM sales_cte
  UNION ALL
  SELECT * FROM returns_cte
) combined
ORDER BY amount DESC
LIMIT 100
