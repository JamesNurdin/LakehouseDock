SELECT
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month,
    cd_ref.cd_gender AS refunded_gender,
    cd_ret.cd_gender AS returning_gender,
    s.s_division_name AS store_division,
    ws.web_mkt_class AS website_market_class,
    CASE
        WHEN cr.cr_return_quantity > 5 THEN 'Bulk'
        ELSE 'Single'
    END AS return_type,
    COUNT(*) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(cr.cr_return_amount) / NULLIF(COUNT(*), 0) AS avg_return_amount,
    SUM(cr.cr_fee) AS total_fee,
    SUM(cr.cr_return_tax) AS total_tax,
    SUM(cr.cr_return_amount + cr.cr_return_tax + cr.cr_fee) AS total_gross_return
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_ret.d_date_sk
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    cd_ref.cd_gender,
    cd_ret.cd_gender,
    s.s_division_name,
    ws.web_mkt_class,
    CASE
        WHEN cr.cr_return_quantity > 5 THEN 'Bulk'
        ELSE 'Single'
    END
HAVING COUNT(*) > 10
ORDER BY total_net_loss DESC
LIMIT 100
