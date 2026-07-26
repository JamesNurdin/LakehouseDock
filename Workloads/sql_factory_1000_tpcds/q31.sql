WITH catalog_agg AS (
  SELECT
    cr_item_sk AS item_sk,
    SUM(cr_return_quantity) AS catalog_return_qty
  FROM catalog_returns
  GROUP BY cr_item_sk
),
web_agg AS (
  SELECT
    wr_item_sk AS item_sk,
    SUM(wr_return_quantity) AS web_return_qty
  FROM web_returns
  GROUP BY wr_item_sk
),
sales_agg AS (
  SELECT
    ws_item_sk AS item_sk,
    SUM(ws_quantity) AS total_sold_qty
  FROM web_sales
  GROUP BY ws_item_sk
),
combined_returns AS (
  SELECT
    item_sk,
    SUM(COALESCE(catalog_return_qty, 0) + COALESCE(web_return_qty, 0)) AS total_return_qty
  FROM (
    SELECT item_sk, catalog_return_qty, 0 AS web_return_qty FROM catalog_agg
    UNION ALL
    SELECT item_sk, 0 AS catalog_return_qty, web_return_qty FROM web_agg
  ) t
  GROUP BY item_sk
),
catalog_reason AS (
  SELECT
    cr_item_sk AS item_sk,
    cr_reason_sk,
    COUNT(*) AS cnt
  FROM catalog_returns
  GROUP BY cr_item_sk, cr_reason_sk
),
web_reason AS (
  SELECT
    wr_item_sk AS item_sk,
    wr_reason_sk,
    COUNT(*) AS cnt
  FROM web_returns
  GROUP BY wr_item_sk, wr_reason_sk
),
combined_reason AS (
  SELECT
    item_sk,
    cr_reason_sk AS reason_sk,
    cnt
  FROM catalog_reason
  UNION ALL
  SELECT
    item_sk,
    wr_reason_sk AS reason_sk,
    cnt
  FROM web_reason
),
most_common_reason AS (
  SELECT
    item_sk,
    reason_sk,
    cnt,
    ROW_NUMBER() OVER (PARTITION BY item_sk ORDER BY cnt DESC) AS rn
  FROM combined_reason
)
SELECT
  cr.item_sk,
  cr.total_return_qty,
  s.total_sold_qty,
  CASE
    WHEN s.total_sold_qty = 0 THEN 0
    ELSE CAST(cr.total_return_qty AS double) / s.total_sold_qty
  END AS return_ratio,
  r.r_reason_desc AS top_reason_desc,
  DENSE_RANK() OVER (ORDER BY CASE WHEN s.total_sold_qty = 0 THEN 0 ELSE CAST(cr.total_return_qty AS double) / s.total_sold_qty END DESC) AS return_rank
FROM combined_returns cr
JOIN sales_agg s
  ON cr.item_sk = s.item_sk
JOIN most_common_reason mr
  ON cr.item_sk = mr.item_sk AND mr.rn = 1
JOIN reason r
  ON mr.reason_sk = r.r_reason_sk
ORDER BY return_ratio DESC
LIMIT 15
