WITH sold AS (
  SELECT
    cs.cs_sold_date_sk AS date_sk,
    td.t_shift,
    cs.cs_item_sk,
    w.w_warehouse_name,
    SUM(cs.cs_quantity) AS sold_qty
  FROM catalog_sales cs
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  GROUP BY cs.cs_sold_date_sk, td.t_shift, cs.cs_item_sk, w.w_warehouse_name
),
returned AS (
  SELECT
    sr.sr_returned_date_sk AS date_sk,
    td.t_shift,
    sr.sr_item_sk AS cs_item_sk,
    SUM(sr.sr_return_quantity) AS returned_qty
  FROM store_returns sr
  JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
  GROUP BY sr.sr_returned_date_sk, td.t_shift, sr.sr_item_sk
)
SELECT
  s.date_sk,
  s.t_shift,
  s.w_warehouse_name,
  s.cs_item_sk,
  s.sold_qty,
  COALESCE(r.returned_qty, 0) AS returned_qty,
  CASE WHEN s.sold_qty = 0 THEN NULL ELSE (COALESCE(r.returned_qty, 0) * 1.0) / s.sold_qty END AS return_ratio,
  RANK() OVER (PARTITION BY s.date_sk ORDER BY CASE WHEN s.sold_qty = 0 THEN 0 ELSE (COALESCE(r.returned_qty, 0) * 1.0) / s.sold_qty END DESC) AS return_rank,
  CASE 
    WHEN s.sold_qty = 0 THEN 'No Sales'
    WHEN COALESCE(r.returned_qty, 0) * 1.0 / s.sold_qty > 0.5 THEN 'High'
    WHEN COALESCE(r.returned_qty, 0) * 1.0 / s.sold_qty > 0.2 THEN 'Medium'
    ELSE 'Low'
  END AS return_category
FROM sold s
LEFT JOIN returned r
  ON s.date_sk = r.date_sk
  AND s.t_shift = r.t_shift
  AND s.cs_item_sk = r.cs_item_sk
WHERE s.sold_qty > 0
ORDER BY s.date_sk, return_rank
