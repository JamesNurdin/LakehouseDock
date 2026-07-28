WITH joined_data AS (
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        c.c_preferred_cust_flag,
        wp.wp_link_count,
        wp.wp_web_page_id
    FROM web_page wp
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE c.c_birth_country IN ('MEXICO', 'BAHAMAS', 'CAYMAN ISLANDS')
      AND c.c_preferred_cust_flag = 'Y'
      AND wp.wp_autogen_flag = 'Y'
      AND cd.cd_purchase_estimate > 4000
),
agg_per_income AS (
    SELECT
        ib_lower_bound,
        ib_upper_bound,
        c_preferred_cust_flag,
        SUM(wp_link_count) AS total_links,
        COUNT(DISTINCT wp_web_page_id) AS page_count,
        CASE WHEN SUM(wp_link_count) > 1000 THEN 'High' ELSE 'Low' END AS link_intensity
    FROM joined_data
    GROUP BY ib_lower_bound, ib_upper_bound, c_preferred_cust_flag
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    c_preferred_cust_flag,
    AVG(total_links) AS avg_total_links,
    AVG(page_count) AS avg_page_count,
    link_intensity
FROM agg_per_income
GROUP BY ib_lower_bound, ib_upper_bound, c_preferred_cust_flag, link_intensity
HAVING AVG(total_links) > 200
ORDER BY avg_total_links DESC
LIMIT 100
