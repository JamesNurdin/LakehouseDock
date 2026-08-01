WITH
  sampled_warehouse AS (
    SELECT *
    FROM warehouse TABLESAMPLE BERNOULLI (10)
    WHERE w_city = 'Fairview'
  ),
  agg_sales AS (
    SELECT
      cs.cs_item_sk,
      cs.cs_warehouse_sk,
      cs.cs_order_number,
      cs.cs_sold_time_sk,
      SUM(cs.cs_net_paid) AS total_net_paid,
      SUM(cs.cs_quantity) AS total_quantity,
      COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN sampled_warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2451000 AND 2452000
      AND cs.cs_quantity > 0
    GROUP BY cs.cs_item_sk, cs.cs_warehouse_sk, cs.cs_order_number, cs.cs_sold_time_sk
  ),
  order_excluding_returns AS (
    SELECT cs_order_number
    FROM catalog_sales
    EXCEPT
    SELECT cr_order_number
    FROM catalog_returns
  ),
  time_filt AS (
    SELECT *
    FROM time_dim
    WHERE t_hour = 15
      AND t_minute IN (2, 8, 16)
  )
SELECT
  final.item_sk,
  final.warehouse_id,
  SUM(final.net_paid) AS sum_net_paid,
  AVG(final.net_paid) AS avg_net_paid,
  COUNT(DISTINCT final.order_number) AS distinct_orders,
  MIN(final.max_return_amount) AS min_max_return,
  MAX(final.max_return_amount) AS max_max_return
FROM (
  -- rows that have at least one catalog return (correlated EXISTS)
  SELECT
    cs.cs_item_sk AS item_sk,
    w.w_warehouse_id AS warehouse_id,
    cs.total_net_paid AS net_paid,
    cs.cs_order_number AS order_number,
    lr.max_return_amount
  FROM agg_sales cs
  JOIN sampled_warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN time_filt td ON cs.cs_sold_time_sk = td.t_time_sk
  LEFT JOIN LATERAL (
    SELECT MAX(cr.cr_return_amount) AS max_return_amount
    FROM catalog_returns cr
    WHERE cr.cr_order_number = cs.cs_order_number
  ) lr ON TRUE
  WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_order_number = cs.cs_order_number
  )

  UNION DISTINCT

  -- rows that have no catalog return (anti‑join) but are in the EXCEPT set
  SELECT
    cs.cs_item_sk AS item_sk,
    w.w_warehouse_id AS warehouse_id,
    cs.total_net_paid AS net_paid,
    cs.cs_order_number AS order_number,
    NULL AS max_return_amount
  FROM agg_sales cs
  JOIN sampled_warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN time_filt td ON cs.cs_sold_time_sk = td.t_time_sk
  WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr3
    WHERE cr3.cr_order_number = cs.cs_order_number
  )
    AND cs.cs_order_number IN (SELECT cs_order_number FROM order_excluding_returns)
) final
WHERE NOT EXISTS (
  SELECT 1
  FROM web_returns wr
  WHERE wr.wr_order_number = final.order_number
)
GROUP BY final.item_sk, final.warehouse_id
ORDER BY sum_net_paid DESC
LIMIT 100
