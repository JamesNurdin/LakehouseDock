WITH
  scalar_avg_profit AS (
    SELECT avg(cs2.cs_net_profit) AS avg_profit
    FROM tpcds.catalog_sales cs2
    WHERE cs2.cs_quantity > 1
  ),
  eligible_customers AS (
    SELECT c.c_customer_sk
    FROM tpcds.customer c
    JOIN tpcds.household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_income_band_sk IN (
        SELECT ib.ib_income_band_sk
        FROM tpcds.income_band ib
        WHERE ib.ib_lower_bound > 30000
    )
      AND regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
  ),
  intersect_items AS (
    SELECT cs.cs_item_sk AS item_sk
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_quantity > 5
    INTERSECT
    SELECT ws.ws_item_sk AS item_sk
    FROM tpcds.web_sales ws
    WHERE ws.ws_quantity > 5
  )
SELECT
  i.i_category AS category,
  i.i_brand AS brand,
  CONCAT(i.i_brand, ' ', i.i_product_name) AS product_full_name,
  regexp_extract(i.i_item_desc, '(\\w+)', 1) AS first_word_desc,
  COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
  SUM(cs.cs_net_profit) AS total_net_profit,
  AVG(cs.cs_quantity) AS avg_quantity
FROM tpcds.catalog_sales cs
JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN intersect_items ii ON cs.cs_item_sk = ii.item_sk
WHERE c.c_customer_sk IN (SELECT ec.c_customer_sk FROM eligible_customers ec)
  AND cs.cs_net_profit > (SELECT avg_profit FROM scalar_avg_profit)
  AND regexp_like(sm.sm_code, '^A[IR]{2}$')
GROUP BY
  i.i_category,
  i.i_brand,
  CONCAT(i.i_brand, ' ', i.i_product_name),
  regexp_extract(i.i_item_desc, '(\\w+)', 1)
ORDER BY total_net_profit DESC
LIMIT 100
