WITH catalog_agg AS (
  SELECT
    cs.cs_item_sk AS item_sk,
    d.d_year,
    SUM(cs.cs_net_paid) AS catalog_net_paid,
    SUM(cs.cs_ext_discount_amt) AS catalog_discount,
    COUNT(*) AS catalog_txn_count,
    MAX(cs.cs_sales_price) AS max_sales_price
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  GROUP BY cs.cs_item_sk, d.d_year
),
store_agg AS (
  SELECT
    ss.ss_item_sk AS item_sk,
    d.d_year,
    SUM(ss.ss_net_paid) AS store_net_paid,
    SUM(ss.ss_ext_discount_amt) AS store_discount,
    COUNT(*) AS store_txn_count,
    MAX(ss.ss_sales_price) AS max_sales_price
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  GROUP BY ss.ss_item_sk, d.d_year
),
web_agg AS (
  SELECT
    ws.ws_item_sk AS item_sk,
    d.d_year,
    SUM(ws.ws_net_paid) AS web_net_paid,
    SUM(ws.ws_ext_discount_amt) AS web_discount,
    COUNT(*) AS web_txn_count,
    MAX(ws.ws_sales_price) AS max_sales_price
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  GROUP BY ws.ws_item_sk, d.d_year
),
item_sales AS (
  SELECT
    COALESCE(ca.item_sk, sa.item_sk, wa.item_sk) AS item_sk,
    COALESCE(ca.d_year, sa.d_year, wa.d_year) AS d_year,
    COALESCE(ca.catalog_net_paid, 0) AS catalog_net_paid,
    COALESCE(sa.store_net_paid, 0) AS store_net_paid,
    COALESCE(wa.web_net_paid, 0) AS web_net_paid,
    COALESCE(ca.catalog_discount, 0) AS catalog_discount,
    COALESCE(sa.store_discount, 0) AS store_discount,
    COALESCE(wa.web_discount, 0) AS web_discount,
    COALESCE(ca.catalog_txn_count, 0) AS catalog_txn_count,
    COALESCE(sa.store_txn_count, 0) AS store_txn_count,
    COALESCE(wa.web_txn_count, 0) AS web_txn_count,
    GREATEST(
      COALESCE(ca.max_sales_price, 0),
      COALESCE(sa.max_sales_price, 0),
      COALESCE(wa.max_sales_price, 0)
    ) AS max_sales_price
  FROM catalog_agg ca
  FULL OUTER JOIN store_agg sa
    ON ca.item_sk = sa.item_sk AND ca.d_year = sa.d_year
  FULL OUTER JOIN web_agg wa
    ON COALESCE(ca.item_sk, sa.item_sk) = wa.item_sk
       AND COALESCE(ca.d_year, sa.d_year) = wa.d_year
),
sales_ranked AS (
  SELECT
    isr.*,
    i.i_product_name,
    i.i_current_price,
    (SELECT MAX(cs2.cs_sales_price)
     FROM catalog_sales cs2
     JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
     WHERE cs2.cs_item_sk = isr.item_sk
       AND d2.d_year > isr.d_year
    ) AS future_max_price,
    RANK() OVER (PARTITION BY isr.d_year ORDER BY (isr.catalog_net_paid + isr.store_net_paid + isr.web_net_paid) DESC) AS sales_rank,
    ROW_NUMBER() OVER (PARTITION BY isr.item_sk ORDER BY isr.d_year) AS year_seq
  FROM item_sales isr
  LEFT JOIN item i ON isr.item_sk = i.i_item_sk
),
returns AS (
  SELECT
    r.item_sk,
    COUNT(DISTINCT sr.sr_return_quantity) AS store_return_qty,
    COUNT(DISTINCT wr.wr_return_quantity) AS web_return_qty
  FROM (
    SELECT cs_item_sk AS item_sk FROM catalog_sales
    UNION ALL
    SELECT ss_item_sk AS item_sk FROM store_sales
    UNION ALL
    SELECT ws_item_sk AS item_sk FROM web_sales
  ) r
  LEFT JOIN store_returns sr ON r.item_sk = sr.sr_item_sk
  LEFT JOIN web_returns wr ON r.item_sk = wr.wr_item_sk
  GROUP BY r.item_sk
),
customer_stats AS (
  SELECT
    cs.item_sk,
    COUNT(DISTINCT cs.cust_sk) AS distinct_customer_cnt,
    SUM(cs.spent) AS total_spent
  FROM (
    SELECT cs.cs_item_sk AS item_sk, cs.cs_bill_customer_sk AS cust_sk, cs.cs_net_paid AS spent
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_item_sk, ss.ss_customer_sk, ss.ss_net_paid
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_item_sk, ws.ws_bill_customer_sk, ws.ws_net_paid
    FROM web_sales ws
  ) cs
  GROUP BY cs.item_sk
)
SELECT
  srk.d_year,
  srk.item_sk,
  srk.i_product_name,
  srk.catalog_net_paid,
  srk.store_net_paid,
  srk.web_net_paid,
  srk.catalog_discount + srk.store_discount + srk.web_discount AS total_discount,
  CASE
    WHEN srk.future_max_price IS NULL THEN 0
    ELSE srk.future_max_price - srk.i_current_price
  END AS future_price_diff,
  COALESCE(ret.store_return_qty, 0) AS store_return_qty,
  COALESCE(ret.web_return_qty, 0) AS web_return_qty,
  COALESCE(cs.distinct_customer_cnt, 0) AS distinct_customer_cnt,
  COALESCE(cs.total_spent, 0) AS total_spent,
  CONCAT(srk.i_product_name, ' (', COALESCE(CAST(srk.d_year AS varchar), 'Unknown'), ')') AS product_label,
  CASE WHEN srk.sales_rank <= 5 THEN 'Top5' ELSE 'Other' END AS rank_category,
  NULLIF(srk.sales_rank, 0) AS nullable_rank,
  SUM(srk.catalog_net_paid + srk.store_net_paid + srk.web_net_paid) OVER (PARTITION BY srk.item_sk ORDER BY srk.d_year) AS cumulative_net_paid,
  EXISTS (
    SELECT 1
    FROM returns r2
    WHERE r2.item_sk = srk.item_sk
      AND r2.store_return_qty > 0
      AND srk.d_year < (SELECT MAX(d_year) FROM date_dim)
  ) AS has_future_store_returns
FROM
  sales_ranked srk
  LEFT JOIN returns ret ON srk.item_sk = ret.item_sk
  LEFT JOIN customer_stats cs ON srk.item_sk = cs.item_sk
WHERE
  srk.year_seq = 1
  AND (srk.catalog_net_paid > 0 OR srk.store_net_paid > 0 OR srk.web_net_paid > 0)
UNION ALL
SELECT
  d.d_year,
  i.i_item_sk,
  i.i_product_name,
  0.0,
  0.0,
  0.0,
  0.0,
  NULL,
  0,
  0,
  NULL,
  NULL,
  CONCAT(i.i_product_name, ' (', CAST(d.d_year AS varchar), ')') AS product_label,
  'NoSales' AS rank_category,
  NULL AS nullable_rank,
  0.0 AS cumulative_net_paid,
  FALSE AS has_future_store_returns
FROM
  item i
  CROSS JOIN (SELECT DISTINCT d_year FROM date_dim WHERE d_year BETWEEN 2000 AND 2002) d
WHERE NOT EXISTS (
  SELECT 1 FROM sales_ranked sr
  WHERE sr.item_sk = i.i_item_sk AND sr.d_year = d.d_year
)
