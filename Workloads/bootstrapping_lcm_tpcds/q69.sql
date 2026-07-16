SELECT
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month,
    s.s_market_desc AS market_desc,
    r.r_reason_desc AS reason_desc,
    wp.wp_type AS page_type,
    CASE WHEN wr.wr_return_quantity > 1 THEN 'Multiple' ELSE 'Single' END AS return_quantity_category,
    CASE WHEN d_ret.d_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_amt_inc_tax) AS avg_return_amt_inc_tax,
    SUM(CASE WHEN wr.wr_return_quantity > 1 THEN wr.wr_return_amt ELSE 0 END) AS multi_item_return_amount,
    MIN(d_creation.d_current_day) AS page_creation_day,
    MIN(d_access.d_current_day) AS page_access_day
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_creation
    ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_market_desc,
    r.r_reason_desc,
    wp.wp_type,
    CASE WHEN wr.wr_return_quantity > 1 THEN 'Multiple' ELSE 'Single' END,
    CASE WHEN d_ret.d_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END
HAVING
    SUM(wr.wr_return_amt) > 500
ORDER BY total_return_amount DESC
LIMIT 100
