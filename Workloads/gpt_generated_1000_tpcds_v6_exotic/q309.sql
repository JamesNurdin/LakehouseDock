WITH store_aggs AS (
  SELECT
    d.d_month_seq AS month_seq,
    i.i_category AS category,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    'store' AS source
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE d.d_year = 2001
    AND s.s_state = 'CA'
  GROUP BY d.d_month_seq, i.i_category
),
catalog_aggs AS (
  SELECT
    d.d_month_seq AS month_seq,
    i.i_category AS category,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    'catalog' AS source
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  WHERE d.d_year = 2001
    AND cc.cc_state = 'CA'
  GROUP BY d.d_month_seq, i.i_category
)
SELECT month_seq, category, total_sales, source
FROM (
  SELECT month_seq, category, total_sales, source FROM store_aggs
  UNION ALL
  SELECT month_seq, category, total_sales, source FROM catalog_aggs
) AS combined
ORDER BY month_seq, category, source
LIMIT 100
