WITH returns_agg AS (
  SELECT
    i.i_item_id AS i_item_id,
    i.i_product_name AS i_product_name,
    SUM(cr.cr_return_amount) AS metric_total,
    COUNT(*) AS cnt,
    CASE WHEN SUM(cr.cr_return_amount) > 1000 THEN 'High' ELSE 'Low' END AS level,
    regexp_extract(i.i_product_name, '(.*)\\s(\\d+)', 1) AS pattern_match
  FROM catalog_returns cr
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE regexp_like(i.i_product_name, '^.*[0-9]{3}$')
    AND cp.cp_type LIKE 'A%'
  GROUP BY i.i_item_id,
    i.i_product_name,
    regexp_extract(i.i_product_name, '(.*)\\s(\\d+)', 1)
),

sales_agg AS (
  SELECT
    i.i_item_id AS i_item_id,
    i.i_product_name AS i_product_name,
    SUM(ws.ws_net_paid_inc_tax) AS metric_total,
    COUNT(*) AS cnt,
    CASE WHEN SUM(ws.ws_net_paid_inc_tax) > 5000 THEN 'High' ELSE 'Low' END AS level,
    regexp_extract(i.i_product_name, '(.*)\\s(\\d+)', 2) AS pattern_match
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
  WHERE i.i_product_name LIKE '%Black%'
    AND regexp_like(i.i_product_name, '.*[A-Z]{2,}$')
  GROUP BY i.i_item_id,
    i.i_product_name,
    regexp_extract(i.i_product_name, '(.*)\\s(\\d+)', 2)
),

union_all AS (
  SELECT * FROM returns_agg
  UNION DISTINCT
  SELECT * FROM sales_agg
),

avg_metric AS (
  SELECT avg(metric_total) AS avg_val FROM union_all
),

ranked AS (
  SELECT
    u.i_item_id,
    u.i_product_name,
    u.metric_total,
    u.cnt,
    u.level,
    u.pattern_match,
    row_number() OVER (PARTITION BY u.i_item_id ORDER BY u.metric_total DESC) AS rnk
  FROM union_all u
  WHERE u.metric_total > (SELECT avg_val FROM avg_metric)
)
SELECT
  i_item_id,
  i_product_name,
  metric_total,
  cnt,
  level,
  pattern_match
FROM ranked
WHERE rnk <= 5
ORDER BY metric_total DESC
LIMIT 100
