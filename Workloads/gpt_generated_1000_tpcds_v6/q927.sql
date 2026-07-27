WITH total_returns AS (
    SELECT SUM(cr_return_amount) AS overall_return_amount
    FROM catalog_returns cr
),
returns_by_month AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(cr.cr_return_amount) > (SELECT overall_return_amount FROM total_returns) * 0.01
             THEN 'High' ELSE 'Low' END AS return_category,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cr.cr_return_amount) DESC) AS rn
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_current_month = 'Y'
    GROUP BY d.d_year, d.d_month_seq
),
promo_by_month AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        SUM(p.p_cost) AS total_promo_cost,
        COUNT(DISTINCT p.p_promo_id) AS promo_cnt,
        CASE WHEN SUM(p.p_cost) > 10000 THEN 'Expensive' ELSE 'Affordable' END AS promo_category,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(p.p_cost) DESC) AS rn
    FROM promotion p
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_current_month = 'Y'
    GROUP BY d.d_year, d.d_month_seq
)
SELECT *
FROM (
    SELECT
        r.d_year,
        r.month_seq,
        r.total_return_amount AS metric_value,
        r.return_cnt AS metric_count,
        r.return_category AS category,
        r.rn AS rank,
        'Return' AS metric_type
    FROM returns_by_month r
    WHERE r.rn <= 5
    UNION ALL
    SELECT
        p.d_year,
        p.month_seq,
        p.total_promo_cost AS metric_value,
        p.promo_cnt AS metric_count,
        p.promo_category AS category,
        p.rn AS rank,
        'Promotion' AS metric_type
    FROM promo_by_month p
    WHERE p.rn <= 5
) combined
ORDER BY combined.d_year DESC, combined.metric_value DESC
LIMIT 100
