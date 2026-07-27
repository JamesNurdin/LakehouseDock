WITH combined AS (
    -- Sales from physical stores (first half of the year, business hours)
    SELECT 
        d.d_fy_week_seq AS fy_week,
        d.d_fy_year AS fy_year,
        SUM(ss.ss_net_paid) AS amount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE d.d_moy BETWEEN 1 AND 6               -- Jan‑Jun
      AND t.t_hour BETWEEN 9 AND 17            -- 9 AM‑5 PM business hours
    GROUP BY d.d_fy_week_seq, d.d_fy_year

    UNION ALL

    -- Returns from the web (second half of the year, high‑content pages)
    SELECT 
        d.d_fy_week_seq AS fy_week,
        d.d_fy_year AS fy_year,
        -SUM(wr.wr_net_loss) AS amount   -- treat loss as negative revenue
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_moy BETWEEN 7 AND 12                -- Jul‑Dec
      AND wp.wp_char_count > 2000                -- large pages
    GROUP BY d.d_fy_week_seq, d.d_fy_year
)
SELECT
    fy_week,
    fy_year,
    SUM(amount) AS total_amount
FROM combined
GROUP BY fy_week, fy_year
HAVING SUM(amount) > 10000                     -- keep only significant weeks
ORDER BY total_amount DESC
