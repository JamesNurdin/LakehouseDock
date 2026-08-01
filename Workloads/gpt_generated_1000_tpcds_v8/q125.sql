WITH filtered_sales AS (
  SELECT
    cs.cs_order_number,
    cs.cs_net_profit,
    cs.cs_ext_sales_price,
    cs.cs_quantity,
    cs.cs_sold_time_sk,
    cp.cp_department,
    cp.cp_description,
    t.t_shift,
    CASE
      WHEN cs.cs_net_profit > 1000 THEN 'HIGH'
      WHEN cs.cs_net_profit > 0 THEN 'MEDIUM'
      ELSE 'LOW'
    END AS profit_category,
    regexp_extract(cp.cp_description, '(\\w+)', 1) AS first_word
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  WHERE regexp_like(cp.cp_description, '.*[0-9]{3}.*')
    AND EXISTS (
      SELECT 1
      FROM web_sales ws
      JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
      WHERE ws.ws_order_number = cs.cs_order_number
        AND wp.wp_url LIKE '%shop%'
    )
),
agg_sales AS (
  SELECT
    cp_department,
    t_shift,
    profit_category,
    COUNT(*) AS sales_count,
    SUM(cs_ext_sales_price) AS total_sales,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    AVG(cs_net_profit) AS avg_profit,
    MAX(first_word) AS sample_first_word
  FROM filtered_sales
  GROUP BY cp_department, t_shift, profit_category
)
SELECT
  cp_department,
  t_shift,
  profit_category,
  sales_count,
  total_sales,
  distinct_orders,
  avg_profit,
  sample_first_word,
  ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_sales DESC) AS dept_sales_rank
FROM agg_sales
ORDER BY total_sales DESC
LIMIT 100
