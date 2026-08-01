WITH
  sales_warehouse AS (
    SELECT
      cs.cs_order_number,
      cs.cs_net_paid,
      cs.cs_quantity,
      cs.cs_item_sk,
      cs.cs_bill_customer_sk,
      c.c_customer_id,
      w.w_warehouse_id,
      w.w_state
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_net_paid > 500
  ),
  full_sales_returns AS (
    SELECT
      cs.cs_order_number,
      cs.cs_net_paid,
      cr.cr_return_amount,
      cs.cs_bill_customer_sk,
      cr.cr_refunded_customer_sk
    FROM catalog_sales cs
    FULL OUTER JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
  ),
  high_return_customers AS (
    SELECT DISTINCT cr.cr_refunded_customer_sk AS c_customer_sk
    FROM catalog_returns cr
    WHERE cr.cr_net_loss > 0
  ),
  high_sales_customers AS (
    SELECT DISTINCT cs.cs_bill_customer_sk AS c_customer_sk
    FROM catalog_sales cs
    WHERE cs.cs_net_paid > 2000
  )
SELECT
  ic.c_customer_id,
  u.w_warehouse_id,
  adj.adjusted_amount
FROM (
  -- intersect the two customer sets
  SELECT c.c_customer_id
  FROM high_sales_customers hsc
  JOIN customer c ON hsc.c_customer_sk = c.c_customer_sk
  WHERE c.c_preferred_cust_flag = 'Y'
  INTERSECT
  SELECT c.c_customer_id
  FROM high_return_customers hrc
  JOIN customer c ON hrc.c_customer_sk = c.c_customer_sk
  WHERE c.c_preferred_cust_flag = 'Y'
) AS ic
JOIN (
  -- union distinct sales records from two states
  SELECT DISTINCT sw.c_customer_id,
                  sw.w_warehouse_id,
                  sw.cs_net_paid AS amount
  FROM sales_warehouse sw
  WHERE sw.w_state = 'TN'
  UNION
  SELECT DISTINCT sw.c_customer_id,
                  sw.w_warehouse_id,
                  sw.cs_net_paid * 0.9 AS amount
  FROM sales_warehouse sw
  WHERE sw.w_state = 'IN'
) AS u
  ON ic.c_customer_id = u.c_customer_id
CROSS JOIN LATERAL (
  SELECT u.amount * 1.08 AS adjusted_amount
) AS adj
ORDER BY adj.adjusted_amount DESC
LIMIT 100
