SELECT
    cp.cp_department,
    cp.cp_type,
    cp.cp_catalog_page_number,
    cp.cp_description,
    dr.d_date AS return_date,
    dr.d_year,
    dr.d_week_seq,
    dr.d_day_name,
    s.s_store_name,
    s.s_city,
    s.s_state,
    cd_returning.cd_gender AS returning_gender,
    cd_returning.cd_credit_rating AS returning_credit_rating,
    cd_refunded.cd_gender AS refunded_gender,
    cd_refunded.cd_credit_rating AS refunded_credit_rating,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
FROM catalog_returns cr
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim dr
    ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN customer_demographics cd_returning
    ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN customer_demographics cd_refunded
    ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = dr.d_date_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
WHERE dr.d_date BETWEEN d_start.d_date AND d_end.d_date
GROUP BY
    cp.cp_department,
    cp.cp_type,
    cp.cp_catalog_page_number,
    cp.cp_description,
    dr.d_date,
    dr.d_year,
    dr.d_week_seq,
    dr.d_day_name,
    s.s_store_name,
    s.s_city,
    s.s_state,
    cd_returning.cd_gender,
    cd_returning.cd_credit_rating,
    cd_refunded.cd_gender,
    cd_refunded.cd_credit_rating
ORDER BY total_net_loss DESC
LIMIT 100
