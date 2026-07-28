WITH cust_catalog AS (
  SELECT
    c.c_customer_id AS customer_id,
    SUM(cs.cs_net_profit) AS catalog_profit,
    COUNT(*) AS catalog_orders,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(cs.cs_net_profit) DESC) AS rn_catalog
  FROM catalog_sales cs
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND cs.cs_net_profit > 0
    AND NOT EXISTS (
        SELECT 1
        FROM inventory i
        JOIN date_dim d_inv ON i.inv_date_sk = d_inv.d_date_sk
        WHERE i.inv_item_sk = cs.cs_item_sk
          AND d_inv.d_holiday = 'Y'
    )
  GROUP BY c.c_customer_id
),
cust_store AS (
  SELECT
    c.c_customer_id AS customer_id,
    SUM(ss.ss_net_profit) AS store_profit,
    COUNT(*) AS store_orders,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ss.ss_net_profit) DESC) AS rn_store
  FROM store_sales ss
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND ss.ss_net_profit > 0
    AND NOT EXISTS (
        SELECT 1
        FROM inventory i
        JOIN date_dim d_inv ON i.inv_date_sk = d_inv.d_date_sk
        WHERE i.inv_item_sk = ss.ss_item_sk
          AND d_inv.d_holiday = 'Y'
    )
  GROUP BY c.c_customer_id
)
SELECT DISTINCT
  customer_id,
  profit,
  source,
  order_count,
  rank_in_source
FROM (
  SELECT
    customer_id,
    catalog_profit AS profit,
    'catalog' AS source,
    catalog_orders AS order_count,
    rn_catalog AS rank_in_source
  FROM cust_catalog
  UNION ALL
  SELECT
    customer_id,
    store_profit AS profit,
    'store' AS source,
    store_orders AS order_count,
    rn_store AS rank_in_source
  FROM cust_store
) combined
ORDER BY profit DESC, customer_id
LIMIT 100
