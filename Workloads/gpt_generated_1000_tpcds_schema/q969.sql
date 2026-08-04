WITH
  common_customers AS (
    SELECT cust_sk FROM (
      SELECT DISTINCT cr_refunded_customer_sk AS cust_sk
      FROM catalog_returns
    )
    INTERSECT
    SELECT cust_sk FROM (
      SELECT DISTINCT wr_refunded_customer_sk AS cust_sk
      FROM web_returns
    )
  ),
  date_call AS (
    SELECT d.d_date_sk,
           d.d_date,
           cc.cc_call_center_id,
           cc.cc_name,
           cc.cc_state
    FROM date_dim d
    FULL OUTER JOIN call_center cc
         ON cc.cc_closed_date_sk = d.d_date_sk
  ),
  sales_item AS (
    SELECT i.i_item_id,
           i.i_category,
           ss.ss_sold_date_sk,
           ss.ss_customer_sk,
           ss.ss_quantity,
           ss.ss_net_paid,
           CASE WHEN ss.ss_quantity > 0 THEN ss.ss_net_paid / ss.ss_quantity ELSE 0 END AS avg_price_per_qty
    FROM store_sales ss
    RIGHT OUTER JOIN item i
         ON ss.ss_item_sk = i.i_item_sk
  ),
  reason_words AS (
    SELECT r.r_reason_id,
           r.r_reason_desc,
           word
    FROM catalog_returns cr
    JOIN reason r
         ON cr.cr_reason_sk = r.r_reason_sk
    CROSS JOIN UNNEST(split(r.r_reason_desc, ' ')) AS t(word)
    WHERE regexp_like(r.r_reason_desc, '(?i)color|size|price')
  )
SELECT
  dc.d_date,
  si.i_category,
  c.c_first_name,
  c.c_last_name,
  CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
  si.avg_price_per_qty,
  CASE
    WHEN si.ss_quantity IS NULL THEN 'No Sales'
    WHEN si.ss_quantity = 0 THEN 'Zero Qty'
    ELSE 'Sold'
  END AS sales_status,
  rw.word,
  COUNT(*) FILTER (WHERE rw.word IS NOT NULL) AS word_occurrences
FROM sales_item si
JOIN date_call dc
     ON si.ss_sold_date_sk = dc.d_date_sk
JOIN customer c
     ON si.ss_customer_sk = c.c_customer_sk
JOIN common_customers ccust
     ON c.c_customer_sk = ccust.cust_sk
LEFT JOIN reason_words rw
     ON TRUE
WHERE regexp_like(c.c_last_name, '^A.*')
  AND dc.cc_name LIKE '%Center%'
GROUP BY
  dc.d_date,
  si.i_category,
  c.c_first_name,
  c.c_last_name,
  CONCAT(c.c_first_name, ' ', c.c_last_name),
  si.avg_price_per_qty,
  CASE
    WHEN si.ss_quantity IS NULL THEN 'No Sales'
    WHEN si.ss_quantity = 0 THEN 'Zero Qty'
    ELSE 'Sold'
  END,
  rw.word
ORDER BY dc.d_date DESC, word_occurrences DESC
LIMIT 100
