WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_promo_sk,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(*) AS order_cnt,
        MAX(ws.ws_sold_date_sk) AS max_date_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 18
    GROUP BY ws.ws_web_site_sk, ws.ws_promo_sk
)
SELECT
    sa.ws_web_site_sk,
    w.web_city,
    w.web_state,
    CONCAT(w.web_city, ', ', w.web_state) AS location,
    p.p_promo_name,
    CASE
        WHEN regexp_like(p.p_promo_name, '(?i)Clearance|Discount') THEN 'Clearance/Discount'
        ELSE 'Other'
    END AS promo_category,
    regexp_extract(p.p_promo_name, '(\\d{4})', 1) AS promo_year_extracted,
    sa.total_net_paid,
    sa.order_cnt,
    (sa.total_net_paid / sa.order_cnt) AS avg_net_paid,
    sa.total_net_paid * CASE WHEN sa.total_net_paid > 100000 THEN 0.9 ELSE 1.0 END AS adjusted_total,
    d2.d_date AS max_sale_date,
    (
        SELECT COUNT(*)
        FROM household_demographics hd
        WHERE hd.hd_income_band_sk = 4
    ) AS demo_income_band_4_cnt,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM promotion p2
            WHERE p2.p_promo_sk = sa.ws_promo_sk
              AND regexp_like(p2.p_promo_name, '(?i)Clearance')
        ) THEN 1
        ELSE 0
    END AS has_clearance_promo
FROM sales_agg sa
JOIN promotion p ON sa.ws_promo_sk = p.p_promo_sk
JOIN web_site w ON sa.ws_web_site_sk = w.web_site_sk
JOIN date_dim d2 ON sa.max_date_sk = d2.d_date_sk
WHERE w.web_city LIKE 'S%'
  AND regexp_like(p.p_promo_name, '(?i)Sale')
ORDER BY sa.total_net_paid DESC
LIMIT 100
