SELECT
    d_sr.d_year AS year,
    COALESCE(p.p_promo_name, 'No Promotion') AS promo_name,
    cp.cp_department AS department,
    cd_sr.cd_gender AS gender,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_count,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_count,
    SUM(sr.sr_net_loss) AS store_net_loss,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(cr.cr_net_loss, 0)) AS total_net_loss,
    COALESCE(w.web_name, 'No Website') AS website_name
FROM
    tpcds.store_returns sr
    JOIN tpcds.date_dim d_sr
        ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN tpcds.customer_demographics cd_sr
        ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    LEFT JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d_sr.d_date_sk
    LEFT JOIN tpcds.customer_demographics cd_refunded
        ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    LEFT JOIN tpcds.customer_demographics cd_returning
        ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    LEFT JOIN tpcds.catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN tpcds.date_dim d_cp_start
        ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    LEFT JOIN tpcds.date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    LEFT JOIN tpcds.promotion p
        ON p.p_start_date_sk = d_sr.d_date_sk
    LEFT JOIN tpcds.date_dim d_p_end
        ON p.p_end_date_sk = d_p_end.d_date_sk
    LEFT JOIN tpcds.web_site w
        ON w.web_open_date_sk = d_sr.d_date_sk
WHERE
    d_sr.d_year BETWEEN 1999 AND 2001
    AND p.p_channel_tv = 'N'
GROUP BY
    d_sr.d_year,
    COALESCE(p.p_promo_name, 'No Promotion'),
    cp.cp_department,
    cd_sr.cd_gender,
    COALESCE(w.web_name, 'No Website')
ORDER BY
    total_net_loss DESC
LIMIT 100
