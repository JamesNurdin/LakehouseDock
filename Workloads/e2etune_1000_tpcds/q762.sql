SELECT
    call_center_name,
    hour,
    net_loss,
    return_amount,
    return_quantity,
    avg_return_qty,
    RANK() OVER (PARTITION BY hour ORDER BY net_loss DESC) AS loss_rank
FROM (
    SELECT
        COALESCE(cc_name, 'ALL_CHANNELS') AS call_center_name,
        hour,
        SUM(total_net_loss) AS net_loss,
        SUM(total_return_amount) AS return_amount,
        SUM(total_return_quantity) AS return_quantity,
        AVG(total_return_quantity) AS avg_return_qty
    FROM (
        SELECT
            cc.cc_name,
            td.t_hour AS hour,
            cr.cr_net_loss AS total_net_loss,
            cr.cr_return_amount AS total_return_amount,
            cr.cr_return_quantity AS total_return_quantity
        FROM catalog_returns cr
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
        WHERE cc.cc_company = 1
          AND cc.cc_tax_percentage > 0.05
          AND td.t_hour BETWEEN 8 AND 20

        UNION ALL

        SELECT
            NULL AS cc_name,
            td.t_hour AS hour,
            sr.sr_net_loss AS total_net_loss,
            sr.sr_return_amt AS total_return_amount,
            sr.sr_return_quantity AS total_return_quantity
        FROM store_returns sr
        JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
        WHERE td.t_hour BETWEEN 8 AND 20

        UNION ALL

        SELECT
            NULL AS cc_name,
            td.t_hour AS hour,
            wr.wr_net_loss AS total_net_loss,
            wr.wr_return_amt AS total_return_amount,
            wr.wr_return_quantity AS total_return_quantity
        FROM web_returns wr
        JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
        WHERE td.t_hour BETWEEN 8 AND 20
    ) AS combined
    GROUP BY
        cc_name,
        hour
) AS agg
ORDER BY
    hour,
    loss_rank
