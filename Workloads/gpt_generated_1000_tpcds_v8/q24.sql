WITH
  -- Aggregate store sales per item and customer
  store_agg AS (
    SELECT
      ss_item_sk,
      ss_customer_sk,
      SUM(ss_ext_sales_price) AS store_sales_total,
      SUM(ss_quantity) AS store_quantity,
      COUNT(*) AS store_txn_cnt
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2452000
      AND ss_ext_sales_price > 0
    GROUP BY ss_item_sk, ss_customer_sk
  ),

  -- Aggregate web sales per item and billing customer
  web_agg AS (
    SELECT
      ws_item_sk,
      ws_bill_customer_sk,
      SUM(ws_ext_sales_price) AS web_sales_total,
      SUM(ws_quantity) AS web_quantity,
      COUNT(*) AS web_txn_cnt
    FROM web_sales
    WHERE ws_ship_date_sk = 2452240
      AND ws_ext_sales_price > 0
    GROUP BY ws_item_sk, ws_bill_customer_sk
  ),

  -- Distinct high‑price items (used to guarantee a DISTINCT usage)
  high_price_items AS (
    SELECT DISTINCT i_item_sk, i_category, i_brand
    FROM item
    WHERE i_current_price > 150
  )
SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  ca.ca_state,
  cd.cd_education_status,
  cd.cd_credit_rating,
  i.i_category,
  i.i_brand,
  sa.store_sales_total,
  wa.web_sales_total,
  (sa.store_sales_total + wa.web_sales_total) AS total_sales,
  ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY (sa.store_sales_total + wa.web_sales_total) DESC) AS sales_rank
FROM store_agg sa
JOIN web_agg wa
  ON sa.ss_item_sk = wa.ws_item_sk
  AND sa.ss_customer_sk = wa.ws_bill_customer_sk
JOIN high_price_items hpi
  ON hpi.i_item_sk = sa.ss_item_sk
JOIN item i
  ON i.i_item_sk = sa.ss_item_sk
JOIN customer c
  ON c.c_customer_sk = sa.ss_customer_sk
JOIN customer_demographics cd
  ON cd.cd_demo_sk = c.c_current_cdemo_sk
JOIN customer_address ca
  ON ca.ca_address_sk = c.c_current_addr_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
  AND ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_page wp
  ON wp.wp_web_page_sk = ws.ws_web_page_sk
WHERE ca.ca_state = 'CA'
  AND cd.cd_education_status = '4 yr Degree'
  AND cd.cd_credit_rating = 'Good'
  AND wp.wp_type = 'ad'
  AND wp.wp_autogen_flag = 'Y'
  AND i.i_current_price > 100
  AND EXISTS (
    SELECT 1
    FROM store_sales ss2
    WHERE ss2.ss_customer_sk = c.c_customer_sk
      AND ss2.ss_quantity > 5
  )
GROUP BY
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  ca.ca_state,
  cd.cd_education_status,
  cd.cd_credit_rating,
  i.i_category,
  i.i_brand,
  sa.store_sales_total,
  wa.web_sales_total,
  c.c_customer_sk
ORDER BY total_sales DESC
LIMIT 100
