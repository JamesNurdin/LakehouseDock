SELECT
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    cd_ret.cd_gender AS returning_gender,
    cd_ref.cd_marital_status AS refunded_marital_status,
    cd_ref_cdemo.cd_credit_rating AS refunded_credit_rating,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    COUNT(*) AS return_cnt
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN customer cust_ret
    ON cr.cr_returning_customer_sk = cust_ret.c_customer_sk
JOIN customer_demographics cd_ret
    ON cust_ret.c_current_cdemo_sk = cd_ret.cd_demo_sk
JOIN customer cust_ref
    ON cr.cr_refunded_customer_sk = cust_ref.c_customer_sk
JOIN customer_demographics cd_ref
    ON cust_ref.c_current_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ref_cdemo
    ON cr.cr_refunded_cdemo_sk = cd_ref_cdemo.cd_demo_sk
WHERE d.d_year = 2022
GROUP BY
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    cd_ret.cd_gender,
    cd_ref.cd_marital_status,
    cd_ref_cdemo.cd_credit_rating
ORDER BY total_net_loss DESC
LIMIT 100
