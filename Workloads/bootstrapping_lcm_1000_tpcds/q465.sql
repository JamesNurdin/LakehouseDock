SELECT
    d.d_year AS year,
    s.s_store_id,
    cd_ref.cd_gender AS refunded_gender,
    cd_ret.cd_gender AS returning_gender,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) AS total_combined_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_order_count,
    COUNT(DISTINCT wr.wr_order_number) AS web_order_count,
    AVG(cr.cr_return_amount) AS avg_catalog_return_amount,
    AVG(wr.wr_return_amt) AS avg_web_return_amount
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN customer_demographics cd_wr_ref
    ON wr.wr_refunded_cdemo_sk = cd_wr_ref.cd_demo_sk
JOIN customer_demographics cd_wr_ret
    ON wr.wr_returning_cdemo_sk = cd_wr_ret.cd_demo_sk
WHERE d.d_year BETWEEN 2000 AND 2005
    AND s.s_state = 'CA'
    AND cd_ref.cd_gender = 'F'
    AND cd_wr_ret.cd_marital_status = 'M'
GROUP BY
    d.d_year,
    s.s_store_id,
    cd_ref.cd_gender,
    cd_ret.cd_gender
HAVING SUM(cr.cr_net_loss + wr.wr_net_loss) > 1000
ORDER BY total_combined_net_loss DESC, d.d_year DESC
LIMIT 100
