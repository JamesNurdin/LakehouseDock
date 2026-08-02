WITH aggregated_sales AS (
    SELECT
        ss.ss_store_sk,
        s.s_store_name,
        d.d_year,
        i.i_brand_id,
        i.i_category,
        SUM(ss.ss_net_paid) AS total_net_paid,
        MAX(CASE WHEN p.p_promo_sk IS NOT NULL THEN 1 ELSE 0 END) AS has_promo
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i.i_category = 'Sports'
    GROUP BY
        ss.ss_store_sk,
        s.s_store_name,
        d.d_year,
        i.i_brand_id,
        i.i_category
),
ranked_sales AS (
    SELECT
        ss_store_sk,
        s_store_name,
        d_year,
        i_brand_id,
        i_category,
        total_net_paid,
        has_promo,
        ROW_NUMBER() OVER (PARTITION BY s_store_name, d_year ORDER BY total_net_paid DESC) AS store_year_rank
    FROM aggregated_sales
)
SELECT
    diff.s_store_name,
    diff.d_year,
    diff.brand_group,
    diff.total_net_paid,
    diff.store_year_rank
FROM (
    SELECT DISTINCT
        s_store_name,
        d_year,
        CASE WHEN i_brand_id = 1001001 THEN 'BrandA' ELSE 'OtherBrand' END AS brand_group,
        total_net_paid,
        store_year_rank
    FROM ranked_sales
    WHERE total_net_paid > 5000
      AND has_promo = 0
    EXCEPT
    SELECT DISTINCT
        s_store_name,
        d_year,
        CASE WHEN i_brand_id = 1001001 THEN 'BrandA' ELSE 'OtherBrand' END AS brand_group,
        total_net_paid,
        store_year_rank
    FROM ranked_sales
    WHERE total_net_paid > 5000
      AND has_promo = 1
) AS diff
ORDER BY diff.s_store_name, diff.d_year
LIMIT 100
