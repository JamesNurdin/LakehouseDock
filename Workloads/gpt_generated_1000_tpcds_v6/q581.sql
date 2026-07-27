WITH
  returns_agg AS (
    SELECT
      cr.cr_refunded_customer_sk AS customer_sk,
      SUM(cr.cr_return_amount) AS total_return_amount,
      SUM(cr.cr_return_quantity) AS total_return_qty,
      COUNT(*) AS return_cnt
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 0
      AND cr.cr_return_quantity >= 1
    GROUP BY cr.cr_refunded_customer_sk
  ),
  sales_agg AS (
    SELECT
      ws.ws_bill_customer_sk AS customer_sk,
      SUM(ws.ws_ext_sales_price) AS total_sales_amount,
      SUM(ws.ws_quantity) AS total_qty,
      COUNT(*) AS sales_cnt,
      MAX(ws.ws_ship_date_sk) AS max_ship_date_sk
    FROM web_sales ws
    WHERE ws.ws_wholesale_cost > 20
      AND ws.ws_ship_date_sk BETWEEN 2451390 AND 2452700
    GROUP BY ws.ws_bill_customer_sk
  ),
  web_page_info AS (
    SELECT
      wp.wp_web_page_sk,
      wp.wp_web_page_id,
      wp.wp_rec_start_date,
      wp.wp_customer_sk
    FROM web_page wp
    WHERE wp.wp_rec_start_date >= DATE '2000-01-01'
  )
SELECT
  c.c_customer_id,
  c.c_salutation,
  c.c_birth_day,
  r.total_return_amount,
  s.total_sales_amount,
  CASE
    WHEN r.total_return_amount > 100 THEN 'High'
    ELSE 'Low'
  END AS return_category,
  ROW_NUMBER() OVER (
    PARTITION BY c.c_customer_sk
    ORDER BY r.total_return_amount DESC NULLS LAST
  ) AS rn_return_rank,
  wp.wp_web_page_id,
  COALESCE(wp.wp_customer_sk, -1) AS wp_customer_sk_coalesced
FROM customer c
LEFT JOIN returns_agg r
  ON r.customer_sk = c.c_customer_sk
LEFT JOIN sales_agg s
  ON s.customer_sk = c.c_customer_sk
LEFT JOIN web_page_info wp
  ON wp.wp_customer_sk = c.c_customer_sk
WHERE c.c_salutation = 'Ms.'
  AND c.c_birth_day BETWEEN 1 AND 15
  AND (r.total_return_amount IS NOT NULL OR s.total_sales_amount IS NOT NULL)
ORDER BY r.total_return_amount DESC NULLS LAST
LIMIT 100
