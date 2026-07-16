WITH store_dates AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        s.s_closed_date_sk,
        d.d_date AS closed_date,
        d.d_year AS closed_year,
        d.d_month_seq AS closed_month_seq
    FROM store s
    JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
),
call_center_dates AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_state,
        cc.cc_employees,
        cc.cc_tax_percentage,
        cc.cc_open_date_sk,
        d.d_date AS open_date,
        d.d_year AS open_year
    FROM call_center cc
    JOIN date_dim d
        ON cc.cc_open_date_sk = d.d_date_sk
),
promotion_dates AS (
    SELECT
        p.p_promo_id,
        p.p_cost,
        p.p_discount_active,
        p.p_start_date_sk,
        p.p_end_date_sk,
        d_start.d_date AS start_date,
        d_end.d_date AS end_date
    FROM promotion p
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
),
web_page_dates AS (
    SELECT
        wp.wp_web_page_id,
        wp.wp_image_count,
        wp.wp_char_count,
        wp.wp_creation_date_sk,
        wp.wp_access_date_sk,
        d_creation.d_date AS creation_date,
        d_access.d_date AS access_date
    FROM web_page wp
    JOIN date_dim d_creation
        ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
)
SELECT
    sd.s_store_name,
    sd.s_state,
    sd.closed_date,
    COUNT(DISTINCT wpd.wp_web_page_id) AS web_pages_created_on_store_close,
    SUM(pd.p_cost) AS total_discounted_promo_cost,
    AVG(ccd.cc_employees) AS avg_call_center_employees_opened_same_day,
    SUM(wpd.wp_image_count) AS total_image_count,
    MIN(pd.start_date) AS earliest_promo_start,
    MAX(pd.end_date) AS latest_promo_end
FROM store_dates sd
LEFT JOIN call_center_dates ccd
    ON ccd.cc_open_date_sk = sd.s_closed_date_sk
LEFT JOIN promotion_dates pd
    ON pd.p_start_date_sk = sd.s_closed_date_sk
LEFT JOIN web_page_dates wpd
    ON wpd.wp_creation_date_sk = sd.s_closed_date_sk
WHERE sd.s_state IN ('CA', 'TX', 'NY')
  AND pd.p_discount_active = 'Y'
  AND ccd.cc_tax_percentage > 5.00
GROUP BY sd.s_store_name, sd.s_state, sd.closed_date
HAVING COUNT(DISTINCT wpd.wp_web_page_id) > 0
ORDER BY total_discounted_promo_cost DESC
LIMIT 100
