WITH 
store_sales_agg AS (
  SELECT
    ss.ss_sold_date_sk AS date_sk,
    ss.ss_item_sk AS item_sk,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(*) AS txn_count
  FROM store_sales ss
  WHERE ss.ss_sold_date_sk IS NOT NULL
  GROUP BY ss.ss_sold_date_sk, ss.ss_item_sk
),
catalog_sales_agg AS (
  SELECT
    cs.cs_sold_date_sk AS date_sk,
    cs.cs_item_sk AS item_sk,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(*) AS txn_count
  FROM catalog_sales cs
  WHERE cs.cs_sold_date_sk IS NOT NULL
  GROUP BY cs.cs_sold_date_sk, cs.cs_item_sk
),
web_sales_agg AS (
  SELECT
    ws.ws_sold_date_sk AS date_sk,
    ws.ws_item_sk AS item_sk,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(*) AS txn_count
  FROM web_sales ws
  WHERE ws.ws_sold_date_sk IS NOT NULL
  GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
all_sales_items AS (
  SELECT
    date_sk,
    item_sk,
    total_net_paid,
    total_net_profit,
    txn_count,
    'store' AS channel
  FROM store_sales_agg
  UNION ALL
  SELECT
    date_sk,
    item_sk,
    total_net_paid,
    total_net_profit,
    txn_count,
    'catalog' AS channel
  FROM catalog_sales_agg
  UNION ALL
  SELECT
    date_sk,
    item_sk,
    total_net_paid,
    total_net_profit,
    txn_count,
    'web' AS channel
  FROM web_sales_agg
),
sales_without_negative AS (
  SELECT *
  FROM all_sales_items
  EXCEPT
  SELECT 
    date_sk,
    item_sk,
    total_net_paid,
    total_net_profit,
    txn_count,
    channel
  FROM all_sales_items
  WHERE total_net_profit < 0
),
store_catalog_combined AS (
  SELECT
    COALESCE(ss.date_sk, cs.date_sk) AS date_sk,
    COALESCE(ss.item_sk, cs.item_sk) AS item_sk,
    ss.total_net_paid AS store_net_paid,
    cs.total_net_paid AS catalog_net_paid,
    ss.total_net_profit AS store_net_profit,
    cs.total_net_profit AS catalog_net_profit
  FROM store_sales_agg ss
  FULL OUTER JOIN catalog_sales_agg cs
    ON ss.date_sk = cs.date_sk AND ss.item_sk = cs.item_sk
),
top_items AS (
  SELECT
    s.date_sk,
    s.item_sk,
    s.channel,
    s.total_net_paid,
    s.total_net_profit,
    s.txn_count,
    ROW_NUMBER() OVER (PARTITION BY s.date_sk, s.channel ORDER BY s.total_net_profit DESC NULLS LAST) AS profit_rank,
    RANK() OVER (PARTITION BY s.date_sk, s.channel ORDER BY s.total_net_paid DESC NULLS LAST) AS paid_rank,
    CASE
      WHEN s.total_net_paid = 0 THEN NULL
      ELSE s.total_net_profit / s.total_net_paid
    END AS profit_margin
  FROM sales_without_negative s
),
top_10_items AS (
  SELECT *
  FROM top_items
  WHERE profit_rank <= 10
),
returns_agg AS (
  SELECT
    sr.sr_returned_date_sk AS date_sk,
    sr.sr_item_sk AS item_sk,
    SUM(sr.sr_net_loss) AS total_return_loss
  FROM store_returns sr
  GROUP BY sr.sr_returned_date_sk, sr.sr_item_sk
  UNION ALL
  SELECT
    cr.cr_returned_date_sk AS date_sk,
    cr.cr_item_sk AS item_sk,
    SUM(cr.cr_net_loss) AS total_return_loss
  FROM catalog_returns cr
  GROUP BY cr.cr_returned_date_sk, cr.cr_item_sk
  UNION ALL
  SELECT
    wr.wr_returned_date_sk AS date_sk,
    wr.wr_item_sk AS item_sk,
    SUM(wr.wr_net_loss) AS total_return_loss
  FROM web_returns wr
  GROUP BY wr.wr_returned_date_sk, wr.wr_item_sk
),
total_returns AS (
  SELECT
    date_sk,
    item_sk,
    SUM(total_return_loss) AS total_return_loss
  FROM returns_agg
  GROUP BY date_sk, item_sk
)
SELECT
  d.d_date AS sale_date,
  i.i_item_id,
  i.i_product_name,
  ti.channel,
  ti.total_net_paid,
  ti.total_net_profit,
  ti.profit_margin,
  ti.profit_rank,
  ti.paid_rank,
  COALESCE(rt.total_return_loss, 0) AS total_return_loss,
  (SELECT AVG(s2.total_net_profit)
   FROM sales_without_negative s2
   WHERE s2.item_sk = ti.item_sk) AS avg_item_profit_across_dates,
  (SELECT MAX(s3.total_net_paid)
   FROM sales_without_negative s3
   WHERE s3.item_sk = ti.item_sk) AS max_net_paid_across_channels,
  COALESCE(scc.store_net_profit, 0) + COALESCE(scc.catalog_net_profit, 0) AS combined_store_catalog_net_profit,
  CONCAT(i.i_brand, '-', i.i_class) AS brand_class,
  REGEXP_REPLACE(LOWER(i.i_product_name), '[^a-z0-9]', '') AS normalized_product_name,
  CASE WHEN EXISTS (
    SELECT 1 FROM total_returns tr2
    WHERE tr2.item_sk = ti.item_sk
  ) THEN TRUE ELSE FALSE END AS any_returns_flag,
  (SELECT MAX(d2.d_date)
   FROM total_returns trd
   JOIN date_dim d2 ON d2.d_date_sk = trd.date_sk
   WHERE trd.item_sk = ti.item_sk) AS last_return_date,
  lm.profit_margin_check
FROM top_10_items ti
LEFT JOIN total_returns rt
  ON rt.date_sk = ti.date_sk AND rt.item_sk = ti.item_sk
JOIN date_dim d
  ON d.d_date_sk = ti.date_sk
JOIN item i
  ON i.i_item_sk IS NOT DISTINCT FROM ti.item_sk
LEFT JOIN store_catalog_combined scc
  ON scc.date_sk = ti.date_sk AND scc.item_sk = ti.item_sk
CROSS JOIN LATERAL (
  SELECT 
    CASE 
      WHEN ti.total_net_paid > 0 THEN ti.total_net_profit / ti.total_net_paid
      ELSE NULL
    END AS profit_margin_check
) lm
WHERE ti.total_net_profit IS NOT NULL 
  AND ti.total_net_paid IS NOT NULL
  AND (ti.channel = 'store' OR ti.channel = 'catalog' OR ti.channel = 'web')
  AND (i.i_color IS NOT NULL OR i.i_color IS NULL)
ORDER BY sale_date DESC, profit_margin DESC
LIMIT 200
