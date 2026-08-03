WITH
  store_customer_keys AS (
    SELECT DISTINCT c.c_customer_sk
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(c.c_email_address, '^.*@example\\.com$')
      AND i.i_category = 'Sports'
  ),

  web_customer_keys AS (
    SELECT DISTINCT c.c_customer_sk
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE c.c_first_name LIKE 'A%'
      AND regexp_extract(i.i_product_name, '(\\w+)') IS NOT NULL
  ),

  store_web_intersect AS (
    SELECT c_customer_sk FROM store_customer_keys
    INTERSECT
    SELECT c_customer_sk FROM web_customer_keys
  ),

  customers_without_high_store_sales AS (
    SELECT ss.ss_customer_sk AS c_customer_sk
    FROM store_sales ss
    GROUP BY ss.ss_customer_sk
    HAVING SUM(ss.ss_ext_sales_price) < 100
  ),

  final_customer_keys AS (
    SELECT c_customer_sk FROM store_web_intersect
    EXCEPT
    SELECT c_customer_sk FROM customers_without_high_store_sales
  ),

  store_sales_agg AS (
    SELECT ss.ss_customer_sk AS c_customer_sk,
           SUM(ss.ss_net_paid) AS total_store_sales,
           COUNT(*) AS store_txn_cnt
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_meal_time = 'lunch'
    GROUP BY ss.ss_customer_sk
  ),

  web_sales_agg AS (
    SELECT ws.ws_bill_customer_sk AS c_customer_sk,
           SUM(ws.ws_net_paid) AS total_web_sales,
           COUNT(*) AS web_txn_cnt
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_meal_time = 'dinner'
    GROUP BY ws.ws_bill_customer_sk
  )

SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  sa.total_store_sales,
  wa.total_web_sales,
  CONCAT('L', SUBSTRING(c.c_email_address, 1, 3)) AS email_code
FROM final_customer_keys fck
JOIN customer c ON fck.c_customer_sk = c.c_customer_sk
LEFT JOIN store_sales_agg sa ON c.c_customer_sk = sa.c_customer_sk
LEFT JOIN web_sales_agg wa ON c.c_customer_sk = wa.c_customer_sk
WHERE EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_customer_sk = c.c_customer_sk
          AND wp.wp_url LIKE '%example%'
      )
ORDER BY sa.total_store_sales DESC NULLS LAST,
         wa.total_web_sales DESC NULLS LAST
