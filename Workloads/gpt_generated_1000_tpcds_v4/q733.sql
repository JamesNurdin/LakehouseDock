WITH filtered_sales AS (
  SELECT
    cp.cp_department AS department,
    d.d_year AS year,
    cs.cs_net_profit,
    i.i_item_desc,
    p.p_promo_name
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE regexp_like(cp.cp_description, '(?i)special')
    AND i.i_item_desc LIKE '%steel%'
    AND cp.cp_department LIKE 'Electronics%'
)
SELECT
  department,
  year,
  SUM(cs_net_profit) AS total_net_profit,
  COUNT(*) AS sales_cnt,
  CASE
    WHEN SUM(cs_net_profit) > 100000 THEN 'HIGH'
    WHEN SUM(cs_net_profit) > 50000 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS profit_category,
  ROW_NUMBER() OVER (PARTITION BY department ORDER BY SUM(cs_net_profit) DESC) AS dept_rank,
  concat(department, '-', CAST(year AS varchar)) AS dept_year_key,
  regexp_extract(MAX(i_item_desc), '^([^ ]+)') AS first_word_item_desc
FROM filtered_sales
GROUP BY department, year
ORDER BY total_net_profit DESC
LIMIT 100
