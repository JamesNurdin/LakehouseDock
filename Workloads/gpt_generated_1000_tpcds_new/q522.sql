WITH
  c_ret_agg AS (
    SELECT
      cr_catalog_page_sk,
      cr_returned_time_sk,
      SUM(cr_return_amount) AS total_return_amount,
      COUNT(*) AS cnt_returns
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
    GROUP BY cr_catalog_page_sk, cr_returned_time_sk
  ),
  ws_agg AS (
    SELECT
      ws_item_sk,
      ws_order_number,
      ws_sold_time_sk,
      SUM(ws_net_paid) AS total_net_paid,
      AVG(ws_ext_tax) AS avg_ext_tax
    FROM web_sales
    GROUP BY ws_item_sk, ws_order_number, ws_sold_time_sk
  ),
  web_returns_sample AS (
    SELECT *
    FROM web_returns
    TABLESAMPLE BERNOULLI (5)
  ),
  ws_orig_sample AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (5)
  )
SELECT
  cp.cp_department                AS department,
  t_cr.t_hour                      AS return_hour,
  t_wr.t_hour                      AS web_return_hour,
  cragg.total_return_amount,
  wr.wr_fee,
  wagg.total_net_paid,
  SUM(u.value)                     AS sum_qty_wholesale,
  COUNT(DISTINCT cp.cp_catalog_page_id) AS distinct_page_ids
FROM c_ret_agg cragg
JOIN catalog_page cp
  ON cragg.cr_catalog_page_sk = cp.cp_catalog_page_sk
FULL OUTER JOIN catalog_page cp2
  ON cragg.cr_catalog_page_sk = cp2.cp_catalog_page_sk
JOIN time_dim t_cr
  ON cragg.cr_returned_time_sk = t_cr.t_time_sk
JOIN web_returns_sample wr
  ON wr.wr_returned_time_sk = t_cr.t_time_sk
JOIN time_dim t_wr
  ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN ws_agg wagg
  ON wr.wr_item_sk = wagg.ws_item_sk
JOIN ws_agg wagg2
  ON wr.wr_order_number = wagg2.ws_order_number
JOIN ws_orig_sample ws_orig
  ON ws_orig.ws_item_sk = wagg.ws_item_sk
JOIN LATERAL (
      SELECT ARRAY[ws_orig.ws_quantity, CAST(ws_orig.ws_wholesale_cost AS double)] AS arr
) AS l ON true
CROSS JOIN UNNEST(l.arr) AS u(value)
WHERE cp.cp_department = 'DEPARTMENT'
GROUP BY
  cp.cp_department,
  t_cr.t_hour,
  t_wr.t_hour,
  cragg.total_return_amount,
  wr.wr_fee,
  wagg.total_net_paid

UNION DISTINCT

SELECT
  cp.cp_department                AS department,
  t_cr.t_hour                      AS return_hour,
  t_wr.t_hour                      AS web_return_hour,
  cragg.total_return_amount,
  wr.wr_fee,
  wagg.total_net_paid,
  SUM(u.value)                     AS sum_qty_wholesale,
  COUNT(DISTINCT cp.cp_catalog_page_id) AS distinct_page_ids
FROM c_ret_agg cragg
JOIN catalog_page cp
  ON cragg.cr_catalog_page_sk = cp.cp_catalog_page_sk
FULL OUTER JOIN catalog_page cp2
  ON cragg.cr_catalog_page_sk = cp2.cp_catalog_page_sk
JOIN time_dim t_cr
  ON cragg.cr_returned_time_sk = t_cr.t_time_sk
JOIN web_returns_sample wr
  ON wr.wr_returned_time_sk = t_cr.t_time_sk
JOIN time_dim t_wr
  ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN ws_agg wagg
  ON wr.wr_item_sk = wagg.ws_item_sk
JOIN ws_agg wagg2
  ON wr.wr_order_number = wagg2.ws_order_number
JOIN ws_orig_sample ws_orig
  ON ws_orig.ws_item_sk = wagg.ws_item_sk
JOIN LATERAL (
      SELECT ARRAY[ws_orig.ws_quantity, CAST(ws_orig.ws_wholesale_cost AS double)] AS arr
) AS l ON true
CROSS JOIN UNNEST(l.arr) AS u(value)
WHERE cp.cp_department <> 'DEPARTMENT'
GROUP BY
  cp.cp_department,
  t_cr.t_hour,
  t_wr.t_hour,
  cragg.total_return_amount,
  wr.wr_fee,
  wagg.total_net_paid

ORDER BY department, return_hour
LIMIT 100
