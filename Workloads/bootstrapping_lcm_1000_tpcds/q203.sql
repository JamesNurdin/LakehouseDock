WITH promo_dates AS (
    SELECT
        p.p_promo_sk,
        p.p_cost,
        p.p_discount_active,
        p.p_start_date_sk,
        p.p_end_date_sk,
        start_date.d_year AS start_year,
        start_date.d_month_seq AS start_month_seq,
        end_date.d_year AS end_year,
        end_date.d_month_seq AS end_month_seq,
        p.p_promo_id
    FROM promotion p
    JOIN date_dim start_date
        ON p.p_start_date_sk = start_date.d_date_sk
    JOIN date_dim end_date
        ON p.p_end_date_sk = end_date.d_date_sk
)
SELECT
    d.d_year,
    d.d_month_seq,
    s.s_state,
    s.s_city,
    COUNT(DISTINCT wp.wp_web_page_sk) AS num_pages,
    SUM(pd.p_cost) AS total_promo_cost,
    AVG(s.s_tax_percentage) AS avg_store_tax,
    MAX(ws_open.web_open_date_sk) AS latest_open_date_sk,
    MIN(ws_close.web_close_date_sk) AS earliest_close_date_sk,
    COUNT(DISTINCT CASE WHEN wp.wp_type = 'product' THEN wp.wp_web_page_sk END) AS product_page_count,
    SUM(CASE WHEN pd.p_discount_active = 'Y' THEN pd.p_cost ELSE 0 END) AS discounted_promo_cost,
    AVG(CASE WHEN d.d_weekend = 'Y' THEN pd.p_cost END) AS avg_weekend_promo_cost,
    AVG(pd.end_year - pd.start_year) AS avg_promo_duration_years,
    AVG(pd.end_month_seq - pd.start_month_seq) AS avg_promo_duration_months
FROM date_dim d
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN promo_dates pd
    ON pd.p_start_date_sk = d.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
JOIN web_site ws_open
    ON ws_open.web_open_date_sk = d.d_date_sk
JOIN web_site ws_close
    ON ws_close.web_close_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
  AND s.s_state IS NOT NULL
  AND pd.p_cost > 0
GROUP BY d.d_year, d.d_month_seq, s.s_state, s.s_city
HAVING COUNT(DISTINCT wp.wp_web_page_sk) > 10
ORDER BY d.d_year DESC, total_promo_cost DESC
LIMIT 100
