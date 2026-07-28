WITH page_sales AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_description,
        d.d_year,
        p.p_promo_name,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_page cp
    JOIN catalog_sales cs ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 1905
      AND regexp_like(cp.cp_description, '\\d{2,}')
      AND p.p_promo_name LIKE '%Clearance%'
    GROUP BY cp.cp_catalog_page_sk, cp.cp_department, cp.cp_description, d.d_year, p.p_promo_name
)
SELECT
    ps.cp_department,
    regexp_extract(ps.cp_description, '^([A-Za-z]+)') AS first_word,
    ps.d_year,
    ps.p_promo_name,
    ps.total_profit,
    ps.sales_cnt,
    CONCAT('Dept-', ps.cp_department) AS dept_code
FROM page_sales ps
WHERE ps.total_profit > (
    SELECT AVG(total_profit) FROM page_sales
)
  AND EXISTS (
    SELECT 1 FROM store s WHERE s.s_market_desc LIKE '%Local%'
  )
ORDER BY ps.total_profit DESC
LIMIT 10
