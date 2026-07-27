WITH catalog_sales_agg AS (
    SELECT
        cp.cp_department AS category,
        d.d_year AS year,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_promo_sk = cs.cs_promo_sk
          AND p.p_start_date_sk = d.d_date_sk
    )
    GROUP BY cp.cp_department, d.d_year
),
store_sales_agg AS (
    SELECT
        s.s_store_name AS category,
        d.d_year AS year,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE s.s_market_id IS NOT NULL
    GROUP BY s.s_store_name, d.d_year
)
SELECT category, year, total_sales
FROM catalog_sales_agg
UNION ALL
SELECT category, year, total_sales
FROM store_sales_agg
ORDER BY year DESC, total_sales DESC
