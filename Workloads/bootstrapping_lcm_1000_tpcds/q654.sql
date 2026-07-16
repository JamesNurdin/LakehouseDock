SELECT
    s.s_store_name,
    s.s_state,
    r.r_reason_desc,
    d.d_year,
    d.d_month_seq,
    SUM(cr.cr_net_loss)                         AS total_net_loss,
    COUNT(*)                                    AS total_returns,
    AVG(cr.cr_return_quantity)                 AS avg_return_quantity,
    SUM(cr.cr_fee)                              AS total_fee,
    SUM(cr.cr_return_amount)                   AS total_return_amount,
    COUNT(DISTINCT cr.cr_order_number)         AS distinct_orders,
    SUM(CASE WHEN cd_returning.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_returning_customers,
    SUM(CASE WHEN cd_refunded.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_refunded_customers
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
LEFT JOIN customer_demographics cd_refunded
    ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
LEFT JOIN customer_demographics cd_returning
    ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
WHERE d.d_year BETWEEN 2000 AND 2005
GROUP BY
    s.s_store_name,
    s.s_state,
    r.r_reason_desc,
    d.d_year,
    d.d_month_seq
ORDER BY total_net_loss DESC
LIMIT 100
