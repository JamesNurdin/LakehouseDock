SELECT
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month,
    (d_ret.d_month_seq % 2) AS month_parity,
    CASE 
        WHEN d_ret.d_month_seq IN (12, 1, 2) THEN 'Winter'
        WHEN d_ret.d_month_seq IN (3, 4, 5) THEN 'Spring'
        WHEN d_ret.d_month_seq IN (6, 7, 8) THEN 'Summer'
        ELSE 'Fall'
    END AS season,
    c_ret.c_birth_country AS customer_birth_country,
    s.s_market_desc AS store_market,
    ws.web_name AS website_name,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_inc_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(wr.wr_return_amt) + SUM(wr.wr_return_tax) AS total_return_plus_tax,
    MAX(c_ref.c_preferred_cust_flag) AS max_preferred_cust_flag,
    MIN(ws.web_country) AS website_country,
    CASE 
        WHEN SUM(wr.wr_return_amt) > 10000 THEN 'High'
        ELSE 'Low'
    END AS return_volume_category
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN customer c_ret
    ON wr.wr_returning_customer_sk = c_ret.c_customer_sk
JOIN customer c_ref
    ON wr.wr_refunded_customer_sk = c_ref.c_customer_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year BETWEEN 2015 AND 2020
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    (d_ret.d_month_seq % 2),
    CASE 
        WHEN d_ret.d_month_seq IN (12, 1, 2) THEN 'Winter'
        WHEN d_ret.d_month_seq IN (3, 4, 5) THEN 'Spring'
        WHEN d_ret.d_month_seq IN (6, 7, 8) THEN 'Summer'
        ELSE 'Fall'
    END,
    c_ret.c_birth_country,
    s.s_market_desc,
    ws.web_name
HAVING SUM(wr.wr_return_amt) > 0
ORDER BY total_return_amount DESC
LIMIT 100
