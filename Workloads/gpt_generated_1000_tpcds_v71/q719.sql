WITH filtered_promos AS (
    SELECT DISTINCT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_start_date_sk,
        p.p_end_date_sk,
        p.p_channel_details
    FROM promotion p
    WHERE regexp_like(p.p_promo_name, '[A-Z]{3}')
      AND p.p_channel_details LIKE '%online%'
)
SELECT
    COALESCE(fp.p_promo_name, 'All Promotions') AS promo_name,
    d.d_year,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    CONCAT(COALESCE(fp.p_promo_name, 'N/A'), ' - ', CAST(d.d_year AS VARCHAR)) AS promo_year_label
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
LEFT JOIN filtered_promos fp
    ON d.d_date_sk BETWEEN fp.p_start_date_sk AND fp.p_end_date_sk
WHERE t.t_meal_time LIKE 'break%'
  AND NOT EXISTS (
        SELECT 1
        FROM promotion p_ex
        WHERE p_ex.p_promo_name = fp.p_promo_name
          AND regexp_like(p_ex.p_promo_name, 'clearance')
    )
  AND EXISTS (
        SELECT 1
        FROM web_page wp
        JOIN date_dim d_wp ON wp.wp_creation_date_sk = d_wp.d_date_sk
        WHERE d_wp.d_date_sk = d.d_date_sk
          AND wp.wp_url LIKE 'http%://%/sale/%'
          AND regexp_like(wp.wp_url, '^https?://[^/]+\\.example\\.com/')
    )
GROUP BY ROLLUP(fp.p_promo_name, d.d_year)
ORDER BY total_net_loss DESC
LIMIT 100
