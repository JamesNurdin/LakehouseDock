WITH
  promo_match AS (
    SELECT
      p.p_promo_sk,
      p.p_promo_name,
      regexp_extract(p.p_promo_name, '(\\d+)%', 1) AS discount_pct
    FROM promotion p
    WHERE regexp_like(p.p_promo_name, '(?i)discount')
  ),
  years AS (
    SELECT DISTINCT d.d_year
    FROM date_dim d
    WHERE d.d_year BETWEEN 2000 AND 2002
  ),
  rank_cutoff AS (
    SELECT 1 AS rank_cutoff UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 5
  )
SELECT
  agg.d_year,
  agg.cd_gender,
  agg.p_promo_name,
  CONCAT(agg.p_promo_name, ' (', COALESCE(agg.discount_pct, ''), '%)') AS promo_label,
  agg.total_sales,
  agg.order_cnt,
  agg.sales_rank
FROM (
  SELECT
    d.d_year,
    cd.cd_gender,
    pm.p_promo_name,
    pm.discount_pct,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COUNT(*) AS order_cnt,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN promo_match pm ON cs.cs_promo_sk = pm.p_promo_sk
  WHERE EXISTS (
    SELECT 1
    FROM call_center cc
    WHERE cc.cc_call_center_sk = cs.cs_call_center_sk
      AND regexp_like(cc.cc_name, '^.*Center.*$')
      AND cc.cc_state LIKE 'C%'
  )
    AND d.d_year BETWEEN 2000 AND 2002
  GROUP BY GROUPING SETS (
    (d.d_year, cd.cd_gender, pm.p_promo_name, pm.discount_pct),
    (d.d_year, cd.cd_gender),
    (d.d_year)
  )
) agg
JOIN years y ON agg.d_year = y.d_year
CROSS JOIN rank_cutoff rc
WHERE agg.sales_rank <= rc.rank_cutoff
ORDER BY agg.d_year, agg.sales_rank
LIMIT 100
