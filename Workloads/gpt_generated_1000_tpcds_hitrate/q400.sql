WITH catalog_customers AS (
  SELECT DISTINCT
    cs.cs_bill_customer_sk AS customer_sk,
    cs.cs_order_number    AS order_num,
    cs.cs_item_sk
  FROM catalog_sales cs
  JOIN date_dim d      ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN promotion p     ON cs.cs_promo_sk = p.p_promo_sk
  WHERE d.d_year = 2001
    AND p.p_discount_active = 'Y'
    AND cs.cs_item_sk IN (SELECT i_item_sk FROM item WHERE i_current_price > 100)
),
web_customers AS (
  SELECT DISTINCT
    ws.ws_bill_customer_sk AS customer_sk,
    ws.ws_order_number    AS order_num
  FROM web_sales ws
  JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
  WHERE d2.d_year = 2001
)
SELECT 
  c.customer_sk,
  c.order_num,
  (SELECT SUM(ss.ss_net_paid)
   FROM store_sales ss
   WHERE ss.ss_customer_sk = c.customer_sk) AS total_store_spent,
  CASE 
    WHEN (SELECT SUM(ss.ss_net_paid)
          FROM store_sales ss
          WHERE ss.ss_customer_sk = c.customer_sk) > 10000 THEN 'High'
    ELSE 'Low'
  END AS spend_category
FROM catalog_customers c
EXCEPT
SELECT 
  w.customer_sk,
  w.order_num,
  CAST(NULL AS decimal(7,2)) AS total_store_spent,
  CAST(NULL AS varchar)      AS spend_category
FROM web_customers w
ORDER BY customer_sk, order_num
LIMIT 100
