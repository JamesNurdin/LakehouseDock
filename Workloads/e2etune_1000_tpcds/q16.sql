WITH cust_pages AS (
    SELECT
        wp_customer_sk,
        COUNT(*) AS page_cnt,
        SUM(wp_char_count) AS total_char,
        AVG(wp_link_count) AS avg_links,
        SUM(wp_image_count) AS total_images,
        MAX(wp_rec_end_date) AS latest_end_date
    FROM web_page
    WHERE wp_rec_end_date >= DATE '2000-01-01'
      AND wp_type = 'article'
    GROUP BY wp_customer_sk
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(*) AS num_customers,
    AVG(cp.page_cnt) AS avg_pages_per_cust,
    SUM(cp.total_char) AS total_char_all,
    AVG(cp.total_char) AS avg_char_per_cust,
    RANK() OVER (ORDER BY AVG(cp.total_char) DESC) AS rank_by_avg_char
FROM cust_pages cp
JOIN income_band ib
  ON cp.page_cnt BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY avg_pages_per_cust DESC
LIMIT 10
