SELECT
    td.t_hour AS hour_of_day,
    cd_ret.cd_gender AS returning_customer_gender,
    r_cr.r_reason_desc AS catalog_return_reason,
    td_extra.t_sub_shift AS return_sub_shift,
    td_sr_extra.t_meal_time AS return_meal_time,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    AVG(cr.cr_return_amount) AS avg_catalog_return_amount,
    COUNT(DISTINCT r_sr.r_reason_desc) AS distinct_store_return_reasons
FROM
    catalog_returns cr
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN customer_demographics cd_ref
        ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_demographics cd_ret
        ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN store_returns sr
        ON sr.sr_return_time_sk = td.t_time_sk
    JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN customer_demographics cd_store
        ON sr.sr_cdemo_sk = cd_store.cd_demo_sk
    JOIN time_dim td_extra
        ON cr.cr_returned_time_sk = td_extra.t_time_sk
    JOIN time_dim td_sr_extra
        ON sr.sr_return_time_sk = td_sr_extra.t_time_sk
WHERE
    cr.cr_net_loss > (SELECT AVG(cr2.cr_net_loss) FROM catalog_returns cr2)
    AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_return_time_sk = cr.cr_returned_time_sk
          AND sr2.sr_net_loss > 100
    )
    AND cd_ret.cd_gender = 'M'
    AND r_cr.r_reason_desc IN (
        SELECT DISTINCT r2.r_reason_desc
        FROM reason r2
        WHERE r2.r_reason_desc LIKE '%damaged%'
    )
GROUP BY
    td.t_hour,
    cd_ret.cd_gender,
    r_cr.r_reason_desc,
    td_extra.t_sub_shift,
    td_sr_extra.t_meal_time
ORDER BY
    total_catalog_net_loss DESC,
    td.t_hour ASC
