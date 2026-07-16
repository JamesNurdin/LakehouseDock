SELECT
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    i.i_category,
    i.i_brand,
    cd_ref.cd_gender AS refunded_gender,
    cd_ret.cd_gender AS returning_gender,
    COUNT(*) AS total_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_quantity
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
GROUP BY
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    i.i_category,
    i.i_brand,
    cd_ref.cd_gender,
    cd_ret.cd_gender
ORDER BY total_return_amount DESC
LIMIT 100
