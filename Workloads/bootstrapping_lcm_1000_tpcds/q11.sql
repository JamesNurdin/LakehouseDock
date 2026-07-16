SELECT
    cp.cp_department,
    cp.cp_type,
    s.s_state,
    s.s_city,
    wp.wp_type,
    d_return.d_year AS return_year,
    CASE
        WHEN d_return.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d_return.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d_return.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS return_quarter,
    COUNT(DISTINCT wr.wr_order_number) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_fee) AS total_fee,
    AVG(wr.wr_return_tax) AS avg_return_tax,
    SUM(wr.wr_return_amt) / NULLIF(SUM(wr.wr_fee), 0) AS return_to_fee_ratio,
    MIN(d_catalog_end.d_date) AS catalog_end_date,
    MIN(d_page_creation.d_date) AS page_creation_date,
    MAX(d_page_access.d_date) AS page_access_date
FROM web_returns wr
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_return.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
JOIN date_dim d_catalog_end
    ON cp.cp_end_date_sk = d_catalog_end.d_date_sk
JOIN date_dim d_page_creation
    ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
JOIN date_dim d_page_access
    ON wp.wp_access_date_sk = d_page_access.d_date_sk
WHERE d_return.d_year >= 2020
GROUP BY
    cp.cp_department,
    cp.cp_type,
    s.s_state,
    s.s_city,
    wp.wp_type,
    d_return.d_year,
    CASE
        WHEN d_return.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d_return.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d_return.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END
HAVING COUNT(DISTINCT wr.wr_order_number) > 5
ORDER BY total_return_amount DESC
LIMIT 100
