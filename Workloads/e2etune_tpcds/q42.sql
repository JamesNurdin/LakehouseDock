WITH base AS (
    SELECT
        cp.cp_department AS dept,
        d_start.d_quarter_name AS quarter,
        COUNT(DISTINCT cp.cp_catalog_page_sk) AS catalog_page_cnt,
        AVG(p.p_cost) AS avg_promo_cost,
        SUM(CASE WHEN s.s_store_sk IS NOT NULL THEN 1 ELSE 0 END) AS stores_closed_cnt,
        COUNT(DISTINCT wp.wp_web_page_sk) AS web_page_cnt
    FROM catalog_page cp
    JOIN date_dim d_start
        ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON cp.cp_end_date_sk = d_end.d_date_sk
    LEFT JOIN promotion p
        ON p.p_start_date_sk = d_start.d_date_sk
        AND p.p_discount_active = 'Y'
    LEFT JOIN store s
        ON s.s_closed_date_sk = d_end.d_date_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d_start.d_date_sk
    WHERE cp.cp_type = 'monthly'
      AND d_start.d_year = 2001
    GROUP BY cp.cp_department, d_start.d_quarter_name
    HAVING COUNT(DISTINCT cp.cp_catalog_page_sk) > 5
)
SELECT
    dept,
    quarter,
    catalog_page_cnt,
    avg_promo_cost,
    stores_closed_cnt,
    web_page_cnt,
    DENSE_RANK() OVER (PARTITION BY dept ORDER BY avg_promo_cost DESC) AS promo_cost_rank
FROM base
ORDER BY avg_promo_cost DESC
LIMIT 50
