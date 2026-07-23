WITH wp_agg AS (
    SELECT
        wp_creation_date_sk,
        COUNT(*) AS page_count,
        SUM(wp_link_count) AS total_links,
        AVG(wp_char_count) AS avg_char_count,
        MAX(wp_rec_end_date) AS latest_rec_end_date
    FROM web_page
    WHERE wp_link_count >= 10
      AND wp_rec_end_date > DATE '1999-12-31'
      AND wp_customer_sk > 1000000
      AND wp_type = 'text/html'
      AND wp_image_count > 0
    GROUP BY wp_creation_date_sk
)
SELECT
    d.d_year,
    d.d_quarter_name,
    d.d_holiday,
    w.page_count,
    w.total_links,
    w.avg_char_count,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY w.total_links DESC) AS rn_total_links,
    RANK() OVER (PARTITION BY d.d_year ORDER BY w.page_count DESC) AS rank_page_count,
    SUM(w.total_links) OVER (PARTITION BY d.d_year ORDER BY d.d_month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_links_by_month
FROM date_dim d
JOIN wp_agg w
    ON d.d_date_sk = w.wp_creation_date_sk
WHERE d.d_holiday = 'N'
  AND d.d_qoy = 2
  AND d.d_year BETWEEN 1999 AND 2001
  AND d.d_day_name = 'Monday'
  AND d.d_weekend = 'N'
ORDER BY d.d_year, rn_total_links
LIMIT 100
