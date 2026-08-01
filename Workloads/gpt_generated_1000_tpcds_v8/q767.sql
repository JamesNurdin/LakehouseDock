/*
  Goal: Summarize return amounts across catalog and store channels, broken down by item brand, return reason, ship mode (when applicable), and customer income band, while demonstrating advanced SQL features such as TABLESAMPLE, EXCEPT, UNION DISTINCT, LEFT OUTER JOINs, DISTINCT, NOT EXISTS anti‑join and ordering.
*/
WITH
  /* Sample a fraction of catalog_returns */
  cat_sample AS (
    SELECT DISTINCT
      cr_order_number,
      cr_return_amount,
      cr_returned_time_sk,
      cr_item_sk,
      cr_refunded_customer_sk,
      cr_refunded_hdemo_sk,
      cr_reason_sk,
      cr_ship_mode_sk
    FROM catalog_returns TABLESAMPLE BERNOULLI (10)
  ),
  /* All store returns (no sampling) */
  store_sample AS (
    SELECT DISTINCT
      sr_ticket_number   AS order_number,
      sr_return_amt      AS return_amount,
      sr_return_time_sk  AS returned_time_sk,
      sr_item_sk         AS item_sk,
      sr_customer_sk     AS customer_sk,
      sr_hdemo_sk        AS hdemo_sk,
      sr_reason_sk       AS reason_sk,
      sr_store_sk        AS store_sk
    FROM store_returns
  ),
  /* Orders that appear in catalog_returns but not in store_returns */
  cat_not_in_store AS (
    SELECT cr_order_number
    FROM cat_sample
    EXCEPT
    SELECT sr_ticket_number
    FROM store_returns
  ),
  /* Union the two sources, keeping only catalog rows that are not in store */
  union_returns AS (
    SELECT
      cr_order_number      AS order_id,
      cr_return_amount     AS amount,
      cr_returned_time_sk  AS time_sk,
      cr_item_sk           AS item_sk,
      cr_refunded_customer_sk AS customer_sk,
      cr_refunded_hdemo_sk AS hdemo_sk,
      cr_reason_sk         AS reason_sk,
      cr_ship_mode_sk      AS ship_mode_sk,
      NULL                 AS store_sk,
      'catalog'            AS source
    FROM cat_sample
    WHERE cr_order_number IN (SELECT cr_order_number FROM cat_not_in_store)

    UNION DISTINCT

    SELECT
      order_number         AS order_id,
      return_amount        AS amount,
      returned_time_sk     AS time_sk,
      item_sk              AS item_sk,
      customer_sk          AS customer_sk,
      hdemo_sk             AS hdemo_sk,
      reason_sk            AS reason_sk,
      NULL                 AS ship_mode_sk,
      store_sk             AS store_sk,
      'store'              AS source
    FROM store_sample
  )
SELECT
  src.source,
  i.i_brand,
  r.r_reason_desc,
  sm.sm_type,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  COUNT(DISTINCT src.order_id)      AS distinct_orders,
  SUM(src.amount)                   AS total_return_amount,
  AVG(src.amount)                   AS avg_return_amount
FROM union_returns src
JOIN item i
  ON src.item_sk = i.i_item_sk
LEFT JOIN ship_mode sm
  ON src.ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r
  ON src.reason_sk = r.r_reason_sk
JOIN household_demographics hd
  ON src.hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN time_dim t
  ON src.time_sk = t.t_time_sk
LEFT JOIN store s
  ON src.store_sk = s.s_store_sk
LEFT JOIN customer c
  ON src.customer_sk = c.c_customer_sk
LEFT JOIN web_page wp
  ON c.c_customer_sk = wp.wp_customer_sk
WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_item_sk = src.item_sk
          AND wr.wr_returned_time_sk = src.time_sk
      )
GROUP BY
  src.source,
  i.i_brand,
  r.r_reason_desc,
  sm.sm_type,
  ib.ib_lower_bound,
  ib.ib_upper_bound
ORDER BY total_return_amount DESC
LIMIT 100
