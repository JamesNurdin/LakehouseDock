WITH
    base AS (
        SELECT
            td.t_time_id,
            td.t_hour,
            td.t_am_pm,
            cc.cc_call_center_id,
            cp.cp_catalog_number,
            cp.cp_catalog_page_number,
            w.w_warehouse_id,
            cr.cr_return_amount,
            cr.cr_return_tax,
            cr.cr_net_loss AS cr_net_loss,
            sr.sr_return_amt,
            sr.sr_return_tax,
            sr.sr_net_loss AS sr_net_loss
        FROM time_dim td
        LEFT JOIN store_returns sr
            ON sr.sr_return_time_sk = td.t_time_sk
        LEFT JOIN catalog_returns cr
            ON cr.cr_returned_time_sk = td.t_time_sk
        LEFT JOIN call_center cc
            ON cr.cr_call_center_sk = cc.cc_call_center_sk
        LEFT JOIN catalog_page cp
            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        LEFT JOIN warehouse w
            ON cr.cr_warehouse_sk = w.w_warehouse_sk
        WHERE
            td.t_am_pm = 'PM'
            AND cp.cp_catalog_number IN (5, 10, 20)
            AND cc.cc_state = 'CA'
            AND w.w_city = 'Seattle'
            AND td.t_hour BETWEEN 12 AND 18
    ),
    catalog_agg AS (
        SELECT
            t_time_id,
            'catalog' AS source,
            SUM(cr_return_amount) AS total_return_amount,
            SUM(cr_net_loss) AS total_net_loss
        FROM base
        WHERE cr_return_amount IS NOT NULL
        GROUP BY t_time_id
    ),
    store_agg AS (
        SELECT
            t_time_id,
            'store' AS source,
            SUM(sr_return_amt) AS total_return_amount,
            SUM(sr_net_loss) AS total_net_loss
        FROM base
        WHERE sr_return_amt IS NOT NULL
        GROUP BY t_time_id
    ),
    combined AS (
        SELECT * FROM catalog_agg
        UNION ALL
        SELECT * FROM store_agg
    ),
    final_agg AS (
        SELECT
            t_time_id,
            SUM(total_return_amount) AS day_total_return,
            AVG(total_net_loss) AS avg_net_loss
        FROM combined
        GROUP BY t_time_id
        HAVING AVG(total_net_loss) > 1000
    )
SELECT
    t_time_id,
    day_total_return,
    avg_net_loss
FROM final_agg
ORDER BY day_total_return DESC
LIMIT 100
