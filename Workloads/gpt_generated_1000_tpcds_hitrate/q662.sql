WITH cc_date AS (
    SELECT
        cc.cc_state,
        cc.cc_employees,
        d.d_date_sk,
        d.d_year,
        d.d_current_day,
        d.d_following_holiday,
        d.d_weekend,
        d.d_date
    FROM call_center cc
    JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
    WHERE cc.cc_state = 'CA'
      AND cc.cc_employees > 50
      AND d.d_current_day = 'N'
      AND d.d_following_holiday = 'N'
      AND d.d_weekend = 'N'
      AND d.d_year = 1998
      AND d.d_date >= DATE '1998-01-01'
      AND d.d_date <= DATE '1998-12-31'
)
SELECT
    ccd.cc_state,
    ccd.d_year,
    COUNT(DISTINCT p.p_promo_id) AS promo_cnt,
    SUM(p.p_cost) AS total_cost,
    AVG(p.p_cost) AS avg_cost,
    MIN(p.p_cost) AS min_cost,
    MAX(p.p_cost) AS max_cost,
    CASE WHEN ccd.cc_employees > 100 THEN 'Large' ELSE 'Small' END AS size_category,
    (
        SELECT COUNT(*)
        FROM promotion p2
        WHERE p2.p_start_date_sk = ccd.d_date_sk
    ) AS promos_on_same_day
FROM cc_date ccd
JOIN promotion p
    ON p.p_start_date_sk = ccd.d_date_sk
WHERE p.p_cost > 500
  AND p.p_purpose = 'Unknown'
  AND p.p_channel_event = 'N'
  AND NOT EXISTS (
        SELECT 1
        FROM promotion p3
        WHERE p3.p_end_date_sk = ccd.d_date_sk
          AND p3.p_discount_active = 'Y'
    )
GROUP BY
    ccd.cc_state,
    ccd.d_year,
    ccd.cc_employees,
    ccd.d_date_sk
ORDER BY total_cost DESC
LIMIT 100
