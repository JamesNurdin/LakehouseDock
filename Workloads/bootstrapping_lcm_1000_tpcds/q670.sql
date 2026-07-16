SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    cd_ref.cd_gender          AS catalog_refunded_gender,
    cd_ret.cd_gender          AS catalog_returning_gender,
    cd_wr_ref.cd_gender       AS web_refunded_gender,
    cd_wr_ret.cd_gender       AS web_returning_gender,
    COUNT(DISTINCT cr.cr_order_number)   AS catalog_return_orders,
    COUNT(DISTINCT wr.wr_order_number)   AS web_return_orders,
    SUM(cr.cr_return_amount)             AS total_catalog_return_amount,
    SUM(wr.wr_return_amt)                AS total_web_return_amount,
    ROUND(
        CASE 
            WHEN SUM(wr.wr_return_amt) = 0 THEN NULL
            ELSE SUM(cr.cr_return_amount) / SUM(wr.wr_return_amt)
        END, 2)                          AS catalog_to_web_return_ratio,
    AVG(cr.cr_return_tax)                AS avg_catalog_return_tax,
    AVG(wr.wr_return_tax)                AS avg_web_return_tax,
    SUM(cr.cr_fee + wr.wr_fee)            AS total_fees,
    MAX(d.d_last_dom)                    AS last_day_of_month
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
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
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY
    d.d_date,
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    cd_ref.cd_gender,
    cd_ret.cd_gender,
    cd_wr_ref.cd_gender,
    cd_wr_ret.cd_gender
ORDER BY d.d_date DESC, s.s_store_name
LIMIT 100
