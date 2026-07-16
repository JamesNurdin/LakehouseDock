SELECT
    cp.cp_type,
    s.s_city,
    d_return.d_year,
    d_return.d_month_seq,
    COUNT(*) AS return_count,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(CASE WHEN cd_returning.cd_credit_rating = 'A' THEN 1.0 ELSE 0.0 END) AS avg_credit_A_flag,
    COUNT(DISTINCT cd_refunded.cd_demo_sk) AS distinct_refunded_demo,
    COUNT(DISTINCT cd_returning.cd_demo_sk) AS distinct_returning_demo,
    SUM(CASE WHEN cd_returning.cd_gender = 'M' THEN cr.cr_return_quantity ELSE 0 END) AS male_return_quantity,
    SUM(CASE WHEN cd_returning.cd_gender = 'F' THEN cr.cr_return_quantity ELSE 0 END) AS female_return_quantity,
    MIN(d_page_start.d_date) AS page_start_date,
    MAX(d_page_end.d_date) AS page_end_date
FROM catalog_page cp
JOIN catalog_returns cr
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN customer_demographics cd_refunded
    ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_demographics cd_returning
    ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
JOIN date_dim d_page_start
    ON cp.cp_start_date_sk = d_page_start.d_date_sk
JOIN date_dim d_page_end
    ON cp.cp_end_date_sk = d_page_end.d_date_sk
GROUP BY cp.cp_type, s.s_city, d_return.d_year, d_return.d_month_seq
ORDER BY total_net_loss DESC
LIMIT 100
