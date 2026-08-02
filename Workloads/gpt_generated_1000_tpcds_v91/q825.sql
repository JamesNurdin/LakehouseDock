WITH
  sales_data AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      i.i_item_id,
      ss.ss_quantity,
      ss.ss_net_paid,
      s.s_store_name,
      p.p_promo_name
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_net_paid > 1000
      AND s.s_division_id = 1
  ),
  catalog_return_data AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      i.i_item_id,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      r.r_reason_desc
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount > 500
      AND i.i_current_price > 200
  )
SELECT
  combined.c_customer_sk,
  combined.c_first_name,
  combined.c_last_name,
  combined.i_item_id,
  combined.activity_type,
  combined.quantity,
  combined.amount,
  combined.location,
  combined.promo,
  (SELECT AVG(ss_net_profit) FROM store_sales) AS avg_store_profit
FROM (
  SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    i.i_item_id,
    'Purchase' AS activity_type,
    CAST(ss.ss_quantity AS BIGINT) AS quantity,
    CAST(ss.ss_net_paid AS DOUBLE) AS amount,
    s.s_store_name AS location,
    p.p_promo_name AS promo
  FROM store_sales ss
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE ss.ss_net_paid > 1000
    AND s.s_division_id = 1

  UNION ALL

  SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    i.i_item_id,
    'Return' AS activity_type,
    CAST(cr.cr_return_quantity AS BIGINT) AS quantity,
    CAST(cr.cr_return_amount AS DOUBLE) AS amount,
    r.r_reason_desc AS location,
    NULL AS promo
  FROM catalog_returns cr
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  WHERE cr.cr_return_amount > 500
    AND i.i_current_price > 200
) AS combined
WHERE combined.c_customer_sk NOT IN (
  SELECT DISTINCT sr_customer_sk FROM store_returns
)
ORDER BY combined.amount DESC
LIMIT 100
