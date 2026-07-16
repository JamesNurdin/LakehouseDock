SELECT
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month_seq,
    i.i_category AS item_category,
    i.i_brand AS item_brand,
    s.s_market_desc AS market_description,
    wp.wp_type AS page_type,
    d_ret.d_holiday AS holiday_flag,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount_inc_tax,
    SUM(wr.wr_fee) AS total_fee,
    AVG(wr.wr_return_quantity) AS avg_quantity,
    ROUND(AVG(wr.wr_return_tax), 2) AS avg_return_tax,
    SUM((i.i_current_price - i.i_wholesale_cost) * wr.wr_return_quantity) AS total_margin_diff,
    SUM(CASE WHEN d_create.d_current_year = d_ret.d_current_year THEN wr.wr_return_amt ELSE 0 END) AS same_year_creation_return_amt,
    SUM(CASE WHEN d_access.d_weekend = 'Y' THEN wr.wr_return_amt ELSE 0 END) AS weekend_access_return_amt,
    MIN(wr.wr_returned_date_sk) AS min_return_date_sk,
    MAX(wr.wr_returned_date_sk) AS max_return_date_sk
FROM web_returns wr
JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN item i ON wr.wr_item_sk = i.i_item_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_create ON wp.wp_creation_date_sk = d_create.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    i.i_category,
    i.i_brand,
    s.s_market_desc,
    wp.wp_type,
    d_ret.d_holiday
ORDER BY total_return_amount DESC
LIMIT 100
