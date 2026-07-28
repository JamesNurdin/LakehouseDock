WITH aggregated AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        REGEXP_EXTRACT(p.p_promo_name, '(\\d{4})') AS promo_year_code,
        sm.sm_type,
        d.d_year,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_count
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND REGEXP_LIKE(p.p_promo_name, '^Promo')
      AND sm.sm_type LIKE '%AIR%'
    GROUP BY
        p.p_promo_sk,
        p.p_promo_name,
        REGEXP_EXTRACT(p.p_promo_name, '(\\d{4})'),
        sm.sm_type,
        d.d_year
),
ranked AS (
    SELECT
        a.*, 
        ROW_NUMBER() OVER (ORDER BY a.total_sales DESC) AS rn
    FROM aggregated a
)
SELECT
    CONCAT('Promotion ', p_promo_name, ' (', COALESCE(promo_year_code, 'N/A'), ')') AS promo_label,
    sm_type,
    d_year,
    total_sales,
    total_profit,
    order_count,
    rn
FROM ranked
WHERE rn <= 10
ORDER BY total_sales DESC
LIMIT 100
