WITH store_daily AS (
    SELECT sr_returned_date_sk AS date_sk,
           SUM(sr_net_loss) AS store_net_loss,
           COUNT(*) AS store_return_cnt,
           SUM(sr_return_quantity) AS store_return_qty
    FROM store_returns
    GROUP BY sr_returned_date_sk
),
web_daily AS (
    SELECT wr_returned_date_sk AS date_sk,
           SUM(wr_net_loss) AS web_net_loss,
           COUNT(*) AS web_return_cnt,
           SUM(wr_return_quantity) AS web_return_qty
    FROM web_returns
    GROUP BY wr_returned_date_sk
),
page_metrics AS (
    SELECT wp_creation_date_sk AS date_sk,
           COUNT(DISTINCT wp_web_page_sk) AS pages_created,
           AVG(wp_char_count) AS avg_char_count,
           AVG(wp_link_count) AS avg_link_count
    FROM web_page
    GROUP BY wp_creation_date_sk
)
SELECT
    d.d_date AS report_date,
    d.d_year,
    d.d_month_seq,
    d.d_day_name,
    COALESCE(sd.store_net_loss, 0) AS store_net_loss,
    COALESCE(wd.web_net_loss, 0) AS web_net_loss,
    COALESCE(pm.pages_created, 0) AS pages_created,
    (COALESCE(sd.store_net_loss, 0) + COALESCE(wd.web_net_loss, 0)) AS total_net_loss,
    RANK() OVER (ORDER BY (COALESCE(sd.store_net_loss, 0) + COALESCE(wd.web_net_loss, 0)) DESC) AS loss_rank,
    SUM(COALESCE(sd.store_net_loss, 0) + COALESCE(wd.web_net_loss, 0)) OVER (ORDER BY d.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_loss,
    AVG(COALESCE(sd.store_net_loss, 0) + COALESCE(wd.web_net_loss, 0)) OVER (ORDER BY d.d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7day_net_loss,
    CASE
        WHEN d.d_holiday = 'Y' THEN 'Holiday'
        WHEN d.d_weekend = 'Y' THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type
FROM date_dim d
LEFT JOIN store_daily sd ON d.d_date_sk = sd.date_sk
LEFT JOIN web_daily wd ON d.d_date_sk = wd.date_sk
LEFT JOIN page_metrics pm ON d.d_date_sk = pm.date_sk
WHERE d.d_year = 2022
ORDER BY d.d_date
